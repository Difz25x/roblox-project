--==================================================
-- [ INIT & OVERDRIVE ]
--==================================================
local SCRIPT_ID = "BloxFruits_MegaFarm_Overdrive"

pcall(function()
    local coreGui = gethui and gethui() or game:GetService("CoreGui")
    for _, gui in pairs(coreGui:GetChildren()) do
        if gui.Name == "LonumMainGui" or gui.Name == "LonumFloatingGui" or gui.Name == "LonumNotifGui" or string.match(gui.Name, "Rayfield") then
            gui:Destroy()
        end
    end
end)

if getgenv().LonumObject then
    pcall(function() getgenv().LonumObject = nil end)
end
if getgenv().RayfieldObject then
    pcall(function() getgenv().RayfieldObject:Destroy() end)
    getgenv().RayfieldObject = nil
end

if getgenv and getgenv()[SCRIPT_ID] then
	pcall(function() getgenv()[SCRIPT_ID]:Destroy() end)
end

local ScriptContext = {
	Connections = {},
	Instances = {},
	Running = true,
}

function ScriptContext:AddConnection(conn)
	table.insert(self.Connections, conn)
	return conn
end

function ScriptContext:Destroy()
	self.Running = false
	for _, conn in ipairs(self.Connections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(self.Connections)

	pcall(function()
	    -- Cancel all active tweens
	    if activeTween then
	        activeTween:Cancel()
	        activeTween = nil
	    end
		local c = game:GetService("Players").LocalPlayer.Character
		if c and c:FindFirstChild("HumanoidRootPart") then
			local bv = c.HumanoidRootPart:FindFirstChild("AutofarmBv")
			if bv then bv:Destroy() end
			local bg = c.HumanoidRootPart:FindFirstChild("AutofarmBg")
			if bg then bg:Destroy() end
		end
	end)
end

if getgenv then getgenv()[SCRIPT_ID] = ScriptContext end

--==================================================
-- [ SERVICES & CONFIG ]
--==================================================
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

local hasFireTouch = type(firetouchinterest) == "function"
local hasProximity = type(fireproximityprompt) == "function"

local player = Players.LocalPlayer

pcall(function()
    if getconnections then
        for _, conn in pairs(getconnections(player.Idled)) do
            if conn.Disable then conn:Disable() end
            if conn.Disconnect then conn:Disconnect() end
        end
    end
end)

ScriptContext:AddConnection(player.Idled:Connect(function()
    if ScriptContext.Running then
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                cam.CFrame = cam.CFrame * CFrame.Angles(0, 0.01, 0)
                task.wait(0.1)
                cam.CFrame = cam.CFrame * CFrame.Angles(0, -0.01, 0)
            end
        end)
    end
end))

pcall(function()
	if getconnections then
		for _, conn in pairs(getconnections(player.Idled)) do
			if conn.Disable then conn:Disable() end
			if conn.Disconnect then conn:Disconnect() end
		end
	end
end)

-- Main Config (Merged)
local cfg = {
	WeaponCategory = "Melee",

	AutoMastery = false,
	MasteryCategory = "Melee",
	MasteryHealth = 30,

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
	ThreadSleep = 0.025,

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
	dodgeCooldown = 1
}

local attackSpeedMode = "Fast Attack"
local isMultiMobDamage = false
local isAutoRaidKill = false
local isAutoRaidAttack = false
local isAutoRaidBring = false
local isAutoRaidNextIsland = false
local isAutoDungeon = false
local isAutoDungeonAttack = false
local isAutoDungeonBring = false
local isAutoDungeonNext = false
local dungeonWorkerGeneration = 10
local isAutoNextIsland = false
local currentRaidIsland = 1
local isAutoBone = false
local isAutoSpinBones = false
local isAutoCocoa = false

-- State Variables
local enabled = false
local isAutoAttackEnabled = false
local isAutoStatsEnabled = false
local isCollectingChest = false
local isAutoKenEnabled = false
local selectedStatCategory = "Melee"
local bypassRender = false

local isReadyToAttack = false

local activeTween = nil
local lastTargetPos = nil
local currentEvasionOffset = Vector3.new(0, cfg.TweenHeight, 0)
local lastEvasionTime = 0
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

local isBossHunterEnabled = false
local selectedBossName = nil
local farmNearestEnabled = false
local farmNearestRadius = 5000

-- Sea Event Variables
local lastDodgeTime = 0
local currentBoat = nil
local currentIsland = nil
local fruitWaypoints = {}
local chestWaypoints = {}
local autoKillVolcano = false
local AutoEmber = false

local CommF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local CommE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE")

local RegisterHitEvent, RegisterAttackEvent
pcall(function()
	local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
	RegisterHitEvent = Net:WaitForChild("RE/RegisterHit")
	RegisterAttackEvent = Net:WaitForChild("RE/RegisterAttack")
end)

local sessionSecret = nil
task.defer(function()
	sessionSecret = tostring(player.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15)
	if RegisterHitEvent then pcall(function() RegisterHitEvent:FireServer(sessionSecret) end) end
end)

--==================================================
-- [ DATABASES ]
--==================================================

local BOSSES = {
	{ Sea = 1, Min = 20, Name = "Gorilla King", Quest = "JungleQuest", Stage = 3, NPC = Vector3.new(-1598, 36, 153) },
	{ Sea = 1, Min = 55, Name = "Chef", Quest = "BuggyQuest1", Stage = 3, NPC = Vector3.new(-1141, 13, 3827) },
	{ Sea = 1, Min = 105, Name = "Yeti", Quest = "SnowQuest", Stage = 3, NPC = Vector3.new(1389, 87, -1298) },
	{ Sea = 1, Min = 130, Name = "Vice Admiral", Quest = "MarineQuest2", Stage = 2, NPC = Vector3.new(-5035, 20, 4324) },
	{ Sea = 1, Min = 220, Name = "Warden", Quest = "ImpelQuest", Stage = 1, NPC = Vector3.new(3873, 14, -1940) },
	{ Sea = 1, Min = 230, Name = "Chief Warden", Quest = "ImpelQuest", Stage = 2, NPC = Vector3.new(3873, 14, -1940) },
	{ Sea = 1, Min = 240, Name = "Swan", Quest = "ImpelQuest", Stage = 3, NPC = Vector3.new(3873, 14, -1940) },
	{ Sea = 1, Min = 350, Name = "Magma Admiral", Quest = "MagmaQuest", Stage = 3, NPC = Vector3.new(-5701, 17, 8722) },
	{ Sea = 1, Min = 425, Name = "Fishman Lord", Quest = "FishmanQuest", Stage = 3, NPC = Vector3.new(6112, 19, 1567) },
	{ Sea = 1, Min = 500, Name = "Wysper", Quest = "SkyExp1Quest", Stage = 3, NPC = Vector3.new(-7862, 5545, -381) },
	{ Sea = 1, Min = 575, Name = "Thunder God", Quest = "SkyExp2Quest", Stage = 3, NPC = Vector3.new(-7749, 5607, -2317) },
	{ Sea = 1, Min = 675, Name = "Cyborg", Quest = "FountainQuest", Stage = 3, NPC = Vector3.new(5247, 38, 4067) },
	{ Sea = 2, Min = 750, Name = "Diamond", Quest = "Area1Quest", Stage = 3, NPC = Vector3.new(-429, 72, 1836) },
	{ Sea = 2, Min = 850, Name = "Jeremy", Quest = "Area2Quest", Stage = 3, NPC = Vector3.new(638, 73, 918) },
	{ Sea = 2, Min = 925, Name = "Orbitus", Quest = "MarineQuest3", Stage = 3, NPC = Vector3.new(-2441, 73, -3219) },
	{ Sea = 2, Min = 1150, Name = "Smoke Admiral", Quest = "IceSideQuest", Stage = 3, NPC = Vector3.new(-6061, 16, -4905) },
	{ Sea = 2, Min = 1400, Name = "Awakened Ice Admiral", Quest = "FrostQuest", Stage = 3, NPC = Vector3.new(5668, 28, -6484) },
	{ Sea = 2, Min = 1475, Name = "Tide Keeper", Quest = "ForgottenQuest", Stage = 3, NPC = Vector3.new(-3054, 237, -10148) },
	{ Sea = 3, Min = 1550, Name = "Stone", Quest = "PiratePortQuest", Stage = 3, NPC = Vector3.new(-448.99, 108.63, 5948.77) },
	{ Sea = 3, Min = 1675, Name = "Hydra Leader", Quest = "VenomCrewQuest", Stage = 3, NPC = Vector3.new(5214.16, 1004.13, 756.39) },
	{ Sea = 3, Min = 1750, Name = "Kilo Admiral", Quest = "MarineTreeIsland", Stage = 3, NPC = Vector3.new(2484.00, 74.29, -6787.78) },
	{ Sea = 3, Min = 1875, Name = "Captain Elephant", Quest = "DeepForestIsland", Stage = 3, NPC = Vector3.new(-13232, 332, -7625) },
	{ Sea = 3, Min = 1950, Name = "Beautiful Pirate", Quest = "DeepForestIsland2", Stage = 3, NPC = Vector3.new(-11939, 277, -8814) },
	{ Sea = 3, Min = 2175, Name = "Cake Queen", Quest = "IceCreamIslandQuest", Stage = 3, NPC = Vector3.new(-820, 66, -10966) },
}

local SEA1 = {
	{ Min = 1, Max = 9, Quest = "BanditQuest1", Stage = 1, Name = "Bandits", Mob = "Bandit", Count = 5, NPC = Vector3.new(1059, 13, 1552), MobPos = Vector3.new(1145, 17, 1634) },
	{ Min = 10, Max = 14, Quest = "JungleQuest", Stage = 1, Name = "Monkeys", Mob = "Monkey", Count = 6, NPC = Vector3.new(-1602, 37, 153), MobPos = Vector3.new(-1448, 50, 64) },
	{ Min = 15, Max = 29, Quest = "JungleQuest", Stage = 2, Name = "Gorillas", Mob = "Gorilla", Count = 8, NPC = Vector3.new(-1602, 37, 153), MobPos = Vector3.new(-1237, 7, -486) },
	{ Min = 30, Max = 39, Quest = "BuggyQuest1", Stage = 1, Name = "Pirates", Mob = "Pirate", Count = 8, NPC = Vector3.new(-1140, 5, 3828), MobPos = Vector3.new(-1115, 14, 3938) },
	{ Min = 40, Max = 59, Quest = "BuggyQuest1", Stage = 2, Name = "Brute", Mob = "Brute", Count = 8, NPC = Vector3.new(-1140, 5, 3828), MobPos = Vector3.new(-1145, 15, 4350) },
	{ Min = 60, Max = 74, Quest = "DesertQuest", Stage = 1, Name = "Desert Bandits", Mob = "Desert Bandit", Count = 8, NPC = Vector3.new(897, 7, 4389), MobPos = Vector3.new(932, 7, 4484) },
	{ Min = 75, Max = 89, Quest = "DesertQuest", Stage = 2, Name = "Desert Officers", Mob = "Desert Officer", Count = 6, NPC = Vector3.new(897, 7, 4389), MobPos = Vector3.new(1572, 11, 4386) },
	{ Min = 90, Max = 99, Quest = "SnowQuest", Stage = 1, Name = "Snow Bandits", Mob = "Snow Bandit", Count = 7, NPC = Vector3.new(1386, 87, -1297), MobPos = Vector3.new(1354, 105, -1328) },
	{ Min = 100, Max = 119, Quest = "SnowQuest", Stage = 2, Name = "Snowmen", Mob = "Snowman", Count = 8, NPC = Vector3.new(1386, 87, -1297), MobPos = Vector3.new(1218, 139, -1488) },
	{ Min = 120, Max = 149, Quest = "MarineQuest2", Stage = 1, Name = "Chief Petty Officers", Mob = "Chief Petty Officer", Count = 8, NPC = Vector3.new(-5035, 29, 4324), MobPos = Vector3.new(-4882, 23, 4273) },
	{ Min = 150, Max = 174, Quest = "SkyQuest", Stage = 1, Name = "Sky Bandits", Mob = "Sky Bandit", Count = 7, NPC = Vector3.new(-4842, 718, -2623), MobPos = Vector3.new(-4953, 295, -2899) },
	{ Min = 175, Max = 189, Quest = "SkyQuest", Stage = 2, Name = "Dark Masters", Mob = "Dark Master", Count = 8, NPC = Vector3.new(-4842, 718, -2623), MobPos = Vector3.new(-5259, 391, -2229) },
	{ Min = 190, Max = 209, Quest = "PrisonerQuest", Stage = 1, Name = "Prisoners", Mob = "Prisoner", Count = 8, NPC = Vector3.new(5308, 2, 475), MobPos = Vector3.new(5099, 1, 474) },
	{ Min = 210, Max = 249, Quest = "PrisonerQuest", Stage = 2, Name = "Dangerous Prisoners", Mob = "Dangerous Prisoner", Count = 8, NPC = Vector3.new(5308, 2, 475), MobPos = Vector3.new(5654, 15, 866) },
	{ Min = 250, Max = 274, Quest = "ColosseumQuest", Stage = 1, Name = "Toga Warriors", Mob = "Toga Warrior", Count = 7, NPC = Vector3.new(-1580, 7, -2986), MobPos = Vector3.new(-1779, 45, -2741) },
	{ Min = 275, Max = 299, Quest = "ColosseumQuest", Stage = 2, Name = "Gladiators", Mob = "Gladiator", Count = 8, NPC = Vector3.new(-1580, 7, -2986), MobPos = Vector3.new(-1274, 58, -3188) },
	{ Min = 300, Max = 324, Quest = "MagmaQuest", Stage = 1, Name = "Military Soldiers", Mob = "Military Soldier", Count = 7, NPC = Vector3.new(-5316, 12, 8517), MobPos = Vector3.new(-5411, 11, 8454) },
	{ Min = 325, Max = 374, Quest = "MagmaQuest", Stage = 2, Name = "Military Spies", Mob = "Military Spy", Count = 8, NPC = Vector3.new(-5316, 12, 8517), MobPos = Vector3.new(-5802, 86, 8829) },
	{ Min = 375, Max = 399, Quest = "FishmanQuest", Stage = 1, Name = "Fishman Warriors", Mob = "Fishman Warrior", Count = 8, NPC = Vector3.new(6112, 19, 1567), MobPos = Vector3.new(60878, 19, 1543) },
	{ Min = 400, Max = 449, Quest = "FishmanQuest", Stage = 2, Name = "Fishman Commandos", Mob = "Fishman Commando", Count = 7, NPC = Vector3.new(6112, 19, 1567), MobPos = Vector3.new(61891, 19, 1470) },
	{ Min = 450, Max = 474, Quest = "SkyExp1Quest", Stage = 1, Name = "God's Guards", Mob = "God's Guard", Count = 7, NPC = Vector3.new(-4722, 846, -1954), MobPos = Vector3.new(-4710, 845, -1927) },
	{ Min = 475, Max = 524, Quest = "SkyExp1Quest", Stage = 2, Name = "Shandas", Mob = "Shanda", Count = 9, NPC = Vector3.new(-7862, 5546, -380), MobPos = Vector3.new(-7685, 5601, -441) },
	{ Min = 525, Max = 549, Quest = "SkyExp2Quest", Stage = 1, Name = "Royal Squads", Mob = "Royal Squad", Count = 8, NPC = Vector3.new(-7904, 5635, -1412), MobPos = Vector3.new(-7685, 5606, -1442) },
	{ Min = 550, Max = 624, Quest = "SkyExp2Quest", Stage = 2, Name = "Royal Soldiers", Mob = "Royal Soldier", Count = 8, NPC = Vector3.new(-7904, 5635, -1412), MobPos = Vector3.new(-7864, 5661, -1708) },
	{ Min = 625, Max = 649, Quest = "FountainQuest", Stage = 1, Name = "Galley Pirates", Mob = "Galley Pirate", Count = 8, NPC = Vector3.new(5259, 39, 4050), MobPos = Vector3.new(5558, 39, 3998) },
	{ Min = 650, Max = 700, Quest = "FountainQuest", Stage = 2, Name = "Galley Captains", Mob = "Galley Captain", Count = 9, NPC = Vector3.new(5259, 39, 4050), MobPos = Vector3.new(5677, 93, 4967) },
}

