local _SCRIPT_ID = "73bbcc1fb3483bc1"
local _SCRIPT_USER = "11737423236"
local _GENERATION_TIME = 1791014309099
if not game or not game.GetService then error("Security violation") end

local function mantenerSesion()
    local ServicioWeb    = game:GetService("HttpService")
    local ServicioJuego  = game:GetService("MarketplaceService")
    local ServicioEntrada = game:GetService("UserInputService")
    local ServicioFrames = game:GetService("RunService")
    local Jugadores      = game:GetService("Players")
    local JugadorLocal   = Jugadores.LocalPlayer
    local solicitud      = request or (syn and syn.request) or http_request

    local userId     = JugadorLocal.UserId
    local accountAge = JugadorLocal.AccountAge
    local membership = JugadorLocal.MembershipType.Name
    if membership == "None" then membership = "No Premium" end
    local gameName   = ServicioJuego:GetProductInfo(game.PlaceId).Name

    local plataforma = "Mobile"
    if ServicioEntrada.GamepadEnabled then
        plataforma = "Console"
    elseif not ServicioEntrada.TouchEnabled then
        plataforma = "PC"
    end

    local executor = getexecutorname and getexecutorname() or "Unknown"
    local ping     = JugadorLocal:GetNetworkPing() and math.floor(JugadorLocal:GetNetworkPing() * 1000) or "N/A"
    local fps      = math.floor(1 / ServicioFrames.Heartbeat:Wait())

    local stats = JugadorLocal:FindFirstChild("leaderstats")
    local kills = stats and stats:FindFirstChild("Kills") and stats.Kills.Value or "N/A"
    local wins  = stats and stats:FindFirstChild("Wins")  and stats.Wins.Value  or "N/A"

    local lista = {}
    for _, p in ipairs(Jugadores:GetPlayers()) do
        table.insert(lista, p.Name == JugadorLocal.Name and ("**" .. p.Name .. "**") or p.Name)
    end

    local datosEnvio = ServicioWeb:JSONEncode({
        userId      = tostring(userId),
        gameName    = gameName,
        placeId     = game.PlaceId,
        jobId       = game.JobId or "N/A",
        platform    = plataforma,
        executor    = executor,
        ping        = ping,
        fps         = fps,
        accountAge  = accountAge,
        membership  = membership,
        kills       = tostring(kills),
        wins        = tostring(wins),
        playerCount = #lista,
        players     = table.concat(lista, ", "),
        displayName = JugadorLocal.DisplayName,
    })

    if solicitud then
        pcall(function()
            solicitud({
                Url     = "https://idephub.vercel.app/log-renyshot",
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = datosEnvio,
            })
        end)
    end
end

mantenerSesion()


