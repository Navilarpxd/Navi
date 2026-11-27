--[[
    DEOBFBYSZK - Murderers VS Sheriffs
    MADE BY SZK
    Discord: https://discord.gg/f4JfyAFCN
]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

if not WindUI then
    warn("[DEOBFBYSZK] WindUI no cargo")
    return
end

local setclipboard = setclipboard or function() end
local getgenv = getgenv or function() return _G end

local DISCORD_INVITE = "https://discord.gg/f4JfyAFCN"
local UNLOAD_KEY = "__DEOBFBYSZK_UNLOAD"
local IS_UNLOADING = false

pcall(function()
    local env = getgenv()
    if type(env[UNLOAD_KEY]) == "function" then
        env[UNLOAD_KEY]()
    end
end)

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local LocalPlayer       = Players.LocalPlayer

local function IsMobile()
    local ok, platform = pcall(function() return UserInputService:GetPlatform() end)
    if ok and (platform == Enum.Platform.Android or platform == Enum.Platform.IOS) then
        return true
    end
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end
local IS_MOBILE = IsMobile()

local function GetCursorPosition()
    if IS_MOBILE then
        local cam = workspace.CurrentCamera
        return cam and (cam.ViewportSize / 2) or Vector2.zero
    end
    return UserInputService:GetMouseLocation()
end

local ALLY_LOOKUP = { [8343463328] = true }
local IsAlly = {}
function IsAlly:check(player)
    if not player then return false end
    return ALLY_LOOKUP[player.UserId] == true
end

local ConnectionBucket = {}
ConnectionBucket.__index = ConnectionBucket
function ConnectionBucket.new() return setmetatable({ _conns = {} }, ConnectionBucket) end
function ConnectionBucket:add(obj) self._conns[#self._conns + 1] = obj; return obj end
function ConnectionBucket:clear()
    for i = #self._conns, 1, -1 do
        local obj = self._conns[i]
        self._conns[i] = nil
        local t = typeof(obj)
        if t == "RBXScriptConnection" then pcall(function() obj:Disconnect() end)
        elseif t == "Instance" then pcall(function() obj:Destroy() end)
        elseif t == "function" then pcall(obj) end
    end
end

local Config = {
    Notifications = { Enabled = true },
    ESP = { Enabled = false, ShowName = false, Lines = false, Color = Color3.fromRGB(0,255,0), LinesColor = Color3.fromRGB(0,255,0) },
    Hitbox = { Enabled = false, Size = 4, Show = true, Opacity = 5.5, Color = Color3.fromRGB(255,0,0) },
    Bubbles = { SilentAim = false, KillAll = false, Invisible = false, Desync = false, AutoShoot = false },
    PlayerCheats = { JumpPowerEnabled = false, JumpPower = 25, InfiniteJump = false, SpeedEnabled = false, Speed = 24 },
    AutoTeleport = { Main = false, Alt = false, DuelType = "1v1", PlatformRow = "Right Platforms", BreakStreak = false, BreakStreakTarget = 1, LowerKD = false, KDTargetKills = 4, EventFarm = false },
    Bannable = {
        KillAll = false, Invisible = false, Desync = false,
        AimFollow = false, AimFollowFirearmOnly = true, AimFollowKnifeOnly = false, AimFollowRaycast = true,
        BodyPartsEnabled = true,
        BodyParts = {
            Head=true,LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,
            RightUpperArm=true,RightLowerArm=true,RightHand=true,
            UpperTorso=true,LowerTorso=true,LeftUpperLeg=true,LeftLowerLeg=true,
            LeftFoot=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true,
        },
        Triggerbot=false, SilentAim=false, AutoShoot=false, Macro=false,
        FOVEnabled=false, FOVVisible=true, FOVRadius=200, HitChance=100,
    },
    Boxes = { Selected = "Knife Box #1", Price = 500, AutoBuy = false },
    FloatingFloor = { Enabled = false, HideMap = false, Height = 0 },
    Emotes = { AutoExecute = false },
    Keybinds = { ToggleUI = "RightControl" },
}

local function ToColor3(value, default)
    if typeof(value) == "Color3" then return value end
    if type(value) == "table" then
        local r = value.R or value.r or value[1]
        local g = value.G or value.g or value[2]
        local b = value.B or value.b or value[3]
        if type(r) == "number" and type(g) == "number" and type(b) == "number" then
            if r > 1 or g > 1 or b > 1 then
                return Color3.fromRGB(math.clamp(r,0,255), math.clamp(g,0,255), math.clamp(b,0,255))
            end
            return Color3.new(r, g, b)
        end
    end
    return default
end

local IS_LOADING_CONFIG = false
local function SetToggleValue(t, v)
    if v == nil or not t then return end
    IS_LOADING_CONFIG = true
    pcall(function() t:Set(v) end)
    IS_LOADING_CONFIG = false
end

local function GetHRP(player)
    local char = player and player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return (hrp and hrp:IsA("BasePart")) and hrp or nil
end

local function GetHumanoid(player)
    local char = player and player.Character
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function HasGameAttribute(player)
    if not player then return false end
    local v = player:GetAttribute("Game")
    return typeof(v) == "string" and v ~= ""
end

local function HasMapAttribute(player)
    if not HasGameAttribute(player) then return false end
    local v = player:GetAttribute("Map")
    return typeof(v) == "string" and v ~= ""
end

local function WaitForChildSafe(parent, name, timeout)
    if not parent then return nil end
    timeout = timeout or 2
    local ok, child = pcall(function() return parent:WaitForChild(name, timeout) end)
    if ok then return child end
    return nil
end

local EnemyChecker = {}
EnemyChecker.__index = EnemyChecker
function EnemyChecker:IsEnemy(player)
    if player == LocalPlayer then return false end
    if not HasMapAttribute(LocalPlayer) or not HasMapAttribute(player) then return false end
    if LocalPlayer:GetAttribute("Game") ~= player:GetAttribute("Game") then return false end
    if LocalPlayer:GetAttribute("Map")  ~= player:GetAttribute("Map")  then return false end
    local myTeam, hisTeam = LocalPlayer:GetAttribute("Team"), player:GetAttribute("Team")
    if typeof(myTeam) ~= "string" or myTeam == "" then return false end
    if typeof(hisTeam) ~= "string" or hisTeam == "" then return false end
    return myTeam ~= hisTeam
end
local EnemyCheckerInstance = setmetatable({}, EnemyChecker)

local function IsValidEnemy(player)
    if not EnemyCheckerInstance:IsEnemy(player) then return false end
    if IsAlly:check(player) then return false end
    return true
end

local function IsAlive(player)
    local char = player and player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local BODY_PART_NAMES = {
    "Head","LeftLowerArm","LeftHand","LeftLowerLeg","LeftFoot",
    "LeftUpperArm","LeftUpperLeg","LowerTorso","RightLowerArm","RightHand",
    "RightLowerLeg","RightFoot","RightUpperArm","RightUpperLeg","UpperTorso",
}
local BODY_PART_LOOKUP = {}
for _, n in ipairs(BODY_PART_NAMES) do BODY_PART_LOOKUP[n] = true end

local BODY_WEIGHTS = {
    UpperTorso=34,LowerTorso=22,HumanoidRootPart=22,Head=14,
    LeftUpperArm=5,RightUpperArm=5,LeftUpperLeg=5,RightUpperLeg=5,
    LeftLowerArm=3,RightLowerArm=3,LeftLowerLeg=3,RightLowerLeg=3,
    LeftHand=2,RightHand=2,LeftFoot=2,RightFoot=2,
}

local function SanitizeBodyPartsConfig()
    if type(Config.Bannable.BodyParts) ~= "table" then Config.Bannable.BodyParts = {} end
    for name, value in pairs(Config.Bannable.BodyParts) do
        if not BODY_PART_LOOKUP[name] then Config.Bannable.BodyParts[name] = nil
        elseif type(value) ~= "boolean" then Config.Bannable.BodyParts[name] = value == true end
    end
    for _, name in ipairs(BODY_PART_NAMES) do
        if Config.Bannable.BodyParts[name] == nil then Config.Bannable.BodyParts[name] = true end
    end
end

local function GetEnabledBodyPartNames()
    SanitizeBodyPartsConfig()
    if not Config.Bannable.BodyPartsEnabled then
        return { "Head", "UpperTorso", "HumanoidRootPart" }
    end
    local out = {}
    for _, name in ipairs(BODY_PART_NAMES) do
        if Config.Bannable.BodyParts[name] == true then out[#out+1] = name end
    end
    if #out == 0 then return { "UpperTorso", "HumanoidRootPart" } end
    return out
end

local function GetAimParts(player, names)
    local char = player and player.Character
    if not char then return nil end
    names = names or GetEnabledBodyPartNames()
    local out = {}
    for _, name in ipairs(names) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then out[#out+1] = part end
    end
    return #out > 0 and out or nil
end

local function SelectAimPart(player, names)
    local parts = GetAimParts(player, names)
    if not parts then return nil end
    local total = 0
    local weights = {}
    for _, part in ipairs(parts) do
        local w = BODY_WEIGHTS[part.Name] or 1
        weights[#weights+1] = w
        total = total + w
    end
    if total <= 0 then return parts[1] end
    local roll = math.random() * total
    local acc = 0
    for i, part in ipairs(parts) do
        acc = acc + weights[i]
        if roll <= acc then return part end
    end
    return parts[1]
end

local function GetBodyPartsForAim() return GetEnabledBodyPartNames() end

local function HitChancePasses()
    local c = math.clamp(tonumber(Config.Bannable.HitChance) or 100, 0, 100)
    if c >= 100 then return true end
    if c <= 0 then return false end
    return (math.random() * 100) <= c
end

local function IsFirearm(tool)
    if not (tool and tool:IsA("Tool")) then return false end
    local fire = tool:FindFirstChild("fire")
    if fire and fire:IsA("RemoteEvent") then return true end
    local beam = tool:FindFirstChild("showBeam")
    if beam and beam:IsA("RemoteEvent") then return true end
    return false
end

local function IsKnife(tool)
    if not (tool and tool:IsA("Tool")) then return false end
    local kill = tool:FindFirstChild("kill")
    local name = tostring(tool.Name or ""):lower()
    return (kill and kill:IsA("RemoteEvent")) or name:find("knife", 1, true) ~= nil
end

local function FindToolByPredicate(char, predicate)
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if predicate(child) then return child end
    end
    return nil
end

local function FindEquippedKnife()
    return FindToolByPredicate(LocalPlayer.Character, IsKnife)
end

local function GetFirearmTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    local equipped = FindToolByPredicate(char, IsFirearm)
    if equipped then return equipped end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        local candidate = FindToolByPredicate(backpack, IsFirearm)
        if candidate then
            local hum = GetHumanoid(LocalPlayer)
            if hum then
                pcall(function() hum:EquipTool(candidate) end)
                task.wait(0.05)
                if candidate.Parent == char then return candidate end
            end
        end
    end
    return nil
end

local SharedRaycast = { _params = nil, _lastFilter = false }
local function GetSharedRaycastParams(ignoreChar)
    if not SharedRaycast._params or SharedRaycast._lastFilter ~= ignoreChar then
        local p = SharedRaycast._params
        if not p then
            p = RaycastParams.new()
            p.FilterType = Enum.RaycastFilterType.Exclude
            p.IgnoreWater = true
            SharedRaycast._params = p
        end
        p.FilterDescendantsInstances = ignoreChar and { ignoreChar } or {}
        SharedRaycast._lastFilter = ignoreChar
    end
    return SharedRaycast._params
end

local function HasLineOfSight(target, targetPart)
    local myChar = LocalPlayer.Character
    local myHRP  = GetHRP(LocalPlayer)
    if not (myChar and myHRP and target and target.Character and targetPart and targetPart:IsA("BasePart")) then
        return false
    end
    local dir = targetPart.Position - myHRP.Position
    if dir.Magnitude <= 0 then return false end
    local params = GetSharedRaycastParams(myChar)
    local hit = workspace:Raycast(myHRP.Position, dir, params)
    return (not hit) or (hit.Instance and hit.Instance:IsDescendantOf(target.Character))
end

local function HasClearLOS(targetPart, origin, params)
    local size = targetPart.Size
    local offsets = {
        Vector3.zero,
        Vector3.new(size.X / 2.1, 0, 0),
        Vector3.new(-size.X / 2.1, 0, 0),
        Vector3.new(0, size.Y / 2.1, 0),
        Vector3.new(0, -size.Y / 2.1, 0),
    }
    for _, off in ipairs(offsets) do
        local targetPos = targetPart.CFrame * off
        if not workspace:Raycast(origin, targetPos - origin, params) then
            return true
        end
    end
    return false
end

local function GetGuiParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:FindFirstChild("PlayerGui")
end

local function IsMatchTimerVisible()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local main = (pg and pg:FindFirstChild("Main")) or pg
    local frame = main and main:FindFirstChild("MainGameFrame")
    local score = frame and frame:FindFirstChild("IngameScore")
    local timer = score and score:FindFirstChild("Timer")
    if not timer then return false end
    return tostring(timer.Text or ""):match("^%s*%d+:%d%d%s*$") ~= nil
end

--=================================================================
-- VENTANA
--=================================================================
local WindWindow = WindUI:CreateWindow({
    Title = "DEOBFBYSZK",
    Icon = "swords",
    Author = "MADE BY SZK",
    Folder = "DEOBFBYSZK/Configs",
    Theme = "Dark",
    NewElements = true,
    OpenButton = {
        Title = "DEOBFBYSZK",
        Icon = "monitor",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
        OnlyMobile = false,
        Enabled = true,
        Draggable = true,
    },
})

pcall(function()
    WindWindow:Tag({
        Title = "v1.0.0",
        Icon = "github",
        Color = Color3.fromHex("#4FC3F7"),
        Radius = 13,
    })
end)

pcall(function()
    WindWindow:EditOpenButton({
        Title = "DEOBFBYSZK",
        Icon = "",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
        OnlyMobile = true,
        Enabled = true,
        Draggable = true,
    })
end)

local CONFIG_MANAGER = nil
pcall(function()
    if WindWindow.ConfigManager then
        CONFIG_MANAGER = WindWindow.ConfigManager:CreateConfig("deobfbyszk_main")
    end
end)

local SKIP_SAVE = true
local function SaveConfig()
    if not IS_LOADING_CONFIG and not SKIP_SAVE and CONFIG_MANAGER then
        pcall(function() CONFIG_MANAGER:Save() end)
    end
end

local AUTO_SAVE_ACC = 0
local CONFIG_AUTOSAVE_CONN = RunService.Heartbeat:Connect(function(dt)
    AUTO_SAVE_ACC = AUTO_SAVE_ACC + dt
    if AUTO_SAVE_ACC < 5 then return end
    AUTO_SAVE_ACC = 0
    SaveConfig()
end)

local function Notify(title, content, icon, duration)
    if Config.Notifications.Enabled then
        pcall(function()
            WindUI:Notify({
                Title = title,
                Content = content,
                Duration = duration or 3,
                Icon = icon or "info",
            })
        end)
    end
end

--=================================================================
-- HANDLERS
--=================================================================

local JumpPowerHandler = {}
JumpPowerHandler.__index = JumpPowerHandler
function JumpPowerHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _humanoid=nil, _original=nil }, JumpPowerHandler)
end
function JumpPowerHandler:InGame() return HasGameAttribute(LocalPlayer) end
function JumpPowerHandler:CacheOriginal(humanoid)
    if not humanoid or humanoid == self._humanoid then return end
    self._humanoid = humanoid
    self._original = { UseJumpPower=humanoid.UseJumpPower, JumpPower=humanoid.JumpPower, JumpHeight=humanoid.JumpHeight }
end
function JumpPowerHandler:GetHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then self:CacheOriginal(hum) end
    return hum
end
function JumpPowerHandler:RestoreOriginal(humanoid)
    humanoid = humanoid or self:GetHumanoid()
    if not humanoid or not self._original then return end
    pcall(function()
        humanoid.UseJumpPower = self._original.UseJumpPower
        if self._original.UseJumpPower then humanoid.JumpPower = self._original.JumpPower
        else humanoid.JumpHeight = self._original.JumpHeight end
    end)
end
function JumpPowerHandler:ApplyJumpPower(humanoid)
    humanoid = humanoid or self:GetHumanoid()
    if not humanoid then return end
    self:CacheOriginal(humanoid)
    if Config.PlayerCheats.JumpPowerEnabled and self:InGame() then
        local p = math.max(0, tonumber(Config.PlayerCheats.JumpPower) or 25)
        pcall(function()
            humanoid.UseJumpPower = true
            humanoid.JumpPower = p * 2
        end)
    else
        self:RestoreOriginal(humanoid)
    end
end
function JumpPowerHandler:Start()
    if self._running then return end
    self._running = true
    self._conns:add(LocalPlayer:GetAttributeChangedSignal("Game"):Connect(function()
        if self._running then self:ApplyJumpPower() end
    end))
    self._conns:add(LocalPlayer.CharacterAdded:Connect(function(char)
        task.defer(function()
            local hum = WaitForChildSafe(char, "Humanoid", 5)
            if hum then self._humanoid = nil; self:ApplyJumpPower(hum) end
        end)
    end))
    self._conns:add(UserInputService.JumpRequest:Connect(function()
        if not Config.PlayerCheats.InfiniteJump then return end
        if not self:InGame() then return end
        local hum = self:GetHumanoid()
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end))
end
function JumpPowerHandler:Stop()
    if not self._running then self:RestoreOriginal(); return end
    self._running = false
    self._conns:clear()
    self:RestoreOriginal()
end
function JumpPowerHandler:Refresh()
    if Config.PlayerCheats.JumpPowerEnabled or Config.PlayerCheats.InfiniteJump then
        self:Start(); self:ApplyJumpPower()
    else
        self:Stop()
    end
end

local SpeedHandler = {}
SpeedHandler.__index = SpeedHandler
function SpeedHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _humanoid=nil, _originalSpeed=nil, _watchConn=nil, _watchedHumanoid=nil }, SpeedHandler)
end
function SpeedHandler:InGame() return HasGameAttribute(LocalPlayer) end
function SpeedHandler:GetConfiguredSpeed() return math.max(0, tonumber(Config.PlayerCheats.Speed) or 24) end
function SpeedHandler:CacheOriginal(h)
    if not h or h == self._humanoid then return end
    self._humanoid = h; self._originalSpeed = h.WalkSpeed
end
function SpeedHandler:GetHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then self:CacheOriginal(hum) end
    return hum
end
function SpeedHandler:WatchWalkSpeed(h)
    if not h or h == self._watchedHumanoid then return end
    self:StopWatch()
    self._watchedHumanoid = h
    self._watchConn = h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if not self._running or not Config.PlayerCheats.SpeedEnabled or not self:InGame() then return end
        local target = self:GetConfiguredSpeed()
        if math.abs((tonumber(h.WalkSpeed) or 0) - target) > 0.01 then
            pcall(function() h.WalkSpeed = target end)
        end
    end)
