local SCRIPT_ID = "BloxFruits_MegaFarm_Overdrive"

pcall(function()
	local targetFolder = game:GetService("CoreGui")
	if not targetFolder then
		targetFolder = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
	end
	for _, gui in pairs(targetFolder:GetDescendants()) do
		if gui:GetAttribute("isLonumUI") == true then
			gui:Destroy()
		end
	end
end)

if getgenv().LonumObject then
	pcall(function()
		getgenv().LonumObject = nil
	end)
end
if getgenv().RayfieldObject then
	pcall(function()
		getgenv().RayfieldObject:Destroy()
	end)
	getgenv().RayfieldObject = nil
end

if getgenv and getgenv()[SCRIPT_ID] then
	pcall(function()
		getgenv()[SCRIPT_ID]:Destroy()
	end)
end

local ScriptContext = {
	Connections = {},
	Instances = {},
	Running = true,
}

local cfg = {
	isAutoSeaBeastActive = false,
	isAutoFactory = false,
	isAutodoughKing = false,
	isAutoCakePrince = false,
	isAutoMaterial = false,
	isTeleporting = false,
	isAutoEliteHunter = false,
	isBossHunterEnabled = false,
	isEliteHunterActive = false,
	isReadyToAttack = false,
	isAutoKenEnabled = false,
	isCollectingChest = false,
	isAutoStatsEnabled = false,
	isAutoAttackEnabled = false,
	isAutoSpinBones = false,
	isAutoBone = false,
	isAutoNextIsland = false,
	isAutoDungeonNext = false,
	isAutoDungeonBring = false,
	isAutoDungeonAttack = false,
	isAutoDungeon = false,
	isAutoRaidNextIsland = false,
	isAutoRaidBring = false,
	isAutoRaidAttack = false,
	isAutoRaidKill = false,
	isMultiMobDamage = false,
	isAutoTorch = false,
	isAutoBanana = false,
	isAutoPearl = false,
	isAutoCrowd = false,
	isAutoMagmaEvent = false,
	isTweeningToPlayer = false,
	WeaponCategory = "Melee",

	AutoMastery = false,
	MasteryCategory = "Melee",
	MasteryHealth = 30,

	UsePortal = true,
	AutoExecute = false,
	BringMethod = "Tween",

	TweenSpeed = 300,
	BringRadius = 350,
	MaxPullRange = 150,
	TweenHeight = 15,
	HitRadius = 55,

	EvasionRadius = 18,
	EvasionTick = 0.5,

	TargetRefresh = 0,
	BringInterval = 0,
	AttackIntervalFast = 0.05,
	AttackIntervalSuper = 0,
	EvasionMoveInterval = 0.45,
	ThreadSleep = 0.05,

	StuckTimeout = 3,

	autoBoat = false,
	autoSail = false,
	autoSeaBeast = false,
	boatSpeedMod = false,
	boatMaxSpeed = 300,
	boatType = "Dinghy",
	autoChest = false,
	autoFruit = false,
	autoBounty = false,

	lowPlayerServer = false,
	maxPlayersForHop = 8,
	hopDelay = 60,
	attackRange = 50,
	seaBeastPriority = false,
	aimOffset = Vector3.new(0, 3, 0),
	fruitScanRadius = 500,
	chestScanRadius = 300,
	playerScanRadius = 200,
	dodgeEnabled = false,
	dodgeDistance = 15,
	dodgeCooldown = 1,

	isAutoBerry = false,
	autoBerryWorker = 0,
	isTeleportingToIsland = false,

	isAutoHaze = false,
}

local activeTween = nil
local syn = getgenv and getgenv().syn or nil
FarmToggle = nil
local GetSafePosition = nil

local Sea3Portals = {
	Turtle = {
		Outer = Vector3.new(-12463.6025, 378.3270, -7566.0830),
		Inner = Vector3.new(-5060.4116, 318.5020, -3193.2248),
	},
	Hydra = {
		Outer = Vector3.new(5650.9477, 1017.2747, -350.3791),
		Inner = Vector3.new(-5027.0302, 318.5020, -3206.7036),
	},
	Tiki = {
		Outer = Vector3.new(-16799.0918, 84.3227997, 291.072845),
		Inner = Vector3.new(-5097.13184, 318.502014, -3178.39844),
	},
}

function ScriptContext:AddConnection(conn)
	table.insert(self.Connections, conn)
	return conn
end

function ScriptContext:GetRaidMap()
	local mapFolder = workspace:FindFirstChild("Map")
	local raidMap = mapFolder and mapFolder:FindFirstChild("RaidMap")
	if raidMap then
		return raidMap
	end

	raidMap = workspace:FindFirstChild("RaidMap")
	if raidMap then
		return raidMap
	end

	if mapFolder then
		for _, child in ipairs(mapFolder:GetChildren()) do
			if string.match(child.Name, "Raid") then
				return child
			end
		end
	end
	return nil
end

function ScriptContext:Destroy()
	self.Running = false
	for _, conn in ipairs(self.Connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	table.clear(self.Connections)

	pcall(function()
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
		local c = game:GetService("Players").LocalPlayer.Character
		if c and c:FindFirstChild("HumanoidRootPart") then
			local bv = c.HumanoidRootPart:FindFirstChild("AutofarmBv")
			if bv then
				bv:Destroy()
			end
			local bg = c.HumanoidRootPart:FindFirstChild("AutofarmBg")
			if bg then
				bg:Destroy()
			end
		end
	end)
end

if getgenv then
	getgenv()[SCRIPT_ID] = ScriptContext
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local hasFireTouch = type(firetouchinterest) == "function"
local hasProximity = type(fireproximityprompt) == "function"

local player = Players.LocalPlayer

pcall(function()
	if getconnections then
		for _, conn in ipairs(getconnections(player.Idled)) do
			if conn.Disable then
				conn:Disable()
			elseif conn.Disconnect then
				conn:Disconnect()
			end
		end
	else
		ScriptContext:AddConnection(player.Idled:Connect(function()
			local VirtualUser = game:GetService("VirtualUser")
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end))
	end
end)

local function SetupAutoExecute()
	local qot = queue_on_teleport
		or queueonteleport
		or (syn and syn.queue_on_teleport)
		or (fluxus and fluxus.queue_on_teleport)
	if qot then
		player.OnTeleport:Connect(function(State)
			if cfg.AutoExecute and State == Enum.TeleportState.Started then
				local cacheBuster = "?v=" .. tostring(os.time())
				local code = game:HttpGet(
					"https://raw.githubusercontent.com/Difz25x/roblox-project/main/temp_bloxfruit.lua" .. cacheBuster
				)
				if code then
					qot(code)
				else
					qot(
						'loadstring(game:HttpGet("https://raw.githubusercontent.com/Difz25x/roblox-project/main/temp_bloxfruit.lua"))()'
					)
				end
			end
		end)
	end
end
SetupAutoExecute()

task.spawn(function()
	pcall(function()
		if sethiddenproperty then
			sethiddenproperty(player, "SimulationRadius", 1000)
			sethiddenproperty(player, "MaxSimulationRadius", 1000)
		end
	end)

	pcall(function()
		if hookmetamethod and getnamecallmethod and checkcaller then
			local oldNamecall
			oldNamecall = hookmetamethod(
				game,
				"__namecall",
				newcclosure(function(self, ...)
					local method = getnamecallmethod()
					if not checkcaller() then
						if (method == "Kick" or method == "kick") and self == player then
							return nil
						end
					end
					return oldNamecall(self, ...)
				end)
			)
		end
	end)

	if hookfunction and require then
		pcall(function()
			local DeathFX = game:GetService("ReplicatedStorage").Effect.Container:FindFirstChild("Death")
			local RespawnFX = game:GetService("ReplicatedStorage").Effect.Container:FindFirstChild("Respawn")
			if DeathFX then
				hookfunction(require(DeathFX), function() end)
			end
			if RespawnFX then
				hookfunction(require(RespawnFX), function() end)
			end
		end)
	end

	local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
	local mainGui = playerGui:WaitForChild("Main")
	local blackScreen = mainGui:WaitForChild("Blackscreen")

	if blackScreen then
		blackScreen.BackgroundTransparency = 1
	end

	local function OptimizeMovement()
		local char = game.Players.LocalPlayer.Character
		if not char then
			return
		end
		local geppoScript = char:WaitForChild("Geppo", 3)
		local dodgeScript = char:WaitForChild("Dodge", 3)

		if geppoScript or dodgeScript then
			pcall(function()
				if getgc and debug.getupvalues and debug.setupvalue then
					for _, v in ipairs(getgc(true)) do
						if type(v) == "function" then
							local fenv = getfenv(v)

							if geppoScript and fenv.script == geppoScript then
								for i, upv in pairs(debug.getupvalues(v)) do
									if tostring(upv) == "0" then
										debug.setupvalue(v, i, 0)
									end
								end
							end

							if dodgeScript and fenv.script == dodgeScript then
								for i, upv in pairs(debug.getupvalues(v)) do
									if type(upv) == "table" and rawget(upv, "LastUse") then
										upv.LastUse = 0
										upv.LastAfter = 0
									end
								end
							end
						end
					end
				end
			end)
		end

		if isNoclipping then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
	end

	game.Players.LocalPlayer.CharacterAdded:Connect(OptimizeMovement)
	if game.Players.LocalPlayer.Character then
		OptimizeMovement()
	end
end)

local function SmartSetProperty(instance, prop, value)
	pcall(function()
		if isscriptable then
			local isExposed = isscriptable(instance, prop)
			if isExposed then
				instance[prop] = value
				return
			end
		end
		if sethiddenproperty then
			sethiddenproperty(instance, prop, value)
		else
			instance[prop] = value
		end
	end)
end

local attackSpeedMode = "Fast Attack"
local dungeonWorkerGeneration = 10
local currentRaidIsland = 1

local enabled = false
local selectedStatCategory = "Melee"
local bypassRender = false

activeTween = nil
local lastTargetPos = nil
local currentEvasionOffset = Vector3.new(0, cfg.TweenHeight, 0)
local lastEvasionTime = 0
local lastAbandonAttempt = 0
local lastPlayerPos = nil

local currentTargetInstance = nil
local lastTargetHealth = -1
local lastTargetHealthChangeAt = 0
local enemyBlacklist = {}

local cachedWeapon = nil
local cachedWeaponCategory = nil
local lastAttackAt = 0
local lastTargetRefreshAt = 0
local lastEvasionMoveAt = 0
local workerGeneration = 10

local teleportTravelKey = nil
local teleportTravelStartedAt = 0
local teleportTravelOrigin = nil
local TELEPORT_TRAVEL_ARRIVE_RADIUS = 120
local cachedEnemiesFolder = nil

selectedBossName = nil
farmNearestEnabled = false
farmNearestRadius = 5000

local lastDodgeTime = 0
local currentBoat = nil
local currentIsland = nil
local fruitWaypoints = {}
local chestWaypoints = {}
local autoKillVolcano = false
local AutoEmber = false

local eliteHunterWorkerGen = 0

local CommF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local CommE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE")

local RegisterHitEvent, RegisterAttackEvent

pcall(function()
	local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
	RegisterHitEvent = Net:WaitForChild("RE/RegisterHit")
	RegisterAttackEvent = Net:WaitForChild("RE/RegisterAttack")

	pcall(function()
		local CombatUtil = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatUtil"))
		if CombatUtil then
			CombatUtil.CanCharacterMeleeAoe = function()
				return 100
			end
			CombatUtil.CanAttack = function()
				return true
			end
		end
	end)

	pcall(function()
		local Global = require(ReplicatedStorage:WaitForChild("Global"))
		if Global then
			Global.tapCooldown = 0
			local mt = getrawmetatable and getrawmetatable(Global) or getmetatable(Global)
			if mt then
				if setreadonly then setreadonly(mt, false) end
				local oldIndex = mt.__index
				mt.__index = function(t, k)
					if k == "tapCooldown" then
						return 0
					end
					if type(oldIndex) == "function" then
						return oldIndex(t, k)
					elseif type(oldIndex) == "table" then
						return oldIndex[k]
					end
					return rawget(t, k)
				end
				local oldNewIndex = mt.__newindex
				mt.__newindex = function(t, k, v)
					if k == "tapCooldown" then
						rawset(t, k, 0)
						return
					end
					if type(oldNewIndex) == "function" then
						return oldNewIndex(t, k, v)
					end
					rawset(t, k, v)
				end
			end
			task.spawn(function()
				while ScriptContext.Running do
					Global.tapCooldown = 0
					task.wait(0.05)
				end
			end)
		end
	end)
end)

local currentSessionSecret = nil
getgenv().cachedNetSeed = 1

local function RefreshSessionSecret()
	pcall(function()
		local c = coroutine.create(function() end)
		currentSessionSecret = tostring(player.UserId):sub(2, 4) .. tostring(c):sub(11, 15)

		local netSeed = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"):FindFirstChild("seed")
		if netSeed and netSeed:IsA("RemoteFunction") then
			getgenv().cachedNetSeed = netSeed:InvokeServer()
		end

		if RegisterHitEvent and currentSessionSecret then
			RegisterHitEvent:FireServer(currentSessionSecret)
		end
	end)
end

task.defer(function()
	RefreshSessionSecret()

	task.spawn(function()
		while ScriptContext.Running do
			task.wait(180)
			RefreshSessionSecret()
		end
	end)
end)

local BOSSES = {
	{ Sea = 1, Min = 20, Name = "Gorilla King", Quest = "JungleQuest", Stage = 3, NPC = Vector3.new(-1598, 36, 153) },
	{ Sea = 1, Min = 55, Name = "Chef", Quest = "BuggyQuest1", Stage = 3, NPC = Vector3.new(-1141, 13, 3827) },
	{ Sea = 1, Min = 105, Name = "Yeti", Quest = "SnowQuest", Stage = 3, NPC = Vector3.new(1389, 87, -1298) },
	{
		Sea = 1,
		Min = 130,
		Name = "Vice Admiral",
		Quest = "MarineQuest2",
		Stage = 2,
		NPC = Vector3.new(-5035, 20, 4324),
	},
	{ Sea = 1, Min = 220, Name = "Warden", Quest = "ImpelQuest", Stage = 1, NPC = Vector3.new(3873, 14, -1940) },
	{ Sea = 1, Min = 230, Name = "Chief Warden", Quest = "ImpelQuest", Stage = 2, NPC = Vector3.new(3873, 14, -1940) },
	{ Sea = 1, Min = 240, Name = "Swan", Quest = "ImpelQuest", Stage = 3, NPC = Vector3.new(3873, 14, -1940) },
	{ Sea = 1, Min = 350, Name = "Magma Admiral", Quest = "MagmaQuest", Stage = 3, NPC = Vector3.new(-5701, 17, 8722) },
	{ Sea = 1, Min = 425, Name = "Fishman Lord", Quest = "FishmanQuest", Stage = 3, NPC = Vector3.new(6112, 19, 1567) },
	{ Sea = 1, Min = 500, Name = "Wysper", Quest = "SkyExp1Quest", Stage = 3, NPC = Vector3.new(-7862, 5545, -381) },
	{
		Sea = 1,
		Min = 575,
		Name = "Thunder God",
		Quest = "SkyExp2Quest",
		Stage = 3,
		NPC = Vector3.new(-7749, 5607, -2317),
	},
	{ Sea = 1, Min = 675, Name = "Cyborg", Quest = "FountainQuest", Stage = 3, NPC = Vector3.new(5247, 38, 4067) },
	{ Sea = 2, Min = 750, Name = "Diamond", Quest = "Area1Quest", Stage = 3, NPC = Vector3.new(-429, 72, 1836) },
	{ Sea = 2, Min = 850, Name = "Jeremy", Quest = "Area2Quest", Stage = 3, NPC = Vector3.new(638, 73, 918) },
	{ Sea = 2, Min = 925, Name = "Orbitus", Quest = "MarineQuest3", Stage = 3, NPC = Vector3.new(-2441, 73, -3219) },
	{
		Sea = 2,
		Min = 1150,
		Name = "Smoke Admiral",
		Quest = "IceSideQuest",
		Stage = 3,
		NPC = Vector3.new(-6061, 16, -4905),
	},
	{
		Sea = 2,
		Min = 1400,
		Name = "Awakened Ice Admiral",
		Quest = "FrostQuest",
		Stage = 3,
		NPC = Vector3.new(5668, 28, -6484),
	},
	{
		Sea = 2,
		Min = 1475,
		Name = "Tide Keeper",
		Quest = "ForgottenQuest",
		Stage = 3,
		NPC = Vector3.new(-3054, 237, -10148),
	},
	{
		Sea = 3,
		Min = 1550,
		Name = "Stone",
		Quest = "PiratePortQuest",
		Stage = 3,
		NPC = Vector3.new(-448.99, 108.63, 5948.77),
	},
	{
		Sea = 3,
		Min = 1675,
		Name = "Hydra Leader",
		Quest = "VenomCrewQuest",
		Stage = 3,
		NPC = Vector3.new(5214.16, 1004.13, 756.39),
	},
	{
		Sea = 3,
		Min = 1750,
		Name = "Kilo Admiral",
		Quest = "MarineTreeIsland",
		Stage = 3,
		NPC = Vector3.new(2484.00, 74.29, -6787.78),
	},
	{
		Sea = 3,
		Min = 1875,
		Name = "Captain Elephant",
		Quest = "DeepForestIsland",
		Stage = 3,
		NPC = Vector3.new(-13232, 332, -7625),
	},
	{
		Sea = 3,
		Min = 1950,
		Name = "Beautiful Pirate",
		Quest = "DeepForestIsland2",
		Stage = 3,
		NPC = Vector3.new(-11939, 277, -8814),
	},
	{
		Sea = 3,
		Min = 2175,
		Name = "Cake Queen",
		Quest = "IceCreamIslandQuest",
		Stage = 3,
		NPC = Vector3.new(-820, 66, -10966),
	},
}

local SEA1 = {
	{
		Min = 1,
		Max = 9,
		Quest = "BanditQuest1",
		Stage = 1,
		Name = "Bandits",
		Mob = "Bandit",
		Count = 5,
		NPC = Vector3.new(1059, 13, 1552),
		MobPos = Vector3.new(1145, 17, 1634),
	},
	{
		Min = 10,
		Max = 14,
		Quest = "JungleQuest",
		Stage = 1,
		Name = "Monkeys",
		Mob = "Monkey",
		Count = 6,
		NPC = Vector3.new(-1602, 37, 153),
		MobPos = Vector3.new(-1448, 50, 64),
	},
	{
		Min = 15,
		Max = 29,
		Quest = "JungleQuest",
		Stage = 2,
		Name = "Gorillas",
		Mob = "Gorilla",
		Count = 8,
		NPC = Vector3.new(-1602, 37, 153),
		MobPos = Vector3.new(-1237, 7, -486),
	},
	{
		Min = 30,
		Max = 39,
		Quest = "BuggyQuest1",
		Stage = 1,
		Name = "Pirates",
		Mob = "Pirate",
		Count = 8,
		NPC = Vector3.new(-1140, 5, 3828),
		MobPos = Vector3.new(-1115, 14, 3938),
	},
	{
		Min = 40,
		Max = 59,
		Quest = "BuggyQuest1",
		Stage = 2,
		Name = "Brute",
		Mob = "Brute",
		Count = 8,
		NPC = Vector3.new(-1140, 5, 3828),
		MobPos = Vector3.new(-1145, 15, 4350),
	},
	{
		Min = 60,
		Max = 74,
		Quest = "DesertQuest",
		Stage = 1,
		Name = "Desert Bandits",
		Mob = "Desert Bandit",
		Count = 8,
		NPC = Vector3.new(897, 7, 4389),
		MobPos = Vector3.new(932, 7, 4484),
	},
	{
		Min = 75,
		Max = 89,
		Quest = "DesertQuest",
		Stage = 2,
		Name = "Desert Officers",
		Mob = "Desert Officer",
		Count = 6,
		NPC = Vector3.new(897, 7, 4389),
		MobPos = Vector3.new(1572, 11, 4386),
	},
	{
		Min = 90,
		Max = 99,
		Quest = "SnowQuest",
		Stage = 1,
		Name = "Snow Bandits",
		Mob = "Snow Bandit",
		Count = 7,
		NPC = Vector3.new(1386, 87, -1297),
		MobPos = Vector3.new(1354, 105, -1328),
	},
	{
		Min = 100,
		Max = 119,
		Quest = "SnowQuest",
		Stage = 2,
		Name = "Snowmen",
		Mob = "Snowman",
		Count = 8,
		NPC = Vector3.new(1386, 87, -1297),
		MobPos = Vector3.new(1218, 139, -1488),
	},
	{
		Min = 120,
		Max = 149,
		Quest = "MarineQuest2",
		Stage = 1,
		Name = "Chief Petty Officers",
		Mob = "Chief Petty Officer",
		Count = 8,
		NPC = Vector3.new(-5035, 29, 4324),
		MobPos = Vector3.new(-4882, 23, 4273),
	},
	{
		Min = 150,
		Max = 174,
		Quest = "SkyQuest",
		Stage = 1,
		Name = "Sky Bandits",
		Mob = "Sky Bandit",
		Count = 7,
		NPC = Vector3.new(-4842, 718, -2623),
		MobPos = Vector3.new(-4953, 295, -2899),
	},
	{
		Min = 175,
		Max = 189,
		Quest = "SkyQuest",
		Stage = 2,
		Name = "Dark Masters",
		Mob = "Dark Master",
		Count = 8,
		NPC = Vector3.new(-4842, 718, -2623),
		MobPos = Vector3.new(-5259, 391, -2229),
	},
	{
		Min = 190,
		Max = 209,
		Quest = "PrisonerQuest",
		Stage = 1,
		Name = "Prisoners",
		Mob = "Prisoner",
		Count = 8,
		NPC = Vector3.new(5308, 2, 475),
		MobPos = Vector3.new(5099, 1, 474),
	},
	{
		Min = 210,
		Max = 249,
		Quest = "PrisonerQuest",
		Stage = 2,
		Name = "Dangerous Prisoners",
		Mob = "Dangerous Prisoner",
		Count = 8,
		NPC = Vector3.new(5308, 2, 475),
		MobPos = Vector3.new(5654, 15, 866),
	},
	{
		Min = 250,
		Max = 274,
		Quest = "ColosseumQuest",
		Stage = 1,
		Name = "Toga Warriors",
		Mob = "Toga Warrior",
		Count = 7,
		NPC = Vector3.new(-1580, 7, -2986),
		MobPos = Vector3.new(-1779, 45, -2741),
	},
	{
		Min = 275,
		Max = 299,
		Quest = "ColosseumQuest",
		Stage = 2,
		Name = "Gladiators",
		Mob = "Gladiator",
		Count = 8,
		NPC = Vector3.new(-1580, 7, -2986),
		MobPos = Vector3.new(-1274, 58, -3188),
	},
	{
		Min = 300,
		Max = 324,
		Quest = "MagmaQuest",
		Stage = 1,
		Name = "Military Soldiers",
		Mob = "Military Soldier",
		Count = 7,
		NPC = Vector3.new(-5316, 12, 8517),
		MobPos = Vector3.new(-5411, 11, 8454),
	},
	{
		Min = 325,
		Max = 374,
		Quest = "MagmaQuest",
		Stage = 2,
		Name = "Military Spies",
		Mob = "Military Spy",
		Count = 8,
		NPC = Vector3.new(-5316, 12, 8517),
		MobPos = Vector3.new(-5802, 86, 8829),
	},
	{
		Min = 375,
		Max = 399,
		Quest = "FishmanQuest",
		Stage = 1,
		Name = "Fishman Warriors",
		Mob = "Fishman Warrior",
		Count = 8,
		NPC = Vector3.new(6112, 19, 1567),
		MobPos = Vector3.new(60878, 19, 1543),
	},
	{
		Min = 400,
		Max = 449,
		Quest = "FishmanQuest",
		Stage = 2,
		Name = "Fishman Commandos",
		Mob = "Fishman Commando",
		Count = 7,
		NPC = Vector3.new(6112, 19, 1567),
		MobPos = Vector3.new(61891, 19, 1470),
	},
	{
		Min = 450,
		Max = 474,
		Quest = "SkyExp1Quest",
		Stage = 1,
		Name = "God's Guards",
		Mob = "God's Guard",
		Count = 7,
		NPC = Vector3.new(-4722, 846, -1954),
		MobPos = Vector3.new(-4710, 845, -1927),
	},
	{
		Min = 475,
		Max = 524,
		Quest = "SkyExp1Quest",
		Stage = 2,
		Name = "Shandas",
		Mob = "Shanda",
		Count = 9,
		NPC = Vector3.new(-7862, 5546, -380),
		MobPos = Vector3.new(-7685, 5601, -441),
	},
	{
		Min = 525,
		Max = 549,
		Quest = "SkyExp2Quest",
		Stage = 1,
		Name = "Royal Squads",
		Mob = "Royal Squad",
		Count = 8,
		NPC = Vector3.new(-7904, 5635, -1412),
		MobPos = Vector3.new(-7685, 5606, -1442),
	},
	{
		Min = 550,
		Max = 624,
		Quest = "SkyExp2Quest",
		Stage = 2,
		Name = "Royal Soldiers",
		Mob = "Royal Soldier",
		Count = 8,
		NPC = Vector3.new(-7904, 5635, -1412),
		MobPos = Vector3.new(-7864, 5661, -1708),
	},
	{
		Min = 625,
		Max = 649,
		Quest = "FountainQuest",
		Stage = 1,
		Name = "Galley Pirates",
		Mob = "Galley Pirate",
		Count = 8,
		NPC = Vector3.new(5259, 39, 4050),
		MobPos = Vector3.new(5558, 39, 3998),
	},
	{
		Min = 650,
		Max = 700,
		Quest = "FountainQuest",
		Stage = 2,
		Name = "Galley Captains",
		Mob = "Galley Captain",
		Count = 9,
		NPC = Vector3.new(5259, 39, 4050),
		MobPos = Vector3.new(5677, 93, 4967),
	},
}

local SEA2 = {
	{
		Min = 700,
		Max = 724,
		Quest = "Area1Quest",
		Stage = 1,
		Name = "Raiders",
		Mob = "Raider",
		Count = 8,
		NPC = Vector3.new(-429, 72, 1836),
		MobPos = Vector3.new(-737, 39, 2385),
	},
	{
		Min = 725,
		Max = 774,
		Quest = "Area1Quest",
		Stage = 2,
		Name = "Mercenaries",
		Mob = "Mercenary",
		Count = 8,
		NPC = Vector3.new(-429, 72, 1836),
		MobPos = Vector3.new(-972, 73, 1419),
	},
	{
		Min = 775,
		Max = 799,
		Quest = "Area2Quest",
		Stage = 1,
		Name = "Swan Pirates",
		Mob = "Swan Pirate",
		Count = 8,
		NPC = Vector3.new(638, 73, 918),
		MobPos = Vector3.new(970, 142, 1217),
	},
	{
		Min = 800,
		Max = 874,
		Quest = "Area2Quest",
		Stage = 2,
		Name = "Factory Staff",
		Mob = "Factory Staff",
		Count = 8,
		NPC = Vector3.new(638, 73, 918),
		MobPos = Vector3.new(296, 73, -56),
	},
	{
		Min = 875,
		Max = 899,
		Quest = "MarineQuest3",
		Stage = 1,
		Name = "Marine Lieutenants",
		Mob = "Marine Lieutenant",
		Count = 8,
		NPC = Vector3.new(-2441, 73, -3219),
		MobPos = Vector3.new(-2821, 73, -3070),
	},
	{
		Min = 900,
		Max = 949,
		Quest = "MarineQuest3",
		Stage = 2,
		Name = "Marine Captains",
		Mob = "Marine Captain",
		Count = 9,
		NPC = Vector3.new(-2441, 73, -3219),
		MobPos = Vector3.new(-1867, 73, -3321),
	},
	{
		Min = 950,
		Max = 974,
		Quest = "ZombieQuest",
		Stage = 1,
		Name = "Zombies",
		Mob = "Zombie",
		Count = 8,
		NPC = Vector3.new(-5497, 48, -795),
		MobPos = Vector3.new(-5736, 126, -728),
	},
	{
		Min = 975,
		Max = 999,
		Quest = "ZombieQuest",
		Stage = 2,
		Name = "Vampires",
		Mob = "Vampire",
		Count = 8,
		NPC = Vector3.new(-5497, 48, -795),
		MobPos = Vector3.new(-6033, 7, -1317),
	},
	{
		Min = 1000,
		Max = 1049,
		Quest = "SnowMountainQuest",
		Stage = 1,
		Name = "Snow Troopers",
		Mob = "Snow Trooper",
		Count = 8,
		NPC = Vector3.new(609, 401, -5372),
		MobPos = Vector3.new(535, 432, -5484),
	},
	{
		Min = 1050,
		Max = 1099,
		Quest = "SnowMountainQuest",
		Stage = 2,
		Name = "Winter Warriors",
		Mob = "Winter Warrior",
		Count = 9,
		NPC = Vector3.new(609, 401, -5372),
		MobPos = Vector3.new(1234, 456, -5174),
	},
	{
		Min = 1100,
		Max = 1124,
		Quest = "IceSideQuest",
		Stage = 1,
		Name = "Lab Subordinates",
		Mob = "Lab Subordinate",
		Count = 8,
		NPC = Vector3.new(-6061, 16, -4905),
		MobPos = Vector3.new(-5720, 63, -4784),
	},
	{
		Min = 1125,
		Max = 1174,
		Quest = "IceSideQuest",
		Stage = 2,
		Name = "Horned Warriors",
		Mob = "Horned Warrior",
		Count = 9,
		NPC = Vector3.new(-6061, 16, -4905),
		MobPos = Vector3.new(-6292, 91, -5503),
	},
	{
		Min = 1175,
		Max = 1199,
		Quest = "FireSideQuest",
		Stage = 1,
		Name = "Magma Ninjas",
		Mob = "Magma Ninja",
		Count = 8,
		NPC = Vector3.new(-5429, 16, -5297),
		MobPos = Vector3.new(-5461, 130, -5836),
	},
	{
		Min = 1200,
		Max = 1249,
		Quest = "FireSideQuest",
		Stage = 2,
		Name = "Lava Pirates",
		Mob = "Lava Pirate",
		Count = 8,
		NPC = Vector3.new(-5429, 16, -5297),
		MobPos = Vector3.new(-5251, 55, -4774),
	},
	{
		Min = 1250,
		Max = 1274,
		Quest = "ShipQuest1",
		Stage = 1,
		Name = "Ship Deckhands",
		Mob = "Ship Deckhand",
		Count = 8,
		NPC = Vector3.new(1038, 125, 32911),
		MobPos = Vector3.new(1212, 126, 33059),
	},
	{
		Min = 1275,
		Max = 1299,
		Quest = "ShipQuest1",
		Stage = 2,
		Name = "Ship Engineers",
		Mob = "Ship Engineer",
		Count = 8,
		NPC = Vector3.new(1038, 125, 32911),
		MobPos = Vector3.new(919, 44, 32779),
	},
	{
		Min = 1300,
		Max = 1324,
		Quest = "ShipQuest2",
		Stage = 1,
		Name = "Ship Stewards",
		Mob = "Ship Steward",
		Count = 8,
		NPC = Vector3.new(969, 125, 33245),
		MobPos = Vector3.new(919, 130, 33419),
	},
	{
		Min = 1325,
		Max = 1349,
		Quest = "ShipQuest2",
		Stage = 2,
		Name = "Ship Officers",
		Mob = "Ship Officer",
		Count = 8,
		NPC = Vector3.new(969, 125, 33245),
		MobPos = Vector3.new(1037, 181, 33316),
	},
	{
		Min = 1350,
		Max = 1374,
		Quest = "FrostQuest",
		Stage = 1,
		Name = "Arctic Warriors",
		Mob = "Arctic Warrior",
		Count = 8,
		NPC = Vector3.new(5668, 28, -6484),
		MobPos = Vector3.new(5966, 58, -6179),
	},
	{
		Min = 1375,
		Max = 1424,
		Quest = "FrostQuest",
		Stage = 2,
		Name = "Snow Lurkers",
		Mob = "Snow Lurker",
		Count = 8,
		NPC = Vector3.new(5668, 28, -6484),
		MobPos = Vector3.new(5407, 69, -6880),
	},
	{
		Min = 1425,
		Max = 1449,
		Quest = "ForgottenQuest",
		Stage = 1,
		Name = "Sea Soldiers",
		Mob = "Sea Soldier",
		Count = 8,
		NPC = Vector3.new(-3054, 237, -10148),
		MobPos = Vector3.new(-3028, 65, -9775),
	},
	{
		Min = 1450,
		Max = 1500,
		Quest = "ForgottenQuest",
		Stage = 2,
		Name = "Water Fighters",
		Mob = "Water Fighter",
		Count = 8,
		NPC = Vector3.new(-3054, 237, -10148),
		MobPos = Vector3.new(-3262, 298, -10553),
	},
}

local SEA3 = {
	{
		Min = 1500,
		Max = 1524,
		Quest = "PiratePortQuest",
		Stage = 1,
		Name = "Pirate Millionaires",
		Mob = "Pirate Millionaire",
		Count = 8,
		NPC = Vector3.new(-448.99, 108.63, 5948.77),
		MobPos = Vector3.new(-435, 190, 5551),
	},
	{
		Min = 1525,
		Max = 1574,
		Quest = "PiratePortQuest",
		Stage = 2,
		Name = "Pistol Billionaires",
		Mob = "Pistol Billionaire",
		Count = 8,
		NPC = Vector3.new(-448.99, 108.63, 5948.77),
		MobPos = Vector3.new(-236, 217, 6007),
	},
	{
		Min = 1575,
		Max = 1599,
		Quest = "DragonCrewQuest",
		Stage = 1,
		Name = "Dragon Crew Warriors",
		Mob = "Dragon Crew Warrior",
		Count = 8,
		NPC = Vector3.new(6737.21, 127.44, -712.48),
		MobPos = Vector3.new(6834.66, 192.74, -829.06),
	},
	{
		Min = 1600,
		Max = 1624,
		Quest = "DragonCrewQuest",
		Stage = 2,
		Name = "Dragon Crew Archers",
		Mob = "Dragon Crew Archer",
		Count = 8,
		NPC = Vector3.new(6737.21, 127.44, -712.48),
		MobPos = Vector3.new(6713.14, 716.12, 631.09),
	},
	{
		Min = 1625,
		Max = 1649,
		Quest = "VenomCrewQuest",
		Stage = 1,
		Name = "Hydra Enforcers",
		Mob = "Hydra Enforcer",
		Count = 8,
		NPC = Vector3.new(5214.16, 1004.13, 756.39),
		MobPos = Vector3.new(4570.93, 1026.70, 405.84),
	},
	{
		Min = 1650,
		Max = 1699,
		Quest = "VenomCrewQuest",
		Stage = 2,
		Name = "Venomous Assailant",
		Mob = "Venomous Assailant",
		Count = 8,
		NPC = Vector3.new(5214.16, 1004.13, 756.39),
		MobPos = Vector3.new(4499.958984, 1169.141724, 796.885559),
	},
	{
		Min = 1700,
		Max = 1724,
		Quest = "MarineTreeIsland",
		Stage = 1,
		Name = "Marine Commodores",
		Mob = "Marine Commodore",
		Count = 8,
		NPC = Vector3.new(2484.00, 74.29, -6787.78),
		MobPos = Vector3.new(2196.70, 284.17, -7413.28),
	},
	{
		Min = 1725,
		Max = 1774,
		Quest = "MarineTreeIsland",
		Stage = 2,
		Name = "Marine Rear Admirals",
		Mob = "Marine Rear Admiral",
		Count = 8,
		NPC = Vector3.new(2484.00, 74.29, -6787.78),
		MobPos = Vector3.new(3671, 161, -6932),
	},
	{
		Min = 1775,
		Max = 1799,
		Quest = "DeepForestIsland3",
		Stage = 1,
		Name = "Fishman Raiders",
		Mob = "Fishman Raider",
		Count = 8,
		NPC = Vector3.new(-10582, 332, -8758),
		MobPos = Vector3.new(-10407, 332, -8368),
	},
	{
		Min = 1800,
		Max = 1824,
		Quest = "DeepForestIsland3",
		Stage = 2,
		Name = "Fishman Captains",
		Mob = "Fishman Captain",
		Count = 8,
		NPC = Vector3.new(-10582, 332, -8758),
		MobPos = Vector3.new(-10993, 352, -9003),
	},
	{
		Min = 1825,
		Max = 1849,
		Quest = "DeepForestIsland",
		Stage = 1,
		Name = "Forest Pirates",
		Mob = "Forest Pirate",
		Count = 8,
		NPC = Vector3.new(-13232, 333, -7627),
		MobPos = Vector3.new(-13389.283203, 332.440765, -7799.888184),
	},
	{
		Min = 1850,
		Max = 1899,
		Quest = "DeepForestIsland",
		Stage = 2,
		Name = "Mythological Pirates",
		Mob = "Mythological Pirate",
		Count = 8,
		NPC = Vector3.new(-13232, 333, -7627),
		MobPos = Vector3.new(-13508, 583, -6985),
	},
	{
		Min = 1900,
		Max = 1924,
		Quest = "DeepForestIsland2",
		Stage = 1,
		Name = "Jungle Pirates",
		Mob = "Jungle Pirate",
		Count = 8,
		NPC = Vector3.new(-12684, 391, -9902),
		MobPos = Vector3.new(-12132.820312, 331.800903, -10543.690430),
	},
	{
		Min = 1925,
		Max = 1974,
		Quest = "DeepForestIsland2",
		Stage = 2,
		Name = "Musketeer Pirates",
		Mob = "Musketeer Pirate",
		Count = 8,
		NPC = Vector3.new(-12684, 391, -9902),
		MobPos = Vector3.new(-13291, 392, -9769),
	},
	{
		Min = 1975,
		Max = 1999,
		Quest = "HauntedQuest1",
		Stage = 1,
		Name = "Reborn Skeletons",
		Mob = "Reborn Skeleton",
		Count = 8,
		NPC = Vector3.new(-9482, 142, 5567),
		MobPos = Vector3.new(-8760, 183, 6168),
	},
	{
		Min = 2000,
		Max = 2024,
		Quest = "HauntedQuest1",
		Stage = 2,
		Name = "Living Zombies",
		Mob = "Living Zombie",
		Count = 8,
		NPC = Vector3.new(-9482, 142, 5567),
		MobPos = Vector3.new(-10144, 139, 5932),
	},
	{
		Min = 2025,
		Max = 2049,
		Quest = "HauntedQuest2",
		Stage = 1,
		Name = "Demonic Souls",
		Mob = "Demonic Soul",
		Count = 8,
		NPC = Vector3.new(-9515, 172, 6078),
		MobPos = Vector3.new(-9507, 172, 6158),
	},
	{
		Min = 2050,
		Max = 2074,
		Quest = "HauntedQuest2",
		Stage = 2,
		Name = "Posessed Mummies",
		Mob = "Posessed Mummy",
		Count = 8,
		NPC = Vector3.new(-9515, 172, 6078),
		MobPos = Vector3.new(-9582, 6, 6205),
	},
	{
		Min = 2075,
		Max = 2099,
		Quest = "NutsIslandQuest",
		Stage = 1,
		Name = "Peanut Scouts",
		Mob = "Peanut Scout",
		Count = 8,
		NPC = Vector3.new(-2104, 38, -10192),
		MobPos = Vector3.new(-2150, 122, -10358),
	},
	{
		Min = 2100,
		Max = 2124,
		Quest = "NutsIslandQuest",
		Stage = 2,
		Name = "Peanut Presidents",
		Mob = "Peanut President",
		Count = 8,
		NPC = Vector3.new(-2104, 38, -10192),
		MobPos = Vector3.new(-2150, 123, -10536),
	},
	{
		Min = 2125,
		Max = 2149,
		Quest = "IceCreamIslandQuest",
		Stage = 1,
		Name = "Ice Cream Chefs",
		Mob = "Ice Cream Chef",
		Count = 8,
		NPC = Vector3.new(-820, 66, -10966),
		MobPos = Vector3.new(-848.671204, 65.882126, -10914.947266),
	},
	{
		Min = 2150,
		Max = 2199,
		Quest = "IceCreamIslandQuest",
		Stage = 2,
		Name = "Ice Cream Commanders",
		Mob = "Ice Cream Commander",
		Count = 8,
		NPC = Vector3.new(-820, 66, -10966),
		MobPos = Vector3.new(-610.750732, 208.282623, -11254.516602),
	},
	{
		Min = 2200,
		Max = 2224,
		Quest = "CakeQuest1",
		Stage = 1,
		Name = "Cookie Crafters",
		Mob = "Cookie Crafter",
		Count = 8,
		NPC = Vector3.new(-2021, 38, -12028),
		MobPos = Vector3.new(-2288.005371, 37.860714, -12088.270508),
	},
	{
		Min = 2225,
		Max = 2249,
		Quest = "CakeQuest1",
		Stage = 2,
		Name = "Cake Guards",
		Mob = "Cake Guard",
		Count = 8,
		NPC = Vector3.new(-2021, 38, -12028),
		MobPos = Vector3.new(-1577.599976, 46.978756, -12365.185547),
	},
	{
		Min = 2250,
		Max = 2274,
		Quest = "CakeQuest2",
		Stage = 1,
		Name = "Baking Staff",
		Mob = "Baking Staff",
		Count = 8,
		NPC = Vector3.new(-1927, 38, -12842),
		MobPos = Vector3.new(-1887, 78, -12998),
	},
	{
		Min = 2275,
		Max = 2299,
		Quest = "CakeQuest2",
		Stage = 2,
		Name = "Head Bakers",
		Mob = "Head Baker",
		Count = 8,
		NPC = Vector3.new(-1927, 38, -12842),
		MobPos = Vector3.new(-2207.034424, 53.564850, -12857.274414),
	},
	{
		Min = 2300,
		Max = 2324,
		Quest = "ChocQuest1",
		Stage = 1,
		Name = "Cocoa Warriors",
		Mob = "Cocoa Warrior",
		Count = 8,
		NPC = Vector3.new(233, 30, -12201),
		MobPos = Vector3.new(31.493752, 24.796925, -12246.680664),
	},
	{
		Min = 2325,
		Max = 2349,
		Quest = "ChocQuest1",
		Stage = 2,
		Name = "Chocolate Bar Battlers",
		Mob = "Chocolate Bar Battler",
		Count = 8,
		NPC = Vector3.new(233, 30, -12201),
		MobPos = Vector3.new(683.419617, 24.796822, -12576.225586),
	},
	{
		Min = 2350,
		Max = 2374,
		Quest = "ChocQuest2",
		Stage = 1,
		Name = "Sweet Thieves",
		Mob = "Sweet Thief",
		Count = 8,
		NPC = Vector3.new(151, 30, -12774),
		MobPos = Vector3.new(165, 77, -12600),
	},
	{
		Min = 2375,
		Max = 2399,
		Quest = "ChocQuest2",
		Stage = 2,
		Name = "Candy Rebels",
		Mob = "Candy Rebel",
		Count = 8,
		NPC = Vector3.new(151, 30, -12774),
		MobPos = Vector3.new(83.6653671, 93.5021515, -12963.4072),
	},
	{
		Min = 2400,
		Max = 2424,
		Quest = "CandyQuest1",
		Stage = 1,
		Name = "Candy Pirates",
		Mob = "Candy Pirate",
		Count = 8,
		NPC = Vector3.new(-1149, 13, -14446),
		MobPos = Vector3.new(-1347, 13, -14585),
	},
	{
		Min = 2425,
		Max = 2449,
		Quest = "CandyQuest1",
		Stage = 2,
		Name = "Snow Demons",
		Mob = "Snow Demon",
		Count = 8,
		NPC = Vector3.new(-1149, 13, -14446),
		MobPos = Vector3.new(-954, 55, -14558),
	},
	{
		Min = 2450,
		Max = 2474,
		Quest = "TikiQuest1",
		Stage = 1,
		Name = "Isle Outlaws",
		Mob = "Isle Outlaw",
		Count = 8,
		NPC = Vector3.new(-16546, 55, -172),
		MobPos = Vector3.new(-16101, 55, -155),
	},
	{
		Min = 2475,
		Max = 2499,
		Quest = "TikiQuest1",
		Stage = 2,
		Name = "Island Boys",
		Mob = "Island Boy",
		Count = 8,
		NPC = Vector3.new(-16546, 55, -172),
		MobPos = Vector3.new(-16731, 55, -257),
	},
	{
		Min = 2500,
		Max = 2524,
		Quest = "TikiQuest2",
		Stage = 1,
		Name = "Sun-kissed Warriors",
		Mob = "Sun-kissed Warrior",
		Count = 8,
		NPC = Vector3.new(-16539, 55, 1051),
		MobPos = Vector3.new(-16349, 55, 1005),
	},
	{
		Min = 2525,
		Max = 2549,
		Quest = "TikiQuest2",
		Stage = 2,
		Name = "Isle Champions",
		Mob = "Isle Champion",
		Count = 8,
		NPC = Vector3.new(-16539, 55, 1051),
		MobPos = Vector3.new(-16847, 55, 1002),
	},
	{
		Min = 2550,
		Max = 2574,
		Quest = "TikiQuest3",
		Stage = 1,
		Name = "Serpent Hunter",
		Mob = "Serpent Hunter",
		Count = 8,
		NPC = Vector3.new(-16663.8633, 105.30751, 1577.3197),
		MobPos = Vector3.new(-16586.220703, 107.084724, 1341.448608),
	},
	{
		Min = 2575,
		Max = 2599,
		Quest = "TikiQuest3",
		Stage = 2,
		Name = "Skull Slayer",
		Mob = "Skull Slayer",
		Count = 8,
		NPC = Vector3.new(-16663.8633, 105.30751, 1577.3197),
		MobPos = Vector3.new(-16666.9453, 176.768646, 1491.6416),
	},
	{
		Min = 2600,
		Max = 2624,
		Quest = "SubmergedQuest1",
		Stage = 1,
		Name = "Reef Bandit",
		Mob = "Reef Bandit",
		Count = 8,
		NPC = Vector3.new(10780.272461, -2087.699463, 9263.379883),
		MobPos = Vector3.new(10978.163086, -2023.948853, 9181.994141),
		TeleportNpc = Vector3.new(-16270.290039, 25.253189, 1371.398926),
	},
	{
		Min = 2625,
		Max = 2649,
		Quest = "SubmergedQuest1",
		Stage = 2,
		Name = "Coral Pirate",
		Mob = "Coral Pirate",
		Count = 8,
		NPC = Vector3.new(10780.272461, -2087.699463, 9263.379883),
		MobPos = Vector3.new(10733.620117, -2010.045288, 9343.441406),
		TeleportNpc = Vector3.new(-16270.290039, 25.253189, 1371.398926),
	},
	{
		Min = 2650,
		Max = 2674,
		Quest = "SubmergedQuest2",
		Stage = 1,
		Name = "Sea Chanter",
		Mob = "Sea Chanter",
		Count = 8,
		NPC = Vector3.new(10882.310547, -2086.176025, 10030.576172),
		MobPos = Vector3.new(10623.348633, -2046.116455, 10102.416016),
		TeleportNpc = Vector3.new(-16270.290039, 25.253189, 1371.398926),
	},
	{
		Min = 2675,
		Max = 2699,
		Quest = "SubmergedQuest2",
		Stage = 2,
		Name = "Ocean Prophet",
		Mob = "Ocean Prophet",
		Count = 8,
		NPC = Vector3.new(10882.310547, -2086.176025, 10030.576172),
		MobPos = Vector3.new(11041.423828, -1949.248901, 10147.605469),
		TeleportNpc = Vector3.new(-16270.290039, 25.253189, 1371.398926),
	},
	{
		Min = 2675,
		Max = 2699,
		Quest = "SubmergedQuest3",
		Stage = 1,
		Name = "High Disciple",
		Mob = "High Disciple",
		Count = 8,
		NPC = Vector3.new(9636.642578, -1992.420532, 9611.206055),
		MobPos = Vector3.new(9830.585938, -1941.134888, 9698.757812),
		TeleportNpc = Vector3.new(-16270.290039, 25.253189, 1371.398926),
	},
	{
		Min = 2700,
		Max = 3000,
		Quest = "SubmergedQuest3",
		Stage = 2,
		Name = "Grand Devotee",
		Mob = "Grand Devotee",
		Count = 8,
		NPC = Vector3.new(9636.642578, -1992.420532, 9611.206055),
		MobPos = Vector3.new(9615.085938, -1993.446533, 9928.485352),
		TeleportNpc = Vector3.new(-16270.290039, 25.253189, 1371.398926),
	},
}

local ELITE_HUNTER_SPAWNS = {
	["Port Town"] = {
		Vector3.new(-1402.016968, 151.991837, 7390.711914),
	},
	["Great Tree"] = {
		Vector3.new(2581.156250, 567.870239, -8267.071289),
		Vector3.new(4324.608398, 565.870239, -6157.793457),
	},
	["Floating Turtle"] = {
		Vector3.new(-11246.158203, 707.750793, -6791.939941),
		Vector3.new(-13938.369141, 382.470673, -9429.875977),
		Vector3.new(-13658.867188, 401.710175, -10171.397461),
		Vector3.new(-11861.125000, 457.982635, -10356.706055),
		Vector3.new(-12436.410156, 334.147888, -9556.802734),
		Vector3.new(-10812.706055, 453.498596, -9742.287109),
		Vector3.new(-11550.122070, 639.300781, -8892.951172),
	},
	["Hydra Island"] = {
		Vector3.new(7074.438477, 246.463486, -423.873932),
		Vector3.new(4395.399902, 1241.267212, 150.202194),
		Vector3.new(6268.424316, 76.489922, 2101.233398),
		Vector3.new(5846.037109, 63.953339, 2312.996338),
	},
}

local IslandProximity = {
	["Port Town"] = "Hydra Island",
	["Great Tree"] = "Hydra Island",
	["Castle on the Sea"] = "Floating Turtle",
	["Haunted Castle"] = "Tiki Outpost",
	["Sea of Treats"] = "Floating Turtle",
	["Submerged Island"] = "Tiki Outpost",
}

local FightingStyleNPC = {
	["Godhuman"] = Vector3.new(-13774.933594, 334.685089, -9878.292969),
}

selectedBossName = BOSSES[1] and BOSSES[1].Name or nil

local function GetMobProfileByName(mobName)
	if not mobName then
		return nil
	end
	local nameLower = string.lower(mobName)

	for _, sea in ipairs({ SEA1, SEA2, SEA3 }) do
		if sea then
			for _, profile in ipairs(sea) do
				if profile.Mob and string.lower(profile.Mob) == nameLower then
					return profile
				end
			end
		end
	end
	return nil
end

local function GetCharacter()
	return player.Character
end
local function GetHumanoid()
	return GetCharacter() and GetCharacter():FindFirstChildOfClass("Humanoid")
end

local function GetPlayerLevel()
	local data = player:FindFirstChild("Data")
	local levelObj = data and data:FindFirstChild("Level")
	return levelObj and levelObj.Value or 1
end

local isNoclipping = false

local function ToggleFloat(state)
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	local humanoid = GetHumanoid()
	if not hrp then
		return
	end

	isNoclipping = state

	if state then
		if humanoid then
			humanoid:ChangeState(11)
		end
		if not hrp:FindFirstChild("BodyClip") then
			local bv = Instance.new("BodyVelocity")
			bv.Name = "BodyClip"
			bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bv.Velocity = Vector3.zero
			bv.Parent = hrp

			local bg = Instance.new("BodyGyro")
			bg.Name = "BodyGyroClip"
			bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			bg.P = 100000
			bg.D = 1000
			bg.CFrame = hrp.CFrame
			bg.Parent = hrp
		end
	else
		if activeTween then
			return
		end
		if hrp:FindFirstChild("BodyClip") then
			hrp.BodyClip:Destroy()
		end
		if hrp:FindFirstChild("BodyGyroClip") then
			hrp.BodyGyroClip:Destroy()
		end
	end
end

local function GetCurrentSea()
	local sea = nil
	pcall(function()
		local Realm = require(game:GetService("ReplicatedStorage").Util.Realm)
		if Realm and Realm.safeGetCurrentSeaAsync then
			sea = Realm.safeGetCurrentSeaAsync()
		end
	end)
	if not sea then
		pcall(function()
			local map = workspace:GetAttribute("MAP") or workspace:GetAttribute("Map")
			if map then
				sea = tostring(map)
			end
		end)
	end
	local sLower = string.lower(tostring(sea or ""))
	if string.find(sLower, "sea3") or string.find(sLower, "third") or string.find(sLower, "3") then
		return "Sea3", 3
	elseif string.find(sLower, "sea2") or string.find(sLower, "second") or string.find(sLower, "2") then
		return "Sea2", 2
	elseif string.find(sLower, "sea1") or string.find(sLower, "first") or string.find(sLower, "1") then
		return "Sea1", 1
	end

	local level = GetPlayerLevel()
	if level >= 1500 then
		return "Sea3", 3
	elseif level >= 700 then
		return "Sea2", 2
	else
		return "Sea1", 1
	end
end

local hasPortalAccess = nil
local function CheckPortalAccess()
	if hasPortalAccess ~= nil then
		return hasPortalAccess
	end
	local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
		and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
	if CommF_ then
		local success, result = pcall(function()
			return CommF_:InvokeServer("GetUnlockables")
		end)
		if success and type(result) == "table" then
			hasPortalAccess = result.DefeatedIndraTrueForm == true
		end
	end
	if hasPortalAccess == nil then
		hasPortalAccess = false
	end
	return hasPortalAccess
end

local function GetBestRoute(startPos, targetPos)
	if startPos.Y < -500 or targetPos.Y < -500 then
		return nil
	end

	if not cfg.UsePortal then
		print("[Portal Debug]: Portal bypass disabled in cfg.UsePortal")
		return nil
	end

	if cfg.lastPortalInvokeAt and (os.clock() - cfg.lastPortalInvokeAt < 3) then
		return nil
	end

	local seaName, seaNum = GetCurrentSea()
	if seaNum ~= 3 then
		print("[Portal Debug]: Not Sea 3 (Detected = " .. tostring(seaName) .. ")")
		return nil
	end
	if not CheckPortalAccess() then
		print("[Portal Debug]: CheckPortalAccess returned false/nil (DefeatedIndraTrueForm not unlocked)")
		return nil
	end
	local isActuallyInRaid = player:GetAttribute("IslandRaiding") or false
	local currLoc = tostring(player:GetAttribute("CurrentLocation") or "")
	if isActuallyInRaid or string.match(currLoc, "Island%s*%d+") then
		print("[Portal Debug]: Player actively in Island Raid (" .. currLoc .. ")")
		return nil
	end

	local distDirect = (startPos - targetPos).Magnitude
	if distDirect < 2500 then
		return nil
	end

	local greatTreePos = Vector3.new(3400, 560, -7200)
	if (targetPos - greatTreePos).Magnitude < 4000 or (startPos - greatTreePos).Magnitude < 4000 then
		return nil
	end

	local CastlePos = Sea3Portals.Turtle.Inner
	local hubs = {
		Castle = CastlePos,
		Turtle = Sea3Portals.Turtle.Outer,
		Hydra = Sea3Portals.Hydra.Outer,
		Tiki = Sea3Portals.Tiki.Outer,
	}

	local closestHub = nil
	local minDistToTarget = math.huge
	for name, pos in pairs(hubs) do
		local d = (pos - targetPos).Magnitude
		if d < minDistToTarget then
			minDistToTarget = d
			closestHub = name
		end
	end

	if (minDistToTarget + 600) >= distDirect then
		return nil
	end

	local curLoc = tostring(player:GetAttribute("CurrentLocation") or "")
	local exactLoc = tostring(player:GetAttribute("ExactLocation") or "")
	local locStr = string.lower(curLoc .. " " .. exactLoc)

	local isAtSeaCastle = false
	if string.find(locStr, "castle on the sea") ~= nil then
		isAtSeaCastle = true
	elseif (startPos - CastlePos).Magnitude < 1500 then
		isAtSeaCastle = true
	end

	local isAtTurtle = (
		string.find(locStr, "floating turtle") ~= nil
		or string.find(locStr, "turtle") ~= nil
		or string.find(locStr, "mansion") ~= nil
	) or (startPos - Sea3Portals.Turtle.Outer).Magnitude < 5500
	local isAtTiki = (string.find(locStr, "tiki") ~= nil) or (startPos - Sea3Portals.Tiki.Outer).Magnitude < 3500
	local isAtHydra = (string.find(locStr, "hydra") ~= nil) or (startPos - Sea3Portals.Hydra.Outer).Magnitude < 3500

	if isAtTurtle and (targetPos - Sea3Portals.Turtle.Outer).Magnitude < 5500 then
		return nil
	end

	print(
		string.format(
			"[Portal Debug]: Target Hub: %s (Dist: %d) | Current Hubs: (SeaCastle:%s, Tiki:%s, Turtle:%s, Hydra:%s) | Loc: %s",
			tostring(closestHub),
			math.floor(minDistToTarget),
			tostring(isAtSeaCastle),
			tostring(isAtTiki),
			tostring(isAtTurtle),
			tostring(isAtHydra),
			locStr
		)
	)

	if
		(closestHub == "Castle" and isAtSeaCastle)
		or (closestHub == "Tiki" and isAtTiki)
		or (closestHub == "Turtle" and isAtTurtle)
		or (closestHub == "Hydra" and isAtHydra)
	then
		print(
			"[Portal Debug]: Already at the closest hub ("
				.. tostring(closestHub)
				.. "), tweening remaining distance..."
		)
		return nil
	end

	if not (isAtSeaCastle or isAtTiki or isAtTurtle or isAtHydra) then
		local myClosestHub = nil
		local myMinDist = math.huge
		for name, pos in pairs(hubs) do
			local d = (startPos - pos).Magnitude
			if d < myMinDist then
				myMinDist = d
				myClosestHub = name
			end
		end
		local estimatedPortalDist = myMinDist + 600 + (hubs[closestHub] - targetPos).Magnitude
		if estimatedPortalDist < distDirect then
			return {
				Type = "Intermediate",
				CFrame = CFrame.new(hubs[myClosestHub] + Vector3.new(0, 300, 0)),
				Name = "Tween to nearest hub: " .. myClosestHub,
			}
		else
			return nil
		end
	end

	if closestHub == "Tiki" then
		if isAtSeaCastle then
			return { Type = "CastleToTiki", Name = "Sea Castle -> Tiki Outpost (BoatTeleport)" }
		elseif isAtTurtle then
			return {
				Type = "Entrance",
				TargetInvoke = Sea3Portals.Turtle.Outer,
				Name = "Floating Turtle (Outer) -> Sea Castle",
			}
		elseif isAtHydra then
			return {
				Type = "Entrance",
				TargetInvoke = Sea3Portals.Hydra.Outer,
				Name = "Hydra Island (Outer) -> Sea Castle",
			}
		end
	elseif closestHub == "Castle" then
		if isAtTiki then
			return { Type = "TikiToCastle", Name = "Tiki Outpost -> Sea Castle (BoatTeleport)" }
		elseif isAtTurtle then
			return {
				Type = "Entrance",
				TargetInvoke = Sea3Portals.Turtle.Outer,
				Name = "Floating Turtle (Outer) -> Sea Castle",
			}
		elseif isAtHydra then
			return {
				Type = "Entrance",
				TargetInvoke = Sea3Portals.Hydra.Outer,
				Name = "Hydra Island (Outer) -> Sea Castle",
			}
		end
	elseif closestHub == "Turtle" then
		if isAtSeaCastle then
			return {
				Type = "Entrance",
				TargetInvoke = Sea3Portals.Turtle.Inner,
				Name = "Sea Castle (Inner) -> Floating Turtle",
			}
		elseif isAtTiki then
			return { Type = "TikiToCastle", Name = "Tiki Outpost -> Sea Castle (BoatTeleport)" }
		elseif isAtHydra then
			return {
				Type = "Entrance",
				TargetInvoke = Sea3Portals.Hydra.Outer,
				Name = "Hydra Island (Outer) -> Sea Castle",
			}
		end
	elseif closestHub == "Hydra" then
		if isAtSeaCastle then
			return {
				Type = "Entrance",
				TargetInvoke = Sea3Portals.Hydra.Inner,
				Name = "Sea Castle (Inner) -> Hydra Island",
			}
		elseif isAtTiki then
			return { Type = "TikiToCastle", Name = "Tiki Outpost -> Sea Castle (BoatTeleport)" }
		elseif isAtTurtle then
			return {
				Type = "Entrance",
				TargetInvoke = Sea3Portals.Turtle.Outer,
				Name = "Floating Turtle (Outer) -> Sea Castle",
			}
		end
	end

	return nil
end

local function TweenTo(targetCFrame)
	if isTeleporting then
		return
	end

	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local targetPos = targetCFrame.Position

	local isCurrentlySubmerged = (player:GetAttribute("ExactLocation") == "Submerged Island") or (hrp.Position.Y < -500)

	if isCurrentlySubmerged and targetPos.Y > -500 then
		local exitPos = Vector3.new(11427.093750, -2154.981934, 9729.259766)
		local distToExitNpc = (hrp.Position - exitPos).Magnitude
		if distToExitNpc > 30 then
			targetPos = exitPos
			targetCFrame = CFrame.new(exitPos)
		else
			if not cfg.lastSubmergedExitAt or (os.clock() - cfg.lastSubmergedExitAt > 3) then
				cfg.lastSubmergedExitAt = os.clock()
				task.spawn(function()
					isTeleporting = true
					print("[Submerged Exit]: Initiating teleport to Tiki Outpost...")
					pcall(function()
						local netModule = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
							and game:GetService("ReplicatedStorage").Modules:FindFirstChild("Net")
						if netModule then
							local Net = require(netModule)
							local rf = Net and Net.RemoteFunction and Net:RemoteFunction("SubmarineTransportation")
							if rf then
								rf:InvokeServer("InitiateTeleport", "Tiki Outpost")
							end
						end
					end)
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Modules.Net
							:FindFirstChild("RF/SubmarineTransportation") or game:GetService("ReplicatedStorage").Modules.Net["RF/SubmarineTransportation"]
						if Event then
							Event:InvokeServer("InitiateTeleport", "Tiki Outpost")
						end
					end)

					local t = 0
					local startPos = hrp.Position
					while t < 25 do
						t = t + 1
						task.wait(0.1)
						local currChar = GetCharacter()
						local currHrp = currChar and currChar:FindFirstChild("HumanoidRootPart")
						local currLoc = player:GetAttribute("ExactLocation")
						if currHrp and (currHrp.Position - startPos).Magnitude > 500 then
							task.wait(0.8)
							break
						elseif currLoc and currLoc ~= "Submerged Island" then
							task.wait(0.8)
							break
						end
					end

					local freshHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
					if freshHrp then
						freshHrp.CFrame = freshHrp.CFrame
						task.wait(0.2)
						isTeleporting = false
						TweenTo(targetCFrame)
					else
						isTeleporting = false
					end
				end)
			end
			return
		end
	end

	if
		not isCurrentlySubmerged
		and targetPos.Y <= -500
		and (targetPos - Vector3.new(11427.093750, -2154.981934, 9729.259766)).Magnitude < 5000
	then
		local enterPos = Vector3.new(-16270.290039, 25.253189, 1371.398926)
		local distToEnterNpc = (hrp.Position - enterPos).Magnitude
		if distToEnterNpc > 35 then
			targetPos = enterPos
			targetCFrame = CFrame.new(enterPos)
		else
			if not cfg.lastSubmergedEnterAt or (os.clock() - cfg.lastSubmergedEnterAt > 5) then
				cfg.lastSubmergedEnterAt = os.clock()
				task.spawn(function()
					isTeleporting = true
					print("[Submerged Enter]: Invoking TravelToSubmergedIsland at Tiki Outpost...")
					pcall(function()
						game:GetService("ReplicatedStorage").Modules.Net
							:WaitForChild("RF/SubmarineWorkerSpeak")
							:InvokeServer("TravelToSubmergedIsland")
					end)

					local t = 0
					local startPos = hrp.Position
					while t < 25 do
						t = t + 1
						task.wait(0.1)
						local currChar = GetCharacter()
						local currHrp = currChar and currChar:FindFirstChild("HumanoidRootPart")
						local currLoc = player:GetAttribute("ExactLocation")
						if currHrp and (currHrp.Position - startPos).Magnitude > 500 then
							task.wait(0.8)
							break
						elseif currLoc == "Submerged Island" then
							task.wait(0.8)
							break
						end
					end

					local freshHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
					if freshHrp then
						freshHrp.CFrame = freshHrp.CFrame
						task.wait(0.2)
						isTeleporting = false
						TweenTo(targetCFrame)
					else
						isTeleporting = false
					end
				end)
			end
			return
		end
	end

	if cfg.UsePortal then
		local route = GetBestRoute(hrp.Position, targetPos)

		if route then
			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end

			if route.Type == "Intermediate" then
				print("[Portal Debug]: " .. tostring(route.Name))
				targetCFrame = route.CFrame
				targetPos = targetCFrame.Position
			else
				task.spawn(function()
					isTeleporting = true

					if activeTween then
						activeTween:Cancel()
						activeTween = nil
					end
					hrp.AssemblyLinearVelocity = Vector3.zero

					cfg.lastPortalInvokeAt = os.clock()
					local startLocation = player:GetAttribute("ExactLocation")
					local startPos = hrp.Position

					if route.Type == "TikiToCastle" then
						print("[Portal Debug]: Invoking BoatCastleTeleporters to Sea Castle...")
						pcall(function()
							local teleEvent =
								game:GetService("ReplicatedStorage").Modules.Net["RF/BoatCastleTeleporters"]
							local targetObj = workspace:FindFirstChild("Map")
								and workspace.Map:FindFirstChild("TikiOutpost")
								and workspace.Map.TikiOutpost:FindFirstChild("MapTeleportC")
							if not targetObj and workspace:FindFirstChild("Map") then
								targetObj = workspace.Map:FindFirstChild("MapTeleportC", true)
							end
							if targetObj and teleEvent then
								local ok, res = pcall(function()
									return teleEvent:InvokeServer("InitiateTeleport", targetObj)
								end)
								task.wait(0.2)
								print(
									"[Portal Debug]: TikiToCastle result -> success: "
										.. tostring(ok)
										.. ", res: "
										.. tostring(res)
								)
							else
								print("[Portal Debug]: TikiOutpost.MapTeleportC not found!")
							end
						end)
					elseif route.Type == "CastleToTiki" then
						print("[Portal Debug]: Invoking BoatCastleTeleporters to Tiki Outpost...")
						pcall(function()
							local teleEvent =
								game:GetService("ReplicatedStorage").Modules.Net["RF/BoatCastleTeleporters"]
							local targetObj = nil
							local map = workspace:FindFirstChild("Map")
							if
								map
								and map:FindFirstChild("Boat Castle")
								and map["Boat Castle"]:FindFirstChild("MapTeleportC")
							then
								targetObj = map["Boat Castle"].MapTeleportC
							elseif map then
								targetObj = map:FindFirstChild("MapTeleportC", true)
							end

							if not targetObj and getnilinstances then
								for _, Object in ipairs(getnilinstances()) do
									if Object.Name == "MapTeleportC" then
										targetObj = Object
										break
									end
								end
							end

							if targetObj and teleEvent then
								local ok, res = pcall(function()
									return teleEvent:InvokeServer("InitiateTeleport", targetObj)
								end)
								task.wait(0.2)
								print(
									"[Portal Debug]: BoatCastleTeleporters (CastleToTiki) result -> success: "
										.. tostring(ok)
										.. ", res: "
										.. tostring(res)
								)
							else
								print("[Portal Debug]: Boat Castle MapTeleportC instance not found!")
							end
						end)
					else
						print("[Portal Debug]: Invoking requestEntrance -> " .. tostring(route.TargetInvoke))
						local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
							and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
						if CommF_ then
							local res = nil
							local ok, err = pcall(function()
								res = CommF_:InvokeServer("requestEntrance", route.TargetInvoke)
							end)
							task.wait(0.2)
							print(
								"[Portal Debug]: Invoke result -> success: "
									.. tostring(ok)
									.. ", res: "
									.. tostring(res)
									.. ", err: "
									.. tostring(err)
							)
						else
							print("[Portal Debug]: Remote CommF_ not found!")
						end
					end

					local t = 0
					while t < 25 do
						t = t + 1
						task.wait(0.1)
						local currChar = GetCharacter()
						local currHrp = currChar and currChar:FindFirstChild("HumanoidRootPart")
						local currLoc = player:GetAttribute("ExactLocation")
						if currHrp and (currHrp.Position - startPos).Magnitude > 500 then
							print(
								"[Portal Debug]: Position jump detected! Distance jumped: "
									.. tostring(math.floor((currHrp.Position - startPos).Magnitude))
							)
							task.wait(0.8)
							break
						elseif currLoc ~= startLocation then
							print("[Portal Debug]: ExactLocation change detected! New: " .. tostring(currLoc))
							task.wait(0.8)
							break
						end
					end

					print(
						"[Portal Debug]: Portal transition finished after "
							.. tostring(t * 0.1)
							.. "s. New ExactLocation: "
							.. tostring(player:GetAttribute("ExactLocation"))
					)
					cfg.lastPortalInvokeAt = os.clock()

					if activeTween then
						activeTween:Cancel()
						activeTween = nil
					end
					lastTargetPos = nil

					local freshHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
					if freshHrp then
						freshHrp.AssemblyLinearVelocity = Vector3.zero
						freshHrp.CFrame = freshHrp.CFrame
						task.wait(0.3)
						isTeleporting = false

						TweenTo(targetCFrame)
					else
						isTeleporting = false
					end
				end)
				return
			end
		end
	end

	local distance = (hrp.Position - targetPos).Magnitude

	ToggleFloat(true)

	if lastTargetPos and (targetPos - lastTargetPos).Magnitude < 2 then
		if activeTween then
			return
		end
	end

	if isTeleporting then
		return
	end

	lastTargetPos = targetPos

	local tweenSpeed = cfg.TweenSpeed
	local duration = math.max(distance / tweenSpeed, 0.05)

	if activeTween then
		activeTween:Cancel()
	end

	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end

	local bg = hrp:FindFirstChild("BodyGyroClip")
	if bg then
		bg.CFrame = targetCFrame
	end

	activeTween = TweenService:Create(
		hrp,
		TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{ CFrame = targetCFrame }
	)

	local currentTween = activeTween
	currentTween.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed and activeTween == currentTween then
			activeTween:Cancel()
			activeTween = nil
		end
	end)

	activeTween:Play()