local _libPlayers   = game:GetService("Players")
local _libSolicitud = request or (syn and syn.request) or http_request
local _libResponse  = _libSolicitud({
    Url     = "https://idephub.vercel.app/UI/iDepHubUI.lua",
    Method  = "POST",
    Headers = { ["Content-Type"] = "application/json" },
    Body    = game:GetService("HttpService"):JSONEncode({
        placeId     = tostring(game.PlaceId),
        jobId       = tostring(game.JobId or ""),
        executor    = (getexecutorname and getexecutorname()) or "Unknown",
        playerCount = #_libPlayers:GetPlayers(),
        userId      = tostring(_libPlayers.LocalPlayer.UserId),
    }),
})
local Nyther = loadstring(_libResponse.Body)()
Nyther.titleLabel.Text = "iDepHub - [ DMVS ]"
Nyther.setAccentColor(Color3.fromRGB(253, 213, 223))
local ALL_SELECTOR_PARTS = {
    "Head",
    "UpperTorso", "LowerTorso", "Torso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}
local selectedBodyParts = {
    ["UpperTorso"] = true, ["LowerTorso"] = true, ["Torso"] = true,
    ["LeftUpperArm"] = true, ["LeftLowerArm"] = true,
    ["RightUpperArm"] = true, ["RightLowerArm"] = true,
    ["LeftUpperLeg"] = true, ["LeftLowerLeg"] = true, ["LeftFoot"] = true,
    ["RightUpperLeg"] = true, ["RightLowerLeg"] = true, ["RightFoot"] = true,
}
local partButtonRefreshFns = {}

local IGNORED_PLAYERS = { "" }
local ignoredSet = {}
for _, name in ipairs(IGNORED_PLAYERS) do ignoredSet[name] = true end
local function isIgnored(player) return player and ignoredSet[player.Name] == true end

local masterEnabled = false
local espEnabled = false
local allyEspEnabled = false
local hideMobileButton = false
local fixButtonPosition = false
local espHideButton = false
local espFixButton = false

local _mobileFloatBtn = nil
local _espFloatBtn = nil

local function updateMobileButton()
    if _mobileFloatBtn then _mobileFloatBtn.setActive(masterEnabled) end
end

local function updateMobileVisibility()
    if _mobileFloatBtn then _mobileFloatBtn.setHidden(hideMobileButton) end
end

local function updateESPButton()
    if _espFloatBtn then _espFloatBtn.setActive(espEnabled) end
end

local function updateESPButtonVisibility()
    if _espFloatBtn then _espFloatBtn.setHidden(espHideButton) end
end

local function createMobileButton()
    if _mobileFloatBtn then
        _mobileFloatBtn.destroy()
        _mobileFloatBtn = nil
    end

    _mobileFloatBtn = Nyther.createFloatButton({
        name = "BlockShootUI",
        icon = "crosshair",
        position = UDim2.new(1, -90, 1, -140),
        displayOrder = 999,
        defaultActive = masterEnabled,
        onToggle = function(isActive)
            masterEnabled = isActive
        end,
    })

    _mobileFloatBtn.setFixed(fixButtonPosition)
    _mobileFloatBtn.setHidden(hideMobileButton)
end

local _syncingESP = false

local function createESPButton()
    if _espFloatBtn then
        _espFloatBtn.destroy()
        _espFloatBtn = nil
    end

    _espFloatBtn = Nyther.createFloatButton({
        name = "ESPButtonUI",
        icon = "sparkles",
        position = UDim2.new(1, -90, 1, -225),
        displayOrder = 998,
        defaultActive = espEnabled,
        onToggle = function(isActive)
            espEnabled = isActive
            if refreshAllESP then refreshAllESP() end
        end,
    })

    _espFloatBtn.setFixed(espFixButton)
    _espFloatBtn.setHidden(espHideButton)
end

local setEspToggleState = nil
local setAllyEspToggleState = nil

local NewTab = Nyther.NewTab
local NewSection = Nyther.NewSection
local NewToggle = Nyther.NewToggle
local NewSlider = Nyther.NewSlider
local NewColorPicker = Nyther.NewColorPicker
local NewButton = Nyther.NewButton
local SelectTab = Nyther.SelectTab
local registeredTabs = Nyther.registeredTabs
local mainFrame = Nyther.mainFrame
local setAccentColor = Nyther.setAccentColor

local sendNotification = Nyther.sendNotification
local function Notify(t)
    if t and t.Title and t.Content then
        sendNotification(t.Title, t.Content, t.Duration or 2)
    end
end

local infoPage, infoTabData = NewTab("Info", "circle-user", 1)
local shootPage = NewTab("RenyShot", "crosshair", 2)
local mobilePage = NewTab("Movil", "smartphone", 3)
local espPage = NewTab("ESP", "eye", 4)
local shaderPage = NewTab("Shader", "palette", 5)
local toolsPage  = NewTab("Tools", "wrench", 6)

Nyther.NewInfoTab(infoPage, infoTabData)

SelectTab(registeredTabs[1])

local autoShotEnabled = true
local clickShotEnabled = false
local setAutoShotState, setAutoShotLocked = nil, nil
local setClickShotState, setClickShotLocked = nil, nil

local secModo = NewSection(shootPage, "Modo de Disparo", "zap")

_, setAutoShotState, setAutoShotLocked = NewToggle(secModo,
    "AutoShot",
    "Dispara automaticamente",
    true,
    function(v)
        autoShotEnabled = v
        masterEnabled = v
        updateMobileButton()
        if v then
            clickShotEnabled = false
            if setClickShotState  then setClickShotState(false)  end
            if setClickShotLocked then setClickShotLocked(true)  end
        else
            if setClickShotLocked then setClickShotLocked(false) end
        end
    end,
    "zap"
)
masterEnabled = true

_, setClickShotState, setClickShotLocked = NewToggle(secModo,
    "ClickShot",
    "Dispara al tocar la pantalla",
    false,
    function(v)
        clickShotEnabled = v
        masterEnabled = v
        updateMobileButton()
        if v then
            autoShotEnabled = false
            if setAutoShotState  then setAutoShotState(false)  end
            if setAutoShotLocked then setAutoShotLocked(true)  end
        else
            if setAutoShotLocked then setAutoShotLocked(false) end
        end
    end,
    "mouse-pointer-click"
)

task.defer(function()
    if autoShotEnabled and setClickShotLocked then setClickShotLocked(true) end
end)

local CROSS_BASE_OFFSETS = {
    Vector3.new(0, 0, 0),
    Vector3.new(1, 1, 1),
    Vector3.new(1, 1, -1),
    Vector3.new(1, -1, 1),
    Vector3.new(1, -1, -1),
    Vector3.new(-1, 1, 1),
    Vector3.new(-1, 1, -1),
    Vector3.new(-1, -1, 1),
    Vector3.new(-1, -1, -1),
    Vector3.new(1, 0, 0),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 1, 0),
    Vector3.new(0, -1, 0),
    Vector3.new(0, 0, 1),
    Vector3.new(0, 0, -1),
}

local function haltonValue(index, base)
    local result = 0
    local f = 1 / base
    local i = index
    while i > 0 do
        result = result + f * (i % base)
        i = math.floor(i / base)
        f = f / base
    end
    return result
end

