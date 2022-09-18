local lighting = game:GetService('Lighting')

lighting:ClearAllChildren()

lighting.Ambient = Color3.fromRGB(2, 2, 2)
lighting.Ambient = Color3.fromRGB(5, 5, 5)
lighting.Brightness = 2.25
lighting.ClockTime = 15
lighting.EnvironmentDiffuseScale = 0.2
lighting.EnvironmentSpecularScale = 0.2 
lighting.ExposureCompensation = 0.5
lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
lighting.ShadowColor = Color3.fromRGB(180, 180, 181)
lighting.ShadowSoftness = 0.2 


local bloom = Instance.new('BloomEffect')
bloom.Intensity = 0.5
bloom.Size = 120
bloom.Threshold = 1.5 
bloom.Parent = lighting 

local blur = Instance.new('BlurEffect')
blur.Size = 2.5 
blur.Parent = lighting

local correction = Instance.new('ColorCorrectionEffect')
correction.Brightness = 0.02
correction.Contrast = 0.08
correction.Saturation = 0.8
correction.TintColor = Color3.fromRGB(250, 228, 209)
correction.Parent = lighting 

local sunrays = Instance.new('SunRaysEffect')
sunrays.Intensity = 0.15
sunrays.Spread = 1 
sunrays.Parent = lighting 

local atmosphere = Instance.new('Atmosphere')
atmosphere.Color = Color3.fromRGB(200, 175, 175)
atmosphere.Decay = Color3.fromRGB(160, 160, 160)
atmosphere.Density = 0.28
atmosphere.Glare = 0.22
atmosphere.Haze = 1.4
atmosphere.Offset = 0.3
atmosphere.Parent = lighting 

local sky = Instance.new('Sky')
sky.Parent = lighting

sethiddenproperty(lighting, 'Technology', Enum.Technology.Future)