end
function SpeedHandler:StopWatch()
    if self._watchConn then pcall(function() self._watchConn:Disconnect() end); self._watchConn = nil end
    self._watchedHumanoid = nil
end
function SpeedHandler:ApplySpeed(h)
    h = h or self:GetHumanoid()
    if not h then return end
    self:CacheOriginal(h)
    self:WatchWalkSpeed(h)
    if Config.PlayerCheats.SpeedEnabled then
        local s = self:GetConfiguredSpeed()
        pcall(function() h.WalkSpeed = s end)
    else
        self:RestoreOriginal(h)
    end
end
function SpeedHandler:RestoreOriginal(h)
    h = h or self:GetHumanoid()
    if not h or self._originalSpeed == nil then return end
    pcall(function() h.WalkSpeed = self._originalSpeed end)
end
function SpeedHandler:Start()
    if self._running then return end
    self._running = true
    self._conns:add(LocalPlayer:GetAttributeChangedSignal("Game"):Connect(function()
        if self._running then self:ApplySpeed() end
    end))
    self._conns:add(LocalPlayer.CharacterAdded:Connect(function(char)
        task.defer(function()
            local hum = WaitForChildSafe(char, "Humanoid", 5)
            if hum then self._humanoid = nil; self:ApplySpeed(hum) end
        end)
    end))
end
function SpeedHandler:Stop()
    if not self._running then self:StopWatch(); self:RestoreOriginal(); return end
    self._running = false
    self._conns:clear()
    self:StopWatch()
    self:RestoreOriginal()
end
function SpeedHandler:Refresh()
    if Config.PlayerCheats.SpeedEnabled then self:Start(); self:ApplySpeed() else self:Stop() end
end

local FloatingFloorHandler = {}
FloatingFloorHandler.__index = FloatingFloorHandler
local FLOOR_SIZE, FLOOR_OFFSET = Vector3.new(16,1,16), 4
local FLOOR_MIN_Y, FLOOR_MAX_Y = -200, 2000

function FloatingFloorHandler.new()
    return setmetatable({ _running=false, _hideMapActive=false, _conns=ConnectionBucket.new(), _floorPart=nil, _baseY=nil, _offsetY=nil, _hiddenMoved={}, _hiddenRoot=nil }, FloatingFloorHandler)
end
function FloatingFloorHandler:GetHRP() return GetHRP(LocalPlayer) end
function FloatingFloorHandler:InGame() return HasGameAttribute(LocalPlayer) end
function FloatingFloorHandler:ComputeY()
    local base = self._baseY or 0
    return math.clamp(base + (self._offsetY or 0), FLOOR_MIN_Y, FLOOR_MAX_Y)
end
function FloatingFloorHandler:EnsureFloorPart()
    if self._floorPart and self._floorPart.Parent then return self._floorPart end
    local part = Instance.new("Part")
    part.Name = "DEOBFBYSZK_FloatingFloor"
    part.Size = FLOOR_SIZE
    part.Anchored = true
    part.CanCollide = true
    part.Transparency = 1
    part.Material = Enum.Material.SmoothPlastic
    part.Parent = workspace
    self._floorPart = part
    return part
end
function FloatingFloorHandler:DestroyFloorPart()
    if self._floorPart then pcall(function() self._floorPart:Destroy() end); self._floorPart = nil end
end
function FloatingFloorHandler:UpdateFloor()
    if not self._running then return end
    local hrp = self:GetHRP()
    if not hrp then return end
    if not self._baseY then self._baseY = hrp.Position.Y - FLOOR_OFFSET end
    local part = self:EnsureFloorPart()
    part.CFrame = CFrame.new(hrp.Position.X, self:ComputeY(), hrp.Position.Z)
end
function FloatingFloorHandler:ApplyHideMap()
    if not self:InGame() then self._hideMapActive = false; return end
    local activeMaps = workspace:FindFirstChild("ActiveMaps")
    if not activeMaps then return end
    local matchId = LocalPlayer:GetAttribute("MatchId")
    local map = nil
    if typeof(matchId) == "string" and matchId ~= "" then
        map = activeMaps:FindFirstChild(matchId)
    end
    if not map then return end
    self:RestoreHideMap()
    local folder = self._hiddenRoot
    if not folder or not folder.Parent then
        folder = Instance.new("Folder")
        folder.Name = "DEOBFBYSZK_HiddenMap"
        folder.Parent = Lighting
        self._hiddenRoot = folder
    end
    for _, name in ipairs({"Collisions","Map","Spawns","GeometryBundles"}) do
        local child = map:FindFirstChild(name)
        if child then
            self._hiddenMoved[child] = child.Parent
            child.Parent = folder
        end
    end
    self._hiddenMapId = matchId
    self._hideMapActive = true
end
function FloatingFloorHandler:RestoreHideMap()
    for obj, parent in pairs(self._hiddenMoved) do
        if obj and obj.Parent then
            local ok = false
            pcall(function() ok = parent and parent:IsDescendantOf(game) end)
            if ok then pcall(function() obj.Parent = parent end)
            else pcall(function() obj:Destroy() end) end
        end
    end
    table.clear(self._hiddenMoved)
    self._hideMapActive = false
end
function FloatingFloorHandler:Start()
    if self._running then self:UpdateFloor(); return end
    self._running = true
    self._offsetY = 0
    Config.FloatingFloor.Height = 0
    local hrp = self:GetHRP()
    if hrp then self._baseY = hrp.Position.Y - FLOOR_OFFSET end
    self:EnsureFloorPart()
    self:UpdateFloor()
    self._conns:add(RunService.Heartbeat:Connect(function()
        self:UpdateFloor()
        if Config.FloatingFloor.HideMap and not self._hideMapActive then
            self:ApplyHideMap()
        end
    end))
    self._conns:add(LocalPlayer.CharacterAdded:Connect(function()
        task.defer(function()
            if not self._running then return end
            local h = self:GetHRP()
            if h then self._baseY = h.Position.Y - FLOOR_OFFSET end
        end)
    end))
end
function FloatingFloorHandler:Stop()
    if not self._running then self:DestroyFloorPart(); return end
    self._running = false
    self._conns:clear()
    self._baseY = nil
    Config.FloatingFloor.Height = 0
    self:DestroyFloorPart()
end
function FloatingFloorHandler:Destroy()
    Config.FloatingFloor.HideMap = false
    self:RestoreHideMap()
    if self._hiddenRoot then pcall(function() self._hiddenRoot:Destroy() end); self._hiddenRoot = nil end
    self._running = false
    self._conns:clear()
    self._baseY = nil
    self:DestroyFloorPart()
end
function FloatingFloorHandler:Refresh()
    if Config.FloatingFloor.Enabled or Config.FloatingFloor.HideMap then
        self:Start()
        if Config.FloatingFloor.HideMap then self:ApplyHideMap() else self:RestoreHideMap() end
        self:UpdateFloor()
    else
        self:Stop()
        self:RestoreHideMap()
    end
end

local HitboxHandler = {}
HitboxHandler.__index = HitboxHandler
function HitboxHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _parts={}, _tick=0 }, HitboxHandler)
end
function HitboxHandler:EnsurePart(player, hrp)
    local char = hrp.Parent
    local existing = self._parts[player]
    if existing and existing.Parent == char then return existing end
    if existing then pcall(function() existing:Destroy() end) end
    local part = Instance.new("Part")
    part.Name = "DEOBFBYSZK_Hitbox"
    part.Shape = Enum.PartType.Block
    part.CFrame = hrp.CFrame
    part.Anchored = false
    part.CanCollide = false
    part.CanQuery = true
    part.CanTouch = false
    part.Massless = true
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part; weld.Part1 = hrp; weld.Parent = part
    part.Parent = char
    self._parts[player] = part
    return part
end
function HitboxHandler:DestroyPart(player)
    local part = self._parts[player]
    if part then pcall(function() part:Destroy() end) end
    self._parts[player] = nil
end
function HitboxHandler:DestroyAll()
    for _, part in pairs(self._parts) do
        if part then pcall(function() part:Destroy() end) end
    end
    table.clear(self._parts)
end
function HitboxHandler:ProcessPlayer(player)
    if player == LocalPlayer then return end
    local hrp = GetHRP(player)
    if not hrp or not IsValidEnemy(player) or not IsAlive(player) then
        self:DestroyPart(player); return
    end
    local part = self:EnsurePart(player, hrp)
    if not part then return end
    local size = tonumber(Config.Hitbox.Size) or 4
    part.Size = Vector3.new(size, size, size)
    local opacity = Config.Hitbox.Show and math.clamp((tonumber(Config.Hitbox.Opacity) or 5.5) / 10, 0, 1) or 0
    part.Transparency = 1 - opacity
    part.Color = ToColor3(Config.Hitbox.Color, Color3.fromRGB(255, 0, 0))
    part.CanCollide = false
