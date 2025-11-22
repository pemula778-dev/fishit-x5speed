# fishit-x5speed
--====================================================--
--==          FISHING SYSTEM v3 + AUTO FISHING      ==--
--==      + Auto Sell + Auto TP + Anti AFK          ==--
--====================================================--

-- SERVICES
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local StarterPack = game:GetService("StarterPack")
local RunService = game:GetService("RunService")

-- REMOTES
local StartRemote = ReplicatedStorage:WaitForChild("FishingStart")
local ReelRemote = ReplicatedStorage:WaitForChild("FishingReel")
local NotifyRemote = ReplicatedStorage:WaitForChild("FishingNotify")
local SellEvent = ReplicatedStorage:FindFirstChild("SellFish") -- Auto sell

-- DEV SETTINGS
local DEV = {
	autoFish = true,
	autoPerfection = true,
	speedMultiplier = 1.0,
	instantCatch = true,
	superFast = 0,
	delayMode = 1.0,
	autoEquipRadar = true,
	animationEnabled = false
}

-- VARIABLES
local isFishing = false
local startTick = 0
local biteTick = nil
local CurrentRod = nil
local AutoFish_Enabled = false
getgenv().AutoSell = false

--------------------------------------------------------
--                   UTILITY FUNCTIONS
--------------------------------------------------------

local function setStatus(text)
	if _G.FishingStatusLabel then
		_G.FishingStatusLabel.Text = text
	end
end

local function setProgress(p)
	p = math.clamp(p or 0, 0, 1)
	if _G.FishingProgressBar then
		_G.FishingProgressBar.Size = UDim2.new(p,0,1,0)
	end
end

-- Equip radar function
local function tryAutoEquipRadar()
	if not DEV.autoEquipRadar then return end
	local backpack = Player:FindFirstChild("Backpack")
	if not backpack then return end
	local tool = backpack:FindFirstChild("FishingRadar") or StarterPack:FindFirstChild("FishingRadar")
	if tool and not Player.Character:FindFirstChild(tool.Name) then
		local clone = tool:Clone()
		clone.Parent = backpack
		local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:EquipTool(clone) end
	end
end

-- Get fishing rod
local function GetRod()
	local backpack = Player:FindFirstChild("Backpack")
	local char = Player.Character
	if char then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then return tool end
	end
	return backpack and backpack:FindFirstChildOfClass("Tool")
end

-- Cast rod
local function CastRod()
	if CurrentRod and CurrentRod:FindFirstChild("Events") then
		local ev = CurrentRod.Events:FindFirstChild("Cast")
		if ev then pcall(function() ev:FireServer(); isFishing = true end) end
	end
end

-- Reel fish
local function ReelFish()
	if CurrentRod and CurrentRod:FindFirstChild("Events") then
		local ev = CurrentRod.Events:FindFirstChild("Reel")
		if ev then pcall(function() ev:FireServer() end) end
	end
end

-- Instant progress
local function InstantProgress()
	local gui = Player.PlayerGui:FindFirstChild("ProgressFrame")
	if gui and gui:FindFirstChild("Bar") then
		pcall(function() gui.Bar.Size = UDim2.new(1,0,1,0) end)
	end
end

--------------------------------------------------------
--                     AUTO FISH LOOP
--------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(0.25)
		if not AutoFish_Enabled then isFishing = false; continue end
		CurrentRod = GetRod()
		if not CurrentRod then isFishing = false; continue end
		-- Auto cast
		if not isFishing then
			CastRod()
			task.wait(0.7)
		end
		-- Auto reel saat bite
		if CurrentRod:FindFirstChild("Bite") then
			ReelFish()
			task.wait(0.3)
			InstantProgress()
			task.wait(0.3)
			isFishing = false
		end
	end
end)

--------------------------------------------------------
--                     AUTO SELL LOOP
--------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)
		if getgenv().AutoSell and SellEvent then
			pcall(function() SellEvent:FireServer() end)
		end
	end
