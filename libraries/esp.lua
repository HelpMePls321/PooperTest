--[[
    made by siper#9938 and mickey#5612
]]

-- main module
local espLibrary = {
    instances = {},
    espCache = {},
    chamsCache = {},
    objectCache = {},
    conns = {},
    whitelist = {}, -- insert string that is the player's name you want to whitelist (turns esp color to whitelistColor in options)
    blacklist = {}, -- insert string that is the player's name you want to blacklist (removes player from esp)
    options = {-- start
local isSynV3 = worldtoscreen ~= nil;

-- localization
local game, workspace, table, math, cframe, vector2, vector3, color3, instance, drawing, raycastParams = game, workspace, table, math, CFrame, Vector2, Vector3, Color3, Instance, Drawing, RaycastParams;
local getService, isA, findFirstChild, getChildren = game.GetService, game.IsA, game.FindFirstChild, game.GetChildren;
local raycast = workspace.Raycast;
local tableInsert = table.insert;
local mathFloor, mathSin, mathCos, mathRad, mathTan, mathAtan2, mathClamp = math.floor, math.sin, math.cos, math.rad, math.tan, math.atan2, math.clamp;
local cframeNew, vector2New, vector3New = cframe.new, vector2.new, vector3.new;
local color3New = color3.new;
local instanceNew, drawingNew = instance.new, drawing.new;
local raycastParamsNew = raycastParams.new;

-- services
local players = getService(game, "Players");
local coreGui = getService(game, "CoreGui");
local runService = getService(game, "RunService");

-- cache
local localPlayer = players.LocalPlayer;
local currentCamera = workspace.CurrentCamera;
local filterType = Enum.RaycastFilterType.Blacklist;
local depthMode = Enum.HighlightDepthMode;
local lastScale, lastFov;

-- function localization
local ccWorldToViewportPoint = currentCamera.WorldToViewportPoint;
local pointToObjectSpace = cframeNew().PointToObjectSpace;

-- support functions
local function worldToViewportPoint(position)
    if (isSynV3) then
        local screenPosition = worldtoscreen({ position })[1];
        local depth = screenPosition.Z;
        return vector2New(screenPosition.X, screenPosition.Y), depth > 0, depth;
    end

    local screenPosition, onScreen = ccWorldToViewportPoint(currentCamera, position);
    return vector2New(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z;
end

local function isDrawing(type)
    return type == "Line" or type == "Text" or type == "Image" or type == "Circle" or type == "Square" or type == "Quad" or type == "Triangle"
end

local function create(type, properties)
    local drawing = isDrawing(type);
    local object = drawing and drawingNew(type) or instanceNew(type);

    if (properties) then
        for property, value in next, properties do
            object[property] = value;
        end
    end

    return object;
end

local function rotateVector(vector, angle)
    local c = mathCos(mathRad(angle));
    local s = mathSin(mathRad(angle));
    return vector2New(c * vector.X - s * vector.Y, s * vector.X + c * vector.Y);
end

local function roundVector(vector)
    return vector2New(mathFloor(vector.X), mathFloor(vector.Y));
end

-- main module
local library = {
    _connections = {},
    _espCache = {},
    _chamsCache = {},
    _screenGui = create("ScreenGui", {
        Parent = coreGui,
    }),
    settings = {
        enabled = true,
        visibleOnly = false,
        teamCheck = false,
        boxStaticWidth = 4,
        boxStaticHeight = 5,
        maxBoxWidth = 6,
        maxBoxHeight = 6,

        chams = false,
        chamsDepthMode = "AlwaysOnTop",
        chamsInlineColor = color3New(0.701960, 0.721568, 1),
        chamsInlineTransparency = 0,
        chamsOutlineColor = color3New(),
        chamsOutlineTransparency = 0,
        names = true,
        nameColor = color3New(1, 1, 1),
        teams = false,
        teamColor = color3New(1, 1, 1),
        teamUseTeamColor = false,
        boxes = true,
        boxColor = color3New(1, 0, 0),
        boxType = "Static",
        boxFill = true,
        boxFillColor = color3New(1, 0, 0),
        boxFillTransparency = 0.5,
        healthbar = true,
        healthbarColor = color3New(0, 1, 0.4),
        healthbarSize = 1,
        healthtext = false,
        healthtextColor = color3New(1, 1, 1),
        distance = false,
        distanceColor = color3New(1, 1, 1),
        weapon = false,
        weaponColor = color3New(1, 1, 1),
        oofArrows = false,
        oofArrowsColor = color3New(0.8, 0.2, 0.2),
        oofArrowsAlpha = 1,
        oofArrowsSize = 30,
        oofArrowsRadius = 150,
    }
};
library.__index = library;

-- support functions
function library:AddConnection(signal, callback)
    local connection = signal:Connect(callback);
    tableInsert(self._connections, connection);
    return connection;
end

-- main functions
function library._getTeam(player)
    return player.Team;
end

function library._getCharacter(player)
    local character = player.Character;
    return character, character and findFirstChild(character, "HumanoidRootPart");
end

function library._getHealth(player, character)
    local humanoid = findFirstChild(character, "Humanoid");

    if (humanoid) then
        return humanoid.Health, humanoid.MaxHealth;
    end

    return 100, 100;
end

function library._getWeapon(player, character)
    return "Hands";
end

function library._visibleCheck(character, origin, target)
    local params = raycastParamsNew();

    params.FilterDescendantsInstances = { library._getCharacter(localPlayer), character, currentCamera };
    params.FilterType = filterType;
    params.IgnoreWater = true;

    return raycast(workspace, origin, target - origin, params) == nil;
end

function library._getScaleFactor(fov, depth)
    if (lastFov ~= fov) then
        lastScale = mathTan(mathRad(fov * 0.5)) * 2;
        lastFov = fov;
    end

    return 1 / (lastScale * depth) * 1000;
end

function library._getBoxSize(character)
    if (library.settings.boxType == "Static" or not isA(character, "Model")) then
        return vector2New(library.settings.boxStaticWidth, library.settings.boxStaticHeight);
    end

    local _, size = character:GetBoundingBox();
    return vector2New(mathClamp(size.X, 0, library.settings.maxBoxWidth), mathClamp(size.Y, 0, library.settings.maxBoxHeight));
end

function library._getBoxData(character, depth)
    local size = library._getBoxSize(character);
    local scaleFactor = library._getScaleFactor(currentCamera.FieldOfView, depth);
    return mathFloor(size.X * scaleFactor), mathFloor(size.Y * scaleFactor);
end

function library._addEsp(player)
    if (player == localPlayer) then
        return
    end

    local font = isSynV3 and 1 or 2;

    local objects = {
        name = create("Text", {
            Color = library.settings.nameColor,
            Text = player.Name,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        team = create("Text", {
            Color = library.settings.teamColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        boxOutline = create("Square", {
            Color = color3New(),
            Transparency = 0.5,
            Thickness = 3,
            Filled = false
        }),
        box = create("Square", {
            Color = library.settings.boxColor,
            Thickness = 1,
            Filled = false
        }),
        boxFill = create("Square", {
            Color = library.settings.boxFillColor,
            Transparency = library.settings.boxFillTransparency,
            Thickness = 1,
            Filled = true
        }),
        healthbarOutline = create("Square", {
            Color = color3New(),
            Transparency = 0.5,
            Thickness = 1,
            Filled = true
        }),
        healthbar = create("Square", {
            Color = library.settings.healthbarColor,
            Thickness = 1,
            Filled = true
        }),
        healthtext = create("Text", {
            Color = library.settings.healthtextColor,
            Size = 13,
            Center = false,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        distance = create("Text", {
            Color = library.settings.distanceColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        weapon = create("Text", {
            Color = library.settings.weaponColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        arrow = create("Triangle", {
            Color = library.settings.oofArrowsColor,
            Thickness = 1,
            Filled = true
        })
    };

    library._espCache[player] = objects;
end

function library._removeEsp(player)
    local espCache = library._espCache[player];

    if (espCache) then
        for index, object in next, espCache do
            object:Remove();
            espCache[index] = nil;
        end
    end
end

function library._addChams(player)
    if (player == localPlayer) then
        return
    end

    library._chamsCache[player] = create("Highlight", {
        Parent = library._screenGui,
        DepthMode = depthMode[library.settings.chamsDepthMode],
        FillColor = library.settings.chamsInlineColor,
        FillTransparency = library.settings.chamsInlineTransparency,
        OutlineColor = library.settings.chamsOutlineColor,
        OutlineTransparency = library.settings.chamsOutlineTransparency,
    });
end

function library._removeChams(player)
    local chamsCache = library._chamsCache[player];

    if (chamsCache) then
        chamsCache:Destroy();
        library._chamsCache[player] = nil;
    end
end

function library:Load()
    for _, player in next, players:GetPlayers() do
        self._addEsp(player);
        self._addChams(player);
    end

    self:AddConnection(players.PlayerAdded, function(player)
        self._addEsp(player);
        self._addChams(player);
    end);

    self:AddConnection(players.PlayerRemoving, function(player)
        self._removeEsp(player);
        self._removeChams(player);
    end);

    self:AddConnection(runService.Heartbeat, function()
        for player, cache in next, self._espCache do
            local team = self._getTeam(player);
            local character, root = self._getCharacter(player);
            local enabled = self.settings.enabled;

            if (self.settings.teamCheck and team == self._getTeam(localPlayer)) then
                enabled = false
            end

            if (enabled and character and root) then
                local enabled = true;
                local cameraCFrame = currentCamera.CFrame;
                local cameraPosition, rootPosition = cameraCFrame.Position, root.Position;

                if (self.settings.visibleOnly and not self._visibleCheck(character, cameraPosition, rootPosition)) then
                    enabled = false;
                end

                if (enabled) then
                    local torsoPosition, onScreen, depth = worldToViewportPoint(rootPosition);

                    local x, y = torsoPosition.X, torsoPosition.Y;
                    local width, height = self._getBoxData(character, depth);
                    local boxSize = vector2New(width, height);
                    local boxPosition = vector2New(mathFloor(x - width * 0.5), mathFloor(y - height * 0.5));

                    local health, maxHealth = self._getHealth(player, character);
                    local barSize = self.settings.healthbarSize;
                    local healthbarSize = vector2New(isSynV3 and barSize - 1 or barSize, height);
                    local healthbarPosition = boxPosition - vector2New(healthbarSize.X + (isSynV3 and 4 or 3), 0);

                    local objectSpace = pointToObjectSpace(cameraCFrame, rootPosition);
                    local angle = mathAtan2(objectSpace.Z, objectSpace.X);
                    local direction = vector2New(mathCos(angle), mathSin(angle));
                    local viewportSize = currentCamera.ViewportSize;
                    local position = vector2New(viewportSize.X * 0.5, viewportSize.Y * 0.5) + direction * self.settings.oofArrowsRadius;

                    cache.arrow.Visible = not onScreen and self.settings.oofArrows;
                    cache.arrow.Color = self.settings.oofArrowsColor;
                    cache.arrow.Transparency = self.settings.oofArrowsAlpha;
                    cache.arrow.PointA = roundVector(position);
                    cache.arrow.PointB = roundVector(position - rotateVector(direction, 30) * self.settings.oofArrowsSize);
                    cache.arrow.PointC = roundVector(position - rotateVector(direction, -30) * self.settings.oofArrowsSize);

                    cache.name.Visible = onScreen and self.settings.names;
                    cache.name.Color = self.settings.nameColor;
                    cache.name.Position = vector2New(x, boxPosition.Y - cache.name.TextBounds.Y - 2);

                    cache.team.Visible = onScreen and self.settings.teams;
                    cache.team.Text = team ~= nil and team.Name or "No Team";
                    cache.team.Color = (self.settings.teamUseTeamColor and team ~= nil) and team.TeamColor.Color or self.settings.teamColor;
                    cache.team.Position = vector2New(x + width * 0.5 + cache.team.TextBounds.X * 0.5 + 2, boxPosition.Y - 2);

                    cache.box.Visible = onScreen and self.settings.boxes;
                    cache.box.Color = self.settings.boxColor;
                    cache.box.Size = boxSize;
                    cache.box.Position = boxPosition;

                    cache.boxOutline.Visible = cache.box.Visible;
                    cache.boxOutline.Size = boxSize;
                    cache.boxOutline.Position = boxPosition;

                    cache.boxFill.Visible = onScreen and self.settings.boxFill;
                    cache.boxFill.Color = self.settings.boxFillColor;
                    cache.boxFill.Transparency = self.settings.boxFillTransparency;
                    cache.boxFill.Size = boxSize;
                    cache.boxFill.Position = boxPosition;

                    cache.healthbar.Visible = onScreen and self.settings.healthbar;
                    cache.healthbar.Color = self.settings.healthbarColor;
                    cache.healthbar.Size = vector2New(healthbarSize.X, -(height * (health / maxHealth)));
                    cache.healthbar.Position = healthbarPosition + vector2New(0, height);

                    cache.healthbarOutline.Visible = cache.healthbar.Visible;
                    cache.healthbarOutline.Size = healthbarSize + vector2New(2, 2);
                    cache.healthbarOutline.Position = healthbarPosition - vector2New(1, 1);

                    cache.healthtext.Visible = onScreen and self.settings.healthtext;
                    cache.healthtext.Text = mathFloor(health) .. " HP";
                    cache.healthtext.Color = self.settings.healthtextColor;
                    cache.healthtext.Position = healthbarPosition - vector2New(cache.healthtext.TextBounds.X + 2, -(height * (1 - (health / maxHealth))) + 2);

                    cache.distance.Visible = onScreen and self.settings.distance;
                    cache.distance.Text = mathFloor((cameraPosition - rootPosition).Magnitude) .. " Studs";
                    cache.distance.Color = self.settings.distanceColor;
                    cache.distance.Position = vector2New(x, boxPosition.Y + height);

                    cache.weapon.Visible = onScreen and self.settings.weapon;
                    cache.weapon.Text = self._getWeapon(player, character);
                    cache.weapon.Color = self.settings.weaponColor;
                    cache.weapon.Position = vector2New(x, boxPosition.Y + height + (cache.distance.Visible and cache.distance.TextBounds.Y + 1 or 0));
                else
                    for _, object in next, cache do
                        object.Visible = false;
                    end
                end
            else
                for _, object in next, cache do
                    object.Visible = false;
                end
            end
        end
    end);

    self:AddConnection(runService.Heartbeat, function()
        for player, highlight in next, self._chamsCache do
            local team = self._getTeam(player);
            local character = self._getCharacter(player);

            if (character) then
                local enabled = self.settings.chams;

                if (self.settings.teamCheck and team == self._getTeam(localPlayer)) then
                    enabled = false
                end

                highlight.Enabled = enabled;
                highlight.Adornee = character;
                highlight.DepthMode = depthMode[self.settings.chamsDepthMode];
                highlight.FillColor = self.settings.chamsInlineColor;
                highlight.FillTransparency = self.settings.chamsInlineTransparency;
                highlight.OutlineColor = self.settings.chamsOutlineColor;
                highlight.OutlineTransparency = self.settings.chamsOutlineTransparency;
            else
                highlight.Enabled = false;
                highlight.Adornee = nil;
            end
        end
    end);
end

function library:Unload()
    self._screenGui:Destroy();

    for index, connection in next, self._connections do
        connection:Disconnect();
        self._connections[index] = nil;
    end

    for _, player in next, players:GetPlayers() do
        self._removeEsp(player);
        self._removeChams(player);
    end
end

return setmetatable({}, library);

        enabled = true,
        minScaleFactorX = 1,
        maxScaleFactorX = 10,
        minScaleFactorY = 1,
        maxScaleFactorY = 10,
        scaleFactorX = 5,
        scaleFactorY = 6,
        boundingBox = false, -- WARNING | Significant Performance Decrease when true
        boundingBoxDescending = true,
        excludedPartNames = {},
        font = 2,
        fontSize = 13,
        limitDistance = false,
        maxDistance = 1000,
        visibleOnly = false,
        teamCheck = false,
        teamColor = false,
        fillColor = nil,
        whitelistColor = Color3.new(1, 0, 0),
        outOfViewArrows = true,
        outOfViewArrowsFilled = true,
        outOfViewArrowsSize = 25,
        outOfViewArrowsRadius = 100,
        outOfViewArrowsColor = Color3.new(1, 1, 1),
        outOfViewArrowsTransparency = 0.5,
        outOfViewArrowsOutline = true,
        outOfViewArrowsOutlineFilled = false,
        outOfViewArrowsOutlineColor = Color3.new(1, 1, 1),
        outOfViewArrowsOutlineTransparency = 1,
        names = true,
        nameTransparency = 1,
        nameColor = Color3.new(1, 1, 1),
        boxes = true,
        boxesTransparency = 1,
        boxesColor = Color3.new(1, 0, 0),
        boxFill = false,
        boxFillTransparency = 0.5,
        boxFillColor = Color3.new(1, 0, 0),
        healthBars = true,
        healthBarsSize = 1,
        healthBarsTransparency = 1,
        healthBarsColor = Color3.new(0, 1, 0),
        healthText = true,
        healthTextTransparency = 1,
        healthTextSuffix = "%",
        healthTextColor = Color3.new(1, 1, 1),
        distance = true,
        distanceTransparency = 1,
        distanceSuffix = " Studs",
        distanceColor = Color3.new(1, 1, 1),
        tracers = false,
        tracerTransparency = 1,
        tracerColor = Color3.new(1, 1, 1),
        tracerOrigin = "Bottom", -- Available [Mouse, Top, Bottom]
        chams = true,
        chamsFillColor = Color3.new(1, 0, 0),
        chamsFillTransparency = 0.5,
        chamsOutlineColor = Color3.new(),
        chamsOutlineTransparency = 0
    },
};
espLibrary.__index = espLibrary;

-- variables
local getService = game.GetService;
local instanceNew = Instance.new;
local drawingNew = Drawing.new;
local vector2New = Vector2.new;
local vector3New = Vector3.new;
local cframeNew = CFrame.new;
local color3New = Color3.new;
local raycastParamsNew = RaycastParams.new;
local abs = math.abs;
local tan = math.tan;
local rad = math.rad;
local clamp = math.clamp;
local floor = math.floor;
local find = table.find;
local insert = table.insert;
local findFirstChild = game.FindFirstChild;
local getChildren = game.GetChildren;
local getDescendants = game.GetDescendants;
local isA = workspace.IsA;
local raycast = workspace.Raycast;
local emptyCFrame = cframeNew();
local pointToObjectSpace = emptyCFrame.PointToObjectSpace;
local getComponents = emptyCFrame.GetComponents;
local cross = vector3New().Cross;
local inf = 1 / 0;

-- services
local workspace = getService(game, "Workspace");
local runService = getService(game, "RunService");
local players = getService(game, "Players");
local coreGui = getService(game, "CoreGui");
local userInputService = getService(game, "UserInputService");

-- cache
local currentCamera = workspace.CurrentCamera;
local localPlayer = players.LocalPlayer;
local screenGui = instanceNew("ScreenGui", coreGui);
local lastFov, lastScale;

-- instance functions
local wtvp = currentCamera.WorldToViewportPoint;

-- Support Functions
local function isDrawing(type)
    return type == "Square" or type == "Text" or type == "Triangle" or type == "Image" or type == "Line" or type == "Circle";
end

local function create(type, properties)
    local drawing = isDrawing(type);
    local object = drawing and drawingNew(type) or instanceNew(type);

    if (properties) then
        for i,v in next, properties do
            object[i] = v;
        end
    end

    if (not drawing) then
        insert(espLibrary.instances, object);
    end

    return object;
end

local function worldToViewportPoint(position)
    local screenPosition, onScreen = wtvp(currentCamera, position);
    return vector2New(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z;
end

local function round(number)
    return typeof(number) == "Vector2" and vector2New(round(number.X), round(number.Y)) or floor(number);
end

-- Main Functions
function espLibrary.getTeam(player)
    local team = player.Team;
    return team, player.TeamColor.Color;
end

function espLibrary.getCharacter(player)
    local character = player.Character;
    return character, character and findFirstChild(character, "HumanoidRootPart");
end

function espLibrary.getBoundingBox(character, torso)
    if (espLibrary.options.boundingBox) then
        local minX, minY, minZ = inf, inf, inf;
        local maxX, maxY, maxZ = -inf, -inf, -inf;

        for _, part in next, espLibrary.options.boundingBoxDescending and getDescendants(character) or getChildren(character) do
            if (isA(part, "BasePart") and not find(espLibrary.options.excludedPartNames, part.Name)) then
                local size = part.Size;
                local sizeX, sizeY, sizeZ = size.X, size.Y, size.Z;

                local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = getComponents(part.CFrame);

                local wiseX = 0.5 * (abs(r00) * sizeX + abs(r01) * sizeY + abs(r02) * sizeZ);
                local wiseY = 0.5 * (abs(r10) * sizeX + abs(r11) * sizeY + abs(r12) * sizeZ);
                local wiseZ = 0.5 * (abs(r20) * sizeX + abs(r21) * sizeY + abs(r22) * sizeZ);

                minX = minX > x - wiseX and x - wiseX or minX;
                minY = minY > y - wiseY and y - wiseY or minY;
                minZ = minZ > z - wiseZ and z - wiseZ or minZ;

                maxX = maxX < x + wiseX and x + wiseX or maxX;
                maxY = maxY < y + wiseY and y + wiseY or maxY;
                maxZ = maxZ < z + wiseZ and z + wiseZ or maxZ;
            end
        end

        local oMin, oMax = vector3New(minX, minY, minZ), vector3New(maxX, maxY, maxZ);
        return (oMax + oMin) * 0.5, oMax - oMin;
    else
        return torso.Position, vector2New(espLibrary.options.scaleFactorX, espLibrary.options.scaleFactorY);
    end
end

function espLibrary.getScaleFactor(fov, depth)
    if (fov ~= lastFov) then
        lastScale = tan(rad(fov * 0.5)) * 2;
        lastFov = fov;
    end

    return 1 / (depth * lastScale) * 1000;
end

function espLibrary.getBoxData(position, size)
    local torsoPosition, onScreen, depth = worldToViewportPoint(position);
    local scaleFactor = espLibrary.getScaleFactor(currentCamera.FieldOfView, depth);

    local clampX = clamp(size.X, espLibrary.options.minScaleFactorX, espLibrary.options.maxScaleFactorX);
    local clampY = clamp(size.Y, espLibrary.options.minScaleFactorY, espLibrary.options.maxScaleFactorY);
    local size = round(vector2New(clampX * scaleFactor, clampY * scaleFactor));

    return onScreen, size, round(vector2New(torsoPosition.X - (size.X * 0.5), torsoPosition.Y - (size.Y * 0.5))), torsoPosition;
end

function espLibrary.getHealth(player, character)
    local humanoid = findFirstChild(character, "Humanoid");

    if (humanoid) then
        return humanoid.Health, humanoid.MaxHealth;
    end

    return 100, 100;
end

function espLibrary.visibleCheck(character, position)
    local origin = currentCamera.CFrame.Position;
    local params = raycastParamsNew();

    params.FilterDescendantsInstances = { espLibrary.getCharacter(localPlayer), currentCamera, character };
    params.FilterType = Enum.RaycastFilterType.Blacklist;
    params.IgnoreWater = true;

    return (not raycast(workspace, origin, position - origin, params));
end

function espLibrary.addEsp(player)
    if (player == localPlayer) then
        return
    end

    local objects = {
        arrow = create("Triangle", {
            Thickness = 1,
        }),
        arrowOutline = create("Triangle", {
            Thickness = 1,
        }),
        top = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        side = create("Text", {
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        bottom = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        boxFill = create("Square", {
            Thickness = 1,
            Filled = true,
        }),
        boxOutline = create("Square", {
            Thickness = 3,
            Color = color3New()
        }),
        box = create("Square", {
            Thickness = 1
        }),
        healthBarOutline = create("Square", {
            Thickness = 1,
            Color = color3New(),
            Filled = true
        }),
        healthBar = create("Square", {
            Thickness = 1,
            Filled = true
        }),
        line = create("Line")
    };

    espLibrary.espCache[player] = objects;
end

function espLibrary.removeEsp(player)
    local espCache = espLibrary.espCache[player];

    if (espCache) then
        espLibrary.espCache[player] = nil;

        for index, object in next, espCache do
            espCache[index] = nil;
            object:Remove();
        end
    end
end

function espLibrary.addChams(player)
    if (player == localPlayer) then
        return
    end

    espLibrary.chamsCache[player] = create("Highlight", {
        Parent = screenGui,
    });
end

function espLibrary.removeChams(player)
    local highlight = espLibrary.chamsCache[player];

    if (highlight) then
        espLibrary.chamsCache[player] = nil;
        highlight:Destroy();
    end
end

function espLibrary.addObject(object, options)
    espLibrary.objectCache[object] = {
        options = options,
        text = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        })
    };
end

function espLibrary.removeObject(object)
    local cache = espLibrary.objectCache[object];

    if (cache) then
        espLibrary.objectCache[object] = nil;
        cache.text:Remove();
    end
end

function espLibrary:AddObjectEsp(object, defaultOptions)
    assert(object and object.Parent, "invalid object passed");

    local options = defaultOptions or {};

    options.enabled = options.enabled or true;
    options.limitDistance = options.limitDistance or false;
    options.maxDistance = options.maxDistance or false;
    options.visibleOnly = options.visibleOnly or false;
    options.color = options.color or color3New(1, 1, 1);
    options.transparency = options.transparency or 1;
    options.text = options.text or object.Name;
    options.font = options.font or 2;
    options.fontSize = options.fontSize or 13;

    self.addObject(object, options);

    insert(self.conns, object.Parent.ChildRemoved:Connect(function(child)
        if (child == object) then
            self.removeObject(child);
        end
    end));

    return options;
end

function espLibrary:Unload()
    for _, connection in next, self.conns do
        connection:Disconnect();
    end

    for _, player in next, players:GetPlayers() do
        self.removeEsp(player);
        self.removeChams(player);
    end

    for object, _ in next, self.objectCache do
        self.removeObject(object);
    end

    for _, object in next, self.instances do
        object:Destroy();
    end

    screenGui:Destroy();
    runService:UnbindFromRenderStep("esp_rendering");
end

function espLibrary:Load(renderValue)
    insert(self.conns, players.PlayerAdded:Connect(function(player)
        self.addEsp(player);
        self.addChams(player);
    end));

    insert(self.conns, players.PlayerRemoving:Connect(function(player)
        self.removeEsp(player);
        self.removeChams(player);
    end));

    for _, player in next, players:GetPlayers() do
        self.addEsp(player);
        self.addChams(player);
    end

    runService:BindToRenderStep("esp_rendering", renderValue or (Enum.RenderPriority.Camera.Value + 1), function()
        for player, objects in next, self.espCache do
            local character, torso = self.getCharacter(player);

            if (character and torso) then
                local onScreen, size, position, torsoPosition = self.getBoxData(torso.Position, Vector3.new(5, 6));
                local distance = (currentCamera.CFrame.Position - torso.Position).Magnitude;
                local canShow, enabled = onScreen and (size and position), self.options.enabled;
                local team, teamColor = self.getTeam(player);
                local color = self.options.teamColor and teamColor or nil;

                if (self.options.fillColor ~= nil) then
                    color = self.options.fillColor;
                end

                if (find(self.whitelist, player.Name)) then
                    color = self.options.whitelistColor;
                end

                if (find(self.blacklist, player.Name)) then
                    enabled = false;
                end

                if (self.options.limitDistance and distance > self.options.maxDistance) then
                    enabled = false;
                end

                if (self.options.visibleOnly and not self.visibleCheck(character, torso.Position)) then
                    enabled = false;
                end

                if (self.options.teamCheck and (team == self.getTeam(localPlayer))) then
                    enabled = false;
                end

                local viewportSize = currentCamera.ViewportSize;

                local screenCenter = vector2New(viewportSize.X / 2, viewportSize.Y / 2);
                local objectSpacePoint = (pointToObjectSpace(currentCamera.CFrame, torso.Position) * vector3New(1, 0, 1)).Unit;
                local crossVector = cross(objectSpacePoint, vector3New(0, 1, 1));
                local rightVector = vector2New(crossVector.X, crossVector.Z);

                local arrowRadius, arrowSize = self.options.outOfViewArrowsRadius, self.options.outOfViewArrowsSize;
                local arrowPosition = screenCenter + vector2New(objectSpacePoint.X, objectSpacePoint.Z) * arrowRadius;
                local arrowDirection = (arrowPosition - screenCenter).Unit;

                local pointA, pointB, pointC = arrowPosition, screenCenter + arrowDirection * (arrowRadius - arrowSize) + rightVector * arrowSize, screenCenter + arrowDirection * (arrowRadius - arrowSize) + -rightVector * arrowSize;

                local health, maxHealth = self.getHealth(player, character);
                local healthBarSize = round(vector2New(self.options.healthBarsSize, -(size.Y * (health / maxHealth))));
                local healthBarPosition = round(vector2New(position.X - (3 + healthBarSize.X), position.Y + size.Y));

                local origin = self.options.tracerOrigin;
                local show = canShow and enabled;

                objects.arrow.Visible = (not canShow and enabled) and self.options.outOfViewArrows;
                objects.arrow.Filled = self.options.outOfViewArrowsFilled;
                objects.arrow.Transparency = self.options.outOfViewArrowsTransparency;
                objects.arrow.Color = color or self.options.outOfViewArrowsColor;
                objects.arrow.PointA = pointA;
                objects.arrow.PointB = pointB;
                objects.arrow.PointC = pointC;

                objects.arrowOutline.Visible = (not canShow and enabled) and self.options.outOfViewArrowsOutline;
                objects.arrowOutline.Filled = self.options.outOfViewArrowsOutlineFilled;
                objects.arrowOutline.Transparency = self.options.outOfViewArrowsOutlineTransparency;
                objects.arrowOutline.Color = color or self.options.outOfViewArrowsOutlineColor;
                objects.arrowOutline.PointA = pointA;
                objects.arrowOutline.PointB = pointB;
                objects.arrowOutline.PointC = pointC;

                objects.top.Visible = show and self.options.names;
                objects.top.Font = self.options.font;
                objects.top.Size = self.options.fontSize;
                objects.top.Transparency = self.options.nameTransparency;
                objects.top.Color = color or self.options.nameColor;
                objects.top.Text = player.Name;
                objects.top.Position = round(position + vector2New(size.X * 0.5, -(objects.top.TextBounds.Y + 2)));

                objects.side.Visible = show and self.options.healthText;
                objects.side.Font = self.options.font;
                objects.side.Size = self.options.fontSize;
                objects.side.Transparency = self.options.healthTextTransparency;
                objects.side.Color = color or self.options.healthTextColor;
                objects.side.Text = health .. self.options.healthTextSuffix;
                objects.side.Position = round(position + vector2New(size.X + 3, -3));

                objects.bottom.Visible = show and self.options.distance;
                objects.bottom.Font = self.options.font;
                objects.bottom.Size = self.options.fontSize;
                objects.bottom.Transparency = self.options.distanceTransparency;
                objects.bottom.Color = color or self.options.nameColor;
                objects.bottom.Text = tostring(round(distance)) .. self.options.distanceSuffix;
                objects.bottom.Position = round(position + vector2New(size.X * 0.5, size.Y + 1));

                objects.box.Visible = show and self.options.boxes;
                objects.box.Color = color or self.options.boxesColor;
                objects.box.Transparency = self.options.boxesTransparency;
                objects.box.Size = size;
                objects.box.Position = position;

                objects.boxOutline.Visible = show and self.options.boxes;
                objects.boxOutline.Transparency = self.options.boxesTransparency;
                objects.boxOutline.Size = size;
                objects.boxOutline.Position = position;

                objects.boxFill.Visible = show and self.options.boxFill;
                objects.boxFill.Color = color or self.options.boxFillColor;
                objects.boxFill.Transparency = self.options.boxFillTransparency;
                objects.boxFill.Size = size;
                objects.boxFill.Position = position;

                objects.healthBar.Visible = show and self.options.healthBars;
                objects.healthBar.Color = color or self.options.healthBarsColor;
                objects.healthBar.Transparency = self.options.healthBarsTransparency;
                objects.healthBar.Size = healthBarSize;
                objects.healthBar.Position = healthBarPosition;

                objects.healthBarOutline.Visible = show and self.options.healthBars;
                objects.healthBarOutline.Transparency = self.options.healthBarsTransparency;
                objects.healthBarOutline.Size = round(vector2New(healthBarSize.X, -size.Y) + vector2New(2, -2));
                objects.healthBarOutline.Position = healthBarPosition - vector2New(1, -1);

                objects.line.Visible = show and self.options.tracers;
                objects.line.Color = color or self.options.tracerColor;
                objects.line.Transparency = self.options.tracerTransparency;
                objects.line.From =
                    origin == "Mouse" and userInputService:GetMouseLocation() or
                    origin == "Top" and vector2New(viewportSize.X * 0.5, 0) or
                    origin == "Bottom" and vector2New(viewportSize.X * 0.5, viewportSize.Y);
                objects.line.To = torsoPosition;
            else
                for _, object in next, objects do
                    object.Visible = false;
                end
            end
        end

        for player, highlight in next, self.chamsCache do
            local character, torso = self.getCharacter(player);

            if (character and torso) then
                local distance = (currentCamera.CFrame.Position - torso.Position).Magnitude;
                local canShow = self.options.enabled and self.options.chams;
                local team, teamColor = self.getTeam(player);
                local color = self.options.teamColor and teamColor or nil;

                if (self.options.fillColor ~= nil) then
                    color = self.options.fillColor;
                end

                if (find(self.whitelist, player.Name)) then
                    color = self.options.whitelistColor;
                end

                if (find(self.blacklist, player.Name)) then
                    canShow = false;
                end

                if (self.options.limitDistance and distance > self.options.maxDistance) then
                    canShow = false;
                end

                if (self.options.teamCheck and (team == self.getTeam(localPlayer))) then
                    canShow = false;
                end

                highlight.Enabled = canShow;
                highlight.DepthMode = self.options.visibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop;
                highlight.Adornee = character;
                highlight.FillColor = color or self.options.chamsFillColor;
                highlight.FillTransparency = self.options.chamsFillTransparency;
                highlight.OutlineColor = color or self.options.chamsOutlineColor;
                highlight.OutlineTransparency = self.options.chamsOutlineTransparency;
            end
        end

        for object, cache in next, self.objectCache do
            local partPosition = vector3New();

            if (object:IsA("BasePart")) then
                partPosition = object.Position;
            elseif (object:IsA("Model")) then
                partPosition = self.getBoundingBox(object);
            end

            local distance = (currentCamera.CFrame.Position - partPosition).Magnitude;
            local screenPosition, onScreen = worldToViewportPoint(partPosition);
            local canShow = cache.options.enabled and onScreen;

            if (self.options.limitDistance and distance > self.options.maxDistance) then
                canShow = false;
            end

            if (self.options.visibleOnly and not self.visibleCheck(object, partPosition)) then
                canShow = false;
            end

            cache.text.Visible = canShow;
            cache.text.Font = cache.options.font;
            cache.text.Size = cache.options.fontSize;
            cache.text.Transparency = cache.options.transparency;
            cache.text.Color = cache.options.color;
            cache.text.Text = cache.options.text;
            cache.text.Position = round(screenPosition);
        end
    end);
end

return espLibrary;