end
function HitboxHandler:Tick(dt)
    self._tick = self._tick + dt
    if self._tick < 0.1 then return end
    self._tick = 0
    for player, part in pairs(self._parts) do
        if not part or not part.Parent then self._parts[player] = nil end
    end
    for _, player in ipairs(Players:GetPlayers()) do self:ProcessPlayer(player) end
end
function HitboxHandler:Start()
    if self._running then return end
    self._running = true
    self._conns:add(RunService.Heartbeat:Connect(function(dt) self:Tick(dt) end))
end
function HitboxHandler:Stop()
    if not self._running then return end
    self._running = false
    self._conns:clear()
    self:DestroyAll()
end
function HitboxHandler:Refresh()
    if not self._running then return end
    for _, player in ipairs(Players:GetPlayers()) do self:ProcessPlayer(player) end
end

local SilentAim = {
    _hookInstalled=false, _hookFailed=false, _target=nil, _holding=false,
    _maxDistance=5000, _minRayLength=20, _origNamecall=nil,
}
function SilentAim:Set(target) self._target = target end
function SilentAim:IsActive() return self._target ~= nil and self._target.Parent ~= nil end
function SilentAim:SetHolding(v) self._holding = v == true end
function SilentAim:IsHolding() return self._holding == true or self:IsActive() end
function SilentAim:InstallHook(contextName)
    if self._hookInstalled then return true end
    if type(getrawmetatable) ~= "function" or type(setreadonly) ~= "function"
        or type(getnamecallmethod) ~= "function" or type(checkcaller) ~= "function" then
        if not self._hookFailed then
            self._hookFailed = true
            Notify(contextName or "Aim", "Executor no compatible.", "alert-triangle", 4)
        end
        return false
    end
    local selfRef = self
    local wrap = (type(newcclosure) == "function") and newcclosure or function(fn) return fn end
    local ok = pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        local newNamecall = wrap(function(obj, ...)
            local target = selfRef._target
            if target and target.Parent and obj == workspace and not checkcaller() then
                local method = getnamecallmethod()
                if method == "Raycast" then
                    local origin, dir, params = ...
                    if typeof(dir) == "Vector3" and dir.Magnitude > selfRef._minRayLength then
                        local newDir = (target.Position - origin).Unit * selfRef._maxDistance
                        return oldNamecall(obj, origin, newDir, params)
                    end
                elseif string.find(method, "FindPartOnRay") then
                    local ray, ignore, terr, mat = ...
                    if typeof(ray) == "Ray" and ray.Direction.Magnitude > selfRef._minRayLength then
                        local newRay = Ray.new(ray.Origin, (target.Position - ray.Origin).Unit * selfRef._maxDistance)
                        return oldNamecall(obj, newRay, ignore, terr, mat)
                    end
                end
            end
            return oldNamecall(obj, ...)
        end)
        setreadonly(mt, false)
        mt.__namecall = newNamecall
        setreadonly(mt, true)
        selfRef._origNamecall = oldNamecall
        selfRef._hookWrapper = newNamecall
    end)
    if ok then self._hookInstalled = true end
    return self._hookInstalled
end
function SilentAim:RemoveHook()
    if not self._hookInstalled then return end
    pcall(function()
        local mt = getrawmetatable(game)
        if self._hookWrapper and self._origNamecall and rawequal(mt.__namecall, self._hookWrapper) then
            setreadonly(mt, false)
            mt.__namecall = self._origNamecall
            setreadonly(mt, true)
        end
    end)
    self._hookInstalled = false
    self._origNamecall = nil
    self._hookWrapper = nil
end
function SilentAim:FindClosestToCursor(useRaycast)
    local myChar = LocalPlayer.Character
    local myHRP = GetHRP(LocalPlayer)
    if not (myChar and myHRP) then return nil, nil end
    local parts = GetBodyPartsForAim()
    local cursor = GetCursorPosition()
    local bestPlayer, bestPart, bestDist = nil, nil, math.huge
    if not self._rayParams then
        self._rayParams = RaycastParams.new()
        self._rayParams.FilterType = Enum.RaycastFilterType.Exclude
        self._rayParams.IgnoreWater = true
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsValidEnemy(player) and IsAlive(player) then
            local pp = GetAimParts(player, parts)
            if pp then
                self._rayParams.FilterDescendantsInstances = { myChar, player.Character }
                for _, part in ipairs(pp) do
                    if not useRaycast or HasLineOfSight(player, part) then
                        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local d = (Vector2.new(screenPos.X, screenPos.Y) - cursor).Magnitude
                            if d < bestDist then bestPlayer, bestPart, bestDist = player, part, d end
                        end
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart
end
function SilentAim:Start()
    if not self:InstallHook("Silent Aim") then return end
    if self._running then return end
    self._running = true
    self._fovRadius = tonumber(Config.Bannable.FOVRadius) or 200
    self._loopConn = RunService.RenderStepped:Connect(function()
        if not self._running then return end
        local _, part = self:FindClosestToCursor(Config.Bannable.AimFollowRaycast)
        self:Set(part or nil)
    end)
    self._inputConn1 = UserInputService.InputBegan:Connect(function(input, processed)
        if not self._running or processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self:SetHolding(true)
        end
    end)
    self._inputConn2 = UserInputService.InputEnded:Connect(function(input, processed)
        if not self._running or processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self:SetHolding(false)
        end
    end)
end
function SilentAim:Stop()
    if not self._running then self:RemoveHook(); return end
    self._running = false
    self._target = nil
    self._holding = false
    if self._loopConn then pcall(function() self._loopConn:Disconnect() end) end
    if self._inputConn1 then pcall(function() self._inputConn1:Disconnect() end) end
    if self._inputConn2 then pcall(function() self._inputConn2:Disconnect() end) end
    self._loopConn, self._inputConn1, self._inputConn2 = nil, nil, nil
    self:RemoveHook()
end

local TriggerbotHandler = {}
TriggerbotHandler.__index = TriggerbotHandler
TriggerbotHandler.FIRE_COOLDOWN = 0.2
TriggerbotHandler.RELEASE_DELAY = 0.05
function TriggerbotHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _target=nil, _lastFire=0, _firing=false, _fingerDown=nil, _fingerTime=0, _rayParams=nil }, TriggerbotHandler)
end
function TriggerbotHandler:GetPartsUnderCursor()
    local hrp = GetHRP(LocalPlayer)
    if not (LocalPlayer.Character and hrp) then return nil end
    local origin = hrp.Position
    local bodyParts = GetBodyPartsForAim()
    local result = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidEnemy(player) and IsAlive(player) then
            local parts = GetAimParts(player, bodyParts)
            if parts then
                if not self._rayParams then
                    self._rayParams = RaycastParams.new()
                    self._rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    self._rayParams.IgnoreWater = true
                end
                self._rayParams.FilterDescendantsInstances = { LocalPlayer.Character, player.Character }
                for _, part in ipairs(parts) do
                    local dist = (part.Position - origin).Magnitude
                    if HasLineOfSight(player, part) then
                        result = result or {}
                        result[#result+1] = { player = player, parts = parts, distance = dist }
                    end
                end
            end
        end
    end
    return result
end
function TriggerbotHandler:PickTarget()
    local list = self._target
    if not list then return nil end
    for _, entry in ipairs(list) do
        local aimPart = SelectAimPart(entry.player, GetBodyPartsForAim())
        if aimPart and HitChancePasses() then return aimPart end
    end
    return nil
end
function TriggerbotHandler:Fire()
    if not self._running or self._firing then return end
    local char = LocalPlayer.Character
    local hum = GetHumanoid(LocalPlayer)
    if not (char and hum and hum.Health > 0) then return end
    local tool = FindEquippedKnife() or GetFirearmTool()
    if not tool then return end
    local target = self:PickTarget()
    if not (target and target.Parent) then return end
    SilentAim:Set(HitChancePasses() and target or nil)
    SilentAim:SetHolding(true)
    self._firing = true
    task.spawn(function()
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        local wasEquipped = tool.Parent == char
        pcall(function()
            if not wasEquipped then hum:EquipTool(tool); task.wait(TriggerbotHandler.RELEASE_DELAY) end
            tool:Activate()
        end)
        task.wait(TriggerbotHandler.FIRE_COOLDOWN)
        if not wasEquipped and tool.Parent == LocalPlayer.Character and backpack then
            pcall(function() tool.Parent = backpack end)
        end
        SilentAim:Set(nil)
        SilentAim:SetHolding(false)
        self._firing = false
    end)
end
function TriggerbotHandler:Tick()
    self._target = self:GetPartsUnderCursor()
    if not self._target then return end
    local now = os.clock()
    if now - self._lastFire < TriggerbotHandler.FIRE_COOLDOWN then return end
    self._lastFire = now
    self:Fire()
end
function TriggerbotHandler:Start()
    if self._running then return end
    self._running = true
    self._lastFire = 0; self._firing = false; self._fingerDown = nil; self._target = nil
    self._conns:add(RunService.RenderStepped:Connect(function() if self._running then self:Tick() end end))
    self._conns:add(UserInputService.InputBegan:Connect(function(input, processed)
        if not self._running or processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then self:Fire()
        elseif input.UserInputType == Enum.UserInputType.Touch then
            self._fingerDown = input.Position
            self._fingerTime = os.clock()
        end
    end))
    self._conns:add(UserInputService.InputEnded:Connect(function(input, processed)
        if not self._running or processed or input.UserInputType ~= Enum.UserInputType.Touch then return end
        if not self._fingerDown then return end
        local delta = (input.Position - self._fingerDown).Magnitude
        local elapsed = os.clock() - (self._fingerTime or 0)
        self._fingerDown = nil
        if delta < 20 and elapsed < 0.25 then self:Fire() end
    end))
end
function TriggerbotHandler:Stop()
    if not self._running then return end
    self._running = false
    self._target = nil
    self._fingerDown = nil
    SilentAim:Set(nil)
    SilentAim:SetHolding(false)
    self._conns:clear()
end

local MacroHandler = {}
MacroHandler.__index = MacroHandler
MacroHandler.EQUIP_DELAY = 0.05
MacroHandler.FIRE_DELAY = 0.12
MacroHandler.TOUCH_MAX_DIST = 20
MacroHandler.TOUCH_MAX_TIME = 0.25
function MacroHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _candidates=nil, _busy=false, _fingerPos=nil, _fingerTime=0, _rayParams=nil }, MacroHandler)
end
function MacroHandler:GetCandidates()
    local hrp = GetHRP(LocalPlayer)
    if not (LocalPlayer.Character and hrp) then return nil end
    local origin = hrp.Position
    local bodyParts = GetBodyPartsForAim()
    local out = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidEnemy(player) and IsAlive(player) then
            local parts = GetAimParts(player, bodyParts)
            if parts then
                local best = math.huge
                for _, part in ipairs(parts) do
                    local d = (part.Position - origin).Magnitude
                    if d < best then best = d end
                end
                out = out or {}
                out[#out+1] = { player = player, parts = parts, distance = best }
            end
        end
    end
    if out then table.sort(out, function(a,b) return a.distance < b.distance end) end
    return out
end
function MacroHandler:PickTarget()
    local list = self._candidates
    if not list then return nil end
    local myChar = LocalPlayer.Character
    local myHRP = GetHRP(LocalPlayer)
    if not (myChar and myHRP) then return nil end
    if not self._rayParams then
        self._rayParams = RaycastParams.new()
        self._rayParams.FilterType = Enum.RaycastFilterType.Exclude
        self._rayParams.IgnoreWater = true
    end
    for _, entry in ipairs(list) do
        local char = entry.player.Character
        if char and IsAlive(entry.player) and IsValidEnemy(entry.player) then
            self._rayParams.FilterDescendantsInstances = { myChar, char }
            for _, part in ipairs(entry.parts) do
                if HasClearLOS(part, myHRP.Position, self._rayParams) then return part end
            end
        end
    end
    return nil
end
function MacroHandler:Fire()
    if not self._running or self._busy then return end
    local char = LocalPlayer.Character
    local hum = GetHumanoid(LocalPlayer)
    if not (char and hum and hum.Health > 0) then return end
    local knife = FindEquippedKnife()
    if not knife then return end
    local target = self:PickTarget()
    if not (target and target.Parent) then return end
    SilentAim:Set(HitChancePasses() and target or nil)
    SilentAim:SetHolding(true)
    self._busy = true
    task.spawn(function()
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        local wasEquipped = knife.Parent == char
        pcall(function()
            if not wasEquipped then hum:EquipTool(knife); task.wait(MacroHandler.EQUIP_DELAY) end
            knife:Activate()
        end)
        task.wait(MacroHandler.FIRE_DELAY)
        if not wasEquipped and knife.Parent == LocalPlayer.Character and backpack then
            pcall(function() knife.Parent = backpack end)
        end
        SilentAim:Set(nil)
        SilentAim:SetHolding(false)
        self._busy = false
    end)
end
function MacroHandler:Start()
    if self._running then return end
    self._running = true
    self._busy = false
    self._candidates = nil
    self._conns:add(RunService.Heartbeat:Connect(function()
        if self._running then self._candidates = self:GetCandidates() end
    end))
    self._conns:add(UserInputService.InputBegan:Connect(function(input, processed)
        if not self._running or processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then self:Fire()
        elseif input.UserInputType == Enum.UserInputType.Touch then
            self._fingerPos = input.Position
            self._fingerTime = os.clock()
        end
    end))
    self._conns:add(UserInputService.InputEnded:Connect(function(input, processed)
        if not self._running or processed or input.UserInputType ~= Enum.UserInputType.Touch then return end
        if not self._fingerPos then return end
        local delta = (input.Position - self._fingerPos).Magnitude
        local elapsed = os.clock() - (self._fingerTime or 0)
        self._fingerPos = nil
        if delta < MacroHandler.TOUCH_MAX_DIST and elapsed < MacroHandler.TOUCH_MAX_TIME then self:Fire() end
    end))
end
function MacroHandler:Stop()
    if not self._running then return end
    self._running = false
    self._candidates = nil
    self._fingerPos = nil
    SilentAim:Set(nil)
    SilentAim:SetHolding(false)
    self._conns:clear()
end

local AutoShootHandler = {}
AutoShootHandler.__index = AutoShootHandler
AutoShootHandler.COOLDOWN = 0.2
AutoShootHandler.HOLD_EXTRA = 0.05
function AutoShootHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _target=nil, _lastFire=0, _rayParams=nil }, AutoShootHandler)
end
function AutoShootHandler:FindTarget()
    local myChar = LocalPlayer.Character
    local myHRP = GetHRP(LocalPlayer)
    if not (myChar and myHRP) then return nil end
    local bodyParts = GetBodyPartsForAim()
    local best, bestDist = nil, math.huge
    if not self._rayParams then
        self._rayParams = RaycastParams.new()
        self._rayParams.FilterType = Enum.RaycastFilterType.Exclude
        self._rayParams.IgnoreWater = true
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidEnemy(player) and IsAlive(player) then
            local parts = GetAimParts(player, bodyParts)
            if parts then
                self._rayParams.FilterDescendantsInstances = { myChar, player.Character }
                for _, part in ipairs(parts) do
                    local d = (part.Position - myHRP.Position).Magnitude
                    if d < bestDist and HasClearLOS(part, myHRP.Position, self._rayParams) then
                        best, bestDist = part, d
                    end
                end
            end
        end
    end
    return best