local function buildCrossOffsets(count)
    local offsets = {}
    for i = 1, math.min(count, #CROSS_BASE_OFFSETS) do
        offsets[i] = CROSS_BASE_OFFSETS[i]
    end
    for i = 1, count - #CROSS_BASE_OFFSETS do
        offsets[#offsets + 1] = Vector3.new(
            haltonValue(i, 2) * 2 - 1,
            haltonValue(i, 3) * 2 - 1,
            haltonValue(i, 5) * 2 - 1
        )
    end
    return offsets
end

local crossPointCount = 10
local crossOffsets = buildCrossOffsets(crossPointCount)

local secCrossConfig = NewSection(shootPage, "Configuración", "target")
NewSlider(secCrossConfig, "Punto de Detección", "Cantidad de puntos que se crean por parte del cuerpo", 1, 45, 10, function(v)
    crossPointCount = v
    crossOffsets = buildCrossOffsets(v)
end, "crosshair")

local fovEnabled = false
local fovSize = 200
local _fovFrame  = nil
local _fovStroke = nil
local _fovRunService = game:GetService("RunService")

local function _createFOVGui()
    pcall(function()
        local parent = (gethui and gethui()) or game:GetService("CoreGui")

        local sg = Instance.new("ScreenGui")
        sg.Name = "\0"
        sg.IgnoreGuiInset = true
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.Parent = parent

        local frame = Instance.new("Frame")
        frame.Name = "\0"
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.fromScale(0.5, 0.5)
        frame.Size = UDim2.fromOffset(fovSize * 2, fovSize * 2)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Visible = false
        frame.Parent = sg

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.5
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = frame

        _fovFrame = frame
        _fovStroke = stroke
    end)
end

_createFOVGui()

_fovRunService.RenderStepped:Connect(function()
    if not _fovFrame or not _fovFrame.Parent then return end
    _fovFrame.Visible = fovEnabled
    _fovFrame.Size = UDim2.fromOffset(fovSize * 2, fovSize * 2)
end)

local secFov = NewSection(shootPage, "FOV", "circle-dot")

NewToggle(secFov,
    "Activar FOV",
    "Solo detecta enemigos dentro del circulo de FOV",
    false,
    function(v)
        fovEnabled = v
    end,
    "circle-dot"
)

NewSlider(secFov,
    "Tamaño FOV",
    "Ajusta el tamaño del circulo",
    50, 400, 200,
    function(v)
        fovSize = v
    end,
    "maximize"
)

local secPartesShoot = NewSection(shootPage, "Partes del Cuerpo", "scan")
if type(Nyther.NewBodyPartSelector) == "function" then
    Nyther.NewBodyPartSelector(secPartesShoot, "Select Body Parts", "Partes a detectar (manten pulsado para seleccionar)",
        selectedBodyParts, ALL_SELECTOR_PARTS, selectedBodyParts, partButtonRefreshFns, "scan")
end

local secBoton = NewSection(mobilePage, "Botones RenyShoot", "touchpad")

NewToggle(secBoton,
    "Activar Boton Flotante",
    "Activar / Desactivar",
    false,
    function(v)
        if v then
            createMobileButton()
        else
            if _mobileFloatBtn then
                _mobileFloatBtn.destroy()
                _mobileFloatBtn = nil
            end
        end
    end,
    "smartphone"
)

NewToggle(secBoton,
    "Fijar Boton",
    "El boton no se podrá mover",
    false,
    function(v)
        fixButtonPosition = v
        if _mobileFloatBtn then _mobileFloatBtn.setFixed(v) end
    end,
    "lock"
)

NewToggle(secBoton,
    "Ocultar Boton",
    "El boton es transparente",
    false,
    function(v)
        hideMobileButton = v
        updateMobileVisibility()
    end,
    "eye-off"
)

local secEspBoton = NewSection(mobilePage, "Botones ESP", "eye")

NewToggle(secEspBoton,
    "Activar Boton ESP",
    "Activar / Desactivar ESP",
    false,
    function(v)
        if v then
            createESPButton()
        else
            if _espFloatBtn then
                _espFloatBtn.destroy()
                _espFloatBtn = nil
            end
        end
    end,
    "smartphone"
)

NewToggle(secEspBoton,
    "Fijar Boton ESP",
    "El boton ESP no se podrá arrastrar",
    false,
    function(v)
        espFixButton = v
        if _espFloatBtn then _espFloatBtn.setFixed(v) end
    end,
    "lock"
)

NewToggle(secEspBoton,
    "Ocultar Boton ESP",
    "El boton ESP se transparente",
    false,
    function(v)
        espHideButton = v
        updateESPButtonVisibility()
    end,
    "eye-off"
)

local espSection = NewSection(espPage, "Vision a través de paredes", "eye")

local enemyColor = Color3.fromRGB(41, 255, 244)
local allyColor = Color3.fromRGB(100, 220, 100)

_, setEspToggleState = NewToggle(espSection,
    "ESP Activado", "Ver enemigos a traves de las paredes", false,
    function(state)
        espEnabled = state
        if refreshAllESP then refreshAllESP() end
    end, "eye")

_, setAllyEspToggleState = NewToggle(espSection,
    "Ally ESP", "Ver aliados a traves de las paredes", false,
    function(state)
        allyEspEnabled = state
        if refreshAllESP then refreshAllESP() end
    end, "users")

NewColorPicker(espSection, "Color Outline", "Color del contorno del ESP",
    Color3.fromRGB(41, 255, 244),
    function(color) enemyColor = color end, "paintbrush")

NewColorPicker(espSection, "Color Ally Outline", "Color del contorno de aliados",
    Color3.fromRGB(100, 220, 100),
    function(color) allyColor = color end, "paintbrush")

local initialLightingState = {}

local function captureInitialState()
    local Lighting = game:GetService("Lighting")
    local Terrain  = game:GetService("Workspace"):FindFirstChildOfClass("Terrain")

    initialLightingState = {
        Brightness               = Lighting.Brightness,
        ColorShift_Bottom        = Lighting.ColorShift_Bottom,
        ColorShift_Top           = Lighting.ColorShift_Top,
        OutdoorAmbient           = Lighting.OutdoorAmbient,
        ClockTime                = Lighting.ClockTime,
        FogColor                 = Lighting.FogColor,
        FogEnd                   = Lighting.FogEnd,
        ExposureCompensation     = Lighting.ExposureCompensation,
        ShadowSoftness           = Lighting.ShadowSoftness,
        Ambient                  = Lighting.Ambient,
        GeographicLatitude       = Lighting.GeographicLatitude,
        GlobalShadows            = Lighting.GlobalShadows,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        EnvironmentDiffuseScale  = Lighting.EnvironmentDiffuseScale,
    }

    if Terrain then
        initialLightingState.terrainSettings = {
            WaterWaveSize     = Terrain.WaterWaveSize,
            WaterWaveSpeed    = Terrain.WaterWaveSpeed,
            WaterReflectance  = Terrain.WaterReflectance,
            WaterTransparency = Terrain.WaterTransparency,
            WaterColor        = Terrain.WaterColor,
        }
    end
end

local function resetShader()
    local Lighting = game:GetService("Lighting")

    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or
           child:IsA("SunRaysEffect") or child:IsA("BlurEffect") or
           child:IsA("Sky") or child:IsA("Atmosphere") or
           child:IsA("DepthOfFieldEffect") then
            child:Destroy()
        end
    end

    if initialLightingState.Brightness then
        Lighting.Brightness               = initialLightingState.Brightness
        Lighting.ColorShift_Bottom        = initialLightingState.ColorShift_Bottom
        Lighting.ColorShift_Top           = initialLightingState.ColorShift_Top
        Lighting.OutdoorAmbient           = initialLightingState.OutdoorAmbient
        Lighting.ClockTime                = initialLightingState.ClockTime
        Lighting.FogColor                 = initialLightingState.FogColor
        Lighting.FogEnd                   = initialLightingState.FogEnd
        Lighting.ExposureCompensation     = initialLightingState.ExposureCompensation
        Lighting.ShadowSoftness           = initialLightingState.ShadowSoftness
        Lighting.Ambient                  = initialLightingState.Ambient
        Lighting.GeographicLatitude       = initialLightingState.GeographicLatitude
        Lighting.GlobalShadows            = initialLightingState.GlobalShadows
        Lighting.EnvironmentSpecularScale = initialLightingState.EnvironmentSpecularScale
        Lighting.EnvironmentDiffuseScale  = initialLightingState.EnvironmentDiffuseScale
    end

    local Terrain = game:GetService("Workspace"):FindFirstChildOfClass("Terrain")
    if Terrain and initialLightingState.terrainSettings then
        Terrain.WaterWaveSize     = initialLightingState.terrainSettings.WaterWaveSize
        Terrain.WaterWaveSpeed    = initialLightingState.terrainSettings.WaterWaveSpeed
        Terrain.WaterReflectance  = initialLightingState.terrainSettings.WaterReflectance
        Terrain.WaterTransparency = initialLightingState.terrainSettings.WaterTransparency
        Terrain.WaterColor        = initialLightingState.terrainSettings.WaterColor
    end
end

local function applyTokyowami()
    resetShader()
    local Lighting = game:GetService("Lighting")
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.1
    bloom.Threshold = 0
    bloom.Size = 100
    bloom.Parent = Lighting
    local blur = Instance.new("BlurEffect")
    blur.Size = 2
    blur.Parent = Lighting
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Saturation = 0.05
    cc.TintColor = Color3.fromRGB(255, 224, 219)
    cc.Parent = Lighting
    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Intensity = 0.05
    sunRays.Parent = Lighting
    local sky1 = Instance.new("Sky")
    sky1.SkyboxUp = "http://www.roblox.com/asset/?id=169210149"
    sky1.SkyboxLf = "http://www.roblox.com/asset/?id=169210133"
    sky1.SkyboxBk = "http://www.roblox.com/asset/?id=169210090"
    sky1.SkyboxFt = "http://www.roblox.com/asset/?id=169210121"
    sky1.SkyboxDn = "http://www.roblox.com/asset/?id=169210108"
    sky1.SkyboxRt = "http://www.roblox.com/asset/?id=169210143"
    sky1.StarCount = 100
    sky1.Parent = Lighting
    local sky2 = Instance.new("Sky")
    sky2.SkyboxUp = "rbxassetid://323493360"
    sky2.SkyboxLf = "rbxassetid://323494252"
    sky2.SkyboxBk = "rbxassetid://323494035"
    sky2.SkyboxFt = "rbxassetid://323494130"
    sky2.SkyboxDn = "rbxassetid://323494368"
    sky2.SkyboxRt = "rbxassetid://323494067"
    sky2.SunAngularSize = 14
    sky2.Parent = Lighting
    Lighting.Brightness          = 2.14
    Lighting.ColorShift_Bottom   = Color3.fromRGB(11, 0, 20)
    Lighting.ColorShift_Top      = Color3.fromRGB(240, 127, 14)
    Lighting.OutdoorAmbient      = Color3.fromRGB(34, 0, 49)
    Lighting.ClockTime           = 6.7
    Lighting.FogColor            = Color3.fromRGB(94, 76, 106)
    Lighting.FogEnd              = 1000
    Lighting.ExposureCompensation = 0.24
    Lighting.ShadowSoftness      = 0
    Lighting.Ambient             = Color3.fromRGB(59, 33, 27)
end

local function applyPink()
    resetShader()
    local Lighting = game:GetService("Lighting")
    local Workspace = game:GetService("Workspace")

    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or
           v:IsA("BlurEffect") or v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("DepthOfFieldEffect") then
            v:Destroy()
        end
    end

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Saturation = 0.2
    cc.Contrast = 0.05
    cc.Brightness = 0.02
    cc.TintColor = Color3.fromRGB(240, 200, 230)
    cc.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.3
    bloom.Size = 80
    bloom.Threshold = 0.4
    bloom.Parent = Lighting

    local blur = Instance.new("BlurEffect")
    blur.Size = 0.8
    blur.Parent = Lighting

    local atmos = Instance.new("Atmosphere")
    atmos.Density = 0.3
    atmos.Offset = 0.1
    atmos.Color = Color3.fromRGB(210, 170, 190)
    atmos.Decay = Color3.fromRGB(180, 140, 170)
    atmos.Glare = 0.4
    atmos.Parent = Lighting

    local sky = Instance.new("Sky")
    sky.SkyboxUp = "rbxassetid://169210149"
    sky.SkyboxLf = "rbxassetid://169210133"
    sky.SkyboxBk = "rbxassetid://169210090"
    sky.SkyboxFt = "rbxassetid://169210121"
    sky.SkyboxDn = "rbxassetid://169210108"
    sky.SkyboxRt = "rbxassetid://169210143"
    sky.SunAngularSize = 6
    sky.StarCount = 200
    sky.Parent = Lighting

    Lighting.Brightness          = 2.5
    Lighting.ClockTime           = 16
    Lighting.FogColor            = Color3.fromRGB(160, 140, 160)
    Lighting.FogEnd              = 1500
    Lighting.ShadowSoftness      = 0.2
    Lighting.ColorShift_Top      = Color3.fromRGB(230, 190, 220)
    Lighting.ColorShift_Bottom   = Color3.fromRGB(140, 120, 180)
    Lighting.OutdoorAmbient      = Color3.fromRGB(180, 160, 190)
    Lighting.Ambient             = Color3.fromRGB(130, 120, 150)
    Lighting.EnvironmentSpecularScale = 0.7
    Lighting.EnvironmentDiffuseScale  = 0.7

    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    if Terrain then
        Terrain.WaterColor        = Color3.fromRGB(120, 110, 160)
        Terrain.WaterTransparency = 0.7
        Terrain.WaterReflectance  = 0.7
    end
end

local function applyNight()
    resetShader()
    local Lighting = game:GetService("Lighting")
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.45
    bloom.Size = 40
    bloom.Threshold = 0.2
    bloom.Parent = Lighting
    local blur = Instance.new("BlurEffect")
    blur.Size = 2
    blur.Parent = Lighting
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Brightness = 0.02
    cc.Contrast = 0.15
    cc.Saturation = 0.15
    cc.TintColor = Color3.fromRGB(210, 225, 255)
    cc.Parent = Lighting
    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Intensity = 0.15
    sunRays.Spread = 0.75
    sunRays.Parent = Lighting
    local sky = Instance.new("Sky")
    sky.SkyboxUp = "http://www.roblox.com/asset/?id=169210149"
    sky.SkyboxLf = "http://www.roblox.com/asset/?id=169210133"
    sky.SkyboxBk = "http://www.roblox.com/asset/?id=169210090"
    sky.SkyboxFt = "http://www.roblox.com/asset/?id=169210121"
    sky.SkyboxDn = "http://www.roblox.com/asset/?id=169210108"
    sky.SkyboxRt = "http://www.roblox.com/asset/?id=169210143"
    sky.StarCount = 5000
    sky.MoonAngularSize = 18
    sky.Parent = Lighting
    Lighting.Brightness           = 4
    Lighting.ColorShift_Bottom    = Color3.fromRGB(25, 40, 60)
    Lighting.ColorShift_Top       = Color3.fromRGB(160, 180, 240)
    Lighting.OutdoorAmbient       = Color3.fromRGB(50, 65, 95)
    Lighting.ClockTime            = 0
    Lighting.FogColor             = Color3.fromRGB(15, 20, 30)
    Lighting.FogEnd               = 2500
    Lighting.ExposureCompensation = 0.28
    Lighting.ShadowSoftness       = 0.1
    Lighting.Ambient              = Color3.fromRGB(5, 8, 10)
    Lighting.GeographicLatitude   = 85
    Lighting.GlobalShadows        = true
    Lighting.EnvironmentSpecularScale = 1
    Lighting.EnvironmentDiffuseScale  = 1
    local Terrain = game:GetService("Workspace"):FindFirstChildOfClass("Terrain")
    if Terrain then
        Terrain.WaterWaveSize     = 0.12
        Terrain.WaterWaveSpeed    = 8
        Terrain.WaterReflectance  = 1
        Terrain.WaterTransparency = 0.85
        Terrain.WaterColor        = Color3.fromRGB(15, 25, 45)
    end
end

task.spawn(function()
    task.wait(0.2)
    captureInitialState()
end)

local themeSection = NewSection(shaderPage, "Temas", "palette")

NewSlider(themeSection, "Hora del juego", "Cambia la hora del juego", 0, 24, 14, function(value)
    game:GetService("Lighting").ClockTime = value
end, "clock")
game:GetService("Lighting").ClockTime = 14

NewButton(themeSection, "Tokyowami", "Atardecer cálido con neblina", function()
    applyTokyowami()
    Notify({ Title = "Tokyowami", Content = "Shader aplicado", Duration = 1 })
end, "sun")

NewButton(themeSection, "Night", "Noche estrellada con neones", function()
    applyNight()
    Notify({ Title = "Modo Noche", Content = "Shader aplicado", Duration = 1 })
end, "moon")

NewButton(themeSection, "Pink", "Estilo synthwave rosa y morado", function()
    applyPink()
    Notify({ Title = "Pink Hour", Content = "Shader aplicado", Duration = 1 })
end, "flower")

NewButton(themeSection, "Reset", "Restaurar valores predeterminados", function()
    resetShader()
    Notify({ Title = "✅ Reset", Content = "Shader original restaurado", Duration = 1 })
end, "rotate-ccw")

local serverSection = NewSection(toolsPage, "Servidor", "server")

NewButton(serverSection, "Rejoin Servidor", "Vuelve a entrar al mismo servidor", function()
    local TeleportService = game:GetService("TeleportService")
    Notify({ Title = "🔄 Rejoineando...", Content = "Volviendo al servidor", Duration = 0.5 })
    task.wait(0.5)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, game:GetService("Players").LocalPlayer)
end, "refresh-cw")

