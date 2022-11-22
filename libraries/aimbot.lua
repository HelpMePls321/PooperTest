-- start
local version = "1.1";

local username = "HelpMePls321";
local repository = "PooperTest";
local baseUrl = "https://raw.githubusercontent.com/" .. username .. "/" .. repository .. "/main/";

local function import(file)
    return game:HttpGet(baseUrl .. file);
end

local function loadLibrary(library)
    return loadstring(import("libraries/" .. library .. ".lua"))();
end

-- libraries
local library = loadLibrary("ui");
local espLibrary = loadLibrary("esp");
local aimbotLibrary = loadLibrary("aimbot")
local hooksLibrary = loadLibrary("hooks")

-- modules
local sharedRequire = getrenv().shared.require;
local replicationInterface = sharedRequire("ReplicationInterface");

-- framework
local framework = {}; do
    
end

-- combat
AimbotSection:NewToggle("Enabled", "", function(state)
    if state then
        FOVringList = {}
        abLoop = rs.RenderStepped:Connect(function()
            for i,v in pairs(FOVringList) do
                v:Remove()
            end
            
            FOVringList = {}
            
            local FOVring = Drawing.new("Circle")
            FOVring.Visible = true
            FOVring.Thickness = 2
            FOVring.Radius = fov / workspace.CurrentCamera.FieldOfView
            FOVring.Transparency = 1
            FOVring.Color = AbColor
            FOVring.Position = game.Workspace.CurrentCamera.ViewportSize/2
            
            FOVringList[#FOVringList+1] = FOVring
            
            local team = getTeam()
            
            local target = Vector2.new(math.huge, math.huge)
            local targetPos
            local targetPlayer
            if game.Workspace.Players:FindFirstChild(team) then
                for i,v in pairs(game.Workspace.Players:FindFirstChild(team):GetChildren()) do
                    local pos = v[abTargetPart].Position
                    local ScreenSpacePos, IsOnScreen = game.Workspace.CurrentCamera:WorldToViewportPoint(pos)
                    ScreenSpacePos = Vector2.new(ScreenSpacePos.X, ScreenSpacePos.Y) - game.Workspace.CurrentCamera.ViewportSize/2
                    
                    if IsOnScreen and ScreenSpacePos.Magnitude < target.Magnitude and (isPointVisible(v, maxWalls) or not wallCheck) then
                        target = ScreenSpacePos
                        targetPos = pos
                        targetPlayer = v
                    end
                end
            end
            
            if target.Magnitude <= fov / workspace.CurrentCamera.FieldOfView and uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                if target ~= Vector2.new(math.huge, math.huge) then
                    mousemoverel(target.X/smoothing, target.Y/smoothing)
                end
            end
        end)
    else
        abLoop:Disconnect()
        for i,v in pairs(FOVringList) do
            v:Remove()
        end
    end
end)
AimbotSection:NewToggle("Wall Check", "", function(state) wallCheck = state end)
AimbotSection:NewSlider("Max Wallbangs", "Inclusive", 50, 0, function(s) maxWalls = s end)
AimbotSection:NewSlider("Fov", "", 50000, 500, function(s) fov = s end)
AimbotSection:NewSlider("Smoothing", "", 300, 100, function(s) smoothing = s/100 end)
AimbotSection:NewDropdown("Target Part", "", {"Head", "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}, function(currentOption) abTargetPart = currentOption end)





local saTargetPart = "Head"
local safov = 500
local panicMode = false
local panicDistance = 5
local saWallCheck = false
local saWallBangs = 0
local gunCF
local motor
local sa = false
local saFovRingList = {}

saLoop = rs.RenderStepped:Connect(function()
    for i,v in pairs(saFovRingList) do
        v:Remove()
    end
      
    saFovRingList = {}
    if not sa then return end        
    local FOVring = Drawing.new("Circle")
    FOVring.Visible = true
    FOVring.Thickness = 2
    FOVring.Radius = safov / workspace.CurrentCamera.FieldOfView
    FOVring.Transparency = 1
    FOVring.Color = AbColor
    FOVring.Position = game.Workspace.CurrentCamera.ViewportSize/2
            
    saFovRingList[#saFovRingList+1] = FOVring
    
    local team = getTeam()
    
    local targetPos
    local last = Vector2.new(math.huge, math.huge)
    if game.Workspace.Players:FindFirstChild(team) then
        for i,v in pairs(game.Workspace.Players:FindFirstChild(team):GetChildren()) do
            local pos = v[saTargetPart].Position
            local ScreenSpacePos, IsOnScreen = game.Workspace.CurrentCamera:WorldToViewportPoint(pos)
            ScreenSpacePos = Vector2.new(ScreenSpacePos.X, ScreenSpacePos.Y) - game.Workspace.CurrentCamera.ViewportSize/2
            
            if (v[saTargetPart].Position - Workspace.CurrentCamera.CFrame.Position).Magnitude <= panicDistance and panicMode then
                targetPos = pos
                break
            end
                    
            if IsOnScreen and ScreenSpacePos.Magnitude < last.Magnitude and ScreenSpacePos.Magnitude <= (safov / workspace.CurrentCamera.FieldOfView) and (isPointVisible(v, saWallBangs) or not saWallCheck) then
                last = ScreenSpacePos
                targetPos = pos
            end
        end
    end
    if targetPos then
        motor = Workspace.CurrentCamera:GetChildren()[3].Trigger.Motor6D
        local cf = motor.C0
                
        local cf2 = CFrame.new(motor.Part0.CFrame:ToWorldSpace(cf).Position, targetPos)
        gunCF = motor.Part0.CFrame:ToObjectSpace(cf2)
    else
        gunCF = nil
        motor = nil
    end
end)
local OldIndex
OldIndex = hookmetamethod(game, "__newindex", newcclosure(function(...)
    local Self, Key, Value = ...

    if sa and motor and gunCF and Self == motor and Key == "C0" then
        return OldIndex(Self, Key, gunCF)
    end

    return OldIndex(...)
end))

-- visuals
do
    function espLibrary._getCharacter(player)
        local entry = replicationInterface.getEntry(player);
        local thirdPersonObject = entry and entry:getThirdPersonObject();
        local character = thirdPersonObject and thirdPersonObject:getCharacterModel();
        return character, character and character:FindFirstChild("Torso");
    end

    function espLibrary._getPlayerFromCharacter(character)
        return replicationInterface.getPlayerFromBodyPart(character:FindFirstChild("Torso"));
    end

    function espLibrary._getHealth(player)
        local entry = replicationInterface.getEntry(player);

        if (entry) then
            return entry:getHealth();
        end

        return 100, 100;
    end

    function espLibrary._getWeapon(player, _)
        local entry = replicationInterface.getEntry(player);
        return entry and entry:getThirdPersonObject()._weaponname or "Unknown";
    end

    espLibrary.settings.teamUseTeamColor = true;

    espLibrary:Load();
end

-- hooks
do
    
end

-- ui
do
    library.font = (worldtoscreen ~= nil) and 1 or 2;

    local window = library:load({
        name = repository .. " - v" .. version,
        sizex = 450,
        sizey = 460,
        theme = "Midnight",
        folder = repository,
        extension = ".json"
    }); do
        local legitbot = window:tab("Legitbot"); do
            local aimbot = legitbot:section({ name = "Aimbot", side = "left" }); do
                aimbot:toggle({ name = "Enabled", flag = "legitbot_aimbot_enabled" });
                aimbot:toggle({ name = "Visible Check", flag = "legitbot_aimbot_visiblecheck" });
                local showFOV = aimbot:toggle({ name = "Show Field Of View", flag = "legitbot_aimbot_showfov" });
                showFOV:colorpicker({ default = Color3.new(1, 1, 1), flag = "legitbot_aimbot_fovcolor" });
                showFOV:slider({ name = "Field Of View", min = 0, max = 20, default = 10, flag = "legitbot_aimbot_fov" });
                aimbot:slider({ name = "Smoothing", min = 3, max = 100, default = 10, flag = "legitbot_aimbot_smoothing" });
            end
        end

        local visuals = window:tab("Visuals"); do
            local esp = visuals:section({ name = "Esp", side = "left" }); do
                esp:toggle({ name = "Enabled", flag = "visuals_esp_enabled", callback = function(state)
                    espLibrary.settings.enabled = state;
                end });
                esp:toggle({ name = "Names", flag = "visuals_esp_names", callback = function(state)
                    espLibrary.settings.names = state;
                end });
                esp:toggle({ name = "Team", flag = "visuals_esp_team", callback = function(state)
                    espLibrary.settings.teams = state;
                end });
                local boxes = esp:toggle({ name = "Boxes", flag = "visuals_esp_boxes", callback = function(state)
                    espLibrary.settings.boxes = state;
                end });
                boxes:colorpicker({ default = Color3.new(1, 1, 1), flag = "visuals_esp_boxcolor", callback = function(color)
                    espLibrary.settings.boxColor = color;
                end });
                boxes:dropdown({ content = { "Static", "Dynamic" }, default = "Static", flag = "visuals_esp_boxtype", callback = function(selected)
                    espLibrary.settings.boxType = selected;
                end })
                esp:toggle({ name = "Box Fill", flag = "visuals_esp_boxfill", callback = function(state)
                    espLibrary.settings.boxFill = state;
                end });
                esp:toggle({ name = "Healthbar", flag = "visuals_esp_healthbar", callback = function(state)
                    espLibrary.settings.healthbar = state;
                end });
                esp:toggle({ name = "Health Text", flag = "visuals_esp_healthtext", callback = function(state)
                    espLibrary.settings.healthtext = state;
                end });
                esp:toggle({ name = "Distance", flag = "visuals_esp_distance", callback = function(state)
                    espLibrary.settings.distance = state;
                end });
                esp:toggle({ name = "Weapon", flag = "visuals_esp_weapon", callback = function(state)
                    espLibrary.settings.weapon = state;
                end });
                esp:toggle({ name = "Out Of View Arrows", flag = "visuals_esp_oofarrows", callback = function(state)
                    espLibrary.settings.oofArrows = state;
                end });
            end

            local settings = visuals:section({ name = "Settings", side = "left" }); do
                
            end
        end

        local settings = window:tab("Settings"); do
            local configuration = settings:section({ name = "Configuration", side = "left" }); do
                local function getConfigs()
                    local list = {};
                    local configs = library:GetConfigs();

                    for _, config in next, configs do
                        list[#list+1] = config:gsub(library.folder .. "\\" .. game.PlaceId .. "\\", "");
                    end

                    return list;
                end

                local configList = configuration:list({ name = "Configs", content = getConfigs(), scrollable = true, scrollingmax = 11, flag = "Config List" });

                configuration:box({ placeholder = "Config Name", flag = "Config Box" });

                configuration:button({ name = "Refresh Configs", callback = function()
                    configList:Refresh(getConfigs());
                end });

                configuration:button({ name = "Create Config", callback = function()
                    library:SaveConfig(library.flags["Config Box"]);
                    configList:Refresh(getConfigs());
                end });

                configuration:button({ name = "Load Config", callback = function()
                    library:LoadConfig(library.flags["Config List"]);
                end });

                configuration:button({ name = "Save Config", callback = function()
                    library:SaveConfig(library.flags["Config List"]);
                end });

                configuration:button({ name = "Delete Config", callback = function()
                    library:DeleteConfig(library.flags["Config List"]);
                    configList:Refresh(getConfigs());
                end });

                library:ConfigIgnore("Config List");
                library:ConfigIgnore("Config Box");
            end

            local theme = settings:section({ name = "Theme", side = "right" }); do
                for option, color in next, library.theme do
                    theme:colorpicker({ name = option, default = color, flag = option, callback = function(newColor)
                        library:ChangeThemeOption(option, newColor);
                    end });
                end
            end

            local cheat = settings:section({ name = "Cheat", side = "right" }); do
                cheat:keybind({ name = "Menu Key", default = library.keybind, flag = "Menu Key", callback = function()
                    library:Close();
                end });

                cheat:button({ name = "Unload", callback = function()
                    espLibrary:Unload();
                    library:Unload();
                end });
            end
        end
    end

    library:Close();
end
