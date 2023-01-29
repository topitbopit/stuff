--- Labyrinth Item Esp
-- Made by topit 
-- Version 1.1.1 // January 28th, 2023

--[[
Version v1.1.1
 * Fixed text scaling erroring when text_size > 35     

Version v1.1.0
 * Changed how text scaling works a tiny bit 
 * Cleaned up some code
 + Added culled_refresh_rate setting
 + Added rarity_specific setting
 + Optimized ESP culling even more - off-screen ESPs get updated at a lower rate (culled_refresh_rate) than on-screen ESPs
    
Version v1.0.1
 * Fixed "Labrynth" typos

Version v1.0.0
 + Released
]]

if ( game.PlaceId ~= 534701013 ) then
    messagebox('Wrong game', 'Oopsies', 0)
    return
end

--- Setup shared stuff 
local espInfo = shared.labyrinthEsp

if ( espInfo ) then
    if ( espInfo.Destroy ) then
        espInfo.Destroy()
    end
else
    espInfo = {} 
    shared.labyrinthEsp = espInfo
end

if ( not game:IsLoaded() ) then
    game.Loaded:Wait()
end

--- Handle settings 
local settings = espInfo.settings or {} 
local defaultSettings = {
    -- Render settings 
    max_draw_distance = 1000; -- Disables drawing of ESPs that are further away than this setting 
    text_size = 18; -- Size of the ESP text
    distance_scale = false; -- Changes scaling of ESP based off of distance 
    optimized_updating = false; -- Updates only one ESP manager per frame - boosts your fps, but some ESP looks even more delayed
    culled_refresh_rate = 0.3; -- How long to wait inbetween off-screen ESP updates. In other words, higher number = less lag, but more delay 
    
    -- Script settings 
    destroy_bind = 'End'; -- Keybind for destroying the script - refer to https://create.roblox.com/docs/reference/engine/enums/KeyCode
    rarity_level = 3; -- Rarity required to ESP an item. 1 is common, 2 is uncommon, 3 is rare, etc.
    rarity_specific = false; -- If true, only items with the rarity equal to rarity_level get ESP'd. If false, items equal to and above rarity_level get ESP'd.
    item_types = { 'Fish', 'Ores', 'Trees', 'Ingredients' }; -- What types of item to ESP. Options are 'Fish', 'Ores', 'Trees', and 'Ingredients'
    
    -- Display settings 
    background_box = true; -- Shows a background box behind each ESP, making it easier to read 
    distance_label = true; -- Shows a label displaying how far away you are from the item
    rarity_label = true; -- Shows a label displaying the item's rarity
    item_label = true; -- Shows a label displaying the item's name 
};

for k, v in pairs(defaultSettings) do 
    if ( settings[k] ~= nil ) then
        settings[k] = settings[k]
    else
        settings[k] = v
    end
end

defaultSettings = nil