end)

--------------------------------------------------------
--                   ANTI AFK (NO KICK)
--------------------------------------------------------
local vu = game:GetService("VirtualUser")
Player.Idled:Connect(function()
	vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

--------------------------------------------------------
--             FISHING SPOTS TELEPORT
--------------------------------------------------------
local FishingSpots = {
	["Starter Island"] = CFrame.new(23.4, 4.6, 2868.3),
	["Kohana Fishing"] = CFrame.new(-759.09, 24.30, 429.12),
	["Coral Reefs"] = CFrame.new(-3222.68, 9.97, 1898.06),
	["The Depths"] = CFrame.new(3239.96, -1298.21, 1353.69),
	["Volcano"] = CFrame.new(-606.58, 59.0, 105.82)
}

--------------------------------------------------------
--                   GUI SETUP
--------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", Player.PlayerGui)

-- Auto Fish Button
local AutoFishButton = Instance.new("TextButton", ScreenGui)
AutoFishButton.Size = UDim2.new(0,150,0,50)
AutoFishButton.Position = UDim2.new(0.05,0,0.75,0)
AutoFishButton.BackgroundColor3 = Color3.fromRGB(25,25,25)
AutoFishButton.TextColor3 = Color3.fromRGB(255,255,255)
AutoFishButton.Text = "AUTO FISH: OFF"
AutoFishButton.Font = Enum.Font.GothamBold
AutoFishButton.TextScaled = true
AutoFishButton.BorderSizePixel = 0
AutoFishButton.MouseButton1Click:Connect(function()
	AutoFish_Enabled = not AutoFish_Enabled
	AutoFishButton.Text = AutoFish_Enabled and "AUTO FISH: ON" or "AUTO FISH: OFF"
	AutoFishButton.BackgroundColor3 = AutoFish_Enabled and Color3.fromRGB(0,170,50) or Color3.fromRGB(25,25,25)
end)

-- Auto Sell Button
local SellButton = Instance.new("TextButton", ScreenGui)
SellButton.Size = UDim2.new(0,180,0,50)
SellButton.Position = UDim2.new(0.8,0,0.15,0)
SellButton.BackgroundColor3 = Color3.fromRGB(25,25,25)
SellButton.TextColor3 = Color3.fromRGB(255,255,255)
SellButton.Text = "AUTO SELL: OFF"
SellButton.Font = Enum.Font.GothamBold
SellButton.TextScaled = true
SellButton.BorderSizePixel = 0
SellButton.MouseButton1Click:Connect(function()
	getgenv().AutoSell = not getgenv().AutoSell
	SellButton.Text = getgenv().AutoSell and "AUTO SELL: ON" or "AUTO SELL: OFF"
	SellButton.BackgroundColor3 = getgenv().AutoSell and Color3.fromRGB(0,150,0) or Color3.fromRGB(25,25,25)
end)

-- Fishing Spot Buttons
local SpotFrame = Instance.new("Frame", ScreenGui)
SpotFrame.Size = UDim2.new(0,180,0,#FishingSpots*40)
SpotFrame.Position = UDim2.new(0.8,0,0.3,0)
SpotFrame.BackgroundTransparency = 0.25
SpotFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
SpotFrame.BorderSizePixel = 0
local UIList = Instance.new("UIListLayout", SpotFrame)
UIList.Padding = UDim.new(0,4)

for spotName, cf in pairs(FishingSpots) do
	local b = Instance.new("TextButton", SpotFrame)
	b.Size = UDim2.new(1,0,0,35)
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)
	b.TextColor3 = Color3.new(1,1,1)
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.Text = "TP: "..spotName
	b.BorderSizePixel = 0
	b.MouseButton1Click:Connect(function()
		pcall(function() Player.Character.HumanoidRootPart.CFrame = cf end)
	end)
end

print("🎣 Fishing System v3 (Full) Loaded Successfully!")