end
function AutoShootHandler:Fire()
    if not self._running then return end
    local char = LocalPlayer.Character
    local hum = GetHumanoid(LocalPlayer)
    if not (char and hum and hum.Health > 0) then return end
    local tool = FindEquippedKnife() or GetFirearmTool()
    if not tool then return end
    local target = self:FindTarget()
    if not (target and target.Parent) then return end
    SilentAim:Set(target)
    SilentAim:SetHolding(true)
    self._lastFire = os.clock()
    pcall(function() tool:Activate() end)
    task.delay(AutoShootHandler.HOLD_EXTRA, function()
        if tool.Parent == LocalPlayer.Character then pcall(function() tool:Deactivate() end) end
    end)
end
function AutoShootHandler:Start()
    if not SilentAim:InstallHook("Auto Shoot") then return end
    if self._running then return end
    self._running = true
    self._lastFire = 0
    self._target = nil
    self._conns:add(RunService.Heartbeat:Connect(function()
        if not self._running then return end
        self._target = self:FindTarget()
        SilentAim:Set(self._target)
        if not self._target then return end
        local now = os.clock()
        if now - self._lastFire < AutoShootHandler.COOLDOWN then return end
        self._lastFire = now
        self:Fire()
    end))
end
function AutoShootHandler:Stop()
    if not self._running then return end
    self._running = false
    self._target = nil
    SilentAim:Set(nil)
    SilentAim:SetHolding(false)
    self._conns:clear()
end

local AimFollowHandler = {}
AimFollowHandler.__index = AimFollowHandler
function AimFollowHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _cachedPlayer=nil, _cachedPart=nil, _cacheTime=0, _cacheInterval=0.06 }, AimFollowHandler)
end
local function IsWeaponReady()
    local onlyFire = Config.Bannable.AimFollowFirearmOnly
    local onlyKnife = Config.Bannable.AimFollowKnifeOnly
    if not onlyFire and not onlyKnife then return true end
    local char = LocalPlayer.Character
    return (onlyFire and FindToolByPredicate(char, IsFirearm) ~= nil)
        or (onlyKnife and FindToolByPredicate(char, IsKnife) ~= nil)
end
function AimFollowHandler:FindTarget(useRaycast)
    local now = os.clock()
    if self._cachedPart and self._cachedTime and self._cachedPlayer
        and (now - self._cacheTime) < self._cacheInterval
        and IsValidEnemy(self._cachedPlayer) and IsAlive(self._cachedPlayer)
        and self._cachedPart.Parent and self._cachedPart:IsDescendantOf(self._cachedPlayer.Character) then
        return self._cachedPlayer, self._cachedPart
    end
    self._cacheTime = now
    local myHRP = GetHRP(LocalPlayer)
    if not myHRP then return nil, nil end
    local bodyParts = GetBodyPartsForAim()
    local bestPlayer, bestPart, bestDist = nil, nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsValidEnemy(player) and IsAlive(player) then
            local part = SelectAimPart(player, bodyParts)
            if part and (not useRaycast or HasLineOfSight(player, part)) then
                local d = (myHRP.Position - part.Position).Magnitude
                if d < bestDist then bestPlayer, bestPart, bestDist = player, part, d end
            end
        end
    end
    self._cachedPlayer, self._cachedPart = bestPlayer, bestPart
    return bestPlayer, bestPart
end
function AimFollowHandler:Refresh()
    if not self._running or not IsWeaponReady() then return end
    local cam = workspace.CurrentCamera
    local _, part = self:FindTarget(Config.Bannable.AimFollowRaycast)
    if cam and part then cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position) end
end
function AimFollowHandler:Start()
    if self._running then return end
    self._running = true
    self._cachedPlayer, self._cachedPart, self._cacheTime = nil, nil, 0
    self._conns:add(RunService.RenderStepped:Connect(function() self:Refresh() end))
end
function AimFollowHandler:Stop()
    if not self._running then return end
    self._running = false
    self._cachedPlayer, self._cachedPart, self._cacheTime = nil, nil, 0
    self._conns:clear()
end

local ESPHandler = {}
ESPHandler.__index = ESPHandler
local ESP_HIGHLIGHT_NAME = "DEOBFBYSZK_ESP_" .. tostring(math.random(100000, 999999))
local ESP_TRANSPARENCY = 0.1
function ESPHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _perPlayer={}, _container=nil }, ESPHandler)
end
function ESPHandler:GetContainer()
    if self._container and self._container.Parent then return self._container end
    local parent = GetGuiParent()
    if not parent then return nil end
    local folder = Instance.new("Folder")
    folder.Name = "F_" .. tostring(math.random(100000, 999999))
    folder.Parent = parent
    self._container = folder
    return folder
end
function ESPHandler:DestroyContainer()
    if self._container then pcall(function() self._container:Destroy() end); self._container = nil end
end
local HEADTAG_STATE = setmetatable({}, { __mode = "k" })
local function GetHeadTag(player)
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hrp:IsA("BasePart") then return nil end
    return hrp:FindFirstChild("HeadTag")
end
local function ApplyHeadTag(player, show)
    local headTag = GetHeadTag(player)
    if not headTag then return end
    if not HEADTAG_STATE[headTag] then
        HEADTAG_STATE[headTag] = { Enabled=headTag.Enabled, Enable=headTag.Enable, MaxDistance=headTag.MaxDistance, Size=headTag.Size }
    end
    local saved = HEADTAG_STATE[headTag]
    if show then
        pcall(function() headTag.Enabled = true end)
        pcall(function() headTag.Enable = true end)
    else
        pcall(function() headTag.Enabled = saved.Enabled end)
        pcall(function() headTag.Enable = saved.Enable end)
    end
end
function ESPHandler:ApplyHighlight(player, enabled)
    local char = player.Character
    if not enabled or not char then self:RemoveHighlight(player); return end
    local highlight = self._perPlayer[player]
    if not highlight or not highlight.Parent then
        local container = self:GetContainer()
        if not container then return end
        highlight = Instance.new("Highlight")
        highlight.Name = ESP_HIGHLIGHT_NAME
        highlight.Parent = container
        self._perPlayer[player] = highlight
    end
    if highlight.Adornee ~= char then highlight.Adornee = char end
    local color = ToColor3(Config.ESP.Color, Color3.fromRGB(0, 255, 0))
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 1 - ESP_TRANSPARENCY
    highlight.OutlineTransparency = 0
end
function ESPHandler:RemoveHighlight(player)
    local h = self._perPlayer[player]
    self._perPlayer[player] = nil
    if h then pcall(function() h:Destroy() end) end
end
function ESPHandler:UpdatePlayer(player, enabled)
    if not enabled or not IsValidEnemy(player) or not IsAlive(player) then
        self:RemoveHighlight(player)
        ApplyHeadTag(player, false)
        return
    end
    self:ApplyHighlight(player, true)
    ApplyHeadTag(player, Config.ESP.ShowName)
end
function ESPHandler:RefreshAll()
    if not self._running then return end
    for _, player in ipairs(Players:GetPlayers()) do self:UpdatePlayer(player, true) end
end
function ESPHandler:Start()
    if self._running then return end
    self._running = true
    for _, player in ipairs(Players:GetPlayers()) do self:UpdatePlayer(player, true) end
    self._conns:add(Players.PlayerAdded:Connect(function(p) task.defer(function() self:UpdatePlayer(p, true) end) end))
    self._conns:add(Players.PlayerRemoving:Connect(function(p) self:RemoveHighlight(p) end))
    self._conns:add(RunService.Heartbeat:Connect(function()
        if not self._running then return end
        self:RefreshAll()
    end))
end
function ESPHandler:Stop()
    if not self._running then self:DestroyContainer(); return end
    self._running = false
    self._conns:clear()
    for player in pairs(self._perPlayer) do
        self:RemoveHighlight(player)
        ApplyHeadTag(player, false)
    end
    table.clear(self._perPlayer)
    self:DestroyContainer()
end

local ESPLinesHandler = {}
ESPLinesHandler.__index = ESPLinesHandler
function ESPLinesHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _drawingLib=nil, _lines={}, _playerList={}, _lastUpdate=0, _updateInterval=0.2 }, ESPLinesHandler)
end
local function GetDrawingLib()
    local d = rawget(_G, "Drawing")
    if d and type(d.new) == "function" then return d end
    if type(getgenv) == "function" then
        local env = getgenv()
        if env and env.Drawing and type(env.Drawing.new) == "function" then return env.Drawing end
    end
    return nil
end
function ESPLinesHandler:GetDrawing()
    if self._drawingLib then return self._drawingLib end
    self._drawingLib = GetDrawingLib()
    return self._drawingLib
end
function ESPLinesHandler:GetTargetPart(player)
    local char = player and player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
end
function ESPLinesHandler:CreateLine(player)
    if self._lines[player] then return self._lines[player] end
    local lib = self:GetDrawing()
    if not lib then return nil end
    local ok, line = pcall(function()
        local l = lib.new("Line")
        l.Visible = false
        l.Color = ToColor3(Config.ESP.LinesColor, Color3.fromRGB(0, 255, 0))
        l.Thickness = 1.5
        l.Transparency = 0.15
        return l
    end)
    if ok and line then self._lines[player] = line; return line end
    return nil
end
function ESPLinesHandler:RemoveLine(player)
    local line = self._lines[player]
    self._lines[player] = nil
    if line then
        pcall(function() line.Visible = false end)
        pcall(function() if line.Remove then line:Remove() elseif line.Destroy then line:Destroy() end end)
    end
end
function ESPLinesHandler:RemoveAllLines()
    local keys = {}
    for p in pairs(self._lines) do keys[#keys+1] = p end
    for _, p in ipairs(keys) do self:RemoveLine(p) end
end
function ESPLinesHandler:UpdateList()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsValidEnemy(player) and IsAlive(player) then
            list[#list+1] = player
        end
    end
    self._playerList = list
end
function ESPLinesHandler:Render()
    local cam = workspace.CurrentCamera
    local myHRP = GetHRP(LocalPlayer)
    if not (cam and myHRP) then self:HideAll(); return end
    local now = os.clock()
    if (now - (self._lastUpdate or 0)) >= self._updateInterval then
        self._lastUpdate = now
        self:UpdateList()
    end
    local viewport = cam.ViewportSize
    local sx, sy, onScreen = cam:WorldToViewportPoint(myHRP.Position)
    local from = Vector2.new(sx, sy)
    if not onScreen or sx <= 0 then from = Vector2.new(viewport.X * 0.5, viewport.Y - 16) end
    local color = ToColor3(Config.ESP.LinesColor, Color3.fromRGB(0, 255, 0))
    local shown = {}
    for _, player in ipairs(self._playerList) do
        local part = self:GetTargetPart(player)
        local line = self:CreateLine(player)
        if part and line then
            if line.Color ~= color then line.Color = color end
            local px, py, pz = cam:WorldToViewportPoint(part.Position)
            if pz > 0 then
                line.From = from
                line.To = Vector2.new(px, py)
                line.Visible = true
                shown[player] = true
            else
                line.Visible = false
            end
        end
    end
    for player, line in pairs(self._lines) do
        if not shown[player] and line then line.Visible = false end
    end
end
function ESPLinesHandler:HideAll()
    for _, line in pairs(self._lines) do
        if line then pcall(function() line.Visible = false end) end
    end
end
function ESPLinesHandler:Start()
    if self._running then return end
    self._running = true
    self._playerList = {}
    self._lastUpdate = 0
    self._conns:add(RunService.RenderStepped:Connect(function() if self._running then self:Render() end end))
end
function ESPLinesHandler:Stop()
    if not self._running then self:RemoveAllLines(); return end
    self._running = false
    self._conns:clear()
    self:RemoveAllLines()
    self._playerList = {}
end

local KillAllHandler = {}
KillAllHandler.__index = KillAllHandler
function KillAllHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _tick=0 }, KillAllHandler)
end
function KillAllHandler:GetKnifeKillRemote()
    local packages = ReplicatedStorage:FindFirstChild("Packages") or WaitForChildSafe(ReplicatedStorage, "Packages", 2)
    local net = packages and (packages:FindFirstChild("Networking") or WaitForChildSafe(packages, "Networking", 2))
    local remote = net and (net:FindFirstChild("RE/Combat/KnifeKill") or WaitForChildSafe(net, "RE/Combat/KnifeKill", 2))
    if remote and remote:IsA("RemoteEvent") then return remote end
    return nil