end

local function SafeTouch(targetPart, hrp, overrideDistance)
	if not targetPart or not hrp then
		return
	end
	local dist = (hrp.Position - targetPart.Position).Magnitude
	local triggerDist = overrideDistance or 10

	if hasFireTouch then
		if dist <= triggerDist then
			firetouchinterest(hrp, targetPart, 0)
			task.wait(0.05)
			firetouchinterest(hrp, targetPart, 1)
			return true
		end
	else
		if dist > 8 then
			TweenTo(CFrame.new(targetPart.Position))
		else
			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end
			hrp.CFrame = CFrame.new(targetPart.Position)
			task.wait(0.1)
			return true
		end
	end
	return false
end

local function SafeProximity(prompt)
	local proximityPrompt = nil
	if prompt:IsA("ProximityPrompt") then
		proximityPrompt = prompt
	elseif prompt:IsA("BasePart") or prompt:IsA("Model") then
		local child = prompt:FindFirstChildOfClass("ProximityPrompt")
		if child then
			proximityPrompt = child
		else
			local children = prompt:GetChildren()
			for _, v in ipairs(children) do
				if v:IsA("ProximityPrompt") then
					proximityPrompt = v
					break
				end
			end
		end
	end

	if hasProximity then
		if proximityPrompt then
			fireproximityprompt(proximityPrompt)
		end
	else
		local key = prompt.KeyboardKeyCode ~= Enum.KeyCode.Unknown and prompt.KeyboardKeyCode or Enum.KeyCode.E
		VirtualInputManager:SendKeyEvent(true, key, false, game)
		task.wait(prompt.HoldDuration > 0 and prompt.HoldDuration or 0.1)
		VirtualInputManager:SendKeyEvent(false, key, false, game)
	end
end

local function GetIslandLocations()
	local islandList = {}
	local origin = workspace:FindFirstChild("_WorldOrigin")
	local locations = origin and origin:FindFirstChild("Locations")
	if locations then
		for _, loc in ipairs(locations:GetChildren()) do
			if loc:IsA("BasePart") or loc:IsA("Model") then
				table.insert(islandList, loc.Name)
			end
		end
	end
	table.sort(islandList)
	if #islandList == 0 then
		table.insert(islandList, "No islands found (Error)")
	end
	return islandList
end

local function GetNearestIsland()
	local islands = {}
	for _, obj in pairs(Workspace:GetChildren()) do
		if obj.Name:find("Island") and obj:FindFirstChild("HumanoidRootPart") then
			table.insert(islands, obj)
		end
	end
	local nearestIsland = nil
	local shortestDistance = math.huge
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	if hrp then
		for _, island in pairs(islands) do
			local pos = nil
			if island:IsA("Model") then
				pos = island.PrimaryPart.Position or island:GetBoundingBox().Position
			elseif island:IsA("BasePart") then
				pos = island.Position
			end
			local distance = (hrp.Position - pos).Magnitude
			if distance < shortestDistance then
				shortestDistance = distance
				nearestIsland = island
			end
		end
	end
	return nearestIsland
end

local function CreateIslandESP(islandName, color)
	task.spawn(function()
		while true do
			task.wait(1)
			local origin = workspace:FindFirstChild("_WorldOrigin")
			local locations = origin and origin:FindFirstChild("Locations")
			if locations then
				for _, loc in ipairs(locations:GetChildren()) do
					if loc.Name == islandName then
						if not loc:FindFirstChild("ESP_UI") then
							local bg = Instance.new("BillboardGui")
							bg.Name = "ESP_UI"
							bg.AlwaysOnTop = true
							bg.Size = UDim2.new(0, 200, 0, 50)
							bg.StudsOffset = Vector3.new(0, 50, 0)
							local tl = Instance.new("TextLabel")
							tl.Size = UDim2.new(1, 0, 1, 0)
							tl.BackgroundTransparency = 1
							tl.TextColor3 = color
							tl.TextStrokeTransparency = 0.5
							tl.TextSize = 14
							tl.Font = Enum.Font.Code
							tl.Parent = bg
							bg.Parent = loc
						end

						local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
						if hrp and loc:FindFirstChild("ESP_UI") then
							local dist = (hrp.Position - loc.Position).Magnitude
							loc.ESP_UI.TextLabel.Text = string.format("%s\n[%d M]", islandName, math.floor(dist / 3))
						end
					end
				end
			end
		end
	end)
end

local function HandleESP(folderOrList, espName, color, toggleVarName)
	task.spawn(function()
		while task.wait(1) do
			if not getgenv()[toggleVarName] then
				pcall(function()
					local list = type(folderOrList) == "function" and folderOrList() or folderOrList:GetChildren()
					for _, obj in ipairs(list) do
						local ui = obj:FindFirstChild(espName)
						if ui then
							ui:Destroy()
						end
					end
				end)
			else
				pcall(function()
					local list = type(folderOrList) == "function" and folderOrList() or folderOrList:GetChildren()
					for _, obj in ipairs(list) do
						if obj ~= game.Players.LocalPlayer.Character then
							local hrp = obj:FindFirstChild("HumanoidRootPart")
								or (obj:IsA("BasePart") and obj)
								or obj:FindFirstChildWhichIsA("BasePart")
							if hrp then
								local ui = obj:FindFirstChild(espName)
								if not ui then
									ui = Instance.new("BillboardGui")
									ui.Name = espName
									ui.AlwaysOnTop = true
									ui.Size = UDim2.new(0, 200, 0, 50)
									ui.StudsOffset = Vector3.new(0, 5, 0)
									local tl = Instance.new("TextLabel")
									tl.Size = UDim2.new(1, 0, 1, 0)
									tl.BackgroundTransparency = 1
									tl.TextColor3 = color
									tl.TextStrokeTransparency = 0.5
									tl.TextSize = 14
									tl.Font = Enum.Font.Code
									tl.Parent = ui
									ui.Parent = obj
								end

								local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
								if myHrp then
									local dist = (myHrp.Position - hrp.Position).Magnitude
									ui.TextLabel.Text = string.format("%s\n[%d M]", obj.Name, math.floor(dist / 3))
								end
							end
						end
					end
				end)
			end
		end
	end)
end

