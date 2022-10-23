-- Trusty GUI v1.0.0
-- Made by topit 

if ( game.PlaceId ~= 8726743209 ) then
    return messagebox('Wrong game!', 'Oopsies', 0)
end

local inputServ = game:GetService('UserInputService')
local playerServ = game:GetService('Players')
local runServ = game:GetService('RunService')
local vimServ = game:GetService('VirtualInputManager')

local repStorage = game:GetService('ReplicatedStorage')

local GUIVER = 'v1.0.0'

-- // Variables that do stuff 
local localPlayer = playerServ.LocalPlayer
local localChar = localPlayer.Character 
local localRoot = localChar and localChar:FindFirstChild('HumanoidRootPart')
local localHum = localChar and localChar:FindFirstChild('Humanoid')

local localMouse = localPlayer:GetMouse()
local localCam = workspace.CurrentCamera

local remotes = {
    clientevent = repStorage.Events.ClientEvent;
    sell = workspace.Map.Sellary.Keeper.IPart.Interact;
}

local grabbable = workspace.Grabable
local ignore = workspace.MouseIgnore

local signals = {}

local playerPlotPointer = localPlayer.Values.Plot
local playerPlot = playerPlotPointer.Value 

local playerVehicle = nil 

-- Functions that do stuff
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Blacklist
params.FilterDescendantsInstances = { ignore, localChar }

local utilfuncs = {} 
function utilfuncs.tryTeleport( destination: CFrame ) 
    if ( playerVehicle ) then
        playerVehicle:SetPrimaryPartCFrame(destination + Vector3.new(0, 1, 0))
        playerVehicle.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
    else
        localRoot.CFrame = destination
    end
end

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

    vimServ:SendMouseButtonEvent(x, y, 0, true, game, 0) -- mouse1 down at x, y once
    task.wait()
    vimServ:SendMouseButtonEvent(x, y, 0, false, game, 0)  -- mouse1 up at x, y once
end

function utilfuncs.getYes() 
    local dialog = localPlayer.PlayerGui.UserGui.Dialog
    task.wait(0.5)
    local yes = dialog:WaitForChild('Yes', 1)
    if ( yes ) then
        if ( yes.AbsolutePosition.X == 0 ) then
            task.wait(0.5)
            yes = dialog:WaitForChild('Yes', 1)
        end
    end
    
    return yes 
end

function utilfuncs.sellItems() 
    utilfuncs.tryTeleport(CFrame.new(-456.7, 5.8, -67.8))
    task.wait()
    remotes.sell:FireServer()
    
    utilfuncs.clickGui(utilfuncs.getYes())
end

function utilfuncs.raycastMouse() 
    local mouseLoc = inputServ:GetMouseLocation()
    local unitRay = localCam:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
    local raycast = workspace:Raycast(unitRay.Origin, unitRay.Direction * 99999, params)
    
    return raycast and raycast.Instance 
end

function utilfuncs.buyItem( instance: Instance ) 
    local startCFrame = localRoot.CFrame 
    local startPos = localRoot.Position
    
    local instanceCFrame = instance:GetPivot()
    
    if ( ( instance:GetPivot().Position - startPos ).Magnitude > 25 ) then -- too far away, teleport to it 
        utilfuncs.tryTeleport(instanceCFrame)
        task.wait(0.1)
    end
    
    local shop = instance.Shop.Value.Parent.Parent 
    local register = utilfuncs.getClosestRegister(shop)
    
    if ( register ) then
        local counter = register.Counter.Counter 
        local buy = register.Worker.IPart.Interact
        
        instance:SetPrimaryPartCFrame(counter.CFrame + Vector3.new(0, 2, 0))
        utilfuncs.tryTeleport(counter.CFrame + counter.Size)
        task.wait(0.2)
        buy:FireServer()
        utilfuncs.clickGui(utilfuncs.getYes())
        
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

-- Update the stuff for the stuff  
signals['*PlotUpd'] = playerPlotPointer.Changed:Connect(function( value )
    playerPlot = value
end)