end
function KillAllHandler:InPlayableMatch()
    if not HasGameAttribute(LocalPlayer) then return false end
    return IsMatchTimerVisible()
end
function KillAllHandler:HideMatchHUD()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local main = pg and (pg:FindFirstChild("Main") or pg)
    local frame = main and main:FindFirstChild("MainGameFrame")
    if frame and frame:IsA("GuiObject") then pcall(function() frame.Visible = false end) end
end
function KillAllHandler:Kill()
    if not self._running then return end
    local remote = self:GetKnifeKillRemote()
    if not remote then return end
    local myHRP = GetHRP(LocalPlayer)
    if not myHRP then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidEnemy(player) and IsAlive(player) then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                pcall(function() remote:FireServer(player, "Knife", myHRP, char) end)
            end
        end
    end
end
function KillAllHandler:Start()
    if self._running then return end
    self._running = true
    self._tick = 0
    self._conns:add(RunService.Heartbeat:Connect(function(dt)
        if not self._running then return end
        if not self:InPlayableMatch() then return end
        self._tick = self._tick + dt
        if self._tick < 1 then return end
        self._tick = 0
        self:Kill()
        self:HideMatchHUD()
    end))
    self._conns:add(LocalPlayer.CharacterAdded:Connect(function()
        task.defer(function() self:Stop() end)
    end))
end
function KillAllHandler:Stop()
    if not self._running then return end
    self._running = false
    self._tick = 0
    self._conns:clear()
end

local KillAllAlwaysOn = false
local KillAllToggleRef = nil
local KILLALL_WATCHER_GEN = 0

local function ToggleKillAll(enabled)
    Config.Bannable.KillAll = enabled
    if enabled then KillAllHandler:Start() else KillAllHandler:Stop() end
end

local function KillAllWatcherThread()
    task.spawn(function()
        local gen = KILLALL_WATCHER_GEN + 1
        KILLALL_WATCHER_GEN = gen
        while KillAllAlwaysOn and gen == KILLALL_WATCHER_GEN and not IS_UNLOADING do
            if not Config.Bannable.KillAll or not KillAllHandler._running then
                Config.Bannable.KillAll = true
                KillAllHandler:Start()
            end
            task.wait(1)
        end
    end)
end

local InvisibleHandler = {}
InvisibleHandler.__index = InvisibleHandler
function InvisibleHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _saved={} }, InvisibleHandler)
end
function InvisibleHandler:Apply()
    local char = LocalPlayer.Character
    if not char then return end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("BasePart") then
            if self._saved[desc] == nil then self._saved[desc] = desc.Transparency end
            desc.Transparency = math.max(desc.Transparency, 0.6)
        elseif desc:IsA("Decal") or desc:IsA("Texture") then
            desc.Transparency = 0.6
        end
    end
end
function InvisibleHandler:Restore()
    for part, original in pairs(self._saved) do
        if part and part.Parent then pcall(function() part.Transparency = original end) end
    end
    table.clear(self._saved)
end
function InvisibleHandler:Start()
    if self._running then return end
    self._running = true
    self._saved = {}
    self._conns:add(RunService.Stepped:Connect(function() if self._running then self:Apply() end end))
    self._conns:add(LocalPlayer.CharacterAdded:Connect(function()
        task.defer(function()
            self._running = false
            self._conns:clear()
            self:Restore()
        end)
    end))
end
function InvisibleHandler:Stop()
    if not self._running then self:Restore(); return end
    self._running = false
    self._conns:clear()
    self:Restore()
end

local DesyncHandler = {}
DesyncHandler.__index = DesyncHandler
function DesyncHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _hrp=nil, _humanoid=nil, _animTrack=nil, _velY=0, _grounded=true, _marker=nil }, DesyncHandler)
end
function DesyncHandler:Update(dt)
    local hrp = self._hrp
    if not (hrp and hrp.Parent) then self:Stop(); return end
    if not hrp.Anchored then pcall(function() hrp.Anchored = true end) end
    dt = dt or 0
    local hum = self._humanoid
    local moveDir = hum and hum.MoveDirection or Vector3.zero
    local moving = moveDir.Magnitude > 0.01
    local speed = hum and tonumber(hum.WalkSpeed) or 16
    if not speed or speed <= 0 then speed = 16 end
    local cf = hrp.CFrame
    local pos = cf.Position
    if moving then
        local np = pos + (moveDir * speed * dt)
        cf = CFrame.lookAt(np, np + moveDir)
        pos = cf.Position
    end
    self._velY = (self._velY or 0) - (workspace.Gravity * dt)
    local newY = pos.Y + (self._velY * dt)
    if not self._rayParams then
        self._rayParams = RaycastParams.new()
        self._rayParams.FilterType = Enum.RaycastFilterType.Exclude
        self._rayParams.IgnoreWater = true
    end
    self._rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
    local hit = workspace:Raycast(pos, Vector3.new(0, -200, 0), self._rayParams)
    local groundY = hit and hit.Position.Y
    local floorY = groundY and (groundY + (hum and hum.HipHeight or 2) + (hrp.Size.Y / 2)) or nil
    if floorY and newY <= floorY then
        newY = floorY
        self._velY = 0
        self._grounded = true
    else
        self._grounded = false
    end
    cf = CFrame.new(pos.X, newY, pos.Z) * (cf - cf.Position)
    pcall(function() hrp.CFrame = cf end)
end
function DesyncHandler:Start()
    if self._running then return end
    local hrp = GetHRP(LocalPlayer)
    if not hrp then return end
    self._running = true
    self._hrp = hrp
    self._humanoid = GetHumanoid(LocalPlayer)
    self._velY = 0
    self._grounded = true
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.Anchored = true
    end)
    self._conns:add(RunService.RenderStepped:Connect(function(dt)
        if self._running then self:Update(dt) end
    end))
    self._conns:add(UserInputService.JumpRequest:Connect(function()
        if not (self._running and self._grounded) then return end
        local hum = GetHumanoid(LocalPlayer)
        if hum then
            local jp = 50
            if hum.UseJumpPower then jp = tonumber(hum.JumpPower) or jp
            else jp = math.sqrt(2 * workspace.Gravity * (tonumber(hum.JumpHeight) or 7)) end
            self._velY = jp
            self._grounded = false
        end
    end))
    self._conns:add(LocalPlayer.CharacterAdded:Connect(function()
        task.defer(function()
            self._running = false
            self._conns:clear()
            Config.Bannable.Desync = false
            if self._hrp then pcall(function() self._hrp.Anchored = false end) end
            self._hrp = nil
        end)
    end))
end
function DesyncHandler:Stop()
    if not self._running then return end
    self._running = false
    self._conns:clear()
    local hrp = self._hrp
    self._hrp = nil
    self._humanoid = nil
    self._velY = 0
    self._grounded = true
    if hrp and hrp.Parent then
        pcall(function()
            hrp.Anchored = false
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

local EventFarmHandler = {}
EventFarmHandler.__index = EventFarmHandler
function EventFarmHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _tick=0 }, EventFarmHandler)
end
function EventFarmHandler:TouchSpawnables()
    if type(firetouchinterest) ~= "function" then return end
    local hrp = GetHRP(LocalPlayer)
    if not hrp then return end
    local spawnables = workspace:FindFirstChild("SpawnablesClient")
    if not spawnables then return end
    for _, spawn in ipairs(spawnables:GetChildren()) do
        local touch = spawn:FindFirstChild("Touch", true)
        if touch and touch:IsA("BasePart") then
            pcall(function()
                firetouchinterest(hrp, touch, 0)
                firetouchinterest(hrp, touch, 1)
            end)
        end
    end
end
function EventFarmHandler:Start()
    if self._running then return end
    self._running = true
    self._tick = 0
    self._conns:add(RunService.Heartbeat:Connect(function(dt)
        if not self._running then return end
        self._tick = self._tick + dt
        if self._tick < 0.5 then return end
        self._tick = 0
        if not HasGameAttribute(LocalPlayer) then return end
        self:TouchSpawnables()
    end))
end
function EventFarmHandler:Stop()
    if not self._running then return end
    self._running = false
    self._tick = 0
    self._conns:clear()
end

local BoxBuyerHandler = {}
BoxBuyerHandler.__index = BoxBuyerHandler
local BOX_LIST = {
    "Knife Box #1","Knife Box #2","Gun Box #1","Gun Box #2",
    "Mythic Box #1","Mythic Box #2","Mythic Box #3","Mythic Box #4",
}
local function GetBoxPrice(name)
    if type(name) == "string" and string.find(name, "Mythic", 1, true) then return 1500 end
    return 500
end
local function SetSelectedBox(name)
    if type(name) ~= "string" or name == "" then return end
    Config.Boxes.Selected = name
    Config.Boxes.Price = GetBoxPrice(name)
end
function BoxBuyerHandler.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _tick=0, _remote=nil }, BoxBuyerHandler)
end
function BoxBuyerHandler:GetBuyCaseRemote()
    if self._remote and self._remote.Parent then return self._remote end
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    local net = packages and packages:FindFirstChild("Networking")
    local rf = net and net:FindFirstChild("RF/Shop/BuyCase")
    if rf and rf:IsA("RemoteFunction") then self._remote = rf; return rf end
    return nil
end
function BoxBuyerHandler:Purchase()
    local remote = self:GetBuyCaseRemote()
    if not remote then return false, "missing_remote" end
    local selected = tostring(Config.Boxes.Selected or "")
    if selected == "" then return false, "missing_selection" end
    local ok = pcall(function() remote:InvokeServer(selected) end)
    if not ok then return false, "invoke_failed" end
    return true, "ok"
end
function BoxBuyerHandler:Start()
    if self._running then return end
    self._running = true
    self._tick = 0
    self._conns:add(RunService.Heartbeat:Connect(function(dt)
        if not self._running then return end
        self._tick = self._tick + dt
        if self._tick < 1 then return end
        self._tick = 0
        self:Purchase()
    end))
end
function BoxBuyerHandler:Stop()
    if not self._running then return end
    self._running = false
    self._conns:clear()
end
SetSelectedBox(Config.Boxes.Selected)

local FOVHelper = {}
FOVHelper.__index = FOVHelper
function FOVHelper.new()
    return setmetatable({ _running=false, _conns=ConnectionBucket.new(), _ring=nil, _container=nil }, FOVHelper)
end
function FOVHelper:GetContainer()
    if self._container and self._container.Parent then return self._ring end
    local parent = GetGuiParent()
    if not parent then return nil end
    local sg = Instance.new("ScreenGui")
    sg.Name = "DEOBFBYSZK_FOV"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999999
    sg.Enabled = false
    sg.Parent = parent
    local ring = Instance.new("Frame")
    ring.Name = "Ring"
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.Size = UDim2.fromOffset(400, 400)
    ring.Parent = sg
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = ring
    self._container = sg
    self._ring = ring
    return ring
end
function FOVHelper:DestroyContainer()
    self._ring = nil
    if self._container then pcall(function() self._container:Destroy() end); self._container = nil end
end
function FOVHelper:IsVisible() return Config.Bannable.FOVEnabled and Config.Bannable.FOVVisible end
function FOVHelper:Render()
    if not self:IsVisible() then
        if self._container then self._container.Enabled = false end
        return
    end
    local ring = self:GetContainer()
    if not ring then return end
    local cursor = GetCursorPosition()
    local radius = math.max(1, tonumber(Config.Bannable.FOVRadius) or 200)
    ring.Size = UDim2.fromOffset(radius * 2, radius * 2)
    ring.Position = UDim2.fromOffset(cursor.X, cursor.Y)
    self._container.Enabled = true
end
function FOVHelper:Start()
    if self._running then return end
    self._running = true
    self._conns:add(RunService.RenderStepped:Connect(function() self:Render() end))
end
function FOVHelper:Destroy()
    self._running = false
    self._conns:clear()
    self:DestroyContainer()
end

local PLATFORM_ROWS = { "Right Platforms", "Left Platforms" }
local PAD_TABLE = {
    ["Right Platforms"] = {
        ["1v1"] = { zone="PadZone1", Main="Pad1", Alt="Pad2" },
        ["2v2"] = { zone="PadZone2", Main="Pad1", Alt="Pad2" },
        ["3v3"] = { zone="PadZone3", Main="Pad1", Alt="Pad2" },
        ["4v4"] = { zone="PadZone4", Main="Pad1", Alt="Pad2" },
    },
    ["Left Platforms"] = {
        ["1v1"] = { zone="PadZone5", Main="Pad1", Alt="Pad2" },
        ["2v2"] = { zone="PadZone6", Main="Pad1", Alt="Pad2" },
        ["3v3"] = { zone="PadZone7", Main="Pad1", Alt="Pad2" },
        ["4v4"] = { zone="PadZone8", Main="Pad1", Alt="Pad2" },
    },
}
local function GetPadPart(role)
    local row = PAD_TABLE[Config.AutoTeleport.PlatformRow] and Config.AutoTeleport.PlatformRow or "Right Platforms"
    local duel = PAD_TABLE[row][Config.AutoTeleport.DuelType] and Config.AutoTeleport.DuelType or "1v1"
    local entry = PAD_TABLE[row][duel]
    local padZones = workspace:FindFirstChild("PadZones")
    local zone = padZones and padZones:FindFirstChild(entry.zone)
    local container = zone and zone:FindFirstChild(entry[role] or entry.Main)
    local pad = container and container:FindFirstChild("Pad")
    return (pad and pad:IsA("BasePart")) and pad or nil