local function GetBoat()
	if not workspace:FindFirstChild("Boats") then
		return nil
	end

	local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	if not myHrp then
		return nil
	end

	local myBoat = nil
	local shortestDistance = math.huge

	for _, boat in ipairs(workspace.Boats:GetChildren()) do
		local seat = boat:FindFirstChild("VehicleSeat")
		local ownerVal = boat:FindFirstChild("Owner")

		if seat and ownerVal then
			local isMine = false
			if ownerVal:IsA("ObjectValue") and ownerVal.Value == player then
				isMine = true
			elseif ownerVal:IsA("StringValue") and ownerVal.Value == player.Name then
				isMine = true
			elseif tostring(ownerVal.Value) == player.Name then
				isMine = true
			end

			if isMine then
				local distance = (myHrp.Position - seat.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					myBoat = boat
				end
			end
		end
	end

	return myBoat
end

local function GetNearestBoatDealer()
	local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	if not myHrp then
		return nil
	end

	local npcsFolder = workspace:FindFirstChild("NPCs")
	if not npcsFolder then
		return nil
	end

	local nearestDealer = nil
	local shortestDist = math.huge

	for _, npc in ipairs(npcsFolder:GetChildren()) do
		if npc.Name == "Boat Dealer" or npc.Name == "Luxury Boat Dealer" then
			local npcPos = GetSafePosition(npc)
			if npcPos ~= Vector3.zero then
				local dist = (myHrp.Position - npcPos).Magnitude
				if dist < shortestDist then
					shortestDist = dist
					nearestDealer = npc
				end
			end
		end
	end

	return nearestDealer
end

local lastBuyAttempt = 0
local function BuyBoat()
	local success = false

	if os.clock() - lastBuyAttempt < 2 then
		return false
	end

	pcall(function()
		local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
			and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
		if CommF_ then
			local result = CommF_:InvokeServer("BuyBoat", cfg.boatType)
			if result == nil or result == false then
				CommF_:InvokeServer("BuyBoat", "Dinghy")
			end
			lastBuyAttempt = os.clock()
			success = true
		end
	end)
	return success
end

local function BoardBoat(boat)
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	local hum = GetHumanoid()
	if boat and boat:FindFirstChild("VehicleSeat") and hrp and hum then
		local seat = boat.VehicleSeat
		local distance = (hrp.Position - seat.Position).Magnitude

		if distance < 10 then
			if not hum.Sit then
				hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
				task.wait(0.1)
				seat:Sit(hum)
			end
		else
			TweenTo(CFrame.new(seat.Position + Vector3.new(0, 5, 0), seat.Position))
		end
	end
	return false
end

local function DodgeAttack()
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	if os.clock() - lastDodgeTime < cfg.dodgeCooldown then
		return
	end

	for _, obj in pairs(Workspace:GetChildren()) do
		if obj.Name:find("Projectile") or obj.Name:find("Bullet") then
			local distance = (hrp.Position - obj.Position).Magnitude
			if distance < 20 then
				local dodgeDirection = (hrp.Position - obj.Position).Unit * cfg.dodgeDistance
				local newPosition = hrp.Position + dodgeDirection
				hrp.CFrame = CFrame.new(newPosition)
				lastDodgeTime = os.clock()
				break
			end
		end
	end
end

local function ScanForFruits()
	fruitWaypoints = {}
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	if hrp then
		for _, obj in pairs(Workspace:GetChildren()) do
			if obj.Name:find("Fruit") and obj:FindFirstChild("Handle") then
				local distance = (hrp.Position - obj.Handle.Position).Magnitude
				if distance < cfg.fruitScanRadius then
					table.insert(fruitWaypoints, obj.Handle)
				end
			end
		end
	end
end

local function ScanForChests()
	chestWaypoints = {}
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	local chestModels = Workspace:FindFirstChild("ChestModels")
	if hrp and chestModels then
		for _, chest in ipairs(chestModels:GetChildren()) do
			local targetPart = chest:IsA("Model") and (chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart"))
				or chest
			if targetPart and targetPart:IsA("BasePart") then
				table.insert(chestWaypoints, targetPart)
			end
		end
	end
end

local function CollectNearestFruit()
	if #fruitWaypoints == 0 then
		return false
	end
	local nearestFruit = nil
	local shortestDistance = math.huge
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	local hum = GetHumanoid()
	if hrp and hum then
		for _, fruit in pairs(fruitWaypoints) do
			local distance = (hrp.Position - fruit.Position).Magnitude
			if distance < shortestDistance then
				shortestDistance = distance
				nearestFruit = fruit
			end
		end
		if nearestFruit then
			SafeTouch(hrp, nearestFruit, 50)
			return true
		end
	end
	return false
end

local currentIslandIndex = 1
local function CollectNearestChest()
	ScanForChests()
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	local hum = GetHumanoid()
	if not hrp or not hum then
		return false
	end

	if #chestWaypoints == 0 then
		local originLocations = workspace:FindFirstChild("_WorldOrigin")
			and workspace._WorldOrigin:FindFirstChild("Locations")
		if originLocations then
			local islands = originLocations:GetChildren()
			if #islands > 0 then
				if currentIslandIndex > #islands then
					currentIslandIndex = 1
				end
				local targetLocation = islands[currentIslandIndex]

				if targetLocation then
					local locName = string.lower(targetLocation.Name)
					if
						string.find(locName, "trial")
						or string.find(locName, "secret temple")
						or string.find(locName, "l'église de prophétie")
						or string.find(locName, "???")
						or string.find(locName, "temple of time")
					then
						currentIslandIndex = currentIslandIndex + 1
						if currentIslandIndex > #islands then
							currentIslandIndex = 1
						end
						return false
					end
				end

				if targetLocation and targetLocation:IsA("BasePart") then
					pcall(function()
						local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
						if remote then
							local req = remote:FindFirstChild("RequestStreamAroundAsync")
							if req then
								req:FireServer(targetLocation.Position)
							end
						end
					end)

					local targetCFrame = targetLocation.CFrame * CFrame.new(0, 150, 0)
					TweenTo(targetCFrame)

					if (hrp.Position - targetCFrame.Position).Magnitude < 50 then
						currentIslandIndex = currentIslandIndex + 1
					end
					return true
				end
			end
		end
		return false
	end

	local nearestChest = nil
	local shortestDistance = math.huge
	for _, chest in pairs(chestWaypoints) do
		local distance = (hrp.Position - chest.Position).Magnitude
		if distance < shortestDistance then
			shortestDistance = distance
			nearestChest = chest
		end
	end

	if nearestChest then
		local targetPart = nearestChest:IsA("Model")
				and (nearestChest.PrimaryPart or nearestChest:FindFirstChildWhichIsA("BasePart"))
			or nearestChest
		if targetPart then
			pcall(function()
				local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
				if remote then
					local req = remote:FindFirstChild("RequestStreamAroundAsync")
					if req then
						req:FireServer(targetPart.Position)
					end
				end
			end)

			local dist = (hrp.Position - targetPart.Position).Magnitude
			if dist > 280 then
				TweenTo(targetPart.CFrame)
			else
				if not isCollectingChest then
					isCollectingChest = true
					task.spawn(function()
						if activeTween then
							activeTween:Cancel()
							activeTween = nil
						end

						hrp.CFrame = targetPart.CFrame
						task.wait(0.1)
						isCollectingChest = false
					end)
				end
			end
			return true
		end
	end
	return false
end

local function ServerHop()
	pcall(function()
		if getgenv().LonumObject then
			getgenv().LonumObject:Notify({
				Title = "Server Hop",
				Content = "Looking for a new server, please wait...",
				Duration = 3,
			})
		end
	end)

	local servers = {}
	local req = syn and syn.request or http_request
	if req then
		local res = req({
			Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
			Method = "GET",
		})
		if res and res.StatusCode == 200 then
			local body = HttpService:JSONDecode(res.Body)
			for _, server in pairs(body.data) do
				if server.playing < cfg.maxPlayersForHop and server.id ~= game.JobId then
					table.insert(servers, server.id)
				end
			end
		end
	end

	if #servers > 0 then
		local randomServer = servers[math.random(1, #servers)]
		TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, player)
	else
		TeleportService:Teleport(game.PlaceId, player)
	end
end

local currentQuestPool = {}
local currentPoolIndex = 1
local lastLevelCalculated = -1
local questBracketKey = nil
local lastStartedQuestKey = nil
local lastStartedQuestAt = 0
lastTargetHealth = -1
lastTargetHealthChangeAt = 0

if getgenv then
	if not getgenv().QuestCache then
		getgenv().QuestCache = {
			IsActive = false,
			MobName = nil,
			Current = 0,
			Maximum = 0,
			Finished = false,
			Text = "",
			LastSeen = 0,
		}
	end
else
	_G.QuestCache = _G.QuestCache
		or {
			IsActive = false,
			MobName = nil,
			Current = 0,
			Maximum = 0,
			Finished = false,
			Text = "",
			LastSeen = 0,
		}
end
local QuestCache = getgenv and getgenv().QuestCache or _G.QuestCache

local function GetEligibleBoss()
	local level = GetPlayerLevel()
	local closestBoss = nil
	local minDiff = math.huge

	for _, boss in ipairs(BOSSES) do
		if level >= boss.Min then
			local diff = level - boss.Min
			if diff < minDiff and diff <= 45 then
				minDiff = diff
				closestBoss = boss
			end
		end
	end
	return closestBoss
end

local function GetQuestStatus(targetMobName)
	local success, result = pcall(function()
		local playerGui = player:FindFirstChild("PlayerGui")
		local text = ""
		local progressText = ""
		local descText = ""
		local isQuestVisible = false

		local trackedQuest = playerGui and playerGui:FindFirstChild("TrackedQuestFrame")
		if trackedQuest and trackedQuest.Enabled then
			local frame = trackedQuest:FindFirstChild("Frame")
			if frame and frame.Visible then
				isQuestVisible = true
				local header = frame:FindFirstChild("header")
				local textLabel = header and header:FindFirstChild("textLabel")
				local progressLabel = frame:FindFirstChild("progress")
				local descLabel = frame:FindFirstChild("description")

				text = textLabel and textLabel.Text or ""
				progressText = progressLabel and progressLabel.Text or ""
				descText = descLabel and descLabel.Text or ""
			end
		end

		if not isQuestVisible then
			local questContainer = playerGui
				and playerGui:FindFirstChild("Main")
				and playerGui.Main:FindFirstChild("Quest")
			local titleObj = questContainer
				and questContainer:FindFirstChild("Container")
				and questContainer.Container:FindFirstChild("QuestTitle")
				and questContainer.Container.QuestTitle:FindFirstChild("Title")

			if questContainer and questContainer.Visible then
				text = titleObj and titleObj.Text or ""
				if text ~= "" then
					isQuestVisible = true
					progressText = text
				end
			end
		end

		if isQuestVisible and (text ~= "" or progressText ~= "") then
			local current, maximum = string.match(progressText, "(%d+)%s*/%s*(%d+)")
			if not current then
				current, maximum = string.match(text, "(%d+)%s*/%s*(%d+)")
			end

			local actualMob = nil
			local checkString = string.lower(text .. " " .. descText)

			if currentQuestPool and #currentQuestPool > 0 then
				for _, quest in ipairs(currentQuestPool) do
					if quest.Mob and string.find(checkString, string.lower(quest.Mob), 1, true) then
						actualMob = quest.Mob
						break
					end
				end
			end

			if not actualMob and targetMobName and string.find(checkString, string.lower(targetMobName), 1, true) then
				actualMob = targetMobName
			end

			if not actualMob and descText ~= "" then
				actualMob = descText
			end

			if not actualMob then
				actualMob = targetMobName
					or (currentQuestPool and currentQuestPool[1] and currentQuestPool[1].Mob)
					or "ActiveQuest"
			end

			QuestCache.MobName = actualMob
			QuestCache.Current = tonumber(current) or 0
			QuestCache.Maximum = tonumber(maximum) or 0
			QuestCache.Finished = (QuestCache.Maximum > 0 and QuestCache.Current >= QuestCache.Maximum)
			QuestCache.Text = text
			QuestCache.LastSeen = tick()
			QuestCache.IsActive = true
		else
			QuestCache.IsActive = false
			QuestCache.Finished = false
		end

		local correct = targetMobName
			and QuestCache.IsActive
			and (
				string.lower(QuestCache.MobName) == string.lower(targetMobName)
				or string.find(string.lower(text .. " " .. descText), string.lower(targetMobName), 1, true) ~= nil
			)

		return {
			Active = QuestCache.IsActive,
			Correct = correct == true,
			Finished = QuestCache.Finished,
			Text = QuestCache.Text,
			MobName = QuestCache.MobName,
			Current = QuestCache.Current,
			Maximum = QuestCache.Maximum,
		}
	end)

	if success and result then
		return result
	end

	return { Active = false, Correct = false, Finished = false, Text = "", MobName = nil, Current = 0, Maximum = 0 }
end

local function GetQuestProfile()
	local level = GetPlayerLevel()
	local list = nil

	local seaName, seaNum = GetCurrentSea()
	if seaNum == 1 then
		list = SEA1
	elseif seaNum == 2 then
		list = SEA2
	elseif seaNum == 3 then
		list = SEA3
	else
		list = (level >= 1500) and SEA3 or (level >= 700) and SEA2 or SEA1
	end

	if not list or #list == 0 then
		return nil
	end

	local highestQuest = nil
	for _, p in ipairs(list) do
		if level >= p.Min then
			if
				not highestQuest
				or p.Min > highestQuest.Min
				or (p.Min == highestQuest.Min and p.Stage > highestQuest.Stage)
			then
				highestQuest = p
			end
		end
	end

	if not highestQuest then
		return list[1]
	end

	local bracketKey = tostring(highestQuest.Min) .. ":" .. tostring(highestQuest.Max)

	if level ~= lastLevelCalculated or questBracketKey ~= bracketKey then
		lastLevelCalculated = level
		questBracketKey = bracketKey
		QuestCache.IsActive = false
		QuestCache.Finished = false
		QuestCache.MobName = nil
		QuestCache.LastSeen = 0
		currentPoolIndex = 1
		currentQuestPool = {}

		for _, p in ipairs(list) do
			local sameHighestNpc = p.NPC == highestQuest.NPC and level >= p.Min
			local sameExactBracket = p.Min == highestQuest.Min and p.Max == highestQuest.Max

			if sameHighestNpc or sameExactBracket then
				table.insert(currentQuestPool, p)
			end
		end

		local deduped = {}
		local seen = {}
		for _, p in ipairs(currentQuestPool) do
			local key = tostring(p.Quest) .. "|" .. tostring(p.Stage) .. "|" .. tostring(p.Mob)
			if not seen[key] then
				seen[key] = true
				table.insert(deduped, p)
			end
		end
		currentQuestPool = deduped

		table.sort(currentQuestPool, function(a, b)
			if a.Min ~= b.Min then
				return a.Min > b.Min
			end
			if a.Stage ~= b.Stage then
				return a.Stage > b.Stage
			end
			return tostring(a.Quest) < tostring(b.Quest)
		end)

		for i, quest in ipairs(currentQuestPool) do
			local status = GetQuestStatus(quest.Mob)
			if status.Active and status.Correct then
				currentPoolIndex = i
				break
			end
		end
	end

	if #currentQuestPool == 0 then
		return highestQuest
	end
	if currentPoolIndex > #currentQuestPool then
		currentPoolIndex = 1
	end

	return currentQuestPool[currentPoolIndex]
end

local function GetQuestProfileKey(profile)
	if not profile then
		return ""
	end
	return table.concat({
		tostring(profile.Quest or ""),
		tostring(profile.Stage or ""),
		tostring(profile.Mob or ""),
		tostring(profile.Min or ""),
		tostring(profile.Max or ""),
	}, "|")
end

local function CycleQuestProfile()
	if #currentQuestPool > 1 then
		currentPoolIndex = (currentPoolIndex % #currentQuestPool) + 1
	end
	lastStartedQuestKey = nil
	lastStartedQuestAt = 0
	lastTargetHealth = -1
	lastTargetHealthChangeAt = 0
	currentTargetInstance = nil
	isReadyToAttack = false
	lastTargetRefreshAt = 0
end

local function HasActiveQuest()
	local status = GetQuestStatus(nil)
	return status.Active
end

local function IsQuestFinished(profile)
	local status = GetQuestStatus(profile and profile.Mob or nil)
	return status.Active and status.Correct and status.Finished
end

local preferredHitParts = {
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
	"UpperTorso",
	"LowerTorso",
	"Head",
	"ModelHitbox",
}
local meleeNames = {
	Combat = true,
	["Dark Step"] = true,
	Electro = true,
	["Water Kung Fu"] = true,
	["Fishman Karate"] = true,
	["Dragon Breath"] = true,
	Superhuman = true,
	["Death Step"] = true,
	["Sharkman Karate"] = true,
	["Electric Claw"] = true,
	["Dragon Talon"] = true,
	Godhuman = true,
	["Sanguine Art"] = true,
}

GetSafePosition = function(instance)
	if not instance then
		return Vector3.zero
	end
	if typeof(instance) == "Vector3" then
		return instance
	end
	if typeof(instance) == "CFrame" then
		return instance.Position
	end

	if instance:IsA("BasePart") then
		return instance.Position
	end

	if instance:IsA("Model") then
		if instance.PrimaryPart then
			return instance.PrimaryPart.Position
		end
		local part = instance:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.Position
		end
		return instance:GetBoundingBox().Position
	end

	local success, pos = pcall(function()
		if instance.Position then
			return instance.Position
		end
		return Vector3.zero
	end)
	if success and pos and pos ~= Vector3.zero then
		return pos
	end
	return Vector3.zero
end

local function StopAllActivities()
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end

	ToggleFloat(false)
	isNoclipping = false

	local c = GetCharacter()
	if c then
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if hrp then
			local bv = hrp:FindFirstChild("AutofarmBv")
			if bv then
				bv:Destroy()
			end
			local bg = hrp:FindFirstChild("AutofarmBg")
			if bg then
				bg:Destroy()
			end
			local bc = hrp:FindFirstChild("BodyClip")
			if bc then
				bc:Destroy()
			end
			local bgc = hrp:FindFirstChild("BodyGyroClip")
			if bgc then
				bgc:Destroy()
			end
		end
		local hum = c:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
			hum:ChangeState(8)
		end
	end

	isReadyToAttack = false
	currentTargetInstance = nil
	lastTargetPos = nil
	cfg.isAutoBerry = false
	cfg.autoBerryWorker = cfg.autoBerryWorker + 1
end

local function GetHitPart(model)
	if not model then
		return nil
	end
	for _, name in ipairs(preferredHitParts) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	local fallbackPart = model:FindFirstChildWhichIsA("BasePart", true)
	if fallbackPart then
		return fallbackPart
	end

	if model:IsA("BasePart") then
		return model
	end

	return nil
end

local function ExpandEnemyHitbox(hitPart)
	if not hitPart or not hitPart:IsA("BasePart") then
		return
	end
	if hitPart:GetAttribute("HitboxExpanded") then
		return
	end

	pcall(function()
		for _, child in ipairs(hitPart:GetChildren()) do
			if child:IsA("Decal") or child:IsA("Texture") or child:IsA("BillboardGui") then
				child:Destroy()
			end
		end

		hitPart.CanCollide = false
		hitPart.Transparency = 1
		hitPart.Massless = true
		hitPart.Size = Vector3.new(22, 20, 22)
		hitPart:SetAttribute("HitboxExpanded", true)
	end)
end

local function IsBossEntity(targetChar)
	if not targetChar then
		return false
	end
	return targetChar:GetAttribute("IsRaidBoss") == true
		or targetChar:GetAttribute("isRaidBoss") == true
		or targetChar:GetAttribute("RaidBoss") == true
		or targetChar:GetAttribute("IsBoss") == true
		or targetChar:GetAttribute("isBoss") == true
		or targetChar:GetAttribute("Boss") == true
		or targetChar.Name == "PropHitboxPlaceholder"
end

local function IsEnemyVulnerable(targetChar, targetMobName)
	if not targetChar then
		return false
	end

	if targetChar.Name == "Blank Buddy" then
		return false
	end

	if targetChar.Name == "PropHitboxPlaceholder" then
		local hasPart = targetChar:FindFirstChildWhichIsA("BasePart", true) or targetChar:IsA("BasePart")
		local hum = targetChar:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health <= 0 then
			return false
		end
		return hasPart ~= nil
	end

	if enemyBlacklist[targetChar] then
		if os.clock() < enemyBlacklist[targetChar] then
			return false
		else
			enemyBlacklist[targetChar] = nil
		end
	end

	if targetMobName and string.lower(targetChar.Name) ~= string.lower(targetMobName) then
		return false
	end

	local hum = targetChar:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then
		return false
	end

	return (
		targetChar:FindFirstChild("HumanoidRootPart")
		or targetChar:FindFirstChild("Head")
		or targetChar:IsA("BasePart")
		or targetChar:FindFirstChildWhichIsA("BasePart", true)
	) ~= nil
end

local spawnDelayTracker, activeMagnetTweens, lastFindAnywhereAt, emptyTargetThrottle, lastMagnetTick =
	setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" }), 0, {}, 0
local function IsEnemyReadyToPull(enemy)
	if not spawnDelayTracker[enemy] then
		spawnDelayTracker[enemy] = os.clock()
		return false
	end
	return (os.clock() - spawnDelayTracker[enemy]) >= 0.3
end

local function UniversalMagnet(targetMobName, gatherPos, myHrpPos)
	local now = os.clock()
	if now - lastMagnetTick < 0.1 then
		return
	end
	lastMagnetTick = now

	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder or not gatherPos or not myHrpPos then
		return
	end

	local distPlayerToMobPos = (myHrpPos - gatherPos).Magnitude

	if distPlayerToMobPos > cfg.BringRadius then
		return
	end

	local gatherCFrame = CFrame.new(gatherPos.X, gatherPos.Y, gatherPos.Z)
	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		local isMatch = false
		if targetMobName then
			isMatch = (string.lower(enemy.Name) == string.lower(targetMobName))
				and IsEnemyVulnerable(enemy, targetMobName)
		else
			isMatch = IsEnemyVulnerable(enemy, nil)
		end

		if isMatch and enemy.Name ~= "PropHitboxPlaceholder" then
			local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
			local eHum = enemy:FindFirstChildOfClass("Humanoid")
			local humanoid = GetHumanoid()
			if not IsEnemyReadyToPull(enemy) then
				eHrp = nil
			end
			if eHrp and eHum and eHum.Health > 0 then
				local distToPlayer = (GetSafePosition(eHrp) - myHrpPos).Magnitude
				if distToPlayer <= cfg.BringRadius then
					if eHrp.CanCollide then
						eHrp.CanCollide = false
					end
					if eHum.PlatformStand == false then
						eHum.PlatformStand = true
					end

					if activeMagnetTweens[eHrp] then
						activeMagnetTweens[eHrp]:Cancel()
						activeMagnetTweens[eHrp] = nil
					end
					eHrp.Massless = true
					eHrp.CFrame = gatherCFrame
				end
			end
		end
	end
end

local function UniversalEvasionTween(myHrp, targetPos, now)
	ToggleFloat(true)
	local targetDistance = (targetPos - myHrp.Position).Magnitude
	if targetDistance > 80 then
		if now - lastEvasionMoveAt >= cfg.EvasionTick then
			lastEvasionMoveAt = now
			TweenTo(CFrame.new(targetPos + Vector3.new(0, cfg.TweenHeight, 0), targetPos))
		end
	else
		TweenTo(CFrame.new(targetPos + currentEvasionOffset, targetPos))
	end
end

local lastQuestClaimAt = 0
local function ClaimQuestHandler(myHrp, profileQuest, profileStage, npcPos)
	isReadyToAttack = false
	currentTargetInstance = nil
	ToggleFloat(true)
	local distToNpc = (myHrp.Position - npcPos).Magnitude
	if distToNpc > 15 then
		TweenTo(CFrame.new(npcPos))
		return false
	end
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
	local now = os.clock()
	if now - lastQuestClaimAt > 1.5 then
		lastQuestClaimAt = now
		local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
			and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
		if CommF_ then
			pcall(function()
				CommF_:InvokeServer("StartQuest", profileQuest, profileStage or 1)
			end)
		end
	end
	return true
end

local function FindEntityAnywhere(mobName)
	if not mobName then
		return nil
	end
	local now = os.clock()
	if now - lastFindAnywhereAt < 0.5 then
		return nil
	end
	lastFindAnywhereAt = now

	local nameLower = string.lower(mobName)

	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if enemiesFolder then
		for _, enemy in ipairs(enemiesFolder:GetChildren()) do
			if string.lower(enemy.Name) == nameLower and IsEnemyVulnerable(enemy, mobName) then
				return enemy
			end
		end
	end

	local wHit = workspace:FindFirstChild(mobName, true)
	if wHit and IsEnemyVulnerable(wHit, mobName) then
		return wHit
	end

	if getnilinstances then
		pcall(function()
			for _, ent in ipairs(getnilinstances()) do
				if ent:IsA("Model") and string.lower(ent.Name) == nameLower and IsEnemyVulnerable(ent, mobName) then
					wHit = ent
					break
				end
			end
		end)
		if wHit then
			return wHit
		end
	end

	return nil
end

local function findTarget(name)
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	local allTargets = {}

	if enemiesFolder then
		if not name or name == "" then
			for _, enemy in ipairs(enemiesFolder:GetChildren()) do
				if enemy.Parent == enemiesFolder and IsEnemyVulnerable(enemy, nil) then
					table.insert(allTargets, enemy)
				end
			end
		else
			local nameLower = string.lower(name)
			for _, enemy in ipairs(enemiesFolder:GetChildren()) do
				if
					enemy.Parent == enemiesFolder
					and string.lower(enemy.Name) == nameLower
					and IsEnemyVulnerable(enemy, name)
				then
					table.insert(allTargets, enemy)
				end
			end
		end

		for _, enemy in ipairs(enemiesFolder:GetChildren()) do
			if enemy.Name == "PropHitboxPlaceholder" and IsEnemyVulnerable(enemy, nil) then
				table.insert(allTargets, enemy)
			end
		end
	end

	if #allTargets == 0 and name and name ~= "" and not farmNearestEnabled and not isAutoRaidKill then
		local fallbackEnemy = FindEntityAnywhere(name)
		if fallbackEnemy then
			table.insert(allTargets, fallbackEnemy)
		end
	end

	return allTargets
end

local function GetTargetEnemy(mobName)
	local throttleKey = mobName or "ANY_MOB"
	local now = os.clock()
	if emptyTargetThrottle[throttleKey] and (now - emptyTargetThrottle[throttleKey]) < 0.25 then
		return nil
	end

	local result = nil
	local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")

	local targets = (farmNearestEnabled or isAutoRaidKill or mobName == nil) and findTarget() or findTarget(mobName)

	local closest, shortestDist = nil, math.huge
	if myHrp then
		for _, enemy in ipairs(targets) do
			local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
			if eHrp then
				local dist = (eHrp.Position - myHrp.Position).Magnitude
				if dist < shortestDist then
					if not farmNearestEnabled or dist <= farmNearestRadius then
						shortestDist = dist
						closest = enemy
					end
				end
			end
		end
	end

	result = closest

	if not result then
		emptyTargetThrottle[throttleKey] = now
	else
		emptyTargetThrottle[throttleKey] = nil
	end

	return result
end

local function GetBossProfileByName(name)
	if not name then
		return nil
	end
	for _, boss in ipairs(BOSSES) do
		if boss.Name == name then
			return boss
		end
	end
	return nil
end

local PriorityLevels = {
	AutoHaze = 5,
	EliteHunter = 4,
	BossHunter = 3,
	EventFarm = 2,
	RegularFarm = 1,
}

local function GetCurrentFarmPriority()
	local currentPri = 0

	if cfg.isAutoHaze then
		local hasHaze = false
		local enemiesFolder = workspace:FindFirstChild("Enemies")
		if enemiesFolder then
			for _, enemy in ipairs(enemiesFolder:GetChildren()) do
				if enemy:FindFirstChild("HazeESP") then
					hasHaze = true
					break
				end
			end
		end
		if hasHaze then
			return PriorityLevels.AutoHaze
		end
	end

	if cfg.isEliteHunterActive then
		return PriorityLevels.EliteHunter
	end

	if cfg.isBossHunterEnabled and selectedBossName then
		local bossProfile = GetBossProfileByName(selectedBossName)
		if bossProfile then
			local enemiesFolder = workspace:FindFirstChild("Enemies")
			if enemiesFolder then
				for _, enemy in ipairs(enemiesFolder:GetChildren()) do
					if enemy.Name == bossProfile.Name and IsEnemyVulnerable(enemy, bossProfile.Name) then
						if enemy:FindFirstChild("HumanoidRootPart") then
							return PriorityLevels.BossHunter
						end
					end
				end
			end
			local anywhereBoss = FindEntityAnywhere(bossProfile.Name)
			if anywhereBoss then
				return PriorityLevels.BossHunter
			end
		end
	end

	if cfg.isAutoCakePrince or cfg.isAutodoughKing then
		return PriorityLevels.EventFarm
	end

	return currentPri
end

local function IsHighPriorityActive(callerPriorityName)
	local callerLevel = PriorityLevels[callerPriorityName] or PriorityLevels.RegularFarm
	local currentActiveLevel = GetCurrentFarmPriority()
	return currentActiveLevel > callerLevel
end

local function GetSpawnedBoss(targetBossName)
	local bossProfile = GetBossProfileByName(targetBossName)
	local now = os.clock()
	if emptyTargetThrottle[targetBossName] and (now - emptyTargetThrottle[targetBossName]) < 0.5 then
		return nil, bossProfile
	end

	local result = nil
	local targets = findTarget(bossProfile and bossProfile.Name or targetBossName)
	local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")

	local closest, shortestDist = nil, math.huge
	if myHrp then
		for _, enemy in ipairs(targets) do
			local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
			if eHrp then
				local dist = (eHrp.Position - myHrp.Position).Magnitude
				if dist < shortestDist then
					shortestDist = dist
					closest = enemy
				end
			end
		end
	end
	result = closest

	if result then
		emptyTargetThrottle[targetBossName] = nil
	else
		emptyTargetThrottle[targetBossName] = now
	end

	return result, bossProfile
end

local function IsToolMatching(tool, wantedCategory)
	if not tool or not tool:IsA("Tool") or tool.Name == "Tool" then
		return false
	end
	local expectedToolTip = wantedCategory
	if wantedCategory == "Fruit" or wantedCategory == "Blox Fruit" or wantedCategory == "Demon Fruit" then
		expectedToolTip = "Blox Fruit"
	end
	if tool.ToolTip == expectedToolTip then
		return true
	end
	return wantedCategory == "Melee" and meleeNames[tool.Name] == true
end

local lastDripMamaCheck, cachedDripMamaStatus = 0, "unknown"

local function getDripMamaStatus()
	local now = os.clock()
	if now - lastDripMamaCheck < 4 then
		return cachedDripMamaStatus
	end
	lastDripMamaCheck = now

	local res = nil
	pcall(function()
		res = CommF_:InvokeServer("CakePrinceSpawner", true)
	end)

	if type(res) == "string" then
		local left = string.match(res, "We still need to defeat <Color=Yellow>(%d+)<Color=/>")
		if left then
			cachedDripMamaStatus = left .. " left"
		elseif
			string.find(string.lower(res), "portal is already open")
			or string.find(string.lower(res), "behind the house")
		then
			cachedDripMamaStatus = "spawned"
		elseif
			string.find(string.lower(res), "we have defeated enough")
			or string.find(string.lower(res), "do you want to open the portal")
		then
			cachedDripMamaStatus = "ready"
		else
			cachedDripMamaStatus = "unknown"
		end
	end
	return cachedDripMamaStatus
end

local function EquipWeapon(overrideCategory)
	local c = GetCharacter()
	local h = GetHumanoid()
	if not c or not h then
		return nil
	end

	local wantedCategory = overrideCategory or (cfg.AutoMastery and cfg.MasteryCategory or cfg.WeaponCategory)
	local existing = c:FindFirstChildOfClass("Tool")
	if IsToolMatching(existing, wantedCategory) then
		cachedWeapon = existing
		cachedWeaponCategory = wantedCategory
		return existing
	end

	if cachedWeapon and cachedWeapon.Parent == c and IsToolMatching(cachedWeapon, wantedCategory) then
		return cachedWeapon
	end

	local bag = player:FindFirstChildOfClass("Backpack")
	if not bag then
		return nil
	end

	for _, tool in ipairs(bag:GetChildren()) do
		if IsToolMatching(tool, wantedCategory) then
			pcall(function()
				h:EquipTool(tool)
			end)
			cachedWeapon = tool
			cachedWeaponCategory = wantedCategory
			return tool
		end
	end
	return nil
end

local function EnableBuso()
	local c = GetCharacter()
	if c and not c:GetAttribute("BusoEnabled") then
		pcall(function()
			CommF_:InvokeServer("Buso")
		end)
	end
end

local lastSkillFiredAt = 0
local skillKeys = { Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V, Enum.KeyCode.F }
local skillIndex = 1

local function TriggerSkills(key)
	local now = os.clock()
	if now - lastSkillFiredAt >= 0.5 then
		lastSkillFiredAt = now
		task.spawn(function()
			pcall(function()
				VirtualInputManager:SendKeyEvent(true, key, false, game)
				task.wait(0.1)
				VirtualInputManager:SendKeyEvent(false, key, false, game)
			end)
			skillIndex = skillIndex + 1
			if skillIndex > #skillKeys then
				skillIndex = 1
			end
		end)
	end
end

	local lastExecuteAttackCall = 0
	local function ExecuteAttack(myChar, myHrp, forceNoEquip, targetMobName)
	local now = os.clock()
	local minInterval = (attackSpeedMode == "Super Fast Attack") and 0 or 0.05
	if now - lastExecuteAttackCall < minInterval then
		return
	end
	lastExecuteAttackCall = now

	local targetCategory = cfg.WeaponCategory
	if cfg.AutoMastery and not forceNoEquip then
		if currentTargetInstance then
			local hum = currentTargetInstance:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local pct = (hum.Health / hum.MaxHealth) * 100
				if cfg.MasteryCategory == "Fruit" or cfg.MasteryCategory == "Gun" then
					targetCategory = (pct <= cfg.MasteryHealth) and cfg.MasteryCategory or "Melee"
				else
					targetCategory = cfg.MasteryCategory
				end
			end
		end
	end

	local weapon = myChar:FindFirstChildOfClass("Tool")
	if forceNoEquip then
		if not weapon then
			return
		end
	else
		weapon = cachedWeapon
		if not weapon or weapon.Parent ~= myChar or not IsToolMatching(weapon, targetCategory) then
			weapon = EquipWeapon(targetCategory)
			if not weapon then
				local bag = player:FindFirstChildOfClass("Backpack")
				if bag then
					for _, t in ipairs(bag:GetChildren()) do
						if IsToolMatching(t, targetCategory) then
							GetHumanoid():EquipTool(t)
							weapon = t
							break
						end
					end
				end
			end
		end
	end

	if weapon then
		if myHrp.Anchored then
			myHrp.Anchored = false
		end

		local isBloxFruit = IsToolMatching(weapon, "Fruit")
			or IsToolMatching(weapon, "Blox Fruit")
			or IsToolMatching(weapon, "Demon Fruit")
		local isPhysical = IsToolMatching(weapon, "Melee") or IsToolMatching(weapon, "Sword")
		local isGun = IsToolMatching(weapon, "Gun") or (weapon.ToolTip == "Gun")
		if isPhysical or isBloxFruit or isGun then
			EnableBuso()
			local enemiesFolder = workspace:FindFirstChild("Enemies")
			if enemiesFolder then
				local hitTargets = {}

				if not isMultiMobDamage and currentTargetInstance and IsEnemyVulnerable(currentTargetInstance, nil) then
					local eHrp = currentTargetInstance:FindFirstChild("HumanoidRootPart")
						or currentTargetInstance:FindFirstChildWhichIsA("BasePart", true)
					if eHrp then
						local dist = (GetSafePosition(eHrp) - GetSafePosition(myHrp)).Magnitude
						if dist <= (cfg.HitRadius + 40) then
							local ePart = GetHitPart(currentTargetInstance)
							if ePart then
								table.insert(hitTargets, { EnemyModel = currentTargetInstance, HitPart = ePart })
							end
						end
					end
				else
					for _, enemy in ipairs(enemiesFolder:GetChildren()) do
						if IsEnemyVulnerable(enemy, nil) then
							local eHrp = enemy:FindFirstChild("HumanoidRootPart")
								or enemy:FindFirstChildWhichIsA("BasePart", true)
							if eHrp then
								local dist = (GetSafePosition(eHrp) - GetSafePosition(myHrp)).Magnitude
								local isTarget = (currentTargetInstance and enemy == currentTargetInstance)

								local allowedDist = isTarget and (cfg.HitRadius + 40) or cfg.HitRadius

								if dist <= allowedDist then
									local ePart = GetHitPart(enemy)
									if ePart then
										table.insert(hitTargets, { EnemyModel = enemy, HitPart = ePart })
									end
								end
							end
						end
					end
				end

				if #hitTargets > 0 then
					for _, targetData in ipairs(hitTargets) do
						if targetData.HitPart then
							ExpandEnemyHitbox(targetData.HitPart)
						end
					end

					local primaryDict = hitTargets[1]
					local primaryModel = primaryDict.EnemyModel
					local primaryHrp = primaryModel
						and (
							primaryModel:FindFirstChild("HumanoidRootPart")
							or primaryModel:FindFirstChildWhichIsA("BasePart", true)
						)

					local primaryPart = primaryDict and primaryDict.HitPart
					local tPos = primaryPart and primaryPart.Position or (myHrp.Position + myHrp.CFrame.LookVector * 10)
					local dir = (tPos - myHrp.Position).Unit

					if isBloxFruit then
						pcall(function()
							local remote = weapon:FindFirstChild("LegacyRemoteEvent") or weapon:FindFirstChild("RemoteEvent")
							if remote and remote:IsA("RemoteEvent") then
								local mousePosInst = weapon:FindFirstChild("MousePos") or weapon:FindFirstChild("Mouse")
								remote:FireServer(true)
								if mousePosInst and not mousePosInst:IsA("Vector3Value") then
									remote:FireServer(CFrame.new(tPos))
								else
									remote:FireServer(tPos)
								end
								remote:FireServer(false)
							elseif weapon:FindFirstChild("LeftClickRemote") then
								local combo = Random.new():NextInteger(1, 4)
								weapon.LeftClickRemote:FireServer(dir, combo)
							end
						end)
					end

					if isGun then
						local hum = myChar:FindFirstChildOfClass("Humanoid")
						local hiddenHumRemote = hum and hum:FindFirstChild("")
						if hiddenHumRemote and hiddenHumRemote:IsA("RemoteFunction") then
							pcall(function()
								hiddenHumRemote:InvokeServer("TAP", tPos)
							end)
						end
					end

					if isPhysical or isBloxFruit then
						pcall(function()
							if RegisterAttackEvent then
								RegisterAttackEvent:FireServer(0, combo)
							end

							local primaryPartToHit = GetHitPart(primaryDict.EnemyModel) or primaryPart
							if RegisterHitEvent and primaryPartToHit then
								local additionalHits = {}
								if isMultiMobDamage and #hitTargets > 1 then
									for j = 2, #hitTargets do
										local enemyObj = hitTargets[j]
										local enemyModel = enemyObj.EnemyModel
										local partToHit = enemyObj.HitPart or GetHitPart(enemyModel)
										if enemyModel and partToHit then
											table.insert(additionalHits, { enemyModel, partToHit })
										end
									end
								end

								local seed = getgenv().cachedNetSeed
								local args = {
									primaryPartToHit,
									additionalHits,
									seed,
									currentSessionSecret,
								}
								RegisterHitEvent:FireServer(unpack(args))
							end
						end)
					end
				end
			end
		end
	end
end

local function AttackThread(generation)
	task.spawn(function()
		while ScriptContext.Running and generation == workerGeneration do
			if enabled then
				local now = os.clock()
				local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
					or cfg.AttackIntervalFast
				local myChar = GetCharacter()
				local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

				if now - lastAttackAt >= interval then
					if
						myHrp
						and isReadyToAttack
						and currentTargetInstance
						and currentTargetInstance.Parent
						and currentTargetInstance:FindFirstChild("Humanoid")
						and currentTargetInstance.Humanoid.Health > 0
					then
						local tName = currentTargetInstance.Name
						ExecuteAttack(myChar, myHrp, false, tName)
						lastAttackAt = now
					end
				end
			end

			if enabled and attackSpeedMode == "Super Fast Attack" then
				task.wait()
			else
				task.wait(cfg.ThreadSleep)
			end
		end
	end)
end

local cachedHazeMob = nil
local lastScanTime = 0
local SCAN_COOLDOWN = 2.5

local HazeTargets = {}

local function GetBestHazeMob()
	local myChar = GetCharacter()
	local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHrp then
		return nil
	end

	local questHaze = player:FindFirstChild("QuestHaze")
	if questHaze then
		local bestDistance = math.huge
		local bestGhostInfo = nil

		for _, child in ipairs(questHaze:GetChildren()) do
			if child.Value > 0 then
				local targetName = child.Name
				local targetPos = child:GetAttribute("Position")

				local mobProfile = GetMobProfileByName(targetName)
				if mobProfile and mobProfile.MobPos then
					targetPos = mobProfile.MobPos
				end

				if targetPos then
					local dist = (myHrp.Position - targetPos).Magnitude
					if dist < bestDistance then
						bestDistance = dist
						bestGhostInfo = {
							Name = targetName,
							Mob = targetName,
							MobPos = targetPos,
							Instance = nil,
							IsGhostPos = true,
						}
					end
				end
			end
		end

		if bestGhostInfo then
			local enemiesFolder = workspace:FindFirstChild("Enemies")
			if enemiesFolder then
				local myHrpPos = myHrp.Position
				local closestEnemyInst = nil
				local closestEnemyDist = math.huge

				for _, enemy in ipairs(enemiesFolder:GetChildren()) do
					if string.find(string.lower(enemy.Name), string.lower(bestGhostInfo.Name)) then
						if IsEnemyVulnerable(enemy, nil) then
							local eHrp = enemy:FindFirstChild("HumanoidRootPart")
							if eHrp then
								local d = (myHrpPos - eHrp.Position).Magnitude
								if d < closestEnemyDist then
									closestEnemyDist = d
									closestEnemyInst = enemy
									bestGhostInfo.MobPos = eHrp.Position
									bestGhostInfo.Instance = enemy
									bestGhostInfo.IsGhostPos = false
								end
							end
						end
					end
				end
			end
			return bestGhostInfo
		end
	end

	for i = #HazeTargets, 1, -1 do
		local targetData = HazeTargets[i]
		local inst = targetData.Instance
		if inst and inst.Parent and inst:FindFirstChild("HazeESP") and IsEnemyVulnerable(inst, nil) then
			local eHrp = inst:FindFirstChild("HumanoidRootPart")
			if eHrp then
				targetData.MobPos = eHrp.Position
				return targetData
			end
		else
			table.remove(HazeTargets, i)
		end
	end

	local now = os.clock()
	if (now - lastScanTime) < SCAN_COOLDOWN then
		return nil
	end
	lastScanTime = now

	local searchList = {}
	if getinstances then
		for _, inst in ipairs(getinstances()) do
			table.insert(searchList, inst)
		end
	end
	if getnilinstances then
		for _, inst in ipairs(getnilinstances()) do
			table.insert(searchList, inst)
		end
	end

	local foundAny = false
	for _, obj in ipairs(searchList) do
		if typeof(obj) == "Instance" and obj:FindFirstChild("HazeESP") then
			if IsEnemyVulnerable(obj, nil) then
				local eHrp = obj:FindFirstChild("HumanoidRootPart")
				if eHrp then
					local exists = false
					for _, existingTarget in ipairs(HazeTargets) do
						if existingTarget.Instance == obj then
							exists = true
							break
						end
					end
					if not exists then
						local newHazeMob = { Name = obj.Name, Mob = obj.Name, MobPos = eHrp.Position, Instance = obj }
						table.insert(HazeTargets, newHazeMob)
					end
					foundAny = true
				end
			end
		end
	end

	if foundAny and #HazeTargets > 0 then
		return HazeTargets[#HazeTargets]
	end

	return nil
end

local function StartAutoHaze()
	local generation = workerGeneration
	ToggleFloat(true)

	local Sea3PatrolLocations = {
		Vector3.new(-449, 108, 5948),
		Vector3.new(5214, 1004, 756),
		Vector3.new(2581, 567, -8267),
		Vector3.new(-11246, 707, -6791),
		Vector3.new(-820, 66, -10966),
		Vector3.new(-9482, 142, 5567),
		Vector3.new(-16546, 55, -172),
	}
	local currentPatrolIndex = 1
	local lastPatrolTime = 0
	local PATROL_INTERVAL = 8

	task.spawn(function()
		while cfg.isAutoHaze and ScriptContext.Running and generation == workerGeneration do
			if IsHighPriorityActive("AutoHaze") then
				task.wait(1)
				break
			end
			local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
				or cfg.AttackIntervalFast
			local myChar = GetCharacter()
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if myHrp then
				local tName = currentTargetInstance and currentTargetInstance.Name
				ExecuteAttack(myChar, myHrp, false, tName)
			end

			if interval <= 0 then
				task.wait()
			else
				task.wait(interval)
			end
		end
	end)

	local hazeBringConn
	hazeBringConn = RunService.Heartbeat:Connect(function()
		if not cfg.isAutoHaze or not ScriptContext.Running or generation ~= workerGeneration then
			if hazeBringConn then
				hazeBringConn:Disconnect()
			end
			return
		end
		if IsHighPriorityActive("AutoHaze") then
			return
		end
		if isReadyToAttack then
			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			local target = currentTargetInstance
			local tHrp = target and target:FindFirstChild("HumanoidRootPart")
			if myHrp and tHrp then
				local magnetPos = targetMobInfo and targetMobInfo.MobPos or tHrp.Position
				if magnetPos then
					UniversalMagnet(target.Name, magnetPos, myHrp.Position)
				end
			end
		end
	end)
	ScriptContext:AddConnection(hazeBringConn)

	task.spawn(function()
		while cfg.isAutoHaze and ScriptContext.Running and generation == workerGeneration do
			if IsHighPriorityActive("AutoHaze") then
				task.wait(1)
				break
			end
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				local now = os.clock()
				if now - lastEvasionTime >= cfg.EvasionTick then
					lastEvasionTime = now
					local radius = math.max(0, math.floor(cfg.EvasionRadius))
					currentEvasionOffset =
						Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
					lastEvasionMoveAt = 0
				end

				local targetMobInfo = GetBestHazeMob()
				if not targetMobInfo then
					isReadyToAttack = false
					currentTargetInstance = nil
					ToggleFloat(true)

					if (now - lastPatrolTime) > PATROL_INTERVAL then
						lastPatrolTime = now
						currentPatrolIndex = currentPatrolIndex + 1
						if currentPatrolIndex > #Sea3PatrolLocations then
							currentPatrolIndex = 1
						end

						local targetPatrol = Sea3PatrolLocations[currentPatrolIndex] + Vector3.new(0, 400, 0)
						TweenTo(CFrame.new(targetPatrol))
					end
					return
				end

				if targetMobInfo.IsGhostPos then
					isReadyToAttack = false
					currentTargetInstance = nil
					ToggleFloat(true)
					TweenTo(CFrame.new(targetMobInfo.MobPos + Vector3.new(0, cfg.TweenHeight, 0)))
					return
				end

				local targetEnemy = targetMobInfo.Instance
				currentTargetInstance = targetEnemy

				if targetEnemy then
					local h = targetEnemy:FindFirstChildOfClass("Humanoid")
					if h then
						if h.Health ~= lastTargetHealth then
							lastTargetHealth = h.Health
							lastTargetHealthChangeAt = os.clock()
						end
						if h.Health == 0 or (os.clock() - lastTargetHealthChangeAt > cfg.StuckTimeout) then
							enemyBlacklist[targetEnemy] = os.clock() + cfg.StuckTimeout
							isReadyToAttack = false
							currentTargetInstance = nil
							task.wait(0.1)
							return
						end
					end
				end

				if targetEnemy and targetEnemy:FindFirstChild("HumanoidRootPart") then
					EquipWeapon()
					local tHrp = targetEnemy.HumanoidRootPart
					local targetDistance = (tHrp.Position - myHrp.Position).Magnitude

					if targetDistance > cfg.BringRadius then
						isReadyToAttack = false
						ToggleFloat(true)
						TweenTo(CFrame.new(tHrp.Position + Vector3.new(0, cfg.TweenHeight, 0), tHrp.Position))
					else
						isReadyToAttack = true
						UniversalEvasionTween(myHrp, tHrp.Position, now)
					end
				else
					isReadyToAttack = false
				end
			end)
			if not ok then
				warn("[Auto Haze Error] " .. tostring(err))
			end
			task.wait(cfg.ThreadSleep)
		end
		ToggleFloat(false)
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
	end)
end

local function GetBestHauntedMob()
	local hauntedMobs = {
		{ Name = "Reborn Skeletons", Mob = "Reborn Skeleton" },
		{ Name = "Living Zombies", Mob = "Living Zombie" },
		{ Name = "Demonic Souls", Mob = "Demonic Soul" },
		{ Name = "Posessed Mummies", Mob = "Posessed Mummy" },
		{ Name = "Bone Breakers", Mob = "Bone Breaker", MobPos = Vector3.new(71738, 4, -33780) },
		{ Name = "Sorcerers", Mob = "Sorcerer", MobPos = Vector3.new(71573, -2, -34078) },
	}

	for _, info in ipairs(hauntedMobs) do
		local profile = GetMobProfileByName(info.Mob)
		if profile and profile.MobPos then
			info.MobPos = profile.MobPos
		end
	end

	local myChar = GetCharacter()
	local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local myPos = myHrp and myHrp.Position or Vector3.new(-9482, 142, 5567)

	local enemies = workspace:FindFirstChild("Enemies")

	local availableMobTypes = {}
	local seenMobTypes = {}

	if enemies then
		for _, enemy in ipairs(enemies:GetChildren()) do
			for _, mobInfo in ipairs(hauntedMobs) do
				if enemy.Name == mobInfo.Mob and IsEnemyVulnerable(enemy, mobInfo.Mob) then
					local dist = mobInfo.MobPos and (myPos - mobInfo.MobPos).Magnitude or 0
					if dist < 5000 then
						if not seenMobTypes[mobInfo.Mob] then
							seenMobTypes[mobInfo.Mob] = true
							table.insert(availableMobTypes, mobInfo)
						end
					end
				end
			end
		end
	end

	if #availableMobTypes > 0 then
		local randomIndex = math.random(1, #availableMobTypes)
		return availableMobTypes[randomIndex]
	end

	local closestMob = nil
	local closestDist = math.huge
	for _, info in ipairs(hauntedMobs) do
		if info.MobPos then
			local d = (myPos - info.MobPos).Magnitude
			if d < closestDist then
				closestDist = d
				closestMob = info
			end
		end
	end

	return closestMob or hauntedMobs[1]
end

local hazeDetectorConn = nil
if workspace:FindFirstChild("Enemies") then
	hazeDetectorConn = workspace.Enemies.ChildAdded:Connect(function(v)
		if cfg.isAutoHaze then
			if v:WaitForChild("HazeESP", 1.5) then
				local eHrp = v:WaitForChild("HumanoidRootPart", 1)
				if eHrp then
					local newTarget = { Name = v.Name, Mob = v.Name, MobPos = eHrp.Position, Instance = v }
					table.insert(HazeTargets, newTarget)
					print("Ghost spawns with: " .. v.Name .. " (Added to Target Queue)")
				end
			end
		end
	end)
	ScriptContext:AddConnection(hazeDetectorConn)
end

local selectedMaterialTarget = "None"

local function TeleportToSea(seaNumber)
	local canTravel = true
	local failReason = ""

	local myLevel = GetPlayerLevel()

	if seaNumber == 2 then
		if myLevel < 700 then
			canTravel = false
			failReason = "Level < 700"
		end
	elseif seaNumber == 3 then
		if myLevel < 1500 then
			canTravel = false
			failReason = "Level < 1500"
		else
			pcall(function()
				local CommF_ = game:GetService("ReplicatedStorage").Remotes.CommF_
				local unlocks = CommF_:InvokeServer("GetUnlockables")
				if unlocks then
					if type(unlocks) == "table" and not unlocks["DefeatedIndraTrueForm"] then
						canTravel = false
						failReason = "Rip_Indra puzzle not finished"
					end
				end
			end)
		end
	end

	if not canTravel then
		if getgenv().LonumObject then
			getgenv().LonumObject:Notify({
				Title = "Travel Failed",
				Content = "Cannot travel to Sea " .. tostring(seaNumber) .. " (" .. failReason .. ")",
				Duration = 5,
			})
		end
		isAutoMaterial = false
		return false
	end

	if getgenv().LonumObject then
		getgenv().LonumObject:Notify({
			Title = "Auto Travel",
			Content = "Teleporting to Sea " .. tostring(seaNumber) .. " for material farming...",
			Duration = 5,
		})
	end
	task.spawn(function()
		if seaNumber == 1 then
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelMain")
		elseif seaNumber == 2 then
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelDressrosa")
		elseif seaNumber == 3 then
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelZou")
		end
	end)
	task.wait(5)
	return true
end

local function GetBestMaterialMob()
	local mobTargets = {}
	local requiredSea = 0

	local _, currentSea = GetCurrentSea()

	if selectedMaterialTarget == "Conjured Cocoa" then
		requiredSea = 3
		if currentSea == 3 then
			mobTargets = {
				{ Name = "Cocoa Warriors", Mob = "Cocoa Warrior", MobPos = Vector3.new(31.5, 24.8, -12246.7) },
				{
					Name = "Chocolate Bar Battlers",
					Mob = "Chocolate Bar Battler",
					MobPos = Vector3.new(683.4, 24.8, -12576.2),
				},
			}
		end
	elseif selectedMaterialTarget == "Dragon Scale" then
		requiredSea = 3
		if currentSea == 3 then
			mobTargets = {
				{
					Name = "Dragon Crew Warriors",
					Mob = "Dragon Crew Warrior",
					MobPos = Vector3.new(6834.7, 192.7, -829.1),
				},
				{
					Name = "Dragon Crew Archers",
					Mob = "Dragon Crew Archer",
					MobPos = Vector3.new(6713.1, 716.1, 631.1),
				},
			}
		end
	elseif selectedMaterialTarget == "Mystic Droplet" then
		requiredSea = 2
		if currentSea == 2 then
			mobTargets = {
				{ Name = "Sea Soldiers", Mob = "Sea Soldier", MobPos = Vector3.new(-3028, 65, -9775) },
				{ Name = "Water Fighters", Mob = "Water Fighter", MobPos = Vector3.new(-3262, 298, -10553) },
			}
		end
	elseif selectedMaterialTarget == "Fish Tail" then
		if currentSea == 1 then
			requiredSea = 1
			mobTargets = {
				{ Name = "Fishman Warriors", Mob = "Fishman Warrior", MobPos = Vector3.new(60878, 19, 1543) },
				{ Name = "Fishman Commandos", Mob = "Fishman Commando", MobPos = Vector3.new(61891, 19, 1470) },
				{ Name = "Fishman Lord", Mob = "Fishman Lord", MobPos = Vector3.new(6112, 19, 1567) },
			}
		elseif currentSea == 3 then
			requiredSea = 3
			mobTargets = {
				{ Name = "Fishman Raiders", Mob = "Fishman Raider", MobPos = Vector3.new(-10407, 332, -8368) },
				{ Name = "Fishman Captains", Mob = "Fishman Captain", MobPos = Vector3.new(-10993, 352, -9003) },
			}
		else
			requiredSea = 1
		end
	elseif selectedMaterialTarget == "Magma Orb" then
		if currentSea == 1 then
			requiredSea = 1
			mobTargets = {
				{ Name = "Military Soldiers", Mob = "Military Soldier", MobPos = Vector3.new(-5411, 11, 8454) },
				{ Name = "Military Spies", Mob = "Military Spy", MobPos = Vector3.new(-5802, 86, 8829) },
				{ Name = "Magma Admiral", Mob = "Magma Admiral", MobPos = Vector3.new(-5701, 17, 8722) },
			}
		elseif currentSea == 2 then
			requiredSea = 2
			mobTargets = {
				{ Name = "Magma Ninjas", Mob = "Magma Ninja", MobPos = Vector3.new(-5461, 130, -5836) },
				{ Name = "Lava Pirates", Mob = "Lava Pirate", MobPos = Vector3.new(-5251, 55, -4774) },
			}
		else
			requiredSea = 1
		end
	else
		return nil
	end

	if requiredSea ~= 0 and currentSea ~= requiredSea then
		if not TeleportToSea(requiredSea) then
			return nil
		end
		return { Mob = "Teleporting_Dummy", MobPos = Vector3.zero }
	end

	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then
		return mobTargets[math.random(1, #mobTargets)]
	end

	local availableMobTypes = {}
	local seenMobTypes = {}

	for _, enemy in ipairs(enemies:GetChildren()) do
		for _, mobInfo in ipairs(mobTargets) do
			if enemy.Name == mobInfo.Mob and IsEnemyVulnerable(enemy, mobInfo.Mob) then
				if not seenMobTypes[mobInfo.Mob] then
					seenMobTypes[mobInfo.Mob] = true
					table.insert(availableMobTypes, mobInfo)
				end
			end
		end
	end

	if #availableMobTypes > 0 then
		local randomIndex = math.random(1, #availableMobTypes)
		return availableMobTypes[randomIndex]
	end

	return mobTargets[math.random(1, #mobTargets)]
end

local function GetBestCakeMob()
	local cakeMobs = {
		{ Name = "Cookie Crafters", Mob = "Cookie Crafter" },
		{ Name = "Cake Guards", Mob = "Cake Guard" },
		{ Name = "Baking Staff", Mob = "Baking Staff" },
		{ Name = "Head Bakers", Mob = "Head Baker" },
	}

	for _, info in ipairs(cakeMobs) do
		local profile = GetMobProfileByName(info.Mob)
		if profile then
			info.MobPos = profile.MobPos
		end
	end

	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then
		return cakeMobs[math.random(1, #cakeMobs)]
	end

	local availableMobTypes = {}
	local seenMobTypes = {}

	for _, enemy in ipairs(enemies:GetChildren()) do
		for _, mobInfo in ipairs(cakeMobs) do
			if enemy.Name == mobInfo.Mob and IsEnemyVulnerable(enemy, mobInfo.Mob) then
				if not seenMobTypes[mobInfo.Mob] then
					seenMobTypes[mobInfo.Mob] = true
					table.insert(availableMobTypes, mobInfo)
				end
			end
		end
	end

	if #availableMobTypes > 0 then
		local randomIndex = math.random(1, #availableMobTypes)
		return availableMobTypes[randomIndex]
	end

	return cakeMobs[math.random(1, #cakeMobs)]
end

local function StartAutoBone()
	local generation = workerGeneration
	ToggleFloat(true)

	local defaultHauntedFallback =
		{ Name = "Reborn Skeletons", Mob = "Reborn Skeleton", MobPos = Vector3.new(-8760, 183, 6168) }
	local activeHauntedMobInfo = GetBestHauntedMob() or defaultHauntedFallback

	task.spawn(function()
		while isAutoBone and ScriptContext.Running and generation == workerGeneration do
			if IsHighPriorityActive("RegularFarm") then
				task.wait(1)
				break
			end
			local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
				or cfg.AttackIntervalFast
			local myChar = GetCharacter()
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if myHrp then
				local tName = currentTargetInstance and currentTargetInstance.Name or activeHauntedMobInfo.Mob
				ExecuteAttack(myChar, myHrp, false, tName)
			end

			if interval <= 0 then
				task.wait()
			else
				task.wait(interval)
			end
		end
	end)

	local boneBringConn
	boneBringConn = RunService.Heartbeat:Connect(function()
		if not isAutoBone or not ScriptContext.Running or generation ~= workerGeneration then
			if boneBringConn then
				boneBringConn:Disconnect()
			end
			return
		end
		if IsHighPriorityActive("RegularFarm") then
			return
		end
		if isReadyToAttack then
			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			local target = currentTargetInstance
			local tHrp = target and target:FindFirstChild("HumanoidRootPart")
			if myHrp and tHrp then
				local targetMobInfo = activeHauntedMobInfo or GetBestHauntedMob()
				local targetMobName = targetMobInfo.Mob
				local magnetPos = targetMobInfo and targetMobInfo.MobPos or tHrp.Position
				if magnetPos then
					UniversalMagnet(targetMobName, magnetPos, myHrp.Position)
				end
			end
		end
	end)
	ScriptContext:AddConnection(boneBringConn)

	task.spawn(function()
		while isAutoBone and ScriptContext.Running and generation == workerGeneration do
			if IsHighPriorityActive("RegularFarm") then
				task.wait(1)
				break
			end
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				local now = os.clock()
				if now - lastEvasionTime >= cfg.EvasionTick then
					lastEvasionTime = now
					local radius = math.max(0, math.floor(cfg.EvasionRadius))
					currentEvasionOffset =
						Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
					lastEvasionMoveAt = 0
				end

				if not activeHauntedMobInfo then
					activeHauntedMobInfo = GetBestHauntedMob() or defaultHauntedFallback
				end

				local targetMobInfo = activeHauntedMobInfo
				local targetMobName = targetMobInfo.Mob
				local targetEnemy = currentTargetInstance

				if targetEnemy then
					local h = targetEnemy:FindFirstChildOfClass("Humanoid")
					if h then
						if h.Health ~= lastTargetHealth then
							lastTargetHealth = h.Health
							lastTargetHealthChangeAt = now
						end

						if lastTargetHealthChangeAt > 0 and (now - lastTargetHealthChangeAt >= cfg.StuckTimeout) then
							if not IsBossEntity(targetEnemy) then
								enemyBlacklist[targetEnemy] = now + 3
								currentTargetInstance = nil
								isReadyToAttack = false
								targetEnemy = nil
							else
								lastTargetHealthChangeAt = now
							end
						end
					end
				end

				if not targetEnemy or not IsEnemyVulnerable(targetEnemy, targetMobName) then
					targetEnemy = GetTargetEnemy(targetMobName)

					if not targetEnemy then
						local distToCurrentSpawn = (myHrp.Position - targetMobInfo.MobPos).Magnitude
						if distToCurrentSpawn < 80 then
							local checkNewMob = GetBestHauntedMob()
							if checkNewMob then
								activeHauntedMobInfo = checkNewMob
								targetMobInfo = activeHauntedMobInfo
								targetMobName = targetMobInfo.Mob
								targetEnemy = GetTargetEnemy(targetMobName)
							end
						end
					end

					currentTargetInstance = targetEnemy
					if targetEnemy then
						local h = targetEnemy:FindFirstChildOfClass("Humanoid")
						lastTargetHealth = h and h.Health or -1
						lastTargetHealthChangeAt = now
					end
				end

				if targetEnemy then
					local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
						or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
					if tHrp then
						local mobProfile = GetMobProfileByName(targetEnemy.Name)

						local centerPos = mobProfile and mobProfile.MobPos or tHrp.Position

						local targetDistance = (centerPos - myHrp.Position).Magnitude
						if targetDistance > 80 then
							TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
							lastEvasionMoveAt = now
						else
							TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
						end

						isReadyToAttack = (GetSafePosition(tHrp) - myHrp.Position).Magnitude <= cfg.MaxPullRange
					end
				else
					currentTargetInstance = nil
					isReadyToAttack = false
					local distToSpawn = (myHrp.Position - targetMobInfo.MobPos).Magnitude
					if distToSpawn > 80 then
						TweenTo(
							CFrame.new(targetMobInfo.MobPos + Vector3.new(0, cfg.TweenHeight, 0), targetMobInfo.MobPos)
						)
					else
						TweenTo(CFrame.new(targetMobInfo.MobPos + currentEvasionOffset, targetMobInfo.MobPos))
					end
				end
			end)
			task.wait()
		end
	end)
end

local function StartAutoMaterialFarm()
	local generation = workerGeneration
	ToggleFloat(true)

	local activeMaterialMobInfo = GetBestMaterialMob()

	task.spawn(function()
		while isAutoMaterial and ScriptContext.Running and generation == workerGeneration do
			if IsHighPriorityActive("RegularFarm") then
				task.wait(1)
				break
			end
			local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
				or cfg.AttackIntervalFast
			local myChar = GetCharacter()
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if myHrp then
				local tName = currentTargetInstance and currentTargetInstance.Name
					or (activeMaterialMobInfo and activeMaterialMobInfo.Mob or nil)
				ExecuteAttack(myChar, myHrp, false, tName)
			end

			if interval <= 0 then
				task.wait()
			else
				task.wait(interval)
			end
		end
	end)

	local materialBringConn
	materialBringConn = RunService.Heartbeat:Connect(function()
		if not isAutoMaterial or not ScriptContext.Running or generation ~= workerGeneration then
			if materialBringConn then
				materialBringConn:Disconnect()
			end
			return
		end
		if IsHighPriorityActive("RegularFarm") then
			return
		end
		if isReadyToAttack then
			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			local target = currentTargetInstance
			local tHrp = target and target:FindFirstChild("HumanoidRootPart")
			if myHrp and tHrp then
				local enemiesFolder = workspace:FindFirstChild("Enemies")
				if enemiesFolder then
					local targetMobInfo = activeMaterialMobInfo or GetBestMaterialMob()
					if not targetMobInfo then
						return
					end
					local targetMobName = targetMobInfo.Mob
					local magnetPos = targetMobInfo and targetMobInfo.MobPos or tHrp.Position

					if magnetPos then
						UniversalMagnet(targetMobName, magnetPos, myHrp.Position)
					end
				end
			end
		end
	end)
	ScriptContext:AddConnection(materialBringConn)

	task.spawn(function()
		while isAutoMaterial and ScriptContext.Running and generation == workerGeneration do
			if IsHighPriorityActive("RegularFarm") then
				task.wait(1)
				break
			end
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				if not activeMaterialMobInfo or selectedMaterialTarget == "None" then
					activeMaterialMobInfo = GetBestMaterialMob()
					if not activeMaterialMobInfo then
						ToggleFloat(false)
						isReadyToAttack = false
						currentTargetInstance = nil
						return
					end
				end

				local now = os.clock()
				if now - lastEvasionTime >= cfg.EvasionTick then
					lastEvasionTime = now
					local radius = math.max(0, math.floor(cfg.EvasionRadius))
					currentEvasionOffset =
						Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
					lastEvasionMoveAt = 0
				end

				local targetMobInfo = activeMaterialMobInfo
				local targetMobName = targetMobInfo.Mob
				local targetEnemy = currentTargetInstance

				if targetEnemy then
					local h = targetEnemy:FindFirstChildOfClass("Humanoid")
					if h then
						if h.Health ~= lastTargetHealth then
							lastTargetHealth = h.Health
							lastTargetHealthChangeAt = now
						end

						if lastTargetHealthChangeAt > 0 and (now - lastTargetHealthChangeAt >= cfg.StuckTimeout) then
							if not IsBossEntity(targetEnemy) then
								enemyBlacklist[targetEnemy] = now + 3
								currentTargetInstance = nil
								isReadyToAttack = false
								targetEnemy = nil
							else
								lastTargetHealthChangeAt = now
							end
						end
					end
				end

				if not targetEnemy or not IsEnemyVulnerable(targetEnemy, targetMobName) then
					targetEnemy = GetTargetEnemy(targetMobName)

					if not targetEnemy then
						local checkNewMob = GetBestMaterialMob()
						if checkNewMob then
							activeMaterialMobInfo = checkNewMob
							targetMobInfo = activeMaterialMobInfo
							targetMobName = targetMobInfo.Mob
							targetEnemy = GetTargetEnemy(targetMobName)
						end
					end

					currentTargetInstance = targetEnemy
					if targetEnemy then
						local h = targetEnemy:FindFirstChildOfClass("Humanoid")
						lastTargetHealth = h and h.Health or -1
						lastTargetHealthChangeAt = now
					end
				end

				if targetEnemy then
					local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
						or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
					if tHrp then
						local mobProfile = GetMobProfileByName(targetEnemy.Name)
						local centerPos = mobProfile and mobProfile.MobPos or GetSafePosition(tHrp)

						local targetDistance = (centerPos - myHrp.Position).Magnitude
						UniversalEvasionTween(myHrp, centerPos, now)
					end
				else
					currentTargetInstance = nil
					isReadyToAttack = false
					local distToSpawn = (myHrp.Position - targetMobInfo.MobPos).Magnitude
					UniversalEvasionTween(myHrp, targetMobInfo.MobPos, now)
				end
			end)
			if not ok then
				warn("[Lonum Material Error]: " .. tostring(err))
				currentTargetInstance = nil
				isReadyToAttack = false
			end
			task.wait()
		end
	end)
end

local cakePrinceWorkerGeneration = 0

local function StartAutoCakePrince()
	local generation = cakePrinceWorkerGeneration

	local defaultCakeFallback =
		{ Name = "Cookie Crafters", Mob = "Cookie Crafter", MobPos = Vector3.new(-2374, 38, -12125) }
	local activeCakeMobInfo = GetBestCakeMob() or defaultCakeFallback

	task.spawn(function()
		while isAutoCakePrince and ScriptContext.Running and generation == cakePrinceWorkerGeneration do
			if isEliteHunterActive then
				task.wait(1)
				break
			end
			local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
				or cfg.AttackIntervalFast
			local myChar = GetCharacter()
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

			if myHrp then
				local tName = currentTargetInstance and currentTargetInstance.Name or activeCakeMobInfo.Mob

				local cakeBoss = nil
				local enemies = workspace:FindFirstChild("Enemies")
				if enemies then
					cakeBoss = enemies:FindFirstChild("Cake Prince")
				end

				if cakeBoss then
					tName = "Cake Prince"
				end
				ExecuteAttack(myChar, myHrp, false, tName)
			end

			if interval <= 0 then
				task.wait()
			else
				task.wait(interval)
			end
		end
	end)

	local cakeBringConn
	cakeBringConn = RunService.Heartbeat:Connect(function()
		if not isAutoCakePrince or not ScriptContext.Running or generation ~= cakePrinceWorkerGeneration then
			if cakeBringConn then
				cakeBringConn:Disconnect()
			end
			return
		end
		if isEliteHunterActive then
			return
		end
		if isReadyToAttack then
			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			local target = currentTargetInstance
			local tHrp = target and target:FindFirstChild("HumanoidRootPart")
			if myHrp and tHrp then
				local enemiesFolder = workspace:FindFirstChild("Enemies")
				if enemiesFolder then
					local targetMobInfo = activeCakeMobInfo or GetBestCakeMob()
					local targetMobName = targetMobInfo and targetMobInfo.Mob or target.Name
					if targetMobName == "Cake Prince" or targetMobName == "Dough King" then
						return
					end

					local magnetPos = targetMobInfo and targetMobInfo.MobPos or tHrp.Position
					if magnetPos then
						UniversalMagnet(targetMobName, magnetPos, myHrp.Position)
					end
				end
			end
		end
	end)
	ScriptContext:AddConnection(cakeBringConn)

	task.spawn(function()
		while isAutoCakePrince and ScriptContext.Running and generation == cakePrinceWorkerGeneration do
			if isEliteHunterActive then
				task.wait(1)
				break
			end
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				local now = os.clock()
				if now - lastEvasionTime >= cfg.EvasionTick then
					lastEvasionTime = now
					local radius = math.max(0, math.floor(cfg.EvasionRadius))
					currentEvasionOffset =
						Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
					lastEvasionMoveAt = 0
				end

				local status = getDripMamaStatus()

				if status == "ready" then
					CommF_:InvokeServer("CakePrinceSpawner")
				end

				local enemiesFolder = workspace:FindFirstChild("Enemies")
				local cakeBossSpawned = enemiesFolder and enemiesFolder:FindFirstChild("Cake Prince") ~= nil

				local targetMobInfo = activeCakeMobInfo
				local targetMobName = targetMobInfo.Mob

				if cakeBossSpawned then
					targetMobName = "Cake Prince"
				else
					if not activeCakeMobInfo then
						activeCakeMobInfo = GetBestCakeMob() or defaultCakeFallback
					end
					targetMobInfo = activeCakeMobInfo
					targetMobName = targetMobInfo.Mob
				end

				local targetEnemy = currentTargetInstance

				if targetEnemy then
					local h = targetEnemy:FindFirstChildOfClass("Humanoid")
					if h then
						if h.Health ~= lastTargetHealth then
							lastTargetHealth = h.Health
							lastTargetHealthChangeAt = now
						end

						if lastTargetHealthChangeAt > 0 and (now - lastTargetHealthChangeAt >= cfg.StuckTimeout) then
							if
								not IsBossEntity(targetEnemy)
								and targetEnemy.Name ~= "Cake Prince"
								and targetEnemy.Name ~= "Dough King"
							then
								enemyBlacklist[targetEnemy] = now + 3
								currentTargetInstance = nil
								isReadyToAttack = false
								targetEnemy = nil
							else
								lastTargetHealthChangeAt = now
							end
						end
					end
				end

				if not targetEnemy or not IsEnemyVulnerable(targetEnemy, targetMobName) then
					targetEnemy = GetTargetEnemy(targetMobName)
					if not targetEnemy and not cakeBossSpawned then
						local checkNewMob = GetBestCakeMob()
						if checkNewMob then
							activeCakeMobInfo = checkNewMob
							targetMobInfo = activeCakeMobInfo
							targetMobName = targetMobInfo.Mob
							targetEnemy = GetTargetEnemy(targetMobName)
						end
					end

					currentTargetInstance = targetEnemy
					if targetEnemy then
						local h = targetEnemy:FindFirstChildOfClass("Humanoid")
						lastTargetHealth = h and h.Health or -1
						lastTargetHealthChangeAt = now
					end
				end

				if targetEnemy then
					local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
						or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
					if tHrp then
						ToggleFloat(true)
						local mobProfile = GetMobProfileByName(targetEnemy.Name)
						local centerPos = mobProfile and mobProfile.MobPos or tHrp.Position

						if cakeBossSpawned then
							centerPos = tHrp.Position
						end

						local targetDistance = (centerPos - myHrp.Position).Magnitude
						if targetDistance > 80 then
							TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
							lastEvasionMoveAt = now
						else
							TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
						end
						isReadyToAttack = (GetSafePosition(tHrp) - myHrp.Position).Magnitude <= cfg.MaxPullRange
					end
				else
					currentTargetInstance = nil
					isReadyToAttack = false

					local distToSpawn = (myHrp.Position - targetMobInfo.MobPos).Magnitude
					ToggleFloat(true)
					if distToSpawn > 80 then
						if now - lastEvasionMoveAt >= cfg.EvasionTick then
							lastEvasionMoveAt = now
							TweenTo(
								CFrame.new(
									targetMobInfo.MobPos + Vector3.new(0, cfg.TweenHeight, 0),
									targetMobInfo.MobPos
								)
							)
						end
					else
						TweenTo(CFrame.new(targetMobInfo.MobPos + currentEvasionOffset, targetMobInfo.MobPos))
					end
				end
			end)
			if not ok then
				warn("[Lonum Error]: " .. tostring(err))
				currentTargetInstance = nil
				isReadyToAttack = false
				if not cfg.isTeleportingToIsland then
					ToggleFloat(false)
				end
			end
			task.wait()
		end
	end)
end

local doughKingWorkerGeneration = 0

local function StartAutoDoughKing()
	local generation = doughKingWorkerGeneration

	local defaultCakeFallback =
		{ Name = "Cookie Crafters", Mob = "Cookie Crafter", MobPos = Vector3.new(-2374, 38, -12125) }
	local activeCakeMobInfo = GetBestCakeMob() or defaultCakeFallback

	task.spawn(function()
		while isAutodoughKing and ScriptContext.Running and generation == doughKingWorkerGeneration do
			if isEliteHunterActive then
				task.wait(1)
				break
			end
			local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
				or cfg.AttackIntervalFast
			local myChar = GetCharacter()
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

			if myHrp then
				local tName = currentTargetInstance and currentTargetInstance.Name or activeCakeMobInfo.Mob

				local mapFolder = workspace:FindFirstChild("Map")
				local cakeDimension = mapFolder and mapFolder:FindFirstChild("MirrorDimension") or nil

				if not cakeDimension and mapFolder then
					for _, child in ipairs(mapFolder:GetChildren()) do
						if
							string.find(string.lower(child.Name), "dimension")
							and string.find(string.lower(child.Name), "cake")
						then
							cakeDimension = child
							break
						end
					end
				end

				local hasDoughKing = false
				local enemies = workspace:FindFirstChild("Enemies")
				if enemies then
					if enemies:FindFirstChild("Dough King") then
						hasDoughKing = true
						tName = "Dough King"
					end
				end

				if cakeDimension and not hasDoughKing and tName ~= "Dough King" then
					tName = "Dough King"
				end
				ExecuteAttack(myChar, myHrp, false, tName)
			end

			if interval <= 0 then
				task.wait()
			else
				task.wait(interval)
			end
		end
	end)

	local doughBringConn
	doughBringConn = RunService.Heartbeat:Connect(function()
		if not isAutoDoughKing or not ScriptContext.Running or generation ~= doughKingWorkerGeneration then
			if doughBringConn then
				doughBringConn:Disconnect()
			end
			return
		end
		if isEliteHunterActive then
			return
		end
		if isReadyToAttack then
			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			local target = currentTargetInstance
			local tHrp = target and target:FindFirstChild("HumanoidRootPart")
			if myHrp and tHrp then
				local enemiesFolder = workspace:FindFirstChild("Enemies")
				if enemiesFolder then
					local targetMobInfo = activeCakeMobInfo or GetBestCakeMob()
					local targetMobName = targetMobInfo and targetMobInfo.Mob or target.Name
					if targetMobName == "Cake Prince" or targetMobName == "Dough King" then
						return
					end

					local magnetPos = targetMobInfo and targetMobInfo.MobPos or tHrp.Position
					if magnetPos then
						UniversalMagnet(targetMobName, magnetPos, myHrp.Position)
					end
				end
			end
		end
	end)
	ScriptContext:AddConnection(doughBringConn)

	task.spawn(function()
		while isAutoDoughKing and ScriptContext.Running and generation == doughKingWorkerGeneration do
			if isEliteHunterActive then
				task.wait(1)
				break
			end
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				local now = os.clock()
				if now - lastEvasionTime >= cfg.EvasionTick then
					lastEvasionTime = now
					local radius = math.max(0, math.floor(cfg.EvasionRadius))
					currentEvasionOffset =
						Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
					lastEvasionMoveAt = 0
				end

				local status = getDripMamaStatus()

				if status == "ready" then
					CommF_:InvokeServer("CakePrinceSpawner")
				end

				local mapFolder = workspace:FindFirstChild("Map")
				local cakeDimension = mapFolder and mapFolder:FindFirstChild("MirrorDimension") or nil

				local targetMobInfo = activeCakeMobInfo
				local targetMobName = targetMobInfo.Mob

				if cakeDimension then
					targetMobName = "Dough King"
				else
					if not activeCakeMobInfo then
						activeCakeMobInfo = GetBestCakeMob() or defaultCakeFallback
					end
					targetMobInfo = activeCakeMobInfo
					targetMobName = targetMobInfo.Mob
				end

				local targetEnemy = currentTargetInstance

				if targetEnemy then
					local h = targetEnemy:FindFirstChildOfClass("Humanoid")
					if h then
						if h.Health ~= lastTargetHealth then
							lastTargetHealth = h.Health
							lastTargetHealthChangeAt = now
						end

						if lastTargetHealthChangeAt > 0 and (now - lastTargetHealthChangeAt >= cfg.StuckTimeout) then
							if
								not IsBossEntity(targetEnemy)
								and targetEnemy.Name ~= "Cake Prince"
								and targetEnemy.Name ~= "Dough King"
							then
								enemyBlacklist[targetEnemy] = now + 3
								currentTargetInstance = nil
								isReadyToAttack = false
								targetEnemy = nil
							else
								lastTargetHealthChangeAt = now
							end
						end
					end
				end

				if not targetEnemy or not IsEnemyVulnerable(targetEnemy, targetMobName) then
					targetEnemy = GetTargetEnemy(targetMobName)
					if not targetEnemy and not cakeDimension then
						local checkNewMob = GetBestCakeMob()
						if checkNewMob then
							activeCakeMobInfo = checkNewMob
							targetMobInfo = activeCakeMobInfo
							targetMobName = targetMobInfo.Mob
							targetEnemy = GetTargetEnemy(targetMobName)
						end
					end

					currentTargetInstance = targetEnemy
					if targetEnemy then
						local h = targetEnemy:FindFirstChildOfClass("Humanoid")
						lastTargetHealth = h and h.Health or -1
						lastTargetHealthChangeAt = now
					end
				end

				if targetEnemy then
					local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
						or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
					if tHrp then
						ToggleFloat(true)
						local mobProfile = GetMobProfileByName(targetEnemy.Name)
						local centerPos = mobProfile and mobProfile.MobPos or tHrp.Position

						if cakeDimension then
							centerPos = tHrp.Position
						end

						local targetDistance = (centerPos - myHrp.Position).Magnitude
						if targetDistance > 80 then
							TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
							lastEvasionMoveAt = now
						else
							TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
						end
						isReadyToAttack = (GetSafePosition(tHrp) - myHrp.Position).Magnitude <= cfg.MaxPullRange
					end
				else
					currentTargetInstance = nil
					isReadyToAttack = false

					if cakeDimension then
						local dimPos = GetSafePosition(cakeDimension)
						local distToDim = (myHrp.Position - dimPos).Magnitude
						ToggleFloat(true)
						if distToDim > 80 then
							if now - lastEvasionMoveAt >= cfg.EvasionTick then
								lastEvasionMoveAt = now
								TweenTo(CFrame.new(dimPos + Vector3.new(0, cfg.TweenHeight, 0), dimPos))
							end
						else
							TweenTo(CFrame.new(dimPos + currentEvasionOffset, dimPos))
						end
					else
						local distToSpawn = (myHrp.Position - targetMobInfo.MobPos).Magnitude
						ToggleFloat(true)
						if distToSpawn > 80 then
							if now - lastEvasionMoveAt >= cfg.EvasionTick then
								lastEvasionMoveAt = now
								TweenTo(
									CFrame.new(
										targetMobInfo.MobPos + Vector3.new(0, cfg.TweenHeight, 0),
										targetMobInfo.MobPos
									)
								)
							end
						else
							TweenTo(CFrame.new(targetMobInfo.MobPos + currentEvasionOffset, targetMobInfo.MobPos))
						end
					end
				end
			end)
			if not ok then
				warn("[Lonum Error]: " .. tostring(err))
				currentTargetInstance = nil
				isReadyToAttack = false
				if not cfg.isTeleportingToIsland then
					ToggleFloat(false)
				end
			end
			task.wait()
		end
	end)
end

function ScriptContext:GetAvailableBerryBushes()
	local CollectionService = game:GetService("CollectionService")
	local bushes = {}
	local tagged = CollectionService:GetTagged("BerryBushStreamed")

	for _, bush in ipairs(tagged) do
		local parent = bush.Parent
		if parent then
			local hasBerries = false
			for k, _ in pairs(parent:GetAttributes()) do
				if k:sub(1, 12) == "_BerryCFrame" and bush:GetAttribute(k) then
					hasBerries = true
					break
				end
			end
			if hasBerries then
				table.insert(bushes, bush)
			end
		end
	end

	if #bushes == 0 then
		local map = workspace:FindFirstChild("Map")
		if map then
			for _, desc in ipairs(map:GetDescendants()) do
				if desc:IsA("Model") or desc:IsA("Configuration") or desc:IsA("Folder") then
					local parent = desc.Parent
					if parent then
						for k, _ in pairs(parent:GetAttributes()) do
							if k:sub(1, 12) == "_BerryCFrame" and desc:GetAttribute(k) then
								table.insert(bushes, desc)
								break
							end
						end
					end
				end
			end
		end
	end

	return bushes
end

function ScriptContext:StartAutoBerry()
	cfg.autoBerryWorker = cfg.autoBerryWorker + 1
	local currentWorker = cfg.autoBerryWorker

	task.spawn(function()
		local Net = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
			and game:GetService("ReplicatedStorage").Modules:FindFirstChild("Net")
		local ClaimBerry = Net and require(Net):RemoteFunction("ClaimBerry")
		if not ClaimBerry then
			pcall(function()
				ClaimBerry = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
					and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("ClaimBerry")
			end)
		end

		while cfg.isAutoBerry and ScriptContext.Running and currentWorker == cfg.autoBerryWorker do
			local ok, err = pcall(function()
				local myChar = GetCharacter()
				local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				local bushes = ScriptContext:GetAvailableBerryBushes()
				if #bushes == 0 then
					task.wait(1.5)
					return
				end

				for _, bush in ipairs(bushes) do
					if not cfg.isAutoBerry or currentWorker ~= cfg.autoBerryWorker then
						break
					end
					local parent = bush.Parent
					if parent then
						for k, _ in pairs(parent:GetAttributes()) do
							if not cfg.isAutoBerry or currentWorker ~= cfg.autoBerryWorker then
								break
							end
							if k:sub(1, 12) == "_BerryCFrame" and bush:GetAttribute(k) then
								local claimed = false
								if ClaimBerry then
									pcall(function()
										claimed = ClaimBerry:InvokeServer(parent.Name, k)
									end)
								end

								if not claimed then
									local bushPivot = bush:GetPivot()
									local targetCF = bushPivot * CFrame.new(0, 3, 0)

									ToggleFloat(true)
									TweenTo(targetCF)

									local startTime = os.clock()
									while
										cfg.isAutoBerry
										and currentWorker == cfg.autoBerryWorker
										and (myHrp.Position - bushPivot.Position).Magnitude > 15
										and (os.clock() - startTime < 6)
									do
										task.wait(0.1)
									end

									if ClaimBerry then
										pcall(function()
											claimed = ClaimBerry:InvokeServer(parent.Name, k)
										end)
									end

									local prompt = bush:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled and hasProximity then
										pcall(function()
											fireproximityprompt(prompt)
										end)
									end
								end

								task.wait(0.35)
							end
						end
					end
				end
			end)
			if not ok then
				warn("[AutoBerry Error]: " .. tostring(err))
			end
			task.wait(0.5)
		end
	end)
end

function ScriptContext:StopAutoBerry()
	cfg.isAutoBerry = false
	cfg.autoBerryWorker = cfg.autoBerryWorker + 1
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
	ToggleFloat(false)
end

function ScriptContext:SpinFruitCousin()
	task.spawn(function()
		local Net = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
			and game:GetService("ReplicatedStorage").Modules:FindFirstChild("Net")
		local gachaRemote = Net and Net:FindFirstChild("RF/GachaNetworkRF")

		if not gachaRemote then
			if getgenv().LonumObject then
				getgenv().LonumObject:Notify({
					Title = "Spin Fruit Error",
					Content = "Remote GachaNetworkRF was not found!",
					Duration = 3,
					Image = 4483362458,
				})
			end
			return
		end

		local checkData = nil
		pcall(function()
			checkData = gachaRemote:InvokeServer({
				Context = "Check",
				BoxName = "ZiolesGacha",
			})
		end)

		if checkData and checkData.RequirementsMet == false and checkData.ErrorMessage then
			if getgenv().LonumObject then
				getgenv().LonumObject:Notify({
					Title = "Gacha Cooldown",
					Content = tostring(checkData.ErrorMessage),
					Duration = 4,
					Image = 4483362458,
				})
			end
			return
		end

		local success, result = pcall(function()
			return gachaRemote:InvokeServer({
				Context = "Purchase",
				BoxName = "ZiolesGacha",
			})
		end)

		print("[Spin Fruit Result]:", tostring(result))

		if not success then
			if getgenv().LonumObject then
				getgenv().LonumObject:Notify({
					Title = "Spin Fruit Error",
					Content = "Failed to invoke remote: " .. tostring(result),
					Duration = 4,
					Image = 4483362458,
				})
			end
			return
		end

		local resStr = tostring(result or "")
		local waitHours, waitMins = string.match(resStr, "(%d+):(%d+)")

		if waitHours and waitMins then
			local waitTime = waitHours .. ":" .. waitMins
			if getgenv().LonumObject then
				getgenv().LonumObject:Notify({
					Title = "Spin Cooldown",
					Content = "Still on cooldown! You can spin again in: " .. waitTime .. " (hours:minutes)",
					Duration = 5,
					Image = 4483362458,
				})
			end
		else
			print("[Spin Fruit Success / Gacha Screen Opened]:", resStr)
			if getgenv().LonumObject then
				getgenv().LonumObject:Notify({
					Title = "Spin Fruit",
					Content = "Spin successfully triggered! Response: "
						.. (resStr ~= "" and resStr or "Gacha screen opened."),
					Duration = 5,
					Image = 4483362458,
				})
			end
		end
	end)
end

local function StartAutoFarm()
	local generation = workerGeneration

	ToggleFloat(true)
	AttackThread(generation)

	task.spawn(function()
		while enabled and ScriptContext.Running and generation == workerGeneration do
			if IsHighPriorityActive("RegularFarm") then
				task.wait(1)
				break
			end
			local ok, err = pcall(function()
				local char = GetCharacter()
				local myHrp = char and char:FindFirstChild("HumanoidRootPart")

				if not myHrp then
					return
				end

				local hasQuestUI = HasActiveQuest()
				local profile = GetQuestProfile()
				if not profile then
					return
				end

				local now = os.clock()
				if now - lastEvasionTime >= cfg.EvasionTick then
					lastEvasionTime = now
					local radius = math.max(0, math.floor(cfg.EvasionRadius))
					currentEvasionOffset =
						Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
				end

				if isBossHunterEnabled and selectedBossName then
					local spawnedBoss, bossProfile = GetSpawnedBoss(selectedBossName)
					if not bossProfile then
						return
					end

					local bossQuestStatus = GetQuestStatus(bossProfile.Name)
					local hasBossQuest = bossQuestStatus.Active and bossQuestStatus.Correct

					if spawnedBoss then
						if not hasBossQuest then
							isReadyToAttack = false
							currentTargetInstance = nil
							if ClaimQuestHandler(myHrp, bossProfile.Quest, bossProfile.Stage, bossProfile.NPC) then
								task.wait(0.5)
							end
						else
							local bHrp = spawnedBoss:FindFirstChild("HumanoidRootPart")
							if bHrp then
								local targetDistance = (bHrp.Position - myHrp.Position).Magnitude

								if targetDistance > 80 then
									TweenTo(
										CFrame.new(bHrp.Position + Vector3.new(0, cfg.TweenHeight, 0), bHrp.Position)
									)
									lastEvasionMoveAt = now
								else
									if now - lastEvasionMoveAt >= cfg.EvasionTick then
										lastEvasionMoveAt = now
										TweenTo(CFrame.new(bHrp.Position + currentEvasionOffset, bHrp.Position))
									end
								end

								isReadyToAttack = (GetSafePosition(bHrp) - myHrp.Position).Magnitude <= cfg.MaxPullRange
								currentTargetInstance = spawnedBoss
							end
						end
					else
						currentTargetInstance = nil
						isReadyToAttack = false
						if (myHrp.Position - bossProfile.NPC).Magnitude > 8 then
							TweenTo(CFrame.new(bossProfile.NPC))
						else
							if activeTween then
								activeTween:Cancel()
								activeTween = nil
							end
						end
					end
					return
				end

				local questStatus = GetQuestStatus(profile.Mob)
				local isCorrectQuestOnUI = questStatus.Correct
				local isFinished = IsQuestFinished(profile)

				if isFinished then
					CycleQuestProfile()
					QuestCache.IsActive = false
					QuestCache.Finished = false
					QuestCache.MobName = nil
					QuestCache.Current = 0
					QuestCache.Maximum = 0
					QuestCache.LastSeen = 0
					isReadyToAttack = false
					currentTargetInstance = nil
					lastTargetRefreshAt = 0
					return
				end

				if hasQuestUI and not isCorrectQuestOnUI then
					if os.clock() - lastAbandonAttempt > 2 then
						pcall(function()
							CommF_:InvokeServer("AbandonQuest")
						end)
						lastAbandonAttempt = os.clock()
					end
					QuestCache.IsActive = false
					QuestCache.Finished = false
					QuestCache.MobName = nil
					QuestCache.LastSeen = 0
					isReadyToAttack = false
					currentTargetInstance = nil
					lastTargetRefreshAt = 0
					return
				end

				local recentlyTookQuest = (os.clock() - lastStartedQuestAt < 4)
				if not hasQuestUI and not recentlyTookQuest then
					isReadyToAttack = false
					currentTargetInstance = nil
					if (myHrp.Position - profile.NPC).Magnitude > 8 then
						TweenTo(CFrame.new(profile.NPC))
						return
					end
					if activeTween then
						activeTween:Cancel()
						activeTween = nil
					end
					pcall(function()
						CommF_:InvokeServer("StartQuest", profile.Quest, profile.Stage)
					end)
					lastStartedQuestKey = GetQuestProfileKey(profile)
					lastStartedQuestAt = os.clock()
					task.wait(0.2)
					return
				end

				local targetEnemy = currentTargetInstance
				if not targetEnemy or not IsEnemyVulnerable(targetEnemy, profile.Mob) then
					targetEnemy = GetTargetEnemy(profile.Mob)
					currentTargetInstance = targetEnemy
					lastTargetRefreshAt = now
					if targetEnemy then
						local h = targetEnemy:FindFirstChildOfClass("Humanoid")
						lastTargetHealth = h and h.Health or -1
						lastTargetHealthChangeAt = now
					end
				end

				if targetEnemy then
					local h = targetEnemy:FindFirstChildOfClass("Humanoid")
					if h then
						if h.Health ~= lastTargetHealth then
							lastTargetHealth = h.Health
							lastTargetHealthChangeAt = now
						end

						if lastTargetHealthChangeAt > 0 and (now - lastTargetHealthChangeAt >= cfg.StuckTimeout) then
							if not IsBossEntity(targetEnemy) then
								enemyBlacklist[targetEnemy] = now + 3
								currentTargetInstance = nil
								isReadyToAttack = false
								targetEnemy = nil
							else
								lastTargetHealthChangeAt = now
							end
						end
					end
				end

				if targetEnemy and targetEnemy.Parent then
					local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
						or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
					if tHrp then
						ToggleFloat(true)
						local centerPos = profile and profile.MobPos or GetSafePosition(tHrp)

						UniversalEvasionTween(myHrp, centerPos, now)

						local magnetPos = profile and profile.MobPos or tHrp.Position
						UniversalMagnet(profile.Mob, magnetPos, myHrp.Position)

						isReadyToAttack = (GetSafePosition(tHrp) - myHrp.Position).Magnitude <= cfg.MaxPullRange
					end
				else
					currentTargetInstance = nil
					isReadyToAttack = false
					ToggleFloat(true)
					local distToSpawn = (myHrp.Position - profile.MobPos).Magnitude
					UniversalEvasionTween(myHrp, profile.MobPos, now)
				end
			end)

			if not ok then
				warn("[Lonum Error]: " .. tostring(err))
				currentTargetInstance = nil
				isReadyToAttack = false
			end
			task.wait()
		end
	end)
end

local function StopAutoFarm()
	enabled = false
	isReadyToAttack = false
	StopAllActivities()
	cachedWeapon = nil
	cachedWeaponCategory = nil
	cachedEnemiesFolder = nil
	lastAttackAt = 0
	lastTargetRefreshAt = 0
	lastEvasionMoveAt = 0
	lastStartedQuestKey = nil
	lastStartedQuestAt = 0
	lastTargetHealth = -1
	lastTargetHealthChangeAt = 0
end

ScriptContext:AddConnection(RunService.Stepped:Connect(function()
	if ScriptContext.Running then
		local c = player.Character
		if c then
			local hrp = c:FindFirstChild("HumanoidRootPart")
			local hasFloat = hrp and hrp:FindFirstChild("AutofarmBv") ~= nil
			if
				activeTween
				or hasFloat
				or isTweeningToPlayer
				or isAutoTorch
				or enabled
				or isAutoRaidKill
				or isAutoBone
				or isAutoMaterial
				or isAutoDungeon
				or farmNearestEnabled
				or autoKillVolcano
				or isAutoCakePrince
				or cfg.isAutoBerry
			then
				local parts = { "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "Torso" }
				for _, partName in ipairs(parts) do
					local p = c:FindFirstChild(partName)
					if p and p:IsA("BasePart") and p.CanCollide then
						p.CanCollide = false
					end
				end
			end
		end
	end
end))

ScriptContext:AddConnection(RunService.Heartbeat:Connect(function(deltaTime)
	if not ScriptContext.Running then
		return
	end

	if cfg.autoBoat then
		currentBoat = GetBoat()
		if not currentBoat then
			local dealer = GetNearestBoatDealer()
			if dealer then
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if myHrp then
					local dealerPos = GetSafePosition(dealer)
					local dist = (myHrp.Position - dealerPos).Magnitude

					if dist > 20 then
						TweenTo(CFrame.new(dealerPos + Vector3.new(0, cfg.TweenHeight, 0)))
					else
						if activeTween then
							activeTween:Cancel()
							activeTween = nil
						end
						BuyBoat()
					end
				end
			else
				if activeTween then
					activeTween:Cancel()
					activeTween = nil
				end
			end
		else
			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end
			BoardBoat(currentBoat)
		end
	end

	if cfg.autoSail and currentBoat then
		currentIsland = GetNearestIsland()
		if currentIsland then
			local boatSeat = currentBoat:FindFirstChild("VehicleSeat")
			if boatSeat then
				local targetPosition = currentIsland.HumanoidRootPart.Position
				TweenTo(CFrame.new(targetPosition))
			end
		end
	end

	if cfg.boatSpeedMod then
		local myBoat = nil
		if workspace:FindFirstChild("Boats") then
			for _, boat in ipairs(workspace.Boats:GetChildren()) do
				local ownerVal = boat:FindFirstChild("Owner")
				if ownerVal then
					local isMine = false
					if ownerVal:IsA("ObjectValue") and ownerVal.Value == player then
						isMine = true
					elseif ownerVal:IsA("StringValue") and ownerVal.Value == player.Name then
						isMine = true
					elseif tostring(ownerVal.Value) == player.Name then
						isMine = true
					end

					if isMine then
						myBoat = boat
						break
					end
				end
			end
		end

		if myBoat then
			local seat = myBoat:FindFirstChild("VehicleSeat")
			if seat and seat:IsA("VehicleSeat") then
				seat.MaxSpeed = cfg.boatMaxSpeed
				seat.TurnSpeed = math.clamp(cfg.boatMaxSpeed / 100, 1, 3)
			end
		end
	end

	if cfg.autoFruit and #fruitWaypoints > 0 then
		CollectNearestFruit()
	end
	if cfg.autoChest then
		ScanForChests()
		CollectNearestChest()
	end
	if cfg.dodgeEnabled then
		DodgeAttack()
	end

	if enabled and isReadyToAttack then
		local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
		local target = currentTargetInstance
		local tHrp = target and target:FindFirstChild("HumanoidRootPart")

		if myHrp and tHrp then
			local targetMobName = nil
			local profile = nil
			if isBossHunterEnabled and selectedBossName then
				targetMobName = selectedBossName
			else
				profile = GetQuestProfile()
				if profile then
					targetMobName = profile.Mob
				end
			end

			if targetMobName then
				if not cachedEnemiesFolder or not cachedEnemiesFolder.Parent then
					cachedEnemiesFolder = workspace:FindFirstChild("Enemies")
				end
				if cachedEnemiesFolder then
					local magnetPos = nil
					if profile and profile.MobPos then
						magnetPos = profile.MobPos
					elseif currentTargetInstance and currentTargetInstance:FindFirstChild("HumanoidRootPart") then
						magnetPos = currentTargetInstance.HumanoidRootPart.Position
					end

					if magnetPos then
						UniversalMagnet(targetMobName, magnetPos, myHrp.Position)
					end
				end
			end
		end
	end
end))

task.spawn(function()
	while task.wait(1) do
		if not ScriptContext.Running then
			break
		end
		if cfg.autoFruit then
			ScanForFruits()
		end
	end
end)

task.spawn(function()
	while task.wait(0.2) do
		if not ScriptContext.Running then
			break
		end
		if isAutoSpinBones then
			pcall(function()
				local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
					and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
				if CommF_ then
					local bonesCount = CommF_:InvokeServer("Bones", "Check")
					if type(bonesCount) == "number" and bonesCount >= 50 then
						CommF_:InvokeServer("Bones", "Buy", 1, 1)
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.5) do
		if not ScriptContext.Running then
			break
		end
		if isAutoStatsEnabled then
			local data = player:FindFirstChild("Data")
			local points = data and data:FindFirstChild("Points")
			if points and points.Value > 0 then
				pcall(function()
					if CommF_ then
						CommF_:InvokeServer("AddPoint", selectedStatCategory, 1)
					end
				end)
			end
		end
	end
end)

task.spawn(function()
	while task.wait() do
		if not ScriptContext.Running then
			break
		end
		if isAutoKenEnabled then
			local c = GetCharacter()
			local h = GetHumanoid()
			if c and h and h.Health > 0 then
				if not c:FindFirstChild("KenDisabled") then
					pcall(function()
						local isKenActive = game.ReplicatedStorage.Events.IsObservationActive:Invoke()
						if not isKenActive then
							pcall(function()
								VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
								task.wait(0.1)
								VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
							end)
						end
					end)
				end
			end
		end
	end
end)

local raidWorkerGeneration = 0

local function GetTargetRaidIsland()
	local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	local raidMap = ScriptContext:GetRaidMap()
	if not myHrp or not raidMap then
		return nil, 0
	end

	local currLocStr = tostring(player:GetAttribute("CurrentLocation") or "")
	local exactLocStr = tostring(player:GetAttribute("ExactLocation") or "")
	local isRaiding = (player:GetAttribute("IslandRaiding") == true)
		or string.match(currLocStr, "Island%s*%d+") ~= nil
		or string.match(exactLocStr, "Island%s*%d+") ~= nil
	if not isRaiding then
		return nil, 0
	end

	local currentNum = tonumber(string.match(currLocStr, "%d+")) or tonumber(string.match(exactLocStr, "%d+")) or 1
	local nextNum = currentNum + 1

	local islandMap = {}
	for _, island in ipairs(raidMap:GetChildren()) do
		local nameLower = string.lower(island.Name)
		if string.find(nameLower, "island") or string.find(nameLower, "raid") then
			local numStr = string.match(island.Name, "%d+")
			local islandNum = numStr and tonumber(numStr) or 0
			if islandNum > 0 then
				islandMap[islandNum] = island
			end
		end
	end

	local currentIsland = islandMap[currentNum]
	local nextIsland = islandMap[nextNum]

	if currentIsland then
		local cDist = (myHrp.Position - GetSafePosition(currentIsland)).Magnitude

		local hasEnemies = false
		local enemiesFolder = workspace:FindFirstChild("Enemies")
		if enemiesFolder then
			for _, v in ipairs(enemiesFolder:GetChildren()) do
				if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
					hasEnemies = true
					break
				end
			end
		end

		if not hasEnemies and nextIsland then
			return nextIsland, nextNum
		end

		if cDist > 150 then
			return currentIsland, currentNum
		elseif nextIsland then
			return nextIsland, nextNum
		else
			return currentIsland, currentNum
		end
	elseif nextIsland then
		return nextIsland, nextNum
	end

	local closestIsland, closestNum, closestDist = nil, 0, math.huge
	for num, island in pairs(islandMap) do
		local dist = (myHrp.Position - GetSafePosition(island)).Magnitude
		if dist < closestDist then
			closestDist = dist
			closestIsland = island
			closestNum = num
		end
	end

	if closestIsland then
		return closestIsland, closestNum
	end

	return nil, 0
end

local function StartAutoRaid()
	raidWorkerGeneration = raidWorkerGeneration + 1
	local generation = raidWorkerGeneration
	ToggleFloat(true)

	task.spawn(function()
		while isAutoRaidKill and ScriptContext.Running and generation == raidWorkerGeneration do
			if isReadyToAttack and isAutoRaidAttack then
				local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
					or cfg.AttackIntervalFast
				local myChar = GetCharacter()
				local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
				if myHrp then
					local tName = currentTargetInstance and currentTargetInstance.Name or nil
					ExecuteAttack(myChar, myHrp, false, tName)
				end

				if interval <= 0 then
					task.wait()
				else
					task.wait(interval)
				end
			else
				task.wait()
			end
		end
	end)

	local raidBringConn
	raidBringConn = RunService.Heartbeat:Connect(function()
		if not isAutoRaidKill or not ScriptContext.Running or generation ~= raidWorkerGeneration then
			if raidBringConn then
				raidBringConn:Disconnect()
			end
			return
		end

		local raidMap = ScriptContext:GetRaidMap()
		if not raidMap then
			return
		end

		local myChar = GetCharacter()
		local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

		if isReadyToAttack and isAutoRaidBring then
			local target = currentTargetInstance
			local tHrp = target
				and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart", true))
			if myHrp and tHrp then
				local magnetPos = GetSafePosition(tHrp)
				if magnetPos and magnetPos ~= Vector3.zero then
					UniversalMagnet(nil, magnetPos, myHrp.Position)
				end
			end
		end
	end)
	ScriptContext:AddConnection(raidBringConn)

	local raidEmptyTimer = 0

	task.spawn(function()
		while isAutoRaidKill and ScriptContext.Running and generation == raidWorkerGeneration do
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				local now = os.clock()
				if now - lastEvasionTime >= cfg.EvasionTick then
					lastEvasionTime = now
					local radius = math.max(0, math.floor(cfg.EvasionRadius))
					currentEvasionOffset =
						Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
					lastEvasionMoveAt = 0
				end

				local enemiesFolder = workspace:FindFirstChild("Enemies")
				local raidMap = ScriptContext:GetRaidMap()

				if not raidMap then
					if activeTween then
						activeTween:Cancel()
						activeTween = nil
					end
					ToggleFloat(false)
					currentTargetInstance = nil
					isReadyToAttack = false
					return
				end

				local targetEnemy = currentTargetInstance

				if not targetEnemy or not IsEnemyVulnerable(targetEnemy) then
					local closest = nil

					local shortestDist = 1500
					if enemiesFolder then
						for _, enemy in ipairs(enemiesFolder:GetChildren()) do
							if enemy.Name == "PropHitboxPlaceholder" and IsEnemyVulnerable(enemy) then
								closest = enemy
								break
							end
						end

						if not closest then
							for _, enemy in ipairs(enemiesFolder:GetChildren()) do
								if IsEnemyVulnerable(enemy) then
									local eHrp = enemy:FindFirstChild("HumanoidRootPart")
										or enemy:FindFirstChildWhichIsA("BasePart", true)
									if eHrp then
										local dist = (GetSafePosition(eHrp) - myHrp.Position).Magnitude
										if dist < shortestDist then
											shortestDist = dist
											closest = enemy
										end
									end
								end
							end
						end
					end
					targetEnemy = closest
					currentTargetInstance = targetEnemy
					if targetEnemy then
						local h = targetEnemy:FindFirstChildOfClass("Humanoid")
						lastTargetHealth = h and h.Health or -1
						lastTargetHealthChangeAt = now
					end
				end

				if targetEnemy then
					local h = targetEnemy:FindFirstChildOfClass("Humanoid")
					if h then
						if h.Health ~= lastTargetHealth then
							lastTargetHealth = h.Health
							lastTargetHealthChangeAt = now
						end

						if lastTargetHealthChangeAt > 0 and (now - lastTargetHealthChangeAt >= cfg.StuckTimeout) then
							if not IsBossEntity(targetEnemy) then
								enemyBlacklist[targetEnemy] = now + 3
								currentTargetInstance = nil
								isReadyToAttack = false
								targetEnemy = nil
							else
								lastTargetHealthChangeAt = now
							end
						end
					end
				end

				if targetEnemy then
					raidEmptyTimer = now
					local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
						or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
					if tHrp then
						local centerPos = GetSafePosition(tHrp)

						local targetDistance = (centerPos - myHrp.Position).Magnitude
						if targetDistance > 80 then
							TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
							lastEvasionMoveAt = now
						else
							TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
						end

						isReadyToAttack = (GetSafePosition(tHrp) - myHrp.Position).Magnitude <= cfg.MaxPullRange
					end
				else
					isReadyToAttack = false
					currentTargetInstance = nil

					if raidEmptyTimer == 0 then
						raidEmptyTimer = now
					end

					if isAutoRaidNextIsland and (now - raidEmptyTimer >= 1) then
						local activeIsland, activeIslandNum = GetTargetRaidIsland()
						if activeIsland then
							local iPos = GetSafePosition(activeIsland)
							local dist = (myHrp.Position - iPos).Magnitude

							if dist > 15000 then
								if activeTween then
									activeTween:Cancel()
									activeTween = nil
								end
								ToggleFloat(true)
								return
							end

							if activeIslandNum >= 5 and dist <= 150 then
								if activeTween then
									activeTween:Cancel()
									activeTween = nil
								end
								ToggleFloat(true)
								return
							end

							if dist > 80 then
								TweenTo(CFrame.new(iPos + Vector3.new(0, 60, 0), iPos))
							else
								TweenTo(CFrame.new(iPos + currentEvasionOffset, iPos))
							end
						else
							if activeTween then
								activeTween:Cancel()
								activeTween = nil
							end
							ToggleFloat(true)
						end
					else
						ToggleFloat(true)
					end
				end
			end)
			task.wait()
		end
	end)
end

local function StartFarmNearest()
	local generation = workerGeneration
	ToggleFloat(true)

	task.spawn(function()
		while farmNearestEnabled and ScriptContext.Running and generation == workerGeneration do
			local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
				or cfg.AttackIntervalFast
			local myChar = GetCharacter()
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if myHrp then
				local tName = currentTargetInstance and currentTargetInstance.Name or nil
				ExecuteAttack(myChar, myHrp, false, tName)
			end

			if interval <= 0 then
				task.wait()
			else
				task.wait(interval)
			end
		end
	end)

	local nearestBringConn
	nearestBringConn = RunService.Heartbeat:Connect(function()
		if not farmNearestEnabled or not ScriptContext.Running or generation ~= workerGeneration then
			if nearestBringConn then
				nearestBringConn:Disconnect()
			end
			return
		end
		if isReadyToAttack then
			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			local target = currentTargetInstance
			local tHrp = target
				and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart", true))
			if myHrp and tHrp then
				local enemiesFolder = workspace:FindFirstChild("Enemies")
				if enemiesFolder then
					local magnetPos = GetSafePosition(tHrp)
					if magnetPos and magnetPos ~= Vector3.zero then
						UniversalMagnet(nil, magnetPos, myHrp.Position)
					end
				end
			end
		end
	end)
	ScriptContext:AddConnection(nearestBringConn)

	task.spawn(function()
		while farmNearestEnabled and ScriptContext.Running and generation == workerGeneration do
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				local now = os.clock()
				if now - lastEvasionTime >= cfg.EvasionTick then
					lastEvasionTime = now
					local radius = math.max(0, math.floor(cfg.EvasionRadius))
					currentEvasionOffset =
						Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
					lastEvasionMoveAt = 0
				end

				local targetEnemy = currentTargetInstance
				if targetEnemy then
					local h = targetEnemy:FindFirstChildOfClass("Humanoid")
					if h then
						if h.Health ~= lastTargetHealth then
							lastTargetHealth = h.Health
							lastTargetHealthChangeAt = now
						end

						if lastTargetHealthChangeAt > 0 and (now - lastTargetHealthChangeAt >= cfg.StuckTimeout) then
							if not IsBossEntity(targetEnemy) then
								enemyBlacklist[targetEnemy] = now + 3
								currentTargetInstance = nil
								isReadyToAttack = false
								targetEnemy = nil
							else
								lastTargetHealthChangeAt = now
							end
						end
					end
				end

				if not targetEnemy or not IsEnemyVulnerable(targetEnemy, nil) then
					targetEnemy = GetTargetEnemy(nil)
					currentTargetInstance = targetEnemy
					if targetEnemy then
						local h = targetEnemy:FindFirstChildOfClass("Humanoid")
						lastTargetHealth = h and h.Health or -1
						lastTargetHealthChangeAt = now
					end
				end

				if targetEnemy then
					local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
						or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
					if tHrp then
						local centerPos = GetSafePosition(tHrp)

						local targetDistance = (centerPos - myHrp.Position).Magnitude
						if targetDistance > 80 then
							TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
							lastEvasionMoveAt = now
						else
							TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
						end

						isReadyToAttack = (GetSafePosition(tHrp) - myHrp.Position).Magnitude <= cfg.MaxPullRange
					end
				else
					currentTargetInstance = nil
					isReadyToAttack = false
					ToggleFloat(true)
				end
			end)
			task.wait(0.05)
		end
	end)
end

local function GetNearestDungeonExit()
	local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	local mapFolder = workspace:FindFirstChild("Map")
	local dungeonFolder = nil
	if mapFolder then
		dungeonFolder = mapFolder:FindFirstChild("Dungeon")
		if not dungeonFolder then
			for _, child in ipairs(mapFolder:GetChildren()) do
				if string.find(child.Name, "Dungeon") then
					dungeonFolder = child
					break
				end
			end
		end
	end

	if
		not dungeonFolder
		and workspace:FindFirstChild("_WorldOrigin")
		and workspace._WorldOrigin:FindFirstChild("Locations")
	then
		for _, child in ipairs(workspace._WorldOrigin.Locations:GetChildren()) do
			if string.find(child.Name, "Dungeon") then
				dungeonFolder = child
				break
			end
		end
	end

	if not myHrp or not dungeonFolder then
		return nil
	end

	local nearestExitPos = nil
	local shortestDist = math.huge

	for _, dung in ipairs(dungeonFolder:GetChildren()) do
		local exitEntrance = dung:FindFirstChild("ExitEntrance") or dung:FindFirstChild("ExitTeleporter")
		if exitEntrance then
			local targetPos = nil
			if exitEntrance:IsA("Model") and exitEntrance.PrimaryPart then
				targetPos = exitEntrance.PrimaryPart.Position
			elseif exitEntrance:IsA("BasePart") then
				targetPos = exitEntrance.Position
			end

			if targetPos then
				local dist = (myHrp.Position - targetPos).Magnitude

				if dist < shortestDist and dist < 5000 then
					shortestDist = dist
					nearestExitPos = targetPos
				end
			end
		end
	end

	return nearestExitPos
end

local function StartAutoDungeon()
	local generation = dungeonWorkerGeneration
	ToggleFloat(true)

	task.spawn(function()
		while isAutoDungeon and ScriptContext.Running and generation == dungeonWorkerGeneration do
			if isReadyToAttack and isAutoDungeonAttack then
				local now = os.clock()
				local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
					or cfg.AttackIntervalFast
				if now - lastAttackAt >= interval then
					local myChar = GetCharacter()
					local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
					if myHrp then
						ExecuteAttack(myChar, myHrp)
						lastAttackAt = now
					end
				end
				if attackSpeedMode == "Super Fast Attack" then
					task.wait()
				else
					task.wait(cfg.ThreadSleep)
				end
			else
				task.wait(cfg.ThreadSleep)
			end
		end
	end)

	local dungeonBringConn
	dungeonBringConn = RunService.Heartbeat:Connect(function()
		if not isAutoDungeon or not ScriptContext.Running or generation ~= dungeonWorkerGeneration then
			if dungeonBringConn then
				dungeonBringConn:Disconnect()
			end
			return
		end

		if isReadyToAttack and isAutoDungeonBring then
			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			local target = currentTargetInstance
			local tHrp = target and target:FindFirstChild("HumanoidRootPart")
			if myHrp and tHrp then
				local enemiesFolder = workspace:FindFirstChild("Enemies")
				if enemiesFolder then
					local targetMobName = target.Name
					local magnetPos = targetMobInfo and targetMobInfo.MobPos or tHrp.Position
					if magnetPos then
						UniversalMagnet(targetMobName, magnetPos, myHrp.Position)
					end
				end
			end
		end
	end)
	ScriptContext:AddConnection(dungeonBringConn)

	task.spawn(function()
		while isAutoDungeon and ScriptContext.Running and generation == dungeonWorkerGeneration do
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				local isDungeon = workspace:GetAttribute("IsDungeonInstance")
				if not isDungeon then
					isReadyToAttack = false
					currentTargetInstance = nil
					if activeTween then
						activeTween:Cancel()
						activeTween = nil
					end
					return
				end

				local now = os.clock()
				if now - lastEvasionTime >= cfg.EvasionTick then
					lastEvasionTime = now
					local radius = math.max(0, math.floor(cfg.EvasionRadius))
					currentEvasionOffset =
						Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
					lastEvasionMoveAt = 0
				end

				local enemiesFolder = workspace:FindFirstChild("Enemies")
				local targetEnemy = currentTargetInstance

				if targetEnemy then
					local h = targetEnemy:FindFirstChildOfClass("Humanoid")
					if h then
						if h.Health ~= lastTargetHealth then
							lastTargetHealth = h.Health
							lastTargetHealthChangeAt = now
						end
						if lastTargetHealthChangeAt > 0 and (now - lastTargetHealthChangeAt >= cfg.StuckTimeout) then
							if not IsBossEntity(targetEnemy) then
								enemyBlacklist[targetEnemy] = now + 3
								currentTargetInstance = nil
								isReadyToAttack = false
								targetEnemy = nil
							else
								lastTargetHealthChangeAt = now
							end
						end
					end
				end

				if enemiesFolder then
					for _, enemy in ipairs(enemiesFolder:GetChildren()) do
						if
							enemy.Parent == enemiesFolder
							and enemy.Name == "PropHitboxPlaceholder"
							and IsEnemyVulnerable(enemy)
						then
							targetEnemy = enemy
							currentTargetInstance = targetEnemy
							if targetEnemy then
								local h = targetEnemy:FindFirstChildOfClass("Humanoid")
								lastTargetHealth = h and h.Health or -1
								lastTargetHealthChangeAt = now
							end
							break
						end
					end
				end

				if not targetEnemy or not IsEnemyVulnerable(targetEnemy) then
					if currentTargetInstance then
						if activeTween then
							activeTween:Cancel()
							activeTween = nil
						end
						currentTargetInstance = nil
					end

					local closest = nil
					local shortestDist = math.huge
					if enemiesFolder then
						for _, enemy in ipairs(enemiesFolder:GetChildren()) do
							if
								enemy.Parent == enemiesFolder
								and enemy.Name == "PropHitboxPlaceholder"
								and IsEnemyVulnerable(enemy)
							then
								closest = enemy
								break
							end
						end

						if not closest then
							for _, enemy in ipairs(enemiesFolder:GetChildren()) do
								if enemy.Parent == enemiesFolder and IsEnemyVulnerable(enemy) then
									local eHrp = enemy:FindFirstChild("HumanoidRootPart")
										or enemy:FindFirstChildWhichIsA("BasePart", true)
									if eHrp then
										local dist = (GetSafePosition(eHrp) - myHrp.Position).Magnitude
										if dist < shortestDist then
											shortestDist = dist
											closest = enemy
										end
									end
								end
							end
						end
					end
					targetEnemy = closest
					currentTargetInstance = targetEnemy
					if targetEnemy then
						local h = targetEnemy:FindFirstChildOfClass("Humanoid")
						lastTargetHealth = h and h.Health or -1
						lastTargetHealthChangeAt = now
					end
				end

				if targetEnemy then
					local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
						or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
					if tHrp then
						local centerPos = GetSafePosition(tHrp)
						local targetDistance = (centerPos - myHrp.Position).Magnitude

						if targetDistance > 2000 then
							currentTargetInstance = nil
							targetEnemy = nil
							isReadyToAttack = false
							if activeTween then
								activeTween:Cancel()
								activeTween = nil
							end
							return
						end

						if targetDistance > 80 then
							TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
							lastEvasionMoveAt = now
						else
							TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
						end
						isReadyToAttack = (GetSafePosition(tHrp) - myHrp.Position).Magnitude <= cfg.MaxPullRange
					end
				else
					isReadyToAttack = false
					currentTargetInstance = nil

					if isAutoDungeonNext then
						local exitPos = GetNearestDungeonExit()
						if exitPos then
							local myHrpPos = myHrp.Position
							local dist = (myHrpPos - exitPos).Magnitude
							if dist > 15 then
								if now - lastEvasionMoveAt >= cfg.EvasionTick then
									lastEvasionMoveAt = now
									TweenTo(CFrame.new(exitPos))
								end
								TweenTo(CFrame.new(exitPos))
							else
								if activeTween then
									activeTween:Cancel()
									activeTween = nil
								end
								myHrp.CFrame = CFrame.new(exitPos)
							end
						else
							if activeTween then
								activeTween:Cancel()
								activeTween = nil
							end
						end
					else
						if activeTween then
							activeTween:Cancel()
							activeTween = nil
						end
					end
				end
			end)
			task.wait()
		end
	end)
end

local function StartAutoKillVolcano()
	local generation = workerGeneration
	ToggleFloat(true)

	task.spawn(function()
		while autoKillVolcano and ScriptContext.Running and generation == workerGeneration do
			if isReadyToAttack then
				local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
					or cfg.AttackIntervalFast
				local myChar = GetCharacter()
				local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
				if myHrp then
					local tName = currentTargetInstance and currentTargetInstance.Name or nil
					ExecuteAttack(myChar, myHrp, false, tName)
				end

				if interval <= 0 then
					task.wait()
				else
					task.wait(interval)
				end
			else
				task.wait(cfg.ThreadSleep)
			end
		end
	end)

	local volcanoBringConn
	volcanoBringConn = RunService.Heartbeat:Connect(function()
		if not autoKillVolcano or generation ~= workerGeneration then
			if volcanoBringConn then
				volcanoBringConn:Disconnect()
				volcanoBringConn = nil
			end
			return
		end

		if isReadyToAttack then
			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			local target = currentTargetInstance
			local tHrp = target and target:FindFirstChild("HumanoidRootPart")

			if myHrp and tHrp and target and target.Parent then
				UniversalMagnet("Lava Golem", tHrp.Position, myHrp.Position)
			end
		end
	end)
	ScriptContext:AddConnection(volcanoBringConn)

	task.spawn(function()
		while autoKillVolcano and ScriptContext.Running and generation == workerGeneration do
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				local now = os.clock()
				if now - lastEvasionTime >= cfg.EvasionTick then
					lastEvasionTime = now
					local radius = math.max(0, math.floor(cfg.EvasionRadius))
					currentEvasionOffset =
						Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
					lastEvasionMoveAt = 0
				end

				local targetEnemy = currentTargetInstance
				if targetEnemy then
					local h = targetEnemy:FindFirstChildOfClass("Humanoid")
					if h then
						if h.Health ~= lastTargetHealth then
							lastTargetHealth = h.Health
							lastTargetHealthChangeAt = now
						end

						if lastTargetHealthChangeAt > 0 and (now - lastTargetHealthChangeAt >= cfg.StuckTimeout) then
							if not IsBossEntity(targetEnemy) then
								enemyBlacklist[targetEnemy] = now + 3
								currentTargetInstance = nil
								isReadyToAttack = false
								targetEnemy = nil
							else
								lastTargetHealthChangeAt = now
							end
						end
					end
				end

				if not targetEnemy or not IsEnemyVulnerable(targetEnemy, nil) then
					targetEnemy = GetTargetEnemy(nil)
					currentTargetInstance = targetEnemy
					if targetEnemy then
						local h = targetEnemy:FindFirstChildOfClass("Humanoid")
						lastTargetHealth = h and h.Health or -1
						lastTargetHealthChangeAt = now
					end
				end

				if targetEnemy then
					local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
						or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
					if tHrp then
						local centerPos = myHrp.Position

						local targetDistance = (centerPos - myHrp.Position).Magnitude
						if targetDistance > 80 then
							TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
							lastEvasionMoveAt = now
						else
							TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
						end

						isReadyToAttack = (GetSafePosition(tHrp) - myHrp.Position).Magnitude <= cfg.MaxPullRange
					end
				else
					currentTargetInstance = nil
					isReadyToAttack = false
					if activeTween then
						activeTween:Cancel()
						activeTween = nil
					end
				end
			end)
			task.wait()
		end
	end)
end

isAutoTorch = false
local autoTorchWorker = 0

local function StartAutoTorch()
	if isAutoTorch then
		return
	end
	isAutoTorch = true
	autoTorchWorker = autoTorchWorker + 1
	local gen = autoTorchWorker
	ToggleFloat(true)

	local litTorches = {}

	task.spawn(function()
		while isAutoTorch and ScriptContext.Running and gen == autoTorchWorker do
			local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			if not hrp then
				task.wait(1)
			else
				local turtle = workspace.Map:FindFirstChild("Turtle")
				local torchesFolder = turtle and turtle:FindFirstChild("QuestTorches")

				if torchesFolder then
					local foundUnlit = false

					for i = 1, 5 do
						if not litTorches[i] then
							local torch = torchesFolder:FindFirstChild("Torch" .. i)
							if torch and torch:IsA("BasePart") then
								local dist = (hrp.Position - torch.Position).Magnitude

								local touchDist = hasFireTouch and 300 or 10

								if dist > touchDist then
									TweenTo(CFrame.new(torch.Position + Vector3.new(0, 5, 0), torch.Position))
								else
									local touched = SafeTouch(torch, hrp, touchDist)
									if touched then
										litTorches[i] = true
										if activeTween then
											activeTween:Cancel()
											activeTween = nil
										end
										task.wait(0.5)
									end
								end
								foundUnlit = true
								break
							else
								litTorches[i] = true
							end
						end
					end

					if not foundUnlit then
						isAutoTorch = false
						StopAllActivities()
					end
				end
			end
			task.wait()
		end
	end)
end

local autoFactoryWorker = 0

local function StartAutoFactory()
	if isAutoFactory then
		return
	end
	isAutoFactory = true
	autoFactoryWorker = autoFactoryWorker + 1
	local gen = autoFactoryWorker

	task.spawn(function()
		while isAutoFactory and ScriptContext.Running and gen == autoFactoryWorker do
			local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			if not hrp then
				task.wait()
			else
				local enemiesFolder = workspace:FindFirstChild("Enemies")
				local targetCore = nil

				if enemiesFolder then
					for _, enemy in ipairs(enemiesFolder:GetChildren()) do
						if enemy.Name == "Core" and IsEnemyVulnerable(enemy, "Core") then
							targetCore = enemy
							break
						end
					end
				end

				if targetCore then
					local tHrp = targetCore:FindFirstChild("HumanoidRootPart")
						or targetCore:FindFirstChildWhichIsA("BasePart", true)
					if tHrp then
						ToggleFloat(true)

						local now = os.clock()
						if now - lastEvasionTime >= cfg.EvasionTick then
							lastEvasionTime = now
							local radius = math.max(0, math.floor(cfg.EvasionRadius))
							currentEvasionOffset =
								Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
							lastEvasionMoveAt = 0
						end

						local centerPos = mobProfile and mobProfile.MobPos or tHrp.Position
						local dist = (hrp.Position - centerPos).Magnitude

						if dist > 80 then
							TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
						else
							TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
						end

						if dist <= cfg.HitRadius then
							local myChar = GetCharacter()
							local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
								or cfg.AttackIntervalFast
							local timeSinceLastAtk = os.clock() - lastAttackAt

							if timeSinceLastAtk >= interval then
								ExecuteAttack(myChar, hrp, false, "Core")
								lastAttackAt = os.clock()
							end
						end
					end
				else
					if not cfg.isTeleportingToIsland then
						if activeTween then
							activeTween:Cancel()
							activeTween = nil
						end
						ToggleFloat(false)
					end
				end
			end

			if targetCore and attackSpeedMode == "Super Fast Attack" then
				task.wait()
			else
				task.wait(cfg.ThreadSleep)
			end
		end
	end)
end

local function StartStandaloneAutoAttackThread()
	task.spawn(function()
		while ScriptContext.Running do
			if isAutoAttackEnabled and not (enabled and isReadyToAttack) then
				local now = os.clock()
				local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
					or cfg.AttackIntervalFast

				if now - lastAttackAt >= interval then
					local myChar = GetCharacter()
					local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

					if myHrp then
						local target = currentTargetInstance
						if
							not target
							or not target.Parent
							or not target:FindFirstChild("Humanoid")
							or target.Humanoid.Health <= 0
						then
							local enemiesFolder = workspace:FindFirstChild("Enemies")
							if enemiesFolder then
								local minDist = cfg.HitRadius + 40
								for _, enemy in ipairs(enemiesFolder:GetChildren()) do
									local eHrp = enemy:FindFirstChild("HumanoidRootPart")
										or enemy:FindFirstChildWhichIsA("BasePart", true)
									local eHum = enemy:FindFirstChild("Humanoid")
									if eHrp and eHum and eHum.Health > 0 then
										local d = (GetSafePosition(eHrp) - myHrp.Position).Magnitude
										if d < minDist then
											minDist = d
											target = enemy
										end
									end
								end
							end
						end

						if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
							ExecuteAttack(myChar, myHrp, true, target.Name)
							lastAttackAt = now
						end
					end
				end
			end

			if isAutoAttackEnabled and attackSpeedMode == "Super Fast Attack" then
				task.wait()
			else
				task.wait(cfg.ThreadSleep)
			end
		end
	end)
end

StartStandaloneAutoAttackThread()

local autoSeaBeastWorkerGen = 0

local function StartAutoSeaBeast()
	if isAutoSeaBeastActive then
		return
	end
	isAutoSeaBeastActive = true
	autoSeaBeastWorkerGen = autoSeaBeastWorkerGen + 1
	local gen = autoSeaBeastWorkerGen

	task.spawn(function()
		while cfg.autoSeaBeast and ScriptContext.Running and gen == autoSeaBeastWorkerGen do
			local ok, err = pcall(function()
				local myChar = GetCharacter()
				local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				local seaBeasts = workspace:FindFirstChild("SeaBeasts") or workspace:FindFirstChild("Enemies")
				local targetSeaBeast = nil

				local targetNames = { "sea beast", "rumbling", "terrorshark", "shark", "piranha", "fish crew" }

				if seaBeasts then
					for _, obj in ipairs(seaBeasts:GetChildren()) do
						local objName = string.lower(obj.Name)
						for _, tName in ipairs(targetNames) do
							if string.find(objName, tName) then
								if IsEnemyVulnerable(obj, obj.Name) then
									targetSeaBeast = obj
									break
								end
							end
						end
						if targetSeaBeast then
							break
						end
					end
				end

				if targetSeaBeast then
					local sbHrp = targetSeaBeast:FindFirstChild("HumanoidRootPart")
						or targetSeaBeast:FindFirstChildWhichIsA("BasePart", true)
					if sbHrp then
						TweenTo(CFrame.new(sbHrp.Position + Vector3.new(0, 50, 0), sbHrp.Position))
						ExecuteAttack(myChar, myHrp, false, targetSeaBeast.Name)
						ToggleFloat(true)
					end
				else
					ToggleFloat(false)
				end
			end)
			if not ok then
				warn("[Auto Sea Beast Error]", err)
			end
			task.wait(0.1)
		end
		isAutoSeaBeastActive = false
	end)
end

local function StartAutoEliteHunter()
	eliteHunterWorkerGen = eliteHunterWorkerGen + 1
	local gen = eliteHunterWorkerGen

	local currentEliteEnemy = nil
	local currentEliteLocation = nil
	local spawnIndex = 1

	task.spawn(function()
		while isAutoEliteHunter and ScriptContext.Running and gen == eliteHunterWorkerGen do
			if isReadyToAttack then
				local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
					or cfg.AttackIntervalFast
				local myChar = GetCharacter()
				local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
				if myHrp and currentTargetInstance then
					ExecuteAttack(myChar, myHrp, false, currentTargetInstance.Name)
				end
				if interval <= 0 then
					task.wait()
				else
					task.wait(interval)
				end
			else
				task.wait(cfg.ThreadSleep)
			end
		end
	end)

	local eliteBringConn
	eliteBringConn = RunService.Heartbeat:Connect(function()
		if not isAutoEliteHunter or not ScriptContext.Running or gen ~= eliteHunterWorkerGen then
			if eliteBringConn then
				eliteBringConn:Disconnect()
			end
			return
		end
		if isReadyToAttack and currentTargetInstance and currentEliteEnemy then
			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			local tHrp = currentTargetInstance:FindFirstChild("HumanoidRootPart")
			if myHrp and tHrp then
				UniversalMagnet(currentEliteEnemy, tHrp.Position, myHrp.Position)
			end
		end
	end)
	ScriptContext:AddConnection(eliteBringConn)

	task.spawn(function()
		local lastEliteCheck = 0

		while isAutoEliteHunter and ScriptContext.Running and gen == eliteHunterWorkerGen do
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then
					return
				end

				local now = os.clock()
				if now - lastEvasionTime >= cfg.EvasionTick then
					lastEvasionTime = now
					local radius = math.max(0, math.floor(cfg.EvasionRadius))
					currentEvasionOffset =
						Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
					lastEvasionMoveAt = 0
				end

				if not currentTargetInstance and (now - lastEliteCheck > 6) then
					lastEliteCheck = now
					if CommF_ then
						local result = CommF_:InvokeServer("EliteHunter")
						if type(result) == "string" then
							local bossName = string.match(result, "about (%a+) roaming")
							local locationName = string.match(result, "near (.-)%.")
							if bossName and locationName then
								if currentEliteLocation ~= locationName then
									spawnIndex = 1
									currentEliteLocation = locationName
								end
								currentEliteEnemy = bossName
							else
								currentEliteEnemy = nil
								currentEliteLocation = nil
								currentTargetInstance = nil
							end
						else
							currentEliteEnemy = nil
							currentEliteLocation = nil
							currentTargetInstance = nil
						end
					end
				end

				isEliteHunterActive = currentEliteEnemy ~= nil

				if currentEliteEnemy and currentEliteLocation then
					local targetEnemy = currentTargetInstance
					if targetEnemy then
						local h = targetEnemy:FindFirstChildOfClass("Humanoid")
						if h and h.Health <= 0 then
							targetEnemy = nil
							currentTargetInstance = nil
							isReadyToAttack = false
							currentEliteEnemy = nil
							isEliteHunterActive = false
							lastEliteCheck = 0
							ToggleFloat(false)
						elseif h and h.Health ~= lastTargetHealth then
							lastTargetHealth = h.Health
							lastTargetHealthChangeAt = now
						end

						local ePos = GetSafePosition(targetEnemy)
						local distToBoss = (ePos - myHrp.Position).Magnitude
						if distToBoss <= 80 then
							if
								lastTargetHealthChangeAt > 0 and (now - lastTargetHealthChangeAt >= cfg.StuckTimeout)
							then
								enemyBlacklist[targetEnemy] = now + 3
								currentTargetInstance = nil
								isReadyToAttack = false
								targetEnemy = nil
							end
						else
							lastTargetHealthChangeAt = now
						end
					end

					if not targetEnemy or not IsEnemyVulnerable(targetEnemy, currentEliteEnemy) then
						targetEnemy = GetTargetEnemy(currentEliteEnemy)
						currentTargetInstance = targetEnemy
						if targetEnemy then
							local h = targetEnemy:FindFirstChildOfClass("Humanoid")
							lastTargetHealth = h and h.Health or -1
							lastTargetHealthChangeAt = now
						end
					end

					if targetEnemy then
						local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
							or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
						local centerPos = GetSafePosition(tHrp or targetEnemy)
						if centerPos ~= Vector3.zero then
							ToggleFloat(true)
							local targetDistance = (centerPos - myHrp.Position).Magnitude
							if targetDistance > 80 then
								TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
								lastEvasionMoveAt = now
							else
								TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
							end
							isReadyToAttack = targetDistance <= cfg.MaxPullRange
						end
					else
						currentTargetInstance = nil
						isReadyToAttack = false

						local spawns = ELITE_HUNTER_SPAWNS[currentEliteLocation]
						if spawns and #spawns > 0 then
							ToggleFloat(true)
							if spawnIndex > #spawns then
								spawnIndex = 1
							end
							local targetSpawn = spawns[spawnIndex]
							local flatDist = (Vector3.new(myHrp.Position.X, 0, myHrp.Position.Z) - Vector3.new(
								targetSpawn.X,
								0,
								targetSpawn.Z
							)).Magnitude
							if flatDist > 50 then
								TweenTo(CFrame.new(targetSpawn + Vector3.new(0, 100, 0), targetSpawn))
							else
								if not getgenv().EliteWaitStart then
									getgenv().EliteWaitStart = now
								end
								if now - getgenv().EliteWaitStart > 3 then
									spawnIndex = spawnIndex + 1
									getgenv().EliteWaitStart = nil
								else
									TweenTo(CFrame.new(targetSpawn + Vector3.new(0, 20, 0), targetSpawn))
								end
							end
						else
							ToggleFloat(false)
						end
					end
				else
					currentTargetInstance = nil
					isReadyToAttack = false
					if not cfg.isTeleportingToIsland then
						if activeTween then
							activeTween:Cancel()
							activeTween = nil
						end
						ToggleFloat(false)
					end
				end
			end)
			if not ok then
				warn("[Elite Hunter Error]: " .. tostring(err))
				currentTargetInstance = nil
				isReadyToAttack = false
				if not cfg.isTeleportingToIsland then
					ToggleFloat(false)
				end
			end
			task.wait()
		end
	end)
end

local cacheBuster = "?v=" .. tostring(os.time())
local Lonum = loadstring(
	game:HttpGet("https://raw.githubusercontent.com/Difz25x/roblox-project/refs/heads/main/library2.lua" .. cacheBuster)
)()

getgenv().LonumUNCPassed = false
getgenv().UNCSupportReport = {}

Lonum.UNC(function(uncReport)
	getgenv().LonumUNCPassed = true
	getgenv().UNCSupportReport = uncReport or getgenv().LonumUNCSupport or {}

	if uncReport and type(uncReport) == "table" then
		if not uncReport["hookmetamethod"] or not uncReport["getnamecallmethod"] or not uncReport["checkcaller"] then
			print(
				"[UNC Warning]: hookmetamethod/namecall/checkcaller incomplete, client anti-kick protection disabled."
			)
		end
		if not uncReport["hookfunction"] or not uncReport["newcclosure"] then
			print("[UNC Warning]: hookfunction/newcclosure not supported, visual FX bypass skipped.")
		end

		if not uncReport["sethiddenproperty"] then
			print("[UNC Warning]: sethiddenproperty not supported, using normal simulation radius.")
		end
		if not uncReport["gethiddenproperty"] then
			print("[UNC Warning]: gethiddenproperty not supported, hidden properties inspection disabled.")
		end
		if not uncReport["setscriptable"] then
			print("[UNC Warning]: setscriptable not supported, non-scriptable properties skipped.")
		end
		if not uncReport["setreadonly"] then
			print("[UNC Warning]: setreadonly not supported, read-only metatable modification restricted.")
		end

		if not uncReport["getnilinstances"] then
			print("[UNC Warning]: getnilinstances not supported, nil instance search disabled.")
		end
		if not uncReport["getinstances"] then
			print(
				"[UNC Warning]: getinstances not supported, material optimization fallback to workspace:GetDescendants()."
			)
		end
		if not uncReport["gethui"] then
			print("[UNC Warning]: gethui not supported, GUI parented to PlayerGui/CoreGui.")
		end

		if not uncReport["getgenv"] then
			print("[UNC Warning]: getgenv not supported, global variables fallback to _G and shared.")
		end
		if not uncReport["getrenv"] or not uncReport["getfenv"] then
			print("[UNC Warning]: getrenv/getfenv not supported, environment isolation disabled.")
		end
		if not uncReport["getsenv"] then
			print("[UNC Warning]: getsenv not supported, local script variable extraction skipped.")
		end
		if not uncReport["getgc"] then
			print("[UNC Warning]: getgc not supported, garbage collector memory scan disabled.")
		end
		if not uncReport["debug.getupvalues"] or not uncReport["debug.setupvalue"] then
			print(
				"[UNC Warning]: debug upvalues not supported, LocalScript internal cooldown bypass switching to remote interval."
			)
		end
		if not uncReport["debug.getinfo"] then
			print("[UNC Warning]: debug.getinfo not supported, traceback debugger skipped.")
		end

		if not uncReport["fireproximityprompt"] then
			print("[UNC Warning]: fireproximityprompt not supported, secret quests switching purely to remote invoke.")
		end
		if not uncReport["firetouchinterest"] then
			print("[UNC Warning]: firetouchinterest not supported, item collection switching to CFrame touch.")
		end
		if not uncReport["getconnections"] then
			print("[UNC Warning]: getconnections not supported, anti-AFK fallback to VirtualUser simulation.")
		end

		if not uncReport["readfile"] or not uncReport["writefile"] or not uncReport["isfile"] then
			print("[UNC Warning]: Filesystem (readfile/writefile) not supported, automatic config saving disabled.")
		end
		if not uncReport["makefolder"] or not uncReport["isfolder"] then
			print("[UNC Warning]: Folder creation not supported, data saved without subfolder.")
		end

		if not uncReport["Drawing"] then
			print("[UNC Warning]: Drawing API not supported, ESP switching to BillboardGui.")
		end
		if not uncReport["queue_on_teleport"] then
			print("[UNC Warning]: queue_on_teleport not supported, auto-reexecute on server hop disabled.")
		end
		if not uncReport["require"] then
			print("[UNC Warning]: custom require not supported, game modules accessed via Roblox native require.")
		end
	end
end)

while not getgenv().LonumUNCPassed do
	task.wait(0.1)
end

Window = Lonum:CreateWindow({
	Name = "Blox Fruits | Lonum",
	Subtitle = "Made by Difzz",
	ConfigurationSaving = { FolderName = "Lonum_Data", FileName = "Cfg_BloxFruits" },
})

MoonPhases = {
	[1] = "1/8 (Waxing Crescent)",
	[2] = "2/8 (First Quarter)",
	[3] = "3/8 (Waxing Gibbous)",
	[4] = "4/8 (Full Moon)",
	[5] = "5/8 (Waning Gibbous)",
	[6] = "6/8 (Last Quarter)",
	[7] = "7/8 (Waning Crescent)",
	[8] = "8/8 (New Moon)",
}

Tabs = {
	Main = Window:CreateTab("Farming"),
	Raid = Window:CreateTab("Raid"),
	Dungeon = Window:CreateTab("Dungeon"),
	PVP = Window:CreateTab("PVP"),
	Travel = Window:CreateTab("Travel & Sea"),
	Stats = Window:CreateTab("Stats & Abilities"),
	Sea1 = Window:CreateTab("Sea 1"),
	Sea2 = Window:CreateTab("Sea 2"),
	Sea3 = Window:CreateTab("Sea 3"),
	Quests = Window:CreateTab("Quests & Items"),
	Shop = Window:CreateTab("Shop & Craft"),
	Misc = Window:CreateTab("Misc"),
	Status = Window:CreateTab("Status"),
	Settings = Window:CreateTab("Settings"),
}

do
	Tabs.Quests:CreateSection("Auto Get Swords (Auto Kill Boss)")

	local swordBosses = {
		{ "Saber", "Saber Expert" },
		{ "Pole", "Thunder God" },
		{ "Saw", "The Saw" },
		{ "Wardens", "Chief Warden" },
		{ "Trident", "Fishman Lord" },
		{ "Longsword", "Diamond" },
		{ "Gravity Blade", "Fajita" },
		{ "Flail", "Jeremy" },
		{ "Rengoku", "Awakened Ice Admiral" },
		{ "Dragon Trident", "Tide Keeper" },
		{ "Twin Hooks", "Captain Elephant" },
		{ "Canvander", "Beautiful Pirate" },
		{ "Buddy Sword", "Cake Queen" },
	}

	for _, data in ipairs(swordBosses) do
		local swordName = data[1]
		local bossName = data[2]
		Tabs.Quests:CreateToggle({
			Name = "Auto Get " .. swordName .. " (" .. bossName .. ")",
			CurrentValue = false,
			Flag = "AutoSword_" .. string.gsub(swordName, " ", ""),
			Callback = function(Value)
				getgenv()["AutoSword_" .. swordName] = Value
				task.spawn(function()
					while getgenv()["AutoSword_" .. swordName] do
						task.wait(0.5)
						pcall(function()
							local db = workspace:FindFirstChild("Enemies")
								and workspace.Enemies:FindFirstChild(bossName)
							local char = GetCharacter()
							local hrp = char and char:FindFirstChild("HumanoidRootPart")
							if db and db:FindFirstChild("Humanoid") and db.Humanoid.Health > 0 and hrp then
								TweenTo(db.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0))
								ExecuteAttack(char, hrp, false, bossName)
								ToggleFloat(true)
							else
								local profile = GetBossProfileByName(bossName)
								if profile then
									TweenTo(CFrame.new(profile.NPC) * CFrame.new(0, 50, 0))
								end
								ToggleFloat(false)
							end
						end)
					end
				end)
			end,
		})
	end

	Tabs.Quests:CreateSection("Special Quests")
	local specialQuests = {
		{ "Auto Quest Sea Bartilo", "BartiloQuestProgress" },
		{ "Auto Quest Sea 3", "ZQuestProgress" },
		{ "Auto Buy Haki Colors", "activateColor" },
		{ "Auto Skull Guitar", "Ectoplasm" },
		{ "Auto Holy Torch Tushita", "ProQuestProgress" },
		{ "Auto CDK [Beta]", "CDKQuest" },
	}

	for _, data in ipairs(specialQuests) do
		local qName = data[1]
		local qRemote = data[2]
		Tabs.Quests:CreateToggle({
			Name = qName,
			CurrentValue = false,
			Flag = "AutoQuest_" .. string.gsub(qName, " ", ""),
			Callback = function(Value)
				getgenv()["AutoQuest_" .. qName] = Value
				task.spawn(function()
					while getgenv()["AutoQuest_" .. qName] do
						task.wait(2)
						pcall(function()
							game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(qRemote, "Progress")
						end)
						pcall(function()
							game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(qRemote, "Buy")
						end)
					end
				end)
			end,
		})
	end

	Tabs.Quests:CreateSection("Auto Trial V4 & Misc")
	Tabs.Quests:CreateButton({
		Name = "Buy Ancient One Quest",
		Callback = function()
			pcall(function()
				game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyAncientOne")
			end)
		end,
	})
	Tabs.Quests:CreateButton({
		Name = "Auto Race Door",
		Callback = function()
			pcall(function()
				game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("RaceV4Door")
			end)
		end,
	})
	Tabs.Quests:CreateToggle({
		Name = "Auto Fishing",
		CurrentValue = false,
		Flag = "AutoFishingOpt",
		Callback = function(Value)
			getgenv().AutoFishing = Value
			task.spawn(function()
				while getgenv().AutoFishing do
					task.wait(1)
					pcall(function()
						game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Fishing", "Cast")
					end)
				end
			end)
		end,
	})
end

Tabs.Shop:CreateSection("Buy Melee V1")
melees1 = { "Black Leg", "Electro", "Water Kung Fu", "Dragon Claw" }
for _, name in ipairs(melees1) do
	Tabs.Shop:CreateButton({
		Name = "Buy " .. name,
		Callback = function()
			pcall(function()
				game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buy" .. string.gsub(name, " ", ""))
			end)
		end,
	})
end

Tabs.Shop:CreateSection("Buy Melee V2 & V3")
melees2 =
	{ "Superhuman", "Death Step", "Sharkman Karate", "Electric Claw", "Dragon Talon", "God Human", "Sanguine Art" }
for _, name in ipairs(melees2) do
	Tabs.Shop:CreateButton({
		Name = "Buy " .. name,
		Callback = function()
			pcall(function()
				game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buy" .. string.gsub(name, " ", ""))
			end)
		end,
	})
end

Tabs.Shop:CreateSection("Skills & Haki")
hakis = { "Geppo", "Buso", "Soru", "Observation" }
for _, name in ipairs(hakis) do
	Tabs.Shop:CreateButton({
		Name = "Buy " .. name,
		Callback = function()
			pcall(function()
				game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyHaki", name)
			end)
		end,
	})
end

Tabs.Shop:CreateSection("Swords & Guns")
weapons = {
	"Cutlass",
	"Katana",
	"Iron Mace",
	"Dual Katana",
	"Triple Katana",
	"Pipe",
	"Dual-Headed Blade",
	"Bisento",
	"Soul Cane",
	"Slingshot",
	"Musket",
	"Flintlock",
	"Refined Slingshot",
	"Refined Flintlock",
	"Cannon",
}
for _, name in ipairs(weapons) do
	Tabs.Shop:CreateButton({
		Name = "Buy " .. name,
		Callback = function()
			pcall(function()
				game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyItem", name)
			end)
		end,
	})
end

Tabs.Shop:CreateSection("Crafting (Sea Events)")
crafts = {
	"Dragonheart",
	"Dragonstorm",
	"DinoHood",
	"SharkTooth",
	"TerrorJaw",
	"SharkAnchor",
	"LeviathanCrown",
	"LeviathanShield",
	"LeviathanBoat",
	"LegendaryScroll",
	"MythicalScroll",
}
for _, name in ipairs(crafts) do
	Tabs.Shop:CreateButton({
		Name = "Craft " .. name,
		Callback = function()
			pcall(function()
				game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("CraftItem", "Craft", name)
			end)
		end,
	})
end

Tabs.Sea3:CreateSection("Sea 3 Puzzles")
Tabs.Sea3:CreateToggle({
	Name = "Auto Light Torches",
	CurrentValue = false,
	Flag = "ToggleAutoTorch",
	Callback = function(Value)
		if Value then
			enabled = false
			isAutoRaidKill = false
			isAutoBone = false
			if FarmToggle then
				FarmToggle:Set(false)
			end

			StartAutoTorch()
		else
			isAutoTorch = false
			autoTorchWorker = autoTorchWorker + 1
			StopAllActivities()
		end
	end,
})

Tabs.Sea1:CreateSection("Jungle")
Tabs.Sea1:CreateToggle({
	Name = "Auto Collect Banana",
	CurrentValue = false,
	Flag = "ToggleAutoBanana",
	Callback = function(Value)
		cfg.isAutoBanana = Value
		if Value then
			task.spawn(function()
				while cfg.isAutoBanana do
					task.wait(0.5)
					pcall(function()
						local bananaFolder = workspace:FindFirstChild("BananaSpawner")
						if bananaFolder then
							local bananas = bananaFolder:GetChildren()
							for _, banana in ipairs(bananas) do
								if not cfg.isAutoBanana then
									break
								end
								if banana:IsA("Tool") or banana:IsA("Model") or banana:IsA("BasePart") then
									local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
									if hrp then
										local targetPos
										if banana:IsA("Model") and banana.PrimaryPart then
											targetPos = banana.PrimaryPart.CFrame
										elseif banana:IsA("Tool") and banana:FindFirstChild("Handle") then
											targetPos = banana.Handle.CFrame
										elseif banana:IsA("BasePart") then
											targetPos = banana.CFrame
										else
											targetPos = banana:GetPivot()
										end

										if targetPos then
											TweenTo(targetPos)
											task.wait(0.2)
										end
									end
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Underwater Village")
Tabs.Sea1:CreateToggle({
	Name = "Auto Black Pearl (Summon Fishman Lord)",
	CurrentValue = false,
	Flag = "ToggleAutoPearl",
	Callback = function(Value)
		cfg.isAutoPearl = Value
		if Value then
			task.spawn(function()
				local CollectionService = game:GetService("CollectionService")
				local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
				local bmRemote = Remotes:WaitForChild("BonusMomentsRemoteFunction")

				while cfg.isAutoPearl do
					task.wait(1)
					pcall(function()
						local clams = CollectionService:GetTagged("PearlClam")
						for _, clam in ipairs(clams) do
							if not cfg.isAutoPearl then
								break
							end

							local cframePos
							if clam:IsA("Model") and clam.PrimaryPart then
								cframePos = clam.PrimaryPart.CFrame
							elseif clam:IsA("BasePart") then
								cframePos = clam.CFrame
							else
								cframePos = clam:GetBoundingBox()
							end

							if cframePos then
								TweenTo(cframePos * CFrame.new(0, 5, 0))
								task.wait(0.5)

								local prompt = clam:FindFirstChildWhichIsA("ProximityPrompt", true)
								if prompt and prompt.Enabled then
									fireproximityprompt(prompt)
									task.wait(1.5)

									local pearlPrompt = nil
									for _, p in ipairs(workspace:GetDescendants()) do
										if
											p:IsA("ProximityPrompt")
											and p.ObjectText == "Pearl of the Deep"
											and p.ActionText == "Claim"
										then
											pearlPrompt = p
											break
										end
									end

									if pearlPrompt and pearlPrompt.Enabled then
										fireproximityprompt(pearlPrompt)
										cfg.isAutoPearl = false
										local pearlToggle = Window.Flags["ToggleAutoPearl"]
										if pearlToggle then
											pearlToggle:Set(false)
										end
										break
									end
								else
									local res = bmRemote:InvokeServer("Pearl of the Deep", "OpenClam", clam)
									if res == "Black" then
										task.wait(1)
										bmRemote:InvokeServer("Pearl of the Deep", "ClaimPearl")
										cfg.isAutoPearl = false
										local pearlToggle = Window.Flags["ToggleAutoPearl"]
										if pearlToggle then
											pearlToggle:Set(false)
										end
										break
									end
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Colosseum")
Tabs.Sea1:CreateToggle({
	Name = "Auto Crowd Favorite (Destroy Targets)",
	CurrentValue = false,
	Flag = "ToggleAutoCrowd",
	Callback = function(Value)
		cfg.isAutoCrowd = Value
		if Value then
			task.spawn(function()
				while cfg.isAutoCrowd do
					task.wait(0.1)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						local foundTarget = false
						for _, obj in ipairs(workspace:GetDescendants()) do
							if not cfg.isAutoCrowd then
								break
							end

							if obj.Name == "Target" and (obj:IsA("Model") or obj:IsA("BasePart")) then
								local targetPos
								if obj:IsA("Model") and obj.PrimaryPart then
									targetPos = obj.PrimaryPart.CFrame
								elseif obj:IsA("BasePart") then
									targetPos = obj.CFrame
								end

								if targetPos then
									foundTarget = true

									TweenTo(targetPos * CFrame.new(0, 5, 0))

									ExecuteAttack(myChar, myHrp, false, obj.Name)
									task.wait(0.2)
								end
							end
						end

						if not foundTarget then
							task.wait(1)
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Magma Village")
Tabs.Sea1:CreateToggle({
	Name = "Auto Magma Event (Evil Slimes & Fissures)",
	CurrentValue = false,
	Flag = "ToggleAutoMagmaEvent",
	Callback = function(Value)
		cfg.isAutoMagmaEvent = Value
		if Value then
			task.spawn(function()
				while cfg.isAutoMagmaEvent do
					task.wait(0.1)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						local foundTarget = false
						local enemiesFolder = workspace:FindFirstChild("Enemies")

						if enemiesFolder then
							for _, slime in ipairs(enemiesFolder:GetChildren()) do
								if not cfg.isAutoMagmaEvent then
									break
								end

								if
									slime.Name == "Evil Slime"
									and slime:FindFirstChild("Humanoid")
									and slime.Humanoid.Health > 0
								then
									local targetHrp = slime:FindFirstChild("HumanoidRootPart")
									if targetHrp then
										foundTarget = true
										TweenTo(targetHrp.CFrame * CFrame.new(0, 15, 0))
										ExecuteAttack(myChar, myHrp, false, "Evil Slime")
										task.wait(0.2)
									end
								end
							end
						end

						if not foundTarget then
							for _, obj in ipairs(workspace:GetDescendants()) do
								if not cfg.isAutoMagmaEvent then
									break
								end

								if obj.Name == "MagmaFissure" and obj:IsA("Model") then
									local targetPos
									if obj.PrimaryPart then
										targetPos = obj.PrimaryPart.CFrame
									else
										targetPos = obj:GetBoundingBox()
									end

									if targetPos then
										foundTarget = true
										TweenTo(targetPos * CFrame.new(0, 5, 0))
										ExecuteAttack(myChar, myHrp, false, obj.Name)
										task.wait(0.2)
									end
								end
							end
						end

						if not foundTarget then
							task.wait(1)
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Fountain City")
Tabs.Sea1:CreateToggle({
	Name = "Auto Pipe Repair (Fountain)",
	CurrentValue = false,
	Flag = "ToggleAutoFountainPipe",
	Callback = function(Value)
		cfg.isAutoFountainPipe = Value
		if Value then
			task.spawn(function()
				while cfg.isAutoFountainPipe do
					task.wait(0.1)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						local foundPipe = false
						for _, obj in ipairs(workspace:GetDescendants()) do
							if not cfg.isAutoFountainPipe then
								break
							end

							if
								(obj.Name == "FountainPipeNodes" or obj.Name == "PipeNode" or obj.Name == "Leak")
								and (obj:IsA("Model") or obj:IsA("BasePart"))
							then
								local targetPos
								if obj:IsA("Model") and obj.PrimaryPart then
									targetPos = obj.PrimaryPart.CFrame
								elseif obj:IsA("BasePart") then
									targetPos = obj.CFrame
								end

								if targetPos then
									foundPipe = true
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									ExecuteAttack(myChar, myHrp, false, obj.Name)
									task.wait(0.2)
								end
							end
						end

						if not foundPipe then
							task.wait(1)
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateToggle({
	Name = "Auto Wire Repair (Fountain)",
	CurrentValue = false,
	Flag = "ToggleAutoFountainWire",
	Callback = function(Value)
		cfg.isAutoFountainWire = Value
		if Value then
			task.spawn(function()
				local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
				local bmRemote = Remotes:WaitForChild("BonusMomentsRemoteFunction")

				while cfg.isAutoFountainWire do
					task.wait(0.1)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						local foundWire = false
						for _, obj in ipairs(workspace:GetDescendants()) do
							if not cfg.isAutoFountainWire then
								break
							end

							if
								(obj.Name == "LiveWire" or obj.Name == "FountainWire")
								and (obj:IsA("Model") or obj:IsA("BasePart"))
							then
								local targetPos
								if obj:IsA("Model") and obj.PrimaryPart then
									targetPos = obj.PrimaryPart.CFrame
								elseif obj:IsA("BasePart") then
									targetPos = obj.CFrame
								end

								if targetPos then
									foundWire = true
									TweenTo(targetPos * CFrame.new(0, 5, 0))

									ExecuteAttack(myChar, myHrp, false, obj.Name)
									bmRemote:InvokeServer("Fountain Wire Repair", "WireHit", obj)
									task.wait(0.2)
								end
							end
						end

						if not foundWire then
							task.wait(1)
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Pirate Village & Starter")
Tabs.Sea1:CreateToggle({
	Name = "Auto Windmill Maintenance",
	CurrentValue = false,
	Flag = "ToggleAutoWindmill",
	Callback = function(Value)
		getgenv().AutoWindmill = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoWindmill do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoWindmill then
								break
							end
							if
								obj.Name == "WindmillBlade"
								or obj.Name == "WindmillGear"
								or obj.Name == "WindmillPart"
							then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									else
										bmRemote:InvokeServer("Windmill Maintenance", "Repair", obj)
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateToggle({
	Name = "Auto Tavern Brawl",
	CurrentValue = false,
	Flag = "ToggleAutoTavernBrawl",
	Callback = function(Value)
		getgenv().AutoTavernBrawl = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoTavernBrawl do
					task.wait(0.2)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						local enemies = workspace:FindFirstChild("Enemies")
						if enemies then
							for _, enemy in ipairs(enemies:GetChildren()) do
								if not getgenv().AutoTavernBrawl then
									break
								end
								if string.find(enemy.Name, "Tavern") or string.find(enemy.Name, "Brawler") then
									local eHrp = enemy:FindFirstChild("HumanoidRootPart")
									local eHum = enemy:FindFirstChild("Humanoid")
									if eHrp and eHum and eHum.Health > 0 then
										TweenTo(eHrp.CFrame * CFrame.new(0, 5, 0))
										ExecuteAttack(myChar, myHrp, false, enemy.Name)
										task.wait(0.2)
									end
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateToggle({
	Name = "Auto The Thieving Monkey (Return Hat)",
	CurrentValue = false,
	Flag = "ToggleAutoThievingMonkey",
	Callback = function(Value)
		getgenv().AutoThievingMonkey = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoThievingMonkey do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoThievingMonkey then
								break
							end
							if obj.Name == "MonkeyHat" or obj.Name == "ThievingMonkey" then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									else
										bmRemote:InvokeServer("The Thieving Monkey", "ClaimHat", obj)
										task.wait(0.5)
										bmRemote:InvokeServer("The Thieving Monkey", "ReturnHat")
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Desert")
Tabs.Sea1:CreateToggle({
	Name = "Auto Rescue Hasan",
	CurrentValue = false,
	Flag = "ToggleAutoRescueHasan",
	Callback = function(Value)
		getgenv().AutoRescueHasan = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoRescueHasan do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						pcall(function()
							bmRemote:InvokeServer("Rescue Hasan", "StartWaves")
						end)

						local enemies = workspace:FindFirstChild("Enemies")
						if enemies then
							for _, enemy in ipairs(enemies:GetChildren()) do
								if not getgenv().AutoRescueHasan then
									break
								end
								if string.find(enemy.Name, "Skeleton") or string.find(enemy.Name, "Desert") then
									local eHrp = enemy:FindFirstChild("HumanoidRootPart")
									local eHum = enemy:FindFirstChild("Humanoid")
									if eHrp and eHum and eHum.Health > 0 then
										TweenTo(eHrp.CFrame * CFrame.new(0, 5, 0))
										ExecuteAttack(myChar, myHrp, false, enemy.Name)
										task.wait(0.2)
									end
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateToggle({
	Name = "Auto Prickly Harvest (Cactus Fruit)",
	CurrentValue = false,
	Flag = "ToggleAutoPricklyHarvest",
	Callback = function(Value)
		getgenv().AutoPricklyHarvest = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoPricklyHarvest do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoPricklyHarvest then
								break
							end
							if string.find(obj.Name, "Cactus") or string.find(obj.Name, "Prickly") then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Snow Island")
Tabs.Sea1:CreateToggle({
	Name = "Auto Build Snowman",
	CurrentValue = false,
	Flag = "ToggleAutoSnowman",
	Callback = function(Value)
		getgenv().AutoSnowman = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoSnowman do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoSnowman then
								break
							end
							if string.find(obj.Name, "Snowball") or string.find(obj.Name, "Snowman") then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									else
										bmRemote:InvokeServer("Snowman", "GrabSnowball", obj)
										task.wait(0.5)
										bmRemote:InvokeServer("Snowman", "Finished")
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Marineford & Fortress")
Tabs.Sea1:CreateToggle({
	Name = "Auto Fortress Flagpole (Hoist Flag)",
	CurrentValue = false,
	Flag = "ToggleAutoFlagpole",
	Callback = function(Value)
		getgenv().AutoFlagpole = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoFlagpole do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoFlagpole then
								break
							end
							if string.find(obj.Name, "Flagpole") or string.find(obj.Name, "FortressFlag") then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									else
										bmRemote:InvokeServer("Fortress Flagpole", "Hoist", obj)
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Sky Island")
Tabs.Sea1:CreateToggle({
	Name = "Auto Echoes Through Clouds (Wake God)",
	CurrentValue = false,
	Flag = "ToggleAutoEchoesClouds",
	Callback = function(Value)
		getgenv().AutoEchoesClouds = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoEchoesClouds do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoEchoesClouds then
								break
							end
							if
								string.find(obj.Name, "Bell")
								or string.find(obj.Name, "GoldenBell")
								or string.find(obj.Name, "SkyCloud")
							then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									else
										bmRemote:InvokeServer("Echoes Through the Clouds", "WakeGod", obj)
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Impel Down / Prison")
Tabs.Sea1:CreateToggle({
	Name = "Auto Lever Jailbreak",
	CurrentValue = false,
	Flag = "ToggleAutoLeverJailbreak",
	Callback = function(Value)
		getgenv().AutoLeverJailbreak = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoLeverJailbreak do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoLeverJailbreak then
								break
							end
							if
								string.find(obj.Name, "Lever")
								or string.find(obj.Name, "Jailbreak")
								or string.find(obj.Name, "CellDoor")
							then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									else
										bmRemote:InvokeServer("Lever Jailbreak", "Pull", obj)
										bmRemote:InvokeServer("Lever Jailbreak", "Release", obj)
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateToggle({
	Name = "Auto Escape from Alcatraz",
	CurrentValue = false,
	Flag = "ToggleAutoEscapeAlcatraz",
	Callback = function(Value)
		getgenv().AutoEscapeAlcatraz = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoEscapeAlcatraz do
					task.wait(0.3)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						pcall(function()
							bmRemote:InvokeServer("Escape from Alcatraz", "Provoke")
						end)
						local enemies = workspace:FindFirstChild("Enemies")
						if enemies then
							for _, enemy in ipairs(enemies:GetChildren()) do
								if not getgenv().AutoEscapeAlcatraz then
									break
								end
								if
									string.find(enemy.Name, "Guard")
									or string.find(enemy.Name, "Prisoner")
									or string.find(enemy.Name, "Warden")
								then
									local eHrp = enemy:FindFirstChild("HumanoidRootPart")
									local eHum = enemy:FindFirstChild("Humanoid")
									if eHrp and eHum and eHum.Health > 0 then
										TweenTo(eHrp.CFrame * CFrame.new(0, 5, 0))
										ExecuteAttack(myChar, myHrp, false, enemy.Name)
										task.wait(0.2)
									end
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Fishman Island & Underwater")
Tabs.Sea1:CreateToggle({
	Name = "Auto Beyond the Bubble (Secret Chests)",
	CurrentValue = false,
	Flag = "ToggleAutoBeyondBubble",
	Callback = function(Value)
		getgenv().AutoBeyondBubble = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoBeyondBubble do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoBeyondBubble then
								break
							end
							if string.find(obj.Name, "BubbleChest") or string.find(obj.Name, "UnderwaterChest") then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									else
										bmRemote:InvokeServer("Beyond the Bubble", "OpenChest", obj)
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Buggy Island / Clown Village")
Tabs.Sea1:CreateToggle({
	Name = "Auto The Clown's Jewels",
	CurrentValue = false,
	Flag = "ToggleAutoClownJewels",
	Callback = function(Value)
		getgenv().AutoClownJewels = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoClownJewels do
					task.wait(0.3)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						pcall(function()
							bmRemote:InvokeServer("The Clown's Jewels", "Provoke")
						end)
						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoClownJewels then
								break
							end
							if
								string.find(obj.Name, "Jewel")
								or string.find(obj.Name, "ClownChest")
								or string.find(obj.Name, "BagOfJewels")
							then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									else
										bmRemote:InvokeServer("The Clown's Jewels", "Collect", obj)
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Marineford Fortress & Secret Vault")
Tabs.Sea1:CreateToggle({
	Name = "Auto Unexpected Guest (Break Vault)",
	CurrentValue = false,
	Flag = "ToggleAutoUnexpectedGuest",
	Callback = function(Value)
		getgenv().AutoUnexpectedGuest = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoUnexpectedGuest do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoUnexpectedGuest then
								break
							end
							if
								string.find(obj.Name, "VaultDoor")
								or string.find(obj.Name, "VaultChest")
								or string.find(obj.Name, "SecretVault")
							then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									else
										bmRemote:InvokeServer("Unexpected Guest", "BreakDoor", obj)
										task.wait(0.5)
										bmRemote:InvokeServer("Unexpected Guest", "TakeChest", obj)
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateSection("Secret Exploration & Treasure")
Tabs.Sea1:CreateToggle({
	Name = "Auto Sewer Gangs (Claim Treasure)",
	CurrentValue = false,
	Flag = "ToggleAutoSewerGangs",
	Callback = function(Value)
		getgenv().AutoSewerGangs = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoSewerGangs do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoSewerGangs then
								break
							end
							if string.find(obj.Name, "SewerChest") or string.find(obj.Name, "SewerTreasure") then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									else
										bmRemote:InvokeServer("Sewer Gangs", "ClaimTreasure", obj)
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea1:CreateToggle({
	Name = "Auto X Marks The Spot (Treasure Map)",
	CurrentValue = false,
	Flag = "ToggleAutoXMarksSpot",
	Callback = function(Value)
		getgenv().AutoXMarksSpot = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				while getgenv().AutoXMarksSpot do
					task.wait(0.5)
					pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							return
						end

						for _, obj in ipairs(workspace:GetDescendants()) do
							if not getgenv().AutoXMarksSpot then
								break
							end
							if
								string.find(obj.Name, "TreasureMap")
								or string.find(obj.Name, "BuriedTreasure")
								or string.find(obj.Name, "XSpot")
							then
								local targetPos = obj:IsA("BasePart") and obj.CFrame
									or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
								if targetPos then
									TweenTo(targetPos * CFrame.new(0, 5, 0))
									local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
									if prompt and prompt.Enabled then
										fireproximityprompt(prompt)
									else
										bmRemote:InvokeServer("X Marks The Spot", "PickupMap", obj)
										task.wait(0.5)
										bmRemote:InvokeServer("X Marks The Spot", "CollectCheckpoint", obj)
									end
									task.wait(0.3)
								end
							end
						end
					end)
				end
			end)
		end
	end,
})

Tabs.Sea2:CreateSection("World Events")
Tabs.Sea2:CreateToggle({
	Name = "Auto Factory (Core)",
	CurrentValue = false,
	Flag = "ToggleAutoFactory",
	Callback = function(Value)
		if Value then
			enabled = false
			isAutoRaidKill = false
			isAutoBone = false
			isAutoTorch = false
			if FarmToggle then
				FarmToggle:Set(false)
			end

			StartAutoFactory()
		else
			isAutoFactory = false
			autoFactoryWorker = autoFactoryWorker + 1
			StopAllActivities()
		end
	end,
})

Tabs.Sea2:CreateToggle({
	Name = "Auto Kill Darkbeard",
	CurrentValue = false,
	Flag = "AutoDarkbeard",
	Callback = function(Value)
		getgenv().AutoDarkbeard = Value
		task.spawn(function()
			while getgenv().AutoDarkbeard do
				task.wait(0.5)
				pcall(function()
					local db = workspace:FindFirstChild("Enemies") and workspace.Enemies:FindFirstChild("Darkbeard")
					local char = GetCharacter()
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if db and db:FindFirstChild("Humanoid") and db.Humanoid.Health > 0 and hrp then
						TweenTo(db.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0))
						ExecuteAttack(char, hrp, false, "Darkbeard")
						ToggleFloat(true)
					else
						local dbSpawns = game:GetService("ReplicatedStorage"):FindFirstChild("Darkbeard")
						if dbSpawns then
							TweenTo(dbSpawns.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0))
						end
						ToggleFloat(false)
					end
				end)
			end
		end)
	end,
})

Tabs.Sea2:CreateToggle({
	Name = "Auto Kill Cursed Captain",
	CurrentValue = false,
	Flag = "AutoCursedCaptain",
	Callback = function(Value)
		getgenv().AutoCursedCaptain = Value
		task.spawn(function()
			while getgenv().AutoCursedCaptain do
				task.wait(0.5)
				pcall(function()
					local cap = workspace:FindFirstChild("Enemies")
						and workspace.Enemies:FindFirstChild("Cursed Captain")
					local char = GetCharacter()
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if cap and cap:FindFirstChild("Humanoid") and cap.Humanoid.Health > 0 and hrp then
						TweenTo(cap.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0))
						ExecuteAttack(char, hrp, false, "Cursed Captain")
						ToggleFloat(true)
					else
						TweenTo(CFrame.new(912, 126, 32852))
						ToggleFloat(false)
					end
				end)
			end
		end)
	end,
})

Tabs.Sea3:CreateSection("World Bosses (Sea 3)")
Tabs.Sea3:CreateToggle({
	Name = "Auto Kill Rip Indra",
	CurrentValue = false,
	Flag = "AutoRipIndra",
	Callback = function(Value)
		getgenv().AutoRipIndra = Value
		task.spawn(function()
			while getgenv().AutoRipIndra do
				task.wait(0.5)
				pcall(function()
					local indra = workspace:FindFirstChild("Enemies")
						and (
							workspace.Enemies:FindFirstChild("rip_indra True Form")
							or workspace.Enemies:FindFirstChild("rip_indra")
						)
					local char = GetCharacter()
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if indra and indra:FindFirstChild("Humanoid") and indra.Humanoid.Health > 0 and hrp then
						TweenTo(indra.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0))
						ExecuteAttack(char, hrp, false, indra.Name)
						ToggleFloat(true)
					else
						local indraArena = CFrame.new(-5333, 424, -2630)
						if (hrp.Position - indraArena.Position).Magnitude > 500 then
							TweenTo(indraArena)
						end
						ToggleFloat(false)
					end
				end)
			end
		end)
	end,
})

Tabs.Settings:CreateSection("UI Configuration")
Tabs.Settings:CreateToggle({
	Name = "Enable Auto Execute",
	CurrentValue = cfg.AutoExecute,
	Flag = "ToggleAutoExecute",
	Callback = function(Value)
		cfg.AutoExecute = Value
	end,
})
Tabs.Settings:CreateKeybind({
	Name = "Toggle Menu Key",
	CurrentValue = Enum.KeyCode.K,
	Flag = "ToggleUIKeybind",
	Callback = function(Key)
		if getgenv().LonumObject then
			getgenv().LonumObject:Notify({
				Title = "Keybind Saved",
				Content = "UI Toggle set to " .. Key.Name,
				Duration = 2,
			})
		end
	end,
})

Tabs.Settings:CreateSection("UNC Engine Optimizations")
Tabs.Settings:CreateToggle({
	Name = "FPS Boost)",
	CurrentValue = false,
	Flag = "UNC_FPSBoost",
	Callback = function(Value)
		task.spawn(function()
			if Value then
				SmartSetProperty(game.Lighting, "Technology", 2)
				pcall(function()
					game.Lighting.GlobalShadows = false
				end)
				pcall(function()
					game.Lighting.FogEnd = 9e9
				end)
				if getinstances then
					for _, v in ipairs(getinstances()) do
						if v:IsA("BasePart") then
							pcall(function()
								v.Material = Enum.Material.SmoothPlastic
							end)
						elseif v:IsA("Texture") or v:IsA("Decal") then
							pcall(function()
								v.Transparency = 1
							end)
						end
					end
				end
			else
				SmartSetProperty(game.Lighting, "Technology", 3)
				pcall(function()
					game.Lighting.GlobalShadows = true
				end)
				pcall(function()
					game.Lighting.FogEnd = 10000
				end)
			end
		end)
	end,
})

Tabs.Settings:CreateToggle({
	Name = "Walk on Water (Devil Fruit)",
	CurrentValue = false,
	Flag = "UNC_WalkWater",
	Callback = function(Value)
		task.spawn(function()
			pcall(function()
				local waterBase = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WaterBase-Plane")
				if waterBase then
					waterBase.Size = Value and Vector3.new(1000, 112, 1000) or Vector3.new(1000, 80, 1000)
				end
			end)
		end)
	end,
})

Tabs.Misc:CreateSection("Auto Redeem Codes")
Tabs.Misc:CreateButton({
	Name = "Redeem All Codes",
	Callback = function()
		local codes = {
			"EASTEREXP",
			"fudd10",
			"fudd10_V2",
			"Chandler",
			"BIGNEWS",
			"KITT_RESET",
			"Sub2UncleKizaru",
			"SUB2GAMERROBOT_RESET1",
			"Sub2Fer999",
			"Enyu_is_Pro",
			"JCWK",
			"StarcodeHEO",
			"MagicBUS",
			"KittGaming",
			"Sub2CaptainMaui",
			"Sub2OfficialNoobie",
			"TheGreatAce",
			"Sub2NoobMaster123",
			"Sub2Daigrock",
			"Axiore",
			"StrawHatMaine",
			"TantaiGaming",
			"Bluxxy",
			"SUB2GAMERROBOT_EXP1",
		}
		task.spawn(function()
			local redeemEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
				and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Redeem")
			if redeemEvent then
				getgenv().LonumObject:Notify({
					Title = "Redeem Codes",
					Content = "Starting to redeem " .. tostring(#codes) .. " codes...",
					Duration = 3,
				})
				for _, code in ipairs(codes) do
					pcall(function()
						redeemEvent:InvokeServer(code)
					end)
					task.wait(1)
				end
				getgenv().LonumObject:Notify({
					Title = "Redeem Finished",
					Content = "Finished trying to redeem all codes.",
					Duration = 5,
				})
			else
				getgenv().LonumObject:Notify({
					Title = "Error",
					Content = "Redeem remote event not found!",
					Duration = 3,
				})
			end
		end)
	end,
})

Tabs.Stats:CreateSection("Auto Stats & Abilities")
Tabs.Stats:CreateToggle({
	Name = "Enable Auto Stats",
	CurrentValue = false,
	Flag = "ToggleAutoStats",
	Callback = function(Value)
		isAutoStatsEnabled = Value
	end,
})

Tabs.Stats:CreateToggle({
	Name = "Enable Auto Ken (Haki)",
	CurrentValue = false,
	Flag = "ToggleAutoKen",
	Callback = function(Value)
		isAutoKenEnabled = Value
	end,
})

Tabs.Stats:CreateDropdown({
	Name = "Select Stat to Upgrade",
	Options = { "Melee", "Defense", "Sword", "Gun", "Demon Fruit" },
	CurrentOption = { "Melee" },
	MultipleOptions = false,
	Flag = "AutoStatsDropdown",
	Callback = function(Option)
		selectedStatCategory = Option[1]
	end,
})

Tabs.Stats:CreateSection("Auto Use Skills")
skillLetters = { "Z", "X", "C", "V" }
for _, sk in ipairs(skillLetters) do
	Tabs.Stats:CreateToggle({
		Name = "Auto Use Skill " .. sk,
		CurrentValue = false,
		Flag = "AutoSkill" .. sk,
		Callback = function(Value)
			getgenv()["AutoSkill" .. sk] = Value
			task.spawn(function()
				while getgenv()["AutoSkill" .. sk] do
					task.wait(0.1)
					if (isReadyToAttack or currentTargetInstance) and not getgenv().IsUsingSkill then
						getgenv().IsUsingSkill = true
						pcall(function()
							game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode[sk], false, game)
							task.wait(0.15)
							game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode[sk], false, game)
						end)
						task.wait(0.1)
						getgenv().IsUsingSkill = false
					end
				end
			end)
		end,
	})
end

Tabs.Main:CreateSection("Auto Farming")
FarmToggle = Tabs.Main:CreateToggle({
	Name = "Enable Auto Farm",
	CurrentValue = false,
	Flag = "ToggleAutoFarm",
	Callback = function(Value)
		enabled = Value
		if enabled then
			StartAutoFarm()
		else
			StopAutoFarm()
		end
	end,
})

Tabs.Main:CreateToggle({
	Name = "Auto Attack",
	CurrentValue = false,
	Flag = "ToggleStandaloneAttack",
	Callback = function(Value)
		isAutoAttackEnabled = Value
	end,
})

Tabs.Main:CreateToggle({
	Name = "Auto Farm Nearest",
	CurrentValue = false,
	Flag = "ToggleFarmNearest",
	Callback = function(Value)
		farmNearestEnabled = Value
		if Value then
			enabled = false
			if FarmToggle then
				FarmToggle:Set(false)
			end
			workerGeneration = workerGeneration + 1

			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil

			StartFarmNearest()
		else
			workerGeneration = workerGeneration + 1
			StopAllActivities()
		end
	end,
})

Tabs.Main:CreateSlider({
	Name = "Farm Nearest Radius",
	Range = { 100, 5000 },
	Increment = 50,
	CurrentValue = 5000,
	Flag = "SliderFarmNearestRadius",
	Callback = function(Value)
		farmNearestRadius = Value
	end,
})

Tabs.Main:CreateToggle({
	Name = "Auto Farm Berry",
	CurrentValue = false,
	Flag = "ToggleAutoFarmBerry",
	Callback = function(Value)
		cfg.isAutoBerry = Value
		if Value then
			enabled = false
			if FarmToggle then
				FarmToggle:Set(false)
			end
			isAutoBone = false
			isAutoMaterial = false
			ScriptContext:StartAutoBerry()
		else
			ScriptContext:StopAutoBerry()
		end
	end,
})

bossNames = {}
for _, boss in ipairs(BOSSES) do
	table.insert(bossNames, boss.Name)
end

Tabs.Misc:CreateSection("Material Farming")
Tabs.Misc:CreateToggle({
	Name = "Auto Spin Bones",
	CurrentValue = false,
	Flag = "ToggleAutoSpinBones",
	Callback = function(Value)
		isAutoSpinBones = Value
	end,
})

Tabs.Misc:CreateButton({
	Name = "Spin Bones 1x",
	Callback = function()
		task.spawn(function()
			pcall(function()
				local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
					and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
				if CommF_ then
					local bonesCount = CommF_:InvokeServer("Bones", "Check")
					if type(bonesCount) == "number" and bonesCount >= 50 then
						local result = CommF_:InvokeServer("Bones", "Buy", 1, 1)
						if getgenv().LonumObject then
							getgenv().LonumObject:Notify({
								Title = "Spin Bones Success",
								Content = "Successfully spun! Remaining Bones: " .. tostring(bonesCount - 50),
								Duration = 3,
								Image = 4483362458,
							})
						end
					else
						if getgenv().LonumObject then
							getgenv().LonumObject:Notify({
								Title = "Spin Bones Failed",
								Content = "Bones tidak cukup/anda terkena limit 10 spin per hari",
								Duration = 3,
								Image = 4483362458,
							})
						end
					end
				end
			end)
		end)
	end,
})

Tabs.Sea3:CreateToggle({
	Name = "Auto Farm Bone",
	CurrentValue = false,
	Flag = "ToggleAutoBone",
	Callback = function(Value)
		isAutoBone = Value
		if Value then
			enabled = false
			FarmToggle:Set(false)
			isAutoMaterial = false

			workerGeneration = workerGeneration + 1

			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil
			lastTargetPos = nil
			StartAutoBone()
		else
			workerGeneration = workerGeneration + 1
			StopAllActivities()
		end
	end,
})

Tabs.Sea3:CreateToggle({
	Name = "Auto Cake Prince",
	CurrentValue = false,
	Flag = "ToggleAutoCakePrince",
	Callback = function(Value)
		isAutoCakePrince = Value
		if Value then
			enabled = false
			isAutoBone = false
			isAutoMaterial = false
			if FarmToggle then
				FarmToggle:Set(false)
			end

			cakePrinceWorkerGeneration = cakePrinceWorkerGeneration + 1

			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil
			lastTargetPos = nil
			StartAutoCakePrince()
		else
			isAutoCakePrince = false
			cakePrinceWorkerGeneration = cakePrinceWorkerGeneration + 1
			StopAllActivities()
		end
	end,
})

Tabs.Sea3:CreateToggle({
	Name = "Auto Dough King",
	CurrentValue = false,
	Flag = "ToggleAutoDoughKing",
	Callback = function(Value)
		isAutoDoughKing = Value
		isAutodoughKing = Value
		if Value then
			enabled = false
			isAutoBone = false
			isAutoMaterial = false
			if FarmToggle then
				FarmToggle:Set(false)
			end

			doughKingWorkerGeneration = doughKingWorkerGeneration + 1

			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil
			lastTargetPos = nil
			StartAutoDoughKing()
		else
			isAutoDoughKing = false
			isAutodoughKing = false
			doughKingWorkerGeneration = doughKingWorkerGeneration + 1
			StopAllActivities()
		end
	end,
})

Tabs.Sea3:CreateSection("Elite Hunter")
Tabs.Sea3:CreateToggle({
	Name = "Auto Elite Hunter",
	CurrentValue = false,
	Flag = "ToggleAutoEliteHunter",
	Callback = function(Value)
		isAutoEliteHunter = Value
		if Value then
			enabled = false
			isAutoBone = false
			isAutoMaterial = false
			if FarmToggle then
				FarmToggle:Set(false)
			end

			eliteHunterWorkerGen = eliteHunterWorkerGen + 1
			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil
			StartAutoEliteHunter()
		else
			isEliteHunterActive = false
			eliteHunterWorkerGen = eliteHunterWorkerGen + 1
			StopAllActivities()
		end
	end,
})

Tabs.Main:CreateToggle({
	Name = "Boss Hunter",
	CurrentValue = false,
	Flag = "ToggleBossHunter",
	Callback = function(Value)
		isBossHunterEnabled = Value
		isReadyToAttack = false
		currentTargetInstance = nil
		lastTargetPos = nil
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
	end,
})

Tabs.Raid:CreateSection("Law Raid (Sea 2)")
Tabs.Raid:CreateToggle({
	Name = "Auto Buy Chip Law",
	CurrentValue = false,
	Flag = "AutoBuyLaw",
	Callback = function(Value)
		getgenv().AutoBuyLaw = Value
		task.spawn(function()
			while getgenv().AutoBuyLaw do
				task.wait(1)
				pcall(function()
					local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
						and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
					if CommF_ then
						CommF_:InvokeServer("BuyMicrochip")
					end
				end)
			end
		end)
	end,
})

Tabs.Raid:CreateToggle({
	Name = "Auto Start Raid Law",
	CurrentValue = false,
	Flag = "AutoStartLaw",
	Callback = function(Value)
		getgenv().AutoStartLaw = Value
		task.spawn(function()
			while getgenv().AutoStartLaw do
				task.wait(1)
				pcall(function()
					local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
					if myHrp then
						local lawButton = workspace:FindFirstChild("Map")
							and workspace.Map:FindFirstChild("Igloo")
							and workspace.Map.Igloo:FindFirstChild("TopButton")
						if lawButton then
							local dist = (myHrp.Position - lawButton.Position).Magnitude
							if dist > 20 then
								TweenTo(CFrame.new(lawButton.Position))
							else
								firetouchinterest(myHrp, lawButton, 0)
								task.wait(0.1)
								firetouchinterest(myHrp, lawButton, 1)
							end
						end
					end
				end)
			end
		end)
	end,
})

Tabs.Raid:CreateSection("Auto Raid")
Tabs.Raid:CreateToggle({
	Name = "Enable Auto Raid",
	CurrentValue = false,
	Flag = "ToggleAutoRaidMaster",
	Callback = function(Value)
		isAutoRaidKill = Value
		if Value then
			StartAutoRaid()
		else
			raidWorkerGeneration = raidWorkerGeneration + 1
			StopAllActivities()
		end
	end,
})

Tabs.Raid:CreateToggle({
	Name = "Auto Raid Attack",
	CurrentValue = true,
	Flag = "ToggleRaidAttack",
	Callback = function(Value)
		isAutoRaidAttack = Value
	end,
})

Tabs.Raid:CreateToggle({
	Name = "Auto Raid Bring",
	CurrentValue = true,
	Flag = "ToggleRaidBring",
	Callback = function(Value)
		isAutoRaidBring = Value
	end,
})

Tabs.Raid:CreateToggle({
	Name = "Auto Next Island",
	CurrentValue = true,
	Flag = "ToggleRaidNextIsland",
	Callback = function(Value)
		isAutoRaidNextIsland = Value
	end,
})

Tabs.Main:CreateSection("Material Farming")
Tabs.Main:CreateDropdown({
	Name = "Select Material",
	Options = { "None", "Conjured Cocoa", "Dragon Scale", "Fish Tail", "Mystic Droplet", "Magma Orb" },
	CurrentOption = { "None" },
	MultipleOptions = false,
	Flag = "MaterialTargetDrop",
	Callback = function(Option)
		selectedMaterialTarget = Option[1]
		isReadyToAttack = false
		currentTargetInstance = nil
	end,
})

Tabs.Main:CreateToggle({
	Name = "Enable Auto Material Farm",
	CurrentValue = false,
	Flag = "ToggleAutoMaterial",
	Callback = function(Value)
		isAutoMaterial = Value
		if Value then
			enabled = false
			isAutoBone = false
			if FarmToggle then
				FarmToggle:Set(false)
			end
			workerGeneration = workerGeneration + 1

			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil
			lastTargetPos = nil
			StartAutoMaterialFarm()
		else
			workerGeneration = workerGeneration + 1
			StopAllActivities()
		end
	end,
})

Tabs.Main:CreateSection("Boss & Targeting")
Tabs.Main:CreateDropdown({
	Name = "Boss Target",
	Options = bossNames,
	CurrentOption = { bossNames[1] or "" },
	MultipleOptions = false,
	Flag = "BossTargetDrop",
	Callback = function(Option)
		selectedBossName = Option[1]
		isReadyToAttack = false
		currentTargetInstance = nil
		lastTargetPos = nil
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
	end,
})

Tabs.Main:CreateDropdown({
	Name = "Attack Speed",
	Options = { "Fast Attack", "Super Fast Attack" },
	CurrentOption = { "Fast Attack" },
	MultipleOptions = false,
	Flag = "AtkSpeedDrop",
	Callback = function(Option)
		attackSpeedMode = Option[1]
	end,
})

Tabs.Main:CreateToggle({
	Name = "Fast Gun M1",
	CurrentValue = false,
	Flag = "FastGunM1Tog",
	Callback = function(Value)
		getgenv().isFastGun = Value
	end,
})

Tabs.Main:CreateToggle({
	Name = "Multi Mob Damage",
	CurrentValue = isMultiMobDamage,
	Flag = "MultiMobTog",
	Callback = function(Value)
		isMultiMobDamage = Value
	end,
})

Tabs.Travel:CreateSection("Boat")

Tabs.Travel:CreateDropdown({
	Name = "Select Boat to Buy",
	Options = { "Dinghy", "Sloop", "MarineBrigade", "MarineGrandBrigade", "Guardian" },
	CurrentOption = { "Dinghy" },
	MultipleOptions = false,
	Flag = "BoatTypeDrop",
	Callback = function(Option)
		cfg.boatType = Option[1]
	end,
})

Tabs.Travel:CreateToggle({
	Name = "Auto Boat",
	CurrentValue = false,
	Flag = "AutoBoatEnabled",
	Callback = function(Value)
		cfg.autoBoat = Value
		if not Value then
			StopAllActivities()

			local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.Velocity = Vector3.zero
			end
		end
	end,
})

Tabs.Travel:CreateToggle({
	Name = "Enable Boat Speed Mod",
	CurrentValue = false,
	Flag = "ToggleBoatMod",
	Callback = function(Value)
		cfg.boatSpeedMod = Value
	end,
})

Tabs.Travel:CreateSlider({
	Name = "Boat Max Speed",
	Range = { 50, 300 },
	Increment = 10,
	CurrentValue = 300,
	Flag = "SliderBoatMaxSpeed",
	Callback = function(Value)
		cfg.boatMaxSpeed = Value
	end,
})

Tabs.Travel:CreateButton({
	Name = "Remove Rocks",
	Callback = function()
		local Rocks = Workspace:WaitForChild("Rocks")

		if Rocks then
			Rocks:Destroy()
		end
	end,
})

Tabs.Travel:CreateButton({
	Name = "Remove Dark (Danger 6)",
	Callback = function()
		local Layers = Lighting:FindFirstChild("LightingLayers")
		if not Layers then
			return
		end

		local Fog = Layers:FindFirstChild("DarkFog")
		if not Fog then
			return
		end

		Fog:SetAttribute("ZIndex", 0)
		Fog.Density = 0
		Fog.Offset = 0

		local Intensity = Fog:FindFirstChild("Intensity")
		if Intensity then
			Intensity.Value = 0
		end
	end,
})

Tabs.Sea3:CreateSection("Mirage Island")
CreateIslandESP("Mirage Island", Color3.fromRGB(0, 255, 255))
Tabs.Sea3:CreateToggle({
	Name = "Look Moon + Auto V3 (Mirage)",
	CurrentValue = false,
	Flag = "LookMoonV3",
	Callback = function(Value)
		getgenv().AutoMoonV3 = Value
		task.spawn(function()
			while getgenv().AutoMoonV3 do
				task.wait(2)
				pcall(function()
					local moonDir = game.Lighting:GetMoonDirection()
					local cam = workspace.CurrentCamera
					local lookPos = cam.CFrame.p + moonDir * 100
					cam.CFrame = CFrame.lookAt(cam.CFrame.p, lookPos)

					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
					task.wait(0.1)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
				end)
			end
		end)
	end,
})

Tabs.Sea3:CreateToggle({
	Name = "Auto Mirage Chests",
	CurrentValue = false,
	Callback = function(state)
		autoChest = state

		if not state then
			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end
			return
		end

		task.spawn(function()
			while autoChest do
				local mysticIsland = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("MysticIsland")
				local chestsFolder = mysticIsland and mysticIsland:FindFirstChild("Chests")

				if chestsFolder then
					local chests = chestsFolder:GetChildren()
					local foundChest = false

					for _, chest in ipairs(chests) do
						if not autoChest then
							break
						end

						if chest:IsA("BasePart") and chest.Parent == chestsFolder then
							foundChest = true

							ToggleFloat(true)
							TweenTo(chest.CFrame * CFrame.new(0, 3, 0))
						end
					end

					if not foundChest then
						task.wait()
					end
				else
					ToggleFloat(false)
					task.wait()
				end

				task.wait()
			end
		end)
	end,
})

Tabs.Sea3:CreateSection("Kitsune Island")
CreateIslandESP("Kitsune Island", Color3.fromRGB(0, 85, 255))
Tabs.Sea3:CreateToggle({
	Name = "Auto Tween Kitsune Island",
	CurrentValue = false,
	Flag = "TweenKitsune",
	Callback = function(Value)
		getgenv().TweenKitsune = Value
		task.spawn(function()
			while getgenv().TweenKitsune do
				local origin = workspace:FindFirstChild("_WorldOrigin")
				local locs = origin and origin:FindFirstChild("Locations")
				local targetPos = nil
				if locs then
					local kIsland = locs:FindFirstChild("Kitsune Island")
					if kIsland then
						targetPos = kIsland.Position
					end
				end
				if not targetPos then
					local map = workspace:FindFirstChild("Map")
					local kMod = map and map:FindFirstChild("KitsuneIsland")
					if kMod then
						targetPos = GetSafePosition(kMod)
					end
				end
				if targetPos then
					TweenTo(CFrame.new(targetPos + Vector3.new(0, 300, 0)))
				end
				task.wait(1)
			end
		end)
	end,
})

Tabs.Sea3:CreateToggle({
	Name = "Auto Collect Ember",
	CurrentValue = false,
	Flag = "ToggleKitsuneEmber",
	Callback = function(Value)
		AutoEmber = Value

		if Value then
			task.spawn(function()
				while AutoEmber do
					local char = GetCharacter()
					local myHrp = char and char:FindFirstChild("HumanoidRootPart")

					if myHrp then
						if workspace:FindFirstChild("AttachedAzureEmber") then
							for _, part in ipairs(workspace:GetChildren()) do
								if part.Name == "EmberTemplate" then
									local safePos = GetSafePosition(part)
									if safePos then
										myHrp.CFrame = CFrame.new(safePos)
									end
								end
							end
						end
					end
					task.wait()
				end
			end)
		end
	end,
})

Tabs.Sea3:CreateSection("Prehistoric Island")
Tabs.Sea3:CreateToggle({
	Name = "Auto Start Prehistoric",
	CurrentValue = false,
	Flag = "AutoPrehistoricStart",
	Callback = function(Value)
		if not Value then
			return
		end

		local prehistoricIsland = nil
		local nearestDistance = math.huge
		local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
		if not myHrp or not workspace:FindFirstChild("Map") then
			return
		end

		for _, datamodel in ipairs(workspace.Map:GetChildren()) do
			if
				(datamodel.Name == "PrehistoricIsland" or string.find(datamodel.Name, "Prehistoric"))
				and datamodel:IsA("Model")
			then
				local prehistoricIslandPos = GetSafePosition(datamodel)
				local distance = (myHrp.Position - prehistoricIslandPos).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					prehistoricIsland = datamodel
				end
			end
		end

		if
			not prehistoricIsland
			and workspace:FindFirstChild("_WorldOrigin")
			and workspace._WorldOrigin:FindFirstChild("Locations")
		then
			for _, datamodel in ipairs(workspace._WorldOrigin.Locations:GetChildren()) do
				if string.find(datamodel.Name, "Prehistoric") then
					local prehistoricIslandPos = GetSafePosition(datamodel)
					local distance = (myHrp.Position - prehistoricIslandPos).Magnitude
					if distance < nearestDistance then
						nearestDistance = distance
						prehistoricIsland = datamodel
					end
				end
			end
		end

		if not prehistoricIsland then
			return
		end

		local startPromptPart = prehistoricIsland:FindFirstChild("Core")
			and prehistoricIsland.Core:FindFirstChild("ActivationPrompt")
		if not startPromptPart then
			return
		end

		local startPromptLocation = GetSafePosition(startPromptPart)
		TweenTo(CFrame.new(startPromptLocation))

		if (myHrp.Position - startPromptLocation).Magnitude < 10 then
			SafeProximity(startPromptPart)
		end
	end,
})

Tabs.Sea3:CreateSection("Race V4 (Trials) & Teleports")
Tabs.Sea3:CreateButton({
	Name = "Teleport to Temple Of Time",
	Callback = function()
		TweenTo(CFrame.new(28286, 14897, 103))
	end,
})
Tabs.Sea3:CreateButton({
	Name = "Teleport to Lever Pull",
	Callback = function()
		TweenTo(CFrame.new(28285, 14897, -35))
	end,
})
Tabs.Sea3:CreateButton({
	Name = "Teleport to Top Great Tree",
	Callback = function()
		TweenTo(CFrame.new(28284, 14897, -36))
	end,
})
Tabs.Sea3:CreateButton({
	Name = "Teleport To The Clock",
	Callback = function()
		TweenTo(CFrame.new(29000, 14897, 100))
	end,
})
Tabs.Sea3:CreateToggle({
	Name = "Auto Buy Ancient One Quest (Gear)",
	CurrentValue = false,
	Flag = "AutoBuyAncient",
	Callback = function(Value)
		getgenv().AutoAncient = Value
		task.spawn(function()
			while getgenv().AutoAncient do
				task.wait(1)
				pcall(function()
					local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
						and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
					if CommF_ then
						CommF_:InvokeServer("BuyAncientOne")
					end
				end)
			end
		end)
	end,
})

Tabs.Sea3:CreateSection("Cursed Dual Katana")
Tabs.Sea3:CreateToggle({
	Name = "Auto Haze",
	CurrentValue = false,
	Flag = "AutoHazeOpt",
	Callback = function(Value)
		cfg.isAutoHaze = Value
		if Value then
			local seaName, seaNum = GetCurrentSea()
			if seaNum ~= 3 then
				print("You must be in Sea 3 to use Auto Haze")
				local pcallOk = pcall(rconsoleprint, "You must be in Sea 3 to use Auto Haze\n")
				if not pcallOk then
					print("Missing rconsoleprint")
				end
				return
			end
			enabled = false
			isAutoRaidKill = false
			isAutoBone = false
			if FarmToggle then
				FarmToggle:Set(false)
			end
			workerGeneration = workerGeneration + 1
			StartAutoHaze()
		else
			workerGeneration = workerGeneration + 1
			StopAllActivities()
		end
	end,
})

Tabs.Travel:CreateToggle({
	Name = "Auto Kill Enemy",
	CurrentValue = false,
	Flag = "AutoKillEnemy",
	Callback = function(Value)
		autoKillVolcano = Value
		if Value then
			enabled = false
			if FarmToggle then
				FarmToggle:Set(false)
			end
			workerGeneration = workerGeneration + 1

			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil

			StartAutoKillVolcano()
		else
			workerGeneration = workerGeneration + 1
			StopAllActivities()
		end
	end,
})

Tabs.Travel:CreateToggle({
	Name = "Auto Fill Volcano",
	CurrentValue = false,
	Flag = "AutoFillVolcano",
	Callback = function(Value)
		if not Value then
			return
		end

		local prehistoricIsland = nil
		local nearestDistance = math.huge
		local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
		if not myHrp or not workspace:FindFirstChild("Map") then
			return
		end

		for _, datamodel in ipairs(workspace.Map:GetChildren()) do
			if datamodel.Name == "PrehistoricIsland" or string.find(datamodel.Name, "Prehistoric") then
				local distance = (myHrp.Position - GetSafePosition(datamodel)).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					prehistoricIsland = datamodel
				end
			end
		end

		if
			not prehistoricIsland
			and workspace:FindFirstChild("_WorldOrigin")
			and workspace._WorldOrigin:FindFirstChild("Locations")
		then
			for _, datamodel in ipairs(workspace._WorldOrigin.Locations:GetChildren()) do
				if string.find(datamodel.Name, "Prehistoric") then
					local distance = (myHrp.Position - GetSafePosition(datamodel)).Magnitude
					if distance < nearestDistance then
						nearestDistance = distance
						prehistoricIsland = datamodel
					end
				end
			end
		end

		if not prehistoricIsland or not prehistoricIsland:FindFirstChild("Core") then
			return
		end

		local Rocks = prehistoricIsland.Core:FindFirstChild("VolcanoRocks")
		if not Rocks then
			return
		end

		for _, rock in ipairs(Rocks:GetChildren()) do
			for _, volcanoRock in ipairs(rock:GetChildren()) do
				if volcanoRock.Name == "volcanorock" then
					local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
					local volcanoRockPos = GetSafePosition(volcanoRock)
					TweenTo(CFrame.new(volcanoRockPos))

					local currentFruit = game:GetService("Players").LocalPlayer.Data.DevilFruit
					local function IsCooldown(skillName)
						local playerGui = player:FindFirstChild("PlayerGui")
						local mainUI = playerGui and playerGui:FindFirstChild("Main")
						local skillsUI = mainUI and mainUI:FindFirstChild("Skills")

						local fruitUI = skillsUI and skillsUI:FindFirstChild(tostring(currentFruit))
						local skillSlot = fruitUI and fruitUI:FindFirstChild(tostring(skillName))
						local cdBar = skillSlot and skillSlot:FindFirstChild("Cooldown")

						if cdBar and cdBar:IsA("GuiObject") then
							return cdBar.Size.X.Scale > 0
						end

						return true
					end

					local bg = myHrp:FindFirstChild("BodyGyroClip")
					local lookCFrame =
						CFrame.lookAt(myHrp.Position, Vector3.new(volcanoRockPos.X, myHrp.Position.Y, volcanoRockPos.Z))
					if bg then
						bg.CFrame = lookCFrame
					elseif not activeTween then
						myHrp.CFrame = lookCFrame
					end
					for _, keyCode in ipairs(skillKeys) do
						local skillName = keyCode.Name

						if not IsCooldown(skillName) then
							TriggerSkills(keyCode)
							break
						end
					end
				end
			end
		end
	end,
})

Tabs.Travel:CreateSection("Sea Events")
Tabs.Travel:CreateToggle({
	Name = "Auto Sail",
	CurrentValue = false,
	Flag = "AutoSailEnabled",
	Callback = function(Value)
		cfg.autoSail = Value
		if not Value then
			StopAllActivities()
			local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.Velocity = Vector3.zero
			end
		end
	end,
})

Tabs.Travel:CreateToggle({
	Name = "Auto Sea Events (Sea Beast, Terror, Shark)",
	CurrentValue = false,
	Flag = "AutoSeaBeastEnabled",
	Callback = function(Value)
		cfg.autoSeaBeast = Value
		if Value then
			StartAutoSeaBeast()
		else
			isAutoSeaBeastActive = false
			autoSeaBeastWorkerGen = autoSeaBeastWorkerGen + 1
			StopAllActivities()
		end
	end,
})

Tabs.Travel:CreateSection("World Events")
Tabs.Travel:CreateToggle({
	Name = "Auto Collect Chest",
	CurrentValue = false,
	Flag = "AutoChestEnabled",
	Callback = function(Value)
		cfg.autoChest = Value
		if not Value and activeTween then
			activeTween:Cancel()
			activeTween = nil
			ToggleFloat(false)
		end
	end,
})

Tabs.Travel:CreateToggle({
	Name = "Auto Fruit Finder",
	CurrentValue = false,
	Flag = "AutoFruitEnabled",
	Callback = function(Value)
		cfg.autoFruit = Value
		if not Value and activeTween then
			activeTween:Cancel()
			activeTween = nil
			ToggleFloat(false)
		end
	end,
})

Tabs.Travel:CreateToggle({
	Name = "Auto Dodge Projectiles",
	CurrentValue = false,
	Flag = "AutoDodgeEnabled",
	Callback = function(Value)
		cfg.dodgeEnabled = Value
	end,
})

Tabs.Travel:CreateSection("Server & Teleport")
Tabs.Travel:CreateButton({
	Name = "Set Home Point (Spawn)",
	Callback = function()
		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SetSpawnPoint")
		end)
	end,
})
Tabs.Travel:CreateButton({
	Name = "Rejoin Current Server",
	Callback = function()
		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
	end,
})
Tabs.Travel:CreateButton({
	Name = "Server Hop Now",
	Callback = function()
		ServerHop()
	end,
})

Tabs.Travel:CreateToggle({
	Name = "Find Low Player Server",
	CurrentValue = false,
	Flag = "LowPlayerServerEnabled",
	Callback = function(Value)
		cfg.lowPlayerServer = Value
	end,
})

Tabs.Travel:CreateSlider({
	Name = "Max Players for Hop",
	Range = { 1, 20 },
	Increment = 1,
	CurrentValue = 8,
	Flag = "MaxPlayersForHop",
	Callback = function(Value)
		cfg.maxPlayersForHop = Value
	end,
})

Tabs.Settings:CreateSection("Weapon & Mastery")

Tabs.Settings:CreateDropdown({
	Name = "Weapon Category",
	Options = { "Melee", "Sword", "Fruit", "Gun" },
	CurrentOption = { "Melee" },
	MultipleOptions = false,
	Flag = "WepCatDrop",
	Callback = function(Option)
		cfg.WeaponCategory = Option[1]
	end,
})

Tabs.Settings:CreateToggle({
	Name = "Auto Mastery",
	CurrentValue = cfg.AutoMastery,
	Flag = "AutoMastTog",
	Callback = function(Value)
		cfg.AutoMastery = Value
	end,
})

Tabs.Settings:CreateDropdown({
	Name = "Mastery Category",
	Options = { "Melee", "Sword", "Fruit", "Gun" },
	CurrentOption = { "Melee" },
	MultipleOptions = false,
	Flag = "MastCatDrop",
	Callback = function(Option)
		cfg.MasteryCategory = Option[1]
	end,
})

Tabs.Settings:CreateSlider({
	Name = "Mastery Health Switch (%)",
	Range = { 1, 95 },
	Increment = 1,
	CurrentValue = cfg.MasteryHealth,
	Flag = "MastHealthSlider",
	Callback = function(Value)
		cfg.MasteryHealth = Value
	end,
})

Tabs.Settings:CreateSection("Ranges & Evasion")

Tabs.Settings:CreateSlider({
	Name = "Bring Radius",
	Range = { 100, 1000 },
	Increment = 10,
	CurrentValue = cfg.BringRadius,
	Flag = "BringRadSlider",
	Callback = function(Value)
		cfg.BringRadius = Value
	end,
})

Tabs.Settings:CreateSlider({
	Name = "Max Pull Range",
	Range = { 100, 1000 },
	Increment = 10,
	CurrentValue = cfg.MaxPullRange,
	Flag = "PullRangeSlider",
	Callback = function(Value)
		cfg.MaxPullRange = Value
	end,
})

Tabs.Settings:CreateSlider({
	Name = "Hit Radius",
	Range = { 10, 150 },
	Increment = 5,
	CurrentValue = cfg.HitRadius,
	Flag = "HitRadSlider",
	Callback = function(Value)
		cfg.HitRadius = Value
	end,
})

Tabs.Settings:CreateSlider({
	Name = "Evasion Radius",
	Range = { 0, 100 },
	Increment = 1,
	CurrentValue = cfg.EvasionRadius,
	Flag = "EvasionRadSlider",
	Callback = function(Value)
		cfg.EvasionRadius = Value
	end,
})

Tabs.Settings:CreateSection("Tween & Timing")

Tabs.Settings:CreateDropdown({
	Name = "Bring Method",
	Options = { "Tween", "CFrame" },
	CurrentOption = "Tween",
	Flag = "BringMethodOpt",
	Callback = function(Option)
		cfg.BringMethod = Option
	end,
})

Tabs.Settings:CreateSlider({
	Name = "Tween Speed",
	Range = { 100, 600 },
	Increment = 10,
	CurrentValue = cfg.TweenSpeed,
	Flag = "TweenSpdSlider",
	Callback = function(Value)
		cfg.TweenSpeed = Value

		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
	end,
})

Tabs.Settings:CreateToggle({
	Name = "Portal Teleport Bypass",
	CurrentValue = cfg.UsePortal,
	Flag = "UsePortalToggle",
	Callback = function(Value)
		cfg.UsePortal = Value
	end,
})

Tabs.Settings:CreateSlider({
	Name = "Tween Height",
	Range = { 0, 50 },
	Increment = 1,
	CurrentValue = cfg.TweenHeight,
	Flag = "TweenHeightSlider",
	Callback = function(Value)
		cfg.TweenHeight = Value
	end,
})

Tabs.Settings:CreateSlider({
	Name = "Evasion Tick (x100)",
	Range = { 1, 100 },
	Increment = 1,
	CurrentValue = cfg.EvasionTick * 100,
	Flag = "EvasionTickSlider",
	Callback = function(Value)
		cfg.EvasionTick = Value / 100
	end,
})

Tabs.Settings:CreateSlider({
	Name = "Stuck Timeout",
	Range = { 2, 30 },
	Increment = 1,
	CurrentValue = 3,
	Flag = "StuckTimeSlider",
	Callback = function(Value)
		cfg.StuckTimeout = Value
	end,
})

Tabs.Dungeon:CreateSection("Auto Dungeon Settings")

Tabs.Dungeon:CreateToggle({
	Name = "Enable Auto Dungeon",
	CurrentValue = false,
	Flag = "ToggleAutoDungeonMaster",
	Callback = function(Value)
		isAutoDungeon = Value
		if Value then
			enabled = false
			isAutoRaidKill = false
			isAutoBone = false
			if FarmToggle then
				FarmToggle:Set(false)
			end
			StartAutoDungeon()
		else
			dungeonWorkerGeneration = dungeonWorkerGeneration + 1
			StopAllActivities()
		end
	end,
})

Tabs.Dungeon:CreateToggle({
	Name = "Auto Dungeon Attack",
	CurrentValue = false,
	Flag = "ToggleDungAttack",
	Callback = function(Value)
		isAutoDungeonAttack = Value
	end,
})

Tabs.Dungeon:CreateToggle({
	Name = "Auto Dungeon Bring",
	CurrentValue = false,
	Flag = "ToggleDungBring",
	Callback = function(Value)
		isAutoDungeonBring = Value
	end,
})

Tabs.Dungeon:CreateToggle({
	Name = "Auto Next Dungeon Stage",
	CurrentValue = false,
	Flag = "ToggleDungNext",
	Callback = function(Value)
		isAutoDungeonNext = Value
	end,
})

local islandOptions = GetIslandLocations()

Tabs.Travel:CreateButton({
	Name = "Open Fruit Dealer",
	Callback = function()
		pcall(function()
			local env = getrenv and getrenv() or _G
			local Library = env.require(game.ReplicatedStorage.DialoguesList.Library)
			if Library and Library.openFruitShop then
				Library.openFruitShop("FruitDealer")
			end
		end)
	end,
})

Tabs.Travel:CreateButton({
	Name = "Open Advanced Fruit Dealer",
	Callback = function()
		pcall(function()
			local env = getrenv and getrenv() or _G
			local Library = env.require(game.ReplicatedStorage.DialoguesList.Library)
			if Library and Library.openFruitShop then
				Library.openFruitShop("AdvancedFruitDealer")
			end
		end)
	end,
})

local selectedIslandToTeleport = ""
Tabs.Travel:CreateDropdown({
	Name = "Select Island",
	Options = islandOptions,
	CurrentOption = { islandOptions[1] or "" },
	MultipleOptions = false,
	Flag = "TeleportIslandDrop",
	Callback = function(Option)
		selectedIslandToTeleport = Option[1]
	end,
})

local isTeleportingToIsland = false
local teleportIslandWorker = 0
Tabs.Travel:CreateToggle({
	Name = "Auto Teleport",
	CurrentValue = false,
	Flag = "ToggleTeleportIsland",
	Callback = function(Value)
		if not Value then
			isTeleportingToIsland = false
			cfg.isTeleportingToIsland = false
			teleportIslandWorker = teleportIslandWorker + 1
			StopAllActivities()
			return
		end

		if selectedIslandToTeleport == "" or selectedIslandToTeleport == "No islands found (Error)" then
			if getgenv().LonumObject then
				getgenv().LonumObject:Notify({
					Title = "Teleport Failed",
					Content = "Please select an island from the dropdown first.",
					Duration = 3,
					Image = 4483362458,
				})
			end
			return
		end

		enabled = false
		isAutoBone = false
		isAutoMaterial = false
		isAutoCakePrince = false
		isAutoDoughKing = false
		isAutodoughKing = false
		isAutoEliteHunter = false
		autoKillVolcano = false
		cfg.autoSeaBeast = false
		cfg.isTeleportingToIsland = true
		workerGeneration = workerGeneration + 1
		if FarmToggle then
			FarmToggle:Set(false)
		end

		isTeleportingToIsland = true
		teleportIslandWorker = teleportIslandWorker + 1
		local gen = teleportIslandWorker

		local origin = workspace:FindFirstChild("_WorldOrigin")
		local locations = origin and origin:FindFirstChild("Locations")
		local targetIsland = locations and locations:FindFirstChild(selectedIslandToTeleport)

		if targetIsland then
			local targetCFrame = targetIsland:IsA("Model") and targetIsland:GetPivot() or targetIsland.CFrame
			local safeCFrame = targetCFrame * CFrame.new(0, 150, 0)

			if getgenv().LonumObject then
				getgenv().LonumObject:Notify({
					Title = "Teleportasi Dimulai",
					Content = "Terbang menuju " .. selectedIslandToTeleport .. ". Matikan toggle untuk berhenti.",
					Duration = 3,
					Image = 4483362458,
				})
			end

			task.spawn(function()
				while isTeleportingToIsland and ScriptContext.Running and gen == teleportIslandWorker do
					local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
					if hrp then
						ToggleFloat(true)
						local dist = (hrp.Position - safeCFrame.Position).Magnitude
						if dist > 50 then
							if not isTeleporting and not activeTween then
								TweenTo(safeCFrame)
							end
						else
							isTeleportingToIsland = false
							cfg.isTeleportingToIsland = false
							StopAllActivities()
						end
					end
					task.wait(0.2)
				end
			end)
		end
	end,
})

Tabs.PVP:CreateSection("Player Selection")

local function GetPlayerList()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			table.insert(list, p.Name)
		end
	end
	if #list == 0 then
		table.insert(list, "No Players Found")
	end
	return list
end

PlayerDropdown = Tabs.PVP:CreateDropdown({
	Name = "Select Target Player",
	Options = GetPlayerList(),
	CurrentOption = { GetPlayerList()[1] or "" },
	MultipleOptions = false,
	Flag = "CombatPlayerDrop",
	Callback = function(Option)
		getgenv().selectedPlayerToHunt = Option[1]
	end,
})

Tabs.PVP:CreateButton({
	Name = "Refresh Player List",
	Callback = function()
		PlayerDropdown:Refresh(GetPlayerList())
	end,
})

Tabs.PVP:CreateSection("PVP Toggles")

getgenv().tweenPlayerConn = nil
Tabs.PVP:CreateToggle({
	Name = "Tween To Player",
	CurrentValue = false,
	Flag = "ToggleTweenToPlayer",
	Callback = function(Value)
		isTweeningToPlayer = Value
		if Value then
			enabled = false
			isAutoRaidKill = false
			isAutoBone = false
			if FarmToggle then
				FarmToggle:Set(false)
			end

			getgenv().tweenPlayerConn = RunService.Heartbeat:Connect(function()
				if not isTweeningToPlayer then
					if getgenv().tweenPlayerConn then
						getgenv().tweenPlayerConn:Disconnect()
						getgenv().tweenPlayerConn = nil
					end
					return
				end

				local targetPlayer = Players:FindFirstChild(getgenv().selectedPlayerToHunt)
				if
					targetPlayer
					and targetPlayer.Character
					and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				then
					local tHrp = targetPlayer.Character.HumanoidRootPart
					TweenTo(tHrp.CFrame * CFrame.new(0, cfg.TweenHeight, 0))
				else
					if activeTween then
						activeTween:Cancel()
						activeTween = nil
					end
				end
			end)
			ScriptContext:AddConnection(getgenv().tweenPlayerConn)
		else
			if getgenv().tweenPlayerConn then
				getgenv().tweenPlayerConn:Disconnect()
				getgenv().tweenPlayerConn = nil
			end
			StopAllActivities()
		end
	end,
})

Tabs.PVP:CreateToggle({
	Name = "Spectate Player",
	CurrentValue = false,
	Flag = "ToggleSpectatePlayer",
	Callback = function(Value)
		local cam = workspace.CurrentCamera
		if Value then
			local targetPlayer = Players:FindFirstChild(getgenv().selectedPlayerToHunt)
			if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
				cam.CameraSubject = targetPlayer.Character.Humanoid
				if getgenv().LonumObject then
					getgenv().LonumObject:Notify({
						Title = "Spectating",
						Content = "Now spectating " .. targetPlayer.Name,
						Duration = 3,
						Image = 4483362458,
					})
				end
			else
				if getgenv().LonumObject then
					getgenv().LonumObject:Notify({
						Title = "Spectate Failed",
						Content = "Target player not found or dead.",
						Duration = 3,
						Image = 4483362458,
					})
				end
			end
		else
			local myChar = GetCharacter()
			if myChar and myChar:FindFirstChild("Humanoid") then
				cam.CameraSubject = myChar.Humanoid
			end
		end
	end,
})

getgenv().aimbotConn = nil
Tabs.PVP:CreateToggle({
	Name = "Aimbot To Player (Look At)",
	CurrentValue = false,
	Flag = "ToggleAimbotPlayer",
	Callback = function(Value)
		getgenv().isAimbotEnabled = Value
		if Value then
			getgenv().aimbotConn = RunService.RenderStepped:Connect(function()
				if not getgenv().isAimbotEnabled then
					if getgenv().aimbotConn then
						getgenv().aimbotConn:Disconnect()
						getgenv().aimbotConn = nil
					end
					return
				end

				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				local targetPlayer = Players:FindFirstChild(getgenv().selectedPlayerToHunt)

				if
					myHrp
					and targetPlayer
					and targetPlayer.Character
					and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				then
					local tHrp = targetPlayer.Character.HumanoidRootPart
					local bg = myHrp:FindFirstChild("BodyGyroClip")
					local lookCFrame =
						CFrame.lookAt(myHrp.Position, Vector3.new(tHrp.Position.X, myHrp.Position.Y, tHrp.Position.Z))
					if bg then
						bg.CFrame = lookCFrame
					elseif not activeTween then
						myHrp.CFrame = lookCFrame
					end
				end
			end)
			ScriptContext:AddConnection(getgenv().aimbotConn)
		else
			if getgenv().aimbotConn then
				getgenv().aimbotConn:Disconnect()
				getgenv().aimbotConn = nil
			end
		end
	end,
})

local function GetCurrentScriptTask()
	if isAutodoughKing then
		return "Auto Dough King"
	end
	if isAutoCakePrince then
		return "Auto Cake Prince"
	end
	if isAutoEliteHunter then
		return "Auto Elite Hunter"
	end
	if isAutoBone then
		return "Auto Bone"
	end
	if isAutoRaidKill then
		return "Auto Raid"
	end
	if cfg.isAutoBerry then
		return "Auto Berry / Spawn"
	end
	if farmNearestEnabled then
		return "Farm Nearest"
	end
	if autoKillVolcano then
		return "Auto Volcano"
	end
	if isAutoMaterial then
		return "Auto Material (" .. tostring(selectedMaterialTarget) .. ")"
	end
	if enabled then
		return "Auto Farm Level"
	end
	return "Idle"
end

Tabs.Status:CreateSection("ESP Players & Items")
Tabs.Status:CreateToggle({
	Name = "ESP Players",
	CurrentValue = false,
	Flag = "ESPPlayers",
	Callback = function(Value)
		getgenv().ESPPlayers = Value
	end,
})
HandleESP(game:GetService("Players"), "ESP_Player", Color3.fromRGB(255, 255, 255), "ESPPlayers")

Tabs.Status:CreateToggle({
	Name = "ESP Chests",
	CurrentValue = false,
	Flag = "ESPChests",
	Callback = function(Value)
		getgenv().ESPChests = Value
	end,
})
HandleESP(function()
	local chests = {}
	for _, v in ipairs(workspace:GetDescendants()) do
		if string.find(string.lower(v.Name), "chest") and v:IsA("Model") then
			table.insert(chests, v)
		end
	end
	return chests
end, "ESP_Chest", Color3.fromRGB(255, 215, 0), "ESPChests")

Tabs.Status:CreateToggle({
	Name = "ESP Devil Fruits",
	CurrentValue = false,
	Flag = "ESPFruits",
	Callback = function(Value)
		getgenv().ESPFruits = Value
	end,
})
HandleESP(function()
	local fruits = {}
	for _, v in ipairs(workspace:GetChildren()) do
		if string.find(v.Name, "Fruit") and v:IsA("Tool") then
			table.insert(fruits, v)
		end
	end
	return fruits
end, "ESP_Fruit", Color3.fromRGB(255, 0, 100), "ESPFruits")

task.spawn(function()
	while ScriptContext.Running do
		pcall(function()
			local Net = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
				and game:GetService("ReplicatedStorage").Modules:FindFirstChild("Net")
			local hintRemote = Net and Net:FindFirstChild("RF/RequestNextRaidHint")

			if hintRemote then
				local res = hintRemote:InvokeServer()
				if res and type(res) == "table" and res.Boss then
					local bossName = tostring(res.Boss)
					local islandName = tostring(res.Island or "Unknown")
					local state = tostring(res.State or "Unknown")
					local seconds = tonumber(res.Seconds) or 0
					local mins = math.floor(seconds / 60)
					local secs = seconds % 60
					local timeStr = string.format("%02d:%02d", mins, secs)

					local bText = string.format("%s (%s) [%s - %s]", bossName, islandName, state, timeStr)
					getgenv().lastAwakenedBossText = bText
				else
					getgenv().lastAwakenedBossText = "None / Inactive"
				end
			end
		end)
		task.wait(0.2)
	end
end)

Tabs.Status:CreateSection("Debug Information")
isDebugActive = false
debugWorker = 0

Tabs.Misc:CreateSection("Devil Fruit Stock Viewer")

StockSplit = Tabs.Misc:CreateSplitView({ Columns = 2, Spacing = 10 })
NormalCol = StockSplit.Columns[1]
AdvancedCol = StockSplit.Columns[2]

NormalCol:CreateLabel("Waiting for refresh...")
AdvancedCol:CreateLabel("Waiting for refresh...")

Tabs.Misc:CreateButton({
	Name = "Refresh All Stock",
	Callback = function()
		local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
			and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
		if not Event then
			return
		end

		local function formatPrice(n)
			local formatted = tostring(n)
			while true do
				local k
				formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
				if k == 0 then
					break
				end
			end
			return formatted
		end

		local function getRarityColor(rarity)
			local raritys = {
				[0] = {
					Name = "Common",
					Color = Color3.fromRGB(255, 255, 255),
				},
				[1] = {
					Name = "Rare",
					Color = Color3.fromRGB(0, 255, 255),
				},
				[2] = {
					Name = "Epic",
					Color = Color3.fromRGB(0, 140, 255),
				},
				[3] = {
					Name = "Legendary",
					Color = Color3.fromRGB(255, 140, 0),
				},
				[4] = {
					Name = "Mythical",
					Color = Color3.fromRGB(139, 0, 255),
				},
				[5] = {
					Name = "Premium",
					Color = Color3.fromRGB(255, 0, 255),
				},
			}

			return raritys[rarity] or "Unknown", Color3.fromRGB(255, 255, 255)
		end

		local function cleanFruitName(name)
			return string.match(name, "^([^-]+)") or name
		end

		local function populateColumn(column, title, isAdvanced)
			for _, child in ipairs(column.Frame:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextLabel") then
					child:Destroy()
				end
			end

			local result = nil
			pcall(function()
				result = Event:InvokeServer("GetFruits", isAdvanced)
			end)

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Size = UDim2.new(1, 0, 0, 20)
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Text = title
			TitleLabel.TextColor3 = Color3.fromRGB(85, 120, 255)
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.TextSize = 13
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
			TitleLabel.Parent = column.Frame

			local count = 0
			if type(result) == "table" then
				for _, fruit in ipairs(result) do
					if fruit.OnSale == true then
						count = count + 1
						local rarity = getRarityColor(fruit.Rarity)
						column:CreateCard({
							Title = cleanFruitName(fruit.Name),
							Content = string.format(
								"Price: $%s\nRarity: %s",
								formatPrice(fruit.Price),
								tostring(rarity.Name)
							),
						})
					end
				end
			end

			if count == 0 then
				column:CreateLabel("No stock available.")
			end
		end

		populateColumn(NormalCol, "NORMAL STOCK", false)
		populateColumn(AdvancedCol, "ADVANCED STOCK", true)
	end,
})

Tabs.Shop:CreateSection("Stats & Race Management")
Tabs.Shop:CreateButton({
	Name = "Reset Stats (2500F)",
	Callback = function()
		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BlackbeardReward", "Refund", "2")
		end)
	end,
})
Tabs.Shop:CreateButton({
	Name = "Random Race (3000F)",
	Callback = function()
		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BlackbeardReward", "Reroll", "2")
		end)
	end,
})
Tabs.Shop:CreateButton({
	Name = "Change Race Cyborg",
	Callback = function()
		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("CyborgTrainer", "Buy")
		end)
	end,
})
Tabs.Shop:CreateButton({
	Name = "Change Race Ghoul",
	Callback = function()
		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("GhoulQuest", "Buy")
		end)
	end,
})

Tabs.Misc:CreateSection("Auto Fruit Sniping & Gacha")
Tabs.Misc:CreateToggle({
	Name = "Auto Store Fruits",
	CurrentValue = false,
	Flag = "AutoStoreFruit",
	Callback = function(Value)
		getgenv().AutoStoreFruit = Value
		task.spawn(function()
			while getgenv().AutoStoreFruit do
				task.wait(1)
				pcall(function()
					local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
						and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
					if CommF_ then
						local bag = player:FindFirstChildOfClass("Backpack")
						local char = player.Character
						local tools = {}
						if bag then
							for _, v in ipairs(bag:GetChildren()) do
								table.insert(tools, v)
							end
						end
						if char then
							for _, v in ipairs(char:GetChildren()) do
								table.insert(tools, v)
							end
						end

						for _, t in ipairs(tools) do
							if t:IsA("Tool") and (string.find(t.Name, "Fruit") or t.ToolTip == "Blox Fruit") then
								CommF_:InvokeServer("StoreFruit", t:GetAttribute("OriginalName") or t.Name, t)
							end
						end
					end
				end)
			end
		end)
	end,
})

Tabs.Misc:CreateToggle({
	Name = "Auto Random Fruit (Gacha)",
	CurrentValue = false,
	Flag = "AutoGacha",
	Callback = function(Value)
		getgenv().AutoGacha = Value
		task.spawn(function()
			local Net = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net")
			local gachaRemote = Net:WaitForChild("RF/GachaNetworkRF")

			while getgenv().AutoGacha do
				task.wait(5)
				pcall(function()
					local check = gachaRemote:InvokeServer({
						Context = "Check",
						BoxName = "ZiolesGacha",
					})

					if check and check.RequirementsMet ~= false then
						gachaRemote:InvokeServer({
							Context = "Purchase",
							BoxName = "ZiolesGacha",
						})
					end
				end)
			end
		end)
	end,
})

Tabs.Misc:CreateSection("Server & Environment")
Tabs.Misc:CreateButton({
	Name = "Join Pirates Team",
	Callback = function()
		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
		end)
	end,
})
Tabs.Misc:CreateButton({
	Name = "Join Marines Team",
	Callback = function()
		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SetTeam", "Marines")
		end)
	end,
})
Tabs.Misc:CreateButton({
	Name = "Delete Lava",
	Callback = function()
		for _, v in pairs(workspace:GetDescendants()) do
			if v.Name == "Lava" then
				pcall(function()
					v:Destroy()
				end)
			end
		end
	end,
})
Tabs.Misc:CreateButton({
	Name = "Open Title Name Menu",
	Callback = function()
		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TitleNPC")
		end)
	end,
})

Tabs.Travel:CreateSection("Sea Teleportation (Hop)")
Tabs.Travel:CreateButton({
	Name = "Teleport to Sea 1",
	Callback = function()
		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelMain")
		end)
	end,
})
Tabs.Travel:CreateButton({
	Name = "Teleport to Sea 2",
	Callback = function()
		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelDressrosa")
		end)
	end,
})
Tabs.Travel:CreateButton({
	Name = "Teleport to Sea 3",
	Callback = function()
		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelZou")
		end)
	end,
})

Tabs.Misc:CreateSection("Devil Fruit Gacha")
Tabs.Misc:CreateButton({
	Name = "Spin Fruit (Cousin)",
	Callback = function()
		ScriptContext:SpinFruitCousin()
	end,
})
DebugHUD = Lonum:CreateFloatingHUD({ Title = "Script Status" })
DebugHUD:SetVisible(false)

getgenv().HUD_Config = getgenv().HUD_Config
	or {
		ShowTask = true,
		ShowMoon = true,
		ShowBlueMoon = true,
		ShowCakePrince = true,
		ShowAwakenedBoss = true,
	}

Tabs.Status:CreateToggle({
	Name = "Show Debug Floating HUD",
	CurrentValue = false,
	Flag = "ToggleShowDebugHUD",
	Callback = function(Value)
		DebugHUD:SetVisible(Value)
		if Value then
			isDebugActive = true
			debugWorker = debugWorker + 1
			local gen = debugWorker

			task.spawn(function()
				local lastCakeCheck = 0
				local lastCakeStatus = "Checking..."
				local commF = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
					and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")

				while isDebugActive and ScriptContext.Running and gen == debugWorker do
					local phaseNum = Lighting:GetAttribute("MoonPhase") or 0
					local isBlueMoon = Lighting:GetAttribute("IsBlueMoon") or false

					local phaseName = MoonPhases[phaseNum] or (tostring(phaseNum) .. " (Unknown)")
					local blueMoonStatus = isBlueMoon and "✅ Active" or "❌ Inactive"

					if os.clock() - lastCakeCheck > 1 then
						lastCakeCheck = os.clock()
						if commF then
							pcall(function()
								local status = getDripMamaStatus()
								if status == "ready" then
									lastCakeStatus = "✅ Ready"
								elseif status == "spawned" then
									lastCakeStatus = "✅ Spawned"
								elseif status == "unknown" then
									lastCakeStatus = "Unknown"
								else
									local left = tonumber(string.match(status, "(%d+) left"))
									lastCakeStatus = tostring(left) .. " left"
								end
							end)
						end
					end

					local currentTask = GetCurrentScriptTask()

					local hudLines = {}
					if getgenv().HUD_Config.ShowTask then
						table.insert(hudLines, "Script Task: " .. tostring(currentTask))
					end
					if getgenv().HUD_Config.ShowMoon then
						table.insert(hudLines, "Moon Phase: " .. tostring(phaseName))
					end
					if getgenv().HUD_Config.ShowBlueMoon then
						table.insert(hudLines, "Blue Moon: " .. tostring(blueMoonStatus))
					end
					if getgenv().HUD_Config.ShowCakePrince then
						table.insert(hudLines, "Cake Prince: " .. tostring(lastCakeStatus))
					end
					if getgenv().HUD_Config.ShowAwakenedBoss then
						table.insert(hudLines, "Awakened Boss: " .. tostring(getgenv().lastAwakenedBossText or "Checking..."))
					end

					DebugHUD:UpdateText(table.concat(hudLines, "\n"))
					task.wait(0.2)
				end
			end)
		else
			isDebugActive = false
			debugWorker = debugWorker + 1
		end
	end,
})

Tabs.Status:CreateSection("HUD Elements Config")
Tabs.Status:CreateToggle({
	Name = "HUD: Script Task",
	CurrentValue = true,
	Flag = "HUD_ShowTask",
	Callback = function(v)
		getgenv().HUD_Config.ShowTask = v
	end,
})
Tabs.Status:CreateToggle({
	Name = "HUD: Moon Phase",
	CurrentValue = true,
	Flag = "HUD_ShowMoon",
	Callback = function(v)
		getgenv().HUD_Config.ShowMoon = v
	end,
})
Tabs.Status:CreateToggle({
	Name = "HUD: Blue Moon",
	CurrentValue = true,
	Flag = "HUD_ShowBlueMoon",
	Callback = function(v)
		getgenv().HUD_Config.ShowBlueMoon = v
	end,
})
Tabs.Status:CreateToggle({
	Name = "HUD: Cake Prince",
	CurrentValue = true,
	Flag = "HUD_ShowCakePrince",
	Callback = function(v)
		getgenv().HUD_Config.ShowCakePrince = v
	end,
})
Tabs.Status:CreateToggle({
	Name = "HUD: Next Awakened Boss",
	CurrentValue = true,
	Flag = "HUD_ShowAwakenedBoss",
	Callback = function(v)
		getgenv().HUD_Config.ShowAwakenedBoss = v
	end,
})

Lonum:Notify({
	Title = "Mega Farm Loaded",
	Content = "Script is ready with optimized cross-platform support.",
	Duration = 5,
})

getgenv().LonumObject = Lonum