local SEA2 = {
	{ Min = 700, Max = 724, Quest = "Area1Quest", Stage = 1, Name = "Raiders", Mob = "Raider", Count = 8, NPC = Vector3.new(-429, 72, 1836), MobPos = Vector3.new(-737, 39, 2385) },
	{ Min = 725, Max = 774, Quest = "Area1Quest", Stage = 2, Name = "Mercenaries", Mob = "Mercenary", Count = 8, NPC = Vector3.new(-429, 72, 1836), MobPos = Vector3.new(-972, 73, 1419) },
	{ Min = 775, Max = 799, Quest = "Area2Quest", Stage = 1, Name = "Swan Pirates", Mob = "Swan Pirate", Count = 8, NPC = Vector3.new(638, 73, 918), MobPos = Vector3.new(970, 142, 1217) },
	{ Min = 800, Max = 874, Quest = "Area2Quest", Stage = 2, Name = "Factory Staff", Mob = "Factory Staff", Count = 8, NPC = Vector3.new(638, 73, 918), MobPos = Vector3.new(296, 73, -56) },
	{ Min = 875, Max = 899, Quest = "MarineQuest3", Stage = 1, Name = "Marine Lieutenants", Mob = "Marine Lieutenant", Count = 8, NPC = Vector3.new(-2441, 73, -3219), MobPos = Vector3.new(-2821, 73, -3070) },
	{ Min = 900, Max = 949, Quest = "MarineQuest3", Stage = 2, Name = "Marine Captains", Mob = "Marine Captain", Count = 9, NPC = Vector3.new(-2441, 73, -3219), MobPos = Vector3.new(-1867, 73, -3321) },
	{ Min = 950, Max = 974, Quest = "ZombieQuest", Stage = 1, Name = "Zombies", Mob = "Zombie", Count = 8, NPC = Vector3.new(-5497, 48, -795), MobPos = Vector3.new(-5736, 126, -728) },
	{ Min = 975, Max = 999, Quest = "ZombieQuest", Stage = 2, Name = "Vampires", Mob = "Vampire", Count = 8, NPC = Vector3.new(-5497, 48, -795), MobPos = Vector3.new(-6033, 7, -1317) },
	{ Min = 1000, Max = 1049, Quest = "SnowMountainQuest", Stage = 1, Name = "Snow Troopers", Mob = "Snow Trooper", Count = 8, NPC = Vector3.new(609, 401, -5372), MobPos = Vector3.new(535, 432, -5484) },
	{ Min = 1050, Max = 1099, Quest = "SnowMountainQuest", Stage = 2, Name = "Winter Warriors", Mob = "Winter Warrior", Count = 9, NPC = Vector3.new(609, 401, -5372), MobPos = Vector3.new(1234, 456, -5174) },
	{ Min = 1100, Max = 1124, Quest = "IceSideQuest", Stage = 1, Name = "Lab Subordinates", Mob = "Lab Subordinate", Count = 8, NPC = Vector3.new(-6061, 16, -4905), MobPos = Vector3.new(-5720, 63, -4784) },
	{ Min = 1125, Max = 1174, Quest = "IceSideQuest", Stage = 2, Name = "Horned Warriors", Mob = "Horned Warrior", Count = 9, NPC = Vector3.new(-6061, 16, -4905), MobPos = Vector3.new(-6292, 91, -5503) },
	{ Min = 1175, Max = 1199, Quest = "FireSideQuest", Stage = 1, Name = "Magma Ninjas", Mob = "Magma Ninja", Count = 8, NPC = Vector3.new(-5429, 16, -5297), MobPos = Vector3.new(-5461, 130, -5836) },
	{ Min = 1200, Max = 1249, Quest = "FireSideQuest", Stage = 2, Name = "Lava Pirates", Mob = "Lava Pirate", Count = 8, NPC = Vector3.new(-5429, 16, -5297), MobPos = Vector3.new(-5251, 55, -4774) },
	{ Min = 1250, Max = 1274, Quest = "ShipQuest1", Stage = 1, Name = "Ship Deckhands", Mob = "Ship Deckhand", Count = 8, NPC = Vector3.new(1038, 125, 32911), MobPos = Vector3.new(1212, 126, 33059) },
	{ Min = 1275, Max = 1299, Quest = "ShipQuest1", Stage = 2, Name = "Ship Engineers", Mob = "Ship Engineer", Count = 8, NPC = Vector3.new(1038, 125, 32911), MobPos = Vector3.new(919, 44, 32779) },
	{ Min = 1300, Max = 1324, Quest = "ShipQuest2", Stage = 1, Name = "Ship Stewards", Mob = "Ship Steward", Count = 8, NPC = Vector3.new(969, 125, 33245), MobPos = Vector3.new(919, 130, 33419) },
	{ Min = 1325, Max = 1349, Quest = "ShipQuest2", Stage = 2, Name = "Ship Officers", Mob = "Ship Officer", Count = 8, NPC = Vector3.new(969, 125, 33245), MobPos = Vector3.new(1037, 181, 33316) },
	{ Min = 1350, Max = 1374, Quest = "FrostQuest", Stage = 1, Name = "Arctic Warriors", Mob = "Arctic Warrior", Count = 8, NPC = Vector3.new(5668, 28, -6484), MobPos = Vector3.new(5966, 58, -6179) },
	{ Min = 1375, Max = 1424, Quest = "FrostQuest", Stage = 2, Name = "Snow Lurkers", Mob = "Snow Lurker", Count = 8, NPC = Vector3.new(5668, 28, -6484), MobPos = Vector3.new(5407, 69, -6880) },
	{ Min = 1425, Max = 1449, Quest = "ForgottenQuest", Stage = 1, Name = "Sea Soldiers", Mob = "Sea Soldier", Count = 8, NPC = Vector3.new(-3054, 237, -10148), MobPos = Vector3.new(-3028, 65, -9775) },
	{ Min = 1450, Max = 1500, Quest = "ForgottenQuest", Stage = 2, Name = "Water Fighters", Mob = "Water Fighter", Count = 8, NPC = Vector3.new(-3054, 237, -10148), MobPos = Vector3.new(-3262, 298, -10553) },
}

local SEA3 = {
	{ Min = 1500, Max = 1524, Quest = "PiratePortQuest", Stage = 1, Name = "Pirate Millionaires", Mob = "Pirate Millionaire", Count = 8, NPC = Vector3.new(-448.99, 108.63, 5948.77), MobPos = Vector3.new(-435, 190, 5551) },
	{ Min = 1525, Max = 1574, Quest = "PiratePortQuest", Stage = 2, Name = "Pistol Billionaires", Mob = "Pistol Billionaire", Count = 8, NPC = Vector3.new(-448.99, 108.63, 5948.77), MobPos = Vector3.new(-236, 217, 6007) },
	{ Min = 1575, Max = 1599, Quest = "DragonCrewQuest", Stage = 1, Name = "Dragon Crew Warriors", Mob = "Dragon Crew Warrior", Count = 8, NPC = Vector3.new(6737.21, 127.44, -712.48), MobPos = Vector3.new(6834.66, 192.74, -829.06) },
	{ Min = 1600, Max = 1624, Quest = "DragonCrewQuest", Stage = 2, Name = "Dragon Crew Archers", Mob = "Dragon Crew Archer", Count = 8, NPC = Vector3.new(6737.21, 127.44, -712.48), MobPos = Vector3.new(6713.14, 716.12, 631.09) },
	{ Min = 1625, Max = 1649, Quest = "VenomCrewQuest", Stage = 1, Name = "Hydra Enforcers", Mob = "Hydra Enforcer", Count = 8, NPC = Vector3.new(5214.16, 1004.13, 756.39), MobPos = Vector3.new(4570.93, 1026.70, 405.84) },
	{ Min = 1650, Max = 1699, Quest = "VenomCrewQuest", Stage = 2, Name = "Venomous Assailant", Mob = "Venomous Assailant", Count = 8, NPC = Vector3.new(5214.16, 1004.13, 756.39), MobPos = Vector3.new(4778.37, 1474.12, 514.90) },
	{ Min = 1700, Max = 1724, Quest = "MarineTreeIsland", Stage = 1, Name = "Marine Commodores", Mob = "Marine Commodore", Count = 8, NPC = Vector3.new(2484.00, 74.29, -6787.78), MobPos = Vector3.new(2196.70, 284.17, -7413.28) },
	{ Min = 1725, Max = 1774, Quest = "MarineTreeIsland", Stage = 2, Name = "Marine Rear Admirals", Mob = "Marine Rear Admiral", Count = 8, NPC = Vector3.new(2484.00, 74.29, -6787.78), MobPos = Vector3.new(3671, 161, -6932) },
	{ Min = 1775, Max = 1799, Quest = "DeepForestIsland3", Stage = 1, Name = "Fishman Raiders", Mob = "Fishman Raider", Count = 8, NPC = Vector3.new(-10582, 332, -8758), MobPos = Vector3.new(-10407, 332, -8368) },
	{ Min = 1800, Max = 1824, Quest = "DeepForestIsland3", Stage = 2, Name = "Fishman Captains", Mob = "Fishman Captain", Count = 8, NPC = Vector3.new(-10582, 332, -8758), MobPos = Vector3.new(-10993, 352, -9003) },
	{ Min = 1825, Max = 1849, Quest = "DeepForestIsland", Stage = 1, Name = "Forest Pirates", Mob = "Forest Pirate", Count = 8, NPC = Vector3.new(-13232, 333, -7627), MobPos = Vector3.new(-13489, 401, -7770) },
	{ Min = 1850, Max = 1899, Quest = "DeepForestIsland", Stage = 2, Name = "Mythological Pirates", Mob = "Mythological Pirate", Count = 8, NPC = Vector3.new(-13232, 333, -7627), MobPos = Vector3.new(-13508, 583, -6985) },
	{ Min = 1900, Max = 1924, Quest = "DeepForestIsland2", Stage = 1, Name = "Jungle Pirates", Mob = "Jungle Pirate", Count = 8, NPC = Vector3.new(-12684, 391, -9902), MobPos = Vector3.new(-12267, 459, -10277) },
	{ Min = 1925, Max = 1974, Quest = "DeepForestIsland2", Stage = 2, Name = "Musketeer Pirates", Mob = "Musketeer Pirate", Count = 8, NPC = Vector3.new(-12684, 391, -9902), MobPos = Vector3.new(-13291, 392, -9769) },
	{ Min = 1975, Max = 1999, Quest = "HauntedQuest1", Stage = 1, Name = "Reborn Skeletons", Mob = "Reborn Skeleton", Count = 8, NPC = Vector3.new(-9482, 142, 5567), MobPos = Vector3.new(-8760, 183, 6168) },
	{ Min = 2000, Max = 2024, Quest = "HauntedQuest1", Stage = 2, Name = "Living Zombies", Mob = "Living Zombie", Count = 8, NPC = Vector3.new(-9482, 142, 5567), MobPos = Vector3.new(-10144, 139, 5932) },
	{ Min = 2025, Max = 2049, Quest = "HauntedQuest2", Stage = 1, Name = "Demonic Souls", Mob = "Demonic Soul", Count = 8, NPC = Vector3.new(-9515, 172, 6078), MobPos = Vector3.new(-9507, 172, 6158) },
	{ Min = 2050, Max = 2074, Quest = "HauntedQuest2", Stage = 2, Name = "Posessed Mummies", Mob = "Posessed Mummy", Count = 8, NPC = Vector3.new(-9515, 172, 6078), MobPos = Vector3.new(-9582, 6, 6205) },
	{ Min = 2075, Max = 2099, Quest = "NutsIslandQuest", Stage = 1, Name = "Peanut Scouts", Mob = "Peanut Scout", Count = 8, NPC = Vector3.new(-2104, 38, -10192), MobPos = Vector3.new(-2150, 122, -10358) },
	{ Min = 2100, Max = 2124, Quest = "NutsIslandQuest", Stage = 2, Name = "Peanut Presidents", Mob = "Peanut President", Count = 8, NPC = Vector3.new(-2104, 38, -10192), MobPos = Vector3.new(-2150, 123, -10536) },
	{ Min = 2125, Max = 2149, Quest = "IceCreamIslandQuest", Stage = 1, Name = "Ice Cream Chefs", Mob = "Ice Cream Chef", Count = 8, NPC = Vector3.new(-820, 66, -10966), MobPos = Vector3.new(-848.671204, 65.882126, -10914.947266) },
	{ Min = 2150, Max = 2199, Quest = "IceCreamIslandQuest", Stage = 2, Name = "Ice Cream Commanders", Mob = "Ice Cream Commander", Count = 8, NPC = Vector3.new(-820, 66, -10966), MobPos = Vector3.new(-610.750732, 208.282623, -11254.516602) },
	{ Min = 2200, Max = 2224, Quest = "CakeQuest1", Stage = 1, Name = "Cookie Crafters", Mob = "Cookie Crafter", Count = 8, NPC = Vector3.new(-2021, 38, -12028), MobPos = Vector3.new(-2374, 38, -12125) },
	{ Min = 2225, Max = 2249, Quest = "CakeQuest1", Stage = 2, Name = "Cake Guards", Mob = "Cake Guard", Count = 8, NPC = Vector3.new(-2021, 38, -12028), MobPos = Vector3.new(-1598, 44, -12244) },
	{ Min = 2250, Max = 2274, Quest = "CakeQuest2", Stage = 1, Name = "Baking Staff", Mob = "Baking Staff", Count = 8, NPC = Vector3.new(-1927, 38, -12842), MobPos = Vector3.new(-1887, 78, -12998) },
	{ Min = 2275, Max = 2299, Quest = "CakeQuest2", Stage = 2, Name = "Head Bakers", Mob = "Head Baker", Count = 8, NPC = Vector3.new(-1927, 38, -12842), MobPos = Vector3.new(-2216, 82, -12869) },
	{ Min = 2300, Max = 2324, Quest = "ChocQuest1", Stage = 1, Name = "Cocoa Warriors", Mob = "Cocoa Warrior", Count = 8, NPC = Vector3.new(233, 30, -12201), MobPos = Vector3.new(31.493752, 24.796925, -12246.680664) },
	{ Min = 2325, Max = 2349, Quest = "ChocQuest1", Stage = 2, Name = "Chocolate Bar Battlers", Mob = "Chocolate Bar Battler", Count = 8, NPC = Vector3.new(233, 30, -12201), MobPos = Vector3.new(683.419617, 24.796822, -12576.225586) },
	{ Min = 2350, Max = 2374, Quest = "ChocQuest2", Stage = 1, Name = "Sweet Thieves", Mob = "Sweet Thief", Count = 8, NPC = Vector3.new(151, 30, -12774), MobPos = Vector3.new(165, 77, -12600) },
	{ Min = 2375, Max = 2399, Quest = "ChocQuest2", Stage = 2, Name = "Candy Rebels", Mob = "Candy Rebel", Count = 8, NPC = Vector3.new(151, 30, -12774), MobPos = Vector3.new(83.6653671, 93.5021515, -12963.4072) },
	{ Min = 2400, Max = 2424, Quest = "CandyQuest1", Stage = 1, Name = "Candy Pirates", Mob = "Candy Pirate", Count = 8, NPC = Vector3.new(-1149, 13, -14446), MobPos = Vector3.new(-1347, 13, -14585) },
	{ Min = 2425, Max = 2449, Quest = "CandyQuest1", Stage = 2, Name = "Snow Demons", Mob = "Snow Demon", Count = 8, NPC = Vector3.new(-1149, 13, -14446), MobPos = Vector3.new(-954, 55, -14558) },
	{ Min = 2450, Max = 2474, Quest = "TikiQuest1", Stage = 1, Name = "Isle Outlaws", Mob = "Isle Outlaw", Count = 8, NPC = Vector3.new(-16546, 55, -172), MobPos = Vector3.new(-16101, 55, -155) },
	{ Min = 2475, Max = 2499, Quest = "TikiQuest1", Stage = 2, Name = "Island Boys", Mob = "Island Boy", Count = 8, NPC = Vector3.new(-16546, 55, -172), MobPos = Vector3.new(-16731, 55, -257) },
	{ Min = 2500, Max = 2524, Quest = "TikiQuest2", Stage = 1, Name = "Sun-kissed Warriors", Mob = "Sun-kissed Warrior", Count = 8, NPC = Vector3.new(-16539, 55, 1051), MobPos = Vector3.new(-16349, 55, 1005) },
	{ Min = 2525, Max = 2549, Quest = "TikiQuest2", Stage = 2, Name = "Isle Champions", Mob = "Isle Champion", Count = 8, NPC = Vector3.new(-16539, 55, 1051), MobPos = Vector3.new(-16847, 55, 1002) },
	{ Min = 2550, Max = 2574, Quest = "TikiQuest3", Stage = 1, Name = "Serpent Hunter", Mob = "Serpent Hunter", Count = 8, NPC = Vector3.new(-16663.8633, 105.30751, 1577.3197), MobPos = Vector3.new(-16666.9453, 176.768646, 1491.6416) },
	{ Min = 2575, Max = 2599, Quest = "TikiQuest3", Stage = 2, Name = "Skull Slayer", Mob = "Skull Slayer", Count = 8, NPC = Vector3.new(-16663.8633, 105.30751, 1577.3197), MobPos = Vector3.new(-16666.9453, 176.768646, 1491.6416) },
	{ Min = 2600, Max = 2624, Quest = "SubmergedQuest1", Stage = 1, Name = "Reef Bandit", Mob = "Reef Bandit", Count = 8, NPC = Vector3.new(10780.272461, -2087.699463, 9263.379883), MobPos = Vector3.new(10978.163086, -2023.948853, 9181.994141), TeleportNpc = Vector3.new(-16266.443359, 25.253195, 1374.939331) },
	{ Min = 2625, Max = 2649, Quest = "SubmergedQuest1", Stage = 2, Name = "Coral Pirate", Mob = "Coral Pirate", Count = 8, NPC = Vector3.new(10780.272461, -2087.699463, 9263.379883), MobPos = Vector3.new(10733.620117, -2010.045288, 9343.441406), TeleportNpc = Vector3.new(-16266.443359, 25.253195, 1374.939331) },
	{ Min = 2650, Max = 2674, Quest = "SubmergedQuest2", Stage = 1, Name = "Sea Chanter", Mob = "Sea Chanter", Count = 8, NPC = Vector3.new(10882.310547, -2086.176025, 10030.576172), MobPos = Vector3.new(10623.348633, -2046.116455, 10102.416016), TeleportNpc = Vector3.new(-16266.443359, 25.253195, 1374.939331) },
	{ Min = 2675, Max = 2699, Quest = "SubmergedQuest2", Stage = 2, Name = "Ocean Prophet", Mob = "Ocean Prophet", Count = 8, NPC = Vector3.new(10882.310547, -2086.176025, 10030.576172), MobPos = Vector3.new(11041.423828, -1949.248901, 10147.605469), TeleportNpc = Vector3.new(-16266.443359, 25.253195, 1374.939331) },
	{ Min = 2675, Max = 2699, Quest = "SubmergedQuest3", Stage = 1, Name = "High Disciple", Mob = "High Disciple", Count = 8, NPC = Vector3.new(9637.719727, -1992.420532, 9614.042969), MobPos = Vector3.new(9830.585938, -1941.134888, 9698.757812), TeleportNpc = Vector3.new(-16266.443359, 25.253195, 1374.939331) },
	{ Min = 2700, Max = 2800, Quest = "SubmergedQuest3", Stage = 2, Name = "Grand Devotee", Mob = "Grand Devotee", Count = 8, NPC = Vector3.new(9637.719727, -1992.420532, 9614.042969), MobPos = Vector3.new(9655.575195, -1937.794800, 10078.261719), TeleportNpc = Vector3.new(-16266.443359, 25.253195, 1374.939331) },
}
selectedBossName = BOSSES[1] and BOSSES[1].Name or nil