signals['CharAdd'] = localPlayer.CharacterAdded:Connect(function( newChar ) 
    localChar = newChar
    localRoot = newChar:WaitForChild('HumanoidRootPart')
    localHum = newChar:WaitForChild('Humanoid')
    
    params.FilterDescendantsInstances = { ignore, newChar }
    
    signals['CarUpd'] = localHum:GetPropertyChangedSignal('SeatPart'):Connect(utilfuncs.seatUpdate)
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
                    Text = 'Click buy',
                    Tooltip = 'Lets you click on a store item to instantly buy and bring it',
                    Callback = function( ns ) 
                        if ( ns ) then
                            inputCn = localMouse.Button1Down:Connect(function() 
                                local part = utilfuncs.raycastMouse()
                                
                                if ( part ) then
                                    local item = part.Parent 
                                    
                                    if ( item:FindFirstChild('Link') and item:FindFirstChild('Shop') ) then
                                        local boughtItem = utilfuncs.buyItem(item) 
                                        if ( boughtItem == item ) then
                                            item:SetPrimaryPartCFrame(bringLocation)
                                        end
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
                                local part = utilfuncs.raycastMouse()
                                
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
                                local part = utilfuncs.raycastMouse()
                                
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
                                local part = utilfuncs.raycastMouse()
                                
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
                        local dest = base.CFrame + ( base.Size / 1.5 ) + Vector3.new(0, 3, 0)
                        
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
                        utilfuncs.sellItems()
                    end
                })
            end
        end
        
        
        local section = tab:Section({
            Text = 'Movement',
            Side = 'Right'
        })
        do 
            -- speed
            do 
                local speed = 3
                section:Slider({
                    Text = 'Speed amount',
                    Tooltip = 'How fast you move when Speed is enabled',
                    Default = 3,
                    Minimum = 1,
                    Maximum = 20,
                    Callback = function( value ) 
                        speed = value
                    end
                })
                
                local cn
                section:Toggle({
                    Text = 'Speed',
                    Tooltip = 'Makes you move faster',
                    Callback = function( t ) 
                        if ( t ) then
                            cn = runServ.Heartbeat:Connect(function( delta ) 
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
            end
        end
        -- clicktp, fly?, speed, noclip
        
        
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
        Tooltip = 'Some nice automation, like auto mining, auto farming money, and more'
    })
    do 
        
    end]]

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
        }
        
        local Caves = {
            ['Cloudnite Quarry'] = CFrame.new(571.4, 431.7, 1049.3); -- Cloudnite quarry
            ['Crystal Cave'] = CFrame.new(1312.5, -197.8, 1052.0); -- Crystal Cave
            ['Emerald Quarry'] = CFrame.new(477.7, 273.7, 208.4); -- Emerald Cave
            ['Gold / Silver Quarry'] = CFrame.new(542.6, 3.7, -1500.2); -- Gold / Silver quarry
            ['Marble Quarry'] = CFrame.new(425.8, 3.7, -1005.1); -- Marble quarry
            ['Purple Cave'] = CFrame.new(1722.1, -6.8, -117.8); -- Purple Cave
            ['Sunstone Quarry'] = CFrame.new(1015.0, 254.1, 73.5); -- Sunstone Cave
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
                Text = 'Goto your plot',
                Tooltip = 'Teleports you to your plot',
                Callback = function() 
                    if ( playerPlot ) then
                        local base = playerPlot.Base
                        local dest = base.CFrame + ( base.Size / 1.5 ) + Vector3.new(0, 3, 0)
                        
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
        Text = 'Tweaks',
        Tooltip = 'Small QOL tweaks, like fullbright, nofog, norain, and more'
    })]]
end

lib:Notification({
    Title = 'Loaded Trusty GUI ' .. GUIVER,
    Description = 'Welcome, ' .. localPlayer.Name ,
    Timeout = 3 
}) 
