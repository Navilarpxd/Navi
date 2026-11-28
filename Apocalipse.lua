--[[
    Survive the Apocalypse - Loot Bringer + Full Logger
    By Navi
]]

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local function getChar()
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    return char, hrp
end

-- ==================== UI ====================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Survive Apocalypse | Loot",
    Author = "By Navi",
    Folder = "SurviveApocalypse",
    Size = UDim2.fromOffset(520, 500),
    Transparent = false,
    Theme = "Dark",
})

local Main = Window:Tab({ Title = "Main", Icon = "box" })
local Logger = Window:Tab({ Title = "Logger", Icon = "list" })
local Settings = Window:Tab({ Title = "Settings", Icon = "settings" })

local function notify(title, text)
    pcall(function()
        WindUI:Notify({
            Title = title or "Survive",
            Content = text or "",
            Duration = 2.5
        })
    end)
end

-- Nombres reales del juego (de tu scan)
local lootKeywords = {
    "trunk", "crate", "box", "cardboard", "beans", "fuel",
    "generator", "tray", "workbench", "ammo", "med", "food",
    "loot", "supply", "bag", "backpack", "case", "chest"
}

local function isLoot(obj)
    if not obj then return false end
    local name = string.lower(obj.Name)
    for _, key in ipairs(lootKeywords) do
        if string.find(name, key) then
            return true
        end
    end
    return false
end

local function getPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

-- ==================== MAIN - TRAER LOOT ====================
Main:Section({ Title = "Loot Bringer", Icon = "zap", Opened = true })

local bringRadius = 8
local statusLabel = Main:Paragraph({
    Title = "Estado",
    Desc = "Listo. Presiona el botón para traer el loot."
})

Main:Slider({
    Title = "Radio alrededor tuyo",
    Value = { Min = 3, Max = 20, Default = 8 },
    Callback = function(v) bringRadius = v end
})

Main:Button({
    Title = "TRAER TODO EL LOOT AQUÍ",
    Icon = "package",
    Callback = function()
        local char, hrp = getChar()
        if not hrp then
            notify("Error", "No se encontró tu personaje")
            return
        end

        local brought = 0
        local myPos = hrp.Position

        for _, obj in ipairs(workspace:GetDescendants()) do
            if isLoot(obj) then
                local part = getPart(obj)
                if part and part:IsA("BasePart") then
                    if not part:IsDescendantOf(char) then
                        local offset = Vector3.new(
                            math.random(-bringRadius, bringRadius),
                            math.random(1, 4),
                            math.random(-bringRadius, bringRadius)
                        )
                        pcall(function()
                            if obj:IsA("Model") and obj.PrimaryPart then
                                obj:PivotTo(CFrame.new(myPos + offset))
                            else
                                part.CFrame = CFrame.new(myPos + offset)
                                part.Anchored = false
                            end
                            brought = brought + 1
                        end)
                    end
                end
            end
        end

        local dropped = workspace:FindFirstChild("DroppedItems")
        if dropped then
            for _, obj in ipairs(dropped:GetDescendants()) do
                local part = getPart(obj)
                if part and part:IsA("BasePart") then
                    local offset = Vector3.new(
                        math.random(-bringRadius, bringRadius),
                        math.random(1, 3),
                        math.random(-bringRadius, bringRadius)
                    )
                    pcall(function()
                        part.CFrame = CFrame.new(myPos + offset)
                        brought = brought + 1
                    end)
                end
            end
        end

        pcall(function()
            statusLabel:SetDesc("Traídos: " .. brought .. " objetos cerca de ti")
        end)
        notify("Loot Bringer", "Se trajeron " .. brought .. " objetos")
    end
})

