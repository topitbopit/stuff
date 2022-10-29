-- Trusty GUI v1.0.2
-- Made by topit 

-- ideas:
--[[
- auto trusty and meteor
]]


if ( game.PlaceId ~= 8726743209 ) then
    return messagebox('Wrong game!', 'Oopsies', 0)
end

local inputService = game:GetService('UserInputService')
local lightingService = game:GetService('Lighting')
local playerService = game:GetService('Players')
local runService = game:GetService('RunService')
local tweenService = game:GetService('TweenService')
local vimService = game:GetService('VirtualInputManager')

local repStorage = game:GetService('ReplicatedStorage')

local GUIVER = 'v1.0.2'

-- // Variables that do stuff 
local localPlayer = playerService.LocalPlayer
local localChar = localPlayer.Character 
local localRoot = localChar and localChar:FindFirstChild('HumanoidRootPart')
local localHum = localChar and localChar:FindFirstChild('Humanoid')

local localMouse = localPlayer:GetMouse()
local localCam = workspace.CurrentCamera

local remotes = {
    clientevent = repStorage.Events.ClientEvent;
    sellarySell = workspace.Map.Sellary.Keeper.IPart.Interact;
    grab = repStorage.Events.Grab;
    ungrab = repStorage.Events.Ungrab;
}

local grabbable = workspace.Grabable
local ignore = workspace.MouseIgnore

local signals = {}

local playerPlotPointer = localPlayer.Values.Plot
local playerPlot = playerPlotPointer.Value 

local playerCashPointer = localPlayer.Values.Saveable.Cash
local playerCash = playerCashPointer.Value

local playerVehicle = nil 

local delays = {
    dialog_button_wait = 0.5; -- how long to wait before getting the "Yes" dialog button
    interact_after_teleport = 0.5; -- how long to wait before interacting with the employee after teleporting to them
    distance_teleport = 0.05; -- how long to wait after teleporting to an item (if you are too far away)
    teleport_after_buy = 2.5; -- how long to wait before teleporting back once an item is bought
    shopkeep_sell_prompt = 0.5; -- wait needed for the shopkeep to react after firing the interact remote
    item_own = 1; -- wait needed for the item to be registered as yours after buying
}

-- Functions that do stuff
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Blacklist
params.FilterDescendantsInstances = { ignore, localChar }

local utilfuncs = {} 

function utilfuncs.getClosestRegister( building: Instance ) 
    local localPos = localRoot.Position
    
    local maxDistance = 9e5 
    local target 
    
    for i, reg in ipairs( building.Registers:GetChildren() ) do 
        local counter = reg.Counter.Counter
        local thisDistance = (counter.Position - localPos).Magnitude
        if ( thisDistance < maxDistance ) then
            maxDistance = thisDistance
            target = reg 
        end
    end
    
    return target 
end

function utilfuncs.clickGui( obj: GuiObject ) 
    if ( not obj ) then
        return
    end 
    local pos = obj.AbsolutePosition
    local x, y = pos.X + 15, pos.Y + 45

    vimService:SendMouseButtonEvent(x, y, 0, true, game, 0) -- mouse1 down at x, y once
    task.wait()
    vimService:SendMouseButtonEvent(x, y, 0, false, game, 0)  -- mouse1 up at x, y once
end

function utilfuncs.getYes() 
    local dialog = localPlayer.PlayerGui.UserGui.Dialog
    task.wait(delays.dialog_button_wait)
    local yes = dialog:WaitForChild('Yes', 1)
    if ( yes ) then
        if ( yes.AbsolutePosition.X == 0 ) then
            task.wait(delays.dialog_button_wait)
            yes = dialog:WaitForChild('Yes', 1)
        end
    end
    
    return yes 
end

function utilfuncs.getStoreItem( storeItem: string ) 
    for _, i in ipairs( grabbable:GetChildren() ) do 
        if ( i.Name == storeItem and i:FindFirstChild('Shop') ) then
            return i  
        end
    end
end

function utilfuncs.raycastMouse() 
    local mouseLoc = inputService:GetMouseLocation()
    local unitRay = localCam:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
    local raycast = workspace:Raycast(unitRay.Origin, unitRay.Direction * 99999, params)
    
    return raycast -- and raycast.Instance 
end

function utilfuncs.buyItem( instance: Instance ) 
    local startCFrame = localRoot.CFrame 
    local startPos = localRoot.Position
    
    local instanceCFrame = instance:GetPivot()
    
    if ( ( instance:GetPivot().Position - startPos ).Magnitude > 25 ) then -- too far away, teleport to it 
        utilfuncs.tryTeleport(instanceCFrame)
        task.wait(delays.distance_teleport)
    end
    
    local shop = instance.Shop.Value.Parent.Parent 
    local register = utilfuncs.getClosestRegister(shop)
    
    if ( register ) then
        local counter = register.Counter.Counter 
        local buy = register.Worker.IPart.Interact
        
        instance:SetPrimaryPartCFrame(counter.CFrame + Vector3.new(0, 2, 0))
        utilfuncs.tryTeleport(counter.CFrame + counter.Size)
        task.wait(delays.interact_after_teleport)
        buy:FireServer()
        task.wait(delays.shopkeep_sell_prompt)
        utilfuncs.clickGui(utilfuncs.getYes())
        task.wait(delays.item_own)
        
        return instance 
    end
    
    return false 
end

function utilfuncs.seatUpdate() 
    local seat = localHum.SeatPart
    if ( seat and seat:IsA('VehicleSeat') ) then
        -- incar = true
        local vehicle = seat.Parent 
        local owner = vehicle and vehicle:FindFirstChild('Owner')
        if ( owner and owner.Value == localPlayer ) then
            playerVehicle = vehicle
        else
            playerVehicle = nil
        end
    else
        playerVehicle = nil
    end
end