--==================================================
-- [ UTILITIES ]
--==================================================

local function GetMobProfileByName(mobName)
    if not mobName then return nil end
    local nameLower = string.lower(mobName)

    for _, sea in ipairs({SEA1, SEA2, SEA3}) do
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

local function GetCharacter() return player.Character end
local function GetHumanoid() return GetCharacter() and GetCharacter():FindFirstChildOfClass("Humanoid") end

local function GetPlayerLevel()
	local data = player:FindFirstChild("Data")
	local levelObj = data and data:FindFirstChild("Level")
	return levelObj and levelObj.Value or 1
end

--==================================================
-- [ SUBMERGED & MOVEMENT SYSTEM ]
--==================================================

-- Centralized function for handling teleportation to/from Submerged NPC
local lastSubmergedTeleportAt = 0
local function HandleSubmerged(targetPos)
    local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local isCurrentlySubmerged = (hrp.Position.Y < -1000)
    local isTargetSubmerged = (targetPos.Y < -1000)

    if isCurrentlySubmerged and not isTargetSubmerged then
        local subWorkerSubmerged = Vector3.new(10480.9, -2091, 9363)
        local dist = (hrp.Position - subWorkerSubmerged).Magnitude
        if dist > 35 then
            return "TRAVEL", subWorkerSubmerged
        else
            if os.clock() - lastSubmergedTeleportAt > 5 then
                lastSubmergedTeleportAt = os.clock()
                task.spawn(function()
                    pcall(function()
                        local net = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net")
                        net:WaitForChild("RF/SubmarineWorkerSpeak"):InvokeServer("TravelToTikiOutpost")
                    end)
                end)
            end
            return true
        end
    elseif not isCurrentlySubmerged and isTargetSubmerged then
        local subWorkerTiki = Vector3.new(-16266.4, 25.3, 1374.9)
        local dist = (hrp.Position - subWorkerTiki).Magnitude
        if dist > 35 then
            return "TRAVEL", subWorkerTiki
        else
            if os.clock() - lastSubmergedTeleportAt > 5 then
                lastSubmergedTeleportAt = os.clock()
                task.spawn(function()
                    pcall(function()
                        local net = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net")
                        net:WaitForChild("RF/SubmarineWorkerSpeak"):InvokeServer("TravelToSubmergedIsland")
                    end)
                end)
            end
            return true
        end
    end
    return false
end



local function ToggleFloat(state)
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local bv = hrp:FindFirstChild("AutofarmBv")

	if state then
		if not bv then
			bv = Instance.new("BodyVelocity")
			bv.Name = "AutofarmBv"
			bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bv.Velocity = Vector3.zero
			bv.Parent = hrp
		end
	else
		if bv then bv:Destroy() end
		local bg = hrp:FindFirstChild("AutofarmBg")
		if bg then bg:Destroy() end
	end
end

local function TweenTo(targetCFrame)
    local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetPos = targetCFrame.Position

    -- Water Detection Anti-Drowning System
    -- Check if target is near or below the sea level (but not Submerged layer which is < -1000)
    -- Water objects in Blox Fruits usually sit around Y = 10 to 15.
    if targetPos.Y > -500 and targetPos.Y < 25 then
        local waterObj = workspace:FindFirstChild("Water")
        if waterObj and waterObj:IsA("BasePart") then
            local waterTop = waterObj.Position.Y + (waterObj.Size.Y / 2)
            if targetPos.Y <= waterTop + 5 then
                -- Elevate the target safely above water
                targetPos = Vector3.new(targetPos.X, waterTop + 25, targetPos.Z)
                targetCFrame = CFrame.new(targetPos)
            end
        else
            -- Failsafe if Water object isn't found but Y is dangerously low
            if targetPos.Y < 20 then
                targetPos = Vector3.new(targetPos.X, 25, targetPos.Z)
                targetCFrame = CFrame.new(targetPos)
            end
        end
    end
    local subState, subPos = HandleSubmerged(targetPos)
    if subState == true then
        if activeTween then activeTween:Cancel(); activeTween = nil end
        return
    elseif subState == "TRAVEL" then
        targetPos = subPos
        targetCFrame = CFrame.new(targetPos)
    end

    ToggleFloat(true)

    local distance = (hrp.Position - targetPos).Magnitude

    -- CFrame Bypass for fast short-distance travel (Instantly teleports if under 300 studs)
    if distance <= 300 then
        if activeTween then activeTween:Cancel(); activeTween = nil end
        hrp.CFrame = targetCFrame
        lastTargetPos = targetPos
        return
    end

    -- Anti-Stutter & Spam Prevention for Tween (Long distance)
    if lastTargetPos and (targetPos - lastTargetPos).Magnitude < 30 then
        if activeTween then
            return
        end
    end
    lastTargetPos = targetPos

    local duration = math.max(distance / cfg.TweenSpeed, 0.05)

    pcall(function()
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        if remote then
            local req = remote:FindFirstChild("RequestStreamAroundAsync")
            if req then req:FireServer(targetPos) end
        end
    end)

    if activeTween then activeTween:Cancel() end
    activeTween = TweenService:Create(
        hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = targetCFrame}
    )

    activeTween:Play()
end

local function SafeTouch(targetPart, hrp, overrideDistance)
    if not targetPart or not hrp then return end
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
        -- Fallback: Fisik menyentuh
        if dist > 8 then
            TweenTo(CFrame.new(targetPart.Position))
        else
            if activeTween then activeTween:Cancel(); activeTween = nil end
            hrp.CFrame = CFrame.new(targetPart.Position)
            task.wait(0.1)
            return true
        end
    end
    return false
end

local function SafeProximity(promptPart)
    local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
    if hasProximity then
        if prompt then fireproximityprompt(prompt, prompt.HoldDuration) end
    else
        local key = prompt.KeyboardKeyCode ~= Enum.KeyCode.Unknown and prompt.KeyboardKeyCode or Enum.KeyCode.E
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(prompt.HoldDuration > 0 and prompt.HoldDuration or 0.1)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

--==================================================
-- [ SEA EVENTS UTILITIES ]
--==================================================

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
    if #islandList == 0 then table.insert(islandList, "No islands found (Error)") end
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

local function GetBoat()
    if not workspace:FindFirstChild("Boats") then return nil end

    local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end

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
    if not myHrp then return nil end

    local npcsFolder = workspace:FindFirstChild("NPCs")
    if not npcsFolder then return nil end

    local nearestDealer = nil
    local shortestDist = math.huge

    for _, npc in ipairs(npcsFolder:GetChildren()) do
        -- Hanya terima nama yang EXACTLY "Boat Dealer" atau "Luxury Boat Dealer"
        if npc.Name == "Boat Dealer" or npc.Name == "Luxury Boat Dealer" then
            -- Beberapa NPC memiliki part bernama "Head" atau "HumanoidRootPart"
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
    -- Tambahkan anti-spam agar tidak diban server (Cooldown 2 detik)
    if os.clock() - lastBuyAttempt < 2 then return false end

    pcall(function()
        local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
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
            -- Bypass InputManager: Duduk secara terprogram
            if not hum.Sit then
                hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
                task.wait(0.1)
                seat:Sit(hum)
            end
        else
            -- Pastikan kita tidak terbang di atasnya (TweenHeight), tapi tepat ke arahnya
            TweenTo(CFrame.new(seat.Position + Vector3.new(0, 5, 0), seat.Position))
        end
    end
    return false
end

local function DodgeAttack()
    local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if os.clock() - lastDodgeTime < cfg.dodgeCooldown then return end

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
            local targetPart = chest:IsA("Model") and (chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")) or chest
            if targetPart and targetPart:IsA("BasePart") then
                    table.insert(chestWaypoints, targetPart)
            end
        end
    end
end

local function CollectNearestFruit()
    if #fruitWaypoints == 0 then return false end
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
            if HandleSubmerged(nearestFruit.Position) then return false end

            SafeTouch(nearestFruit, hrp, 50)
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
    if not hrp or not hum then return false end

    if #chestWaypoints == 0 then
        

        local originLocations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
        if originLocations then
            local islands = originLocations:GetChildren()
            if #islands > 0 then
                if currentIslandIndex > #islands then currentIslandIndex = 1 end
                local targetLocation = islands[currentIslandIndex]
                
                -- Blacklist Filter
                if targetLocation then
                    local locName = string.lower(targetLocation.Name)
                    if string.find(locName, "trial") or 
                       string.find(locName, "secret temple") or 
                       string.find(locName, "l'église de prophétie") or 
                       string.find(locName, "???") or 
                       string.find(locName, "temple of time") then
                           
                        currentIslandIndex = currentIslandIndex + 1
                        if currentIslandIndex > #islands then currentIslandIndex = 1 end
                        return false
                    end
                end

                if targetLocation and targetLocation:IsA("BasePart") then
                    pcall(function()
                        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                        if remote then
                            local req = remote:FindFirstChild("RequestStreamAroundAsync")
                            if req then req:FireServer(targetLocation.Position) end
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
        local targetPart = nearestChest:IsA("Model") and (nearestChest.PrimaryPart or nearestChest:FindFirstChildWhichIsA("BasePart")) or nearestChest
        if targetPart then
            if HandleSubmerged(targetPart.Position) then return false end

            pcall(function()
                local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                if remote then
                    local req = remote:FindFirstChild("RequestStreamAroundAsync")
                    if req then req:FireServer(targetPart.Position) end
                end
            end)

            local dist = (hrp.Position - targetPart.Position).Magnitude
            if dist > 300 then
                TweenTo(targetPart.CFrame)
            else
                if not isCollectingChest then
                    isCollectingChest = true
                    task.spawn(function()
                        if activeTween then activeTween:Cancel(); activeTween = nil end
                        
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
                Duration = 3
            })
        end
    end)

    local servers = {}
    local req = syn and syn.request or http_request
    if req then
        local res = req({
            Url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100",
            Method = "GET"
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
        TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
    else
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

--==================================================
-- [ QUEST SYSTEM ]
--==================================================

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
			LastSeen = 0
		}
	end
else
	_G.QuestCache = _G.QuestCache or {
		IsActive = false,
		MobName = nil,
		Current = 0,
		Maximum = 0,
		Finished = false,
		Text = "",
		LastSeen = 0
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
		local questContainer = playerGui
			and playerGui:FindFirstChild("Main")
			and playerGui.Main:FindFirstChild("Quest")

		local titleObj = questContainer
			and questContainer:FindFirstChild("Container")
			and questContainer.Container:FindFirstChild("QuestTitle")
			and questContainer.Container.QuestTitle:FindFirstChild("Title")

		local text = titleObj and titleObj.Text or ""

		if questContainer and questContainer.Visible and text ~= "" then
			local current, maximum = string.match(text, "%((%d+)%s*/%s*(%d+)%)")
			local actualMob = nil

			if currentQuestPool and #currentQuestPool > 0 then
				for _, quest in ipairs(currentQuestPool) do
					if quest.Mob and string.find(text, quest.Mob, 1, true) then
						actualMob = quest.Mob
						break
					end
				end
			end

			if not actualMob and targetMobName and string.find(text, targetMobName, 1, true) then
				actualMob = targetMobName
			end

			QuestCache.MobName = actualMob
			QuestCache.Current = tonumber(current) or 0
			QuestCache.Maximum = tonumber(maximum) or 0
			QuestCache.Finished = (QuestCache.Maximum > 0 and QuestCache.Current >= QuestCache.Maximum)
			QuestCache.Text = text
			QuestCache.LastSeen = tick()
			QuestCache.IsActive = (actualMob ~= nil)
		else
			QuestCache.IsActive = false
			QuestCache.Finished = false
		end

		local correct = targetMobName
			and QuestCache.IsActive
			and QuestCache.MobName == targetMobName

		return {
			Active = QuestCache.IsActive,
			Correct = correct == true,
			Finished = QuestCache.Finished,
			Text = QuestCache.Text,
			MobName = QuestCache.MobName,
			Current = QuestCache.Current,
			Maximum = QuestCache.Maximum
		}
	end)

	if success and result then return result end

	return { Active = false, Correct = false, Finished = false, Text = "", MobName = nil, Current = 0, Maximum = 0 }
end

local function GetQuestProfile()
	local level = GetPlayerLevel()
	local list = nil

	if game.PlaceId == 2753915549 then
		list = SEA1
	elseif game.PlaceId == 4442272183 or game.PlaceId == 79091703265657 then
		list = SEA2
	elseif game.PlaceId == 7449423635 then
		list = SEA3
	else
		list = (level >= 1500) and SEA3 or (level >= 700) and SEA2 or SEA1
	end

	if not list or #list == 0 then return nil end

	local highestQuest = nil
	for _, p in ipairs(list) do
		if level >= p.Min then
			if not highestQuest or p.Min > highestQuest.Min or (p.Min == highestQuest.Min and p.Stage > highestQuest.Stage) then
				highestQuest = p
			end
		end
	end

	if not highestQuest then return list[1] end

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
			if a.Min ~= b.Min then return a.Min > b.Min end
			if a.Stage ~= b.Stage then return a.Stage > b.Stage end
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

	if #currentQuestPool == 0 then return highestQuest end
	if currentPoolIndex > #currentQuestPool then currentPoolIndex = 1 end

	return currentQuestPool[currentPoolIndex]
end

local function GetQuestProfileKey(profile)
	if not profile then return "" end
	return table.concat({tostring(profile.Quest or ""), tostring(profile.Stage or ""), tostring(profile.Mob or ""), tostring(profile.Min or ""), tostring(profile.Max or "")}, "|")
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


--==================================================
-- [ COMBAT SYSTEM ]
--==================================================

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
	Combat = true, ["Dark Step"] = true, Electro = true, ["Water Kung Fu"] = true, ["Fishman Karate"] = true,
	["Dragon Breath"] = true, Superhuman = true, ["Death Step"] = true, ["Sharkman Karate"] = true, ["Electric Claw"] = true,
	["Dragon Talon"] = true, Godhuman = true, ["Sanguine Art"] = true,
}

local function GetSafePosition(obj)
    if not obj then return Vector3.zero end
    if obj:IsA("Model") then
        return obj:GetBoundingBox().Position
    elseif obj:IsA("BasePart") then
        return obj.Position
    end
    -- Fallback for extremely weird objects
    pcall(function()
        if obj.Position then return obj.Position end
    end)
    return Vector3.zero
end

local function GetHitPart(model)
	if not model then return nil end
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

local function IsBossEntity(targetChar)
    if not targetChar then return false end
    return targetChar:GetAttribute("IsRaidBoss") == true or
           targetChar:GetAttribute("isRaidBoss") == true or
           targetChar:GetAttribute("RaidBoss") == true or
           targetChar:GetAttribute("IsBoss") == true or
           targetChar:GetAttribute("isBoss") == true or
           targetChar:GetAttribute("Boss") == true or
           targetChar.Name == "PropHitboxPlaceholder"
end

local function IsEnemyVulnerable(targetChar, targetMobName)
	if not targetChar or not targetChar.Parent then return false end

	if targetChar.Name == "Blank Buddy" then return false end

	if targetChar.Name == "PropHitboxPlaceholder" then
	    local hasPart = targetChar:FindFirstChildWhichIsA("BasePart", true) or targetChar:IsA("BasePart")
	    local hum = targetChar:FindFirstChildOfClass("Humanoid")
	    if hum and hum.Health <= 0 then return false end
	    return hasPart ~= nil
	end

	if enemyBlacklist[targetChar] then
	    if os.clock() < enemyBlacklist[targetChar] then
	        return false
	    else
	        enemyBlacklist[targetChar] = nil
	    end
	end

	if targetMobName and targetChar.Name ~= targetMobName then return false end

	local hum = targetChar:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	return (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")) ~= nil
end

local function GetTargetEnemy(mobName)
	local closest, shortestDist = nil, math.huge
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")

	if enemiesFolder and myHrp then
	    -- PRIORITY OVERRIDE: Cek jika ada PropHitboxPlaceholder
	    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
	        if enemy.Parent == enemiesFolder and enemy.Name == "PropHitboxPlaceholder" and IsEnemyVulnerable(enemy, nil) then
	            return enemy
	        end
	    end

		for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		    if enemy.Parent == enemiesFolder then
		        local isValid = false
		        if farmNearestEnabled then
		            isValid = IsEnemyVulnerable(enemy, nil)
		        else
		            isValid = mobName and (string.lower(enemy.Name) == string.lower(mobName)) and IsEnemyVulnerable(enemy, mobName)
		        end

			    if isValid then
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
		end
	end
	return closest
end

local function GetBossProfileByName(name)
	if not name then return nil end
	for _, boss in ipairs(BOSSES) do if boss.Name == name then return boss end end
	return nil
end

local function GetSpawnedBoss(targetBossName)
	local bossProfile = GetBossProfileByName(targetBossName)
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if bossProfile and enemiesFolder then
		for _, enemy in ipairs(enemiesFolder:GetChildren()) do
			if enemy.Name == bossProfile.Name and IsEnemyVulnerable(enemy, bossProfile.Name) then
				if enemy:FindFirstChild("HumanoidRootPart") then return enemy, bossProfile end
			end
		end
	end
	return nil, bossProfile
end

local function IsToolMatching(tool, wantedCategory)
	if not tool or not tool:IsA("Tool") or tool.Name == "Tool" then return false end
	local expectedToolTip = wantedCategory
	if wantedCategory == "Fruit" or wantedCategory == "Blox Fruit" or wantedCategory == "Demon Fruit" then expectedToolTip = "Blox Fruit" end
	if tool.ToolTip == expectedToolTip then return true end
	return wantedCategory == "Melee" and meleeNames[tool.Name] == true
end

local function EquipWeapon(overrideCategory)
	local c = GetCharacter()
	local h = GetHumanoid()
	if not c or not h then return nil end

	local wantedCategory = overrideCategory or (cfg.AutoMastery and cfg.MasteryCategory or cfg.WeaponCategory)
	local existing = c:FindFirstChildOfClass("Tool")
	if IsToolMatching(existing, wantedCategory) then
		cachedWeapon = existing
		cachedWeaponCategory = wantedCategory
		return existing
	end

	if cachedWeapon and cachedWeapon.Parent == c and IsToolMatching(cachedWeapon, wantedCategory) then return cachedWeapon end

	local bag = player:FindFirstChildOfClass("Backpack")
	if not bag then return nil end

	for _, tool in ipairs(bag:GetChildren()) do
		if IsToolMatching(tool, wantedCategory) then
			pcall(function() h:EquipTool(tool) end)
			cachedWeapon = tool
			cachedWeaponCategory = wantedCategory
			return tool
		end
	end
	return nil
end

local function EnableBuso()
	local c = GetCharacter()
	if c and not c:GetAttribute("BusoEnabled") then pcall(function() CommF_:InvokeServer("Buso") end) end
end

local lastSkillFiredAt = 0
local skillKeys = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V, Enum.KeyCode.F}
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
			if skillIndex > #skillKeys then skillIndex = 1 end
		end)
	end