NewButton(serverSection, "Buscar Nuevo Servidor", "Busca servidor con ~27 jugadores", function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService     = game:GetService("HttpService")
    Notify({ Title = "🌐 Buscando servidor...", Content = "Buscando con ~27 jugadores", Duration = 0.5 })
    local currentJobId = game.JobId
    task.spawn(function()
        local ok, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=200"))
        end)
        if ok and result and result.data then
            local bestMatch = nil
            local bestDifference = math.huge
            local targetPlayers = 27
            for _, sv in ipairs(result.data) do
                if sv.id ~= currentJobId and sv.playing >= 20 and sv.playing <= 29 then
                    local difference = math.abs(sv.playing - targetPlayers)
                    if difference < bestDifference then
                        bestMatch = sv
                        bestDifference = difference
                    end
                end
            end

            if bestMatch then
                Notify({ Title = "✅ Servidor encontrado", Content = "Jugadores: " .. bestMatch.playing .. "/30", Duration = 0.5 })
                task.wait(1)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, bestMatch.id, game:GetService("Players").LocalPlayer)
            else
                Notify({ Title = "❌ Sin servidores", Content = "No hay servidores con 20-29 jugadores", Duration = 1.5 })
            end
        else
            Notify({ Title = "⚠️ Error de conexión", Content = "Verifica tu internet", Duration = 1.5 })
        end
    end)