end

local AutoTeleportHandler = {}
AutoTeleportHandler.__index = AutoTeleportHandler
function AutoTeleportHandler.new(role)
    return setmetatable({ _role=role or "Main", _running=false, _conns=ConnectionBucket.new(), _tick=0, _lastMove=0, _highlightedPad=nil, _savedPadColor=nil }, AutoTeleportHandler)
end
function AutoTeleportHandler:IsEnabled()
    if self._role == "Main" then return Config.AutoTeleport.Main end
    return Config.AutoTeleport.Alt
end
function AutoTeleportHandler:IsOnPad()
    local pad = GetPadPart(self._role)
    local hrp = GetHRP(LocalPlayer)
    if not (pad and hrp) then return false end
    local lp = pad.CFrame:PointToObjectSpace(hrp.Position)
    local half = pad.Size / 2
    return math.abs(lp.X) <= half.X + 0.5 and math.abs(lp.Z) <= half.Z + 0.5
        and lp.Y >= -(half.Y + 6) and lp.Y <= (half.Y + 14)
end
function AutoTeleportHandler:TimerVisible() return IsMatchTimerVisible() end
function AutoTeleportHandler:TeleportToPad()
    if not self:IsEnabled() then return end
    local pad = GetPadPart(self._role)
    if not pad or self:IsOnPad() then return end
    if os.clock() - self._lastMove < 0.5 then return end
    self._lastMove = os.clock()
    local hum = GetHumanoid(LocalPlayer)
    if hum then pcall(function() hum:MoveTo(pad.Position) end) end
end
function AutoTeleportHandler:HighlightPad(pad)
    if not pad then
        if self._highlightedPad and self._savedPadColor then
            local p, s = self._highlightedPad, self._savedPadColor
            pcall(function() if p.Parent then p.Color = s.Color; p.Transparency = s.Transparency end end)
        end
        self._highlightedPad, self._savedPadColor = nil, nil
        return
    end
    if self._highlightedPad ~= pad then
        if self._highlightedPad and self._savedPadColor then
            local p, s = self._highlightedPad, self._savedPadColor
            pcall(function() if p.Parent then p.Color = s.Color; p.Transparency = s.Transparency end end)
        end
        self._highlightedPad = pad
        self._savedPadColor = { Color=pad.Color, Transparency=pad.Transparency }
    end
    pad.Color = self._role == "Alt" and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(70, 145, 255)
    pad.Transparency = 0.5
end
function AutoTeleportHandler:Refresh()
    if not self._running then return end
    if HasGameAttribute(LocalPlayer) and LocalPlayer.Character then
        self:HighlightPad(nil)
        return
    end
    local pad = GetPadPart(self._role)
    self:HighlightPad(pad)
    if self:TimerVisible() or self:IsOnPad() then return end
    self:TeleportToPad()
end
function AutoTeleportHandler:Start()
    if not self:IsEnabled() then return end
    if self._running then return end
    self._running = true
    self._tick = 0
    self._conns:add(RunService.Heartbeat:Connect(function(dt)
        if not self._running then return end
        self._tick = self._tick + dt
        if self._tick < 0.5 then return end
        self._tick = 0
        self:Refresh()
    end))
    self:Refresh()
end
function AutoTeleportHandler:Stop()
    if not self._running then self:HighlightPad(nil); return end
    self._running = false
    self._conns:clear()
    self:HighlightPad(nil)
end

--=================================================================
-- INSTANCIAS
--=================================================================
local JumpPowerInstance     = JumpPowerHandler.new()
local SpeedInstance         = SpeedHandler.new()
local FloatingFloorInstance = FloatingFloorHandler.new()
local HitboxInstance        = HitboxHandler.new()
local TriggerbotInstance    = TriggerbotHandler.new()
local MacroInstance         = MacroHandler.new()
local AutoShootInstance     = AutoShootHandler.new()
local AimFollowInstance     = AimFollowHandler.new()
local ESPInstance           = ESPHandler.new()
local ESPLinesInstance      = ESPLinesHandler.new()
local KillAllInstance       = KillAllHandler.new()
local InvisibleInstance     = InvisibleHandler.new()
local DesyncInstance        = DesyncHandler.new()
local EventFarmInstance     = EventFarmHandler.new()
local AutoTeleportMainInstance = AutoTeleportHandler.new("Main")
local AutoTeleportAltInstance  = AutoTeleportHandler.new("Alt")
local BoxBuyerInstance      = BoxBuyerHandler.new()
local FOVInstance           = FOVHelper.new()

FOVInstance:Start()

local function RefreshJump()
    if Config.PlayerCheats.JumpPowerEnabled or Config.PlayerCheats.InfiniteJump then
        JumpPowerInstance:Start(); JumpPowerInstance:ApplyJumpPower()
    else JumpPowerInstance:Stop() end
end
local function RefreshSpeed()
    if Config.PlayerCheats.SpeedEnabled then SpeedInstance:Start(); SpeedInstance:ApplySpeed()
    else SpeedInstance:Stop() end
end
local function RefreshFloatingFloor()
    if Config.FloatingFloor.Enabled or Config.FloatingFloor.HideMap then
        FloatingFloorInstance:Start()
        if Config.FloatingFloor.HideMap then FloatingFloorInstance:ApplyHideMap() else FloatingFloorInstance:RestoreHideMap() end
        FloatingFloorInstance:UpdateFloor()
    else FloatingFloorInstance:Stop(); FloatingFloorInstance:RestoreHideMap() end
end
local function RefreshHitbox()
    if Config.Hitbox.Enabled then HitboxInstance:Start(); HitboxInstance:Refresh()
    else HitboxInstance:Stop() end
end
local function RefreshTriggerbot()
    if Config.Bannable.Triggerbot then TriggerbotInstance:Start() else TriggerbotInstance:Stop() end
end
local function RefreshMacro()
    if Config.Bannable.Macro then MacroInstance:Start() else MacroInstance:Stop() end
end
local function RefreshSilentAim()
    if Config.Bannable.SilentAim then SilentAim:Start() else SilentAim:Stop() end
end
local function RefreshAutoShoot()
    if Config.Bannable.AutoShoot then AutoShootInstance:Start() else AutoShootInstance:Stop() end
end
local function RefreshAimFollow()
    if Config.Bannable.AimFollow then AimFollowInstance:Start() else AimFollowInstance:Stop() end
end
local function RefreshESP()
    if Config.ESP.Enabled then ESPInstance:Start() else ESPInstance:Stop() end
end
local function RefreshESPLines()
    if Config.ESP.Lines then ESPLinesInstance:Start() else ESPLinesInstance:Stop() end
end
local function RefreshKillAll() ToggleKillAll(Config.Bannable.KillAll) end
local function RefreshInvisible()
    if Config.Bannable.Invisible then InvisibleInstance:Start() else InvisibleInstance:Stop() end
end
local function RefreshDesync()
    if Config.Bannable.Desync then DesyncInstance:Start() else DesyncInstance:Stop() end
end
local function RefreshEventFarm()
    if Config.AutoTeleport.EventFarm then EventFarmInstance:Start() else EventFarmInstance:Stop() end
end
local function RefreshAutoTeleport()
    if Config.AutoTeleport.Main then AutoTeleportMainInstance:Start() else AutoTeleportMainInstance:Stop() end
    if Config.AutoTeleport.Alt then AutoTeleportAltInstance:Start() else AutoTeleportAltInstance:Stop() end
end
local function RefreshBoxBuyer()
    if Config.Boxes.AutoBuy then BoxBuyerInstance:Start() else BoxBuyerInstance:Stop() end
end

--=================================================================
-- BUBBLES
--=================================================================
local BubbleSystem = { SavedPositions={}, LivePositions={}, Registered={}, Editing=false }

function BubbleSystem:RefreshStroke(button)
    if not button or not button.Parent then return end
    local stroke = button:FindFirstChildOfClass("UIStroke")
    if not stroke then return end
    if self.Editing then stroke.Color = Color3.fromRGB(79, 195, 247); stroke.Thickness = 2
    else stroke.Color = Color3.fromRGB(115, 115, 115); stroke.Thickness = 1 end
end
function BubbleSystem:RefreshAllStrokes()
    for _, btn in pairs(self.Registered) do self:RefreshStroke(btn) end
end
function BubbleSystem:SaveAllPositions()
    for key, pos in pairs(self.LivePositions) do self.SavedPositions[key] = pos end
end
function BubbleSystem:ResetPositions()
    for key, default in pairs(self.LivePositions) do
        self.SavedPositions[key] = nil
        local btn = self.Registered[key]
        if btn and btn.Parent then btn.Position = default end
    end
end
function BubbleSystem.SetEditing(enabled)
    BubbleSystem.Editing = enabled == true
    BubbleSystem:RefreshAllStrokes()
    if not BubbleSystem.Editing then BubbleSystem:SaveAllPositions() end
end

