local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/RandomAdamYT/DarkHub_V3/main/UILIB",true))()
local main = lib:Window()
local Aimbot = main:Tab('Aimbot')
local GunMods = main:Tab('Gun Mods')
local Esp = main:Tab('Esp')
local Misc = main:Tab('Miscellaneous')
local FovCircle = Drawing.new("Circle")
FovCircle.Visible = Client.Toggles.UseFov
FovCircle.Radius = Client.Values.Fov
FovCircle.Color = Color3.new(1, 1, 1)
FovCircle.Thickness = 1
FovCircle.Position = Vector2.new(workspace.Camera.ViewportSize.X * 0.5, workspace.Camera.ViewportSize.Y * 0.5)

local whitelistedcharacters = "abcdefghijklmnopqrstuvwxyz"

local found = {}
local hashes = {}
for i, v in pairs(getnilinstances()) do
    if v.ClassName == "ModuleScript" and (v.Name == "effects" or v.Name == "camera" or v.Name == "particle") then
        found[v.Name] = require(v)
    end
end

for i, v in pairs(getgc(false)) do
    if getinfo(v).name == "loadgun" then
        getgenv()["loadgun"] = v
        break
    end
end

found["network"] = debug.getupvalue(found.effects.breakwindow, 1)
found["char"] = debug.getupvalue(found.effects.muzzleflash, 2)
found["replication"] = debug.getupvalue(found.camera.setspectate, 1)
found["hud"] = debug.getupvalue(found.char.setmovementmode, 10)
found["gamelogic"] = debug.getupvalue(found.char.setsprint, 1)
found["input"] = debug.getupvalue(found.gamelogic.controllerstep, 2)
local gunsway = debug.getupvalue(found.char.loadgrenade, 34)
local gunbob = debug.getupvalue(found.char.loadgrenade, 33)
local gunrequire = debug.getupvalue(loadgun, 2)
local fromaxisangle = debug.getupvalue(found.camera.step, 11)
local physicsignore = {workspace.Players, workspace.Camera, workspace.Ignore}
local userinputservice = game:GetService("UserInputService")
local runservice = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local localplayer = players.LocalPlayer
local rendertime = tick()
local playeresp = {}
local v3 = Vector3.new()
local newcf = CFrame.new()
local dot = v3.Dot
local accel = Vector3.new(0, -workspace.Gravity, 0)
local badtick, add, reset = tick(), 0, true

for i, v in pairs(found) do
    getgenv()[i] = v

    for o, b in pairs(v) do
        if not getgenv()[o] and type(b) == "function" then
            getgenv()[o] = b
        end
    end
end
local chartable = debug.getupvalue(getbodyparts, 1)
setreadonly(particle, false)

--Framework under this along with ui elements

Aimbot:Toggle('Silent Aim', function(state)
    Client.Toggles.SilentAim = state
end,Client.Toggles.SilentAim)

Aimbot:Toggle('Visible Check', function(state)
    Client.Toggles.VisibleCheck = state
end,Client.Toggles.VisibleCheck)

Aimbot:Toggle('Head Shots Only', function(state)
    Client.Toggles.Head = state
end,Client.Toggles.Head)

Aimbot:Toggle('Use Fov', function(state)
    Client.Toggles.UseFov = state
    FovCircle.Visible = state
end,Client.Toggles.UseFov)

Aimbot:Slider("Fov", 1, 1000, function(num)
    Client.Values.Fov = num
    FovCircle.Radius = num
end,Client.Values.Fov)