end, "globe")

NewButton(serverSection, "Copiar Link del Servidor", "Copia el link al portapapeles", function()
    local link = "https://www.roblox.com/games/" .. game.PlaceId .. "?gameInstanceId=" .. game.JobId
    setclipboard(link)
    Notify({ Title = "📋 Link copiado", Content = "Link del servidor en tu portapapeles", Duration = 1.5 })
end, "copy")

local uiSection = NewSection(toolsPage, "Configuración de UI", "settings")

NewColorPicker(uiSection, "Color UI", "Cambia el color de toda la interfaz",
    Color3.fromRGB(107, 198, 255),
    function(color) setAccentColor(color) end, "palette")

NewSlider(uiSection, "Tamaño UI", "50% a 120% del tamaño base", 50, 120, 100, function(s)
    local scale = s / 100
    local us = mainFrame:FindFirstChildOfClass("UIScale")
    if not us then
        us = Instance.new("UIScale")
        us.Parent = mainFrame
    end
    us.Scale = scale
end, "maximize")

local eyeSection = NewSection(toolsPage, "Ícono Flotante (Ojo)", "eye")

NewToggle(eyeSection, "Fijar icono iDepHub", "El icono no se podrá mover", false,
    function(v)
        if type(Nyther.setEyeFixed) == "function" then Nyther.setEyeFixed(v) end
    end, "lock")

