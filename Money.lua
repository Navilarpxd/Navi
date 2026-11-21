--[[ NAVI MONEY · un botón ]]

if getgenv().NaviMoneyCleanup then
	pcall(getgenv().NaviMoneyCleanup)
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local C = {
	bg = Color3.fromRGB(24, 3, 6),
	panel = Color3.fromRGB(19, 2, 4),
	stroke = Color3.fromRGB(158, 18, 30),
	accent = Color3.fromRGB(228, 30, 44),
	text = Color3.fromRGB(244, 236, 236),
	dim = Color3.fromRGB(176, 122, 128),
	ok = Color3.fromRGB(90, 220, 130),
}
local FB = Enum.Font.GothamBold
local FM = Enum.Font.GothamMedium
local FR = Enum.Font.Gotham

local function new(class, props, parent)
	local i = Instance.new(class)
	local par = parent
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				par = v
			else
				i[k] = v
			end
		end
	end
	if par then
		i.Parent = par
	end
	return i
end

local function tw(o, d, p)
	TweenService:Create(o, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

local gui = new("ScreenGui", {
	Name = "NaviMoney",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
if gethui then
	pcall(function()
		gui.Parent = gethui()
	end)
end
if not gui.Parent then
	gui.Parent = LP:WaitForChild("PlayerGui")
end

local main = new("Frame", {
	Size = UDim2.fromOffset(330, 250),
	Position = UDim2.fromScale(0.5, 0.4),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = C.bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, main)
new("UIStroke", { Color = C.stroke, Thickness = 1.5, Transparency = 0.1 }, main)
new("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(70, 7, 12), C.bg),
	Rotation = 90,
	Transparency = NumberSequence.new(0.1, 0.3),
}, main)

local header = new("Frame", {
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
}, main)
new("UIStroke", { Color = C.stroke, Transparency = 0.5 }, header)

new("TextLabel", {
	Size = UDim2.fromOffset(200, 20),
	Position = UDim2.fromOffset(14, 12),
	BackgroundTransparency = 1,
	Font = FB,
	TextSize = 14,
	TextColor3 = C.accent,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "NAVI MONEY",
}, header)

local minBtn = new("TextButton", {
	Size = UDim2.fromOffset(24, 24),
	Position = UDim2.new(1, -32, 0, 9),
	BackgroundTransparency = 1,
	Font = FB,
	TextSize = 17,
	TextColor3 = C.dim,
	Text = "–",
}, header)

local reopen = new("TextButton", {
	Size = UDim2.fromOffset(44, 44),
	Position = UDim2.fromOffset(24, 190),
	BackgroundColor3 = C.accent,
	BorderSizePixel = 0,
	Font = FB,
	TextSize = 20,
	TextColor3 = C.text,
	Text = "$",
	Visible = false,
	AutoButtonColor = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, reopen)

local function minimizar()
	main.Visible = false
	reopen.Visible = true
end

minBtn.MouseButton1Click:Connect(minimizar)
reopen.MouseButton1Click:Connect(function()
	main.Visible = true
	reopen.Visible = false
end)

do
	local arr = false
	local ini, iniPos
	reopen.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			arr = true
			ini = i.Position
			iniPos = reopen.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not arr then
			return
		end
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			local d = i.Position - ini
			reopen.Position = UDim2.new(iniPos.X.Scale, iniPos.X.Offset + d.X, iniPos.Y.Scale, iniPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function()
		arr = false
	end)
end

do
	local arr = false
	local ini, iniPos
	header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			arr = true
			ini = i.Position
			iniPos = main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not arr then
			return
		end
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			local d = i.Position - ini
			main.Position = UDim2.new(iniPos.X.Scale, iniPos.X.Offset + d.X, iniPos.Y.Scale, iniPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function()
		arr = false
	end)
end

local log = new("ScrollingFrame", {
	Size = UDim2.new(1, -20, 1, -140),
	Position = UDim2.fromOffset(10, 50),
	BackgroundColor3 = Color3.fromRGB(10, 1, 2),
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = C.accent,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
new("UICorner", { CornerRadius = UDim.new(0, 7) }, log)
new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, log)
new("UIPadding", {
	PaddingTop = UDim.new(0, 6),
	PaddingLeft = UDim.new(0, 7),
	PaddingRight = UDim.new(0, 7),
	PaddingBottom = UDim.new(0, 6),
}, log)

local function escribir(texto, color)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = FR,
		TextSize = 11,
		TextColor3 = color or C.dim,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = texto,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, log)
end

local CLAVES = { "coin", "cash", "money", "gem", "egg", "token", "buck", "dollar", "credit", "gold", "dinero", "moneda", "saldo", "wallet", "balance" }

local function esMoneda(nombre)
	local n = string.lower(tostring(nombre))
	for _, k in ipairs(CLAVES) do
		if string.find(n, k, 1, true) then
			return true
		end
	end
	return false
end

local TOPE = 999999999
local activo = false
local originales = {}
local vigilados = {}

local function escanear()
	local lista = {}
	local ls = LP:FindFirstChild("leaderstats")
	if ls then
		for _, v in ipairs(ls:GetChildren()) do
			if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
				if esMoneda(v.Name) then
					lista[#lista + 1] = v
				end
			end
		end
	end
	for _, v in ipairs(LP:GetChildren()) do
		if (v:IsA("IntValue") or v:IsA("NumberValue")) and esMoneda(v.Name) then
			lista[#lista + 1] = v
		end
	end
	for nombre, valor in pairs(LP:GetAttributes()) do
		if type(valor) == "number" and esMoneda(nombre) then
			lista[#lista + 1] = { atributo = nombre }
		end
	end
	return lista
end

local function escribirValor(entrada, valor)
	if typeof(entrada) == "Instance" then
		if entrada:IsA("StringValue") then
			entrada.Value = tostring(valor)
		else
			entrada.Value = valor
		end
	elseif type(entrada) == "table" and entrada.atributo then
		LP:SetAttribute(entrada.atributo, valor)
	end
end

local function leerValor(entrada)
	if typeof(entrada) == "Instance" then
		return tonumber(entrada.Value) or 0
	elseif type(entrada) == "table" and entrada.atributo then
		return tonumber(LP:GetAttribute(entrada.atributo)) or 0
	end
	return 0
end

local function etiqueta(entrada)
	if typeof(entrada) == "Instance" then
		return entrada:GetFullName()
	elseif type(entrada) == "table" then
		return "atributo:" .. entrada.atributo
	end
	return "?"
end

local hilo
local function detener()
	if hilo then
		task.cancel(hilo)
		hilo = nil
	end
end

local function restaurar()
	detener()
	for entrada, valor in pairs(originales) do
		pcall(function()
			escribirValor(entrada, valor)
		end)
	end
	originales = {}
	activo = false
	escribir("Restaurado a los valores originales.", C.dim)
end

local function activar()
	local lista = escanear()
	if #lista == 0 then
		escribir("No encontré ninguna moneda. Espera a estar dentro de la partida y reintenta.", C.accent)
		return
	end

	originales = {}
	for _, entrada in ipairs(lista) do
		originales[entrada] = leerValor(entrada)
		escribir("Encontrado: " .. etiqueta(entrada) .. " = " .. tostring(originales[entrada]), C.ok)
		pcall(function()
			escribirValor(entrada, TOPE)
		end)

		if typeof(entrada) == "Instance" and not vigilados[entrada] then
			vigilados[entrada] = true
			entrada.Changed:Connect(function()
				if not activo then
					return
				end
				if leerValor(entrada) < TOPE then
					pcall(function()
						escribirValor(entrada, TOPE)
					end)
				end
			end)
		end
	end

	activo = true
	detener()
	hilo = task.spawn(function()
		while activo do
			task.wait(0.15)
			for entrada in pairs(originales) do
				if leerValor(entrada) < TOPE then
					pcall(function()
						escribirValor(entrada, TOPE)
					end)
				end
			end
		end
	end)

	escribir("Valores fijados en " .. TOPE .. ". Abre la tienda e intenta comprar.", C.ok)
end

local boton = new("TextButton", {
	Size = UDim2.new(1, -20, 0, 38),
	Position = UDim2.new(0, 10, 1, -48),
	BackgroundColor3 = C.accent,
	BorderSizePixel = 0,
	Font = FB,
	TextSize = 14,
	TextColor3 = C.text,
	Text = "DINERO INFINITO",
	AutoButtonColor = false,
}, main)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, boton)

boton.MouseButton1Click:Connect(function()
	if activo then
		restaurar()
		boton.Text = "DINERO INFINITO"
		tw(boton, 0.12, { BackgroundTransparency = 0 })
	else
		activar()
		if activo then
			boton.Text = "RESTAURAR"
			tw(boton, 0.12, { BackgroundTransparency = 0.25 })
		end
	end
end)

getgenv().NaviMoneyCleanup = function()
	activo = false
	detener()
	gui:Destroy()
end

escribir("Pulsa el botón. Escanea leaderstats, valores y atributos de tu personaje.", C.dim)