Main:Button({
    Title = "TRAER SOLO CRATES / TRUNKS / BOX",
    Icon = "box",
    Callback = function()
        local char, hrp = getChar()
        if not hrp then return end

        local keywords = {"trunk", "crate", "box", "cardboard"}
        local brought = 0
        local myPos = hrp.Position

        for _, obj in ipairs(workspace:GetDescendants()) do
            local name = string.lower(obj.Name)
            local match = false
            for _, k in ipairs(keywords) do
                if string.find(name, k) then match = true break end
            end
            if match then
                local part = getPart(obj)
                if part and not part:IsDescendantOf(char) then
                    local offset = Vector3.new(
                        math.random(-bringRadius, bringRadius),
                        2,
                        math.random(-bringRadius, bringRadius)
                    )
                    pcall(function()
                        if obj:IsA("Model") then
                            obj:PivotTo(CFrame.new(myPos + offset))
                        else
                            part.CFrame = CFrame.new(myPos + offset)
                        end
                        brought = brought + 1
                    end)
                end
            end
        end

        pcall(function()
            statusLabel:SetDesc("Crates/Trunks/Box traídos: " .. brought)
        end)
        notify("Loot", "Cajas traídas: " .. brought)
    end
})

Main:Paragraph({
    Title = "Info",
    Desc = "El botón principal trae Trunk, Crate, Box, Cardboard Box, Beans, Fuel, etc. hacia donde estás. Luego solo recógelos."
})

-- ==================== LOGGER COMPLETO ====================
Logger:Section({ Title = "Object Logger", Icon = "search", Opened = true })

local resultsLabel = Logger:Paragraph({
    Title = "Resultados",
    Desc = "Presiona ESCANEAR para ver todos los objetos aquí."
})

Logger:Button({
    Title = "ESCANEAR TODO (LOOT)",
    Icon = "search",
    Callback = function()
        local char, hrp = getChar()
        local list = {}

        for _, obj in ipairs(workspace:GetDescendants()) do
            if isLoot(obj) then
                local part = getPart(obj)
                if part then
                    local dist = hrp and (part.Position - hrp.Position).Magnitude or 0
                    table.insert(list, {
                        name = obj.Name,
                        full = obj:GetFullName(),
                        dist = dist,
                        class = obj.ClassName
                    })
                end
            end
        end

        table.sort(list, function(a, b) return a.dist < b.dist end)

        local text = "Total loot: " .. #list .. "\n\n"
        local maxShow = math.min(#list, 80)
        for i = 1, maxShow do
            local c = list[i]
            text = text .. string.format("%d. %s  (%.0fm)\n", i, c.name, c.dist)
        end
        if #list > maxShow then
            text = text .. "\n... +" .. (#list - maxShow) .. " más"
        end

        pcall(function()
            resultsLabel:SetDesc(text)
        end)

        print("========== LOOT LOG ==========")
        for i, c in ipairs(list) do
            print(string.format("[%d] %s | %.1fm | %s", i, c.full, c.dist, c.class))
        end
        print("Total: " .. #list)

        notify("Logger", "Loot encontrados: " .. #list)
    end
})

Logger:Button({
    Title = "LISTAR WORKSPACE",
    Callback = function()
        local text = "Workspace:\n\n"
        local count = 0
        for _, obj in ipairs(workspace:GetChildren()) do
            count = count + 1
            text = text .. count .. ". " .. obj.Name .. " (" .. obj.ClassName .. ")\n"
            print(count .. " | " .. obj.Name .. " (" .. obj.ClassName .. ")")
        end
        pcall(function()
            resultsLabel:SetDesc(text)
        end)
        notify("Logger", "Modelos: " .. count)
    end
})

-- ==================== SETTINGS ====================
Settings:Section({ Title = "Extra" })

Settings:Button({
    Title = "REJOIN",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end
})

Settings:Button({
    Title = "SERVER HOP",
    Callback = function()
        local Http = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local ok, res = pcall(function()
            return Http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if ok and res and res.data then
            for _, s in ipairs(res.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TPS:TeleportToPlaceInstance(game.PlaceId, s.id)
                    return
                end
            end
        end
        TPS:Teleport(game.PlaceId)
    end
})

notify("Survive Apocalypse", "Loot Bringer cargado")
print("[Survive Apocalypse] Loot Bringer listo - By Navi")