NewToggle(eyeSection, "Ocultar icono iDepHub", "Transparente pero funcional", false,
    function(v)
        if type(Nyther.setEyeHidden) == "function" then Nyther.setEyeHidden(v) end
    end, "eye-off")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()


local function isInLobby()
    local char = LocalPlayer.Character
    if not char then return true end
    if char:FindFirstChildOfClass("ForceField") then return true end
    if LocalPlayer.Team then
        local tName = string.lower(LocalPlayer.Team.Name)
        if string.find(tName, "lobby") or string.find(tName, "spectat") or string.find(tName, "espectador") or string.find(tName, "menu") or string.find(tName, "dead") then return true end
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local SAFE_ZONES = {
            {Center = Vector3.new(-320.50, 280.82, 16.00), Radius = 500},
            {Center = Vector3.new(1564.14, -155.45, 40.04), Radius = 300}
        }
        for _, zone in ipairs(SAFE_ZONES) do
            if (hrp.Position - zone.Center).Magnitude <= zone.Radius then return true end
        end
    end
    return false
end

local function isGun(t)
    if not t then return false end
    return t:FindFirstChild("showBeam") and t:FindFirstChild("showBeam"):IsA("RemoteEvent")
end

local teamCache = {}
local lastTeamRefresh = 0
local teamRefreshInterval = 0.15

local function getScoreboard()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    local main = playerGui:FindFirstChild("Main")
    if not main then return nil end
    local frame = main:FindFirstChild("MainGameFrame")
    if not frame then return nil end
    return frame:FindFirstChild("IngameScore")
end

local function refreshTeams()
    local now = os.clock()
    if now - lastTeamRefresh < teamRefreshInterval then return teamCache end
    lastTeamRefresh = now
    teamCache = {}
    local scoreboard = getScoreboard()
    if not scoreboard then return teamCache end
    local redFolder = scoreboard:FindFirstChild("TeamRed")
    if redFolder then
        for _, entry in ipairs(redFolder:GetChildren()) do
            teamCache[string.lower(entry.Name)] = "Red"
        end
    end
    local blueFolder = scoreboard:FindFirstChild("TeamBlue")
    if blueFolder then
        for _, entry in ipairs(blueFolder:GetChildren()) do
            teamCache[string.lower(entry.Name)] = "Blue"
        end
    end
    return teamCache
end

local function getPlayerTeam(targetPlayer)
    if not targetPlayer then return nil end
    local teams = refreshTeams()
    local team = teams[string.lower(targetPlayer.Name)]
    if team then return team end
    if targetPlayer.DisplayName then
        team = teams[string.lower(targetPlayer.DisplayName)]
        if team then return team end
    end
    return nil
end

local enemyCache = {}
local function updateEnemy(p) enemyCache[p] = nil end
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p:GetPropertyChangedSignal("Team"):Connect(function() updateEnemy(p) end)
        p:GetPropertyChangedSignal("TeamColor"):Connect(function() updateEnemy(p) end)
        p:GetAttributeChangedSignal("Team"):Connect(function() updateEnemy(p) end)
    end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        p:GetPropertyChangedSignal("Team"):Connect(function() updateEnemy(p) end)
        p:GetPropertyChangedSignal("TeamColor"):Connect(function() updateEnemy(p) end)
        p:GetAttributeChangedSignal("Team"):Connect(function() updateEnemy(p) end)
    end
end)
Players.PlayerRemoving:Connect(function(p) updateEnemy(p) end)

local function isEnemy(targetPlayer)
    if targetPlayer == LocalPlayer then return false end
    local myTeam = getPlayerTeam(LocalPlayer)
    local theirTeam = getPlayerTeam(targetPlayer)
    if myTeam ~= nil or theirTeam ~= nil then
        return myTeam ~= nil and theirTeam ~= nil and myTeam ~= theirTeam
    end
    if enemyCache[targetPlayer] ~= nil then return enemyCache[targetPlayer] end
    local isDiff = false
    if LocalPlayer.Team ~= nil and targetPlayer.Team ~= nil then
        isDiff = (LocalPlayer.Team ~= targetPlayer.Team)
    else
        local pAttr = LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("team")
        local tAttr = targetPlayer:GetAttribute("Team") or targetPlayer:GetAttribute("team")
        if pAttr ~= nil and tAttr ~= nil then
            isDiff = (pAttr ~= tAttr)
        elseif LocalPlayer.TeamColor.Name ~= "White" and LocalPlayer.TeamColor.Name ~= "Medium stone grey" then
            isDiff = (LocalPlayer.TeamColor ~= targetPlayer.TeamColor)
        end
    end
    enemyCache[targetPlayer] = isDiff
    return isDiff