function utilfuncs.getHotkey( acceptMouse: boolean ) 
    local now = coroutine.running()
    
    local finalKey, keyType 
    local cn = inputService.InputBegan:Connect(function(io, gpe) 
        if ( acceptMouse ) then
            local inputType = io.UserInputType.Name 
            if ( inputType == 'MouseButton1' ) then
                finalKey = io.UserInputType 
                keyType = 'UserInputType'
                
                return coroutine.resume(now)
            end
        end
        
        local keyCode = io.KeyCode.Name 
        if ( keyCode ~= 'Unknown' ) then
            finalKey = io.KeyCode 
            keyType = 'KeyCode'
            
            coroutine.resume(now)
        end
    end)
    
    coroutine.yield()
    
    return finalKey, keyType
end


-- teleport related 
do
    function utilfuncs.tryTeleport( destination: CFrame ) 
        if ( playerVehicle ) then
            playerVehicle:SetPrimaryPartCFrame(destination + Vector3.new(0, 1, 0))
            playerVehicle.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
        else
            localRoot.CFrame = destination
        end
    end


    local freezeDest
    function utilfuncs.EnableFreeze() 
        localHum:SetStateEnabled('FallingDown', false)
        localHum:SetStateEnabled('Ragdoll', false)
        
        signals.FreezeCn = runService.Heartbeat:Connect(function() 
            localRoot.CFrame = freezeDest
        end)
    end

    function utilfuncs.DisableFreeze() 
        if ( signals.FreezeCn ) then
            signals.FreezeCn:Disconnect()  
        end
        
        localHum:SetStateEnabled('FallingDown', true)
        localHum:SetStateEnabled('Ragdoll', true)
    end

    function utilfuncs.SetFreezePos( Position: CFrame ) -- surely not confusing 
        freezeDest = Position 
    end
end

-- Update the stuff for the stuff  
signals['*PlotUpd'] = playerPlotPointer.Changed:Connect(function( value )
    playerPlot = value
end)

signals['*CashUpd'] = playerCashPointer.Changed:Connect(function( value )
    playerCash = value
end)

signals['CharAdd'] = localPlayer.CharacterAdded:Connect(function( newChar ) 
    localChar = newChar
    localRoot = newChar:WaitForChild('HumanoidRootPart')
    localHum = newChar:WaitForChild('Humanoid')
    
    params.FilterDescendantsInstances = { ignore, newChar }
    
    signals['CarUpd'] = localHum:GetPropertyChangedSignal('SeatPart'):Connect(utilfuncs.seatUpdate)
end)

signals['CharRemove'] = localPlayer.CharacterRemoving:Connect(function() 
    localChar = nil
end)

if ( localHum ) then
    signals['CarUpd'] = localHum:GetPropertyChangedSignal('SeatPart'):Connect(utilfuncs.seatUpdate)    
end

-- End init stuff //

local lib = loadstring(game:HttpGet('https://raw.githubusercontent.com/topitbopit/Forks/main/Rain-Design/UnnamedLibrary.lua'))()
local flags = lib.Flags

lib.SectionsOpened = true
lib.Theme = 'Starry Night'
lib.KillCallback = function() 
    for i,v in ipairs( lib.Toggles ) do 
        if ( v.State ) then
            v:Set(false) 
        end
    end
    
    for i, v in pairs( signals ) do
        v:Disconnect()
    end
end

