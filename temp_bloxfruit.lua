--==================================================
-- [ INIT & OVERDRIVE ]
--==================================================
local SCRIPT_ID = "BloxFruits_MegaFarm_Overdrive"

pcall(function()
    local coreGui = gethui and gethui() or game:GetService("CoreGui")
    for _, gui in pairs(coreGui:GetChildren()) do
        if gui.Name == "Rayfield" or gui.Name == "Rayfield-Old" or string.match(gui.Name, "Rayfield") then
            gui:Destroy()
        end
    end
end)

if getgenv().RayfieldObject then
    pcall(function() getgenv().RayfieldObject:Destroy() end)
    getgenv().RayfieldObject = nil
end

if getgenv().Fluent_Overdrive then
	pcall(function() end)
	getgenv().Fluent_Overdrive = nil
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
	    -- Batalkan semua penerbangan
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

local player = Players.LocalPlayer

-- Anti-AFK Fallbacks
ScriptContext:AddConnection(player.Idled:Connect(function()
	if ScriptContext.Running then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
		VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		task.wait(1)
		VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
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
	EvasionTick = 0.35,

	TargetRefresh = 0,
	BringInterval = 0,
	AttackIntervalFast = 0.12,
	AttackIntervalSuper = 0.01,
	MaxAdditionalTargets = 12,
	EvasionMoveInterval = 0.12,
	ThreadSleep = 0.025,

	StuckTimeout = 10,

	autoBoat = false,
	autoSail = false,
	autoSeaBeast = false,
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
local isAutoNextIsland = false
local currentRaidIsland = 1

-- State Variables
local enabled = false
local isAutoAttackEnabled = false
local isAutoStatsEnabled = false
local isCollectingChest = false
local isAutoKenEnabled = false
local selectedStatCategory = "Melee"
local bypassRender = false

local attacking = false
local isReadyToAttack = false

local activeTween = nil
local lastTargetPos = nil
local currentEvasionOffset = Vector3.new(0, cfg.TweenHeight, 0)
local lastEvasionTime = 0
local lastPlayerPos = nil

local currentTargetInstance = nil
local targetLockStartTime = 0
local enemyBlacklist = {}

local cachedWeapon = nil
local cachedWeaponCategory = nil
local lastAttackAt = 0
local lastTargetRefreshAt = 0
local lastEvasionMoveAt = 0
local workerGeneration = 5

local teleportTravelKey = nil
local teleportTravelStartedAt = 0
local teleportTravelOrigin = nil
local TELEPORT_TRAVEL_ARRIVE_RADIUS = 120
local cachedEnemiesFolder = nil

local isBossHunterEnabled = false
local selectedBossName = nil

-- Sea Event Variables
local lastDodgeTime = 0
local currentBoat = nil
local currentIsland = nil
local fruitWaypoints = {}
local chestWaypoints = {}

local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF")
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


local function ApplyRenderBypass()
    pcall(function()
        local env = getrenv and getrenv() or _G
        local Reparent = env.require(game:GetService("ReplicatedStorage").Reparent)
        if Reparent and Reparent.Unparent and not getgenv().OldUnparent then
            getgenv().OldUnparent = Reparent.Unparent
            Reparent.Unparent = function(...)
                if bypassRender then return end
                return getgenv().OldUnparent(...)
            end
        end
    end)
end

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
	{ Min = 2125, Max = 2149, Quest = "IceCreamIslandQuest", Stage = 1, Name = "Ice Cream Chefs", Mob = "Ice Cream Chef", Count = 8, NPC = Vector3.new(-820, 66, -10966), MobPos = Vector3.new(-872, 66, -10920) },
	{ Min = 2150, Max = 2199, Quest = "IceCreamIslandQuest", Stage = 2, Name = "Ice Cream Commanders", Mob = "Ice Cream Commander", Count = 8, NPC = Vector3.new(-820, 66, -10966), MobPos = Vector3.new(-558, 112, -11291) },
	{ Min = 2200, Max = 2224, Quest = "CakeQuest1", Stage = 1, Name = "Cookie Crafters", Mob = "Cookie Crafter", Count = 8, NPC = Vector3.new(-2021, 38, -12028), MobPos = Vector3.new(-2374, 38, -12125) },
	{ Min = 2225, Max = 2249, Quest = "CakeQuest1", Stage = 2, Name = "Cake Guards", Mob = "Cake Guard", Count = 8, NPC = Vector3.new(-2021, 38, -12028), MobPos = Vector3.new(-1598, 44, -12244) },
	{ Min = 2250, Max = 2274, Quest = "CakeQuest2", Stage = 1, Name = "Baking Staff", Mob = "Baking Staff", Count = 8, NPC = Vector3.new(-1927, 38, -12842), MobPos = Vector3.new(-1887, 78, -12998) },
	{ Min = 2275, Max = 2299, Quest = "CakeQuest2", Stage = 2, Name = "Head Bakers", Mob = "Head Baker", Count = 8, NPC = Vector3.new(-1927, 38, -12842), MobPos = Vector3.new(-2216, 82, -12869) },
	{ Min = 2300, Max = 2324, Quest = "ChocQuest1", Stage = 1, Name = "Cocoa Warriors", Mob = "Cocoa Warrior", Count = 8, NPC = Vector3.new(233, 30, -12201), MobPos = Vector3.new(-21, 80, -12352) },
	{ Min = 2325, Max = 2349, Quest = "ChocQuest1", Stage = 2, Name = "Chocolate Bar Battlers", Mob = "Chocolate Bar Battler", Count = 8, NPC = Vector3.new(233, 30, -12201), MobPos = Vector3.new(582, 78, -12463) },
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

-- Fungsi tersentralisasi untuk menangani teleport NPC Submerged ke/dari laut dalam
local function HandleSubmerged(targetPos)
    local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local isCurrentlySubmerged = (hrp.Position.Y < -1000)
    local isTargetSubmerged = (targetPos.Y < -1000)

    if isCurrentlySubmerged and not isTargetSubmerged then
        pcall(function()
            local net = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net")
            net:WaitForChild("RF/SubmarineWorkerSpeak"):InvokeServer("TravelToTikiOutpost")
        end)
        task.wait(1)
        return true -- Return true artinya sedang di-handle NPC, hentikan gerak sementera
    elseif not isCurrentlySubmerged and isTargetSubmerged then
        pcall(function()
            local net = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net")
            net:WaitForChild("RF/SubmarineWorkerSpeak"):InvokeServer("TravelToSubmergedIsland")
        end)
        task.wait(1)
        return true
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
    if HandleSubmerged(targetPos) then
        if activeTween then activeTween:Cancel(); activeTween = nil end
        return
    end

    ToggleFloat(true)

    local distance = (hrp.Position - targetPos).Magnitude
    if distance < 8 then
        if activeTween then activeTween:Cancel(); activeTween = nil end
        return
    end

    -- Mencegah Stuttering: Jika tween sudah jalan menuju titik yang sama, biarkan saja!
    if lastTargetPos and (targetPos - lastTargetPos).Magnitude < 3 then
        if activeTween and activeTween.PlaybackState == Enum.PlaybackState.Playing then
            return
        end
    end
    lastTargetPos = targetPos

    local duration = math.max(distance / cfg.TweenSpeed, 0.06)

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
    if #islandList == 0 then table.insert(islandList, "Tidak ada pulau (Error)") end
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
            local distance = (hrp.Position - island.HumanoidRootPart.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestIsland = island
            end
        end
    end
    return nearestIsland
end

local function GetBoat()
    local boats = {}
    if not Workspace:FindFirstChild("Boats") then return nil end
    for _, obj in pairs(Workspace.Boats:GetChildren()) do
        if obj:FindFirstChild("VehicleSeat") then
            table.insert(boats, obj)
        end
    end
    local nearestBoat = nil
    local shortestDistance = math.huge
    local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, boat in pairs(boats) do
            local distance = (hrp.Position - boat.VehicleSeat.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestBoat = boat
            end
        end
    end
    return nearestBoat
end

local function BuyBoat()
    local boatShop = Workspace:FindFirstChild("BoatShop")
    local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
    if boatShop and hrp then
        local boatModel = boatShop:FindFirstChild("BoatModel")
        if boatModel then
            local buyEvent = boatModel:FindFirstChild("BuyBoat")
            if buyEvent then
                firetouchinterest(hrp, buyEvent, 0)
                firetouchinterest(hrp, buyEvent, 1)
                return true
            end
        end
    end
    return false
end

local function BoardBoat(boat)
    local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
    local hum = GetHumanoid()
    if boat and boat:FindFirstChild("VehicleSeat") and hrp and hum then
        local seat = boat.VehicleSeat
        local distance = (hrp.Position - seat.Position).Magnitude

        if distance < 15 then
            hum.Sit = true
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            return true
        else
            hum:MoveTo(seat.Position)
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

            firetouchinterest(hrp, nearestFruit, 0)
            firetouchinterest(hrp, nearestFruit, 1)
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
        if getgenv().RayfieldObject then
            getgenv().RayfieldObject:Notify({
                Title = "Server Hop",
                Content = "Mencari server baru, mohon tunggu...",
                Duration = 3,
                Image = 4483362458
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

local preferredHitParts = { "Head", "UpperTorso", "LowerTorso", "ModelHitbox", "HumanoidRootPart" }
local meleeNames = {
	Combat = true, ["Dark Step"] = true, Electro = true, ["Water Kung Fu"] = true, ["Fishman Karate"] = true,
	["Dragon Breath"] = true, Superhuman = true, ["Death Step"] = true, ["Sharkman Karate"] = true, ["Electric Claw"] = true,
	["Dragon Talon"] = true, Godhuman = true, ["Sanguine Art"] = true,
}

local function GetHitPart(model)
	if not model then return nil end
	for _, name in ipairs(preferredHitParts) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then return part end
	end
	return model:FindFirstChildWhichIsA("BasePart")
end

local function IsEnemyVulnerable(targetChar, targetMobName)
	if not targetChar or not targetChar.Parent or enemyBlacklist[targetChar] then return false end
	if targetMobName and targetChar.Name ~= targetMobName then return false end
	local hum = targetChar:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	return (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")) ~= nil
end

local function GetTargetEnemy(mobName)
	local closest, shortestDist = nil, math.huge
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")

	if enemiesFolder and myHrp and mobName then
		for _, enemy in ipairs(enemiesFolder:GetChildren()) do
			if string.lower(enemy.Name) == string.lower(mobName) and IsEnemyVulnerable(enemy, mobName) then
				local eHrp = enemy:FindFirstChild("HumanoidRootPart")
				if eHrp then
					local dist = (eHrp.Position - myHrp.Position).Magnitude
					if dist < shortestDist then
						shortestDist = dist
						closest = enemy
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
	if c and not c:GetAttribute("BusoEnabled") then pcall(function() CommF:InvokeServer("Buso") end) end
end

local lastSkillFiredAt = 0
local skillKeys = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V, Enum.KeyCode.F}
local skillIndex = 1

local function TriggerSkills(weaponCategory)
	if weaponCategory == "Fruit" or weaponCategory == "Gun" then
		local now = os.clock()
		if now - lastSkillFiredAt >= 0.5 then
			lastSkillFiredAt = now
			task.spawn(function()
				local key = skillKeys[skillIndex]
				VirtualInputManager:SendKeyEvent(true, key, false, game)
				task.wait(0.1)
				VirtualInputManager:SendKeyEvent(false, key, false, game)
				skillIndex = skillIndex + 1
				if skillIndex > #skillKeys then skillIndex = 1 end
			end)
		end
	end
end

--==================================================
-- [ AUTO FARM BRAIN ]
--==================================================

local function AttackThread(generation)
    task.spawn(function()
        while ScriptContext.Running and generation == workerGeneration do
            if enabled or isAutoRaidKill or isAutoAttackEnabled then
                local now = os.clock()
                local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast

                if now - lastAttackAt >= interval then
                    local myChar = GetCharacter()
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    
                    if myHrp then
                        local targetCategory = cfg.WeaponCategory
                        if cfg.AutoMastery then
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
                        
                        local weapon = cachedWeapon
                        if not weapon or weapon.Parent ~= myChar or not IsToolMatching(weapon, targetCategory) then
                            weapon = EquipWeapon(targetCategory)
                        end
                        
                        if weapon then
                            local isPhysical = IsToolMatching(weapon, "Melee") or IsToolMatching(weapon, "Sword")
                            if isPhysical then
                                EnableBuso()
                                local enemiesFolder = workspace:FindFirstChild("Enemies")
                                if enemiesFolder then
                                    local mainTargetHitPart = nil
                                    local additionalHits = {}
                                    local hitTargets = {}
                                    
                                    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                                        if IsEnemyVulnerable(enemy) then
                                            local eHrp = enemy:FindFirstChild("HumanoidRootPart")
                                            if eHrp and (eHrp.Position - myHrp.Position).Magnitude <= cfg.HitRadius then
                                                local ePart = GetHitPart(enemy)
                                                if ePart then
                                                    table.insert(hitTargets, ePart)
                                                    if not mainTargetHitPart then
                                                        mainTargetHitPart = ePart
                                                    else
                                                        if isMultiMobDamage then
                                                            table.insert(additionalHits, ePart)
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    
                                    if #hitTargets > 0 then
                                        task.spawn(function()
                                            pcall(function()
                                                if RegisterAttackEvent then RegisterAttackEvent:FireServer(0) end
                                                if RegisterHitEvent then RegisterHitEvent:FireServer(mainTargetHitPart, additionalHits, nil, sessionSecret) end
                                            end)
                                        end)
                                        
                                        if isMultiMobDamage then
                                            for _, ePart in ipairs(hitTargets) do
                                                task.spawn(function()
                                                    pcall(function()
                                                        if RegisterAttackEvent then RegisterAttackEvent:FireServer(0) end
                                                        if RegisterHitEvent then RegisterHitEvent:FireServer(ePart, {}, nil, sessionSecret) end
                                                    end)
                                                end)
                                            end
                                        end
                                        
                                        TriggerSkills(targetCategory)
                                        lastAttackAt = now
                                    end
                                end
                            else
                                TriggerSkills(targetCategory)
                                lastAttackAt = now
                            end
                        end
                    end
                end
            end
            task.wait(cfg.ThreadSleep)
        end
    end)
end

local function StartAutoFarm()
	if attacking then return end
	attacking = true
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
								if CommF then
									if HasActiveQuest() then CommF:InvokeServer("AbandonQuest") end
									CommF:InvokeServer("StartQuest", bossProfile.Quest, bossProfile.Stage or 1)
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
					pcall(function() CommF:InvokeServer("AbandonQuest") end)
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
					pcall(function() CommF:InvokeServer("StartQuest", profile.Quest, profile.Stage) end)
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

				if not hasQuestUI or not isCorrectQuestOnUI then
					isReadyToAttack = false
					currentTargetInstance = nil
					if (myHrp.Position - profile.NPC).Magnitude > 8 then
						TweenTo(CFrame.new(profile.NPC))
					else
						if activeTween then activeTween:Cancel(); activeTween = nil end
						if hasQuestUI and not isCorrectQuestOnUI then
							CommF:InvokeServer("AbandonQuest")
							QuestCache.IsActive = false
							QuestCache.Finished = true
							isReadyToAttack = false
							currentTargetInstance = nil
							return
						end
						CommF:InvokeServer("StartQuest", profile.Quest, profile.Stage)
					end
				else
					local targetEnemy = currentTargetInstance
					if not targetEnemy or not IsEnemyVulnerable(targetEnemy, profile.Mob) then
						targetEnemy = GetTargetEnemy(profile.Mob)
						currentTargetInstance = targetEnemy
						lastTargetRefreshAt = now
						if targetEnemy then targetLockStartTime = now end
					end

					if targetEnemy then
						local tHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
						if tHrp then
							local targetDistance = (tHrp.Position - myHrp.Position).Magnitude
							if targetDistance > 80 and (tHrp.Position - profile.MobPos).Magnitude > 80 then
								TweenTo(CFrame.new(tHrp.Position + currentEvasionOffset, tHrp.Position))
							else
								if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
									lastEvasionMoveAt = now
									TweenTo(CFrame.new(tHrp.Position + currentEvasionOffset, tHrp.Position))
								end
							end
							isReadyToAttack = targetDistance <= cfg.HitRadius
						end
					else
						currentTargetInstance = nil
						isReadyToAttack = false
						TweenTo(CFrame.new(profile.MobPos + currentEvasionOffset, profile.MobPos))
					end
				end
			end)

			if not ok then
				currentTargetInstance = nil
				isReadyToAttack = false
			end
			task.wait(0.05)
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

	if activeTween then activeTween:Cancel(); activeTween = nil end
	attacking = false
end

ScriptContext:AddConnection(RunService.Stepped:Connect(function()
    if ScriptContext.Running then
        local c = player.Character
        if c then
			local hrp = c:FindFirstChild("HumanoidRootPart")
            -- Pastikan tween benar-benar berjalan, bukan sisa variabel yang selesai
            local isTweening = activeTween and activeTween.PlaybackState == Enum.PlaybackState.Playing
            -- Hanya noclip ketika fitur movement otomatis menyala
            if isTweening or enabled or isAutoRaidKill or isAutoNextIsland or cfg.autoChest or cfg.autoFruit then
                for _, v in ipairs(c:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                end
            end
        end
    end
end))

ScriptContext:AddConnection(player.CharacterAdded:Connect(function()
	cachedWeapon = nil
	cachedEnemiesFolder = nil
	currentTargetInstance = nil
	isReadyToAttack = false

	task.wait(0.75)
	if enabled and ScriptContext.Running then
		attacking = false
		StartAutoFarm()
	end
end))

--==================================================
-- [ BACKGROUND TASKS (HEARTBEAT) ]
--==================================================

ScriptContext:AddConnection(RunService.Heartbeat:Connect(function(deltaTime)
	if not ScriptContext.Running then return end

    if cfg.autoBoat and not currentBoat then
        currentBoat = GetBoat()
        if not currentBoat then
            if BuyBoat() then
                currentBoat = GetBoat()
            end
        else
            BoardBoat(currentBoat)
        end
    end

    if cfg.autoSail and currentBoat then
        currentIsland = GetNearestIsland()
        if currentIsland then
            local boatSeat = currentBoat:FindFirstChild("VehicleSeat")
            if boatSeat then
                local targetPosition = currentIsland.HumanoidRootPart.Position
                local hum = GetHumanoid()
                if hum then hum:MoveTo(targetPosition) end
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
					local frontPos = (myHrp.CFrame * CFrame.new(0, 0, -5)).Position
					local targetY = myHrp.Position.Y - cfg.TweenHeight
					for _, enemy in ipairs(cachedEnemiesFolder:GetChildren()) do
						if enemy.Name == targetMobName and IsEnemyVulnerable(enemy, targetMobName) then
							local eHrp = enemy:FindFirstChild("HumanoidRootPart")
							local eHum = enemy:FindFirstChildOfClass("Humanoid")
							if eHrp and eHum and eHum.Health > 0 then
								local dist = (eHrp.Position - myHrp.Position).Magnitude
								if dist <= (cfg.BringRadius * 2) then
									eHrp.CFrame = CFrame.new(frontPos.X, targetY, frontPos.Z)
									eHrp.AssemblyLinearVelocity = Vector3.zero
									eHrp.AssemblyAngularVelocity = Vector3.zero
									eHrp.Size = Vector3.new(60, 60, 60)
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
end))

task.spawn(function()
    while task.wait(1) do
        if not ScriptContext.Running then break end
        if cfg.autoFruit then ScanForFruits() end
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
                    if CommF then CommF:InvokeServer("AddPoint", selectedStatCategory, 1) end
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
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                            task.wait(0.1)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        end
                    end)
                end
            end
        end
    end
end)

local raidLockedTarget = nil

local function StartAutoRaidKill()
    task.spawn(function()
        while ScriptContext.Running do
            if isAutoRaidKill and not (enabled and isReadyToAttack) then
                local now = os.clock()
                local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast

                if now - lastAttackAt >= interval then
                    local myChar = GetCharacter()
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local weapon = myChar and myChar:FindFirstChildOfClass("Tool")

                    if myHrp and weapon then
                        local isPhysical = IsToolMatching(weapon, "Melee") or IsToolMatching(weapon, "Sword")

                        if isPhysical then
                            local enemiesFolder = workspace:FindFirstChild("Enemies")
                            if enemiesFolder then
                                if not raidLockedTarget or not IsEnemyVulnerable(raidLockedTarget) then
                                    local closest, shortestDist = nil, 800
                                    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                                        if IsEnemyVulnerable(enemy) then
                                            local eHrp = enemy:FindFirstChild("HumanoidRootPart")
                                            if eHrp then
                                                local dist = (eHrp.Position - myHrp.Position).Magnitude
                                                if dist < shortestDist then
                                                    shortestDist = dist
                                                    closest = enemy
                                                end
                                            end
                                        end
                                    end
                                    raidLockedTarget = closest
                                end

                                if raidLockedTarget then
                                    local tHrp = raidLockedTarget:FindFirstChild("HumanoidRootPart")
                                    if tHrp then
                                        local targetDist = (tHrp.Position - myHrp.Position).Magnitude

                                        if now - lastEvasionTime >= cfg.EvasionTick then
                                            lastEvasionTime = now
                                            local radius = math.max(0, math.floor(cfg.EvasionRadius))
                                            currentEvasionOffset = Vector3.new(math.random(-radius, radius), cfg.TweenHeight, math.random(-radius, radius))
                                        end

                                        if targetDist > cfg.HitRadius then
                                            TweenTo(CFrame.new(tHrp.Position + currentEvasionOffset, tHrp.Position))
                                        else
                                            if now - lastEvasionMoveAt >= cfg.EvasionMoveInterval then
                                                lastEvasionMoveAt = now
                                                TweenTo(CFrame.new(tHrp.Position + currentEvasionOffset, tHrp.Position))
                                            end
                                        end

                                        if targetDist <= cfg.HitRadius then
                                            EnableBuso()
                                            AttackThread(workerGeneration)
                                            for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                                                if IsEnemyVulnerable(enemy) then
                                                    local eHrp = enemy:FindFirstChild("HumanoidRootPart")
                                                    if eHrp and (eHrp.Position - myHrp.Position).Magnitude <= cfg.HitRadius then
                                                        local eHitPart = GetHitPart(enemy)
                                                        if eHitPart then
                                                            task.spawn(function()
                                                                pcall(function()
                                                                    if RegisterAttackEvent then RegisterAttackEvent:FireServer(0) end
                                                                    if RegisterHitEvent then RegisterHitEvent:FireServer(eHitPart, {}, nil, sessionSecret) end
                                                                end)
                                                            end)
                                                            if not isMultiMobDamage then break end
                                                        end
                                                    end
                                                end
                                            end
                                            lastAttackAt = now
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait(cfg.ThreadSleep)
        end
    end)
end

local function StartAutoNextIsland()
    task.spawn(function()
        while ScriptContext.Running do
            if isAutoNextIsland then
                local myChar = GetCharacter()
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local raidMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("RaidMap")
                
                if myHrp and raidMap then
                    local enemiesFolder = workspace:FindFirstChild("Enemies")
                    local enemiesAlive = false
                    
                    if enemiesFolder then
                        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                            local eHrp = enemy:FindFirstChild("HumanoidRootPart")
                            if eHrp and (eHrp.Position - myHrp.Position).Magnitude < 800 and IsEnemyVulnerable(enemy) then
                                enemiesAlive = true
                                break
                            end
                        end
                    end
                    
                    if not enemiesAlive then
                        local targetIslandName = "RaidIsland" .. tostring(currentRaidIsland)
                        local nearestIsland = nil
                        local shortestDist = math.huge
                        
                        for _, island in ipairs(raidMap:GetChildren()) do
                            if island.Name == targetIslandName then
                                local iPos = island:IsA("Model") and island:GetBoundingBox().Position
                                local dist = (myHrp.Position - iPos).Magnitude
                                if dist < shortestDist then
                                    shortestDist = dist
                                    nearestIsland = island
                                end
                            end
                        end
                        
                        if nearestIsland and shortestDist <= 7000 then
                            local islandPos = nearestIsland:IsA("Model") and nearestIsland:GetBoundingBox().Position
                            
                            if shortestDist > 100 then
                                TweenTo(CFrame.new(islandPos + Vector3.new(0, 50, 0)))
                            else
                                currentRaidIsland = currentRaidIsland + 1
                                if currentRaidIsland > 5 then currentRaidIsland = 1 end
                            end
                        end
                    end
                end
            end
            task.wait(cfg.ThreadSleep)
        end
    end)
end

StartAutoRaidKill()
StartAutoNextIsland()

local function StartStandaloneAutoAttackThread()
    task.spawn(function()
        while ScriptContext.Running do
            if isAutoAttackEnabled and not (enabled and isReadyToAttack) then
                local now = os.clock()
                local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper or cfg.AttackIntervalFast

                if now - lastAttackAt >= interval then
                    local myChar = GetCharacter()
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local weapon = myChar and myChar:FindFirstChildOfClass("Tool")

                    if myHrp and weapon then
                        local isPhysical = IsToolMatching(weapon, "Melee") or IsToolMatching(weapon, "Sword")

                        if isPhysical then
                            local enemiesFolder = workspace:FindFirstChild("Enemies")
                            if enemiesFolder then
                                EnableBuso()
                                local hitCount = 0
                                for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                                    if IsEnemyVulnerable(enemy) then
                                        local eHrp = enemy:FindFirstChild("HumanoidRootPart")
                                        if eHrp and (eHrp.Position - myHrp.Position).Magnitude <= cfg.HitRadius then
                                            local eHitPart = GetHitPart(enemy)
                                            if eHitPart then
                                                hitCount = hitCount + 1
                                                task.spawn(function()
                                                    pcall(function()
                                                        if RegisterAttackEvent then RegisterAttackEvent:FireServer(0) end
                                                        if RegisterHitEvent then RegisterHitEvent:FireServer(eHitPart, {}, nil, sessionSecret) end
                                                    end)
                                                end)
                                                if not isMultiMobDamage then break end
                                            end
                                        end
                                    end
                                end
                                if hitCount > 0 then lastAttackAt = now end
                            end
                        end
                    end
                end
            end
            task.wait(cfg.ThreadSleep)
        end
    end)
end

StartStandaloneAutoAttackThread()

-- [ UI CONFIGURATION & DEFER INITIALIZATION ]
--==================================================
task.defer(function()
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

    local Window = Rayfield:CreateWindow({
       Name = "Blox Fruits | Lonum",
       LoadingTitle = "Loading...",
       LoadingSubtitle = "Made by Difzz",
       ConfigurationSaving = { Enabled = true, FolderName = "Lonum_Data", FileName = "Cfg_BloxFruits" },
       Discord = { Enabled = true, Invite = "https://discord.gg/h7ncnCncJA", RememberJoins = true },
       KeySystem = false
    })

    local Tabs = {
        Main = Window:CreateTab("Farming & Raid", 4483362458),
        Travel = Window:CreateTab("Travel & Collect", 4483362458),
        Settings = Window:CreateTab("Settings", 4483362458)
    }

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
        Name = "Auto Attack (Aura)", CurrentValue = false, Flag = "ToggleStandaloneAttack",
        Callback = function(Value) isAutoAttackEnabled = Value end,
    })

    Tabs.Main:CreateKeybind({
        Name = "Toggle Bind (PC Only)", CurrentKeybind = "G", HoldToInteract = false, Flag = "ToggleBind",
        Callback = function() enabled = not enabled; FarmToggle:Set(enabled) end,
    })

    local bossNames = {}
    for _, boss in ipairs(BOSSES) do table.insert(bossNames, boss.Name) end

    Tabs.Main:CreateToggle({
        Name = "Boss Hunter", CurrentValue = false, Flag = "ToggleBossHunter",
        Callback = function(Value)
            isBossHunterEnabled = Value; isReadyToAttack = false; currentTargetInstance = nil; lastTargetPos = nil
            if activeTween then activeTween:Cancel(); activeTween = nil end
        end,
    })

    Tabs.Main:CreateSection("Auto Raid (Dungeon)")
    Tabs.Main:CreateToggle({
        Name = "Auto Raid Kill", CurrentValue = false, Flag = "ToggleAutoRaidKill",
        Callback = function(Value) isAutoRaidKill = Value; if not Value and activeTween then activeTween:Cancel(); activeTween = nil; ToggleFloat(false) end end,
    })
    Tabs.Main:CreateToggle({
        Name = "Auto Next Island", CurrentValue = false, Flag = "ToggleAutoNextIsland",
        Callback = function(Value) isAutoNextIsland = Value; if Value then currentRaidIsland = 1 else if activeTween then activeTween:Cancel(); activeTween = nil; ToggleFloat(false) end end end,
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

    Tabs.Travel:CreateSection("Sea Events")
    Tabs.Travel:CreateToggle({
        Name = "Auto Boat", CurrentValue = false, Flag = "AutoBoatEnabled",
        Callback = function(Value) cfg.autoBoat = Value; if not Value and activeTween then activeTween:Cancel(); activeTween = nil; ToggleFloat(false) end end,
    })

    Tabs.Travel:CreateToggle({
        Name = "Auto Sail", CurrentValue = false, Flag = "AutoSailEnabled",
        Callback = function(Value) cfg.autoSail = Value; if not Value and activeTween then activeTween:Cancel(); activeTween = nil; ToggleFloat(false) end end,
    })

    Tabs.Travel:CreateToggle({
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
        Name = "Server Hop Sekarang",
        Callback = function()
            ServerHop()
        end,
    })

    Tabs.Travel:CreateToggle({
        Name = "Cari Server Sepi", CurrentValue = false, Flag = "LowPlayerServerEnabled",
        Callback = function(Value) cfg.lowPlayerServer = Value end,
    })

    Tabs.Travel:CreateSlider({
        Name = "Max Players untuk Hop", Range = {1, 20}, Increment = 1, CurrentValue = 8,
        Flag = "MaxPlayersForHop", Callback = function(Value) cfg.maxPlayersForHop = Value end,
    })

    Tabs.Settings:CreateSection("System Optimization")
    Tabs.Settings:CreateToggle({
        Name = "Bypass Map Render Limit", CurrentValue = false, Flag = "BypassRenderTog",
        Callback = function(Value)
            bypassRender = Value
            if Value then
                ApplyRenderBypass()
                pcall(function()
                    local env = getrenv and getrenv() or _G
                    for _, child in pairs(game.Players.LocalPlayer.PlayerScripts:GetDescendants()) do
                        if child:IsA("ModuleScript") and child.Name:match("Controller") then
                            local mod = env.require(child)
                            if mod and type(mod) == "table" and mod.LoadMap then mod:LoadMap() end
                        end
                    end
                end)

                -- CFrame teleport loop to force render all islands
                task.spawn(function()
                    local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    
                    local originalCFrame = hrp.CFrame
                    local originLocations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
                    
                    if originLocations then
                        if getgenv().RayfieldObject then
                            getgenv().RayfieldObject:Notify({
                                Title = "Rendering Map",
                                Content = "Memuat semua pulau... Karakter mungkin akan lag sesaat.",
                                Duration = 3,
                                Image = 4483362458
                            })
                        end

                        for _, island in ipairs(originLocations:GetChildren()) do
                            if island:IsA("BasePart") or island:IsA("Model") then
                                local islandCFrame = island:IsA("Model") and island:GetPivot() or island.CFrame
                                hrp.CFrame = islandCFrame * CFrame.new(0, 150, 0)
                                task.wait(0.05)
                            end
                        end
                        
                        -- Kembalikan ke posisi semula
                        hrp.CFrame = originalCFrame
                        
                        if getgenv().RayfieldObject then
                            getgenv().RayfieldObject:Notify({
                                Title = "Render Selesai",
                                Content = "Semua pulau berhasil dimuat & dikunci!",
                                Duration = 3,
                                Image = 4483362458
                            })
                        end
                    end
                end)
            end
        end,
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
        Name = "Stuck Timeout", Range = {5, 30}, Increment = 1, CurrentValue = cfg.StuckTimeout,
        Flag = "StuckTimeSlider", Callback = function(Value) cfg.StuckTimeout = Value end,
    })

    local islandOptions = GetIslandLocations()
    
    local selectedIslandToTeleport = ""
    Tabs.Travel:CreateDropdown({
        Name = "Pilih Pulau",
        Options = islandOptions,
        CurrentOption = {islandOptions[1] or ""},
        MultipleOptions = false,
        Flag = "TeleportIslandDrop",
        Callback = function(Option)
            selectedIslandToTeleport = Option[1]
        end,
    })

    Tabs.Travel:CreateToggle({
        Name = "Auto Teleport",
        CurrentValue = false,
        Flag = "ToggleTeleportIsland",
        Callback = function(Value)
            if not Value then
                -- Matikan Teleport
                if activeTween then
                    activeTween:Cancel()
                    activeTween = nil
                end
                ToggleFloat(false)
                return
            end

            -- Mulai Teleport
            if selectedIslandToTeleport == "" or selectedIslandToTeleport == "Tidak ada pulau (Error)" then 
                if getgenv().RayfieldObject then
                    getgenv().RayfieldObject:Notify({
                        Title = "Teleportasi Gagal",
                        Content = "Silakan pilih pulau terlebih dahulu dari dropdown.",
                        Duration = 3,
                        Image = 4483362458
                    })
                end
                return 
            end
            
            -- Mematikan state auto farm
            enabled = false
            if FarmToggle then FarmToggle:Set(false) end
            
            local origin = workspace:FindFirstChild("_WorldOrigin")
            local locations = origin and origin:FindFirstChild("Locations")
            local targetIsland = locations and locations:FindFirstChild(selectedIslandToTeleport)
            
            if targetIsland then
                local targetCFrame = targetIsland:IsA("Model") and targetIsland:GetPivot() or targetIsland.CFrame
                -- Tambahkan offset vertical agar tiba di atas tanah
                local safeCFrame = targetCFrame * CFrame.new(0, 150, 0)
                
                TweenTo(safeCFrame)
                
                if getgenv().RayfieldObject then
                    getgenv().RayfieldObject:Notify({
                        Title = "Teleportasi Dimulai",
                        Content = "Terbang menuju " .. selectedIslandToTeleport .. ". Matikan toggle untuk berhenti.",
                        Duration = 3,
                        Image = 4483362458
                    })
                end
            end
        end,
    })

    Rayfield:Notify({
        Title = "Mega Farm Loaded",
        Content = "Script siap digunakan dengan optimasi anti-lag dan zero-delay bring mobs.",
        Duration = 5, Image = 4483362458
    })

    getgenv().RayfieldObject = Rayfield
end)