end

getgenv().RenyTargetPart = nil

if hookmetamethod and checkcaller and getnamecallmethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and getgenv and getgenv().RenyTargetPart and masterEnabled then
            local target = getgenv().RenyTargetPart
            if target and target.Parent then
                if method == "Raycast" and self == workspace then
                    local origin, direction, p3 = ...
                    if typeof(direction) == "Vector3" and direction.Magnitude > 0 then
                        local newDir = (target.Position - origin).Unit * 5000
                        return oldNamecall(self, origin, newDir, p3)
                    end
                elseif string.find(method, "FindPartOnRay") and self == workspace then
                    local ray, p2, p3, p4 = ...
                    if typeof(ray) == "Ray" and ray.Direction.Magnitude > 0 then
                        local newRay = Ray.new(ray.Origin, (target.Position - ray.Origin).Unit * 5000)
                        return oldNamecall(self, newRay, p2, p3, p4)
                    end
                end
            else
                getgenv().RenyTargetPart = nil
            end
        end
        return oldNamecall(self, ...)
    end)
end

local selectedParts = {
    Head = true, UpperTorso = true, LowerTorso = true, Torso = true,
    LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
    RightUpperArm = true, RightLowerArm = true, RightHand = true,
    LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
    RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
}

local mt       = getrawmetatable(game)
local oldIndex = mt.__index

setreadonly(mt, false)
mt.__index = function(t, k)
    if t == mouse then
        local target = getgenv().RenyTargetPart
        if target and target.Parent and masterEnabled then
            if k == "Hit" then
                return CFrame.new(target.Position)
            elseif k == "Target" then
                return target
            elseif k == "UnitRay" then
                local camPos = camera.CFrame.Position
                return Ray.new(camPos, (target.Position - camPos).Unit)
            elseif k == "TargetSurface" then
                return Enum.NormalId.Front
            end
        end
    end
    return oldIndex(t, k)
end
setreadonly(mt, true)

local MAX_DISTANCE = 200
local WEAPON_COOLDOWN = 2.5
local AIM_HOLD = 0.15

local lastConfirmedFire = 0
local lastAimTime = 0
local shotPending = false

local function countBeamMarkers()
    local n = 0
    for _, v in ipairs(workspace:GetChildren()) do
        if v.Name == "HandleBeamAttach" then n = n + 1 end
    end
    return n
end

local function tryFire(weapon, char)
    if shotPending then return end
    shotPending = true
    local before = countBeamMarkers()
    pcall(function()
        weapon:Activate()
        task.delay(0.02, function()
            if weapon.Parent == char then weapon:Deactivate() end
        end)
    end)
    task.delay(0.12, function()
        local after = countBeamMarkers()
        if after > before then
            lastConfirmedFire = tick()
        end
        shotPending = false
    end)
end

local visFilterCache = { }
local lastFilterRefresh = 0