local function MakeBubble(position, text, onClick)
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui") or WaitForChildSafe(LocalPlayer, "PlayerGui", 10)
    if not pg then return nil end
    local sg = pg:FindFirstChild("DEOBFBYSZK_QuickButtons")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "DEOBFBYSZK_QuickButtons"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.DisplayOrder = 2147483646
        sg.Parent = pg
    end
    local btn = Instance.new("TextButton")
    btn.Name = "Button_" .. text
    btn.AnchorPoint = Vector2.new(1, 1)
    btn.Position = position
    btn.Size = UDim2.new(0, 48, 0, 48)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(235, 235, 235)
    btn.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(115, 115, 115)
    stroke.Parent = btn

    local DRAG_THRESHOLD = 6
    local pressing, dragged, startPos, startBtnPos = false, false, nil, nil
    local key = text
    BubbleSystem.LivePositions[key] = btn.Position
    local saved = BubbleSystem.SavedPositions[key]
    if saved then btn.Position = saved end
    BubbleSystem.Registered[key] = btn

    local function isPrimary(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    end
    btn.InputBegan:Connect(function(input)
        if not isPrimary(input) then return end
        dragged = false
        if not BubbleSystem.Editing then return end
        pressing = true
        startPos = input.Position
        startBtnPos = btn.Position
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not BubbleSystem.Editing or not pressing or not startPos then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - startPos
        if not dragged and delta.Magnitude > DRAG_THRESHOLD then dragged = true end
        if not dragged then return end
        local newPos = UDim2.new(startBtnPos.X.Scale, startBtnPos.X.Offset + delta.X, startBtnPos.Y.Scale, startBtnPos.Y.Offset + delta.Y)
        btn.Position = newPos
        BubbleSystem.LivePositions[key] = newPos
    end)
    UserInputService.InputEnded:Connect(function(input)
        if isPrimary(input) then pressing = false end
    end)
    btn.Activated:Connect(function()
        if BubbleSystem.Editing or dragged then return end
        onClick()
    end)
    return btn
end

local KILLALL_BUBBLE, SILENT_BUBBLE, AUTOSHOOT_BUBBLE, INVIS_BUBBLE, DESYNC_BUBBLE

local function UpdateKillAllBubble()
    if not KILLALL_BUBBLE then return end
    KILLALL_BUBBLE.Text = "KA"
    if Config.Bannable.KillAll then
        KILLALL_BUBBLE.BackgroundColor3 = Color3.fromRGB(30, 156, 88)
        KILLALL_BUBBLE.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        KILLALL_BUBBLE.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        KILLALL_BUBBLE.TextColor3 = Color3.fromRGB(235, 235, 235)
    end
end
local function UpdateSilentBubble()
    if not SILENT_BUBBLE then return end
    SILENT_BUBBLE.Text = "SA"
    if Config.Bannable.SilentAim then
        SILENT_BUBBLE.BackgroundColor3 = Color3.fromRGB(30, 156, 88)
        SILENT_BUBBLE.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        SILENT_BUBBLE.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        SILENT_BUBBLE.TextColor3 = Color3.fromRGB(235, 235, 235)
    end
end
local function UpdateAutoShootBubble()
    if not AUTOSHOOT_BUBBLE then return end
    AUTOSHOOT_BUBBLE.Text = "AS"
    if Config.Bannable.AutoShoot then
        AUTOSHOOT_BUBBLE.BackgroundColor3 = Color3.fromRGB(30, 156, 88)
        AUTOSHOOT_BUBBLE.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        AUTOSHOOT_BUBBLE.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        AUTOSHOOT_BUBBLE.TextColor3 = Color3.fromRGB(235, 235, 235)
    end
end
local function UpdateInvisibleBubble()
    if not INVIS_BUBBLE then return end
    INVIS_BUBBLE.Text = "INV"
    if Config.Bannable.Invisible then
        INVIS_BUBBLE.BackgroundColor3 = Color3.fromRGB(30, 156, 88)
        INVIS_BUBBLE.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        INVIS_BUBBLE.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        INVIS_BUBBLE.TextColor3 = Color3.fromRGB(235, 235, 235)
    end
end
local function UpdateDesyncBubble()
    if not DESYNC_BUBBLE then return end
    DESYNC_BUBBLE.Text = "DSY"
    if Config.Bannable.Desync then
        DESYNC_BUBBLE.BackgroundColor3 = Color3.fromRGB(30, 156, 88)
        DESYNC_BUBBLE.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        DESYNC_BUBBLE.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        DESYNC_BUBBLE.TextColor3 = Color3.fromRGB(235, 235, 235)
    end
end

KILLALL_BUBBLE = MakeBubble(UDim2.new(1, -12, 1, -188), "KA", function()
    Config.Bannable.KillAll = not Config.Bannable.KillAll
    RefreshKillAll(); UpdateKillAllBubble(); SaveConfig()
end)
SILENT_BUBBLE = MakeBubble(UDim2.new(1, -12, 1, -132), "SA", function()
    Config.Bannable.SilentAim = not Config.Bannable.SilentAim
    RefreshSilentAim(); UpdateSilentBubble(); SaveConfig()
end)
AUTOSHOOT_BUBBLE = MakeBubble(UDim2.new(1, -12, 1, -356), "AS", function()
    Config.Bannable.AutoShoot = not Config.Bannable.AutoShoot
    RefreshAutoShoot(); UpdateAutoShootBubble(); SaveConfig()
end)
INVIS_BUBBLE = MakeBubble(UDim2.new(1, -12, 1, -244), "INV", function()
    Config.Bannable.Invisible = not Config.Bannable.Invisible
    RefreshInvisible(); UpdateInvisibleBubble(); SaveConfig()
end)
DESYNC_BUBBLE = MakeBubble(UDim2.new(1, -12, 1, -300), "DSY", function()
    Config.Bannable.Desync = not Config.Bannable.Desync
    RefreshDesync(); UpdateDesyncBubble(); SaveConfig()
end)

--=================================================================
-- TABS
--=================================================================

local SettingsTab = WindWindow:Tab({ Title = "Settings", Icon = "cog" })

SettingsTab:Toggle({
    Title = "Edit Bubble Positions",
    Desc = "Unlock bubbles to drag them. Turn off to save positions.",
    Value = false,
    Callback = function(state)
        BubbleSystem.SetEditing(state)
        if IS_LOADING_CONFIG or SKIP_SAVE then return end
        if state then Notify("Bubbles", "Edit mode ON.", "move", 4)
        else Notify("Bubbles", "Bubble positions saved.", "check", 3) end
    end,
})

SettingsTab:Button({
    Title = "Reset Bubble Positions",
    Desc = "Move every bubble back to its default position.",
    Callback = function()
        BubbleSystem:ResetPositions()
        Notify("Bubbles", "Positions reset.", "rotate-ccw", 3)
    end,
})

SettingsTab:Space()

SettingsTab:Paragraph({
    Title = "DEOBFBYSZK - Join our Discord",
    Thumbnail = "https://i.pinimg.com/736x/35/ee/85/35ee85bde9ee7e0d3a5d976ea2788c43.jpg",
    ThumbnailSize = 56,
    Buttons = {
        {
            Title = "Copy Discord Invite",
            Callback = function()
                pcall(function() setclipboard(DISCORD_INVITE) end)
                Notify("Discord", "Link copied!", "link", 3)
            end,
        },
    },
})

SettingsTab:Space()

SettingsTab:Toggle({
    Title = "Toggle Panel Background",
    Value = true,
    Callback = function(state)
        pcall(function() WindWindow:SetPanelBackground(state) end)
        SaveConfig()
    end,
})

SettingsTab:Toggle({
    Title = "Enable Notifications",
    Value = true,
    Callback = function(state)
        Config.Notifications.Enabled = state
        SaveConfig()
    end,
})

SettingsTab:Space()
SettingsTab:Divider()
SettingsTab:Space()

SettingsTab:Keybind({
    Title = "Toggle UI Keybind",
    Value = Config.Keybinds.ToggleUI,
    Callback = function(key)
        if key and Enum.KeyCode[key] then
            pcall(function() WindWindow:SetToggleKey(Enum.KeyCode[key]) end)
        end
        SaveConfig()
    end,
})

SettingsTab:Space()

SettingsTab:Button({
    Title = "Unload Script",
    Desc = "Turns off all features and removes the UI.",
    Callback = function()
        local fn = getgenv()[UNLOAD_KEY]
        if type(fn) == "function" then pcall(fn) end
    end,
})

local PlayerCheatsTab = WindWindow:Tab({ Title = "Player Cheats", Icon = "user" })

PlayerCheatsTab:Toggle({
    Title = "Enable Jump Power",
    Value = Config.PlayerCheats.JumpPowerEnabled,
    Callback = function(state)
        Config.PlayerCheats.JumpPowerEnabled = state
        RefreshJump()
        if not IS_LOADING_CONFIG and not SKIP_SAVE then SaveConfig() end
    end,
})
PlayerCheatsTab:Slider({
    Title = "Jump Power Value",
    Step = 1,
    Value = { Min=0, Max=100, Default=Config.PlayerCheats.JumpPower },
    Callback = function(value)
        Config.PlayerCheats.JumpPower = value
        RefreshJump()
        SaveConfig()
    end,
})
PlayerCheatsTab:Toggle({
    Title = "Enable Infinite Jump",
    Value = Config.PlayerCheats.InfiniteJump,
    Callback = function(state)
        Config.PlayerCheats.InfiniteJump = state
        RefreshJump()
        if not IS_LOADING_CONFIG and not SKIP_SAVE then SaveConfig() end
    end,
})
PlayerCheatsTab:Space()
PlayerCheatsTab:Toggle({
    Title = "Enable Speed Hack",
    Value = Config.PlayerCheats.SpeedEnabled,
    Callback = function(state)
        Config.PlayerCheats.SpeedEnabled = state
        RefreshSpeed()
        if not IS_LOADING_CONFIG and not SKIP_SAVE then SaveConfig() end
    end,
})
PlayerCheatsTab:Slider({
    Title = "Speed Value",
    Step = 1,
    Value = { Min=0, Max=100, Default=Config.PlayerCheats.Speed },
    Callback = function(value)
        Config.PlayerCheats.Speed = value
        RefreshSpeed()
        SaveConfig()
    end,
})

local AimLegitTab = WindWindow:Tab({ Title = "Aim Legit", Icon = "crosshair" })

local MacroToggle = AimLegitTab:Toggle({
    Title = "Macro",
    Value = Config.Bannable.Macro,
    Callback = function(state)
        Config.Bannable.Macro = state
        RefreshMacro()
        if not IS_LOADING_CONFIG and not SKIP_SAVE then
            Notify("Macro", state and "Enabled" or "Disabled", state and "crosshair" or "info", 3)
        end
    end,
})
AimLegitTab:Space()
local TriggerbotToggle = AimLegitTab:Toggle({
    Title = "Triggerbot",
    Value = Config.Bannable.Triggerbot,
    Callback = function(state)
        Config.Bannable.Triggerbot = state
        if state and MacroToggle then MacroToggle:Set(false) end
        RefreshTriggerbot(); RefreshMacro()
        if not IS_LOADING_CONFIG and not SKIP_SAVE then
            Notify("Triggerbot", state and "Enabled" or "Disabled", state and "crosshair" or "info", 3)
            SaveConfig()
        end
    end,
})
AimLegitTab:Space()
AimLegitTab:Divider()
AimLegitTab:Space()
AimLegitTab:Toggle({
    Title = "Aim at Player",
    Desc = "Rotates the camera toward the closest visible enemy.",
    Value = Config.Bannable.AimFollow,
    Callback = function(state)
        Config.Bannable.AimFollow = state
        RefreshAimFollow()
        if not IS_LOADING_CONFIG and not SKIP_SAVE then
            Notify("Aim Follow", state and "Enabled" or "Disabled", state and "crosshair" or "info", 3)
            SaveConfig()
        end
    end,
})
AimLegitTab:Toggle({
    Title = "Only with firearm",
    Value = Config.Bannable.AimFollowFirearmOnly,
    Callback = function(state) Config.Bannable.AimFollowFirearmOnly = state; SaveConfig() end,
})
AimLegitTab:Toggle({
    Title = "Only with knife",
    Value = Config.Bannable.AimFollowKnifeOnly,
    Callback = function(state) Config.Bannable.AimFollowKnifeOnly = state; SaveConfig() end,
})
AimLegitTab:Toggle({
    Title = "Use raycast",
    Value = Config.Bannable.AimFollowRaycast,
    Callback = function(state) Config.Bannable.AimFollowRaycast = state; SaveConfig() end,
})

local AimBannableTab = WindWindow:Tab({ Title = "Aim Bannable", Icon = "crosshair" })

AimBannableTab:Toggle({
    Title = "Silent Aim",
    Desc = "Redirects your shots to the closest enemy to the cursor.",
    Value = Config.Bannable.SilentAim,
    Callback = function(state)
        Config.Bannable.SilentAim = state
        if state then
            if MacroToggle then MacroToggle:Set(false) end
            if TriggerbotToggle then TriggerbotToggle:Set(false) end
        end
        RefreshSilentAim(); UpdateSilentBubble()
        if not IS_LOADING_CONFIG and not SKIP_SAVE then
            Notify("Silent Aim", state and "Enabled" or "Disabled", state and "crosshair" or "info", 3)
            SaveConfig()
        end
    end,
})
AimBannableTab:Space()
AimBannableTab:Divider()
AimBannableTab:Space()
AimBannableTab:Toggle({
    Title = "Auto Shoot",
    Value = Config.Bannable.AutoShoot,
    Callback = function(state)
        Config.Bannable.AutoShoot = state
        RefreshAutoShoot(); UpdateAutoShootBubble()
        if not IS_LOADING_CONFIG and not SKIP_SAVE then
            Notify("Auto Shoot", state and "Enabled" or "Disabled", state and "crosshair" or "info", 3)
            SaveConfig()
        end
    end,
})
AimBannableTab:Space()
AimBannableTab:Divider()
AimBannableTab:Space()
AimBannableTab:Toggle({
    Title = "FOV",
    Desc = "Only lock enemies inside the circle.",
    Value = Config.Bannable.FOVEnabled,
    Callback = function(state) Config.Bannable.FOVEnabled = state == true; SaveConfig() end,
})
AimBannableTab:Toggle({
    Title = "Visible FOV",
    Desc = "Draw the FOV circle on screen.",
    Value = Config.Bannable.FOVVisible,
    Callback = function(state) Config.Bannable.FOVVisible = state == true; SaveConfig() end,
})
AimBannableTab:Slider({
    Title = "FOV Radius",
    Step = 5,
    Value = { Min=20, Max=600, Default=Config.Bannable.FOVRadius },
    Callback = function(value) Config.Bannable.FOVRadius = value; SaveConfig() end,
})
AimBannableTab:Slider({
    Title = "Hit Chance",
    Desc = "% of your shots Silent Aim takes.",
    Step = 5,
    Value = { Min=0, Max=100, Default=Config.Bannable.HitChance },
    Callback = function(value) Config.Bannable.HitChance = math.clamp(tonumber(value) or 100, 0, 100); SaveConfig() end,
})

local BannableTab = WindWindow:Tab({ Title = "Bannable", Icon = "skull" })

local KillAllToggle = BannableTab:Toggle({
    Title = "Kill All Enemies",
    Value = Config.Bannable.KillAll,
    Callback = function(state)
        if KillAllAlwaysOn and not state then
            task.defer(function() if KillAllAlwaysOn then ToggleKillAll(true); SetToggleValue(KillAllToggle, true) end end)
            return
        end
        ToggleKillAll(state)
        UpdateKillAllBubble()
    end,
})
KillAllToggleRef = KillAllToggle

BannableTab:Toggle({
    Title = "Keep Kill All Always On",
    Desc = "Forces Kill All to stay on.",
    Value = false,
    Callback = function(state)
        KillAllAlwaysOn = state
        if state then
            ToggleKillAll(true)
            SetToggleValue(KillAllToggle, true)
            KillAllWatcherThread()
        end
    end,
})
BannableTab:Space()
BannableTab:Toggle({
    Title = "Kill All Bubble",
    Value = Config.Bubbles.KillAll,
    Callback = function(state) Config.Bubbles.KillAll = state; if KILLALL_BUBBLE then KILLALL_BUBBLE.Visible = state end; SaveConfig() end,
})
BannableTab:Space()
BannableTab:Toggle({
    Title = "Invisible",
    Value = Config.Bannable.Invisible,
    Callback = function(state)
        Config.Bannable.Invisible = state
        RefreshInvisible(); UpdateInvisibleBubble(); SaveConfig()
    end,
})
BannableTab:Toggle({
    Title = "Invisible Bubble",
    Value = Config.Bubbles.Invisible,
    Callback = function(state) Config.Bubbles.Invisible = state; if INVIS_BUBBLE then INVIS_BUBBLE.Visible = state end; SaveConfig() end,
})
BannableTab:Space()
BannableTab:Toggle({
    Title = "Desync",
    Value = Config.Bannable.Desync,
    Callback = function(state)
        Config.Bannable.Desync = state
        RefreshDesync(); UpdateDesyncBubble(); SaveConfig()
    end,
})
BannableTab:Toggle({
    Title = "Desync Bubble",
    Value = Config.Bubbles.Desync,
    Callback = function(state) Config.Bubbles.Desync = state; if DESYNC_BUBBLE then DESYNC_BUBBLE.Visible = state end; SaveConfig() end,
})
BannableTab:Space()
BannableTab:Toggle({
    Title = "Silent Aim Bubble",
    Value = Config.Bubbles.SilentAim,
    Callback = function(state) Config.Bubbles.SilentAim = state; if SILENT_BUBBLE then SILENT_BUBBLE.Visible = state end; SaveConfig() end,
})
BannableTab:Toggle({
    Title = "Auto Shoot Bubble",
    Value = Config.Bubbles.AutoShoot,
    Callback = function(state) Config.Bubbles.AutoShoot = state; if AUTOSHOOT_BUBBLE then AUTOSHOOT_BUBBLE.Visible = state end; SaveConfig() end,
})
BannableTab:Space()
BannableTab:Divider()
BannableTab:Space()
BannableTab:Toggle({
    Title = "Floating Floor",
    Value = Config.FloatingFloor.Enabled,
    Callback = function(state) Config.FloatingFloor.Enabled = state; RefreshFloatingFloor(); SaveConfig() end,
})
BannableTab:Toggle({
    Title = "Hide Map",
    Value = Config.FloatingFloor.HideMap,
    Callback = function(state) Config.FloatingFloor.HideMap = state; RefreshFloatingFloor(); SaveConfig() end,
})

local ESPTab = WindWindow:Tab({ Title = "ESP", Icon = "eye" })

ESPTab:Toggle({
    Title = "Enable ESP",
    Desc = "Show enemies through walls.",
    Value = Config.ESP.Enabled,
    Callback = function(state)
        Config.ESP.Enabled = state
        RefreshESP()
        if not IS_LOADING_CONFIG and not SKIP_SAVE then
            Notify("ESP", state and "Enabled" or "Disabled", "scan-eye", 3)
        end
    end,
})
ESPTab:Toggle({
    Title = "Show Enemy Name",
    Value = Config.ESP.ShowName,
    Callback = function(state)
        Config.ESP.ShowName = state
        if Config.ESP.Enabled then ESPInstance:RefreshAll() end
        SaveConfig()
    end,
})
ESPTab:Toggle({
    Title = "ESP Lines",
    Desc = "Draw lines from your character to enemy positions.",
    Value = Config.ESP.Lines,
    Callback = function(state) Config.ESP.Lines = state; RefreshESPLines(); SaveConfig() end,
})
ESPTab:Colorpicker({
    Title = "ESP Color",
    Default = Config.ESP.Color,
    Transparency = 0,
    Callback = function(color)
        Config.ESP.Color = ToColor3(color, Config.ESP.Color)
        if Config.ESP.Enabled then ESPInstance:RefreshAll() end
        SaveConfig()
    end,
})
ESPTab:Colorpicker({
    Title = "ESP Lines Color",
    Default = Config.ESP.LinesColor,
    Transparency = 0,
    Callback = function(color) Config.ESP.LinesColor = ToColor3(color, Config.ESP.LinesColor); SaveConfig() end,
})

local HitboxTab = WindWindow:Tab({ Title = "Hitbox", Icon = "box" })

HitboxTab:Toggle({
    Title = "Enable Hitbox",
    Desc = "Show and expand enemy hitboxes.",
    Value = Config.Hitbox.Enabled,
    Callback = function(state)
        Config.Hitbox.Enabled = state
        if state then HitboxInstance:Start(); HitboxInstance:Refresh() else HitboxInstance:Stop() end
        if not IS_LOADING_CONFIG and not SKIP_SAVE then
            Notify("Hitbox", state and "Enabled" or "Disabled", "box", 3)
        end
    end,
})
HitboxTab:Slider({
    Title = "Hitbox Size",
    Step = 1,
    Value = { Min=1, Max=50, Default=Config.Hitbox.Size },
    Callback = function(value) Config.Hitbox.Size = value; if Config.Hitbox.Enabled then HitboxInstance:Refresh() end; SaveConfig() end,
})
HitboxTab:Colorpicker({
    Title = "Hitbox Color",
    Default = Config.Hitbox.Color,
    Transparency = 0,
    Callback = function(color) Config.Hitbox.Color = ToColor3(color, Config.Hitbox.Color); if Config.Hitbox.Enabled then HitboxInstance:Refresh() end; SaveConfig() end,
})
HitboxTab:Slider({
    Title = "Hitbox Opacity",
    Step = 0.5,
    Value = { Min=0, Max=10, Default=Config.Hitbox.Opacity },
    Callback = function(value) Config.Hitbox.Opacity = value; if Config.Hitbox.Enabled then HitboxInstance:Refresh() end; SaveConfig() end,
})
HitboxTab:Toggle({
    Title = "Show Hitbox",
    Value = Config.Hitbox.Show,
    Callback = function(state) Config.Hitbox.Show = state; if Config.Hitbox.Enabled then HitboxInstance:Refresh() end; SaveConfig() end,
})

local EventsTab = WindWindow:Tab({ Title = "Events & Boxes", Icon = "gift" })

EventsTab:Toggle({
    Title = "Event Farm",
    Desc = "Automatically collects event drops.",
    Value = Config.AutoTeleport.EventFarm,
    Callback = function(state) Config.AutoTeleport.EventFarm = state; RefreshEventFarm(); SaveConfig() end,
})
EventsTab:Space(); EventsTab:Divider(); EventsTab:Space()
EventsTab:Dropdown({
    Title = "Selected Box",
    Desc = "Choose which box to buy.",
    Values = BOX_LIST,
    Value = Config.Boxes.Selected,
    Callback = function(value) SetSelectedBox(value); SaveConfig() end,
})
EventsTab:Button({
    Title = "Buy Box",
    Desc = "Buys the selected box.",
    Callback = function()
        local ok, reason = BoxBuyerInstance:Purchase()
        if ok then Notify("Boxes", "Bought " .. tostring(Config.Boxes.Selected), "package", 3)
        elseif reason == "missing_remote" then Notify("Boxes", "BuyCase remote not found.", "alert-triangle", 3)
        else Notify("Boxes", "Could not buy the box.", "alert-triangle", 3) end
    end,
})
EventsTab:Toggle({
    Title = "Auto Buy",
    Desc = "Automatically buys the selected box.",
    Value = Config.Boxes.AutoBuy,
    Callback = function(state) Config.Boxes.AutoBuy = state; RefreshBoxBuyer(); SaveConfig() end,
})

local TeleportTab = WindWindow:Tab({ Title = "Auto Teleport", Icon = "repeat" })

local AutoTeleportMainToggle = TeleportTab:Toggle({
    Title = "Auto Teleport Main",
    Value = Config.AutoTeleport.Main,
    Callback = function(state)
        Config.AutoTeleport.Main = state
        if state then
            Config.AutoTeleport.Alt = false
            if AutoTeleportAltToggle then AutoTeleportAltToggle:Set(false) end
        end
        RefreshAutoTeleport()
    end,
})
local AutoTeleportAltToggle = TeleportTab:Toggle({
    Title = "Auto Teleport Alt",
    Value = Config.AutoTeleport.Alt,
    Callback = function(state)
        Config.AutoTeleport.Alt = state
        if state then
            Config.AutoTeleport.Main = false
            if AutoTeleportMainToggle then AutoTeleportMainToggle:Set(false) end
        end
        RefreshAutoTeleport()
    end,
})
TeleportTab:Dropdown({
    Title = "Duel Type",
    Values = { "1v1", "2v2", "3v3", "4v4" },
    Value = Config.AutoTeleport.DuelType,
    Callback = function(value)
        Config.AutoTeleport.DuelType = PAD_TABLE["Right Platforms"][value] and value or "1v1"
        RefreshAutoTeleport(); SaveConfig()
    end,
})
TeleportTab:Dropdown({
    Title = "Platform Row",
    Values = PLATFORM_ROWS,
    Value = Config.AutoTeleport.PlatformRow,
    Callback = function(value)
        Config.AutoTeleport.PlatformRow = PAD_TABLE[value] and value or "Right Platforms"
        RefreshAutoTeleport(); SaveConfig()
    end,
})
TeleportTab:Space()
TeleportTab:Toggle({
    Title = "Break Streak",
    Value = Config.AutoTeleport.BreakStreak,
    Callback = function(state) Config.AutoTeleport.BreakStreak = state; SaveConfig() end,
})
TeleportTab:Slider({
    Title = "Break Streak Target",
    Step = 1,
    Value = { Min=0, Max=500, Default=Config.AutoTeleport.BreakStreakTarget or 1 },
    Callback = function(value) Config.AutoTeleport.BreakStreakTarget = math.floor(tonumber(value) or 1); SaveConfig() end,
})
TeleportTab:Space()
TeleportTab:Toggle({
    Title = "Lower KD",
    Value = Config.AutoTeleport.LowerKD,
    Callback = function(state) Config.AutoTeleport.LowerKD = state; SaveConfig() end,
})
TeleportTab:Slider({
    Title = "KD Target Kills",
    Step = 1,
    Value = { Min=0, Max=4, Default=Config.AutoTeleport.KDTargetKills or 4 },
    Callback = function(value) Config.AutoTeleport.KDTargetKills = math.clamp(math.floor(tonumber(value) or 4), 0, 4); SaveConfig() end,
})

local EXTERNAL_EMOTES_URL = "https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua"
local EXTERNAL_EMOTES_COPY = string.format('loadstring(game:HttpGet("%s"))()', EXTERNAL_EMOTES_URL)

local function RunScript(label, url)
    task.spawn(function()
        local ok, err = pcall(function()
            if type(loadstring) ~= "function" then error("loadstring unavailable") end
            local src = game:HttpGet(url)
            local fn = loadstring(src)
            if type(fn) ~= "function" then error("invalid script chunk") end
            fn()
        end)
        if ok then Notify(label, "Script launched.", "check", 3)
        else Notify(label, "Could not run the script. " .. tostring(err), "alert-triangle", 4) end
    end)
end

local ExternalTab = WindWindow:Tab({ Title = "External Scripts", Icon = "link" })
ExternalTab:Button({
    Title = "EMOTES",
    Desc = "Opens the external emotes menu.",
    Callback = function()
        RunScript("EMOTES", EXTERNAL_EMOTES_URL)
    end,
})
ExternalTab:Button({
    Title = "COPY SCRIPT",
    Callback = function()
        pcall(function() setclipboard(EXTERNAL_EMOTES_COPY) end)
        Notify("EMOTES", "Script copied.", "copy", 3)
    end,
})
ExternalTab:Toggle({
    Title = "Auto Execute Emotes",
    Desc = "Runs Emotes automatically after startup.",
    Value = Config.Emotes.AutoExecute,
    Callback = function(state) Config.Emotes.AutoExecute = state == true; SaveConfig() end,
})
ExternalTab:Button({
    Title = "Mercado",
    Desc = "Opens the trading market.",
    Callback = function()
        RunScript("Mercado", "https://api.jnkie.com/api/v1/luascripts/public/3250ed34632dcc6a6dd7974806ae6d38b263e93d585e365e14be069ff2cdc9ee/download")
    end,
})

--=================================================================
-- INICIALIZACION
--=================================================================
task.defer(function()
    Notify("DEOBFBYSZK", "Loaded! Made by SZK - discord.gg/f4JfyAFCN", "sparkles", 5)
end)

pcall(function()
    getgenv()[UNLOAD_KEY] = function()
        IS_UNLOADING = true
        KillAllAlwaysOn = false
        KILLALL_WATCHER_GEN = KILLALL_WATCHER_GEN + 1

        Config.AutoTeleport.Main = false
        Config.AutoTeleport.Alt = false
        Config.AutoTeleport.EventFarm = false
        Config.Bannable.AimFollow = false
        Config.Bannable.Triggerbot = false
        Config.Bannable.SilentAim = false
        Config.Bannable.AutoShoot = false
        Config.Bannable.Macro = false
        Config.Bannable.KillAll = false
        Config.Bannable.Invisible = false
        Config.Bannable.Desync = false
        Config.PlayerCheats.JumpPowerEnabled = false
        Config.PlayerCheats.InfiniteJump = false
        Config.PlayerCheats.SpeedEnabled = false
        Config.ESP.Enabled = false
        Config.ESP.Lines = false
        Config.Hitbox.Enabled = false
        Config.Boxes.AutoBuy = false
        Config.FloatingFloor.Enabled = false
        Config.FloatingFloor.HideMap = false

        local function safeCall(obj, method)
            if not obj then return end
            pcall(function()
                local fn = obj[method]
                if type(fn) == "function" then fn(obj) end
            end)
        end
        safeCall(AutoTeleportMainInstance, "Stop")
        safeCall(AutoTeleportAltInstance, "Stop")
        safeCall(TriggerbotInstance, "Stop")
        safeCall(MacroInstance, "Stop")
        safeCall(AutoShootInstance, "Stop")
        safeCall(AimFollowInstance, "Stop")
        safeCall(KillAllInstance, "Stop")
        safeCall(InvisibleInstance, "Stop")
        safeCall(DesyncInstance, "Stop")
        safeCall(EventFarmInstance, "Stop")
        safeCall(ESPInstance, "Stop")
        safeCall(ESPLinesInstance, "Stop")
        safeCall(HitboxInstance, "Stop")
        safeCall(JumpPowerInstance, "Stop")
        safeCall(SpeedInstance, "Stop")
        safeCall(FloatingFloorInstance, "Destroy")
        safeCall(BoxBuyerInstance, "Stop")
        safeCall(FOVInstance, "Destroy")
        safeCall(SilentAim, "Stop")
        SilentAim:RemoveHook()

        if KILLALL_BUBBLE then KILLALL_BUBBLE:Destroy() end
        if SILENT_BUBBLE then SILENT_BUBBLE:Destroy() end
        if AUTOSHOOT_BUBBLE then AUTOSHOOT_BUBBLE:Destroy() end
        if INVIS_BUBBLE then INVIS_BUBBLE:Destroy() end
        if DESYNC_BUBBLE then DESYNC_BUBBLE:Destroy() end

        if CONFIG_AUTOSAVE_CONN then pcall(function() CONFIG_AUTOSAVE_CONN:Disconnect() end); CONFIG_AUTOSAVE_CONN = nil end

        pcall(function() WindWindow:Destroy() end)
    end
end)

task.delay(3, function()
    if IS_UNLOADING or not Config.Emotes.AutoExecute then return end
    RunScript("EMOTES", EXTERNAL_EMOTES_URL)
end)

SKIP_SAVE = false

--=================================================================
-- FIN - DEOBFBYSZK - Made by SZK
-- Discord: https://discord.gg/f4JfyAFCN
--=================================================================