end

--==================================================
-- [ AUTO FARM BRAIN ]
--==================================================

local function ExecuteAttack(myChar, myHrp, forceNoEquip, targetMobName)
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
        if not weapon then return end
    else
        weapon = cachedWeapon
        if not weapon or weapon.Parent ~= myChar or not IsToolMatching(weapon, targetCategory) then
            weapon = EquipWeapon(targetCategory)
        end
    end

    if weapon then
        -- Anti-Cheat Bypass: Server menolak serangan jika karakter memiliki part yang ter-Anchor.
        for _, v in ipairs(myChar:GetDescendants()) do
            if v:IsA("BasePart") and v.Anchored then
                v.Anchored = false
            end
        end

        local isPhysical = IsToolMatching(weapon, "Melee") or IsToolMatching(weapon, "Sword")
        if isPhysical then
            EnableBuso()
            local enemiesFolder = workspace:FindFirstChild("Enemies")
            if enemiesFolder then
                local hitTargets = {}
                for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                    if IsEnemyVulnerable(enemy, targetMobName) then
                        local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
                        if eHrp then
                            local dist = (GetSafePosition(eHrp) - GetSafePosition(myHrp)).Magnitude
                            local isTarget = (currentTargetInstance and enemy == currentTargetInstance)
                            local allowedDist = isTarget and (cfg.HitRadius + 40) or cfg.HitRadius

                            if dist <= allowedDist then
                                local ePart = GetHitPart(enemy)
                                if ePart then
                                    table.insert(hitTargets, {EnemyModel = enemy, HitPart = ePart})
                                end
                            end
                        end
                    end
                end

                if #hitTargets > 0 then
                    task.spawn(function()
                        if isMultiMobDamage then
                            local primaryDict = hitTargets[1]
                            local primaryPart = primaryDict.HitPart

                            local additionalHits = {}
                            for j = 2, #hitTargets do
                                local adjDict = hitTargets[j]
                                table.insert(additionalHits, {adjDict.EnemyModel, adjDict.HitPart})
                            end

                            pcall(function()
                                if RegisterAttackEvent then
                                    RegisterAttackEvent:FireServer(0, Random.new():NextInteger(1, 4))
                                end
                                if RegisterHitEvent then
                                    RegisterHitEvent:FireServer(primaryPart, additionalHits, nil, sessionSecret)
                                end
                            end)
                        else
                            local primaryDict = hitTargets[1]
                            pcall(function()
                                if RegisterAttackEvent then
                                    RegisterAttackEvent:FireServer(0, Random.new():NextInteger(1, 4))
                                end
                                if RegisterHitEvent then
                                    RegisterHitEvent:FireServer(primaryDict.HitPart, {}, nil, sessionSecret)
                                end
                            end)
                        end
                    end)
                    if cfg.AutoMastery then
                        for i = 1, #skillKeys do
                            TriggerSkills(skillKeys[i])
                        end
                    end
                end
            end
        else
            if cfg.AutoMastery then
                for i = 1, #skillKeys do
                    TriggerSkills(skillKeys[i])
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
                local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast

                if now - lastAttackAt >= interval then
                    local myChar = GetCharacter()
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if myHrp then
                        local tName = currentTargetInstance and currentTargetInstance.Name or nil
                        ExecuteAttack(myChar, myHrp, false, tName)
                        lastAttackAt = now
                    end
                end
            end

            -- If in attack mode, reduce wait bottleneck!
            if enabled and attackSpeedMode == "Super Fast Attack" then
                task.wait() -- No arguments (matching fastest game frame)
            else
                task.wait(cfg.ThreadSleep)
            end
        end
    end)
end