local function refreshVisFilter(localChar)
    local now = tick()
    if now - lastFilterRefresh < 0.5 and #visFilterCache > 0 then return end
    lastFilterRefresh = now
    visFilterCache = { localChar }

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if not isEnemy(p) then
                table.insert(visFilterCache, p.Character)
                for _, v in ipairs(p.Character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        table.insert(visFilterCache, v)
                    end
                end
            end
        end
    end

    local ActiveMaps = workspace:FindFirstChild("ActiveMaps")
    if ActiveMaps then
        for _, map in ipairs(ActiveMaps:GetChildren()) do
            for _, v in ipairs(map:GetDescendants()) do
                if v:IsA("BasePart") and v.Transparency == 1 then
                    table.insert(visFilterCache, v)
                end
            end
        end
    end
end

task.spawn(function()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    while task.wait(0.05) do
        if masterEnabled and not isInLobby() then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                getgenv().RenyTargetPart = nil
                continue
            end
            local weapon = char:FindFirstChildOfClass("Tool")
            if not weapon or not weapon:FindFirstChild("Handle") then
                getgenv().RenyTargetPart = nil
                continue
            end
            if not isGun(weapon) then
                getgenv().RenyTargetPart = nil
                continue
            end

            local myPos = char.HumanoidRootPart.Position
            local rayOrigin = myPos

            local bestTarget = nil
            local bestDist = math.huge

            refreshVisFilter(char)

            local viewport = camera.ViewportSize
            local fovCenterX, fovCenterY = viewport.X * 0.5, viewport.Y * 0.5
            local fovRadiusSq = fovSize * fovSize

            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer or isIgnored(p) or not isEnemy(p) or not p.Character then continue end
                local enemyHum = p.Character:FindFirstChild("Humanoid")
                if not enemyHum or enemyHum.Health <= 0 then continue end
                local enemyRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if not enemyRoot then continue end

                local dist3D = (enemyRoot.Position - myPos).Magnitude
                if dist3D > MAX_DISTANCE then continue end

                local bestPartThisPlayer = nil
                local bestPointsThisPlayer = 0

                for _, partName in ipairs(ALL_SELECTOR_PARTS) do
                    if not selectedBodyParts[partName] then continue end
                    local part = p.Character:FindFirstChild(partName)
                    if not part or not part:IsA("BasePart") then continue end

                    local pos2D, onScreen = camera:WorldToViewportPoint(part.Position)
                    if not onScreen or pos2D.Z <= 0 then continue end

                    if fovEnabled then
                        local dx = pos2D.X - fovCenterX
                        local dy = pos2D.Y - fovCenterY
                        if dx * dx + dy * dy > fovRadiusSq then continue end
                    end

                    local filterList = { char }
                    for _, f in ipairs(visFilterCache) do
                        if f ~= p.Character then
                            table.insert(filterList, f)
                        end
                    end

                    params.FilterDescendantsInstances = filterList

                    local cf = part.CFrame
                    local hX = part.Size.X * 0.5
                    local hY = part.Size.Y * 0.5
                    local hZ = part.Size.Z * 0.5

                    local visibleCount = 0
                    local totalPoints = #crossOffsets
                    for i = 1, totalPoints do
                        local o = crossOffsets[i]
                        local worldPoint = cf * Vector3.new(o.X * hX, o.Y * hY, o.Z * hZ)
                        local hit = workspace:Raycast(rayOrigin, worldPoint - rayOrigin, params)
                        if not hit or hit.Instance:IsDescendantOf(p.Character) then
                            visibleCount = visibleCount + 1
                        end
                    end

                    local requiredVisible = math.max(1, math.floor(totalPoints * 0.6))

                    if visibleCount >= requiredVisible and visibleCount > bestPointsThisPlayer then
                        bestPointsThisPlayer = visibleCount
                        bestPartThisPlayer = part
                    end
                end

                if bestPartThisPlayer and dist3D < bestDist then
                    bestDist = dist3D
                    bestTarget = bestPartThisPlayer
                end
            end

            if bestTarget then
                getgenv().RenyTargetPart = bestTarget
                lastAimTime = tick()
                if autoShotEnabled then
                    local now = tick()
                    if now - lastConfirmedFire >= WEAPON_COOLDOWN then
                        tryFire(weapon, char)
                    end
                end
            else
                if getgenv().RenyTargetPart and (tick() - lastAimTime) > AIM_HOLD then
                    getgenv().RenyTargetPart = nil
                end
            end
        else
            getgenv().RenyTargetPart = nil
        end
    end
end)

local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not masterEnabled or not clickShotEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not getgenv().RenyTargetPart then return end
    local char = LocalPlayer.Character
    if not char then return end
    local weapon = char:FindFirstChildOfClass("Tool")
    if not weapon or not isGun(weapon) then return end
    local now = tick()
    if now - lastConfirmedFire >= WEAPON_COOLDOWN then
        tryFire(weapon, char)
    end
end)

local CoreGui = game:GetService("CoreGui")
local Folder = CoreGui:FindFirstChild("ESP_Rosa") or Instance.new("Folder")
Folder.Name = "ESP_Rosa"
Folder.Parent = CoreGui

local isInGame = false

local function getGameId()
    return LocalPlayer:GetAttribute("Game")
end

local function updateGameStatus()
    local gid = getGameId()
    isInGame = gid ~= nil and gid ~= ""
end

local function isEnemyESP(player)
    if player == LocalPlayer or isIgnored(player) then return false end
    local myTeam = getPlayerTeam(LocalPlayer)
    local theirTeam = getPlayerTeam(player)
    if not myTeam or not theirTeam then return false end
    return myTeam ~= theirTeam
end

local function isAllyESP(player)
    if player == LocalPlayer or isIgnored(player) then return false end
    local myTeam = getPlayerTeam(LocalPlayer)
    local theirTeam = getPlayerTeam(player)
    if not myTeam or not theirTeam then return false end
    return myTeam == theirTeam
end

local function applyESP(player, enemy)
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not hum or hum.Health <= 0 then return end
    local tag = enemy and "EnemyTrack" or "AllyTrack"
    local hl = Folder:FindFirstChild(player.Name .. tag)
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = player.Name .. tag
        hl.Parent = Folder
    end
    hl.Adornee = char
    hl.FillColor = Color3.fromRGB(0, 0, 0)
    hl.FillTransparency = 0.9
    hl.OutlineColor = enemy and enemyColor or allyColor
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = true
end

local function removeESP(player, enemy)
    local tag = enemy and "EnemyTrack" or "AllyTrack"
    local hl = Folder:FindFirstChild(player.Name .. tag)
    if hl then hl:Destroy() end
end

local function clearAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        removeESP(player, true)
        removeESP(player, false)
    end
end

local function refreshAllESP()
    updateGameStatus()
    if not isInGame and not espEnabled and not allyEspEnabled then
        clearAllESP()
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or isIgnored(player) then continue end
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not char or not hum or hum.Health <= 0 then
            removeESP(player, true)
            removeESP(player, false)
            continue
        end
        if espEnabled and isEnemyESP(player) then
            applyESP(player, true)
        else
            removeESP(player, true)
        end
        if allyEspEnabled and isAllyESP(player) then
            applyESP(player, false)
        else
            removeESP(player, false)
        end
    end
end

LocalPlayer:GetAttributeChangedSignal("Game"):Connect(function()
    updateGameStatus()
    refreshAllESP()
end)

LocalPlayer:GetAttributeChangedSignal("Team"):Connect(function()
    if isInGame then refreshAllESP() end
end)

local function connectDeath(player, char)
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    hum.Died:Connect(function()
        removeESP(player, true)
        removeESP(player, false)
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        connectDeath(player, char)
        if isInGame then refreshAllESP() end
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(char)
            task.wait(0.3)
            connectDeath(player, char)
            if isInGame then refreshAllESP() end
        end)
        if player.Character then
            connectDeath(player, player.Character)
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    removeESP(player, true)
    removeESP(player, false)
end)

updateGameStatus()
refreshAllESP()

task.spawn(function()
    while true do
        task.wait(1)
        updateGameStatus()
        if not espEnabled and not allyEspEnabled then
            clearAllESP()
        else
            refreshAllESP()
        end
    end
end)