-- Item type check just in case someone misspells an option
do 
    local clonedTypes = {}
    for i, v in ipairs(settings.item_types) do 
        clonedTypes[i] = v 
    end
    
    for _, itemType in ipairs({ 'Fish', 'Ores', 'Trees', 'Ingredients' }) do 
        local itemIdx = table.find(clonedTypes, itemType)
        if ( itemIdx ) then
            table.remove(clonedTypes, itemIdx)
        end
    end
    
    if ( #clonedTypes > 0 ) then
        local unexpected = table.concat(clonedTypes, ', ')
        return messagebox('Wrong option(s) found for setting item_types:\n' .. unexpected, 'Oopsies', 0)
    end
end

--- Services and some variables 
local playerService = game:GetService('Players')
local inputService = game:GetService('UserInputService')
local runService = game:GetService('RunService')
local repStorage = game:GetService('ReplicatedStorage')

local scriptCons = {} 
local localPlayer = playerService.LocalPlayer
local localChar = localPlayer.Character
local localRoot = localChar and localChar:FindFirstChild('HumanoidRootPart')
local localCamera = workspace.CurrentCamera

--- Get item information 
local itemsModule = require(repStorage.Shared.ItemsModule)
local itemInfo = {} do 
    local wantedLevel = settings.rarity_level
    
    local rarityEnum = {
        Event     = 9;
        Celestial = 8;
        Divine    = 7;
        Mythic    = 6;
        Legendary = 5;
        Epic      = 4;
        Rare      = 3;
        Uncommon  = 2;
        Common    = 1;
    }
    
    local rarityColors = {
        Celestial = Color3.fromHSV(0.90, 0.90, 0.90); -- grey (change to pink)
        Divine    = Color3.fromHSV(0.10, 1.00, 1.00); -- orange 
        Mythic    = Color3.fromHSV(0.00, 1.00, 0.90); -- red 
        Legendary = Color3.fromHSV(0.15, 1.00, 1.00); -- yellow 
        Epic      = Color3.fromHSV(0.75, 1.00, 1.00); -- purple 
        Rare      = Color3.fromHSV(0.65, 0.90, 0.90); -- blue 
        Uncommon  = Color3.fromHSV(0.40, 1.00, 1.00); -- green 
        Common    = Color3.fromHSV(0.60, 0.20, 0.90); -- light grey 
    }
    
    -- colors for each nametag
    local typeColors = {
        Ingredient  = Color3.fromHSV(0.30, 0.3, 0.9);
        Logs        = Color3.fromHSV(0.40, 0.3, 0.9);
        Fish        = Color3.fromHSV(0.75, 0.3, 0.9);
        Ores        = Color3.fromHSV(0.60, 0.3, 0.9);
    }
    
    -- ingredient names are weird for some reason so a lookup table has to be used 
    local ingredientLookup = {
        ['FrostFlower_Ingredient'] = 'Frost_Flower_Vine';
        ['Glowberry_Ingredient'] = 'Glowberry_Plant';  -- this is a guess, not tested 
        ['SeaOrb_Ingredient'] = 'Sea_Orb_Plant'; -- this is a guess
        ['LeafyVine_Ingredient'] = 'Leafy_Vine';
        ['DarkShroom_Ingredient'] = 'Dark_Shroom_Plant'; -- this is a guess
        ['OrnathPlant_Ingredient'] = 'Ornath_Plant';
    }
    
    for name, info in pairs(itemsModule.Items) do 
        if ( info.Type == 'Resource' ) then
            local rarityStr = info.Information.Rarity
            local rarityInt = rarityEnum[rarityStr]
            
            local typeStr = info.Information.Type 
            
            if ( settings.rarity_specific ) then 
                if ( rarityInt ~= wantedLevel ) then
                    continue
                end
            else
                if ( rarityInt < wantedLevel ) then
                    continue
                end
            end 
            
            if ( name:match('Log') ) then
                name = name:gsub('Log', 'Tree')
            elseif ( name:match('Ore') ) then
                name = name:gsub('Ore', 'Rock')
            elseif ( typeStr == 'Ingredient' ) then
                name = ingredientLookup[name]
            end
            
            itemInfo[name] = {
                --- Rarity 
                rarityStr = rarityStr;
                rarityInt = rarityInt;
                
                --- Name 
                nameClean = name:gsub('_', ' ');
                -- nameRaw = name; -- (unused) 
                
                --- Colors 
                -- itemColor = info.Information.Color; -- (unused)
                rarityColor = rarityColors[rarityStr];
                typeColor = typeColors[typeStr];
            }
        end
    end 
end

--- EspObject class
-- Handles creating and updating esp for items
local EspObject = {} do 
    EspObject._class = 'EspObject'
    EspObject.__index = EspObject

    function EspObject:Destroy(keepLinked: boolean) 
        if ( self.destroyed ) then
            warn('Attempt to destroy already destroyed EspObject instance!') -- this prob shouldnt pop up
            return
        end
        
        local objects = self.objects
        for _, label in pairs(objects ) do
            label:Remove()
        end
        
        self.objects = nil 
        self.destroyed = true 
        
        if ( self.destroyCon ) then
            self.destroyCon:Disconnect()
        end
        
        if ( not keepLinked ) then 
            local objectList = self.manager.objects
            local objectIndex = table.find(objectList, self)
            if ( objectIndex ) then
                table.remove(objectList, objectIndex)
            end
        end
        
        objects = nil    
        setmetatable(self, nil)
    end

    function EspObject:Update() 
        if ( self.destroyed ) then
            return false 
        end
        
        local curTime = tick() 
        
        if ( self.culled and ( curTime - self.updateTime ) < settings.culled_refresh_rate ) then
            return
        end
                
        local objects = self.objects 
        
        local parent = self.parent 
        local parentPosition = parent:GetPivot().Position + Vector3.new(0, 3, 0)
        local position3d = localCamera:WorldToViewportPoint(parentPosition)
        
        if ( position3d.Z < 0 ) then
            if ( self.culled == false ) then 
                for _, obj in pairs(self.objects) do
                    obj.Visible = false
                end
                self.culled = true
            end
            
            return
        end
        
        local playerDistance = ( localRoot.Position - parentPosition ).Magnitude 
        if ( playerDistance > settings.max_draw_distance ) then
            if ( self.culled == false ) then 
                for _, obj in pairs(self.objects) do
                    obj.Visible = false
                end
                self.culled = true
            end
            
            return
        end 
        
        local position2d = Vector2.new(position3d.X, position3d.Y) 
        
        local nametag = objects.nametag
        local rarity = objects.rarity
        local distance = objects.distance 
        local box = objects.box 
        
        local depth = position3d.Z
        
        local textSize = settings.text_size 
        
        if ( settings.distance_scale ) then
            local depthScale = 1200 / depth
            local fovScale = 70 / localCamera.FieldOfView
            
            textSize = math.clamp(depthScale, textSize, textSize + 20) * fovScale
        end
        
        local index = 10000 + ( -depth )
        
        local boxHeight = 0
        local boxWidth = 0
        
        if ( nametag ) then
            nametag.Position = position2d 
            nametag.Size = textSize
            nametag.ZIndex = index
            
            local bounds = nametag.TextBounds 
            boxWidth = bounds.X
            boxHeight += bounds.Y 
        end
        
        if ( rarity ) then
            rarity.Position = position2d + Vector2.new(0, boxHeight)
            
            rarity.Size = textSize
            rarity.ZIndex = index
            
            local bounds = rarity.TextBounds 
            boxWidth = math.max(boxWidth, bounds.X)
            boxHeight += bounds.Y 
        end
        
        if ( distance ) then
            distance.Position = position2d + Vector2.new(0, boxHeight)
            
            distance.Text = string.format('[%d]', playerDistance)
            distance.Size = textSize
            distance.ZIndex = index
            
            boxHeight += distance.TextBounds.Y 
        end
        
        if ( box ) then
            local size = Vector2.new(boxWidth + 4, boxHeight + 4)
            
            box.ZIndex = index - 1 
            box.Position = position2d - Vector2.new(boxWidth / 2, 0)
            box.Size = size 
        end
        
        for _, object in pairs(self.objects) do
            object.Visible = true
        end
        
        self.culled = false 
        self.updateTime = curTime
        
        return self 
    end
    
    function EspObject.new(manager: EspManager, parentObject: Instance) 
        local thisItemInfo = itemInfo[parentObject.Name] 
        
        if ( not thisItemInfo ) then
            return -- Item isn't rare enough, cancel creating esp 
        end 
        
        if ( parentObject.Properties.Alive.Value == false ) then
            return -- Item isn't alive, cancel creating esp  
        end
        
        local self = setmetatable({}, EspObject)
        local objects = {}
        
        self.culled = false -- set to true when this object is offscreen and not being updated 
        self.updateTime = 0 -- time when the last update occurred 
        self.manager = manager 
        self.parent = parentObject 
        
        self.destroyCon = parentObject.Properties.Alive.Changed:Connect(function()
            -- Item got destroyed, delete esp 
            self:Destroy() 
        end)
        
        if ( settings.item_label ) then 
            local nametag = Drawing.new('Text')
            nametag.Center = true
            nametag.Color = thisItemInfo.typeColor --Color3.fromRGB(212, 212, 212)
            nametag.Font = 1 
            nametag.Outline = true 
            nametag.OutlineColor = Color3.fromRGB(5, 5, 5)
            nametag.Text = thisItemInfo.nameClean
            nametag.Visible = false 
        
            objects.nametag = nametag 
        end
        
        if ( settings.rarity_label ) then 
            local rarity = Drawing.new('Text')
            rarity.Center = true
            rarity.Color = thisItemInfo.rarityColor 
            rarity.Font = 1 
            rarity.Outline = true 
            rarity.OutlineColor = Color3.fromRGB(5, 5, 5)
            rarity.Text = thisItemInfo.rarityStr
            rarity.Visible = false 
            
            objects.rarity = rarity 
        end 
        
        if ( settings.distance_label ) then 
            local distance = Drawing.new('Text')
            distance.Center = true
            distance.Color = Color3.fromRGB(172, 172, 172)
            distance.Font = 1
            distance.Outline = true 
            distance.OutlineColor = Color3.fromRGB(5, 5, 5)
            distance.Text = '[0]'
            
            objects.distance = distance 
        end 
        
        if ( settings.background_box ) then
            local box = Drawing.new('Square')
            box.Color = Color3.fromRGB(20, 20, 24)
            box.Transparency = 0.3
            box.Visible = false 
            box.Filled = true 
            
            objects.box = box 
        end
        
        self.objects = objects 
        
        return self 
    end
end

--- EspManager class
-- Creates an interface for managing every esp object
local EspManager = {} do 
    EspManager._class = 'EspManager'
    EspManager.__index = EspManager
    
    -- Destroys this EspManager instance, cleaning up every existing EspObject
    function EspManager:Destroy() 
        if ( #self:GetObjects() > 0 ) then
            self:ClearAllEsps()
        end
        
        setmetatable(self, nil)
        
        return true 
    end
    
    -- Updates every EspObject linked to this manager
    function EspManager:Update() 
        for _, object in ipairs(self.objects) do 
            if ( object.Destroyed ) then
                warn('Destroyed EspObject was skipped in EspManager:Update') -- if this warning pops up then it might be memleaking
                continue
            end
            
            object:Update()
        end
        
        return self 
    end
    
    -- Destroys every EspObject linked to this manager. Optimal over iterating manually.
    function EspManager:ClearAllEsps() 
        for _, object in ipairs(self.objects) do 
            object:Destroy(true)
        end
        
        table.clear(self.objects)
        
        return self 
    end
    
    -- Returns the array containing every EspObject
    function EspManager:GetObjects() 
        return self.objects 
    end
    
    -- Creates and returns a new EspObject thats binded to the instance passed 
    function EspManager:CreateEsp(parent: Instance)
        local object = EspObject.new(self, parent)
        
        table.insert(self.objects, object)
        
        return object 
    end
    
    -- Creates and returns a new EspManager
    function EspManager.new() 
        local self = setmetatable({}, EspManager)
        self.objects = {} 
        
        return self 
    end
end


--- Resource handling
-- Handles existing resources in the Maze and Glade 
local mazeResources = workspace.Resources.Maze 
local gladeResources = workspace.Resources.Glade 

local mazeManager = EspManager.new()
local gladeManager = EspManager.new() 

do 
    for _, iType in ipairs(settings.item_types) do 
        -- maze 
        for _, item in ipairs(mazeResources[iType]:GetChildren()) do 
            mazeManager:CreateEsp(item)
        end
        
        -- glade 
        for _, item in ipairs(gladeResources[iType]:GetChildren()) do 
            gladeManager:CreateEsp(item)
        end
    end
end

--- Event listeners 
do 
    -- Respawn connection, refreshes some local variables when the player respawns 
    scriptCons.respawnListener = localPlayer.CharacterAdded:Connect(function(newCharacter) 
        localChar = newCharacter
        localRoot = newCharacter:WaitForChild('HumanoidRootPart')
    end)
    
    scriptCons.inputListener = inputService.InputBegan:Connect(function(input, processed) 
        local keycode = input.KeyCode.Name  
        
        if ( processed == false and keycode == settings.destroy_bind ) then
            espInfo.Destroy() 
        end
    end)
    
    local format = '%s%sListener'
    for _, iType in ipairs(settings.item_types) do 
        -- this is extremely scuffed and looks like shit
        -- but i can't be bothered to switch to a better alternative that doesn't use 139851395813 tables in the process
        
        scriptCons[string.format(format, 'maze', iType)] = mazeResources[iType].ChildAdded:Connect(function(mazeItem) 
            mazeItem:WaitForChild('Properties'):WaitForChild('Alive')
            mazeManager:CreateEsp(mazeItem)
        end)
        
        scriptCons[string.format(format, 'glade', iType)] = gladeResources[iType].ChildAdded:Connect(function(gladeItem) 
            gladeItem:WaitForChild('Properties'):WaitForChild('Alive')
            gladeManager:CreateEsp(gladeItem)
        end)
    end
end

-- Update connection 
if ( settings.optimized_updating ) then 
    local update = false 
    
    scriptCons.updateListener = runService.Heartbeat:Connect(function() 
        update = not update
        if ( update ) then 
            mazeManager:Update()
        else 
            gladeManager:Update()
        end
    end)
else
    scriptCons.updateListener = runService.Heartbeat:Connect(function() 
        mazeManager:Update()
        gladeManager:Update()
    end)
end

--- Cleanup function 
function espInfo.Destroy() 
    for _, con in pairs(scriptCons) do
        con:Disconnect()
    end
    
    mazeManager:Destroy()
    gladeManager:Destroy()
    
    espInfo.Destroy = nil 
end