local window = lib:Window({
    Text = 'Trusty GUI ' .. GUIVER .. ' | Refinery Caves'
})
do 
    local tab = window:Tab({
        Text = 'Utilities',
        Tooltip = 'Simple, quick utilities that are nice to have'
    })
    do 
        tab:Select()
        local bringLocation
        if ( playerPlot ) then
            local base = playerPlot.Base
            local dest = base.CFrame + ( base.Size / 1.5 ) + Vector3.new(0, 3, 0)
            
            bringLocation = dest
        end
        
        local section = tab:Section({
            Text = 'Click interactions',
            Side = 'Left'
        })
        do 
            do 
                local inputCn 
                
                section:Toggle({
                    Text = 'Click counter',
                    Tooltip = 'Lets you click on a store item to bring it to the closest store counter',
                    Callback = function( ns ) 
                        if ( ns ) then
                            inputCn = localMouse.Button1Down:Connect(function() 
                                local raycast = utilfuncs.raycastMouse()
                                local part = raycast and raycast.Instance
                                
                                if ( part ) then
                                    local item = part.Parent 
                                    
                                    if ( item:FindFirstChild('Link') and item:FindFirstChild('Shop') ) then
                                        local pos = localRoot.CFrame 
                                        
                                        local shop = item.Shop.Value.Parent.Parent 
                                        local register = utilfuncs.getClosestRegister(shop)
                                        
                                        if ( register ) then
                                            local counter = register.Counter.Counter 
                                            local buy = register.Worker.IPart.Interact
                                            
                                            local partCFrame = part.CFrame
                                            utilfuncs.tryTeleport(partCFrame)
                                            task.wait(0.10)
                                            
                                            remotes.grab:InvokeServer(part, {})
                                            task.wait(0.03)
                                            item:SetPrimaryPartCFrame(counter.CFrame + Vector3.new(0, 3, 0))
                                            task.wait(0.03)
                                            remotes.ungrab:FireServer(part)
                                            
                                            task.wait(0.03)
                                            utilfuncs.tryTeleport(pos)
                                        end
                                        
                                        --[[local pos = localRoot.CFrame 
                                        local boughtItem = utilfuncs.buyItem(item) ]]
                                        --if ( boughtItem == item ) then
                                        
                                        --end
                                        --[[task.wait(delays.item_own)
                                        localRoot.CFrame = pos ]]
                                    end
                                end
                            end)
                        else
                            inputCn:Disconnect() 
                        end
                    end
                })
            end
            
            -- goto bring location 
            do 
                local inputCn 
                
                section:Toggle({
                    Text = 'Click bring',
                    Tooltip = 'Lets you click on any item to bring it to the saved bring position',
                    Callback = function( ns ) 
                        if ( ns ) then
                            inputCn = localMouse.Button1Down:Connect(function() 
                                local raycast = utilfuncs.raycastMouse()
                                local part = raycast and raycast.Instance
                                                                
                                if ( part ) then
                                    local item = part.Parent 
                                    
                                    if ( item:FindFirstChild('Configuration') and item:IsDescendantOf(playerPlot.Objects) == false ) then
                                        item:SetPrimaryPartCFrame(bringLocation)
                                    end
                                end
                            end)
                        else
                            inputCn:Disconnect() 
                        end
                    end
                })
            end
            
            --[[ migrate to a different menu later 
                
            goto bring location 
            do 
                local inputCn 
                
                section:Toggle({
                    Text = 'Instant destroy',
                    Tooltip = 'Teleports items you click into the void, effectively destroying them',
                    Callback = function( ns ) 
                        if ( ns ) then
                            local voidLocation = CFrame.new(0, -100, 0)
                            
                            inputCn = localMouse.Button1Down:Connect(function() 
                                local raycast = utilfuncs.raycastMouse()
                                local part = raycast and raycast.Instance
                                                                
                                if ( part ) then
                                    local item = part.Parent 
                                    
                                    if ( item:FindFirstChild('Configuration') and item:IsDescendantOf(playerPlot.Objects) == false ) then
                                        item:SetPrimaryPartCFrame(voidLocation)
                                    end
                                end
                            end)
                        else
                            inputCn:Disconnect() 
                        end
                    end
                })
                section:Label({
                    Text = '⚠ This may be unsafe! ⚠',
                    Color = Color3.fromRGB(245, 245, 92)
                })
            end
            ]]
            
            -- bring to sellary
            do 
                local inputCn 
                
                section:Toggle({
                    Text = 'Click sellary',
                    Tooltip = 'Click an item to warp it to the sellary',
                    Callback = function( ns ) 
                        if ( ns ) then
                            local sellaryCF = CFrame.new(-430.2, 8, -70.2)
                            
                            inputCn = localMouse.Button1Down:Connect(function() 
                                local raycast = utilfuncs.raycastMouse()
                                local part = raycast and raycast.Instance
                                                                
                                if ( part ) then
                                    local item = part.Parent 
                                    
                                    if ( item:FindFirstChild('Configuration') and item.Name == 'MaterialPart' ) then
                                        item:SetPrimaryPartCFrame(sellaryCF)
                                    end
                                end
                            end)
                        else
                            inputCn:Disconnect() 
                        end
                    end
                })
            end
        end
        
        
        local section = tab:Section({
            Text = 'Aura interactions',
            Side = 'Right'
        })
        do 
            local distance = 15
            
            -- distance
            do 
                section:Slider({
                    Text = 'Distance',
                    Tooltip = 'How close an ore has to be for it to be teleported',
                    Default = 15,
                    Minimum = 1,
                    Maximum = 100,
                    Callback = function( value ) 
                        distance = value
                    end
                })
            end
            
            
            -- goto bring location 
            do 
                local loop = false
                section:Toggle({
                    Text = 'Bring aura',
                    Tooltip = 'Warps any nearby ores to the saved bring location',
                    Callback = function( ba ) 
                        loop = ba 
                        if ( ba ) then
                            task.spawn(function() 
                                while loop do
                                    local rootPos = localRoot.Position 
                                    for i, v in ipairs(grabbable:GetChildren()) do 
                                        if ( v.Name == 'MaterialPart' and ( v.Part.Position - rootPos ).Magnitude < distance ) then
                                            v:SetPrimaryPartCFrame(bringLocation)
                                        end
                                    end
                                    task.wait(0.05)
                                end
                            end)
                        end
                    end
                })
            end
            
            -- goto bring location 
            do 
                local loop = false
                section:Toggle({
                    Text = 'Sellary aura',
                    Tooltip = 'Warps any nearby ores to the sellary',
                    Callback = function( ba ) 
                        loop = ba 
                        if ( ba ) then
                            local sellaryCF = CFrame.new(-430.2, 8, -70.2)
                            
                            task.spawn(function() 
                                while loop do
                                    local rootPos = localRoot.Position 
                                    for i, v in ipairs(grabbable:GetChildren()) do 
                                        if ( v.Name == 'MaterialPart' and ( v.Part.Position - rootPos ).Magnitude < distance ) then
                                            v:SetPrimaryPartCFrame(sellaryCF)
                                        end
                                    end
                                    task.wait(0.05)
                                end
                            end)
                        end
                    end
                })
            end
        end
        
        
        local section = tab:Section({
            Text = 'Bring location',
            Side = 'Left'
        })
        do 
            local guiHolder
            
            section:Button({
                Text = 'Set bring location',
                Tooltip = 'Saves your current location as the spot where teleported items go',
                Callback = function() 
                    bringLocation = localRoot.CFrame 
                    
                    if ( guiHolder ) then
                        guiHolder.CFrame = bringLocation
                    end
                end
            })
            
            section:Toggle({
                Text = 'Visualize BL',
                Tooltip = 'Displays a label over the bring location',
                Callback = function( t ) 
                    if ( t ) then
                        guiHolder = Instance.new('Part')
                        guiHolder.Anchored = true 
                        guiHolder.CFrame = bringLocation
                        guiHolder.CanCollide = false 
                        guiHolder.CanTouch = false 
                        guiHolder.Transparency = 1
                        guiHolder.Parent = ignore
                                                
                        local billboard = Instance.new('BillboardGui')
                        billboard.Size = UDim2.new(5, 50, 1, 10)
                        billboard.AlwaysOnTop = true 
                        billboard.Parent = guiHolder 
                                                
                        local bg = Instance.new('Frame')
                        bg.BackgroundColor3 = Color3.new(0, 0, 0)
                        bg.BackgroundTransparency = 0.8
                        bg.BorderSizePixel = 0
                        bg.Size = UDim2.fromScale(1, 1)
                        
                        local left = Instance.new('Frame')
                        left.BackgroundColor3 = Color3.fromHSV(math.random(), 0.8, 0.8)
                        left.BorderSizePixel = 0 
                        left.Size = UDim2.fromScale(0.01, 1)
                        left.ZIndex = 4 
                        
                        local label = Instance.new('TextLabel')
                        label.AnchorPoint = Vector2.new(0.5, 0.5)
                        label.BackgroundTransparency = 1
                        label.Font = 'Gotham'
                        label.Position = UDim2.fromScale(0.5, 0.5)
                        label.Size = UDim2.fromScale(0.8, 0.8)
                        label.Text = 'Bring location'
                        label.TextColor3 = Color3.fromRGB(242, 242, 242)
                        label.TextScaled = true 
                        label.TextStrokeTransparency = 0.8
                        label.ZIndex = 5 
                        
                        bg.Parent = billboard
                        left.Parent = bg 
                        label.Parent = bg
                    else
                        guiHolder:Destroy()
                    end
                end
            })
        end
        
        local section = tab:Section({
            Text = 'Quick warps',
            Side = 'Right'
        })
        do 
            section:Button({
                Text = 'Home plot',
                Tooltip = 'Teleports you to your plot',
                Callback = function() 
                    if ( playerPlot ) then
                        local base = playerPlot.Base
                        local dest = ( base.CFrame - ( base.Size / 1.5 ) ) + Vector3.new(0, 3, 0)
                        
                        utilfuncs.tryTeleport(dest)
                    else
                        lib:Notification({
                            Title = 'Failed',
                            Description = 'You don\'t have a plot!',
                            Timeout = 3 
                        }) 
                    end
                end
            })
            
            section:Button({
                Text = 'Home plot - center',
                Tooltip = 'Teleports you to the center of your plot',
                Callback = function() 
                    if ( playerPlot ) then
                        local base = playerPlot.Base
                        local dest = base.CFrame + Vector3.new(0, 3, 0)
                        
                        utilfuncs.tryTeleport(dest)
                    else
                        lib:Notification({
                            Title = 'Failed',
                            Description = 'You don\'t have a plot!',
                            Timeout = 3 
                        }) 
                    end
                end
            })
            
            section:Button({
                Text = 'Goto sellary',
                Tooltip = 'Teleports you to the sellary',
                Callback = function() 
                    utilfuncs.tryTeleport(CFrame.new(-463.4, 5.7, -75.9))
                end
            })
            
            section:Button({
                Text = 'Goto bring location',
                Tooltip = 'Teleports you to the set bring location',
                Callback = function() 
                    utilfuncs.tryTeleport(bringLocation)
                end
            })
        end
        
        --[[local section = tab:Section({
            Text = 'Paint',
            Side = 'Left'
        })
        do
            local material = 'WoodPlank'
            local switch = {
                ['Dark wood'] = 'WoodPlank';
                ['Light wood'] = 'WoodPlank2';
                ['Cobble'] = 'ArCobble';
            }
            do 
                section:Toggle({
                    Text = 'Blueprint paint',
                    Tooltip = 'Lets you click a blueprint to fill it in, has no cost',
                    Callback = function() 
                        
                    end
                })
            end
            
            do 
                local dd = section:Dropdown({
                    Text = 'Material',
                    Tooltip = 'The material that\'s used to fill in blueprints',
                    List = {'Dark wood', 'Light wood', 'Cobble'},
                    Callback = function( t ) 
                        material = switch[t]
                    end
                })
            end
        end]]
        
        local section = tab:Section({
            Text = 'Misc',
            Side = 'Left'
        })
        do
            -- buy land
            do 
                section:Button({
                    Text = 'Buy land',
                    Tooltip = 'Buys as much land as possible',
                    Callback = function() 
                        for i = 1, 12 do 
                            remotes.clientevent:FireServer('LandBuy', i)
                        end
                    end
                })
            end
            
            -- sell items
            do 
                section:Button({
                    Text = 'Sell ores',
                    Tooltip = 'Sells all of your ores that are on the sellary weight',
                    Callback = function() 
                        utilfuncs.tryTeleport(CFrame.new(-456.7, 5.8, -67.8))
                        task.wait(delays.interact_after_teleport)
                        remotes.sellarySell:FireServer()
                        
                        utilfuncs.clickGui(utilfuncs.getYes())
                    end
                })
            end
        end
        
        
        local section = tab:Section({
            Text = 'Dragging',
            Side = 'Left'
        })
        do 
            local speedX, speedY = 5, 1 
            local isEnabled = false 
            
            local grabScript = localPlayer.PlayerGui.Grab
            local bodyVel = grabScript.Vel
            
            section:Toggle({
                Text = 'Custom throw speed',
                Tooltip = 'Changes how far you throw objects',
                Callback = function( enabled ) 
                    isEnabled = enabled
                    
                    if ( enabled ) then
                        bodyVel.MulX.Value = speedX
                        bodyVel.MulY.Value = speedY
                    else
                        bodyVel.MulX.Value = 5
                        bodyVel.MulY.Value = 1
                    end
                end
            })
            
            section:Slider({
                Text = 'Throw X',
                Tooltip = 'How far objects get thrown horizontally',
                Default = 5,
                Minimum = 0,
                Maximum = 200,
                Callback = function( value ) 
                    speedX = value
                    
                    if ( isEnabled ) then
                        bodyVel.MulX.Value = speedX     
                    end
                end
            })
            
            section:Slider({
                Text = 'Throw Y',
                Tooltip = 'How far objects get thrown vertically',
                Default = 1,
                Minimum = 0,
                Maximum = 200,
                Callback = function( value ) 
                    speedY = value
                    
                    if ( isEnabled ) then
                        bodyVel.MulY.Value = speedY    
                    end
                end
            })
        end
    end

    --[[local tab = window:Tab({
        Text = 'Automation',
        Tooltip = 'Some nice automation, like auto mining, auto meteor, and more'
    })
    do 
        local section = tab:Section({
            Text = 'Spawners',
            Side = 'Left'
        })
        do 
        
            --[[ auto trusty
            do 
                local getting = false
                
                section:Button({
                    Text = 'Auto trusty',
                    Tooltip = 'Buys the stuff required and spawns in a trusty pickaxe',
                    Callback = function() 
                        if ( playerCash < 260 ) then
                            lib:Notification({
                                Title = 'Failed',
                                Description = 'Not enough cash!',
                                Timeout = 3 
                            }) 
                            
                            return
                        end
                        
                        if ( getting == true ) then
                            lib:Notification({
                                Title = 'Already running!',
                                Description = 'Wait for auto trusty to finish!',
                                Timeout = 3 
                            }) 
                            
                            return
                        end
                        
                        local plrPurchase = CFrame.new(134.5, 88.7, 1093.6) -- player tp after purchase
                        local pickPurchase = CFrame.new(133.3, 88.7, 1096.3) -- pick tp after purchase
                        local pickFinal = CFrame.new(144.4, 87.1, 1106.7) -- pick tp when finished
                        local plrFinal = CFrame.new(139.0, 88.7, 1095.8) -- player tp when finished
                        
                        getting = true 
                        
                        
                        -- stone
                        local stone = utilfuncs.getStoreItem('Boxed Stone Pickaxe')
                        if ( not stone ) then
                            getting = false
                            lib:Notification({
                                Title = 'Failed',
                                Description = 'Couldn\'t find a stone pickaxe - wait a bit then retry',
                                Timeout = 3 
                            }) 
                            
                            return
                        end
                        
                        local boughtStone = utilfuncs.buyItem(stone) 
                        if ( boughtStone ) then
                            task.wait(2.5)
                            utilfuncs.tryTeleport(plrPurchase)
                            boughtStone:SetPrimaryPartCFrame(pickPurchase)
                            task.wait(0.4)
                        else
                            getting = false 
                            lib:Notification({
                                Title = 'Failed',
                                Description = 'Couldn\'t buy a stone pickaxe for some reason',
                                Timeout = 3 
                            }) 
                            return 
                        end
                        
                        -- rusty
                        local rusty = utilfuncs.getStoreItem('Boxed Rusty Pickaxe')
                        if ( not rusty ) then
                            getting = false
                            lib:Notification({
                                Title = 'Failed',
                                Description = 'Couldn\'t find a rusty pickaxe - wait a bit then retry',
                                Timeout = 3 
                            }) 
                            
                            return
                        end
                        local boughtRusty = utilfuncs.buyItem(rusty) 
                        if ( boughtRusty ) then
                            task.wait(2.5)
                            utilfuncs.tryTeleport(plrPurchase)
                            boughtRusty:SetPrimaryPartCFrame(pickPurchase)
                            task.wait(0.4)
                        else
                            getting = false 
                            lib:Notification({
                                Title = 'Failed',
                                Description = 'Couldn\'t buy a rusty pickaxe for some reason',
                                Timeout = 3 
                            }) 
                            return 
                        end
                        
                        do getting = false return end 
                        
                        -- iron 
                        local iron = utilfuncs.getStoreItem('Boxed Iron Pickaxe')
                        if ( not iron ) then
                            getting = false
                            lib:Notification({
                                Title = 'Failed',
                                Description = 'Couldn\'t find an iron pickaxe - wait a bit then retry',
                                Timeout = 3 
                            }) 
                            
                            return
                        end
                        
                        local boughtIron = utilfuncs.buyItem(iron) 
                        if ( boughtIron ) then
                            utilfuncs.tryTeleport(plrPurchase)
                            boughtIron:SetPrimaryPartCFrame(pickPurchase)
                            task.wait(0.05)
                        else
                            getting = false 
                            lib:Notification({
                                Title = 'Failed',
                                Description = 'Couldn\'t buy an iron pickaxe for some reason',
                                Timeout = 3 
                            }) 
                            return 
                        end
                        
                        
                        getting = false 
                    end
                })
            end]
        end
    end]]

    
    local tab = window:Tab({
        Text = 'Tweaks',
        Tooltip = 'Small QOL tweaks, like fullbright, nofog, norain, and more'
    })
    do 
        local section = tab:Section({
            Text = 'Environment',
            Side = 'Left'
        })
        do  
            -- fullbright
            do 
                local cn
                
                section:Toggle({
                    Text = 'Fullbright',
                    Tooltip = 'Increases brightness - may sometimes flicker',
                    Callback = function( t ) 
                        if ( t ) then 
                            
                            local info = TweenInfo.new(0)
                            local fullbright = { 
                                Ambient = Color3.new(0.8, 0.8, 0.8);
                                Brightness = 3; 
                            }
                            
                            cn = runService.Stepped:Connect(function()
                                tweenService:Create(lightingService, info, fullbright):Play()
                            end)
                        else
                            cn:Disconnect()
                        end
                    end
                })
            end
            
            -- nofog 
            do 
                local cn
                
                section:Toggle({
                    Text = 'Nofog',
                    Tooltip = 'Removes all lighting fog - may sometimes flicker',
                    Callback = function( t ) 
                        if ( t ) then 
                            
                            local info = TweenInfo.new(0)
                            local nofog = { 
                                FogEnd = 9e7;
                                FogStart = 9e5;
                                FogColor = Color3.new(0.8, 0.8, 0.8);
                            }
                            
                            cn = runService.Stepped:Connect(function()
                                tweenService:Create(lightingService, info, nofog):Play()
                            end)
                        else
                            cn:Disconnect()
                        end
                    end
                })
            end
            
            -- no blur  
            do 
                local disableCn
                
                section:Toggle({
                    Text = 'No blur',
                    Tooltip = 'Disables the water blur',
                    Callback = function( t ) 
                        if ( t ) then 
                            local blur = lightingService.WaterBlur
                            
                            disableCn = runService.Stepped:Connect(function()
                                blur.Enabled = false 
                            end)
                        else
                            disableCn:Disconnect()
                        end
                    end
                })
            end
            
            -- norain  
            do 
                local changeCn
                
                section:Toggle({
                    Text = 'No rain',
                    Tooltip = 'Disables rain immediately once it starts',
                    Callback = function( t ) 
                        if ( t ) then 
                            local rain = workspace.Raining
                            
                            if ( rain.Value == true ) then
                                rain.Value = false
                            end
                            
                            changeCn = rain.Changed:Connect(function()
                                rain.Value = false 
                            end)
                        else
                            changeCn:Disconnect()
                        end
                    end
                })
            end
        end
        
        local section = tab:Section({
            Text = 'Enhancements',
            Side = 'Right'
        })
        do 
            local remote = repStorage.Events.DecreaseRad
            local cns = {}
            
            section:Toggle({
                Text = 'Infinite oxygen',
                Tooltip = 'Lets you stay underwater without losing oxygen',
                Callback = function( t ) 
                    if ( t ) then
                        local function cb() 
                            local upvalueFunc
                        
                            for a, cn in ipairs( getconnections(remote.OnClientEvent) ) do 
                                local fn = cn.Function 
                                if ( fn ) then
                                    -- currently bound connection
                                    upvalueFunc = fn 
                                    break
                                end
                            end
                            
                            if ( upvalueFunc ) then
                                cns.Respawn = runService.Heartbeat:Connect(function() 
                                    setupvalue(upvalueFunc, 1, 0)
                                end)
                            else
                                lib:Notification({
                                    Title = 'Inf Oxygen',
                                    Description = 'Failed to find a required function :( - try again in a bit',
                                    Timeout = 3 
                                }) 
                            end
                        end
                        
                        cns.Update = localPlayer.CharacterAdded:Connect(function() 
                            task.wait(3)
                            cb()
                            
                            lib:Notification({
                                Title = 'Inf Oxygen',
                                Description = 'Reactivated!',
                                Timeout = 3 
                            }) 
                        end)
                        
                        cb()
                    else
                        if ( cns.Respawn ) then 
                            cns.Respawn:Disconnect()
                        end
                        if ( cns.Update ) then 
                            cns.Update:Disconnect()
                        end
                    end
                end
            })
            
            -- SLAP IT UP!
        end
    end
    
    local tab = window:Tab({
        Text = 'Movement',
        Tooltip = 'Mods to help you get around faster'
    })
    do 
        -- speed
        local section = tab:Section({
            Text = 'Speed',
            Side = 'Left'
        })
        do 
            local speed = 3
            local cn
            
            local toggle = section:Toggle({
                Text = 'Enable',
                Tooltip = 'Makes you walk insanely fast',
                Callback = function( t ) 
                    if ( t ) then
                        cn = runService.Heartbeat:Connect(function( delta ) 
                            if ( not localRoot ) then
                                return
                            end
                            
                            localRoot.CFrame += localHum.MoveDirection * ( delta * speed * 25 ) 
                        end)
                    else
                        cn:Disconnect() 
                    end
                end
            })
            
            section:Slider({
                Text = 'Amount',
                Tooltip = 'How fast you move when Speed is enabled',
                Default = 3,
                Minimum = 1,
                Maximum = 20,
                Callback = function( value ) 
                    speed = value
                end
            })
            
            section:Keybind({
                Text = 'Keybind',
                Unbindable = true,
                Callback = function() 
                    toggle:Toggle()
                end
            })
        end
        
        -- noclip 
        local section = tab:Section({
            Text = 'Noclip',
            Side = 'Right'
        })
        do 
            local noclip = false
            local noclipCn
            local floatCn
            
            local toggle = section:Toggle({
                Text = 'Enable',
                Tooltip = 'Lets you walk through walls',
                Callback = function( thistoggleisnowenabled ) 
                    noclip = thistoggleisnowenabled
                    if ( thistoggleisnowenabled ) then
                        noclipCn = runService.Stepped:Connect(function( delta ) 
                            if ( not localChar ) then
                                return
                            end
                            
                            -- assuming refinery caves never switches from R6
                            localChar.Head.CanCollide = false 
                            localChar.Torso.CanCollide = false 
                        end)
                    else -- thistoggleisnotenabled :(
                        noclipCn:Disconnect() 
                    end
                end
            })
            
            section:Toggle({
                Text = 'Legacy',
                Tooltip = 'Emulates the older HumanoidState noclip that was patched by making you float',
                Callback = function( tog ) 
                    if ( tog ) then
                        local ids = {
                            ['http://www.roblox.com/asset/?id=180426354'] = true, 
                            ['http://www.roblox.com/asset/?id=180435571'] = true
                        }
                        
                        floatCn = runService.Heartbeat:Connect(function() 
                            if ( ( localChar == nil ) or ( noclip == false )) then
                                return
                            end
                            
                            local vel = localRoot.AssemblyLinearVelocity
                            localRoot.AssemblyLinearVelocity = Vector3.new(vel.X, 2.058888, vel.Z)
                            
                            for i, v in ipairs( localHum:GetPlayingAnimationTracks() ) do
                                if ( ids[v.Animation.AnimationId] ) then
                                    continue
                                end 
                                 
                                v:Stop()
                            end
                        end)
                    else
                        floatCn:Disconnect() 
                    end
                end
            })
            
            section:Keybind({
                Text = 'Keybind',
                Unbindable = true,
                Callback = function() 
                    toggle:Toggle()
                end
            })
        end
        
        -- vehicle speed
        local section = tab:Section({
            Text = 'Vehicle speed',
            Side = 'Left'
        })
        do 
            local speed = 3
            local cn
                        
            local toggle = section:Toggle({
                Text = 'Enable',
                Tooltip = 'Makes your car move weird',
                Callback = function( t ) 
                    if ( t ) then
                        
                        cn = runService.Heartbeat:Connect(function( delta ) 
                            if ( not playerVehicle ) then
                                return
                            end
                            
                            local stuffToAdd = localHum.MoveDirection * ( delta * speed * 25 )
                            local currentCFrame = (playerVehicle:GetPivot() + stuffToAdd).Position
                            
                            local LV = localCam.CFrame.LookVector
                            local newCFrame = CFrame.new(currentCFrame, currentCFrame + Vector3.new(LV.X, 0, LV.Z))
                            
                            playerVehicle:SetPrimaryPartCFrame(newCFrame)
                        end)
                    else
                        cn:Disconnect() 
                    end
                end
            })
            
            section:Slider({
                Text = 'Amount',
                Tooltip = 'How fast your car drives',
                Default = 3,
                Minimum = 1,
                Maximum = 20,
                Callback = function( value ) 
                    speed = value
                end
            })
            
            section:Keybind({
                Text = 'Keybind',
                Unbindable = true,
                Callback = function() 
                    toggle:Toggle()
                end
            })
        end
        
        --[[ flight
        local section = tab:Section({
            Text = 'Flight',
            Side = 'Right'
        })
        do 
            local speed = 3
            local flightCn
            local keyAscension = Enum.KeyCode.Z 
            local keyDescension = Enum.KeyCode.C 
            
            local toggle = section:Toggle({
                Text = 'Enable',
                Tooltip = 'Lets you fly',
                Callback = function( t ) 
                    if ( t ) then
                        flightCn = runService.Heartbeat:Connect(function( delta ) 
                            if ( not localRoot ) then
                                return
                            end
                            
                            localRoot.CFrame += localHum.MoveDirection * ( delta * speed * 25 ) 
                        end)
                    else
                        flightCn:Disconnect() 
                    end
                end
            })
            
            section:Slider({
                Text = 'Amount',
                Tooltip = 'How fast you fly',
                Default = 3,
                Minimum = 1,
                Maximum = 20,
                Callback = function( value ) 
                    speed = value
                end
            })
            
            do
                local keyLabel
                
                section:Button({
                    Text = 'Set ascension key',
                    Callback = function() 
                        keyLabel:SetText('Press any key...')
                        local kc, kt = utilfuncs.getHotkey(true)
                        keyLabel:SetText('Current key: ' .. kc.Name )
                        task.wait()
                        keyType = kt 
                        keyCode = kc
                    end
                })
                keyLabel = section:Label({
                    Text = 'Current key: Z'
                })
            end
            
            section:Keybind({
                Text = 'Keybind',
                Unbindable = true,
                Callback = function() 
                    toggle:Toggle()
                end
            })
        end]]
        
        -- key tp
        local section = tab:Section({
            Text = 'Key TP',
            Side = 'Left'
        })
        do 
            local clickCn
            local keyCode = Enum.KeyCode.T 
            local keyType = 'KeyCode'
            local ctrlReq = false 
            
            local toggle = section:Toggle({
                Text = 'Enable',
                Tooltip = 'Teleports you to your cursor when you press a certain key',
                Callback = function( t )
                    if ( t ) then
                        local function tp() 
                            if ( ctrlReq == true and inputService:IsKeyDown('LeftControl') == false ) then
                                return  
                            end
                            
                            local raycast = utilfuncs.raycastMouse()
                            
                            local curCf = localRoot.CFrame 
                            local destPos = raycast and (raycast.Position + Vector3.new(0, 3, 0))
                            
                            local newCf = CFrame.new(destPos, destPos + curCf.LookVector)
                            utilfuncs.tryTeleport(newCf)
                        end
                        
                        clickCn = inputService.InputBegan:Connect(function(inp, gpe) 
                            if ( gpe ) then
                                return
                            end
                            
                            if ( keyType == 'KeyCode' ) then
                                if ( inp.KeyCode == keyCode ) then
                                    tp() 
                                end
                            elseif ( keyType == 'UserInputType' ) then
                                if ( inp.UserInputType == keyCode ) then
                                    tp()  
                                end
                            end
                        end)
                    else
                        clickCn:Disconnect()  
                    end
                end
            })
            
            section:Toggle({
                Text = 'Control required',
                Tooltip = 'Requires you to hold down CTRL when teleporting',
                Callback = function( t ) 
                    ctrlReq = t 
                end
            })
            
            do
                local keyLabel
                
                section:Button({
                    Text = 'Set key',
                    Callback = function() 
                        keyLabel:SetText('Press any key...')
                        local kc, kt = utilfuncs.getHotkey(true)
                        keyLabel:SetText('Current key: ' .. kc.Name )
                        task.wait()
                        keyType = kt 
                        keyCode = kc
                    end
                })
                keyLabel = section:Label({
                    Text = 'Current key: T'
                })
            end
            
            section:Keybind({
                Text = 'Keybind',
                Unbindable = true,
                Callback = function() 
                    toggle:Toggle()
                end
            })
        end
    end
    
    local tab = window:Tab({
        Text = 'Teleports',
        Tooltip = 'Teleports to nearly every location'
    })
    do 
        local Stores = {
            ['Dealership'] = CFrame.new(701.2, 8.3, -997.2); -- Dealership
            ['Electronics'] = CFrame.new(-106.2, 240.0, 1123.3); -- Electronic shop
            ['Furniture'] = CFrame.new(-1018.1, 4.3, 706.5); -- Furniture shop 
            ['Land Agency'] = CFrame.new(-1007.9, 4.3, -723.1); -- Land agency
            ['Pickaxe Store'] = CFrame.new(740.2, 2.2, 59.5); -- Pickaxe shop 
            ['Sellary'] = CFrame.new(-463.4, 5.7, -75.9); -- Sellary shopkeep
            ['UCS'] = CFrame.new(-989.4, 4.3, -624.7); -- UCS general store 
            ['Utility Shop'] = CFrame.new(-473.1, 5.7, -6.9); -- Utility store
        } 
        
        local Secrets = {
            ['Bowl Room'] = CFrame.new(484.2, 300.6, 709.9); -- Meteorite Bowl Room
            ['Meteorite Shop'] = CFrame.new(-3479.3, 17.2, 1044.3); -- Meteorite Totem
            ['Trusty Pick'] = CFrame.new(131.7, 88.7, 1079.6); -- Trusty pick room
            ['Halloween Room'] = CFrame.new(783.5, 414.7, 1398.6) -- Halloween room 
        }
        
        local Caves = {
            ['Cloudnite Quarry'] = CFrame.new(571.4, 431.7, 1049.3); -- Cloudnite quarry
            ['Crystal Cave'] = CFrame.new(1312.5, -197.8, 1052.0); -- Crystal Cave
            ['Emerald Quarry'] = CFrame.new(477.7, 273.7, 208.4); -- Emerald Cave
            ['Gold / Silver Quarry'] = CFrame.new(542.6, 3.7, -1500.2); -- Gold / Silver quarry
            ['Marble Quarry'] = CFrame.new(425.8, 3.7, -1005.1); -- Marble quarry
            ['Purple Cave'] = CFrame.new(1722.1, -6.8, -117.8); -- Purple Cave
            ['Sunstone Cave'] = CFrame.new(1015.0, 254.1, 73.5); -- Sunstone Cave
            ['Volcanium / Obsidian Cave'] = CFrame.new(-2868.6, -775.8, 2780.4); -- Volcanium / Obsidian cave
        }

        local Misc = {
            ['Bloxxy Cola'] = CFrame.new(-1224.9, 78.7, -92.5); -- Bloxxy cola
            ['Mountain Chair'] = CFrame.new(612.4, 993.2, 1520.0); -- Chair
            ['Railway'] = CFrame.new(-171.1, 195.2, 505.6); -- Railway
            ['Ravine Skeleton'] = CFrame.new(-1153.8, 66.0, 21.8); -- Skeleton
            ['Secret Shack'] = CFrame.new(-475.4, 4.3, -658.5); -- Secret Shack
        }
        
        local section = tab:Section({
            Text = 'Plots',
            Side = 'Right'
        })
        do 
            section:Button({
                Text = 'Home plot',
                Tooltip = 'Teleports you to your plot',
                Callback = function() 
                    if ( playerPlot ) then
                        local base = playerPlot.Base
                        local dest = ( base.CFrame - ( base.Size / 1.5 ) ) + Vector3.new(0, 3, 0)
                        
                        utilfuncs.tryTeleport(dest)
                    else
                        lib:Notification({
                            Title = 'Failed',
                            Description = 'You don\'t have a plot!',
                            Timeout = 3 
                        }) 
                    end
                end
            })
            
            section:Button({
                Text = 'Home plot - center',
                Tooltip = 'Teleports you to the center of your plot',
                Callback = function() 
                    if ( playerPlot ) then
                        local base = playerPlot.Base
                        local dest = base.CFrame + Vector3.new(0, 3, 0)
                        
                        utilfuncs.tryTeleport(dest)
                    else
                        lib:Notification({
                            Title = 'Failed',
                            Description = 'You don\'t have a plot!',
                            Timeout = 3 
                        }) 
                    end
                end
            })
        end
        
        local section = tab:Section({
            Text = 'Stores',
            Side = 'Left'
        })
        do 
            for n, c in pairs( Stores ) do 
                section:Button({
                    Text = n,
                    Callback = function() 
                        utilfuncs.tryTeleport(c)
                    end
                })
            end
        end
        
        local section = tab:Section({
            Text = 'Caves / Quarries',
            Side = 'Right'
        })
        do 
            for n, c in pairs( Caves ) do 
                section:Button({
                    Text = n,
                    Callback = function() 
                        utilfuncs.tryTeleport(c)
                    end
                })
            end
        end
        
        local section = tab:Section({
            Text = 'Secrets',
            Side = 'Left'
        })
        do 
            for n, c in pairs( Secrets ) do 
                section:Button({
                    Text = n,
                    Callback = function() 
                        utilfuncs.tryTeleport(c)
                    end
                })
            end
        end
        
        local section = tab:Section({
            Text = 'Misc',
            Side = 'Right'
        })
        do 
            for n, c in pairs( Misc ) do 
                section:Button({
                    Text = n,
                    Callback = function() 
                        utilfuncs.tryTeleport(c)
                    end
                })
            end
        end
        
        --- ore teleports 
        --CFrame.new(-430.2, 6.5, -70.2) -- Sellary
        --CFrame.new(490.5, 304.7, 711.1) -- Bowl CF
    end
    
    --[[local tab = window:Tab({
        Text = 'Waits',
        Tooltip = 'Primarily used for debugging - lets you configure how long to wait for certain actions'
    })
    do 
        local section = tab:Section({
            Text = 'Waits',
            Side = 'Left'
        })
        do 
            for n, c in pairs( delays ) do 
                section:Slider({
                    Text = n,
                    Default = c * 100,
                    Minimum = 0,
                    Maximum = 1000,
                    Callback = function(v) 
                        delays[n] = v / 100 
                    end
                })
            end
        end
    end]]
end

lib:Notification({
    Title = 'Loaded Trusty GUI ' .. GUIVER,
    Description = 'Welcome, ' .. localPlayer.Name ,
    Timeout = 3 
}) 