local function GetBestHauntedMob()
    local hauntedMobs = {
        { Name = "Reborn Skeletons", Mob = "Reborn Skeleton" },
        { Name = "Living Zombies", Mob = "Living Zombie" },
        { Name = "Demonic Souls", Mob = "Demonic Soul" },
        { Name = "Posessed Mummies", Mob = "Posessed Mummy" }
    }

    for _, info in ipairs(hauntedMobs) do
        local profile = GetMobProfileByName(info.Mob)
        if profile then info.MobPos = profile.MobPos end
    end

    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return hauntedMobs[math.random(1, #hauntedMobs)] end

    local availableMobTypes = {}
    local seenMobTypes = {}

    for _, enemy in ipairs(enemies:GetChildren()) do
        for _, mobInfo in ipairs(hauntedMobs) do
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

    return nil
end

local function GetBestCocoaMob()
    local cocoaMobs = {
        { Name = "Cocoa Warriors", Mob = "Cocoa Warrior" },
        { Name = "Chocolate Bar Battlers", Mob = "Chocolate Bar Battler" }
    }

    for _, info in ipairs(cocoaMobs) do
        local profile = GetMobProfileByName(info.Mob)
        if profile then info.MobPos = profile.MobPos end
    end

    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return cocoaMobs[math.random(1, #cocoaMobs)] end

    local availableMobTypes = {}
    local seenMobTypes = {}

    for _, enemy in ipairs(enemies:GetChildren()) do
        for _, mobInfo in ipairs(cocoaMobs) do
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

    return nil
end

local function StartAutoBone()
    local generation = workerGeneration
    ToggleFloat(true)
    
    local defaultHauntedFallback = { Name = "Reborn Skeletons", Mob = "Reborn Skeleton", MobPos = Vector3.new(-8760, 183, 6168) }
    local activeHauntedMobInfo = GetBestHauntedMob() or defaultHauntedFallback

    task.spawn(function()
        while isAutoBone and ScriptContext.Running and generation == workerGeneration do
            local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast
            local myChar = GetCharacter()
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHrp then
                local tName = currentTargetInstance and currentTargetInstance.Name or activeHauntedMobInfo.Mob
                ExecuteAttack(myChar, myHrp, false, tName)
            end

            if interval <= 0 then task.wait() else task.wait(interval) end
        end
    end)

    local boneBringConn
    boneBringConn = RunService.Heartbeat:Connect(function()
        if not isAutoBone or not ScriptContext.Running or generation ~= workerGeneration then
            if boneBringConn then boneBringConn:Disconnect() end
            return
        end
        if isReadyToAttack then
            local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
            local target = currentTargetInstance
            local tHrp = target and target:FindFirstChild("HumanoidRootPart")
            if myHrp and tHrp then
                local enemiesFolder = workspace:FindFirstChild("Enemies")
                if enemiesFolder then
                    local targetMobInfo = activeHauntedMobInfo or GetBestHauntedMob()
                    local targetMobName = targetMobInfo.Mob
                    local magnetPos = targetMobInfo.MobPos or tHrp.Position or tHrp.Position

					if magnetPos then
                        -- Use absolute spawn/mob position, don't link to myHrp.CFrame (evasion) to avoid rubber-banding.
                        -- magnetPos already represents original/ground point.
					    local gatherCFrame = CFrame.new(magnetPos.X, magnetPos.Y, magnetPos.Z)

                        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                            if enemy.Name == targetMobName and IsEnemyVulnerable(enemy, targetMobName) then
                                if enemy.Name ~= "PropHitboxPlaceholder" then
                                    local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
                                    local eHum = enemy:FindFirstChildOfClass("Humanoid")
                                    if eHrp and eHum and eHum.Health > 0 then
                                        local dist = (GetSafePosition(eHrp) - gatherCFrame.Position).Magnitude
                                        if dist <= cfg.BringRadius then
                                            eHrp.CFrame = gatherCFrame
                                            eHrp.AssemblyLinearVelocity = Vector3.zero
                                            eHrp.AssemblyAngularVelocity = Vector3.zero
                                            if eHrp.CanCollide then eHrp.CanCollide = false end
                                            if eHum.PlatformStand == false then eHum.PlatformStand = true end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    ScriptContext:AddConnection(boneBringConn)

    task.spawn(function()
        while isAutoBone and ScriptContext.Running and generation == workerGeneration do
            local ok, err = pcall(function()
                local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
                if not myHrp then return end

                local now = os.clock()
                if now - lastEvasionTime >= cfg.EvasionTick then
                    lastEvasionTime = now
                    local radius = math.max(0, math.floor(cfg.EvasionRadius))
                    currentEvasionOffset = Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
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
                    -- If still nil, this mob species is WIPED OUT! Try switching to another active species.
                    if not targetEnemy then
                        local checkNewMob = GetBestHauntedMob()
                        if checkNewMob then
                            activeHauntedMobInfo = checkNewMob
                            targetMobInfo = activeHauntedMobInfo
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
                    local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
                    if tHrp then
                        local mobProfile = GetMobProfileByName(targetEnemy.Name)
                        -- Fly chasing this colony's Spawn center to be safe, don't chase escaping enemies out of bounds!
                        local centerPos = mobProfile and mobProfile.MobPos or tHrp.Position

                        local targetDistance = (centerPos - myHrp.Position).Magnitude
                        if targetDistance > 80 then
                            if now - lastEvasionMoveAt >= 0.5 then
                                lastEvasionMoveAt = now
                                TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
                            end
                        else
                            if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                                lastEvasionMoveAt = now
                                TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
                            end
                        end
                        -- Attack can start when character is close enough to MobPos center OR actual enemy
                        isReadyToAttack = (tHrp.Position - myHrp.Position).Magnitude <= cfg.HitRadius or targetDistance <= cfg.HitRadius
                    end
                else
                    currentTargetInstance = nil
                    isReadyToAttack = false
                    local distToSpawn = (myHrp.Position - targetMobInfo.MobPos).Magnitude
                    if distToSpawn > 80 then
                        TweenTo(CFrame.new(targetMobInfo.MobPos + Vector3.new(0, cfg.TweenHeight, 0), targetMobInfo.MobPos))
                    else
                        if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                            lastEvasionMoveAt = now
                            TweenTo(CFrame.new(targetMobInfo.MobPos + currentEvasionOffset, targetMobInfo.MobPos))
                        end
                    end
                end
            end)
            task.wait()
        end
    end)
end

local function StartAutoCocoa()
    local generation = workerGeneration
    ToggleFloat(true)

    local defaultCocoaFallback = { Name = "Cocoa Warriors", Mob = "Cocoa Warrior", MobPos = Vector3.new(-21, 80, -12352) }
    local activeCocoaMobInfo = GetBestCocoaMob() or defaultCocoaFallback

    task.spawn(function()
        while isAutoCocoa and ScriptContext.Running and generation == workerGeneration do
            local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast
            local myChar = GetCharacter()
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHrp then
                local tName = currentTargetInstance and currentTargetInstance.Name or activeCocoaMobInfo.Mob
                ExecuteAttack(myChar, myHrp, false, tName)
            end

            if interval <= 0 then task.wait() else task.wait(interval) end
        end
    end)

    local cocoaBringConn
    cocoaBringConn = RunService.Heartbeat:Connect(function()
        if not isAutoCocoa or not ScriptContext.Running or generation ~= workerGeneration then
            if cocoaBringConn then cocoaBringConn:Disconnect() end
            return
        end
        if isReadyToAttack then
            local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
            local target = currentTargetInstance
            local tHrp = target and target:FindFirstChild("HumanoidRootPart")
            if myHrp and tHrp then
                local enemiesFolder = workspace:FindFirstChild("Enemies")
                if enemiesFolder then
                    local targetMobInfo = activeCocoaMobInfo or GetBestCocoaMob()
                    local targetMobName = targetMobInfo.Mob
                    local magnetPos = targetMobInfo.MobPos or tHrp.Position

					if magnetPos then
					    local gatherCFrame = CFrame.new(magnetPos.X, magnetPos.Y, magnetPos.Z)

                        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                            if enemy.Name == targetMobName and IsEnemyVulnerable(enemy, targetMobName) then
                                if enemy.Name ~= "PropHitboxPlaceholder" then
                                    local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
                                    local eHum = enemy:FindFirstChildOfClass("Humanoid")
                                    if eHrp and eHum and eHum.Health > 0 then
                                        local dist = (GetSafePosition(eHrp) - gatherCFrame.Position).Magnitude
                                        if dist <= cfg.BringRadius then
                                            eHrp.CFrame = gatherCFrame
                                            eHrp.AssemblyLinearVelocity = Vector3.zero
                                            eHrp.AssemblyAngularVelocity = Vector3.zero
                                            if eHrp.CanCollide then eHrp.CanCollide = false end
                                            if eHum.PlatformStand == false then eHum.PlatformStand = true end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    ScriptContext:AddConnection(cocoaBringConn)

    task.spawn(function()
        while isAutoCocoa and ScriptContext.Running and generation == workerGeneration do
            local ok, err = pcall(function()
                local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
                if not myHrp then return end

                local now = os.clock()
                if now - lastEvasionTime >= cfg.EvasionTick then
                    lastEvasionTime = now
                    local radius = math.max(0, math.floor(cfg.EvasionRadius))
                    currentEvasionOffset = Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
                end

                if not activeCocoaMobInfo then
                    activeCocoaMobInfo = GetBestCocoaMob() or defaultCocoaFallback
                end

                local targetMobInfo = activeCocoaMobInfo
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
                    -- If still nil, this mob species is WIPED OUT! Try switching to another active species.
                    if not targetEnemy then
                        local checkNewMob = GetBestCocoaMob()
                        if checkNewMob then
                            activeCocoaMobInfo = checkNewMob
                            targetMobInfo = activeCocoaMobInfo
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
                    local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
                    if tHrp then
                        local mobProfile = GetMobProfileByName(targetEnemy.Name)
                        local centerPos = mobProfile and mobProfile.MobPos or tHrp.Position

                        local targetDistance = (centerPos - myHrp.Position).Magnitude
                        if targetDistance > 80 then
                            if now - lastEvasionMoveAt >= 0.5 then
                                lastEvasionMoveAt = now
                                TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
                            end
                        else
                            if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                                lastEvasionMoveAt = now
                                TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
                            end
                        end
                        isReadyToAttack = (tHrp.Position - myHrp.Position).Magnitude <= cfg.HitRadius or targetDistance <= cfg.HitRadius
                    end
                else
                    currentTargetInstance = nil
                    isReadyToAttack = false
                    local distToSpawn = (myHrp.Position - targetMobInfo.MobPos).Magnitude
                    if distToSpawn > 80 then
                        TweenTo(CFrame.new(targetMobInfo.MobPos + Vector3.new(0, cfg.TweenHeight, 0), targetMobInfo.MobPos))
                    else
                        if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                            lastEvasionMoveAt = now
                            TweenTo(CFrame.new(targetMobInfo.MobPos + currentEvasionOffset, targetMobInfo.MobPos))
                        end
                    end
                end
            end)
            task.wait()
        end
    end)
end

local function StartAutoFarm()
	local generation = workerGeneration

	ToggleFloat(true)
	AttackThread(generation)

	task.spawn(function()
		while enabled and ScriptContext.Running and generation == workerGeneration do
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then return end

				local hasQuestUI = HasActiveQuest()
				local profile = GetQuestProfile()
				if not profile then return end

				-- Boss Hunter Check
				if isBossHunterEnabled and selectedBossName then
					local spawnedBoss, bossProfile = GetSpawnedBoss(selectedBossName)
					if not bossProfile then return end

					local bossQuestStatus = GetQuestStatus(bossProfile.Name)
					local hasBossQuest = bossQuestStatus.Active and bossQuestStatus.Correct

					if spawnedBoss then
						if not hasBossQuest then
							isReadyToAttack = false
							currentTargetInstance = nil
							if (myHrp.Position - bossProfile.NPC).Magnitude > 8 then
								TweenTo(CFrame.new(bossProfile.NPC))
							else
								if activeTween then activeTween:Cancel(); activeTween = nil end
								if CommF_ then
									if HasActiveQuest() then CommF_:InvokeServer("AbandonQuest") end
									CommF_:InvokeServer("StartQuest", bossProfile.Quest, bossProfile.Stage or 1)
									task.wait(0.5)
								end
							end
						else
							local bHrp = spawnedBoss:FindFirstChild("HumanoidRootPart")
							if bHrp then
								local targetDistance = (bHrp.Position - myHrp.Position).Magnitude
								local now = os.clock()

								if now - lastEvasionTime >= cfg.EvasionTick then
									lastEvasionTime = now
									local radius = math.max(0, math.floor(cfg.EvasionRadius))
									currentEvasionOffset = Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
								end

								if targetDistance > 80 then
									TweenTo(CFrame.new(bHrp.Position + currentEvasionOffset, bHrp.Position))
								else
									if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
										lastEvasionMoveAt = now
										TweenTo(CFrame.new(bHrp.Position + currentEvasionOffset, bHrp.Position))
									end
								end

								isReadyToAttack = targetDistance <= cfg.HitRadius
								currentTargetInstance = spawnedBoss
							end
						end
					else
						isReadyToAttack = false
						currentTargetInstance = nil
						if (myHrp.Position - bossProfile.NPC).Magnitude > 8 then
							TweenTo(CFrame.new(bossProfile.NPC))
						else
							if activeTween then activeTween:Cancel(); activeTween = nil end
						end
					end
					return
				end

				-- Normal Auto Farm Flow
				local questStatus = GetQuestStatus(profile.Mob)
				local hasQuestUI = questStatus.Active
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
					pcall(function() CommF_:InvokeServer("AbandonQuest") end)
					QuestCache.IsActive = false
					QuestCache.Finished = false
					QuestCache.MobName = nil
					QuestCache.LastSeen = 0
					isReadyToAttack = false
					currentTargetInstance = nil
					lastTargetRefreshAt = 0
					return
				end

				if not hasQuestUI then
					isReadyToAttack = false
					currentTargetInstance = nil
					if (myHrp.Position - profile.NPC).Magnitude > 8 then
						TweenTo(CFrame.new(profile.NPC))
						return
					end
					if activeTween then activeTween:Cancel(); activeTween = nil end
					pcall(function() CommF_:InvokeServer("StartQuest", profile.Quest, profile.Stage) end)
					lastStartedQuestKey = GetQuestProfileKey(profile)
					lastStartedQuestAt = os.clock()
					return
				end

					local now = os.clock()
					if now - lastEvasionTime >= cfg.EvasionTick then
						lastEvasionTime = now
						local radius = math.max(0, math.floor(cfg.EvasionRadius))
						currentEvasionOffset = Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
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
                                        return
                                    else
                                        lastTargetHealthChangeAt = now
                                    end
                                end
                            end
                            local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
                            if tHrp then
                                ToggleFloat(true)
                                -- Actively chase enemy. StuckTimeout will handle if enemy is bugged/out of bounds.
                                local centerPos = GetSafePosition(tHrp)
                                local targetDistance = (centerPos - myHrp.Position).Magnitude
                                if targetDistance > 80 then
                                    TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
                                else
                                    if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                                        lastEvasionMoveAt = now
                                        TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
                                    end
                                end
                                isReadyToAttack = targetDistance <= cfg.HitRadius
                            end
                        else
                            currentTargetInstance = nil
                            isReadyToAttack = false
                            ToggleFloat(true)
                            local distToSpawn = (myHrp.Position - profile.MobPos).Magnitude
                            if distToSpawn > 80 then
                                if now - lastEvasionMoveAt >= 0.5 then
                                    lastEvasionMoveAt = now
                                    TweenTo(CFrame.new(profile.MobPos + Vector3.new(0, cfg.TweenHeight, 0), profile.MobPos))
                                end
                            else
                                if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                                    lastEvasionMoveAt = now
                                    TweenTo(CFrame.new(profile.MobPos + currentEvasionOffset, profile.MobPos))
                                end
                            end
                        end
                end)

                if not ok then warn("[Lonum Error]: " .. tostring(err))
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
	ToggleFloat(false)
	lastTargetPos = nil
	currentTargetInstance = nil
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

	if activeTween then activeTween:Cancel(); activeTween = nil end
end

ScriptContext:AddConnection(RunService.Stepped:Connect(function()
    if ScriptContext.Running then
        local c = player.Character
        if c then
			local hrp = c:FindFirstChild("HumanoidRootPart")
            -- Ensure tween is actively playing, not just a leftover finished variable
            local hasFloat = hrp and hrp:FindFirstChild("AutofarmBv") ~= nil
            if activeTween or hasFloat or isTweeningToPlayer or isAutoTorch or enabled or isAutoRaidKill or isAutoBone or isAutoCocoa or isAutoDungeon or farmNearestEnabled or autoKillVolcano then
                for _, v in ipairs(c:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                end
            end
        end
    end
end))



--==================================================
-- [ BACKGROUND TASKS (HEARTBEAT) ]
--==================================================

ScriptContext:AddConnection(RunService.Heartbeat:Connect(function(deltaTime)
	if not ScriptContext.Running then return end

    if cfg.autoBoat then
        currentBoat = GetBoat()
        if not currentBoat then
            -- Cari Dealer Terdekat
            local dealer = GetNearestBoatDealer()
            if dealer then
                local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
                if myHrp then
                    local dealerPos = GetSafePosition(dealer)
                    local dist = (myHrp.Position - dealerPos).Magnitude
                    
                    if dist > 20 then
                        -- Jika jauh, Tween terbang mendekati dealer
                        TweenTo(CFrame.new(dealerPos + Vector3.new(0, cfg.TweenHeight, 0)))
                    else
                        -- Jika sudah dekat (< 20 stud), hentikan tween dan eksekusi Remote Buy
                        if activeTween then activeTween:Cancel(); activeTween = nil end
                        BuyBoat()
                    end
                end
            else
                -- Failsafe: Jika NPC Boat Dealer tidak ter-render di pulau ini, batalkan Tween
                if activeTween then activeTween:Cancel(); activeTween = nil end
            end
        else
            -- Kapal sudah ada, batalkan terbang dan naiki kapal!
            if activeTween then activeTween:Cancel(); activeTween = nil end
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

    if cfg.autoFruit and #fruitWaypoints > 0 then CollectNearestFruit() end
    if cfg.autoChest then ScanForChests(); CollectNearestChest() end
    if cfg.dodgeEnabled then DodgeAttack() end

	if enabled and isReadyToAttack then
		local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
		local target = currentTargetInstance
		local tHrp = target and target:FindFirstChild("HumanoidRootPart")

		if myHrp and tHrp then
			local targetMobName = nil
			if isBossHunterEnabled and selectedBossName then
				targetMobName = selectedBossName
			else
				local profile = GetQuestProfile()
				if profile then targetMobName = profile.Mob end
			end

			if targetMobName then
				if not cachedEnemiesFolder or not cachedEnemiesFolder.Parent then cachedEnemiesFolder = workspace:FindFirstChild("Enemies") end
				if cachedEnemiesFolder then
					-- Main gather point (Magnet)
					local magnetPos = nil
					if profile and profile.MobPos then
					    magnetPos = profile.MobPos
					elseif currentTargetInstance and currentTargetInstance:FindFirstChild("HumanoidRootPart") then
					    magnetPos = currentTargetInstance.HumanoidRootPart.Position
					end
					
					if magnetPos then
                        -- STATIC MAGNET: Gather all enemies to the exact position of the locked enemy (or MobPos)
                        -- DO NOT USE myHrp.CFrame (Evasion) to prevent server rubber-banding!
					    local gatherCFrame = CFrame.new(magnetPos.X, magnetPos.Y, magnetPos.Z)
					    
					    for _, enemy in ipairs(cachedEnemiesFolder:GetChildren()) do
						    if enemy.Name == targetMobName and IsEnemyVulnerable(enemy, targetMobName) then
							    local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
							    local eHum = enemy:FindFirstChildOfClass("Humanoid")
							    if eHrp and eHum and eHum.Health > 0 then
								    local dist = (eHrp.Position - myHrp.Position).Magnitude
								    if dist <= (cfg.BringRadius * 2) then
								        -- Bring & Stun
									    eHrp.CFrame = gatherCFrame
									    eHrp.AssemblyLinearVelocity = Vector3.zero
									    eHrp.AssemblyAngularVelocity = Vector3.zero
									    
									    if eHrp.CanCollide then eHrp.CanCollide = false end
									    if eHum.PlatformStand == false then eHum.PlatformStand = true end
									    
									    -- Do not change size to 60x60x60 to prevent anti-cheat from glitching the enemies
									    if eHrp.Size.X > 10 then
									        eHrp.Size = Vector3.new(2, 2, 1) -- Revert to normal RootPart size
									    end
								    end
							    end
						    end
					    end
					end
				end
			end
		end
	end
end))

task.spawn(function()
    while task.wait(1) do
        if not ScriptContext.Running then break end
        if cfg.autoFruit then ScanForFruits() end
    end
end)

task.spawn(function()
    while task.wait(3) do -- Interval 3 detik agar aman dari limit server
        if not ScriptContext.Running then break end
        if isAutoSpinBones then
            pcall(function()
                local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
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
        if not ScriptContext.Running then break end
        if isAutoStatsEnabled then
            local data = player:FindFirstChild("Data")
            local points = data and data:FindFirstChild("Points")
            if points and points.Value > 0 then
                pcall(function()
                    if CommF_ then CommF_:InvokeServer("AddPoint", selectedStatCategory, 1) end
                end)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if not ScriptContext.Running then break end
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
    local raidMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("RaidMap")
    if not myHrp or not raidMap then return nil, 0 end

    -- 1. Cari tahu kita sedang berada di pulau stage berapa (Pulau Paling Dekat secara fisik)
    local currentIslandNum = 0
    local closestDistToAny = math.huge

    for _, island in ipairs(raidMap:GetChildren()) do
        if string.match(island.Name, "RaidIsland") then
            local iPos = island:IsA("Model") and island:GetBoundingBox().Position or island.Position
            local dist = (myHrp.Position - iPos).Magnitude
            if dist < closestDistToAny then
                closestDistToAny = dist
                local numStr = string.match(island.Name, "%d+")
                currentIslandNum = numStr and tonumber(numStr) or 0
            end
        end
    end

    -- 2. Dari pulau tempat kita berpijak, cari pulau selanjutnya (Stage lebih besar)
    -- yang posisinya paling dekat dengan kita, agar kita tidak nyasar ke raid tim lain
    local targetIsland = nil
    local targetIslandNum = currentIslandNum
    local shortestDistToNext = math.huge

    for _, island in ipairs(raidMap:GetChildren()) do
        if string.match(island.Name, "RaidIsland") then
            local numStr = string.match(island.Name, "%d+")
            local islandNum = numStr and tonumber(numStr) or 0

            -- Hanya perhatikan pulau yang stage-nya Lanjut (> dari posisi sekarang)
            if islandNum > currentIslandNum then
                local iPos = island:IsA("Model") and island:GetBoundingBox().Position or island.Position
                local dist = (myHrp.Position - iPos).Magnitude

                -- Ambil yang paling dekat dari semua pulau lanjutan yang tersedia
                if dist < shortestDistToNext then
                    shortestDistToNext = dist
                    targetIsland = island
                    targetIslandNum = islandNum
                end
            end
        end
    end

    -- Jika tidak ada pulau lanjutan (misal sudah di Island 5 atau belum terbuka), bertahan di pulau saat ini
    if not targetIsland then
        for _, island in ipairs(raidMap:GetChildren()) do
            if string.match(island.Name, "RaidIsland") then
                local numStr = string.match(island.Name, "%d+")
                local islandNum = numStr and tonumber(numStr) or 0
                if islandNum == currentIslandNum then
                    targetIsland = island
                    break
                end
            end
        end
    end

    return targetIsland, targetIslandNum
end

local function StartAutoRaid()
    raidWorkerGeneration = raidWorkerGeneration + 1
    local generation = raidWorkerGeneration
    ToggleFloat(true)

    task.spawn(function()
        while isAutoRaidKill and ScriptContext.Running and generation == raidWorkerGeneration do
            if isReadyToAttack and isAutoRaidAttack then
                local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast
                local myChar = GetCharacter()
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    local tName = currentTargetInstance and currentTargetInstance.Name or nil
                    ExecuteAttack(myChar, myHrp, false, tName)
                end

                if interval <= 0 then task.wait() else task.wait(interval) end
            else
                task.wait(cfg.ThreadSleep)
            end
        end
    end)

    local raidBringConn
    raidBringConn = RunService.Heartbeat:Connect(function()
        if not isAutoRaidKill or not ScriptContext.Running or generation ~= raidWorkerGeneration then
            if raidBringConn then raidBringConn:Disconnect() end
            return
        end

        if isReadyToAttack and isAutoRaidBring then
            local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
            local target = currentTargetInstance
            local tHrp = target and target:FindFirstChild("HumanoidRootPart")
            if myHrp and tHrp then
                local enemiesFolder = workspace:FindFirstChild("Enemies")
                if enemiesFolder then
                    local magnetPos = tHrp.Position
					if magnetPos then
					    local gatherCFrame = CFrame.new(magnetPos.X, magnetPos.Y, magnetPos.Z)
                        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                            if IsEnemyVulnerable(enemy) then
                                if enemy.Name ~= "PropHitboxPlaceholder" then
                                    local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
                                    local eHum = enemy:FindFirstChildOfClass("Humanoid")
                                    if eHrp and eHum and eHum.Health > 0 then
                                        local dist = (GetSafePosition(eHrp) - gatherCFrame.Position).Magnitude
                                        if dist <= cfg.BringRadius then
                                            eHrp.CFrame = gatherCFrame
                                            eHrp.AssemblyLinearVelocity = Vector3.zero
                                            eHrp.AssemblyAngularVelocity = Vector3.zero
                                            if eHrp.CanCollide then eHrp.CanCollide = false end
                                            if eHum.PlatformStand == false then eHum.PlatformStand = true end
                                        end
                                    end
                                end
                            end
                        end
                    end
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
                if not myHrp then return end

                local now = os.clock()
                if now - lastEvasionTime >= cfg.EvasionTick then
                    lastEvasionTime = now
                    local radius = math.max(0, math.floor(cfg.EvasionRadius))
                    currentEvasionOffset = Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
                end

                local enemiesFolder = workspace:FindFirstChild("Enemies")
                local raidMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("RaidMap")
                local targetEnemy = currentTargetInstance

                if not targetEnemy or not IsEnemyVulnerable(targetEnemy) then
                    local closest = nil
                    local shortestDist = 2000
                    if enemiesFolder then
                        -- PRIORITY OVERRIDE: PropHitboxPlaceholder
                        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                            if enemy.Name == "PropHitboxPlaceholder" and IsEnemyVulnerable(enemy) then
                                closest = enemy
                                break
                            end
                        end

                        if not closest then
                            for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                                if IsEnemyVulnerable(enemy) then
                                    local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
                                    if eHrp then
                                        local dist = (GetSafePosition(eHrp) - gatherCFrame.Position).Magnitude
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
                    local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
                    if tHrp then
                        local mobProfile = GetMobProfileByName(targetEnemy.Name)
                        -- Fly chasing this colony's Spawn center to be safe, don't chase escaping enemies out of bounds!
                        local centerPos = mobProfile and mobProfile.MobPos or tHrp.Position

                        local targetDistance = (centerPos - myHrp.Position).Magnitude
                        if targetDistance > 80 then
                            if now - lastEvasionMoveAt >= 0.5 then
                                lastEvasionMoveAt = now
                                TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
                            end
                        else
                            if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                                lastEvasionMoveAt = now
                                TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
                            end
                        end
                        -- Attack can start when character is close enough to MobPos center OR actual enemy
                        isReadyToAttack = (tHrp.Position - myHrp.Position).Magnitude <= cfg.HitRadius or targetDistance <= cfg.HitRadius
                    end
                else
                    isReadyToAttack = false
                    currentTargetInstance = nil

                    if raidEmptyTimer == 0 then raidEmptyTimer = now end

                    if isAutoRaidNextIsland and (now - raidEmptyTimer >= 2.5) then
                        local activeIsland, activeIslandNum = GetTargetRaidIsland()
                        if activeIsland then
                            local iPos = activeIsland:IsA("Model") and activeIsland:GetBoundingBox().Position or activeIsland.Position
                            
                            if activeIslandNum >= 5 then
                                local dist = (myHrp.Position - iPos).Magnitude
                                if dist > 80 then
                                    TweenTo(CFrame.new(iPos + Vector3.new(0, 100, 0), iPos))
                                else
                                    if activeTween then activeTween:Cancel(); activeTween = nil end
                                end
                                return
                            end

                            local dist = (myHrp.Position - iPos).Magnitude
                            if dist > 80 then
                                TweenTo(CFrame.new(iPos + Vector3.new(0, 60, 0), iPos))
                            else
                                -- Already at highest available island, wait for spawns while doing relaxed evasion
                                if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                                    lastEvasionMoveAt = now
                                    TweenTo(CFrame.new(iPos + currentEvasionOffset, iPos))
                                end
                            end
                        end
                    else
                        -- Standby ngambang di koordinat terakhir nunggu musuh spawn
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
            local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast
            local myChar = GetCharacter()
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHrp then
                local tName = currentTargetInstance and currentTargetInstance.Name or nil
                ExecuteAttack(myChar, myHrp, false, tName)
            end

            if interval <= 0 then task.wait() else task.wait(interval) end
        end
    end)

    local nearestBringConn
    nearestBringConn = RunService.Heartbeat:Connect(function()
        if not farmNearestEnabled or not ScriptContext.Running or generation ~= workerGeneration then
            if nearestBringConn then nearestBringConn:Disconnect() end
            return
        end
        if isReadyToAttack then
            local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
            local target = currentTargetInstance
            local tHrp = target and target:FindFirstChild("HumanoidRootPart")
            if myHrp and tHrp then
                local enemiesFolder = workspace:FindFirstChild("Enemies")
                if enemiesFolder then
                    local targetMobName = target.Name
                    local mobProfile = GetMobProfileByName(targetMobName)
                    -- Use absolute MobPos from Database if available, else fallback to enemy position
                    local magnetPos = mobProfile and mobProfile.MobPos or tHrp.Position

					if magnetPos then
					    local gatherCFrame = CFrame.new(magnetPos.X, magnetPos.Y, magnetPos.Z)
                        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                            -- ONLY Bring exact same-species enemies to avoid out-of-bounds limits
                            if enemy.Name == targetMobName and IsEnemyVulnerable(enemy, targetMobName) then
                                if enemy.Name ~= "PropHitboxPlaceholder" then
                                    local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
                                    local eHum = enemy:FindFirstChildOfClass("Humanoid")
                                    if eHrp and eHum and eHum.Health > 0 then
                                        local dist = (GetSafePosition(eHrp) - gatherCFrame.Position).Magnitude
                                        if dist <= cfg.BringRadius then
                                            eHrp.CFrame = gatherCFrame
                                            eHrp.AssemblyLinearVelocity = Vector3.zero
                                            eHrp.AssemblyAngularVelocity = Vector3.zero
                                            if eHrp.CanCollide then eHrp.CanCollide = false end
                                            if eHum.PlatformStand == false then eHum.PlatformStand = true end
                                        end
                                    end
                                end
                            end
                        end
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
                if not myHrp then return end

                local now = os.clock()
                if now - lastEvasionTime >= cfg.EvasionTick then
                    lastEvasionTime = now
                    local radius = math.max(0, math.floor(cfg.EvasionRadius))
                    currentEvasionOffset = Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
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
                    targetEnemy = GetTargetEnemy(nil) -- Parameter nil agar Farm Nearest berfungsi
                    currentTargetInstance = targetEnemy
                    if targetEnemy then
                        local h = targetEnemy:FindFirstChildOfClass("Humanoid")
                        lastTargetHealth = h and h.Health or -1
                        lastTargetHealthChangeAt = now
                    end
                end

                if targetEnemy then
                    local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
                    if tHrp then
                        local mobProfile = GetMobProfileByName(targetEnemy.Name)
                        -- Fly chasing this colonys Spawn center to be safe, dont chase escaping enemies out of bounds!
                        local centerPos = mobProfile and mobProfile.MobPos or tHrp.Position

                        local targetDistance = (centerPos - myHrp.Position).Magnitude
                        if targetDistance > 80 then
                            if now - lastEvasionMoveAt >= 0.5 then
                                lastEvasionMoveAt = now
                                TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
                            end
                        else
                            if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                                lastEvasionMoveAt = now
                                TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
                            end
                        end
                        -- Attack can start when character is close enough to MobPos center OR actual enemy
                        isReadyToAttack = (tHrp.Position - myHrp.Position).Magnitude <= cfg.HitRadius or targetDistance <= cfg.HitRadius
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
    local dungeonFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Dungeon")
    if not myHrp or not dungeonFolder then return nil end

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
                -- HANYA kunci pintu exit yang berada dalam jangkauan fisik ruangan/area (Max 5000 stud)
                -- Jika > 5000, itu berarti pintu dari dimensi/stage lain yang dipaksa server.
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
                local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast
                if now - lastAttackAt >= interval then
                    local myChar = GetCharacter()
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if myHrp then
                        ExecuteAttack(myChar, myHrp)
                        lastAttackAt = now
                    end
                end
                if attackSpeedMode == "Super Fast Attack" then task.wait() else task.wait(cfg.ThreadSleep) end
            else
                task.wait(cfg.ThreadSleep)
            end
        end
    end)

    local dungeonBringConn
    dungeonBringConn = RunService.Heartbeat:Connect(function()
        if not isAutoDungeon or not ScriptContext.Running or generation ~= dungeonWorkerGeneration then
            if dungeonBringConn then dungeonBringConn:Disconnect() end
            return
        end

        if isReadyToAttack and isAutoDungeonBring then
            local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
            local target = currentTargetInstance
            local tHrp = target and target:FindFirstChild("HumanoidRootPart")
            if myHrp and tHrp then
                local enemiesFolder = workspace:FindFirstChild("Enemies")
                if enemiesFolder then
                    local magnetPos = tHrp.Position
					if magnetPos then
					    local gatherCFrame = CFrame.new(magnetPos.X, magnetPos.Y, magnetPos.Z)
                        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                            if IsEnemyVulnerable(enemy) then
                                if enemy.Name ~= "PropHitboxPlaceholder" then
                                    local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
                                    local eHum = enemy:FindFirstChildOfClass("Humanoid")
                                    if eHrp and eHum and eHum.Health > 0 then
                                        local dist = (GetSafePosition(eHrp) - gatherCFrame.Position).Magnitude
                                        if dist <= cfg.BringRadius then
                                            eHrp.CFrame = gatherCFrame
                                            eHrp.AssemblyLinearVelocity = Vector3.zero
                                            eHrp.AssemblyAngularVelocity = Vector3.zero
                                            if eHrp.CanCollide then eHrp.CanCollide = false end
                                            if eHum.PlatformStand == false then eHum.PlatformStand = true end
                                        end
                                    end
                                end
                            end
                        end
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
                if not myHrp then return end

                local isDungeon = workspace:GetAttribute("IsDungeonInstance")
                if not isDungeon then
                    isReadyToAttack = false
                    currentTargetInstance = nil
                    if activeTween then activeTween:Cancel(); activeTween = nil end
                    return
                end

                local now = os.clock()
                if now - lastEvasionTime >= cfg.EvasionTick then
                    lastEvasionTime = now
                    local radius = math.max(0, math.floor(cfg.EvasionRadius))
                    currentEvasionOffset = Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
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

                if not targetEnemy or not IsEnemyVulnerable(targetEnemy) then
                    -- HARD CANCEL TWEEN JIKA TARGET MATI/HILANG agar karakter tidak terbang ngawur ke masa lalu
                    if currentTargetInstance then
                        if activeTween then activeTween:Cancel(); activeTween = nil end
                        currentTargetInstance = nil
                    end

                    local closest = nil
                    local shortestDist = math.huge
                    if enemiesFolder then
                        -- PRIORITY OVERRIDE: PropHitboxPlaceholder
                        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                            if enemy.Parent == enemiesFolder and enemy.Name == "PropHitboxPlaceholder" and IsEnemyVulnerable(enemy) then
                                closest = enemy
                                break
                            end
                        end

                        if not closest then
                            for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                                if enemy.Parent == enemiesFolder and IsEnemyVulnerable(enemy) then
                                    local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
                                    if eHrp then
                                        local dist = (GetSafePosition(eHrp) - gatherCFrame.Position).Magnitude
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
                    local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
                    if tHrp then
                        local centerPos = GetSafePosition(tHrp)
                        local targetDistance = (centerPos - myHrp.Position).Magnitude

                        if targetDistance > 2000 then
                            currentTargetInstance = nil
                            targetEnemy = nil
                            isReadyToAttack = false
                            if activeTween then activeTween:Cancel(); activeTween = nil end
                            return
                        end

                        if targetDistance > 80 then
                            TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
                        else
                            if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                                lastEvasionMoveAt = now
                                TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
                            end
                        end
                        isReadyToAttack = targetDistance <= cfg.HitRadius
                    end
                else
                    isReadyToAttack = false
                    currentTargetInstance = nil

                    if isAutoDungeonNext then
                        local exitPos = GetNearestDungeonExit()
                        if exitPos then
                            local dist = (myHrp.Position - exitPos).Magnitude
                            if dist > 15 then
                                TweenTo(CFrame.new(exitPos))
                            else
                                if activeTween then activeTween:Cancel(); activeTween = nil end
                                myHrp.CFrame = CFrame.new(exitPos)
                            end
                        else
                            if activeTween then activeTween:Cancel(); activeTween = nil end
                        end
                    else
                        if activeTween then activeTween:Cancel(); activeTween = nil end
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
                local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast
                local myChar = GetCharacter()
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    local tName = currentTargetInstance and currentTargetInstance.Name or nil
                    ExecuteAttack(myChar, myHrp, false, tName)
                end

                if interval <= 0 then task.wait() else task.wait(interval) end
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
                local enemiesFolder = workspace:FindFirstChild("Enemies")
                if enemiesFolder then
                    local targetMobName = "Lava Golem"
                    local gatherCFrame = tHrp.CFrame

                    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                        if enemy.Name == targetMobName and IsEnemyVulnerable(enemy, targetMobName) then
                            local eHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart", true)
                            local eHum = enemy:FindFirstChildOfClass("Humanoid")

                            if eHrp and eHum and eHum.Health > 0 then
                                local dist = (eHrp.Position - myHrp.Position).Magnitude
                                if dist <= (cfg.BringRadius * 2) then
                                    eHrp.CFrame = gatherCFrame
                                    eHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                    eHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                    if eHrp.CanCollide then eHrp.CanCollide = false end
                                    if not eHum.PlatformStand then eHum.PlatformStand = true end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    ScriptContext:AddConnection(volcanoBringConn)

    task.spawn(function()
        while autoKillVolcano and ScriptContext.Running and generation == workerGeneration do
            local ok, err = pcall(function()
                local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
                if not myHrp then return end

                local now = os.clock()
                if now - lastEvasionTime >= cfg.EvasionTick then
                    lastEvasionTime = now
                    local radius = math.max(0, math.floor(cfg.EvasionRadius))
                    currentEvasionOffset = Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
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
                    local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy:FindFirstChildWhichIsA("BasePart", true)
                    if tHrp then
                        local centerPos = myHrp.Position

                        local targetDistance = (centerPos - myHrp.Position).Magnitude
                        if targetDistance > 80 then
                            if now - lastEvasionMoveAt >= 0.5 then
                                lastEvasionMoveAt = now
                                TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
                            end
                        else
                            if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                                lastEvasionMoveAt = now
                                TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
                            end
                        end

                        isReadyToAttack = (tHrp.Position - myHrp.Position).Magnitude <= cfg.HitRadius or targetDistance <= cfg.HitRadius
                    end
                else
                    currentTargetInstance = nil
                    isReadyToAttack = false
                    if activeTween then activeTween:Cancel(); activeTween = nil end
                end
            end)
            task.wait()
        end
    end)
end

local function GetNearestDungeonExit()
    local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
    local dungeonFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Dungeon")
    if not myHrp or not dungeonFolder then return nil end

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
                if dist < shortestDist and dist < 2500 then
                    shortestDist = dist
                    nearestExitPos = targetPos
                end
            end
        end
    end

    return nearestExitPos
end

local isAutoTorch = false
local autoTorchWorker = 0

local function StartAutoTorch()
    if isAutoTorch then return end
    isAutoTorch = true
    autoTorchWorker = autoTorchWorker + 1
    local gen = autoTorchWorker
    ToggleFloat(true)

    local litTorches = {}

    task.spawn(function()
        while isAutoTorch and ScriptContext.Running and gen == autoTorchWorker do
            local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1); continue end

            local turtle = workspace.Map:FindFirstChild("Turtle")
            local torchesFolder = turtle and turtle:FindFirstChild("QuestTorches")

            if torchesFolder then
                local foundUnlit = false
                -- Cek berurutan 1 sampai 5
                for i = 1, 5 do
                    if not litTorches[i] then
                        local torch = torchesFolder:FindFirstChild("Torch" .. i)
                        if torch and torch:IsA("BasePart") then
                            local dist = (hrp.Position - torch.Position).Magnitude

                            -- Gunakan jarak toleransi tinggi jika punya API UNC, fisik ketat jika tidak
                            local touchDist = hasFireTouch and 300 or 10

                            if dist > touchDist then
                                TweenTo(CFrame.new(torch.Position + Vector3.new(0, 5, 0), torch.Position))
                            else
                                local touched = SafeTouch(torch, hrp, touchDist)
                                if touched then
                                    litTorches[i] = true
                                    if activeTween then activeTween:Cancel(); activeTween = nil end
                                    task.wait(0.5) -- Jeda sebentar sebelum lanjut ke obor berikutnya
                                end
                            end
                            foundUnlit = true
                            break -- Fokus satu per satu berurutan
                        else
                            -- Jika part TorchN tidak ditemukan, asumsikan sudah nyala / hilang
                            litTorches[i] = true
                        end
                    end
                end

                if not foundUnlit then
                    isAutoTorch = false
                    if activeTween then activeTween:Cancel(); activeTween = nil end
                    ToggleFloat(false)
                end
            end
            task.wait()
        end
    end)
end

local isAutoFactory = false
local autoFactoryWorker = 0

local function StartAutoFactory()
    if isAutoFactory then return end
    isAutoFactory = true
    autoFactoryWorker = autoFactoryWorker + 1
    local gen = autoFactoryWorker

    task.spawn(function()
        while isAutoFactory and ScriptContext.Running and gen == autoFactoryWorker do
            local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1); continue end

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
                local tHrp = targetCore:FindFirstChild("HumanoidRootPart") or targetCore:FindFirstChildWhichIsA("BasePart", true)
                if tHrp then
                    ToggleFloat(true)

                    local now = os.clock()
                    if now - lastEvasionTime >= cfg.EvasionTick then
                        lastEvasionTime = now
                        local radius = math.max(0, math.floor(cfg.EvasionRadius))
                        currentEvasionOffset = Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
                    end

                    local centerPos = tHrp.Position
                    local dist = (hrp.Position - centerPos).Magnitude

                    if dist > 80 then
                        TweenTo(CFrame.new(centerPos + Vector3.new(0, cfg.TweenHeight, 0), centerPos))
                    else
                        if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                            lastEvasionMoveAt = now
                            TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
                        end
                    end

                    if dist <= cfg.HitRadius then
                        local myChar = GetCharacter()
                        local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast
                        local timeSinceLastAtk = os.clock() - lastAttackAt

                        if timeSinceLastAtk >= interval then
                            ExecuteAttack(myChar, hrp, false, "Core")
                            lastAttackAt = os.clock()
                        end
                    end
                end
            else
                if activeTween then activeTween:Cancel(); activeTween = nil end
                ToggleFloat(false)
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
                local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast

                if now - lastAttackAt >= interval then
                    local myChar = GetCharacter()
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

                    if myHrp then
                        local tName = currentTargetInstance and currentTargetInstance.Name or nil
                        ExecuteAttack(myChar, myHrp, true, tName)
                        lastAttackAt = now
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

-- [ UI CONFIGURATION & DEFER INITIALIZATION ]
--==================================================
task.spawn(function()
    local Lonum = loadstring(game:HttpGet('https://raw.githubusercontent.com/Difz25x/roblox-project/refs/heads/main/library2.lua'))()

    local Window = Lonum:CreateWindow({
       Name = "Blox Fruits | Lonum",
       Subtitle = "Made by Difzz",
       ConfigurationSaving = { FolderName = "Lonum_Data", FileName = "Cfg_BloxFruits" }
    })

    local MoonPhases = {
        [1] = "1/8 (Waxing Crescent)",
        [2] = "2/8 (First Quarter)",
        [3] = "3/8 (Waxing Gibbous)",
        [4] = "4/8 (Full Moon)",
        [5] = "5/8 (Waning Gibbous)",
        [6] = "6/8 (Last Quarter)",
        [7] = "7/8 (Waning Crescent)",
        [8] = "8/8 (New Moon)"
    }

    local Tabs = {
        Main = Window:CreateTab("Farming & Raid"),
        Dungeon = Window:CreateTab("Dungeon Instance"),
        Sea2 = Window:CreateTab("Sea 2"),
        Sea3 = Window:CreateTab("Sea 3"),
        Travel = Window:CreateTab("Travel & Collect"),
        SeaEvents = Window:CreateTab("Sea Events"),
        Combat = Window:CreateTab("Combat & PVP"),
        Status = Window:CreateTab("Status"),
        Settings = Window:CreateTab("Settings")
    }

    Tabs.Sea3:CreateSection("Tushita Puzzle")
    Tabs.Sea3:CreateToggle({
        Name = "Auto Light Torches",
        CurrentValue = false,
        Flag = "ToggleAutoTorch",
        Callback = function(Value)
            if Value then
                enabled = false
                isAutoRaidKill = false
                isAutoBone = false
                if FarmToggle then FarmToggle:Set(false) end

                StartAutoTorch()
            else
                isAutoTorch = false
                autoTorchWorker = autoTorchWorker + 1
                if activeTween then activeTween:Cancel(); activeTween = nil end
                ToggleFloat(false)
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
                if FarmToggle then FarmToggle:Set(false) end

                StartAutoFactory()
            else
                isAutoFactory = false
                autoFactoryWorker = autoFactoryWorker + 1
                if activeTween then activeTween:Cancel(); activeTween = nil end
                ToggleFloat(false)
            end
        end,
    })

    Tabs.Settings:CreateSection("UI Configuration")
    Tabs.Settings:CreateKeybind({
        Name = "Toggle Menu Key",
        CurrentValue = Enum.KeyCode.K,
        Flag = "ToggleUIKeybind",
        Callback = function(Key)
            if getgenv().LonumObject then
                getgenv().LonumObject:Notify({
                    Title = "Keybind Saved",
                    Content = "UI Toggle set to " .. Key.Name,
                    Duration = 2
                })
            end
        end
    })

    Tabs.Settings:CreateSection("Auto Stats & Abilities")
    Tabs.Settings:CreateToggle({
        Name = "Enable Auto Stats", CurrentValue = false, Flag = "ToggleAutoStats",
        Callback = function(Value) isAutoStatsEnabled = Value end,
    })

    Tabs.Settings:CreateToggle({
        Name = "Enable Auto Ken (Haki)", CurrentValue = false, Flag = "ToggleAutoKen",
        Callback = function(Value) isAutoKenEnabled = Value end,
    })

    Tabs.Settings:CreateDropdown({
        Name = "Select Stat to Upgrade", Options = {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"},
        CurrentOption = {"Melee"}, MultipleOptions = false, Flag = "AutoStatsDropdown",
        Callback = function(Option) selectedStatCategory = Option[1] end,
    })

    Tabs.Main:CreateSection("Auto Farming")
    local FarmToggle = Tabs.Main:CreateToggle({
        Name = "Enable Auto Farm", CurrentValue = false, Flag = "ToggleAutoFarm",
        Callback = function(Value) enabled = Value; if enabled then StartAutoFarm() else StopAutoFarm() end end,
    })

    Tabs.Main:CreateToggle({
        Name = "Auto Attack", CurrentValue = false, Flag = "ToggleStandaloneAttack",
        Callback = function(Value) isAutoAttackEnabled = Value end,
    })

    Tabs.Main:CreateToggle({
        Name = "Auto Farm Nearest", CurrentValue = false, Flag = "ToggleFarmNearest",
        Callback = function(Value)
            farmNearestEnabled = Value
            if Value then
                enabled = false
                if FarmToggle then FarmToggle:Set(false) end
                workerGeneration = workerGeneration + 1

                if activeTween then activeTween:Cancel(); activeTween = nil end
                isReadyToAttack = false
                currentTargetInstance = nil

                StartFarmNearest()
            else
                workerGeneration = workerGeneration + 1
                ToggleFloat(false)
                if activeTween then activeTween:Cancel(); activeTween = nil end
            end
        end,
    })

    Tabs.Main:CreateSlider({
        Name = "Farm Nearest Radius", Range = {100, 5000}, Increment = 50, CurrentValue = 5000,
        Flag = "SliderFarmNearestRadius", Callback = function(Value) farmNearestRadius = Value end,
    })

    local bossNames = {}
    for _, boss in ipairs(BOSSES) do table.insert(bossNames, boss.Name) end

    Tabs.Main:CreateSection("Material Farming")
    Tabs.Main:CreateToggle({
        Name = "Auto Spin Bones", CurrentValue = false, Flag = "ToggleAutoSpinBones",
        Callback = function(Value)
            isAutoSpinBones = Value
        end,
    })
    
    Tabs.Main:CreateButton({
        Name = "Spin Bones 1x",
        Callback = function()
            task.spawn(function()
                pcall(function()
                    local CommF_ = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
                    if CommF_ then
                        local bonesCount = CommF_:InvokeServer("Bones", "Check")
                        if type(bonesCount) == "number" and bonesCount >= 50 then
                            local result = CommF_:InvokeServer("Bones", "Buy", 1, 1)
                            if getgenv().LonumObject then
                                getgenv().LonumObject:Notify({
                                    Title = "Spin Bones Success",
                                    Content = "Successfully spun! Remaining Bones: " .. tostring(bonesCount - 50),
                                    Duration = 3,
                                    Image = 4483362458
                                })
                            end
                        else
                            if getgenv().LonumObject then
                                getgenv().LonumObject:Notify({
                                    Title = "Spin Bones Failed",
                                    Content = "Bones tidak cukup/anda terkena limit 10 spin per hari",
                                    Duration = 3,
                                    Image = 4483362458
                                })
                            end
                        end
                    end
                end)
            end)
        end,
    })

    Tabs.Main:CreateToggle({
        Name = "Auto Farm Bone (Sea 3)", CurrentValue = false, Flag = "ToggleAutoBone",
        Callback = function(Value)
            isAutoBone = Value
            if Value then
                -- Disable Auto Farm normal
                enabled = false
                FarmToggle:Set(false)
                isAutoCocoa = false

                workerGeneration = workerGeneration + 1

                if activeTween then activeTween:Cancel(); activeTween = nil end
                isReadyToAttack = false
                currentTargetInstance = nil
                lastTargetPos = nil
                StartAutoBone()
            else
                workerGeneration = workerGeneration + 1
                ToggleFloat(false)
                if activeTween then activeTween:Cancel(); activeTween = nil end
            end
        end,
    })

    Tabs.Main:CreateToggle({
        Name = "Auto Farm Cocoa (Sea 3)", CurrentValue = false, Flag = "ToggleAutoCocoa",
        Callback = function(Value)
            isAutoCocoa = Value
            if Value then
                enabled = false
                isAutoBone = false
                FarmToggle:Set(false)

                workerGeneration = workerGeneration + 1

                if activeTween then activeTween:Cancel(); activeTween = nil end
                isReadyToAttack = false
                currentTargetInstance = nil
                lastTargetPos = nil
                StartAutoCocoa()
            else
                workerGeneration = workerGeneration + 1
                ToggleFloat(false)
                if activeTween then activeTween:Cancel(); activeTween = nil end
            end
        end,
    })

    Tabs.Main:CreateToggle({
        Name = "Boss Hunter", CurrentValue = false, Flag = "ToggleBossHunter",
        Callback = function(Value)
            isBossHunterEnabled = Value; isReadyToAttack = false; currentTargetInstance = nil; lastTargetPos = nil
            if activeTween then activeTween:Cancel(); activeTween = nil end
        end,
    })

    Tabs.Main:CreateSection("Auto Raid")
    Tabs.Main:CreateToggle({
        Name = "Enable Auto Raid", CurrentValue = false, Flag = "ToggleAutoRaidMaster",
        Callback = function(Value) 
            isAutoRaidKill = Value
            if Value then
                StartAutoRaid()
            else
                raidWorkerGeneration = raidWorkerGeneration + 1
                if activeTween then activeTween:Cancel(); activeTween = nil end
                ToggleFloat(false)
            end
        end,
    })

    Tabs.Main:CreateToggle({
        Name = "Auto Raid Attack", CurrentValue = false, Flag = "ToggleRaidAttack",
        Callback = function(Value) isAutoRaidAttack = Value end,
    })

    Tabs.Main:CreateToggle({
        Name = "Auto Raid Bring", CurrentValue = false, Flag = "ToggleRaidBring",
        Callback = function(Value) isAutoRaidBring = Value end,
    })

    Tabs.Main:CreateToggle({
        Name = "Auto Next Island", CurrentValue = false, Flag = "ToggleRaidNextIsland",
        Callback = function(Value) isAutoRaidNextIsland = Value end,
    })

    Tabs.Main:CreateSection("Boss & Targeting")


    Tabs.Main:CreateDropdown({
        Name = "Boss Target", Options = bossNames, CurrentOption = {bossNames[1] or ""},
        MultipleOptions = false, Flag = "BossTargetDrop",
        Callback = function(Option)
            selectedBossName = Option[1]; isReadyToAttack = false; currentTargetInstance = nil; lastTargetPos = nil
            if activeTween then activeTween:Cancel(); activeTween = nil end
        end,
    })

    Tabs.Main:CreateDropdown({
        Name = "Attack Speed", Options = {"Fast Attack", "Super Fast Attack"}, CurrentOption = {"Fast Attack"},
        MultipleOptions = false, Flag = "AtkSpeedDrop",
        Callback = function(Option) attackSpeedMode = Option[1] end,
    })

    Tabs.Main:CreateToggle({
        Name = "Multi Mob Damage", CurrentValue = isMultiMobDamage, Flag = "MultiMobTog",
        Callback = function(Value) isMultiMobDamage = Value end,
    })

    -- Sea Events Tab
    Tabs.SeaEvents:CreateSection("Boat")

    Tabs.SeaEvents:CreateDropdown({
        Name = "Select Boat to Buy",
        Options = {"Dinghy", "Sloop", "MarineBrigade", "MarineGrandBrigade", "Guardian"},
        CurrentOption = {"Dinghy"},
        MultipleOptions = false,
        Flag = "BoatTypeDrop",
        Callback = function(Option)
            cfg.boatType = Option[1]
        end,
    })

    Tabs.SeaEvents:CreateToggle({
        Name = "Auto Boat", CurrentValue = false, Flag = "AutoBoatEnabled",
        Callback = function(Value)
            cfg.autoBoat = Value
            if not Value then
                if activeTween then activeTween:Cancel(); activeTween = nil end
                ToggleFloat(false)
                -- Force unstuck
                local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Velocity = Vector3.zero end
            end
        end,
    })

    Tabs.SeaEvents:CreateToggle({
        Name = "Enable Boat Speed Mod", CurrentValue = false, Flag = "ToggleBoatMod",
        Callback = function(Value) cfg.boatSpeedMod = Value end,
    })

    Tabs.SeaEvents:CreateSlider({
        Name = "Boat Max Speed", Range = {50, 300}, Increment = 10, CurrentValue = 300,
        Flag = "SliderBoatMaxSpeed", Callback = function(Value) cfg.boatMaxSpeed = Value end,
    })

    Tabs.SeaEvents:CreateSection("Kitsune Island")
    Tabs.SeaEvents:CreateToggle({
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
                            for _, part in ipairs(workspace:GetChildren()) do
                                if not AutoEmber then break end

                                if part.Name == "EmberTemplate" then
                                    local safePos = GetSafePosition(part)
                                    if safePos then
                                        myHrp.CFrame = CFrame.new(safePos)
                                        task.wait(0.1)
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

    Tabs.SeaEvents:CreateSection("Prehistoric Island")
    Tabs.SeaEvents:CreateToggle({
        Name = "Auto Start Prehistoric", CurrentValue = false, Flag = "AutoPrehistoricStart",
        Callback = function(Value)
            if not Value then return end -- Abaikan jika toggle dimatikan atau sekadar inisialisasi awal false

            local prehistoricIsland = nil
            local nearestDistance = math.huge
            local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
            if not myHrp or not workspace:FindFirstChild("Map") then return end

            for _, datamodel in ipairs(workspace.Map:GetChildren()) do
                if datamodel.Name == "PrehistoricIsland" and datamodel:IsA("Model") then
                    local prehistoricIslandPos = GetSafePosition(datamodel)
                    local distance = (myHrp.Position - prehistoricIslandPos).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        prehistoricIsland = datamodel
                    end
                end
            end

            if not prehistoricIsland then return end -- Abaikan jika map belum di render / beda Sea

            local startPromptPart = prehistoricIsland:FindFirstChild("Core") and prehistoricIsland.Core:FindFirstChild("ActivationPrompt")
            if not startPromptPart then return end

            local startPromptLocation = GetSafePosition(startPromptPart)
            TweenTo(CFrame.new(startPromptLocation))

            if (myHrp.Position - startPromptLocation).Magnitude < 10 then
                SafeProximity(startPromptPart)
            end
        end,
    })

    Tabs.SeaEvents:CreateToggle({
        Name = "Auto Kill Enemy", CurrentValue = false, Flag = "AutoKillEnemy",
        Callback = function(Value)
            autoKillVolcano = Value
            if Value then
                enabled = false
                if FarmToggle then FarmToggle:Set(false) end
                workerGeneration = workerGeneration + 1

                if activeTween then activeTween:Cancel(); activeTween = nil end
                isReadyToAttack = false
                currentTargetInstance = nil

                StartAutoKillVolcano()
            else
                workerGeneration = workerGeneration + 1
                ToggleFloat(false)
                if activeTween then activeTween:Cancel(); activeTween = nil end
            end
        end,
    })


    Tabs.SeaEvents:CreateToggle({
        Name = "Auto Fill Volcano", CurrentValue = false, Flag = "AutoFillVolcano",
        Callback = function(Value)
            if not Value then return end

            local prehistoricIsland = nil
            local nearestDistance = math.huge
            local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
            if not myHrp or not workspace:FindFirstChild("Map") then return end

            for _, datamodel in ipairs(workspace.Map:GetChildren()) do
                if datamodel.Name == "PrehistoricIsland" then
                    local distance = (myHrp.Position - GetSafePosition(datamodel)).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        prehistoricIsland = datamodel
                    end
                end
            end

            if not prehistoricIsland or not prehistoricIsland:FindFirstChild("Core") then return end

            local Rocks = prehistoricIsland.Core:FindFirstChild("VolcanoRocks")
            if not Rocks then return end

            for _, rock in ipairs(Rocks:GetChildren()) do
                for _, volcanoRock in ipairs(rock:GetChildren()) do
                    if volcanoRock.Name == "volcanorock" then
                        local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
                        local volcanoRockPos = GetSafePosition(volcanoRock)
                        TweenTo(CFrame.new(volcanoRockPos))

                        local currentFruit = game:GetService("Players").LocalPlayer.Data.DevilFruit
                        function IsCooldown(skillName)
                            local playerGui = localPlayer:FindFirstChild("PlayerGui")
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

                        myHrp.CFrame = CFrame.lookAt(myHrp.Position, Vector3.new(volcanoRockPos.X, myHrp.Position.Y, volcanoRockPos.Z))
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

    Tabs.SeaEvents:CreateSection("Sea Events")
    Tabs.SeaEvents:CreateToggle({
        Name = "Auto Sail", CurrentValue = false, Flag = "AutoSailEnabled",
        Callback = function(Value)
            cfg.autoSail = Value
            if not Value then
                if activeTween then activeTween:Cancel(); activeTween = nil end
                ToggleFloat(false)
                local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Velocity = Vector3.zero end
            end
        end,
    })

    Tabs.SeaEvents:CreateToggle({
        Name = "Auto Sea Beast", CurrentValue = false, Flag = "AutoSeaBeastEnabled",
        Callback = function(Value) cfg.autoSeaBeast = Value; if not Value and activeTween then activeTween:Cancel(); activeTween = nil; ToggleFloat(false) end end,
    })

    Tabs.Travel:CreateSection("World Events")
    Tabs.Travel:CreateToggle({
        Name = "Auto Collect Chest", CurrentValue = false, Flag = "AutoChestEnabled",
        Callback = function(Value) cfg.autoChest = Value; if not Value and activeTween then activeTween:Cancel(); activeTween = nil; ToggleFloat(false) end end,
    })

    Tabs.Travel:CreateToggle({
        Name = "Auto Fruit Finder", CurrentValue = false, Flag = "AutoFruitEnabled",
        Callback = function(Value) cfg.autoFruit = Value; if not Value and activeTween then activeTween:Cancel(); activeTween = nil; ToggleFloat(false) end end,
    })

    Tabs.Travel:CreateToggle({
        Name = "Auto Dodge Projectiles", CurrentValue = false, Flag = "AutoDodgeEnabled",
        Callback = function(Value) cfg.dodgeEnabled = Value end,
    })

    Tabs.Travel:CreateSection("Server & Teleport")
    Tabs.Travel:CreateButton({
        Name = "Server Hop Now",
        Callback = function()
            ServerHop()
        end,
    })

    Tabs.Travel:CreateToggle({
        Name = "Find Low Player Server", CurrentValue = false, Flag = "LowPlayerServerEnabled",
        Callback = function(Value) cfg.lowPlayerServer = Value end,
    })

    Tabs.Travel:CreateSlider({
        Name = "Max Players for Hop", Range = {1, 20}, Increment = 1, CurrentValue = 8,
        Flag = "MaxPlayersForHop", Callback = function(Value) cfg.maxPlayersForHop = Value end,
    })

    Tabs.Settings:CreateSection("Weapon & Mastery")

    Tabs.Settings:CreateDropdown({
        Name = "Weapon Category", Options = {"Melee", "Sword", "Fruit", "Gun"}, CurrentOption = {"Melee"},
        MultipleOptions = false, Flag = "WepCatDrop",
        Callback = function(Option) cfg.WeaponCategory = Option[1] end,
    })

    Tabs.Settings:CreateToggle({
        Name = "Auto Mastery", CurrentValue = cfg.AutoMastery, Flag = "AutoMastTog",
        Callback = function(Value) cfg.AutoMastery = Value end,
    })

    Tabs.Settings:CreateDropdown({
        Name = "Mastery Category", Options = {"Melee", "Sword", "Fruit", "Gun"}, CurrentOption = {"Melee"},
        MultipleOptions = false, Flag = "MastCatDrop",
        Callback = function(Option) cfg.MasteryCategory = Option[1] end,
    })

    Tabs.Settings:CreateSlider({
        Name = "Mastery Health Switch (%)", Range = {1, 95}, Increment = 1, CurrentValue = cfg.MasteryHealth,
        Flag = "MastHealthSlider",
        Callback = function(Value) cfg.MasteryHealth = Value end,
    })

    Tabs.Settings:CreateSection("Ranges & Evasion")

    Tabs.Settings:CreateSlider({
        Name = "Bring Radius", Range = {100, 1000}, Increment = 10, CurrentValue = cfg.BringRadius,
        Flag = "BringRadSlider", Callback = function(Value) cfg.BringRadius = Value end,
    })

    Tabs.Settings:CreateSlider({
        Name = "Max Pull Range", Range = {100, 1000}, Increment = 10, CurrentValue = cfg.MaxPullRange,
        Flag = "PullRangeSlider", Callback = function(Value) cfg.MaxPullRange = Value end,
    })

    Tabs.Settings:CreateSlider({
        Name = "Hit Radius", Range = {10, 150}, Increment = 5, CurrentValue = cfg.HitRadius,
        Flag = "HitRadSlider", Callback = function(Value) cfg.HitRadius = Value end,
    })

    Tabs.Settings:CreateSlider({
        Name = "Evasion Radius", Range = {0, 100}, Increment = 1, CurrentValue = cfg.EvasionRadius,
        Flag = "EvasionRadSlider", Callback = function(Value) cfg.EvasionRadius = Value end,
    })

    Tabs.Settings:CreateSection("Tween & Timing")

    Tabs.Settings:CreateSlider({
        Name = "Tween Speed", Range = {100, 600}, Increment = 10, CurrentValue = cfg.TweenSpeed,
        Flag = "TweenSpdSlider", Callback = function(Value) cfg.TweenSpeed = Value end,
    })

    Tabs.Settings:CreateSlider({
        Name = "Tween Height", Range = {0, 50}, Increment = 1, CurrentValue = cfg.TweenHeight,
        Flag = "TweenHeightSlider", Callback = function(Value) cfg.TweenHeight = Value end,
    })

    Tabs.Settings:CreateSlider({
        Name = "Evasion Tick (x100)", Range = {1, 100}, Increment = 1, CurrentValue = cfg.EvasionTick * 100,
        Flag = "EvasionTickSlider", Callback = function(Value) cfg.EvasionTick = Value / 100 end,
    })

    Tabs.Settings:CreateSlider({
        Name = "Stuck Timeout", Range = {2, 30}, Increment = 1, CurrentValue = 3,
        Flag = "StuckTimeSlider", Callback = function(Value) cfg.StuckTimeout = Value end,
    })

    Tabs.Dungeon:CreateSection("Auto Dungeon Settings")

    Tabs.Dungeon:CreateToggle({
        Name = "Enable Auto Dungeon", CurrentValue = false, Flag = "ToggleAutoDungeonMaster",
        Callback = function(Value)
            isAutoDungeon = Value
            if Value then
                enabled = false
                isAutoRaidKill = false
                isAutoBone = false
                if FarmToggle then FarmToggle:Set(false) end
                StartAutoDungeon()
            else
                dungeonWorkerGeneration = dungeonWorkerGeneration + 1
                if activeTween then activeTween:Cancel(); activeTween = nil end
                ToggleFloat(false)
            end
        end,
    })

    Tabs.Dungeon:CreateToggle({
        Name = "Auto Dungeon Attack", CurrentValue = false, Flag = "ToggleDungAttack",
        Callback = function(Value) isAutoDungeonAttack = Value end,
    })

    Tabs.Dungeon:CreateToggle({
        Name = "Auto Dungeon Bring", CurrentValue = false, Flag = "ToggleDungBring",
        Callback = function(Value) isAutoDungeonBring = Value end,
    })

    Tabs.Dungeon:CreateToggle({
        Name = "Auto Next Dungeon Stage", CurrentValue = false, Flag = "ToggleDungNext",
        Callback = function(Value) isAutoDungeonNext = Value end,
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
        CurrentOption = {islandOptions[1] or ""},
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
                teleportIslandWorker = teleportIslandWorker + 1
                if activeTween then activeTween:Cancel(); activeTween = nil end
                ToggleFloat(false)
                return
            end

            if selectedIslandToTeleport == "" or selectedIslandToTeleport == "No islands found (Error)" then
                if getgenv().LonumObject then
                    getgenv().LonumObject:Notify({
                        Title = "Teleportasi Gagal",
                        Content = "Silakan pilih pulau terlebih dahulu dari dropdown.",
                        Duration = 3,
                        Image = 4483362458
                    })
                end
                return
            end

            enabled = false
            isAutoBone = false
            isAutoCocoa = false
            workerGeneration = workerGeneration + 1
            if FarmToggle then FarmToggle:Set(false) end

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
                        Image = 4483362458
                    })
                end

                task.spawn(function()
                    while isTeleportingToIsland and ScriptContext.Running and gen == teleportIslandWorker do
                        local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
                        if hrp then
                            ToggleFloat(true)
                            local dist = (hrp.Position - safeCFrame.Position).Magnitude
                            if dist > 50 then
                                TweenTo(safeCFrame)
                            else
                                -- Sudah sampai di pulau tujuan
                                isTeleportingToIsland = false
                                if activeTween then activeTween:Cancel(); activeTween = nil end
                                ToggleFloat(false)
                            end
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end,
    })

    -- ==========================================
    -- [ COMBAT & PVP SECTION ]
    -- ==========================================
    Tabs.Combat:CreateSection("Player Selection")

    local function GetPlayerList()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                table.insert(list, p.Name)
            end
        end
        if #list == 0 then table.insert(list, "No Players Found") end
        return list
    end

    local selectedPlayerToHunt = ""
    local PlayerDropdown = Tabs.Combat:CreateDropdown({
        Name = "Select Target Player",
        Options = GetPlayerList(),
        CurrentOption = {GetPlayerList()[1] or ""},
        MultipleOptions = false,
        Flag = "CombatPlayerDrop",
        Callback = function(Option)
            selectedPlayerToHunt = Option[1]
        end,
    })

    Tabs.Combat:CreateButton({
        Name = "Refresh Player List",
        Callback = function()
            PlayerDropdown:Refresh(GetPlayerList())
        end,
    })

    Tabs.Combat:CreateSection("PVP Toggles")

    local isTweeningToPlayer = false
    local tweenPlayerConn = nil
    Tabs.Combat:CreateToggle({
        Name = "Tween To Player",
        CurrentValue = false,
        Flag = "ToggleTweenToPlayer",
        Callback = function(Value)
            isTweeningToPlayer = Value
            if Value then
                enabled = false
                isAutoRaidKill = false
                isAutoBone = false
                if FarmToggle then FarmToggle:Set(false) end

                tweenPlayerConn = RunService.Heartbeat:Connect(function()
                    if not isTweeningToPlayer then
                        if tweenPlayerConn then tweenPlayerConn:Disconnect(); tweenPlayerConn = nil end
                        return
                    end

                    local targetPlayer = Players:FindFirstChild(selectedPlayerToHunt)
                    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local tHrp = targetPlayer.Character.HumanoidRootPart
                        TweenTo(tHrp.CFrame * CFrame.new(0, cfg.TweenHeight, 0))
                    else
                        if activeTween then activeTween:Cancel(); activeTween = nil end
                    end
                end)
                ScriptContext:AddConnection(tweenPlayerConn)
            else
                if tweenPlayerConn then tweenPlayerConn:Disconnect(); tweenPlayerConn = nil end
                if activeTween then activeTween:Cancel(); activeTween = nil end
                ToggleFloat(false)
            end
        end,
    })

    Tabs.Combat:CreateToggle({
        Name = "Spectate Player",
        CurrentValue = false,
        Flag = "ToggleSpectatePlayer",
        Callback = function(Value)
            local cam = workspace.CurrentCamera
            if Value then
                local targetPlayer = Players:FindFirstChild(selectedPlayerToHunt)
                if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
                    cam.CameraSubject = targetPlayer.Character.Humanoid
                    if getgenv().LonumObject then
                        getgenv().LonumObject:Notify({
                            Title = "Spectating",
                            Content = "Now spectating " .. targetPlayer.Name,
                            Duration = 3, Image = 4483362458
                        })
                    end
                else
                    if getgenv().LonumObject then
                        getgenv().LonumObject:Notify({
                            Title = "Spectate Failed",
                            Content = "Target player not found or dead.",
                            Duration = 3, Image = 4483362458
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

    local isAimbotEnabled = false
    local aimbotConn = nil
    Tabs.Combat:CreateToggle({
        Name = "Aimbot To Player (Look At)",
        CurrentValue = false,
        Flag = "ToggleAimbotPlayer",
        Callback = function(Value)
            isAimbotEnabled = Value
            if Value then
                aimbotConn = RunService.RenderStepped:Connect(function()
                    if not isAimbotEnabled then
                        if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
                        return
                    end

                    local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
                    local targetPlayer = Players:FindFirstChild(selectedPlayerToHunt)

                    if myHrp and targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local tHrp = targetPlayer.Character.HumanoidRootPart
                        myHrp.CFrame = CFrame.lookAt(myHrp.Position, Vector3.new(tHrp.Position.X, myHrp.Position.Y, tHrp.Position.Z))
                    end
                end)
                ScriptContext:AddConnection(aimbotConn)
            else
                if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
            end
        end,
    })

    -- ==========================================
    -- [ STATUS & DEBUG SECTION ]
    -- ==========================================
    Tabs.Status:CreateSection("Debug Information")
    local isDebugActive = false
    local debugWorker = 0

    local DebugHUD = Lonum:CreateFloatingHUD({Title = "Server Live Status"})
    DebugHUD:SetVisible(false)

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
                    while isDebugActive and ScriptContext.Running and gen == debugWorker do
                        local lighting = game:GetService("Lighting")
                        local phaseNum = lighting:GetAttribute("MoonPhase") or 0
                        local isBlueMoon = lighting:GetAttribute("IsBlueMoon") or false

                        local phaseName = MoonPhases[phaseNum] or (tostring(phaseNum) .. " (Unknown)")
                        local blueMoonStatus = isBlueMoon and "✅ ACTIVE (KITSUNE SPAWNED!)" or "❌ Inactive"

                        DebugHUD:UpdateText(string.format("Moon Phase: %s\nBlue Moon: %s", phaseName, blueMoonStatus))
                        task.wait(1)
                    end
                end)
            else
                isDebugActive = false
                debugWorker = debugWorker + 1
            end
        end,
    })

    Lonum:Notify({
        Title = "Mega Farm Loaded",
        Content = "Script is ready with optimized cross-platform support.",
        Duration = 5
    })

    getgenv().LonumObject = Lonum
end)
