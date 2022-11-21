local Toggle1 = Section1:CreateToggle("Aimbot", Settings.Enabled, function(State)
    Settings.Enabled = State
end)

local Dropdown1 = Section1:CreateDropdown("HitPart", {"Torso","Head"}, function(String)
	Settings.AimPart = String
end)

local Slider2 = Section1:CreateSlider("Aimbot Smoothness", 0,10,Settings.Smoothness,false, function(Value)
    Settings.Smoothness = Value
end)

local Toggle1 = Section1:CreateToggle("WallCheck",Settings.WallCheck, function(State)
    Settings.WallCheck = State
end)


local Toggle1 = Section1:CreateToggle("TriggerBot", Settings.Tigger, function(State)
    Settings.Tigger = State
end)

local Slider2 = Section1:CreateSlider("Aimbot Radius", 0,1000, Settings.FOV, false, function(Value)
    Settings.FOV = Value
    Circle.Radius = Settings.FOV
end)

local Toggle1 = Section1:CreateToggle("Circle Visible", Settings.Visible, function(State)
   Circle.Visible = State
end)

local Colorpicker3 = Section1:CreateColorpicker("Circle Color", function(Color)
    Circle.Color = Color
end)
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/1201for/dragonadventures/main/Esp-Test"))()

local Toggle1 = Section1:CreateToggle("Enable Esp", Settings.Esp, function(State)
    Settings.Esp = State
    ESP:Toggle(Settings.Esp)
    
end)
