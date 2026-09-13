if not math.ldexp then
	math.ldexp = function(x, n)
		return x * 2 ^ n
	end
end
if not math.frexp then
	math.frexp = function(x)
		if x == 0 then
			return 0, 0
		end
		local exp = math.floor(math.log(math.abs(x)) / math.log(2)) + 1
		local mantissa = x / 2 ^ exp
		return mantissa, exp
	end
end
if not loadstring and load then
	loadstring = load
end
if not loadstring then
	loadstring = function(s)
		return load(s)
	end
end

while not game:IsLoaded() do
	task.wait()
end

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
	isAutoGrapplingHook = false,
	isAutoPearl = false,
	isAutoCrowd = false,
	isAutoMagmaEvent = false,
	isTweeningToPlayer = false,
	WeaponCategory = "Melee",

	AutoMastery = false,
	MasteryCategory = "Melee",
	MasteryHealth = 30,

	UsePortal = false,
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
	AttackIntervalFast = 0.14,
	AttackIntervalSuper = 0.11,
	AttackIntervalBeta = 0,
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
	cframeSpeed = false,
	cframeSpeedValue = 50,
	dodgeDistance = 15,
	dodgeCooldown = 1,

	isAutoBerry = false,
	autoBerryWorker = 0,
	isTeleportingToIsland = false,

	isAutoHaze = false,
	isAutoFarmMagnet = false,
}

local Runtime = {
	activeTween = nil,
	activeCarrier = nil,
	activeFollowConn = nil,
	RegisterHitEvent = nil,
	RegisterAttackEvent = nil,
	activeMagnetTweens = {},
	lastFindAnywhereAt = 0,
	emptyTargetThrottle = {},
	lastMagnetTick = 0,
	lastDripMamaCheck = 0,
	cachedDripMamaStatus = "unknown",
	skillKeys = { Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V, Enum.KeyCode.F },
	skillIndex = 1,
}
local syn = getgenv and getgenv().syn or nil
FarmToggle = nil
local GetSafePosition = nil

Sea3Portals = {
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
		if Runtime.activeTween then
			Runtime.activeTween:Cancel()
			Runtime.activeTween = nil
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

Players = game:GetService("Players")
Workspace = game:GetService("Workspace")
ReplicatedStorage = game:GetService("ReplicatedStorage")
UserInputService = game:GetService("UserInputService")
TweenService = game:GetService("TweenService")
RunService = game:GetService("RunService")
VirtualInputManager = game:GetService("VirtualInputManager")
VirtualUser = game:GetService("VirtualUser")
HttpService = game:GetService("HttpService")
TeleportService = game:GetService("TeleportService")
Lighting = game:GetService("Lighting")

local Paths = setmetatable({
	Enemies = workspace:FindFirstChild("Enemies"),
	Characters = workspace:FindFirstChild("Characters"),
	Map = workspace:FindFirstChild("Map"),
	SeaBeasts = workspace:FindFirstChild("SeaBeasts"),
	Boats = workspace:FindFirstChild("Boats"),
	WorldOrigin = workspace:FindFirstChild("_WorldOrigin"),
	ChestModels = workspace:FindFirstChild("ChestModels"),
	BananaSpawner = workspace:FindFirstChild("BananaSpawner"),
}, {
	__index = function(self, key)
		local found = workspace:FindFirstChild(key)
		if found then
			rawset(self, key, found)
			return found
		end
		return nil
	end,
})

UncAliases = {
	queue_on_teleport = { "queue_on_teleport", "queueonteleport" },
	firetouchinterest = { "firetouchinterest", "touchinterest" },
	fireproximityprompt = { "fireproximityprompt", "proximityprompt" },
	setclipboard = { "setclipboard", "toclipboard", "set_clipboard" },
	sethiddenproperty = { "sethiddenproperty", "set_hidden_property", "set_hidden_prop" },
	gethiddenproperty = { "gethiddenproperty", "get_hidden_property", "get_hidden_prop" },
	getnilinstances = { "getnilinstances", "get_nil_instances" },
	getinstances = { "getinstances", "get_instances" },
	getinstancesbyclass = { "getinstancesbyclass", "get_instances_by_class" },
	getconnections = { "getconnections", "get_connections" },
	readfile = { "readfile", "read_file" },
	writefile = { "writefile", "write_file" },
	isfile = { "isfile", "is_file" },
	isfolder = { "isfolder", "is_folder" },
	makefolder = { "makefolder", "make_folder" },

	-- sUNC / modern UNC compatibility
	gethui = { "gethui" },
	getsenv = { "getsenv" },
	getgc = { "getgc" },
	filtergc = { "filtergc" },
	getloadedmodules = { "getloadedmodules" },
	getrunningscripts = { "getrunningscripts" },
	getscripts = { "getscripts" },
	cloneref = { "cloneref" },
	compareinstances = { "compareinstances" },
	getrawmetatable = { "getrawmetatable" },
	setrawmetatable = { "setrawmetatable" },
	isreadonly = { "isreadonly" },
	isscriptable = { "isscriptable" },
	getrenderproperty = { "getrenderproperty" },
	setrenderproperty = { "setrenderproperty" },
	isrenderobj = { "isrenderobj" },
	cleardrawcache = { "cleardrawcache" },
	restorefunction = { "restorefunction" },
	clonefunction = { "clonefunction" },
	iscclosure = { "iscclosure" },
	islclosure = { "islclosure" },
	isexecutorclosure = { "isexecutorclosure" },
	getfunctionhash = { "getfunctionhash" },
	getscriptbytecode = { "getscriptbytecode", "dumpstring" },
	getscriptclosure = { "getscriptclosure" },
	getscriptfromthread = { "getscriptfromthread" },
	getcallingscript = { "getcallingscript" },
	getcallbackvalue = { "getcallbackvalue" },
	decompile = { "decompile" },
	firesignal = { "firesignal" },
	replicatesignal = { "replicatesignal" },
	setfpscap = { "setfpscap" },
}

local function useUnc(name, argsTable)
	argsTable = argsTable or {}

	Runtime.ExecutorFunctionCache = Runtime.ExecutorFunctionCache or {}
	local cache = Runtime.ExecutorFunctionCache[name]

	if cache == false then
		return false, nil, nil
	end

	if type(cache) == "function" then
		local ok, res = pcall(cache, unpack(argsTable))
		if ok then
			return true, res, cache
		end
	end

	local candidates = UncAliases[name] or { name }

	local function resolve(root, path)
		if type(root) ~= "table" then
			return nil
		end

		local value = root
		for segment in string.gmatch(path, "[^%.]+") do
			value = rawget(value, segment)
			if value == nil then
				return nil
			end
		end

		return type(value) == "function" and value or nil
	end

	for _, fnName in ipairs(candidates) do
		local func = nil

		pcall(function()
			func = resolve(_G, fnName)
				or (getgenv and resolve(getgenv(), fnName))
				or (shared and resolve(shared, fnName))
		end)

		if not func and string.find(fnName, ".", 1, true) then
			local rootName = string.match(fnName, "^[^%.]+")
			local env = nil

			pcall(function()
				env = getfenv()
			end)

			if env then
				func = resolve(env, fnName)
			end

			if not func and rootName then
				local debugRoot = rawget(_G, rootName)
					or (getgenv and rawget(getgenv(), rootName))
					or (shared and rawget(shared, rootName))
				func = resolve(debugRoot, fnName)
			end
		elseif not func then
			pcall(function()
				func = getfenv()[fnName]
			end)
		end

		if type(func) == "function" then
			Runtime.ExecutorFunctionCache[name] = func
			local ok, res = pcall(func, unpack(argsTable))
			return ok, res, func
		end
	end

	if type(syn) == "table" then
		for _, fnName in ipairs(candidates) do
			local clean = string.gsub(fnName, "^syn%_", "")
			if type(syn[clean]) == "function" then
				Runtime.ExecutorFunctionCache[name] = syn[clean]
				local ok, res = pcall(syn[clean], unpack(argsTable))
				return ok, res, syn[clean]
			end
		end
	end

	if type(fluxus) == "table" then
		for _, fnName in ipairs(candidates) do
			local clean = string.gsub(fnName, "^fluxus%_", "")
			if type(fluxus[clean]) == "function" then
				Runtime.ExecutorFunctionCache[name] = fluxus[clean]
				local ok, res = pcall(fluxus[clean], unpack(argsTable))
				return ok, res, fluxus[clean]
			end
		end
	end

	Runtime.ExecutorFunctionCache[name] = false
	return false, nil, nil
end

local hasFireTouch = select(3, useUnc("firetouchinterest")) ~= nil
local hasProximity = select(3, useUnc("fireproximityprompt")) ~= nil

local function SafeGetInstancesByClass(className)
	local ok, res = useUnc("getinstancesbyclass", { className })
	if ok and type(res) == "table" then
		return res
	end
	local list = {}
	if Paths.Enemies then
		for _, v in ipairs(Paths.Enemies:GetChildren()) do
			if v:IsA(className) then
				table.insert(list, v)
			end
		end
	end
	if Paths.Characters then
		for _, v in ipairs(Paths.Characters:GetChildren()) do
			if v:IsA(className) then
				table.insert(list, v)
			end
		end
	end
	return list
end

local function SafeGetNilInstances()
	if type(getnilinstances) == "function" then
		local ok, res = pcall(getnilinstances)
		if ok and type(res) == "table" then
			return res
		end
	end
	return {}
end

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
	player.OnTeleport:Connect(function(State)
		if cfg.AutoExecute and State == Enum.TeleportState.Started then
			local cacheBuster = "?v=" .. tostring(os.time())
			local scriptPayload = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/Difz25x/roblox-project/main/temp_bloxfruit.lua'
				.. cacheBuster
				.. '"))()'
			useUnc("queue_on_teleport", { scriptPayload })
		end
	end)
end
SetupAutoExecute()

task.spawn(function()
	-- Purge stale teleport anchors left by any previous script instance.
	-- Their RenderStepped follow-loops disconnect once the part is gone.
	pcall(function()
		for _, container in ipairs({ workspace, workspace:FindFirstChild("_WorldOrigin") }) do
			if container then
				for _, child in ipairs(container:GetChildren()) do
					if child.Name == "PartTele" then
						child:Destroy()
					end
				end
			end
		end
	end)

	task.spawn(function()
		while ScriptContext.Running do
			pcall(function()
				if sethiddenproperty then
					sethiddenproperty(player, "SimulationRadius", math.huge)
					sethiddenproperty(player, "MaxSimulationRadius", math.huge)
				end

				-- Purge any anchor that drifted into the void (stale/poisoned instance)
				for _, container in ipairs({ workspace, workspace:FindFirstChild("_WorldOrigin") }) do
					if container then
						for _, child in ipairs(container:GetChildren()) do
							if child.Name == "PartTele" and child:IsA("BasePart") then
								local cp = child.Position
								if cp.Y < -500 or math.abs(cp.X) > 200000 or math.abs(cp.Z) > 200000 then
									child:Destroy()
								end
							end
						end
					end
				end

				-- Watchdog: never let a stuck teleport flag freeze all movement forever
				if isTeleporting then
					if not getgenv().LonumTeleportStuckAt then
						getgenv().LonumTeleportStuckAt = os.clock()
					elseif os.clock() - getgenv().LonumTeleportStuckAt > 40 then
						getgenv().LonumTeleportStuckAt = nil
						isTeleporting = false
					end
				else
					getgenv().LonumTeleportStuckAt = nil
				end
			end)
			task.wait(1)
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

	game.Players.LocalPlayer.CharacterAdded:Connect(function(c)
		OptimizeMovement()
	end)
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

attackSpeedMode = "Fast Attack"
dungeonWorkerGeneration = 10
currentRaidIsland = 1

isAutoFarm = false
selectedStatCategory = "Melee"
bypassRender = false

Runtime.activeTween = nil
lastTargetPos = nil
currentEvasionOffset = Vector3.new(0, cfg.TweenHeight, 0)
lastEvasionTime = 0
lastAbandonAttempt = 0
lastPlayerPos = nil

currentTargetInstance = nil
lastTargetHealth = -1
lastTargetHealthChangeAt = 0
enemyBlacklist = {}

cachedWeapon = nil
cachedWeaponCategory = nil
lastAttackAt = 0
lastTargetRefreshAt = 0
lastEvasionMoveAt = 0
TELEPORT_TRAVEL_ARRIVE_RADIUS = 120
cachedEnemiesFolder = nil
selectedBossName = nil
farmNearestEnabled = false
farmNearestRadius = 5000

State = {
	WorkerGen = 10,
	TravelKey = nil,
	TravelStartedAt = 0,
	TravelOrigin = nil,
	LastDodgeTime = 0,
	CurrentBoat = nil,
	CurrentIsland = nil,
	FruitWaypoints = {},
	ChestWaypoints = {},
	AutoKillVolcano = false,
	AutoEmber = false,
	EliteHunterGen = 0,
}

local CommF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local CommE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE")

local shadowRemote = nil
local shadowId = nil

local function ScanShadowRemote()
	if shadowRemote and shadowId then
		return
	end
	local scanDirs = {
		ReplicatedStorage:FindFirstChild("Util"),
		ReplicatedStorage:FindFirstChild("Common"),
		ReplicatedStorage:FindFirstChild("Remotes"),
	}

	for _, folder in ipairs(scanDirs) do
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
					shadowId = child:GetAttribute("Id")
					shadowRemote = child
					return
				end
			end
		end
	end
end

task.defer(ScanShadowRemote)

local cachedOffset = -1
local cachedEncMethod = "RE/RegisterHit"
local function GetEncryptedRegisterHit()
	local offset = math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
	if offset ~= cachedOffset then
		cachedOffset = offset
		cachedEncMethod = string.gsub("RE/RegisterHit", ".", function(c)
			return string.char(bit32.bxor(string.byte(c), offset))
		end)
	end
	return cachedEncMethod
end

local function GetEncryptedSeedKey(seedVal)
	local idVal = shadowId or 0
	local realSeed = seedVal or 1
	return bit32.bxor(idVal + 909090, realSeed * 2)
end

pcall(function()
	local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
	Runtime.RegisterHitEvent = Net:WaitForChild("RE/RegisterHit")
	Runtime.RegisterAttackEvent = Net:WaitForChild("RE/RegisterAttack")

	pcall(function()
		local CombatUtil = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatUtil"))
		if CombatUtil then
			CombatUtil.CanCharacterMeleeAoe = function()
				return 100
			end
			CombatUtil.CanAttack = function()
				return true
			end
			CombatUtil.GetAttackAngle = function()
				return 0
			end
			CombatUtil.GetDefaultAOEDelay = function()
				return 0
			end
			CombatUtil.GetComboPaddingTime = function()
				return 0
			end
			CombatUtil.GetAttackCancelMultiplier = function()
				return 0
			end
		end
	end)

	pcall(function()
		local Global = require(ReplicatedStorage:WaitForChild("Global"))
		if Global then
			Global.tapCooldown = 0
			local mt = getrawmetatable and getrawmetatable(Global) or getmetatable(Global)
			if mt then
				if setreadonly then
					setreadonly(mt, false)
				end
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

pcall(function()
	local renv = getrenv and getrenv() or _G
	if renv and renv._G then
		pcall(function()
			renv._G.checkHits = function(...) end
		end)
	end
end)

local currentSessionSecret = nil
getgenv().cachedNetSeed = 1
local lastSessionRefreshAt = 0

local function RefreshSessionSecret(force)
	local now = os.clock()
	if not force and currentSessionSecret and (now - lastSessionRefreshAt < 60) then
		return currentSessionSecret
	end
	lastSessionRefreshAt = now

	pcall(function()
		local c = coroutine.create(function() end)
		currentSessionSecret = tostring(player.UserId):sub(2, 4) .. tostring(c):sub(11, 15)

		local netModule = ReplicatedStorage:FindFirstChild("Modules")
			and ReplicatedStorage.Modules:FindFirstChild("Net")
		local netSeed = netModule and netModule:FindFirstChild("seed")
		if netSeed and netSeed:IsA("RemoteFunction") then
			local seedVal = netSeed:InvokeServer()
			if seedVal then
				getgenv().cachedNetSeed = seedVal
			end
		end

		if Runtime.RegisterHitEvent and currentSessionSecret then
			Runtime.RegisterHitEvent:FireServer(currentSessionSecret)
		end
	end)
	return currentSessionSecret
end

local function GetRealtimeSessionSecret()
	if not currentSessionSecret then
		return RefreshSessionSecret(true)
	end
	return currentSessionSecret
end

local function GetRealtimeNetSeed()
	if not getgenv().cachedNetSeed or getgenv().cachedNetSeed == 1 then
		pcall(function()
			local netModule = ReplicatedStorage:FindFirstChild("Modules")
				and ReplicatedStorage.Modules:FindFirstChild("Net")
			local netSeed = netModule and netModule:FindFirstChild("seed")
			if netSeed and netSeed:IsA("RemoteFunction") then
				local seedVal = netSeed:InvokeServer()
				if seedVal then
					getgenv().cachedNetSeed = seedVal
				end
			end
		end)
	end
	return getgenv().cachedNetSeed or 1
end

task.defer(function()
	RefreshSessionSecret(true)

	task.spawn(function()
		while ScriptContext.Running do
			task.wait(60)
			RefreshSessionSecret(true)
		end
	end)
end)

Quests = {
	["Sea1"] = {
		["BanditQuest1"] = {
			{
				Level = 0,
				Name = "Bandits",
				Mob = "Bandit",
				Count = 5,
				Stage = 1,
				NPC = Vector3.new(1059, 13, 1552),
				MobPos = Vector3.new(1145, 17, 1634),
			},
		},
		["MarineQuest"] = {
			{
				Level = 0,
				Name = "Trainees",
				Mob = "Trainee",
				Count = 5,
				Stage = 1,
				NPC = Vector3.new(-2566.43, 6.856, 2045.256),
				MobPos = Vector3.new(-2700, 15, 2050),
			},
		},
		["JungleQuest"] = {
			{
				Level = 10,
				Name = "Monkeys",
				Mob = "Monkey",
				Count = 6,
				Stage = 1,
				NPC = Vector3.new(-1602, 37, 153),
				MobPos = Vector3.new(-1659.898804, 18.676752, 183.526260),
			},
			{
				Level = 15,
				Name = "Gorillas",
				Mob = "Gorilla",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-1602, 37, 153),
				MobPos = Vector3.new(-1299.239502, -0.035819, -540.964844),
			},
			{
				Level = 20,
				Name = "Gorilla King",
				Mob = "The Gorilla King",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-1598, 36, 153),
				MobPos = Vector3.new(-1598, 36, 153),
				IsBoss = true,
			},
		},
		["BuggyQuest1"] = {
			{
				Level = 30,
				Name = "Pirates",
				Mob = "Pirate",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-1150.534790, 17.579453, 3861.551514),
				MobPos = Vector3.new(-1221.892456, 17.579453, 3957.021973),
			},
			{
				Level = 40,
				Name = "Brute",
				Mob = "Brute",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-1150.534790, 17.579453, 3861.551514),
				MobPos = Vector3.new(-1145, 15, 4350),
			},
			{
				Level = 55,
				Name = "Chef",
				Mob = "Chef",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-1150.534790, 17.579453, 3861.551514),
				MobPos = Vector3.new(-1150.534790, 17.579453, 3861.551514),
				IsBoss = true,
			},
		},
		["DesertQuest"] = {
			{
				Level = 60,
				Name = "Desert Bandit",
				Mob = "Desert Bandit",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(897, 7, 4389),
				MobPos = Vector3.new(925.362732, 6.181742, 4513.920410),
			},
			{
				Level = 75,
				Name = "Desert Officer",
				Mob = "Desert Officer",
				Count = 6,
				Stage = 2,
				NPC = Vector3.new(897, 7, 4389),
				MobPos = Vector3.new(1558.841797, 14.011657, 4162.903809),
			},
		},
		["SnowQuest"] = {
			{
				Level = 90,
				Name = "Snow Bandit",
				Mob = "Snow Bandit",
				Count = 7,
				Stage = 1,
				NPC = Vector3.new(1386, 87, -1297),
				MobPos = Vector3.new(1354, 105, -1328),
			},
			{
				Level = 100,
				Name = "Snowman",
				Mob = "Snowman",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(1386, 87, -1297),
				MobPos = Vector3.new(1218, 139, -1488),
			},
			{
				Level = 105,
				Name = "Yeti",
				Mob = "Yeti",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(1389, 87, -1298),
				MobPos = Vector3.new(1389, 87, -1298),
				IsBoss = true,
			},
		},
		["MarineQuest2"] = {
			{
				Level = 120,
				Name = "Chief Petty Officer",
				Mob = "Chief Petty Officer",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-5035, 29, 4324),
				MobPos = Vector3.new(-4882, 23, 4273),
			},
			{
				Level = 130,
				Name = "Vice Admiral",
				Mob = "Vice Admiral",
				Count = 1,
				Stage = 2,
				NPC = Vector3.new(-5035, 20, 4324),
				MobPos = Vector3.new(-5035, 20, 4324),
				IsBoss = true,
			},
		},
		["SkyQuest"] = {
			{
				Level = 150,
				Name = "Sky Bandit",
				Mob = "Sky Bandit",
				Count = 7,
				Stage = 1,
				NPC = Vector3.new(-4842, 718, -2623),
				MobPos = Vector3.new(-4953, 295, -2899),
			},
			{
				Level = 175,
				Name = "Dark Master",
				Mob = "Dark Master",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-4842, 718, -2623),
				MobPos = Vector3.new(-5259, 391, -2229),
			},
		},
		["PrisonerQuest"] = {
			{
				Level = 190,
				Name = "Prisoner",
				Mob = "Prisoner",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(5199.588379, 19.836189, 738.117249),
				MobPos = Vector3.new(5288.145996, 10.597742, 462.746582),
			},
			{
				Level = 210,
				Name = "Dangerous Prisoner",
				Mob = "Dangerous Prisoner",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(5199.588379, 19.836189, 738.117249),
				MobPos = Vector3.new(5291.542480, 10.597746, 1011.716492),
			},
		},
		["ImpelQuest"] = {
			{
				Level = 225,
				Name = "Ruthless Prisoner",
				Mob = "Ruthless Prisoner",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(3873, 14, -1940),
				MobPos = Vector3.new(3873, 14, -1940),
				IsBoss = true,
			},
			{
				Level = 230,
				Name = "Warden",
				Mob = "Warden",
				Count = 1,
				Stage = 2,
				NPC = Vector3.new(3873, 14, -1940),
				MobPos = Vector3.new(3873, 14, -1940),
				IsBoss = true,
			},
		},
		["ColosseumQuest"] = {
			{
				Level = 250,
				Name = "Toga Warrior",
				Mob = "Toga Warrior",
				Count = 7,
				Stage = 1,
				NPC = Vector3.new(-1580, 7, -2986),
				MobPos = Vector3.new(-1779, 45, -2741),
			},
			{
				Level = 275,
				Name = "Gladiator",
				Mob = "Gladiator",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-1580, 7, -2986),
				MobPos = Vector3.new(-1274, 58, -3188),
			},
		},
		["MagmaQuest"] = {
			{
				Level = 300,
				Name = "Mil. Soldier",
				Mob = "Military Soldier",
				Count = 7,
				Stage = 1,
				NPC = Vector3.new(-5316, 12, 8517),
				MobPos = Vector3.new(-5411, 11, 8454),
			},
			{
				Level = 325,
				Name = "Mil. Spy",
				Mob = "Military Spy",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-5316, 12, 8517),
				MobPos = Vector3.new(-5802, 86, 8829),
			},
			{
				Level = 350,
				Name = "Magma Admiral",
				Mob = "Magma Admiral",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-5701, 17, 8722),
				MobPos = Vector3.new(-5701, 17, 8722),
				IsBoss = true,
			},
		},
		["FishmanQuest"] = {
			{
				Level = 375,
				Name = "Fishman Warrior",
				Mob = "Fishman Warrior",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(61401.476562, 25.217861, 1630.696655),
				MobPos = Vector3.new(60843.742188, 25.213957, 1426.922852),
			},
			{
				Level = 400,
				Name = "Fishman Commando",
				Mob = "Fishman Commando",
				Count = 7,
				Stage = 2,
				NPC = Vector3.new(61401.476562, 25.217861, 1630.696655),
				MobPos = Vector3.new(61936.566406, 25.215843, 1325.974976),
			},
			{
				Level = 425,
				Name = "Fishman Lord",
				Mob = "Fishman Lord",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(61401.476562, 25.217861, 1630.696655),
				MobPos = Vector3.new(61358.656250, 65.499023, 1134.429565),
				IsBoss = true,
			},
		},
		["SkyExp1Quest"] = {
			{
				Level = 450,
				Name = "God's Guard",
				Mob = "God's Guard",
				Count = 7,
				Stage = 1,
				NPC = Vector3.new(-4722, 846, -1954),
				MobPos = Vector3.new(-4710, 845, -1927),
			},
			{
				Level = 475,
				Name = "Shanda",
				Mob = "Shanda",
				Count = 9,
				Stage = 2,
				NPC = Vector3.new(-7862, 5546, -380),
				MobPos = Vector3.new(-7685, 5601, -441),
			},
			{
				Level = 500,
				Name = "Wysper",
				Mob = "Wysper",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-7862, 5545, -381),
				MobPos = Vector3.new(-7862, 5545, -381),
				IsBoss = true,
			},
		},
		["SkyExp2Quest"] = {
			{
				Level = 525,
				Name = "Royal Squad",
				Mob = "Royal Squad",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-7904, 5635, -1412),
				MobPos = Vector3.new(-7685, 5606, -1442),
			},
			{
				Level = 550,
				Name = "Royal Soldier",
				Mob = "Royal Soldier",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-7904, 5635, -1412),
				MobPos = Vector3.new(-7864, 5661, -1708),
			},
			{
				Level = 575,
				Name = "Thunder God",
				Mob = "Thunder God",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-7749, 5607, -2317),
				MobPos = Vector3.new(-7749, 5607, -2317),
				IsBoss = true,
			},
		},
		["FountainQuest"] = {
			{
				Level = 625,
				Name = "Galley Pirate",
				Mob = "Galley Pirate",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(5259, 39, 4050),
				MobPos = Vector3.new(5558, 39, 3998),
			},
			{
				Level = 650,
				Name = "Galley Captain",
				Mob = "Galley Captain",
				Count = 9,
				Stage = 2,
				NPC = Vector3.new(5259, 39, 4050),
				MobPos = Vector3.new(5677, 93, 4967),
			},
			{
				Level = 675,
				Name = "Cyborg",
				Mob = "Cyborg",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(5247, 38, 4067),
				MobPos = Vector3.new(5247, 38, 4067),
				IsBoss = true,
			},
		},
	},
	["Sea2"] = {
		["Area1Quest"] = {
			{
				Level = 700,
				Name = "Raider",
				Mob = "Raider",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-429, 72, 1836),
				MobPos = Vector3.new(-737, 39, 2385),
			},
			{
				Level = 725,
				Name = "Mercenary",
				Mob = "Mercenary",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-429, 72, 1836),
				MobPos = Vector3.new(-972, 73, 1419),
			},
			{
				Level = 750,
				Name = "Diamond",
				Mob = "Diamond",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-429, 72, 1836),
				MobPos = Vector3.new(-429, 72, 1836),
				IsBoss = true,
			},
		},
		["Area2Quest"] = {
			{
				Level = 775,
				Name = "Swan Pirate",
				Mob = "Swan Pirate",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(638, 73, 918),
				MobPos = Vector3.new(970, 142, 1217),
			},
			{
				Level = 800,
				Name = "Factory Staff",
				Mob = "Factory Staff",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(638, 73, 918),
				MobPos = Vector3.new(296, 73, -56),
			},
			{
				Level = 850,
				Name = "Jeremy",
				Mob = "Jeremy",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(638, 73, 918),
				MobPos = Vector3.new(638, 73, 918),
				IsBoss = true,
			},
		},
		["MarineQuest3"] = {
			{
				Level = 875,
				Name = "Marine Lieutenant",
				Mob = "Marine Lieutenant",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-2441, 73, -3219),
				MobPos = Vector3.new(-2821, 73, -3070),
			},
			{
				Level = 900,
				Name = "Marine Captain",
				Mob = "Marine Captain",
				Count = 9,
				Stage = 2,
				NPC = Vector3.new(-2441, 73, -3219),
				MobPos = Vector3.new(-1867, 73, -3321),
			},
			{
				Level = 925,
				Name = "Orbitus",
				Mob = "Orbitus",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-2441, 73, -3219),
				MobPos = Vector3.new(-2441, 73, -3219),
				IsBoss = true,
			},
		},
		["ZombieQuest"] = {
			{
				Level = 950,
				Name = "Zombie",
				Mob = "Zombie",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-5497, 48, -795),
				MobPos = Vector3.new(-5736, 126, -728),
			},
			{
				Level = 975,
				Name = "Vampire",
				Mob = "Vampire",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-5497, 48, -795),
				MobPos = Vector3.new(-6033, 7, -1317),
			},
		},
		["SnowMountainQuest"] = {
			{
				Level = 1000,
				Name = "Snow Trooper",
				Mob = "Snow Trooper",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(609, 401, -5372),
				MobPos = Vector3.new(535, 432, -5484),
			},
			{
				Level = 1050,
				Name = "Winter Warrior",
				Mob = "Winter Warrior",
				Count = 9,
				Stage = 2,
				NPC = Vector3.new(609, 401, -5372),
				MobPos = Vector3.new(1234, 456, -5174),
			},
		},
		["IceSideQuest"] = {
			{
				Level = 1100,
				Name = "Lab Subordinate",
				Mob = "Lab Subordinate",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-6061, 16, -4905),
				MobPos = Vector3.new(-5720, 63, -4784),
			},
			{
				Level = 1125,
				Name = "Horned Warrior",
				Mob = "Horned Warrior",
				Count = 9,
				Stage = 2,
				NPC = Vector3.new(-6061, 16, -4905),
				MobPos = Vector3.new(-6292, 91, -5503),
			},
			{
				Level = 1150,
				Name = "Smoke Admiral",
				Mob = "Smoke Admiral",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-6061, 16, -4905),
				MobPos = Vector3.new(-6061, 16, -4905),
				IsBoss = true,
			},
		},
		["FireSideQuest"] = {
			{
				Level = 1175,
				Name = "Magma Ninja",
				Mob = "Magma Ninja",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-5429, 16, -5297),
				MobPos = Vector3.new(-5461, 130, -5836),
			},
			{
				Level = 1200,
				Name = "Lava Pirate",
				Mob = "Lava Pirate",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-5429, 16, -5297),
				MobPos = Vector3.new(-5251, 55, -4774),
			},
		},
		["ShipQuest1"] = {
			{
				Level = 1250,
				Name = "Ship Deckhand",
				Mob = "Ship Deckhand",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(1038, 125, 32911),
				MobPos = Vector3.new(1212, 126, 33059),
			},
			{
				Level = 1275,
				Name = "Ship Engineer",
				Mob = "Ship Engineer",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(1038, 125, 32911),
				MobPos = Vector3.new(919, 44, 32779),
			},
		},
		["ShipQuest2"] = {
			{
				Level = 1300,
				Name = "Ship Steward",
				Mob = "Ship Steward",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(969, 125, 33245),
				MobPos = Vector3.new(919, 130, 33419),
			},
			{
				Level = 1325,
				Name = "Ship Officer",
				Mob = "Ship Officer",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(969, 125, 33245),
				MobPos = Vector3.new(1037, 181, 33316),
			},
		},
		["FrostQuest"] = {
			{
				Level = 1350,
				Name = "Arctic Warrior",
				Mob = "Arctic Warrior",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(5668, 28, -6484),
				MobPos = Vector3.new(5966, 58, -6179),
			},
			{
				Level = 1375,
				Name = "Snow Lurker",
				Mob = "Snow Lurker",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(5668, 28, -6484),
				MobPos = Vector3.new(5407, 69, -6880),
			},
			{
				Level = 1400,
				Name = "Ice Admiral",
				Mob = "Awakened Ice Admiral",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(5668, 28, -6484),
				MobPos = Vector3.new(5668, 28, -6484),
				IsBoss = true,
			},
		},
		["ForgottenQuest"] = {
			{
				Level = 1425,
				Name = "Sea Soldier",
				Mob = "Sea Soldier",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-3054, 237, -10148),
				MobPos = Vector3.new(-3028, 65, -9775),
			},
			{
				Level = 1450,
				Name = "Water Fighter",
				Mob = "Water Fighter",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-3054, 237, -10148),
				MobPos = Vector3.new(-3262, 298, -10553),
			},
			{
				Level = 1475,
				Name = "Tide Keeper",
				Mob = "Tide Keeper",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-3054, 237, -10148),
				MobPos = Vector3.new(-3054, 237, -10148),
				IsBoss = true,
			},
		},
		["BartiloQuest"] = {
			{
				Level = 850,
				Name = "Swan's Raid",
				Mob = "Swan Pirate",
				Count = 50,
				Stage = 1,
				NPC = Vector3.new(-429, 72, 1836),
				MobPos = Vector3.new(-429, 72, 1836),
			},
		},
		["CitizenQuest"] = {
			{
				Level = 1800,
				Name = "Town Raid",
				Mob = "Forest Pirate",
				Count = 50,
				Stage = 1,
				NPC = Vector3.new(-429, 72, 1836),
				MobPos = Vector3.new(-429, 72, 1836),
			},
		},
	},
	["Sea3"] = {
		["PiratePortQuest"] = {
			{
				Level = 1500,
				Name = "Pirate Millionaire",
				Mob = "Pirate Millionaire",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-448.99, 108.63, 5948.77),
				MobPos = Vector3.new(-435, 190, 5551),
			},
			{
				Level = 1525,
				Name = "Pistol Billionaire",
				Mob = "Pistol Billionaire",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-448.99, 108.63, 5948.77),
				MobPos = Vector3.new(-236, 217, 6007),
			},
			{
				Level = 1550,
				Name = "Stone",
				Mob = "Stone",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-448.99, 108.63, 5948.77),
				MobPos = Vector3.new(-448.99, 108.63, 5948.77),
				IsBoss = true,
			},
		},
		["DragonCrewQuest"] = {
			{
				Level = 1575,
				Name = "Dragon Crew Warrior",
				Mob = "Dragon Crew Warrior",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(6737.21, 127.44, -712.48),
				MobPos = Vector3.new(6834.66, 192.74, -829.06),
			},
			{
				Level = 1600,
				Name = "Dragon Crew Archer",
				Mob = "Dragon Crew Archer",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(6737.21, 127.44, -712.48),
				MobPos = Vector3.new(6713.14, 716.12, 631.09),
			},
		},
		["VenomCrewQuest"] = {
			{
				Level = 1625,
				Name = "Hydra Enforcer",
				Mob = "Hydra Enforcer",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(5214.16, 1004.13, 756.39),
				MobPos = Vector3.new(4570.93, 1026.70, 405.84),
			},
			{
				Level = 1650,
				Name = "Venomous Assailant",
				Mob = "Venomous Assailant",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(5214.16, 1004.13, 756.39),
				MobPos = Vector3.new(4499.958984, 1169.141724, 796.885559),
			},
			{
				Level = 1675,
				Name = "Hydra Leader",
				Mob = "Hydra Leader",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(5214.16, 1004.13, 756.39),
				MobPos = Vector3.new(5214.16, 1004.13, 756.39),
				IsBoss = true,
			},
		},
		["MarineTreeIsland"] = {
			{
				Level = 1700,
				Name = "Marine Commodore",
				Mob = "Marine Commodore",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(2484.00, 74.29, -6787.78),
				MobPos = Vector3.new(2196.70, 284.17, -7413.28),
			},
			{
				Level = 1725,
				Name = "Marine Rear Admiral",
				Mob = "Marine Rear Admiral",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(2484.00, 74.29, -6787.78),
				MobPos = Vector3.new(3671, 161, -6932),
			},
			{
				Level = 1750,
				Name = "Kilo Admiral",
				Mob = "Kilo Admiral",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(2484.00, 74.29, -6787.78),
				MobPos = Vector3.new(2484.00, 74.29, -6787.78),
				IsBoss = true,
			},
		},
		["DeepForestIsland3"] = {
			{
				Level = 1775,
				Name = "Fishman Raider",
				Mob = "Fishman Raider",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-10582, 332, -8758),
				MobPos = Vector3.new(-10407, 332, -8368),
			},
			{
				Level = 1800,
				Name = "Fishman Captain",
				Mob = "Fishman Captain",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-10582, 332, -8758),
				MobPos = Vector3.new(-10993, 352, -9003),
			},
		},
		["DeepForestIsland"] = {
			{
				Level = 1825,
				Name = "Forest Pirate",
				Mob = "Forest Pirate",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-13232, 333, -7627),
				MobPos = Vector3.new(-13389.283203, 332.440765, -7799.888184),
			},
			{
				Level = 1850,
				Name = "Mythological Pirate",
				Mob = "Mythological Pirate",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-13232, 333, -7627),
				MobPos = Vector3.new(-13508, 583, -6985),
			},
			{
				Level = 1875,
				Name = "Captain Elephant",
				Mob = "Captain Elephant",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-13232, 332, -7625),
				MobPos = Vector3.new(-13232, 332, -7625),
				IsBoss = true,
			},
		},
		["DeepForestIsland2"] = {
			{
				Level = 1900,
				Name = "Jungle Pirate",
				Mob = "Jungle Pirate",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-12684, 391, -9902),
				MobPos = Vector3.new(-12132.820312, 331.800903, -10543.690430),
			},
			{
				Level = 1925,
				Name = "Musketeer Pirate",
				Mob = "Musketeer Pirate",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-12684, 391, -9902),
				MobPos = Vector3.new(-13291, 392, -9769),
			},
			{
				Level = 1950,
				Name = "Beautiful Pirate",
				Mob = "Beautiful Pirate",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-11939, 277, -8814),
				MobPos = Vector3.new(-11939, 277, -8814),
				IsBoss = true,
			},
		},
		["HauntedQuest1"] = {
			{
				Level = 1975,
				Name = "Reborn Skeleton",
				Mob = "Reborn Skeleton",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-9482, 142, 5567),
				MobPos = Vector3.new(-8760, 183, 6168),
			},
			{
				Level = 2000,
				Name = "Living Zombie",
				Mob = "Living Zombie",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-9482, 142, 5567),
				MobPos = Vector3.new(-10144, 139, 5932),
			},
		},
		["HauntedQuest2"] = {
			{
				Level = 2025,
				Name = "Demonic Soul",
				Mob = "Demonic Soul",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-9515, 172, 6078),
				MobPos = Vector3.new(-9507, 172, 6158),
			},
			{
				Level = 2050,
				Name = "Posessed Mummy",
				Mob = "Posessed Mummy",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-9515, 172, 6078),
				MobPos = Vector3.new(-9582, 6, 6205),
			},
		},
		["NutsIslandQuest"] = {
			{
				Level = 2075,
				Name = "Peanut Scout",
				Mob = "Peanut Scout",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-2104, 38, -10192),
				MobPos = Vector3.new(-2150, 122, -10358),
			},
			{
				Level = 2100,
				Name = "Peanut President",
				Mob = "Peanut President",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-2104, 38, -10192),
				MobPos = Vector3.new(-2150, 123, -10536),
			},
		},
		["IceCreamIslandQuest"] = {
			{
				Level = 2125,
				Name = "Ice Cream Chef",
				Mob = "Ice Cream Chef",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-820, 66, -10966),
				MobPos = Vector3.new(-848.671204, 65.882126, -10914.947266),
			},
			{
				Level = 2150,
				Name = "Ice Cream Commander",
				Mob = "Ice Cream Commander",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-820, 66, -10966),
				MobPos = Vector3.new(-610.750732, 208.282623, -11254.516602),
			},
			{
				Level = 2175,
				Name = "Cake Queen",
				Mob = "Cake Queen",
				Count = 1,
				Stage = 3,
				NPC = Vector3.new(-820, 66, -10966),
				MobPos = Vector3.new(-820, 66, -10966),
				IsBoss = true,
			},
		},
		["CakeQuest1"] = {
			{
				Level = 2200,
				Name = "Cookie Crafter",
				Mob = "Cookie Crafter",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-2021, 38, -12028),
				MobPos = Vector3.new(-2288.005371, 37.860714, -12088.270508),
			},
			{
				Level = 2225,
				Name = "Cake Guard",
				Mob = "Cake Guard",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-2021, 38, -12028),
				MobPos = Vector3.new(-1577.599976, 46.978756, -12365.185547),
			},
		},
		["CakeQuest2"] = {
			{
				Level = 2250,
				Name = "Baking Staff",
				Mob = "Baking Staff",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-1927, 38, -12842),
				MobPos = Vector3.new(-1887, 78, -12998),
			},
			{
				Level = 2275,
				Name = "Head Baker",
				Mob = "Head Baker",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-1927, 38, -12842),
				MobPos = Vector3.new(-2207.034424, 53.564850, -12857.274414),
			},
		},
		["ChocQuest1"] = {
			{
				Level = 2300,
				Name = "Cocoa Warrior",
				Mob = "Cocoa Warrior",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(233, 30, -12201),
				MobPos = Vector3.new(31.493752, 24.796925, -12246.680664),
			},
			{
				Level = 2325,
				Name = "Chocolate Bar Battler",
				Mob = "Chocolate Bar Battler",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(233, 30, -12201),
				MobPos = Vector3.new(683.419617, 24.796822, -12576.225586),
			},
		},
		["ChocQuest2"] = {
			{
				Level = 2350,
				Name = "Sweet Thief",
				Mob = "Sweet Thief",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(151, 30, -12774),
				MobPos = Vector3.new(165, 77, -12600),
			},
			{
				Level = 2375,
				Name = "Candy Rebel",
				Mob = "Candy Rebel",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(151, 30, -12774),
				MobPos = Vector3.new(83.6653671, 93.5021515, -12963.4072),
			},
		},
		["CandyQuest1"] = {
			{
				Level = 2400,
				Name = "Candy Pirate",
				Mob = "Candy Pirate",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-1149, 13, -14446),
				MobPos = Vector3.new(-1347, 13, -14585),
			},
			{
				Level = 2425,
				Name = "Snow Demon",
				Mob = "Snow Demon",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-1149, 13, -14446),
				MobPos = Vector3.new(-954, 55, -14558),
			},
		},
		["TikiQuest1"] = {
			{
				Level = 2450,
				Name = "Isle Outlaw",
				Mob = "Isle Outlaw",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-16546, 55, -172),
				MobPos = Vector3.new(-16101, 55, -155),
			},
			{
				Level = 2475,
				Name = "Island Boy",
				Mob = "Island Boy",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-16546, 55, -172),
				MobPos = Vector3.new(-16731, 55, -257),
			},
		},
		["TikiQuest2"] = {
			{
				Level = 2500,
				Name = "Sun-kissed Warrior",
				Mob = "Sun-kissed Warrior",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-16539, 55, 1051),
				MobPos = Vector3.new(-16349, 55, 1005),
			},
			{
				Level = 2525,
				Name = "Isle Champion",
				Mob = "Isle Champion",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-16539, 55, 1051),
				MobPos = Vector3.new(-16847, 55, 1002),
			},
		},
		["TikiQuest3"] = {
			{
				Level = 2550,
				Name = "Serpent Hunter",
				Mob = "Serpent Hunter",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(-16663.8633, 105.30751, 1577.3197),
				MobPos = Vector3.new(-16586.220703, 107.084724, 1341.448608),
			},
			{
				Level = 2575,
				Name = "Skull Slayer",
				Mob = "Skull Slayer",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(-16663.8633, 105.30751, 1577.3197),
				MobPos = Vector3.new(-16666.9453, 176.768646, 1491.6416),
			},
		},
		["SubmergedQuest1"] = {
			{
				Level = 2600,
				Name = "Reef Bandit",
				Mob = "Reef Bandit",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(10780.272461, -2087.699463, 9263.379883),
				MobPos = Vector3.new(10978.163086, -2023.948853, 9181.994141),
			},
			{
				Level = 2625,
				Name = "Coral Pirate",
				Mob = "Coral Pirate",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(10780.272461, -2087.699463, 9263.379883),
				MobPos = Vector3.new(10733.620117, -2010.045288, 9343.441406),
			},
		},
		["SubmergedQuest2"] = {
			{
				Level = 2650,
				Name = "Sea Chanter",
				Mob = "Sea Chanter",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(10882.310547, -2086.176025, 10030.576172),
				MobPos = Vector3.new(10623.348633, -2046.116455, 10102.416016),
			},
			{
				Level = 2675,
				Name = "Ocean Prophet",
				Mob = "Ocean Prophet",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(10882.310547, -2086.176025, 10030.576172),
				MobPos = Vector3.new(11041.423828, -1949.248901, 10147.605469),
			},
		},
		["SubmergedQuest3"] = {
			{
				Level = 2675,
				Name = "High Disciple",
				Mob = "High Disciple",
				Count = 8,
				Stage = 1,
				NPC = Vector3.new(9636.642578, -1992.420532, 9611.206055),
				MobPos = Vector3.new(9830.585938, -1941.134888, 9698.757812),
			},
			{
				Level = 2700,
				Name = "Grand Devotee",
				Mob = "Grand Devotee",
				Count = 8,
				Stage = 2,
				NPC = Vector3.new(9636.642578, -1992.420532, 9611.206055),
				MobPos = Vector3.new(9595.754883, -1993.467651, 9845.081055),
			},
		},
	},
}

BOSSES = {}
for seaKey, seaTable in pairs(Quests) do
	local seaNum = (seaKey == "Sea3" and 3) or (seaKey == "Sea2" and 2) or 1
	for questKey, stageList in pairs(seaTable) do
		for _, stageData in ipairs(stageList) do
			if stageData.IsBoss then
				table.insert(BOSSES, {
					Sea = seaNum,
					Min = stageData.Level,
					Name = stageData.Mob or stageData.Name,
					Quest = questKey,
					Stage = stageData.Stage,
					NPC = stageData.NPC,
					MobPos = stageData.MobPos,
				})
			end
		end
	end
end
table.sort(BOSSES, function(a, b)
	return a.Min < b.Min
end)

FightingStyleNPCs = {
	["Black Leg"] = {
		[1] = Vector3.new(-988, 13, 3996),
		[2] = Vector3.new(-4750.61, 35.08, -4846.33),
		[3] = Vector3.new(-5043.64, 371.35, -3183.40),
	},
	["Electro"] = {
		[1] = Vector3.new(-5382.27, 14.15, -2150.34),
		[2] = Vector3.new(-4863.81, 35.08, -4767.54),
		[3] = Vector3.new(-4993.20, 314.56, -3198.06),
	},
	["Water Kung Fu"] = {
		[1] = Vector3.new(61584.35, 18.85, 988.89),
		[2] = Vector3.new(-4960.04, 35.08, -4662.67),
		[3] = Vector3.new(-5017.39, 371.35, -3187.53),
	},
	["Dragon Claw"] = {
		[2] = Vector3.new(-4997.53, 371.35, -3197.46),
	},
	["Superhuman"] = {
		[2] = Vector3.new(1378.05, 247.43, -5189.37),
		[3] = Vector3.new(-4997.53, 371.35, -3197.46),
	},
	["Death Step"] = {
		[2] = Vector3.new(6360.04, 296.67, -6763.93),
		[3] = Vector3.new(-4997.64, 314.56, -3220.37),
	},
	["Sharkman Karate"] = {
		[2] = Vector3.new(-2602.40, 239.22, -10314.75),
		[3] = Vector3.new(-4970.48, 314.56, -3225.04),
	},
	["Electric Claw"] = { [3] = Vector3.new(-10369.83, 331.69, -10126.49) },
	["Dragon Talon"] = { [3] = Vector3.new(5662.03, 1211.32, 858.60) },
	["God Human"] = { [3] = Vector3.new(-13775.56, 334.66, -9877.67) },
	["Sanguine Art"] = { [3] = Vector3.new(-16514.86, 23.18, -190.84) },
}

local function NavigateAndBuyMelee(name)
	task.spawn(function()
		local myChar = GetCharacter()
		local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not myHrp then
			return
		end

		local seaName, seaNum = GetCurrentSea()
		local meleeData = FightingStyleNPCs[name]
		local targetPos = meleeData and meleeData[seaNum]

		if not targetPos or typeof(targetPos) ~= "Vector3" then
			local availableSeas = {}
			if meleeData then
				for sNum, _ in pairs(meleeData) do
					table.insert(availableSeas, "Sea " .. tostring(sNum))
				end
			end
			local seaMsg = #availableSeas > 0 and table.concat(availableSeas, ", ") or "Sea lain"
			if getgenv().LonumObject then
				getgenv().LonumObject:Notify({
					Title = "NPC Tidak Ditemukan",
					Content = name .. " hanya tersedia di " .. seaMsg .. "!",
					Duration = 4,
				})
			end
			return
		end

		if getgenv().LonumObject then
			getgenv().LonumObject:Notify({
				Title = "Buy Fighting Style",
				Content = "Terbang menuju NPC " .. name .. "...",
				Duration = 3,
			})
		end

		ToggleFloat(true)
		local targetCF = CFrame.new(targetPos + Vector3.new(0, 5, 0))
		TweenTo(targetCF)

		local startTime = os.clock()
		while (myHrp.Position - targetPos).Magnitude > 15 and (os.clock() - startTime < 30) do
			task.wait(0.2)
		end

		pcall(function()
			local cleanName = string.gsub(name, " ", "")
			game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buy" .. cleanName)
		end)

		task.wait(0.5)
		ToggleFloat(false)

		if getgenv().LonumObject then
			getgenv().LonumObject:Notify({
				Title = "Fighting Style",
				Content = "Berhasil mencapai NPC dan membeli " .. name .. "!",
				Duration = 4,
			})
		end
	end)
end

Islands = {
	["Sea1"] = {
		["WindMill"] = CFrame.new(979.799, 16.516, 1429.047),
		["Marine"] = CFrame.new(-2566.43, 6.856, 2045.256),
		["Middle Town"] = CFrame.new(-690.331, 15.094, 1582.238),
		["Jungle"] = CFrame.new(-1612.796, 36.852, 149.128),
		["Pirate Village"] = CFrame.new(-1181.309, 4.751, 3803.546),
		["Desert"] = CFrame.new(944.158, 20.92, 4373.3),
		["Snow Island"] = CFrame.new(1347.807, 104.668, -1319.737),
		["MarineFord"] = CFrame.new(-4914.821, 50.964, 4281.028),
		["Magma Village"] = CFrame.new(-5247.716, 12.884, 8504.969),
		["Fountain City"] = CFrame.new(5127.128, 59.501, 4105.446),
		["Sky Island 1"] = CFrame.new(-483.734, 332.038, 595.327),
		["Sky Island 2"] = CFrame.new(2284.414, 15.152, 875.725),
		["Sky Island 3"] = CFrame.new(-2448.53, 73.016, -3210.631),
		["Prison"] = CFrame.new(4875.33, 5.652, 734.85),
		["Colosseum"] = CFrame.new(-11.311, 29.277, 2771.522),
		["Under Water Island"] = CFrame.new(-2850.201, 7.392, 5354.993),
		["Shank Room"] = CFrame.new(-1442.166, 29.879, -28.355),
		["Mob Island"] = CFrame.new(-2850.201, 7.392, 5354.993),
	},
	["Sea2"] = {
		["The Cafe"] = CFrame.new(-380.479, 77.22, 255.826),
		["Dark Area"] = CFrame.new(3780.03, 22.652, -3498.586),
		["Factory"] = CFrame.new(424.127, 211.162, -427.54),
		["Colossuim"] = CFrame.new(-1503.622, 219.796, 1369.31),
		["Two Snow Mountain"] = CFrame.new(753.143, 408.236, -5274.615),
		["Punk Hazard"] = CFrame.new(-6127.654, 15.952, -5040.286),
		["Ussop Island"] = CFrame.new(4816.862, 8.46, 2863.82),
		["Mini Sky Island"] = CFrame.new(-288.741, 49326.316, -35248.594),
	},
	["Sea3"] = {
		["Great Tree"] = CFrame.new(2681.274, 1682.809, -7190.985),
		["Port Town"] = CFrame.new(-226.751, 20.603, 5538.34),
		["Hydra Island"] = CFrame.new(5291.249, 1005.443, 393.762),
		["Floating Turtle"] = CFrame.new(-13274.528, 531.821, -7579.223),
		["Mansion"] = CFrame.new(-12471.17, 374.94, -7551.678),
		["Castle On The Sea"] = CFrame.new(-5083.26, 314.606, -3175.673),
		["Haunted Castle"] = CFrame.new(-9515.372, 164.006, 5786.061),
		["Ice Cream Island"] = CFrame.new(-902.568, 79.932, -10988.848),
		["Peanut Island"] = CFrame.new(-2062.748, 50.474, -10232.568),
		["Cake Island"] = CFrame.new(-1884.775, 19.328, -11666.897),
		["Cocoa Island"] = CFrame.new(87.943, 73.555, -12319.465),
		["Candy Island"] = CFrame.new(-1014.424, 149.111, -14555.963),
		["Tiki Outpost"] = CFrame.new(-16218.683, 9.086, 445.618),
	},
}

local function GetIslandCFrame(islandName)
	if not islandName then
		return nil
	end
	for _, seaTable in pairs(Islands) do
		if seaTable[islandName] then
			return seaTable[islandName]
		end
	end
	return nil
end

selectedBossName = BOSSES[1] and BOSSES[1].Name or nil

local function GetMobProfileByName(mobName)
	if not mobName then
		return nil
	end
	local nameLower = string.lower(mobName)

	for _, seaTable in pairs(Quests) do
		for questKey, stageList in pairs(seaTable) do
			for _, stageData in ipairs(stageList) do
				if
					(stageData.Mob and string.lower(stageData.Mob) == nameLower)
					or (stageData.Name and string.lower(stageData.Name) == nameLower)
				then
					return {
						Quest = questKey,
						Stage = stageData.Stage,
						Level = stageData.Level,
						Name = stageData.Name,
						Mob = stageData.Mob,
						Count = stageData.Count,
						NPC = stageData.NPC,
						MobPos = stageData.MobPos,
						IsBoss = stageData.IsBoss,
					}
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

local function StopCarrier()
	if Runtime.activeFollowConn then
		pcall(function()
			Runtime.activeFollowConn:Disconnect()
		end)
		Runtime.activeFollowConn = nil
	end
	if Runtime.activeCarrier then
		if Runtime.activeCarrier.Parent then
			Runtime.activeCarrier:Destroy()
		end
		Runtime.activeCarrier = nil
	end
	Runtime.activeTween = nil
	lastTargetPos = nil
end

-- Legacy callers use Runtime.activeTween:Cancel(); keep that contract without TweenService.
carrierToken = {
	Cancel = function()
		StopCarrier()
	end,
}

local function DestroyTeleAnchor()
	StopCarrier()
	for _, container in ipairs({ workspace, workspace:FindFirstChild("_WorldOrigin") }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child.Name == "PartTele" then
					child:Destroy()
				end
			end
		end
	end
	local c = GetCharacter()
	if c then
		local a3 = c:FindFirstChild("PartTele")
		if a3 then
			a3:Destroy()
		end
	end
end

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
			bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
			bv.Velocity = Vector3.zero
			bv.Parent = hrp

			local bg = Instance.new("BodyGyro")
			bg.Name = "BodyGyroClip"
			bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
			bg.P = 100000
			bg.D = 1000
			bg.CFrame = hrp.CFrame
			bg.Parent = hrp
		end
	else
		if Runtime.activeTween then
			Runtime.activeTween:Cancel()
			Runtime.activeTween = nil
		end
		DestroyTeleAnchor()
		if hrp:FindFirstChild("BodyClip") then
			hrp.BodyClip:Destroy()
		end
		if hrp:FindFirstChild("BodyGyroClip") then
			hrp.BodyGyroClip:Destroy()
		end
		if humanoid then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		hrp.AssemblyLinearVelocity = Vector3.zero
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
		return nil
	end

	if cfg.lastPortalInvokeAt and (os.clock() - cfg.lastPortalInvokeAt < 3) then
		return nil
	end

	local seaName, seaNum = GetCurrentSea()
	if seaNum ~= 3 then
		return nil
	end
	if not CheckPortalAccess() then
		return nil
	end
	local isActuallyInRaid = player:GetAttribute("IslandRaiding") or false
	local currLoc = tostring(player:GetAttribute("CurrentLocation") or "")
	if isActuallyInRaid or string.match(currLoc, "Island%s*%d+") then
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

	if
		(closestHub == "Castle" and isAtSeaCastle)
		or (closestHub == "Tiki" and isAtTiki)
		or (closestHub == "Turtle" and isAtTurtle)
		or (closestHub == "Hydra" and isAtHydra)
	then
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

local function LookCFrame(basePos, height)
	local overhead = basePos + Vector3.new(0, height, 0)
	local dir = basePos - overhead
	-- A purely vertical look vector leaves roll undefined and spins the character
	if math.abs(dir.X) < 1e-3 and math.abs(dir.Z) < 1e-3 then
		dir = dir + Vector3.new(0.001, 0, 0.001)
	end
	return CFrame.lookAt(overhead, overhead + dir)
end

local function TweenTo(targetCFrame)
	if not targetCFrame or typeof(targetCFrame) ~= "CFrame" then
		return
	end
	if isTeleporting then
		return
	end

	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local targetPos = targetCFrame.Position
	if not targetPos or typeof(targetPos) ~= "Vector3" then
		return
	end

	if targetPos.Y < -500 then
		local isSubmergedTarget = (targetPos - Vector3.new(11427.09, -2154.98, 9729.26)).Magnitude < 5000
		if not isSubmergedTarget then
			return
		end
	end
	if math.abs(targetPos.X) > 200000 or math.abs(targetPos.Z) > 200000 then
		return
	end

	local seaName, seaNum = GetCurrentSea()
	if seaNum == 1 then
		local isCurrentlyUnderwater = (hrp.Position.X > 55000 and hrp.Position.X < 65000)
		local isTargetUnderwater = (targetPos.X > 55000 and targetPos.X < 65000)

		if isCurrentlyUnderwater and not isTargetUnderwater then
			local exitPos = Vector3.new(61170.0469, -2, 1952.83398)
			local distToExit = (hrp.Position - exitPos).Magnitude

			if distToExit > 10 then
				targetPos = exitPos
				targetCFrame = CFrame.new(exitPos)
			else
				if not cfg.lastUnderwaterExitAt or (os.clock() - cfg.lastUnderwaterExitAt > 2) then
					cfg.lastUnderwaterExitAt = os.clock()
					task.spawn(function()
						isTeleporting = true
						local startPos = hrp.Position
						pcall(function()
							local t = 0
							while t < 30 do
								t = t + 1
								task.wait(0.1)
								local currChar = GetCharacter()
								local currHrp = currChar and currChar:FindFirstChild("HumanoidRootPart")
								if currHrp and (currHrp.Position - startPos).Magnitude > 500 then
									task.wait(0.5)
									break
								end
							end
						end)
						isTeleporting = false
						local freshHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
						if freshHrp then
							TweenTo(targetCFrame)
						end
					end)
				end
				return
			end
		end

		if not isCurrentlyUnderwater and isTargetUnderwater then
			local entrancePos = Vector3.new(4050.31104, -1.68800354, -1814.12402)
			local distToEntrance = (hrp.Position - entrancePos).Magnitude

			if distToEntrance > 10 then
				targetPos = entrancePos
				targetCFrame = CFrame.new(entrancePos)
			else
				if not cfg.lastUnderwaterEnterAt or (os.clock() - cfg.lastUnderwaterEnterAt > 2) then
					cfg.lastUnderwaterEnterAt = os.clock()
					task.spawn(function()
						isTeleporting = true
						local startPos = hrp.Position
						pcall(function()
							local t = 0
							while t < 30 do
								t = t + 1
								task.wait(0.1)
								local currChar = GetCharacter()
								local currHrp = currChar and currChar:FindFirstChild("HumanoidRootPart")
								if currHrp and (currHrp.Position - startPos).Magnitude > 500 then
									task.wait(0.5)
									break
								end
							end
						end)
						isTeleporting = false
						local freshHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
						if freshHrp then
							TweenTo(targetCFrame)
						end
					end)
				end
				return
			end
		end
	end

	ToggleFloat(true)

	if isTeleporting then
		return
	end

	if hrp.AssemblyLinearVelocity ~= Vector3.zero then
		hrp.AssemblyLinearVelocity = Vector3.zero
	end

	local char = GetCharacter()
	if not char then
		return
	end

	-- Goal only shifted a little: move the marker, keep the running glide.
	-- Moving the anchor never snaps the character - it lerps toward it each frame.
	if Runtime.activeCarrier and Runtime.activeCarrier.Parent and lastTargetPos then
		if (targetPos - lastTargetPos).Magnitude < 5 then
			Runtime.activeCarrier.CFrame = targetCFrame
			lastTargetPos = targetPos
			local bg0 = hrp:FindFirstChild("BodyGyroClip")
			if bg0 then
				bg0.CFrame = targetCFrame
			end
			return
		end
	end

	StopCarrier()

	lastTargetPos = targetPos

	local telePart = Instance.new("Part")
	telePart.Name = "PartTele"
	telePart.Size = Vector3.new(2, 2, 2)
	telePart.Transparency = 1
	telePart.CanCollide = false
	telePart.CanTouch = false
	telePart.CanQuery = false
	telePart.Anchored = true
	telePart.CFrame = targetCFrame
	telePart.Parent = workspace._WorldOrigin or workspace
	Runtime.activeCarrier = telePart

	local glideSpeed = cfg.TweenSpeed or 300
	local glideDone = false

	local followConn
	followConn = RunService.RenderStepped:Connect(function(dt)
		if glideDone then
			return
		end

		if not telePart or not telePart.Parent then
			followConn:Disconnect()
			if Runtime.activeFollowConn == followConn then
				Runtime.activeFollowConn = nil
			end
			return
		end

		local anchorPos = telePart.Position
		if anchorPos.Y < -500 or math.abs(anchorPos.X) > 200000 or math.abs(anchorPos.Z) > 200000 then
			glideDone = true
			followConn:Disconnect()
			if Runtime.activeFollowConn == followConn then
				Runtime.activeFollowConn = nil
			end
			StopCarrier()
			return
		end

		local currentHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
		if not currentHrp or not currentHrp.Parent then
			glideDone = true
			followConn:Disconnect()
			if Runtime.activeFollowConn == followConn then
				Runtime.activeFollowConn = nil
			end
			return
		end

		local goal = telePart.CFrame
		local remaining = (goal.Position - currentHrp.Position).Magnitude

		if remaining <= 1 then
			glideDone = true
			currentHrp.CFrame = goal
			currentHrp.AssemblyLinearVelocity = Vector3.zero
			currentHrp.AssemblyAngularVelocity = Vector3.zero
			local bgEnd = currentHrp:FindFirstChild("BodyGyroClip")
			if bgEnd then
				bgEnd.CFrame = goal
			end
			followConn:Disconnect()
			if Runtime.activeFollowConn == followConn then
				Runtime.activeFollowConn = nil
			end
			StopCarrier()
			return
		end

		local step = glideSpeed * dt
		local alpha = math.clamp(step / remaining, 0, 1)
		currentHrp.CFrame = currentHrp.CFrame:Lerp(goal, alpha)
		currentHrp.AssemblyLinearVelocity = Vector3.zero
		currentHrp.AssemblyAngularVelocity = Vector3.zero
		local bgClip = currentHrp:FindFirstChild("BodyGyroClip")
		if bgClip then
			bgClip.CFrame = goal
		end
	end)
	Runtime.activeFollowConn = followConn
	Runtime.activeTween = carrierToken
end

local function SafeTouch(targetPart, hrp, overrideDistance)
	if not targetPart or not hrp then
		return false
	end

	local ok, _ = useUnc("firetouchinterest", { hrp, targetPart, 0 })
	if ok then
		task.wait(0.01)
		useUnc("firetouchinterest", { hrp, targetPart, 1 })
		return true
	else
		local dist = (hrp.Position - targetPart.Position).Magnitude
		if dist > 8 then
			TweenTo(CFrame.new(targetPart.Position))
			return false
		else
			if Runtime.activeTween then
				Runtime.activeTween:Cancel()
				Runtime.activeTween = nil
			end
			hrp.CFrame = CFrame.new(targetPart.Position)
			task.wait(0.1)
			return true
		end
	end
end

local function SafeProximity(prompt, hrp)
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

	local fired = false
	if proximityPrompt then
		local ok, _ = useUnc("fireproximityprompt", { proximityPrompt })
		fired = ok
	end
	if not fired then
		local promptPart = prompt:IsA("BasePart") and prompt
			or (prompt:IsA("Model") and prompt.PrimaryPart)
			or (proximityPrompt and proximityPrompt.Parent:IsA("BasePart") and proximityPrompt.Parent)
		if promptPart and hrp then
			local dist = (hrp.Position - promptPart.Position).Magnitude
			if dist > 10 then
				TweenTo(CFrame.new(promptPart.Position))
				return
			end
		end
		local key = (proximityPrompt and proximityPrompt.KeyboardKeyCode ~= Enum.KeyCode.Unknown)
				and proximityPrompt.KeyboardKeyCode
			or Enum.KeyCode.E
		VirtualInputManager:SendKeyEvent(true, key, false, game)
		local holdDur = proximityPrompt and proximityPrompt.HoldDuration or 0.1
		task.wait(holdDur > 0 and holdDur or 0.1)
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

local hasDrawing = type(Drawing) == "table" and type(Drawing.new) == "function"
local MainCamera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")

function SafeSetRenderProperty(obj, prop, val)
	if type(setrenderproperty) == "function" then
		pcall(setrenderproperty, obj, prop, val)
	else
		pcall(function()
			obj[prop] = val
		end)
	end
end

function GetEntityRenderPart(obj)
	if not obj then
		return nil
	end
	if obj:IsA("BasePart") then
		return obj
	end

	local hrp = obj:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end

	if obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart:IsA("BasePart") then
		return obj.PrimaryPart
	end

	local handle = obj:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		return handle
	end

	local firstPart = obj:FindFirstChildWhichIsA("BasePart")
	if firstPart and firstPart:IsA("BasePart") then
		return firstPart
	end

	return nil
end

local function HandleUniversalESP(generatorFn, espTag, color, toggleVarName)
	if hasDrawing then
		local drawings = {}

		local function CleanAllDrawings()
			for obj, draw in pairs(drawings) do
				pcall(function()
					draw.Visible = false
					if type(draw.Remove) == "function" then
						draw:Remove()
					elseif type(draw.Destroy) == "function" then
						draw:Destroy()
					end
				end)
			end
			table.clear(drawings)
		end

		RunService.RenderStepped:Connect(function()
			if not getgenv()[toggleVarName] then
				if next(drawings) ~= nil then
					CleanAllDrawings()
				end
				return
			end

			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			local myPos = myHrp and myHrp.Position
			local cam = workspace.CurrentCamera or MainCamera
			if not cam then
				return
			end

			local activeList = {}
			local success, items = pcall(generatorFn)
			if success and type(items) == "table" then
				for _, obj in ipairs(items) do
					if obj and obj.Parent and obj ~= player.Character then
						activeList[obj] = true
						local part = GetEntityRenderPart(obj)
						if part then
							local draw = drawings[obj]
							if not draw then
								local ok, newDraw = pcall(function()
									return Drawing.new("Text")
								end)
								if ok and newDraw then
									draw = newDraw
									drawings[obj] = draw
									SafeSetRenderProperty(draw, "Size", 13)
									SafeSetRenderProperty(draw, "Center", true)
									SafeSetRenderProperty(draw, "Outline", true)
									SafeSetRenderProperty(draw, "Color", color)
								end
							end

							if draw then
								local pos = part.Position
								local screenPos, onScreen = cam:WorldToViewportPoint(pos)
								if onScreen then
									local distText = ""
									if myPos then
										local distMeters = math.floor((myPos - pos).Magnitude / 3)
										distText = "\n[" .. tostring(distMeters) .. " M]"
									end
									SafeSetRenderProperty(draw, "Visible", true)
									SafeSetRenderProperty(draw, "Position", Vector2.new(screenPos.X, screenPos.Y))
									SafeSetRenderProperty(draw, "Text", tostring(obj.Name) .. distText)
								else
									SafeSetRenderProperty(draw, "Visible", false)
								end
							end
						end
					end
				end
			end

			for trackedObj, draw in pairs(drawings) do
				if not activeList[trackedObj] or not trackedObj.Parent then
					pcall(function()
						draw.Visible = false
						if type(draw.Remove) == "function" then
							draw:Remove()
						elseif type(draw.Destroy) == "function" then
							draw:Destroy()
						end
					end)
					drawings[trackedObj] = nil
				end
			end
		end)
	else
		task.spawn(function()
			while task.wait(0.5) do
				if not getgenv()[toggleVarName] then
					pcall(function()
						local items = generatorFn()
						for _, obj in ipairs(items) do
							local ui = obj:FindFirstChild(espTag)
							if ui then
								ui:Destroy()
							end
						end
					end)
				else
					pcall(function()
						local items = generatorFn()
						for _, obj in ipairs(items) do
							if obj ~= player.Character then
								local targetPart = GetEntityRenderPart(obj)
								if targetPart then
									local ui = obj:FindFirstChild(espTag)
									if not ui then
										ui = Instance.new("BillboardGui")
										ui.Name = espTag
										ui.AlwaysOnTop = true
										ui.Size = UDim2.new(0, 200, 0, 50)
										ui.StudsOffset = Vector3.new(0, 4, 0)
										local tl = Instance.new("TextLabel")
										tl.Size = UDim2.new(1, 0, 1, 0)
										tl.BackgroundTransparency = 1
										tl.TextColor3 = color
										tl.TextStrokeTransparency = 0.5
										tl.TextSize = 13
										tl.Font = Enum.Font.GothamBold
										tl.Parent = ui
										ui.Parent = obj
									end

									local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
									if myHrp and ui:FindFirstChild("TextLabel") then
										local dist = math.floor((myHrp.Position - targetPart.Position).Magnitude / 3)
										ui.TextLabel.Text = string.format("%s\n[%d M]", tostring(obj.Name), dist)
									end
								end
							end
						end
					end)
				end
			end
		end)
	end
end

local function GetPlayerDisplayInfo(charOrPlayer)
	local targetPlayer = charOrPlayer:IsA("Player") and charOrPlayer or Players:GetPlayerFromCharacter(charOrPlayer)
	local char = targetPlayer and targetPlayer.Character or (charOrPlayer:IsA("Model") and charOrPlayer)
	if not char then
		return nil
	end

	local name = targetPlayer and targetPlayer.Name or char.Name
	local hum = char:FindFirstChildOfClass("Humanoid")
	local curHp = hum and math.floor(hum.Health) or 0
	local maxHp = hum and math.floor(hum.MaxHealth) or 0
	local hpText = hum and (tostring(curHp) .. "/" .. tostring(maxHp)) or "N/A"

	local inCombat = targetPlayer and targetPlayer:GetAttribute("InCombat") == true
	local pvpDisabled = targetPlayer and targetPlayer:GetAttribute("PvpDisabled") == true
	local statusText = inCombat and "In Combat" or (pvpDisabled and "Disabled" or "Ready")

	local kenActive = targetPlayer and targetPlayer:GetAttribute("KenActive") == true
	local dodgesLeft = targetPlayer and tonumber(targetPlayer:GetAttribute("KenDodgesLeft")) or 0
	local maxDodges = targetPlayer and tonumber(targetPlayer:GetAttribute("KenMaxDodges")) or 0
	local kenText = string.format("Ken: %s [%d/%d]", kenActive and "Active" or "Inactive", dodgesLeft, maxDodges)

	local myTeam = player.Team and player.Team.Name or tostring(player:GetAttribute("Team") or "")
	local targetTeam = targetPlayer and targetPlayer.Team and targetPlayer.Team.Name
		or tostring(targetPlayer and targetPlayer:GetAttribute("Team") or "")
	local isSameMarine = (myTeam == "Marines" and targetTeam == "Marines")
	local teamColor = isSameMarine and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)

	return {
		Player = targetPlayer,
		Character = char,
		Name = name,
		HealthText = hpText,
		StatusText = statusText,
		KenText = kenText,
		Color = teamColor,
		IsSameMarine = isSameMarine,
		IsFriendly = isSameMarine,
	}
end

local function GetPlayerEntities()
	local players = {}
	local charFolder = workspace:FindFirstChild("Characters") or workspace:FindFirstChild("Character")
	if charFolder then
		for _, c in ipairs(charFolder:GetChildren()) do
			if
				c ~= player.Character and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildOfClass("Humanoid"))
			then
				table.insert(players, c)
			end
		end
	end
	if #players == 0 then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				table.insert(players, p.Character)
			end
		end
	end
	return players
end

local function HandlePlayerESP(toggleVarName)
	if hasDrawing then
		local drawings = {}

		local function CleanAllDrawings()
			for obj, draw in pairs(drawings) do
				pcall(function()
					draw.Visible = false
					if type(draw.Remove) == "function" then
						draw:Remove()
					elseif type(draw.Destroy) == "function" then
						draw:Destroy()
					end
				end)
			end
			table.clear(drawings)
		end

		RunService.RenderStepped:Connect(function()
			if not getgenv()[toggleVarName] then
				if next(drawings) ~= nil then
					CleanAllDrawings()
				end
				return
			end

			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			local myPos = myHrp and myHrp.Position
			local cam = workspace.CurrentCamera or MainCamera
			if not cam then
				return
			end

			local activeList = {}
			local items = GetPlayerEntities()
			for _, obj in ipairs(items) do
				if obj and obj.Parent and obj ~= player.Character then
					activeList[obj] = true
					local part = GetEntityRenderPart(obj)
					if part then
						local draw = drawings[obj]
						if not draw then
							local ok, newDraw = pcall(function()
								return Drawing.new("Text")
							end)
							if ok and newDraw then
								draw = newDraw
								drawings[obj] = draw
								SafeSetRenderProperty(draw, "Size", 13)
								SafeSetRenderProperty(draw, "Center", true)
								SafeSetRenderProperty(draw, "Outline", true)
							end
						end

						if draw then
							local info = GetPlayerDisplayInfo(obj)
							local pos = part.Position
							local screenPos, onScreen = cam:WorldToViewportPoint(pos)

							if onScreen and info then
								local distText = ""
								if myPos then
									local distMeters = math.floor((myPos - pos).Magnitude / 3)
									distText = "\n[" .. tostring(distMeters) .. " M]"
								end

								local fullText = string.format(
									"%s\nHP: %s\nStatus: %s | %s%s",
									info.Name,
									info.HealthText,
									info.StatusText,
									info.KenText,
									distText
								)

								SafeSetRenderProperty(draw, "Color", info.Color)
								SafeSetRenderProperty(draw, "Visible", true)
								SafeSetRenderProperty(draw, "Position", Vector2.new(screenPos.X, screenPos.Y))
								SafeSetRenderProperty(draw, "Text", fullText)
							else
								SafeSetRenderProperty(draw, "Visible", false)
							end
						end
					end
				end
			end

			for trackedObj, draw in pairs(drawings) do
				if not activeList[trackedObj] or not trackedObj.Parent then
					pcall(function()
						draw.Visible = false
						if type(draw.Remove) == "function" then
							draw:Remove()
						elseif type(draw.Destroy) == "function" then
							draw:Destroy()
						end
					end)
					drawings[trackedObj] = nil
				end
			end
		end)
	else
		task.spawn(function()
			while task.wait(0.5) do
				if not getgenv()[toggleVarName] then
					pcall(function()
						local items = GetPlayerEntities()
						for _, obj in ipairs(items) do
							local ui = obj:FindFirstChild("ESP_Player")
							if ui then
								ui:Destroy()
							end
						end
					end)
				else
					pcall(function()
						local items = GetPlayerEntities()
						for _, obj in ipairs(items) do
							if obj ~= player.Character then
								local targetPart = GetEntityRenderPart(obj)
								local info = GetPlayerDisplayInfo(obj)
								if targetPart and info then
									local ui = obj:FindFirstChild("ESP_Player")
									if not ui then
										ui = Instance.new("BillboardGui")
										ui.Name = "ESP_Player"
										ui.AlwaysOnTop = true
										ui.Size = UDim2.new(0, 250, 0, 75)
										ui.StudsOffset = Vector3.new(0, 4.5, 0)
										local tl = Instance.new("TextLabel")
										tl.Size = UDim2.new(1, 0, 1, 0)
										tl.BackgroundTransparency = 1
										tl.TextStrokeTransparency = 0.5
										tl.TextSize = 12
										tl.Font = Enum.Font.GothamBold
										tl.Parent = ui
										ui.Parent = obj
									end

									local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
									if myHrp and ui:FindFirstChild("TextLabel") then
										local dist = math.floor((myHrp.Position - targetPart.Position).Magnitude / 3)
										ui.TextLabel.TextColor3 = info.Color
										ui.TextLabel.Text = string.format(
											"%s\nHP: %s\nStatus: %s | %s\n[%d M]",
											info.Name,
											info.HealthText,
											info.StatusText,
											info.KenText,
											dist
										)
									end
								end
							end
						end
					end)
				end
			end
		end)
	end
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
	if os.clock() - State.LastDodgeTime < cfg.dodgeCooldown then
		return
	end

	for _, obj in pairs(Workspace:GetChildren()) do
		if obj.Name:find("Projectile") or obj.Name:find("Bullet") then
			local distance = (hrp.Position - obj.Position).Magnitude
			if distance < 20 then
				local dodgeDirection = (hrp.Position - obj.Position).Unit * cfg.dodgeDistance
				local newPosition = hrp.Position + dodgeDirection
				hrp.CFrame = CFrame.new(newPosition)
				State.LastDodgeTime = os.clock()
				break
			end
		end
	end
end

local isCollectingFruit = false

ValidFruitNames = {
	"Quake",
	"Magma",
	"Light",
	"Ice",
	"Buddha",
	"Flame",
	"Dark",
	"Rubber",
	"Bomb",
	"Spike",
	"Meme",
	"Blade",
	"Smoke",
	"Phoenix",
	"Spring",
	"Spider",
	"Sand",
	"Gravity",
	"Pain",
	"Dough",
	"Control",
	"Dragon",
	"Venom",
	"Spin",
	"Portal",
	"Rocket",
	"Diamond",
	"Love",
	"Ghost",
	"Shadow",
	"Spirit",
	"Yeti",
	"Fiend (Yeti)",
	"Tiger",
	"Mammoth",
	"Sound",
	"Kitsune",
	"Empyrean (Kitsune)",
	"T-Rex",
	"Gas",
	"Eagle",
}

local function IsFruitEntity(obj)
	if not obj or typeof(obj) ~= "Instance" then
		return false
	end
	if not (obj:IsA("Tool") or obj:IsA("Model")) then
		return false
	end
	if obj == player.Character then
		return false
	end

	local objNameLower = string.lower(obj.Name)
	local origNameLower = string.lower(tostring(obj:GetAttribute("OriginalName") or ""))

	for _, fruitName in ipairs(ValidFruitNames) do
		local patternLower = string.lower(fruitName)
		if
			origNameLower ~= ""
			and string.find(objNameLower, patternLower, 1, true)
			and string.find(origNameLower, "fruit")
		then
			return true
		end
	end

	return false
end

local function GetFruitHandle(obj)
	if not obj or typeof(obj) ~= "Instance" then
		return nil
	end

	local handle = obj:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		return handle
	end

	if obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart:IsA("BasePart") then
		return obj.PrimaryPart
	end

	local basePart = obj:FindFirstChildWhichIsA("BasePart", true)
	if basePart and basePart:IsA("BasePart") then
		return basePart
	end

	return nil
end

local function ScanForFruits()
	State.FruitWaypoints = {}
	blacklistedFruits = { "Fruit1", "" }
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	for _, obj in ipairs(workspace:GetChildren()) do
		if IsFruitEntity(obj) then
			local handle = GetFruitHandle(obj)
			if handle and handle:IsA("BasePart") and handle.Parent then
				table.insert(State.FruitWaypoints, handle)
			end
		end
	end
end

local function ScanForChests()
	State.ChestWaypoints = {}
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	local chestModels = Workspace:FindFirstChild("ChestModels")
	if hrp and chestModels then
		for _, chest in ipairs(chestModels:GetChildren()) do
			local targetPart = chest:IsA("Model") and (chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart"))
				or chest
			if targetPart and targetPart:IsA("BasePart") then
				table.insert(State.ChestWaypoints, targetPart)
			end
		end
	end
end

local function CollectNearestFruit()
	if #State.FruitWaypoints == 0 then
		return false
	end
	local nearestFruit = nil
	local shortestDistance = math.huge
	local hrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	local hum = GetHumanoid()
	if hrp and hum then
		for _, fruit in pairs(State.FruitWaypoints) do
			if fruit and fruit.Parent then
				local distance = (hrp.Position - fruit.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					nearestFruit = fruit
				end
			end
		end
		if nearestFruit then
			pcall(function()
				local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
				if remote then
					local req = remote:FindFirstChild("RequestStreamAroundAsync")
					if req then
						req:FireServer(nearestFruit.Position)
					end
				end
			end)

			if hasFireTouch then
				SafeTouch(nearestFruit, hrp)
			else
				local dist = (hrp.Position - nearestFruit.Position).Magnitude
				if dist > 250 then
					ToggleFloat(true)
					TweenTo(CFrame.new(nearestFruit.Position + Vector3.new(0, 5, 0)))
				else
					if not isCollectingFruit then
						isCollectingFruit = true
						task.spawn(function()
							if Runtime.activeTween then
								Runtime.activeTween:Cancel()
								Runtime.activeTween = nil
							end
							hrp.CFrame = CFrame.new(nearestFruit.Position)
							task.wait(0.05)
							SafeTouch(nearestFruit, hrp, 50)
							task.wait(0.1)
							isCollectingFruit = false
						end)
					else
						SafeTouch(nearestFruit, hrp, 50)
					end
				end
			end

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

	if #State.ChestWaypoints == 0 then
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
	for _, chest in pairs(State.ChestWaypoints) do
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
						if Runtime.activeTween then
							Runtime.activeTween:Cancel()
							Runtime.activeTween = nil
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
	local seaName, seaNum = GetCurrentSea()
	local seaKey = (seaNum == 3 and "Sea3")
		or (seaNum == 2 and "Sea2")
		or (seaNum == 1 and "Sea1")
		or ((level >= 1500 and "Sea3") or (level >= 700 and "Sea2") or "Sea1")
	local seaTable = Quests[seaKey]
	if not seaTable then
		return nil
	end

	local list = {}
	for questKey, stageList in pairs(seaTable) do
		for _, stageData in ipairs(stageList) do
			table.insert(list, {
				Min = stageData.Level,
				Max = stageData.Level + 25,
				Quest = questKey,
				Stage = stageData.Stage,
				Name = stageData.Name,
				Mob = stageData.Mob,
				Count = stageData.Count,
				NPC = stageData.NPC,
				MobPos = stageData.MobPos,
				IsBoss = stageData.IsBoss,
			})
		end
	end

	if #list == 0 then
		return nil
	end

	local highestQuest = nil
	for _, p in ipairs(list) do
		if not p.IsBoss and level >= p.Min then
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

	local bracketKey = tostring(highestQuest.Quest) .. ":" .. tostring(highestQuest.Min)

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
			if not p.IsBoss then
				local sameNpc = (p.NPC - highestQuest.NPC).Magnitude < 10 and level >= p.Min
				local sameQuestType = p.Quest == highestQuest.Quest and level >= p.Min
				if sameNpc or sameQuestType then
					table.insert(currentQuestPool, p)
				end
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

preferredHitParts = {
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
meleeNames = {
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
	if Runtime.activeTween then
		Runtime.activeTween:Cancel()
		Runtime.activeTween = nil
	end

	isNoclipping = false

	DestroyTeleAnchor()
	local c = GetCharacter()
	if c then
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if hrp then
			for _, child in ipairs(hrp:GetChildren()) do
				if child:IsA("BodyVelocity") or child:IsA("BodyGyro") or child:IsA("BodyPosition") then
					child:Destroy()
				end
			end
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
		local hum = c:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end

	isReadyToAttack = false
	currentTargetInstance = nil
	lastTargetPos = nil
	isTeleporting = false
	cfg.isAutoBerry = false
	cfg.autoBerryWorker = cfg.autoBerryWorker + 1
end

local function GetHitPart(model)
	if not model or model == player.Character then
		return nil
	end

	for _, name in ipairs(preferredHitParts) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end

	if model:IsA("Model") and model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
		return model.PrimaryPart
	end

	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end

	local handle = model:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		return handle
	end

	if model:IsA("BasePart") then
		return model
	end

	local fallbackPart = model:FindFirstChildWhichIsA("BasePart", true)
	if fallbackPart then
		return fallbackPart
	end

	return nil
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

Runtime.activeMagnetTweens = setmetatable({}, { __mode = "k" })
Runtime.lastFindAnywhereAt = 0
Runtime.emptyTargetThrottle = {}
Runtime.lastMagnetTick = 0
local function IsEnemyReadyToPull(enemy)
	return true
end

local enemyContainerPaths = {
	ReplicatedStorage,
	ReplicatedStorage:FindFirstChild("BonusMoments"),
	ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Models"),
	ReplicatedStorage:FindFirstChild("EffectContainer"),
}

local function IsRealEnemyInstance(obj)
	if not obj or not obj:IsA("Model") or obj == player.Character then
		return false
	end
	if obj.Name == "MenuMarine" or obj.Name == "MenuPirate" or obj.Name == "DevBrosChilling" then
		return false
	end
	if obj.Parent and obj.Parent.Name == "NPCs" then
		return false
	end

	local hum = obj:FindFirstChildOfClass("Humanoid")
	local hrp = obj:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then
		return false
	end

	if obj:GetAttribute("ID") ~= nil or obj:GetAttribute("Level") ~= nil or obj:GetAttribute("WeaponName") ~= nil then
		return true
	end
	if obj:FindFirstChild("Stun") or obj:FindFirstChild("Busy") or obj:FindFirstChild("CharacterReady") then
		return true
	end
	if obj.Parent and obj.Parent.Name == "Enemies" then
		return true
	end

	return false
end

local lastRestoreCulledAt = 0

local function RestoreCulledEnemies(targetName)
	-- Native Blox Fruits streaming handler:
	-- Models in ReplicatedStorage have their shirt/pants/textures stripped until approached.
	-- We let the engine stream naturally to preserve all character skins and textures!
end

local function UniversalMagnet(targetMobName, gatherPos, myHrpPos)
	local now = os.clock()
	if now - Runtime.lastMagnetTick < 0.1 then
		return
	end
	Runtime.lastMagnetTick = now

	RestoreCulledEnemies(targetMobName)

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

					if Runtime.activeMagnetTweens[eHrp] then
						Runtime.activeMagnetTweens[eHrp]:Cancel()
						Runtime.activeMagnetTweens[eHrp] = nil
					end

					if cfg.BringMethod == "Tween" then
						local distToGather = (eHrp.Position - gatherPos).Magnitude
						if distToGather > 4 then
							if not Runtime.activeMagnetTweens[eHrp] then
								local duration = math.clamp(distToGather / 400, 0.05, 0.25)
								local tween = TweenService:Create(
									eHrp,
									TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
									{ CFrame = gatherCFrame }
								)
								Runtime.activeMagnetTweens[eHrp] = tween
								tween.Completed:Connect(function()
									Runtime.activeMagnetTweens[eHrp] = nil
									if eHrp and eHrp.Parent then
										eHrp.CFrame = gatherCFrame
									end
								end)
								tween:Play()
							end
						else
							eHrp.CFrame = gatherCFrame
						end
					else
						eHrp.CFrame = gatherCFrame
					end
				end
			end
		end
	end
end

local function UniversalEvasionTween(myHrp, targetPos, now)
	ToggleFloat(true)
	local targetDistance = (targetPos - myHrp.Position).Magnitude
	if now - lastEvasionMoveAt >= cfg.EvasionTick then
		lastEvasionMoveAt = now
		if targetDistance > 80 then
			TweenTo(LookCFrame(targetPos, cfg.TweenHeight))
		else
			TweenTo(CFrame.new(targetPos + currentEvasionOffset, targetPos))
		end
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
	if Runtime.activeTween then
		Runtime.activeTween:Cancel()
		Runtime.activeTween = nil
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

SearchCache = {}

function ClearSearchCache()
	table.clear(SearchCache)
end

local function SearchEntities(filterOpts)
	filterOpts = filterOpts or {}
	local results = {}
	local seen = {}
	local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
	local originPos = filterOpts.Origin or (myHrp and myHrp.Position)
	local radius = filterOpts.Radius
	local aliveOnly = filterOpts.AliveOnly
	local reqHitPart = filterOpts.RequireHitPart
	local nameQuery = filterOpts.Name and string.lower(filterOpts.Name)
	local exactName = filterOpts.ExactName
	local attrFilter = filterOpts.Attribute
	local limit = filterOpts.Limit or math.huge

	local attrKey, attrVal = nil, nil
	if type(attrFilter) == "string" then
		attrKey = attrFilter
	elseif type(attrFilter) == "table" then
		attrKey = attrFilter.Key
		attrVal = attrFilter.Value
	end

	local function isValidEntity(obj)
		if not obj or seen[obj] or obj == player.Character then
			return false
		end
		if filterOpts.Exclude and obj == filterOpts.Exclude then
			return false
		end
		if enemyBlacklist[obj] and os.clock() < enemyBlacklist[obj] then
			return false
		end

		if attrKey then
			local hasAttr = false
			pcall(function()
				local val = obj:GetAttribute(attrKey)
				if attrVal ~= nil then
					hasAttr = (val == attrVal)
				else
					hasAttr = (val ~= nil)
				end
			end)
			if not hasAttr then
				return false
			end
		end

		if exactName and obj.Name ~= exactName then
			return false
		end
		if nameQuery and string.find(string.lower(obj.Name), nameQuery, 1, true) == nil then
			return false
		end

		if aliveOnly then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health <= 0 then
				return false
			end
		end

		local hitPart = reqHitPart and GetHitPart(obj)
			or (obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
		if reqHitPart and not hitPart then
			return false
		end

		if radius and originPos then
			local pos = hitPart and hitPart.Position or GetSafePosition(obj)
			if pos == Vector3.zero or (pos - originPos).Magnitude > radius then
				return false
			end
		end

		if filterOpts.CustomFilter and not filterOpts.CustomFilter(obj) then
			return false
		end

		seen[obj] = true
		return true, hitPart
	end

	if nameQuery then
		RestoreCulledEnemies(nameQuery)
	end

	if Paths.Enemies then
		for _, e in ipairs(Paths.Enemies:GetChildren()) do
			local valid, hPart = isValidEntity(e)
			if valid then
				table.insert(results, e)
				if #results >= limit then
					return results
				end
			end
		end
	end

	if Paths.Characters then
		for _, c in ipairs(Paths.Characters:GetChildren()) do
			local valid, hPart = isValidEntity(c)
			if valid then
				table.insert(results, c)
				if #results >= limit then
					return results
				end
			end
		end
	end

	if radius and originPos and radius <= 600 then
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj ~= Paths.Enemies and obj ~= Paths.Characters and (obj:IsA("Model") or obj:IsA("BasePart")) then
				local valid, hPart = isValidEntity(obj)
				if valid then
					table.insert(results, obj)
					if #results >= limit then
						return results
					end
				end
			end
		end
	end

	if #results == 0 and filterOpts.DeepSearch then
		local repTarget = ReplicatedStorage:FindFirstChild(filterOpts.Name or "")
		if repTarget and isValidEntity(repTarget) then
			table.insert(results, repTarget)
		end
		if #results == 0 then
			for _, ent in ipairs(SafeGetInstancesByClass("Model")) do
				if isValidEntity(ent) then
					table.insert(results, ent)
					if #results >= limit then
						break
					end
				end
			end
		end
		if #results == 0 and getnilinstances then
			pcall(function()
				for _, ent in ipairs(SafeGetNilInstances()) do
					if ent:IsA("Model") and isValidEntity(ent) then
						table.insert(results, ent)
						if #results >= limit then
							break
						end
					end
				end
			end)
		end
	end

	return results
end
local function FindEntityAnywhere(mobName)
	if not mobName then
		return nil
	end
	local now = os.clock()
	if now - Runtime.lastFindAnywhereAt < 2.5 then
		return nil
	end
	Runtime.lastFindAnywhereAt = now

	local nameLower = string.lower(mobName)

	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if enemiesFolder then
		for _, enemy in ipairs(enemiesFolder:GetChildren()) do
			if string.lower(enemy.Name) == nameLower and IsEnemyVulnerable(enemy, mobName) then
				return enemy
			end
		end
	end

	local repTarget = ReplicatedStorage:FindFirstChild(mobName)
	if repTarget and IsEnemyVulnerable(repTarget, mobName) then
		return repTarget
	end

	local charactersFolder = workspace:FindFirstChild("Characters")
	if charactersFolder then
		for _, char in ipairs(charactersFolder:GetChildren()) do
			if string.lower(char.Name) == nameLower and IsEnemyVulnerable(char, mobName) then
				return char
			end
		end
	end

	if getnilinstances then
		pcall(function()
			for _, ent in ipairs(SafeGetNilInstances()) do
				if ent:IsA("Model") and string.lower(ent.Name) == nameLower and IsEnemyVulnerable(ent, mobName) then
					repTarget = ent
					break
				end
			end
		end)
		if repTarget then
			return repTarget
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
	if Runtime.emptyTargetThrottle[throttleKey] and (now - Runtime.emptyTargetThrottle[throttleKey]) < 0.6 then
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
		Runtime.emptyTargetThrottle[throttleKey] = now
	else
		Runtime.emptyTargetThrottle[throttleKey] = nil
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

PriorityLevels = {
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
	if Runtime.emptyTargetThrottle[targetBossName] and (now - Runtime.emptyTargetThrottle[targetBossName]) < 0.5 then
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
		Runtime.emptyTargetThrottle[targetBossName] = nil
	else
		Runtime.emptyTargetThrottle[targetBossName] = now
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


local function getDripMamaStatus()
	local now = os.clock()
	if now - Runtime.lastDripMamaCheck < 4 then
		return Runtime.cachedDripMamaStatus
	end
	Runtime.lastDripMamaCheck = now

	local res = nil
	pcall(function()
		res = CommF_:InvokeServer("CakePrinceSpawner", true)
	end)

	if type(res) == "string" then
		local left = string.match(res, "We still need to defeat <Color=Yellow>(%d+)<Color=/>")
		if left then
			Runtime.cachedDripMamaStatus = left .. " left"
		elseif
			string.find(string.lower(res), "portal is already open")
			or string.find(string.lower(res), "behind the house")
		then
			Runtime.cachedDripMamaStatus = "spawned"
		elseif
			string.find(string.lower(res), "we have defeated enough")
			or string.find(string.lower(res), "do you want to open the portal")
		then
			Runtime.cachedDripMamaStatus = "ready"
		else
			Runtime.cachedDripMamaStatus = "unknown"
		end
	end
	return Runtime.cachedDripMamaStatus
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
			Runtime.skillIndex = Runtime.skillIndex + 1
			if Runtime.skillIndex > #Runtime.skillKeys then
				Runtime.skillIndex = 1
			end
		end)
	end
end

local lastExecuteAttackCall = 0
local lastFruitM1Time = 0
local fruitM1Combo = 0
cachedShootGunFunc = nil

local function IsAllyOrSameTeam(otherEntity)
	if not otherEntity then
		return false
	end
	local otherPlayer = game:GetService("Players"):GetPlayerFromCharacter(otherEntity)
	if not otherPlayer or otherPlayer == player then
		return false
	end

	-- 1. Same Team (Marines vs Marines cannot damage each other)
	local myTeam = player.Team and player.Team.Name
	local theirTeam = otherPlayer.Team and otherPlayer.Team.Name
	if myTeam and theirTeam and myTeam == "Marines" and theirTeam == "Marines" then
		return true
	end

	-- 2. Same Pirate Crew / Allies
	local myData = player:FindFirstChild("Data")
	local theirData = otherPlayer:FindFirstChild("Data")
	local myCrew = myData and myData:FindFirstChild("CrewID") and myData.CrewID.Value
	local theirCrew = theirData and theirData:FindFirstChild("CrewID") and theirData.CrewID.Value
	if myCrew and theirCrew and myCrew ~= "" and theirCrew ~= "" and myCrew == theirCrew then
		return true
	end

	-- 3. Target has PvP Disabled
	if otherPlayer:GetAttribute("PvpDisabled") == true then
		return true
	end

	return false
end

local function ExecuteAttack(myChar, myHrp, forceNoEquip, targetMobName)
	local now = os.clock()
	local minInterval = (attackSpeedMode == "Beta Fast Attack") and cfg.AttackIntervalBeta
		or (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
		or cfg.AttackIntervalFast
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
	if not forceNoEquip then
		if not weapon or not IsToolMatching(weapon, targetCategory) then
			weapon = EquipWeapon(targetCategory)
		end
	end

	if not weapon then
		return
	end

	if weapon then
		if myHrp.Anchored then
			myHrp.Anchored = false
		end

		local isBloxFruit = IsToolMatching(weapon, "Fruit")
			or IsToolMatching(weapon, "Blox Fruit")
			or IsToolMatching(weapon, "Demon Fruit")
		local isPhysical = IsToolMatching(weapon, "Melee") or IsToolMatching(weapon, "Sword")
		local isGun = IsToolMatching(weapon, "Gun")
		if isPhysical or isBloxFruit or isGun then
			EnableBuso()

			local attackRange = math.max(cfg.HitRadius or 60, 85)
			local hitTargets = {}
			local seenEntities = {}

			local function IsAllyOrSameTeam(otherEntity)
				if not otherEntity then
					return false
				end
				local otherPlayer = game:GetService("Players"):GetPlayerFromCharacter(otherEntity)
				if not otherPlayer or otherPlayer == player then
					return false
				end

				-- 1. Same Team (Marines vs Marines)
				local myTeam = player.Team and player.Team.Name
				local theirTeam = otherPlayer.Team and otherPlayer.Team.Name
				if myTeam and theirTeam and myTeam == "Marines" and theirTeam == "Marines" then
					return true
				end

				-- 2. Same Pirate Crew / Allies
				local myData = player:FindFirstChild("Data")
				local theirData = otherPlayer:FindFirstChild("Data")
				local myCrew = myData and myData:FindFirstChild("CrewID") and myData.CrewID.Value
				local theirCrew = theirData and theirData:FindFirstChild("CrewID") and theirData.CrewID.Value
				if myCrew and theirCrew and myCrew ~= "" and theirCrew ~= "" and myCrew == theirCrew then
					return true
				end

				-- 3. Target has PvP Disabled
				if otherPlayer:GetAttribute("PvpDisabled") == true then
					return true
				end

				return false
			end

			local function TryAddTargetEntity(entity)
				if not entity or entity == player.Character or seenEntities[entity] then
					return
				end
				if IsAllyOrSameTeam(entity) then
					return
				end
				if enemyBlacklist[entity] and os.clock() < enemyBlacklist[entity] then
					return
				end
				local eHum = entity:FindFirstChildOfClass("Humanoid")
				local eHrp = entity:FindFirstChild("HumanoidRootPart")
				if not eHum or not eHrp or eHum.Health <= 0 then
					return
				end
				if (eHrp.Position - myHrp.Position).Magnitude > attackRange then
					return
				end

				local partToHit = entity:FindFirstChild("Head") or eHrp
				if partToHit then
					seenEntities[entity] = true
					table.insert(hitTargets, { entity, partToHit })
				end
			end

			if currentTargetInstance then
				TryAddTargetEntity(currentTargetInstance)
			end

			local enemiesFolder = Paths and Paths.Enemies or workspace:FindFirstChild("Enemies")
			if enemiesFolder then
				for _, entity in ipairs(enemiesFolder:GetChildren()) do
					TryAddTargetEntity(entity)
					if #hitTargets >= 25 then
						break
					end
				end
			end

			-- Scan other players in Characters folder & Players service for PvP Auto Attack
			if #hitTargets < 25 then
				local charsFolder = Paths and Paths.Characters or workspace:FindFirstChild("Characters")
				if charsFolder then
					for _, charModel in ipairs(charsFolder:GetChildren()) do
						if charModel ~= myChar and charModel ~= player.Character then
							TryAddTargetEntity(charModel)
							if #hitTargets >= 25 then
								break
							end
						end
					end
				end
			end

			if #hitTargets < 25 then
				for _, otherPlayer in ipairs(game:GetService("Players"):GetPlayers()) do
					if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character ~= myChar then
						TryAddTargetEntity(otherPlayer.Character)
						if #hitTargets >= 25 then
							break
						end
					end
				end
			end

			if #hitTargets > 0 then
				local primaryTargetTuple = hitTargets[1]
				local primaryModel = primaryTargetTuple[1]
				local primaryPart = primaryTargetTuple[2]
				local targetHead = primaryPart

				local tPos = targetHead.Position
				local dir = (tPos - myHrp.Position).Unit

				if isBloxFruit then
					pcall(function()
						local leftClick = weapon:FindFirstChild("LeftClickRemote")
						if leftClick and leftClick:IsA("RemoteEvent") then
							if now - lastFruitM1Time >= 0.22 then
								lastFruitM1Time = now
								fruitM1Combo = (fruitM1Combo % 3) + 1
								leftClick:FireServer(dir, fruitM1Combo)
							end
						else
							local remote = weapon:FindFirstChild("LegacyRemoteEvent")
								or weapon:FindFirstChild("RemoteEvent")
							local mousePosInst = weapon:FindFirstChild("MousePos") or weapon:FindFirstChild("Mouse")
							if remote and remote:IsA("RemoteEvent") then
								local combo = Random.new():NextInteger(1, 4)
								remote:FireServer(true)
								if mousePosInst and not mousePosInst:IsA("Vector3Value") then
									remote:FireServer(CFrame.new(tPos))
								else
									remote:FireServer(tPos)
								end
								remote:FireServer(false)
							end
						end
					end)
				end

				if isGun then
					pcall(function()
						local shootPos = targetHead and targetHead.Position
							or (primaryPart and primaryPart.Position)
							or (myHrp.Position + myHrp.CFrame.LookVector * 20)

						if not cachedShootGunFunc and getgc then
							for _, obj in ipairs(getgc(true)) do
								if type(obj) == "function" and not (isexecutorclosure and isexecutorclosure(obj)) then
									local info = debug.getinfo(obj)
									if info and info.name == "shootGun" then
										cachedShootGunFunc = obj
										break
									end
								end
							end
						end

						if cachedShootGunFunc and weapon then
							weapon.Enabled = true
							weapon:SetAttribute("LocalShotsLeft", 10)
							weapon:SetAttribute("IsReloading_Client", nil)

							local fakeInput = {
								UserInputType = Enum.UserInputType.MouseButton1,
								Position = Vector3.zero,
							}
							cachedShootGunFunc(weapon, fakeInput)
						end
					end)
				end

				if isPhysical then
					pcall(function()
						local secret = GetRealtimeSessionSecret()
							or tostring(player.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15)
						local encMethod = GetEncryptedRegisterHit()
						local encSeedKey = GetEncryptedSeedKey(GetRealtimeNetSeed())
						local targetRemote = cloneref and shadowRemote and cloneref(shadowRemote) or shadowRemote

						fruitM1Combo = (fruitM1Combo % 4) + 1

						if Runtime.RegisterAttackEvent then
							Runtime.RegisterAttackEvent:FireServer(0, fruitM1Combo)
						end

						local renv = getrenv and getrenv() or _G
						if renv and renv._G and type(renv._G.SendHitsToServer) == "function" and targetHead then
							pcall(function()
								renv._G.SendHitsToServer(targetHead, hitTargets)
							end)
						end

						local additionalHits = {}
						if #hitTargets > 1 then
							for j = 2, #hitTargets do
								local enemyObj = hitTargets[j]
								local enemyModel = enemyObj[1]
								local partToHit = enemyObj[2]
									or (enemyModel and enemyModel:FindFirstChild("HumanoidRootPart"))
								if enemyModel and partToHit then
									table.insert(additionalHits, { enemyModel, partToHit })
								end
							end
						end

						if Runtime.RegisterHitEvent and targetHead then
							Runtime.RegisterHitEvent:FireServer(targetHead, additionalHits, {}, secret)
						end

						if targetRemote and shadowId and targetHead then
							targetRemote:FireServer(encMethod, encSeedKey, targetHead, additionalHits)
						end
					end)
				end
			end
		end
	end
end
local function AttackThread(generation)
	task.spawn(function()
		while ScriptContext.Running and generation == State.WorkerGen do
			if isAutoFarm then
				local now = os.clock()
				local interval = (attackSpeedMode == "Beta Fast Attack") and cfg.AttackIntervalBeta
					or (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
					or cfg.AttackIntervalFast
				local myChar = GetCharacter()
				local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

				if now - lastAttackAt >= interval then
					local target = currentTargetInstance
					local hum = target and target.Parent and target:FindFirstChildOfClass("Humanoid")
					if myHrp and hum and hum.Health > 0 then
						local tHrp = target:FindFirstChild("HumanoidRootPart")
							or target:FindFirstChildWhichIsA("BasePart", true)
						local canHit = isReadyToAttack
							or (tHrp and (GetSafePosition(tHrp) - myHrp.Position).Magnitude <= (cfg.HitRadius + 40))
						if canHit then
							ExecuteAttack(myChar, myHrp, false, target.Name)
							lastAttackAt = now
						end
					elseif myHrp then
						local p = GetQuestProfile()
						local newT = GetTargetEnemy(p and p.Mob or nil)
						if newT then
							currentTargetInstance = newT
							local newHum = newT:FindFirstChildOfClass("Humanoid")
							if newHum and newHum.Health > 0 then
								ExecuteAttack(myChar, myHrp, false, newT.Name)
								lastAttackAt = now
							end
						end
					end
				end
			end

			if isAutoFarm and (attackSpeedMode == "Super Fast Attack" or attackSpeedMode == "Beta Fast Attack") then
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

HazeTargets = {}

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
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if enemiesFolder then
		for _, inst in ipairs(enemiesFolder:GetChildren()) do
			table.insert(searchList, inst)
		end
	end
	local repEnemies = ReplicatedStorage:FindFirstChild("Enemies")
	if repEnemies then
		for _, inst in ipairs(repEnemies:GetChildren()) do
			table.insert(searchList, inst)
		end
	end
	if getnilinstances then
		pcall(function()
			for _, inst in ipairs(SafeGetNilInstances()) do
				if inst:IsA("Model") then
					table.insert(searchList, inst)
				end
			end
		end)
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
	local generation = State.WorkerGen
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
		while cfg.isAutoHaze and ScriptContext.Running and generation == State.WorkerGen do
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
	local lastHazeBringTick = 0
	hazeBringConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastHazeBringTick < 0.1 then
			return
		end
		lastHazeBringTick = now
		if not cfg.isAutoHaze or not ScriptContext.Running or generation ~= State.WorkerGen then
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
		while cfg.isAutoHaze and ScriptContext.Running and generation == State.WorkerGen do
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
						TweenTo(LookCFrame(tHrp.Position, cfg.TweenHeight))
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
		if Runtime.activeTween then
			Runtime.activeTween:Cancel()
			Runtime.activeTween = nil
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

local enemySpawnConn = nil
local enemyRemoveConn = nil

local function SetupEnemyRealtimeListeners()
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		return
	end

	if enemySpawnConn then
		enemySpawnConn:Disconnect()
		enemySpawnConn = nil
	end
	if enemyRemoveConn then
		enemyRemoveConn:Disconnect()
		enemyRemoveConn = nil
	end

	enemySpawnConn = enemiesFolder.ChildAdded:Connect(function(v)
		table.clear(Runtime.emptyTargetThrottle)
		lastTargetRefreshAt = 0

		if cfg.isAutoHaze then
			task.spawn(function()
				if v:WaitForChild("HazeESP", 1.5) then
					local eHrp = v:WaitForChild("HumanoidRootPart", 1)
					if eHrp then
						local newTarget = { Name = v.Name, Mob = v.Name, MobPos = eHrp.Position, Instance = v }
						table.insert(HazeTargets, newTarget)
						print("Ghost spawns with: " .. v.Name .. " (Added to Target Queue)")
					end
				end
			end)
		end
	end)
	ScriptContext:AddConnection(enemySpawnConn)

	enemyRemoveConn = enemiesFolder.ChildRemoved:Connect(function(v)
		if currentTargetInstance == v then
			currentTargetInstance = nil
			lastTargetRefreshAt = 0
			table.clear(Runtime.emptyTargetThrottle)
		end
	end)
	ScriptContext:AddConnection(enemyRemoveConn)
end

SetupEnemyRealtimeListeners()
workspace.ChildAdded:Connect(function(child)
	if child.Name == "Enemies" then
		SetupEnemyRealtimeListeners()
	end
end)

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
				{
					Name = "Fishman Warriors",
					Mob = "Fishman Warrior",
					MobPos = Vector3.new(61401.476562, 25.217861, 1630.696655),
				},
				{ Name = "Fishman Commandos", Mob = "Fishman Commando", MobPos = Vector3.new(61891, 19, 1470) },
				{
					Name = "Fishman Lord",
					Mob = "Fishman Lord",
					MobPos = Vector3.new(61401.476562, 25.217861, 1630.696655),
				},
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
	local generation = State.WorkerGen
	ToggleFloat(true)

	local defaultHauntedFallback =
		{ Name = "Reborn Skeletons", Mob = "Reborn Skeleton", MobPos = Vector3.new(-8760, 183, 6168) }
	local activeHauntedMobInfo = GetBestHauntedMob() or defaultHauntedFallback

	task.spawn(function()
		while isAutoBone and ScriptContext.Running and generation == State.WorkerGen do
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
	local lastBoneBringTick = 0
	boneBringConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastBoneBringTick < 0.1 then
			return
		end
		lastBoneBringTick = now
		if not isAutoBone or not ScriptContext.Running or generation ~= State.WorkerGen then
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
		while isAutoBone and ScriptContext.Running and generation == State.WorkerGen do
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

						local centerPos = tHrp.Position

						local targetDistance = (centerPos - myHrp.Position).Magnitude
						if targetDistance > 80 then
							TweenTo(LookCFrame(centerPos, cfg.TweenHeight))
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
						TweenTo(LookCFrame(targetMobInfo.MobPos, cfg.TweenHeight))
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
	local generation = State.WorkerGen
	ToggleFloat(true)

	local activeMaterialMobInfo = GetBestMaterialMob()

	task.spawn(function()
		while isAutoMaterial and ScriptContext.Running and generation == State.WorkerGen do
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
	local lastMaterialBringTick = 0
	materialBringConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastMaterialBringTick < 0.1 then
			return
		end
		lastMaterialBringTick = now
		if not isAutoMaterial or not ScriptContext.Running or generation ~= State.WorkerGen then
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
		while isAutoMaterial and ScriptContext.Running and generation == State.WorkerGen do
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

			if
				myHrp
				and isReadyToAttack
				and currentTargetInstance
				and currentTargetInstance.Parent
				and currentTargetInstance:FindFirstChild("Humanoid")
				and currentTargetInstance.Humanoid.Health > 0
			then
				local tName = currentTargetInstance.Name or activeCakeMobInfo.Mob
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
	local lastCakeBringTick = 0
	cakeBringConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastCakeBringTick < 0.1 then
			return
		end
		lastCakeBringTick = now
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
						local centerPos = tHrp.Position

						if cakeBossSpawned then
							centerPos = tHrp.Position
						end

						local targetDistance = (centerPos - myHrp.Position).Magnitude
						if targetDistance > 80 then
							TweenTo(LookCFrame(centerPos, cfg.TweenHeight))
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
							TweenTo(LookCFrame(targetMobInfo.MobPos, cfg.TweenHeight))
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

			if
				myHrp
				and isReadyToAttack
				and currentTargetInstance
				and currentTargetInstance.Parent
				and currentTargetInstance:FindFirstChild("Humanoid")
				and currentTargetInstance.Humanoid.Health > 0
			then
				local tName = currentTargetInstance.Name or activeCakeMobInfo.Mob
				local enemies = workspace:FindFirstChild("Enemies")
				if enemies and enemies:FindFirstChild("Dough King") then
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
	local lastDoughBringTick = 0
	doughBringConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastDoughBringTick < 0.1 then
			return
		end
		lastDoughBringTick = now
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
						local centerPos = tHrp.Position

						if cakeDimension then
							centerPos = tHrp.Position
						end

						local targetDistance = (centerPos - myHrp.Position).Magnitude
						if targetDistance > 80 then
							TweenTo(LookCFrame(centerPos, cfg.TweenHeight))
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
								TweenTo(LookCFrame(dimPos, cfg.TweenHeight))
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
								TweenTo(LookCFrame(targetMobInfo.MobPos, cfg.TweenHeight))
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
											SafeProximity(
												prompt,
												hrp
													or (
														GetCharacter()
														and GetCharacter():FindFirstChild("HumanoidRootPart")
													)
											)
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
	if Runtime.activeTween then
		Runtime.activeTween:Cancel()
		Runtime.activeTween = nil
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
	local generation = State.WorkerGen

	ToggleFloat(true)
	AttackThread(generation)

	task.spawn(function()
		while isAutoFarm and ScriptContext.Running and generation == State.WorkerGen do
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
									TweenTo(LookCFrame(bHrp.Position, cfg.TweenHeight))
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
							if Runtime.activeTween then
								Runtime.activeTween:Cancel()
								Runtime.activeTween = nil
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
					if Runtime.activeTween then
						Runtime.activeTween:Cancel()
						Runtime.activeTween = nil
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
			task.wait(cfg.ThreadSleep)
		end
	end)
end

local function StopAutoFarm()
	isAutoFarm = false
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

lastSafePlayerPos = nil

ScriptContext:AddConnection(RunService.Stepped:Connect(function()
	if ScriptContext.Running then
		local c = player.Character
		if c then
			local hrp = c:FindFirstChild("HumanoidRootPart")
			local hasFloat = hrp and hrp:FindFirstChild("AutofarmBv") ~= nil

			-- Track last known valid (non-NaN, above-ground) position for recovery
			if hrp then
				local p = hrp.Position
				local valid = (p.X == p.X) and (p.Y == p.Y) and (p.Z == p.Z) and p.Y > -300
				if valid then
					lastSafePlayerPos = p
				end
			end
			if
				Runtime.activeTween
				or hasFloat
				or isTweeningToPlayer
				or isAutoTorch
				or isAutoFarm
				or isAutoRaidKill
				or isAutoBone
				or isAutoMaterial
				or isAutoDungeon
				or farmNearestEnabled
				or State.AutoKillVolcano
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

				-- Neutralize anomalous / NaN velocity to prevent void fall
				if hrp then
					local vel = hrp.AssemblyLinearVelocity
					local isNan = (vel.X ~= vel.X) or (vel.Y ~= vel.Y) or (vel.Z ~= vel.Z)
					local pos = hrp.Position
					local posNan = (pos.X ~= pos.X) or (pos.Y ~= pos.Y) or (pos.Z ~= pos.Z)

					if isNan or posNan then
						-- NaN poisoning detected: purge physics objects and reset cleanly
						for _, child in ipairs(hrp:GetChildren()) do
							if child:IsA("BodyVelocity") or child:IsA("BodyGyro") then
								child:Destroy()
							end
						end
						local safePos = lastSafePlayerPos or Vector3.new(0, 50, 0)
						hrp.CFrame = CFrame.new(safePos)
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
					elseif vel.Y < -200 or vel.Magnitude > 300 then
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end
		end
	end
end))

ScriptContext:AddConnection(RunService.Heartbeat:Connect(function(dt)
	if not ScriptContext.Running or not cfg.cframeSpeed then
		return
	end
	if
		Runtime.activeTween
		or isAutoFarm
		or isAutoTorch
		or isAutoBone
		or isAutoMaterial
		or isAutoDungeon
		or farmNearestEnabled
		or State.AutoKillVolcano
		or isAutoCakePrince
		or isAutoDoughKing
		or cfg.isAutoBerry
	then
		return
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp and hum and hum.Health > 0 and not hum.Sit then
		local moveDir = hum.MoveDirection
		if moveDir.Magnitude > 0 then
			local step = moveDir.Unit * ((cfg.cframeSpeedValue or 50) * dt)
			hrp.CFrame = hrp.CFrame + step
		end
	end
end))

local lastHeartbeatTick = 0
ScriptContext:AddConnection(RunService.Heartbeat:Connect(function(deltaTime)
	if not ScriptContext.Running then
		return
	end
	local now = os.clock()
	if now - lastHeartbeatTick < 0.25 then
		return
	end
	lastHeartbeatTick = now

	if cfg.autoBoat then
		State.CurrentBoat = GetBoat()
		if not State.CurrentBoat then
			local dealer = GetNearestBoatDealer()
			if dealer then
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if myHrp then
					local dealerPos = GetSafePosition(dealer)
					local dist = (myHrp.Position - dealerPos).Magnitude

					if dist > 20 then
						TweenTo(CFrame.new(dealerPos + Vector3.new(0, cfg.TweenHeight, 0)))
					else
						if Runtime.activeTween then
							Runtime.activeTween:Cancel()
							Runtime.activeTween = nil
						end
						BuyBoat()
					end
				end
			else
				if Runtime.activeTween then
					Runtime.activeTween:Cancel()
					Runtime.activeTween = nil
				end
			end
		else
			if Runtime.activeTween then
				Runtime.activeTween:Cancel()
				Runtime.activeTween = nil
			end
			BoardBoat(State.CurrentBoat)
		end
	end

	if cfg.autoSail and State.CurrentBoat then
		State.CurrentIsland = GetNearestIsland()
		if State.CurrentIsland then
			local boatSeat = State.CurrentBoat:FindFirstChild("VehicleSeat")
			if boatSeat then
				local targetPosition = State.CurrentIsland.HumanoidRootPart.Position
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

	if cfg.autoFruit and #State.FruitWaypoints > 0 then
		CollectNearestFruit()
	end
	if cfg.autoChest then
		ScanForChests()
		CollectNearestChest()
	end
	if cfg.dodgeEnabled then
		DodgeAttack()
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
	while task.wait(0.5) do
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
local raidTrackedIslandNum = 1
local raidSpawnedEnemiesSeen = false
local raidIslandCleared = false
local lastRaidWaitSpawnTick = 0

local function GetRealRaidIslandPosition(islandModel)
	if not islandModel then
		return Vector3.zero
	end
	local cf, _ = islandModel:GetBoundingBox()
	return cf.Position
end

local function GetLiveRaidStatus()
	local char = GetCharacter()
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")

	-- 1. ABSOLUTE FIRST CHECK: Player Death or Respawn in Normal Overworld
	local isDead = (not char or not hum or hum.Health <= 0)
	local isOutsideRaid = (not myHrp or myHrp.Position.X < 60000)
	local isRaiding = (player:GetAttribute("IslandRaiding") == true)

	local pGui = player:FindFirstChild("PlayerGui")
	local topHUD = pGui and pGui:FindFirstChild("Main") and pGui.Main:FindFirstChild("TopHUDList")
	local raidTimer = topHUD and topHUD:FindFirstChild("RaidTimer")
	local hasTimer = raidTimer and raidTimer.Visible == true
	local timerText = hasTimer and raidTimer.Text or ""

	local isEnded = false
	if isDead or isOutsideRaid or (not isRaiding and not hasTimer) then
		isEnded = true
	end

	if isEnded then
		raidTrackedIslandNum = 1
		raidSpawnedEnemiesSeen = false
		raidIslandCleared = false
		lastRaidWaitSpawnTick = 0
		return {
			Active = false,
			Ended = true,
			IslandNumber = 1,
			CurrentIsland = nil,
			NextIsland = nil,
			Enemies = {},
			EnemiesCount = 0,
			TimeLeft = "",
		}
	end

	local raidMap = ScriptContext:GetRaidMap()
	local islandMap = {}
	if raidMap then
		for i = 1, 5 do
			local isl = raidMap:FindFirstChild("RaidIsland" .. i) or raidMap:FindFirstChild("Island" .. i)
			if isl then
				islandMap[i] = isl
			end
		end
	end

	-- 2. Detect player's own current island using exact BoundingBox center from RaidMap
	local detectedIslandNum = nil
	local closestDist = math.huge
	if myHrp and raidMap then
		for num, isl in pairs(islandMap) do
			local realCenter = GetRealRaidIslandPosition(isl)
			local dist = (myHrp.Position - realCenter).Magnitude
			if dist < closestDist then
				closestDist = dist
				if dist <= 800 then
					detectedIslandNum = num
				end
			end
		end
	end

	-- Fallback to game's CurrentLocation attribute if between islands
	local currLoc = tostring(player:GetAttribute("CurrentLocation") or "")
	local locNum = tonumber(string.match(currLoc, "Island%s*(%d+)"))

	local resolvedIslandNum = detectedIslandNum or locNum or raidTrackedIslandNum or 1
	if resolvedIslandNum ~= raidTrackedIslandNum then
		raidTrackedIslandNum = resolvedIslandNum
		raidSpawnedEnemiesSeen = false
		raidIslandCleared = false
		lastRaidWaitSpawnTick = os.clock()
	end

	local currentIslandModel = islandMap[raidTrackedIslandNum] or islandMap[1]
	local nextIslandModel = islandMap[raidTrackedIslandNum + 1]

	-- 3. Filter active enemies specifically belonging to player's current island in RaidMap
	local activeEnemies = {}
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if enemiesFolder and currentIslandModel then
		local islandCenter = GetRealRaidIslandPosition(currentIslandModel)
		for _, enemy in ipairs(enemiesFolder:GetChildren()) do
			local eHum = enemy:FindFirstChildOfClass("Humanoid")
			local eHrp = enemy:FindFirstChild("HumanoidRootPart")
			if eHum and eHum.Health > 0 and eHrp and eHrp.Position.X > 60000 then
				local distToIsland = (eHrp.Position - islandCenter).Magnitude
				if distToIsland <= 850 then
					table.insert(activeEnemies, enemy)
				end
			end
		end
	end

	local enemyCount = #activeEnemies
	if enemyCount > 0 then
		raidSpawnedEnemiesSeen = true
		raidIslandCleared = false
	elseif raidSpawnedEnemiesSeen and enemyCount == 0 then
		raidIslandCleared = true
	end

	return {
		Active = true,
		Ended = false,
		IslandNumber = raidTrackedIslandNum,
		CurrentIsland = currentIslandModel,
		NextIsland = nextIslandModel,
		Enemies = activeEnemies,
		EnemiesCount = enemyCount,
		EnemiesSeen = raidSpawnedEnemiesSeen,
		Cleared = raidIslandCleared,
		TimeLeft = timerText,
	}
end

local function GetTargetRaidIsland()
	local status = GetLiveRaidStatus()
	if status.Ended then
		return nil, 0
	end

	-- Only advance to next island if current island was cleared of enemies
	if (status.Cleared or status.EnemiesCount == 0) and status.NextIsland then
		return status.NextIsland, status.IslandNumber + 1
	end

	if status.CurrentIsland then
		return status.CurrentIsland, status.IslandNumber
	end

	return nil, 0
end

local function StartAutoRaid()
	raidWorkerGeneration = raidWorkerGeneration + 1
	local generation = raidWorkerGeneration
	ToggleFloat(true)

	task.spawn(function()
		while isAutoRaidKill and ScriptContext.Running and generation == raidWorkerGeneration do
			if isReadyToAttack and isAutoRaidAttack and not GetLiveRaidStatus().Ended then
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
	local lastRaidBringTick = 0
	raidBringConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastRaidBringTick < 0.1 then
			return
		end
		lastRaidBringTick = now
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

		if isReadyToAttack and isAutoRaidBring and not GetLiveRaidStatus().Ended then
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

				local raidStatus = GetLiveRaidStatus()
				if raidStatus.Ended then
					isReadyToAttack = false
					currentTargetInstance = nil
					if Runtime.activeTween then
						Runtime.activeTween:Cancel()
						Runtime.activeTween = nil
					end
					ToggleFloat(false)
					task.wait(1)
					return
				end

				ToggleFloat(true)

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
					if Runtime.activeTween then
						Runtime.activeTween:Cancel()
						Runtime.activeTween = nil
					end
					ToggleFloat(false)
					currentTargetInstance = nil
					isReadyToAttack = false
					return
				end

				local targetEnemy = currentTargetInstance

				if not targetEnemy or not IsEnemyVulnerable(targetEnemy) then
					local closest = nil
					local shortestDist = math.huge

					for _, enemy in ipairs(raidStatus.Enemies) do
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
							TweenTo(LookCFrame(centerPos, cfg.TweenHeight))
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
							local iPos = GetRealRaidIslandPosition(activeIsland)
							local dist = (myHrp.Position - iPos).Magnitude

							if dist > 15000 then
								if Runtime.activeTween then
									Runtime.activeTween:Cancel()
									Runtime.activeTween = nil
								end
								ToggleFloat(true)
								return
							end

							if activeIslandNum >= 5 and dist <= 150 then
								if Runtime.activeTween then
									Runtime.activeTween:Cancel()
									Runtime.activeTween = nil
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
							if Runtime.activeTween then
								Runtime.activeTween:Cancel()
								Runtime.activeTween = nil
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
	local generation = State.WorkerGen
	ToggleFloat(true)

	task.spawn(function()
		while farmNearestEnabled and ScriptContext.Running and generation == State.WorkerGen do
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
	local lastNearestBringTick = 0
	nearestBringConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastNearestBringTick < 0.1 then
			return
		end
		lastNearestBringTick = now
		if not farmNearestEnabled or not ScriptContext.Running or generation ~= State.WorkerGen then
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
		while farmNearestEnabled and ScriptContext.Running and generation == State.WorkerGen do
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
							TweenTo(LookCFrame(centerPos, cfg.TweenHeight))
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
	local lastDungeonBringTick = 0
	dungeonBringConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastDungeonBringTick < 0.1 then
			return
		end
		lastDungeonBringTick = now
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
					if Runtime.activeTween then
						Runtime.activeTween:Cancel()
						Runtime.activeTween = nil
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
						if Runtime.activeTween then
							Runtime.activeTween:Cancel()
							Runtime.activeTween = nil
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
							if Runtime.activeTween then
								Runtime.activeTween:Cancel()
								Runtime.activeTween = nil
							end
							return
						end

						if targetDistance > 80 then
							TweenTo(LookCFrame(centerPos, cfg.TweenHeight))
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
								if Runtime.activeTween then
									Runtime.activeTween:Cancel()
									Runtime.activeTween = nil
								end
								myHrp.CFrame = CFrame.new(exitPos)
							end
						else
							if Runtime.activeTween then
								Runtime.activeTween:Cancel()
								Runtime.activeTween = nil
							end
						end
					else
						if Runtime.activeTween then
							Runtime.activeTween:Cancel()
							Runtime.activeTween = nil
						end
					end
				end
			end)
			task.wait()
		end
	end)
end

local function StartAutoKillVolcano()
	local generation = State.WorkerGen
	ToggleFloat(true)

	task.spawn(function()
		while State.AutoKillVolcano and ScriptContext.Running and generation == State.WorkerGen do
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
	local lastVolcanoBringTick = 0
	volcanoBringConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastVolcanoBringTick < 0.1 then
			return
		end
		lastVolcanoBringTick = now
		if not State.AutoKillVolcano or generation ~= State.WorkerGen then
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
		while State.AutoKillVolcano and ScriptContext.Running and generation == State.WorkerGen do
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
							TweenTo(LookCFrame(centerPos, cfg.TweenHeight))
							lastEvasionMoveAt = now
						else
							TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
						end

						isReadyToAttack = (GetSafePosition(tHrp) - myHrp.Position).Magnitude <= cfg.MaxPullRange
					end
				else
					currentTargetInstance = nil
					isReadyToAttack = false
					if Runtime.activeTween then
						Runtime.activeTween:Cancel()
						Runtime.activeTween = nil
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
								if hasFireTouch then
									SafeTouch(torch, hrp)
									litTorches[i] = true
									task.wait(0.3)
								else
									local dist = (hrp.Position - torch.Position).Magnitude
									if dist > 10 then
										TweenTo(CFrame.new(torch.Position + Vector3.new(0, 5, 0), torch.Position))
									else
										local touched = SafeTouch(torch, hrp)
										if touched then
											litTorches[i] = true
											if Runtime.activeTween then
												Runtime.activeTween:Cancel()
												Runtime.activeTween = nil
											end
											task.wait(0.5)
										end
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

autoFarmMagnetWorkerGen = 0
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

						local centerPos = tHrp.Position
						local dist = (hrp.Position - centerPos).Magnitude

						if dist > 80 then
							TweenTo(LookCFrame(centerPos, cfg.TweenHeight))
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
						if Runtime.activeTween then
							Runtime.activeTween:Cancel()
							Runtime.activeTween = nil
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

local function FindMagnetEnemies()
	local results = {}
	local myChar = GetCharacter()

	local function checkMagnetEnemy(obj)
		if not obj or not obj:IsA("Model") or obj == myChar then
			return
		end
		if obj:GetAttribute("MagnetEnemy") == true then
			local eHum = obj:FindFirstChildOfClass("Humanoid")
			local eHrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart", true)
			if eHum and eHrp and eHum.Health > 0 then
				table.insert(results, obj)
			end
		end
	end

	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if enemiesFolder then
		for _, e in ipairs(enemiesFolder:GetChildren()) do
			checkMagnetEnemy(e)
		end
	end

	for _, container in ipairs(enemyContainerPaths) do
		if container then
			for _, obj in ipairs(container:GetChildren()) do
				checkMagnetEnemy(obj)
			end
		end
	end

	local bonusFolder = game:GetService("ReplicatedStorage"):FindFirstChild("BonusMoments")
	if bonusFolder then
		for _, sub in ipairs(bonusFolder:GetChildren()) do
			if sub:IsA("Folder") or sub:IsA("Model") then
				for _, obj in ipairs(sub:GetChildren()) do
					checkMagnetEnemy(obj)
				end
			end
		end
	end

	return results
end

local function BuildAutoFarmMagnetRoute()
	local routes = {}
	local sea1QuestData = Quests and Quests.Sea1

	if not sea1QuestData then
		return routes
	end

	local islandList = {}
	for islandName, islandCF in pairs(Islands and Islands.Sea1 or {}) do
		if typeof(islandCF) == "CFrame" then
			table.insert(islandList, {
				Name = islandName,
				CFrame = islandCF,
			})
		end
	end

	table.sort(islandList, function(a, b)
		return a.Name < b.Name
	end)

	for index, island in ipairs(islandList) do
		routes[index] = {
			Name = island.Name,
			CFrame = island.CFrame,
			Points = {},
			Checked = {},
		}
	end

	local function getNearestIslandIndex(point)
		local bestIndex = nil
		local bestDistance = math.huge

		for index, island in ipairs(islandList) do
			local distance = (island.CFrame.Position - point).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				bestIndex = index
			end
		end

		return bestIndex
	end

	local seen = {}

	for questName, questEntries in pairs(sea1QuestData) do
		if type(questEntries) == "table" then
			for _, entry in ipairs(questEntries) do
				local mobName = entry and entry.Mob
				local mobPos = entry and entry.MobPos

				if mobName and typeof(mobPos) == "Vector3" then
					local anchorPos = entry.NPC
					if typeof(anchorPos) ~= "Vector3" then
						anchorPos = mobPos
					end

					local islandIndex = getNearestIslandIndex(anchorPos)
					local route = islandIndex and routes[islandIndex]

					if route then
						local key = string.lower(tostring(mobName))
							.. "|"
							.. string.format("%.2f|%.2f|%.2f", mobPos.X, mobPos.Y, mobPos.Z)

						if not seen[key] then
							seen[key] = true
							table.insert(route.Points, {
								Key = key,
								Mob = mobName,
								MobPos = mobPos,
								Quest = questName,
							})
						end
					end
				end
			end
		end
	end

	local filtered = {}
	for _, route in ipairs(routes) do
		if #route.Points > 0 then
			table.insert(filtered, route)
		end
	end

	table.sort(filtered, function(a, b)
		local ai = math.huge
		local bi = math.huge

		for i, island in ipairs(islandList) do
			if island.Name == a.Name then
				ai = i
			end
			if island.Name == b.Name then
				bi = i
			end
		end

		return ai < bi
	end)

	for _, route in ipairs(filtered) do
		table.sort(route.Points, function(a, b)
			if string.lower(tostring(a.Mob)) == string.lower(tostring(b.Mob)) then
				return a.Key < b.Key
			end
			return string.lower(tostring(a.Mob)) < string.lower(tostring(b.Mob))
		end)
	end

	return filtered
end

local function ScanRenderedMagnetEnemies(route, renderRadius)
	local folder = workspace:FindFirstChild("Enemies")
	if not folder or not route then
		return {}
	end

	local radius = renderRadius or 180
	local found = {}
	local children = folder:GetChildren()

	for _, point in ipairs(route.Points or {}) do
		for _, enemy in ipairs(children) do
			if enemy:IsA("Model")
				and string.lower(enemy.Name) == string.lower(tostring(point.Mob))
			then
				local eHrp = enemy:FindFirstChild("HumanoidRootPart")
					or enemy:FindFirstChildWhichIsA("BasePart", true)
				local eHum = enemy:FindFirstChildOfClass("Humanoid")

				if eHrp and eHum and eHum.Health > 0
					and (eHrp.Position - point.MobPos).Magnitude <= radius
				then
					found[point.Key] = enemy
					break
				end
			end
		end
	end

	return found
end

local function StartAutoFarmMagnet()
	autoFarmMagnetWorkerGen = autoFarmMagnetWorkerGen + 1
	local gen = autoFarmMagnetWorkerGen
	ToggleFloat(true)

	task.spawn(function()
		while cfg.isAutoFarmMagnet and ScriptContext.Running and gen == autoFarmMagnetWorkerGen do
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
		end
	end)

	local magnetBringConn
	local lastMagnetBringTick = 0
	magnetBringConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastMagnetBringTick < 0.1 then
			return
		end
		lastMagnetBringTick = now
		if not cfg.isAutoFarmMagnet or not ScriptContext.Running or gen ~= autoFarmMagnetWorkerGen then
			if magnetBringConn then
				magnetBringConn:Disconnect()
				magnetBringConn = nil
			end
			return
		end

		local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
		if not myHrp then
			return
		end

		local magnetMobs = FindMagnetEnemies()
		local target = currentTargetInstance
		local gatherPos = target and GetSafePosition(target)

		if not gatherPos or gatherPos == Vector3.zero then
			gatherPos = myHrp.Position
		end

		if gatherPos and gatherPos ~= Vector3.zero then
			for _, enemy in ipairs(magnetMobs) do
				local eHrp = enemy:FindFirstChild("HumanoidRootPart")
					or enemy:FindFirstChildWhichIsA("BasePart", true)
				local eHum = enemy:FindFirstChildOfClass("Humanoid")

				if eHrp and eHum and eHum.Health > 0 then
					local dist = (eHrp.Position - myHrp.Position).Magnitude
					if dist <= cfg.BringRadius then
						if eHrp.CanCollide then
							eHrp.CanCollide = false
						end
						if eHum.PlatformStand == false then
							eHum.PlatformStand = true
						end

						local gatherCF = CFrame.new(gatherPos)
						if cfg.BringMethod == "Tween" then
							local d = (eHrp.Position - gatherPos).Magnitude
							if d > 4 then
								if not Runtime.activeMagnetTweens[eHrp] then
									local dur = math.clamp(d / 400, 0.05, 0.25)
									local tween = TweenService:Create(
										eHrp,
										TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
										{ CFrame = gatherCF }
									)
									Runtime.activeMagnetTweens[eHrp] = tween
									tween.Completed:Connect(function()
										Runtime.activeMagnetTweens[eHrp] = nil
										if eHrp and eHrp.Parent then
											eHrp.CFrame = gatherCF
										end
									end)
									tween:Play()
								end
							else
								eHrp.CFrame = gatherCF
							end
						else
							eHrp.CFrame = gatherCF
						end
					end
				end
			end
		end
	end)
	ScriptContext:AddConnection(magnetBringConn)

	task.spawn(function()
		local routes = BuildAutoFarmMagnetRoute()
		local routeIndex = 1
		local pointIndex = 1
		local routeWaitUntil = 0
		local spawnedCheckDone = false

		while cfg.isAutoFarmMagnet and ScriptContext.Running and gen == autoFarmMagnetWorkerGen do
			local ok, err = pcall(function()
				local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
				if not myHrp then
					task.wait()
					return
				end

				local now = os.clock()
				local magnetMobs = FindMagnetEnemies()

				-- Keep any rendered magnet enemy inside workspace.Enemies.
				local enemiesFolder = workspace:FindFirstChild("Enemies")
				if enemiesFolder then
					for _, m in ipairs(magnetMobs) do
						if m.Parent ~= enemiesFolder then
							m:SetAttribute("DisableDistanceCulling", true)
							pcall(function()
								m.Parent = enemiesFolder
							end)
						end
					end
				end

				-- Existing rendered enemies always take priority.
				if #magnetMobs > 0 then
					currentTargetInstance = magnetMobs[1]
					local target = currentTargetInstance
					local tHrp = target:FindFirstChild("HumanoidRootPart")
						or target:FindFirstChildWhichIsA("BasePart", true)

					if tHrp then
						local centerPos = GetSafePosition(tHrp)
						local dist = (centerPos - myHrp.Position).Magnitude

						if now - lastEvasionMoveAt >= cfg.EvasionTick then
							lastEvasionMoveAt = now
							if dist > 80 then
								TweenTo(LookCFrame(centerPos, cfg.TweenHeight))
							else
								TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
							end
						end

						isReadyToAttack = (centerPos - myHrp.Position).Magnitude <= cfg.MaxPullRange
					end

					-- Keep route cursor where it is while mobs are being farmed.
					spawnedCheckDone = false
					routeWaitUntil = 0
					return
				end

				currentTargetInstance = nil
				isReadyToAttack = false

				if #routes == 0 then
					task.wait(0.5)
					return
				end

				if routeIndex > #routes then
					routeIndex = 1
					pointIndex = 1
					for _, route in ipairs(routes) do
						table.clear(route.Checked)
					end
				end

				local route = routes[routeIndex]
				if not route then
					routeIndex = 1
					pointIndex = 1
					return
				end

				-- Once one enemy from an island is streamed in, scan the whole
				-- island immediately. A and B loaded from the same island are
				-- both marked as checked so the movement stays deterministic.
				if spawnedCheckDone and #route.Points > 0 then
					local rendered = ScanRenderedMagnetEnemies(route, 220)
					for _, point in ipairs(route.Points) do
						if rendered[point.Key] then
							route.Checked[point.Key] = true
						end
					end
					spawnedCheckDone = false
				end

				-- Skip every point that was already rendered/processed.
				while pointIndex <= #route.Points
					and route.Checked[route.Points[pointIndex].Key]
				do
					pointIndex = pointIndex + 1
				end

				-- Finished this island; move to the next one without randomness.
				if pointIndex > #route.Points then
					routeIndex = routeIndex + 1
					pointIndex = 1
					routeWaitUntil = 0
					spawnedCheckDone = false
					return
				end

				local point = route.Points[pointIndex]
				local targetPos = point.MobPos
				local distance = (myHrp.Position - targetPos).Magnitude

				if distance > 70 then
					routeWaitUntil = 0
					spawnedCheckDone = false
					TweenTo(LookCFrame(targetPos, cfg.TweenHeight))
					return
				end

				-- At MobPos: wait only ~0.3s for streaming/render.
				if routeWaitUntil == 0 then
					routeWaitUntil = os.clock() + 0.3
					return
				end

				if os.clock() < routeWaitUntil then
					return
				end

				-- Check workspace.Enemies, mark all matching points on this
				-- island as processed. Missing mobs are skipped immediately.
				local rendered = ScanRenderedMagnetEnemies(route, 220)
				for _, routePoint in ipairs(route.Points) do
					if rendered[routePoint.Key] then
						route.Checked[routePoint.Key] = true
					end
				end

				route.Checked[point.Key] = true
				pointIndex = pointIndex + 1
				routeWaitUntil = 0
				spawnedCheckDone = true
			end)

			if not ok then
				warn("[Auto Farm Magnet Error]: " .. tostring(err))
				task.wait(0.1)
			end

			task.wait(cfg.ThreadSleep)
		end

		StopAllActivities()
	end)
end

local function StartStandaloneAutoAttackThread()
	task.spawn(function()
		while ScriptContext.Running do
			if isAutoAttackEnabled and not (isAutoFarm and isReadyToAttack) then
				local now = os.clock()
				local interval = (attackSpeedMode == "Super Fast Attack") and cfg.AttackIntervalSuper
					or cfg.AttackIntervalFast

				if now - lastAttackAt >= interval then
					local myChar = GetCharacter()
					local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

					if myHrp then
						local target = currentTargetInstance
						local tHum = target and target:FindFirstChildOfClass("Humanoid")
						if not target or not target.Parent or not tHum or tHum.Health <= 0 then
							local minDist = math.max(cfg.HitRadius or 60, 85)

							local function checkCandidate(entity)
								if not entity or entity == myChar or entity == player.Character then
									return
								end
								if IsAllyOrSameTeam(entity) then
									return
								end
								local eHrp = entity:FindFirstChild("HumanoidRootPart")
									or entity:FindFirstChildWhichIsA("BasePart", true)
								local eHum = entity:FindFirstChildOfClass("Humanoid")
								if eHrp and eHum and eHum.Health > 0 then
									local d = (GetSafePosition(eHrp) - myHrp.Position).Magnitude
									if d < minDist then
										minDist = d
										target = entity
									end
								end
							end

							local enemiesFolder = workspace:FindFirstChild("Enemies")
							if enemiesFolder then
								for _, enemy in ipairs(enemiesFolder:GetChildren()) do
									checkCandidate(enemy)
								end
							end

							local charsFolder = workspace:FindFirstChild("Characters")
							if charsFolder then
								for _, c in ipairs(charsFolder:GetChildren()) do
									checkCandidate(c)
								end
							end

							for _, otherP in ipairs(game:GetService("Players"):GetPlayers()) do
								if otherP ~= player and otherP.Character then
									checkCandidate(otherP.Character)
								end
							end
						end

						if
							target
							and target:FindFirstChildOfClass("Humanoid")
							and target:FindFirstChildOfClass("Humanoid").Health > 0
						then
							ExecuteAttack(myChar, myHrp, false, target.Name)
							lastAttackAt = now
						end
					end
				end
			end

			if
				isAutoAttackEnabled
				and (attackSpeedMode == "Super Fast Attack" or attackSpeedMode == "Beta Fast Attack")
			then
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
	State.EliteHunterGen = State.EliteHunterGen + 1
	local gen = State.EliteHunterGen

	local currentEliteEnemy = nil
	local currentEliteLocation = nil
	local spawnIndex = 1

	task.spawn(function()
		while isAutoEliteHunter and ScriptContext.Running and gen == State.EliteHunterGen do
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
	local lastEliteBringTick = 0
	eliteBringConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastEliteBringTick < 0.1 then
			return
		end
		lastEliteBringTick = now
		if not isAutoEliteHunter or not ScriptContext.Running or gen ~= State.EliteHunterGen then
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

		while isAutoEliteHunter and ScriptContext.Running and gen == State.EliteHunterGen do
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
							if now - lastEvasionMoveAt >= cfg.EvasionTick then
								lastEvasionMoveAt = now
								if targetDistance > 80 then
									TweenTo(LookCFrame(centerPos, cfg.TweenHeight))
								else
									TweenTo(CFrame.new(centerPos + currentEvasionOffset, centerPos))
								end
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
						if Runtime.activeTween then
							Runtime.activeTween:Cancel()
							Runtime.activeTween = nil
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

Lonum.UNC({
	Tests = {
		"Drawing",
		"require",
		"checkcaller",
		"getnamecallmethod",
		"hookmetamethod",
		"hookfunction",
		"newcclosure",
		"getgenv",
		"getrenv",
		"getfenv",
		"getsenv",
		"getgc",
		"filtergc",
		"getinstances",
		"getnilinstances",
		"getloadedmodules",
		"getrunningscripts",
		"getscripts",
		"gethui",
		"cloneref",
		"compareinstances",
		"getrawmetatable",
		"setrawmetatable",
		"sethiddenproperty",
		"gethiddenproperty",
		"setscriptable",
		"isscriptable",
		"setreadonly",
		"isreadonly",
		"getconnections",
		"firetouchinterest",
		"fireproximityprompt",
		"setrenderproperty",
		"getrenderproperty",
		"isrenderobj",
		"cleardrawcache",
		"readfile",
		"writefile",
		"appendfile",
		"loadfile",
		"isfile",
		"isfolder",
		"makefolder",
		"listfiles",
		"queue_on_teleport",
		"setclipboard",
		"restorefunction",
		"clonefunction",
		"iscclosure",
		"islclosure",
		"isexecutorclosure",
		"getfunctionhash",
		"getscriptbytecode",
		"getscriptclosure",
		"getscriptfromthread",
		"getcallingscript",
		"getcallbackvalue",
		"decompile",
		"firesignal",
		"replicatesignal",
		"setfpscap",
		"debug.getinfo",
		"debug.getconstant",
		"debug.getconstants",
		"debug.getupvalue",
		"debug.getupvalues",
		"debug.setupvalue",
		"debug.setconstant",
		"debug.getstack",
		"debug.setstack",
	},
	MinimumRate = 60,
	AutoClose = true,
	CloseDelay = 1.5,
	Title = "Wait, Load Script... (Make sure you see UNC Test!)",
	Callback = function(uncReport)
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
	end
})

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
DEV_USER_ID = {
	[10899280539] = true,
	[10289245854] = true,
	["10899280539"] = true,
	["10289245854"] = true,
}

currentUid = player and player.UserId
if DEV_USER_ID[currentUid] or DEV_USER_ID[tostring(currentUid)] then
	Tabs.Developers = Window:CreateTab("Developers")
	Tabs.Developers:CreateSection("Auto Farm")

	devEnemyList = {}
	seenEnemies = {}

	for _, boss in ipairs(BOSSES) do
		if boss.Name and not seenEnemies[boss.Name] then
			seenEnemies[boss.Name] = true
			table.insert(devEnemyList, "[Boss] " .. boss.Name)
		end
	end

	for _, seaTable in pairs(Quests) do
		for _, stageList in pairs(seaTable) do
			for _, p in ipairs(stageList) do
				local label = p.Mob or p.Name
				if label and not seenEnemies[label] then
					seenEnemies[label] = true
					table.insert(devEnemyList, label)
				end
			end
		end
	end

	table.sort(devEnemyList)

	selectedDevEnemy = devEnemyList[1] or ""
	Tabs.Developers:CreateDropdown({
		Name = "Select Enemy / Boss",
		Options = devEnemyList,
		CurrentOption = { selectedDevEnemy },
		MultipleOptions = false,
		Flag = "DevEnemySelectDrop",
		Callback = function(Option)
			selectedDevEnemy = Option[1]
		end,
	})

	Tabs.Developers:CreateButton({
		Name = "Set New Position",
		Callback = function()
			local myHrp = GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart")
			if not myHrp then
				if getgenv().LonumObject then
					getgenv().LonumObject:Notify({
						Title = "Dev Tool Error",
						Content = "HumanoidRootPart not found!",
						Duration = 3,
					})
				end
				return
			end

			local newPos = myHrp.Position
			local cleanName = string.gsub(selectedDevEnemy, "^%[Boss%]%s*", "")
			local updated = false

			for _, boss in ipairs(BOSSES) do
				if boss.Name == cleanName then
					boss.NPC = newPos
					boss.MobPos = newPos
					updated = true
					break
				end
			end

			for _, sea in ipairs({ SEA1, SEA2, SEA3 }) do
				for _, p in ipairs(sea) do
					if p.Mob == cleanName or p.Name == cleanName then
						p.MobPos = newPos
						updated = true
					end
				end
			end

			local posString = string.format("Vector3.new(%.2f, %.2f, %.2f)", newPos.X, newPos.Y, newPos.Z)
			print(string.format("[Dev Tool] Set New Position for %s: %s", cleanName, posString))

			useUnc("setclipboard", { posString })

			if getgenv().LonumObject then
				getgenv().LonumObject:Notify({
					Title = "Position Updated",
					Content = string.format("%s set to %s (Copied!)", cleanName, posString),
					Duration = 4,
				})
			end
		end,
	})
end

do
	Tabs.Quests:CreateSection("Auto Get Swords (Auto Kill Boss)")

	swordBosses = {
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
							if
								db
								and db:FindFirstChildOfClass("Humanoid")
								and db:FindFirstChildOfClass("Humanoid").Health > 0
								and hrp
							then
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
	specialQuests = {
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
				NavigateAndBuyMelee(name)
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
				NavigateAndBuyMelee(name)
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
			isAutoFarm = false
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
Tabs.Sea1:CreateToggle({
	Name = "Auto Grappling Hook",
	CurrentValue = false,
	Flag = "ToggleAutoGrapplingHook",
	Callback = function(Value)
		cfg.isAutoGrapplingHook = Value
		if Value then
			task.spawn(function()
				local bmRemote = game:GetService("ReplicatedStorage")
					:WaitForChild("Remotes")
					:WaitForChild("BonusMomentsRemoteFunction")
				local netFolder = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net")
				local useZipline = netFolder:WaitForChild("RE/UseZipline")
				local guideRemote = netFolder:WaitForChild("RF/BonusMomentsGuide")

				while cfg.isAutoGrapplingHook do
					local success, err = pcall(function()
						local myChar = GetCharacter()
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if not myHrp then
							task.wait(0.5)
							return
						end

						local hookPickup = workspace:FindFirstChild("GroundPickupGrapplingHook")
						if hookPickup then
							local ropePart = hookPickup:FindFirstChild("Rope")
							local hookPart = hookPickup:FindFirstChild("hook.001")
							local prompt = hookPart and hookPart:FindFirstChildWhichIsA("ProximityPrompt", true)

							if ropePart and ropePart:IsA("BasePart") then
								local dist = (myHrp.Position - ropePart.Position).Magnitude
								if dist > 15 then
									TweenTo(CFrame.new(ropePart.Position + Vector3.new(0, 3, 0)))
									task.wait(0.3)
								end
							end

							if prompt then
								SafeProximity(prompt, myHrp)
								task.wait(0.5)
							end
						end

						local throwPos = Vector3.new(-1278.500977, 74.385216, -249.276627)
						local distToThrow = (myHrp.Position - throwPos).Magnitude
						if distToThrow > 10 then
							TweenTo(CFrame.new(throwPos))
							local startTime = os.clock()
							while
								cfg.isAutoGrapplingHook
								and (myHrp.Position - throwPos).Magnitude > 10
								and (os.clock() - startTime < 10)
							do
								task.wait(0.1)
							end
						end
						task.wait(0.3)

						local throwArgs = {
							"Zipline Repair",
							"Throw",
							"Grappling Hook",
							{
								Type = "AimData",
								Origin = CFrame.new(
									-1283.0609130859375,
									74.38521575927734,
									-263.3216552734375,
									-0.7788268327713013,
									0,
									0.6272390484809875,
									0,
									1.0000001192092896,
									-0,
									-0.6272390484809875,
									0,
									-0.7788268327713013
								),
								Target = Vector3.new(-1482.841064453125, 78.08488464355469, -15.25970458984375),
								InitialVelocity = Vector3.new(
									-135.9412841796875,
									146.5705108642578,
									168.79486083984375
								),
								Arc = {
									ArcLength = 340.6257979931375,
									AimDegrees = 20,
									HighestPointOffsetY = 54.791302827463625,
									HighestPoint = Vector3.new(
										-1486.3323974609375,
										129.176513671875,
										-10.924606323242188
									),
									TargetOffsetX = 318.5072021484375,
									GroundPoint = Vector3.new(
										-1486.3323974609375,
										74.38521575927734,
										-10.924606323242188
									),
									GroundPointOffsetX = 324.0734015001714,
									TargetOffsetY = 3.6996688842773438,
								},
							},
						}
						bmRemote:InvokeServer(unpack(throwArgs))
						task.wait(1.5)

						local jungleMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle")
						local ziplinePair = jungleMap and jungleMap:FindFirstChild("ZiplinePair")
						local ziplineObj = ziplinePair and ziplinePair:FindFirstChild("zipline")
						if ziplinePair and ziplineObj then
							useZipline:FireServer(ziplinePair, ziplineObj)
						end
						task.wait(2)

						guideRemote:InvokeServer("InteractQuestGiver", "JungleQuest")
						task.wait(0.5)

						cfg.isAutoGrapplingHook = false
						if Window and Window.Flags and Window.Flags["ToggleAutoGrapplingHook"] then
							Window.Flags["ToggleAutoGrapplingHook"]:Set(false)
						end
						if getgenv().LonumObject then
							getgenv().LonumObject:Notify({
								Title = "Auto Grappling Hook",
								Content = "Quest Zipline Repair successfully completed!",
								Duration = 5,
							})
						end
					end)

					if not success then
						warn("[Auto Grappling Hook Error]: " .. tostring(err))
						task.wait(2)
					end
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
									SafeProximity(
										prompt,
										hrp or (GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart"))
									)
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
										SafeProximity(
											pearlPrompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
						local map = workspace:FindFirstChild("Map")
						local searchFolder = (map and map:FindFirstChild("Colosseum")) or workspace
						for _, obj in ipairs(searchFolder:GetChildren()) do
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
							local map = workspace:FindFirstChild("Map")
							local searchFolder = (map and map:FindFirstChild("Magma")) or workspace
							for _, obj in ipairs(searchFolder:GetChildren()) do
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
						local map = workspace:FindFirstChild("Map")
						local searchFolder = (map and map:FindFirstChild("Fountain")) or workspace
						for _, obj in ipairs(searchFolder:GetChildren()) do
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
						local map = workspace:FindFirstChild("Map")
						local searchFolder = (map and map:FindFirstChild("Fountain")) or workspace
						for _, obj in ipairs(searchFolder:GetChildren()) do
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

						local map = workspace:FindFirstChild("Map")
						local searchFolder = (map and map:FindFirstChild("Windmill")) or workspace
						for _, obj in ipairs(searchFolder:GetChildren()) do
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
									local eHum = enemy:FindFirstChildOfClass("Humanoid")
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

						local map = workspace:FindFirstChild("Map")
						local searchFolder = (map and map:FindFirstChild("Jungle")) or workspace
						for _, obj in ipairs(searchFolder:GetChildren()) do
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
									local eHum = enemy:FindFirstChildOfClass("Humanoid")
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

						local map = workspace:FindFirstChild("Map")
						local searchFolder = (map and map:FindFirstChild("Desert")) or workspace
						for _, obj in ipairs(searchFolder:GetChildren()) do
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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

						local map = workspace:FindFirstChild("Map")
						local searchFolder = (map and map:FindFirstChild("Snow")) or workspace
						for _, obj in ipairs(searchFolder:GetChildren()) do
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
									local eHum = enemy:FindFirstChildOfClass("Humanoid")
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
										SafeProximity(
											prompt,
											hrp
												or (
													GetCharacter()
													and GetCharacter():FindFirstChild("HumanoidRootPart")
												)
										)
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
			isAutoFarm = false
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
					if
						db
						and db:FindFirstChildOfClass("Humanoid")
						and db:FindFirstChildOfClass("Humanoid").Health > 0
						and hrp
					then
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
					if
						cap
						and cap:FindFirstChildOfClass("Humanoid")
						and cap:FindFirstChildOfClass("Humanoid").Health > 0
						and hrp
					then
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
					if
						indra
						and indra:FindFirstChildOfClass("Humanoid")
						and indra:FindFirstChildOfClass("Humanoid").Health > 0
						and hrp
					then
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
	Name = "FPS Boost",
	CurrentValue = false,
	Flag = "UNC_FPSBoost",
	Callback = function(Value)
		task.spawn(function()
			if Value then
				SmartSetProperty(game.Lighting, "Technology", 2)
				pcall(function()
					local l = game:GetService("Lighting")
					l.GlobalShadows = false
					l.FogEnd = 9e9
					l.EnvironmentDiffuseScale = 0
					l.EnvironmentSpecularScale = 0
				end)
				pcall(function()
					local t = workspace.Terrain
					t.WaterWaveSize = 0
					t.WaterWaveSpeed = 0
					t.WaterReflectance = 0
					t.WaterTransparency = 1
				end)
				for _, v in ipairs(game:GetService("Lighting"):GetDescendants()) do
					if
						v:IsA("BlurEffect")
						or v:IsA("SunRaysEffect")
						or v:IsA("ColorCorrectionEffect")
						or v:IsA("BloomEffect")
						or v:IsA("DepthOfFieldEffect")
						or v:IsA("Atmosphere")
					then
						pcall(function()
							v.Enabled = false
						end)
					end
				end
				for _, v in ipairs(workspace:GetDescendants()) do
					if v:IsA("BasePart") then
						pcall(function()
							v.Material = Enum.Material.SmoothPlastic
							v.CastShadow = false
						end)
					elseif v:IsA("Texture") or v:IsA("Decal") then
						pcall(function()
							v.Transparency = 1
						end)
					elseif
						v:IsA("ParticleEmitter")
						or v:IsA("Trail")
						or v:IsA("Beam")
						or v:IsA("Sparkles")
						or v:IsA("Fire")
						or v:IsA("Smoke")
					then
						pcall(function()
							v.Enabled = false
						end)
					end
				end
			else
				SmartSetProperty(game.Lighting, "Technology", 3)
				pcall(function()
					local l = game:GetService("Lighting")
					l.GlobalShadows = true
					l.FogEnd = 10000
					l.EnvironmentDiffuseScale = 1
					l.EnvironmentSpecularScale = 1
				end)
				pcall(function()
					local t = workspace.Terrain
					t.WaterWaveSize = 0.15
					t.WaterWaveSpeed = 10
					t.WaterReflectance = 1
					t.WaterTransparency = 0.3
				end)
				for _, v in ipairs(game:GetService("Lighting"):GetDescendants()) do
					if
						v:IsA("BlurEffect")
						or v:IsA("SunRaysEffect")
						or v:IsA("ColorCorrectionEffect")
						or v:IsA("BloomEffect")
						or v:IsA("DepthOfFieldEffect")
						or v:IsA("Atmosphere")
					then
						pcall(function()
							v.Enabled = true
						end)
					end
				end
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
		isAutoFarm = Value
		if isAutoFarm then
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
			isAutoFarm = false
			if FarmToggle then
				FarmToggle:Set(false)
			end
			State.WorkerGen = State.WorkerGen + 1

			if Runtime.activeTween then
				Runtime.activeTween:Cancel()
				Runtime.activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil

			StartFarmNearest()
		else
			State.WorkerGen = State.WorkerGen + 1
			StopAllActivities()
		end
	end,
})
Tabs.Main:CreateToggle({
	Name = "Auto Farm Magnet",
	CurrentValue = false,
	Flag = "ToggleAutoFarmMagnet",
	Callback = function(Value)
		cfg.isAutoFarmMagnet = Value
		if Value then
			isAutoFarm = false
			farmNearestEnabled = false
			isAutoBone = false
			isAutoMaterial = false
			isAutoCakePrince = false
			isAutoDoughKing = false
			if FarmToggle then
				FarmToggle:Set(false)
			end

			autoFarmMagnetWorkerGen = autoFarmMagnetWorkerGen + 1
			if Runtime.activeTween then
				Runtime.activeTween:Cancel()
				Runtime.activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil
			StartAutoFarmMagnet()
		else
			autoFarmMagnetWorkerGen = autoFarmMagnetWorkerGen + 1
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
			isAutoFarm = false
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
			isAutoFarm = false
			FarmToggle:Set(false)
			isAutoMaterial = false

			State.WorkerGen = State.WorkerGen + 1

			if Runtime.activeTween then
				Runtime.activeTween:Cancel()
				Runtime.activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil
			lastTargetPos = nil
			StartAutoBone()
		else
			State.WorkerGen = State.WorkerGen + 1
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
			isAutoFarm = false
			isAutoBone = false
			isAutoMaterial = false
			if FarmToggle then
				FarmToggle:Set(false)
			end

			cakePrinceWorkerGeneration = cakePrinceWorkerGeneration + 1

			if Runtime.activeTween then
				Runtime.activeTween:Cancel()
				Runtime.activeTween = nil
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
			isAutoFarm = false
			isAutoBone = false
			isAutoMaterial = false
			if FarmToggle then
				FarmToggle:Set(false)
			end

			doughKingWorkerGeneration = doughKingWorkerGeneration + 1

			if Runtime.activeTween then
				Runtime.activeTween:Cancel()
				Runtime.activeTween = nil
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
			isAutoFarm = false
			isAutoBone = false
			isAutoMaterial = false
			if FarmToggle then
				FarmToggle:Set(false)
			end

			State.EliteHunterGen = State.EliteHunterGen + 1
			if Runtime.activeTween then
				Runtime.activeTween:Cancel()
				Runtime.activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil
			StartAutoEliteHunter()
		else
			isEliteHunterActive = false
			State.EliteHunterGen = State.EliteHunterGen + 1
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
		if Runtime.activeTween then
			Runtime.activeTween:Cancel()
			Runtime.activeTween = nil
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
							if hasFireTouch then
								SafeTouch(lawButton, myHrp)
							else
								local dist = (myHrp.Position - lawButton.Position).Magnitude
								if dist > 15 then
									TweenTo(CFrame.new(lawButton.Position))
								else
									SafeTouch(lawButton, myHrp)
								end
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
			isAutoFarm = false
			isAutoBone = false
			if FarmToggle then
				FarmToggle:Set(false)
			end
			State.WorkerGen = State.WorkerGen + 1

			if Runtime.activeTween then
				Runtime.activeTween:Cancel()
				Runtime.activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil
			lastTargetPos = nil
			StartAutoMaterialFarm()
		else
			State.WorkerGen = State.WorkerGen + 1
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
		if Runtime.activeTween then
			Runtime.activeTween:Cancel()
			Runtime.activeTween = nil
		end
	end,
})

Tabs.Main:CreateDropdown({
	Name = "Attack Speed",
	Options = { "Fast Attack", "Super Fast Attack", "Beta Fast Attack" },
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
			if Runtime.activeTween then
				Runtime.activeTween:Cancel()
				Runtime.activeTween = nil
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
		State.AutoEmber = Value

		if Value then
			task.spawn(function()
				while State.AutoEmber do
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
			isAutoFarm = false
			isAutoRaidKill = false
			isAutoBone = false
			if FarmToggle then
				FarmToggle:Set(false)
			end
			State.WorkerGen = State.WorkerGen + 1
			StartAutoHaze()
		else
			State.WorkerGen = State.WorkerGen + 1
			StopAllActivities()
		end
	end,
})

Tabs.Travel:CreateToggle({
	Name = "Auto Kill Enemy",
	CurrentValue = false,
	Flag = "AutoKillEnemy",
	Callback = function(Value)
		State.AutoKillVolcano = Value
		if Value then
			isAutoFarm = false
			if FarmToggle then
				FarmToggle:Set(false)
			end
			State.WorkerGen = State.WorkerGen + 1

			if Runtime.activeTween then
				Runtime.activeTween:Cancel()
				Runtime.activeTween = nil
			end
			isReadyToAttack = false
			currentTargetInstance = nil

			StartAutoKillVolcano()
		else
			State.WorkerGen = State.WorkerGen + 1
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
					elseif not Runtime.activeTween then
						myHrp.CFrame = lookCFrame
					end
					for _, keyCode in ipairs(Runtime.skillKeys) do
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
		if not Value and Runtime.activeTween then
			Runtime.activeTween:Cancel()
			Runtime.activeTween = nil
			ToggleFloat(false)
		end
	end,
})

Tabs.Travel:CreateToggle({
	Name = "Auto Collect Fruit",
	CurrentValue = false,
	Flag = "AutoFruitEnabled",
	Callback = function(Value)
		cfg.autoFruit = Value
		if not Value and Runtime.activeTween then
			Runtime.activeTween:Cancel()
			Runtime.activeTween = nil
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

		if Runtime.activeTween then
			Runtime.activeTween:Cancel()
			Runtime.activeTween = nil
		end
	end,
})

Tabs.Settings:CreateSection("CFrame Speed (Undetected)")

Tabs.Settings:CreateToggle({
	Name = "CFrame WalkSpeed",
	CurrentValue = cfg.cframeSpeed,
	Flag = "CFrameWalkSpeedToggle",
	Callback = function(Value)
		cfg.cframeSpeed = Value
	end,
})

Tabs.Settings:CreateSlider({
	Name = "CFrame Speed Magnitude",
	Range = { 10, 250 },
	Increment = 5,
	CurrentValue = cfg.cframeSpeedValue,
	Flag = "CFrameSpeedMagSlider",
	Callback = function(Value)
		cfg.cframeSpeedValue = Value
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
			isAutoFarm = false
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

local function GetCurrentSeaIslands()
	local _, seaNum = GetCurrentSea()
	local seaKey = (seaNum == 3 and "Sea3") or (seaNum == 2 and "Sea2") or "Sea1"
	local options = {}
	local seaTable = Islands[seaKey] or Islands["Sea1"]
	for name, _ in pairs(seaTable) do
		table.insert(options, name)
	end
	table.sort(options)
	return options
end

islandOptions = GetCurrentSeaIslands()

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

selectedIslandToTeleport = islandOptions[1] or ""
Tabs.Travel:CreateDropdown({
	Name = "Select Island",
	Options = islandOptions,
	CurrentOption = { selectedIslandToTeleport },
	MultipleOptions = false,
	Flag = "TeleportIslandDrop",
	Callback = function(Option)
		selectedIslandToTeleport = Option[1]
	end,
})

isTeleportingToIsland = false
teleportIslandWorker = 0
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

		local targetCFrame = GetIslandCFrame(selectedIslandToTeleport)
		if not targetCFrame then
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

		isAutoFarm = false
		isAutoBone = false
		isAutoMaterial = false
		isAutoCakePrince = false
		isAutoDoughKing = false
		isAutodoughKing = false
		isAutoEliteHunter = false
		State.AutoKillVolcano = false
		cfg.autoSeaBeast = false
		cfg.isTeleportingToIsland = true
		State.WorkerGen = State.WorkerGen + 1
		if FarmToggle then
			FarmToggle:Set(false)
		end

		isTeleportingToIsland = true
		teleportIslandWorker = teleportIslandWorker + 1
		local gen = teleportIslandWorker

		local safeCFrame = targetCFrame * CFrame.new(0, 80, 0)
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
					if dist > 35 then
						if not isTeleporting and not Runtime.activeTween then
							TweenTo(safeCFrame)
						end
					else
						isTeleportingToIsland = false
						cfg.isTeleportingToIsland = false
						StopAllActivities()
						if Window and Window.Flags and Window.Flags["ToggleTeleportIsland"] then
							Window.Flags["ToggleTeleportIsland"]:Set(false)
						end
					end
				end
				task.wait(0.2)
			end
		end)
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
			isAutoFarm = false
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
					local playerInfo = GetPlayerDisplayInfo(targetPlayer)
					if playerInfo and (playerInfo.IsFriendly or playerInfo.IsSameMarine) then
						return
					end
					local tHrp = targetPlayer.Character.HumanoidRootPart
					TweenTo(tHrp.CFrame * CFrame.new(0, cfg.TweenHeight, 0))
				else
					if Runtime.activeTween then
						Runtime.activeTween:Cancel()
						Runtime.activeTween = nil
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
					local playerInfo = GetPlayerDisplayInfo(targetPlayer)
					if playerInfo and (playerInfo.IsFriendly or playerInfo.IsSameMarine) then
						return
					end
					local tHrp = targetPlayer.Character.HumanoidRootPart
					local bg = myHrp:FindFirstChild("BodyGyroClip")
					local lookCFrame =
						CFrame.lookAt(myHrp.Position, Vector3.new(tHrp.Position.X, myHrp.Position.Y, tHrp.Position.Z))
					if bg then
						bg.CFrame = lookCFrame
					elseif not Runtime.activeTween then
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
	if State.AutoKillVolcano then
		return "Auto Volcano"
	end
	if isAutoMaterial then
		return "Auto Material (" .. tostring(selectedMaterialTarget) .. ")"
	end
	if isAutoFarm then
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
HandlePlayerESP("ESPPlayers")

Tabs.Status:CreateToggle({
	Name = "ESP Chests",
	CurrentValue = false,
	Flag = "ESPChests",
	Callback = function(Value)
		getgenv().ESPChests = Value
	end,
})
HandleUniversalESP(function()
	local chests = {}
	local chestFolder = workspace:FindFirstChild("ChestModels")
	if chestFolder then
		for _, c in ipairs(chestFolder:GetChildren()) do
			table.insert(chests, c)
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
HandleUniversalESP(function()
	local fruits = {}
	for _, v in ipairs(workspace:GetChildren()) do
		if IsFruitEntity(v) then
			table.insert(fruits, v)
		end
	end
	return fruits
end, "ESP_Fruit", Color3.fromRGB(255, 0, 100), "ESPFruits")

local function GetServerStirsAndWeather()
	local data = {
		StirsText = "None / Inactive",
		WeatherText = "Clear Sky",
		ActiveAwakenedBoss = nil,
		MagnetEvent = nil,
		SystemText = "FPS: - | Ping: - | Mem: -",
	}

	pcall(function()
		local stats = game:GetService("Stats")
		local ping = "0"
		pcall(function()
			local perfStats = stats:FindFirstChild("Network") and stats.Network:FindFirstChild("ServerStatsItem")
			local dataPing = perfStats and perfStats:FindFirstChild("Data Ping")
			ping = dataPing and tostring(math.floor(dataPing:GetValue())) or "0"
		end)
		local mem = math.floor(stats:GetTotalMemoryUsageMb())
		local fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
		data.SystemText = string.format("FPS: %d | Ping: %dms | Mem: %dMB", fps, tonumber(ping) or 0, mem)
	end)

	pcall(function()
		local Net = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
			and game:GetService("ReplicatedStorage").Modules:FindFirstChild("Net")
		local hintRemote = Net and Net:FindFirstChild("RF/RequestNextRaidHint")
		if hintRemote then
			local res = hintRemote:InvokeServer()
			if res and type(res) == "table" then
				local bossName = tostring(res.Boss or "Boss")
				local islandName = tostring(res.Island or "Island")
				local state = tostring(res.State or "Scheduled")
				local seconds = tonumber(res.Seconds) or 0
				local mins = math.max(1, math.ceil(seconds / 60))

				if state == "Arming" then
					data.StirsText = string.format("[Arming] %s about to stir on %s", bossName, islandName)
				elseif state == "Deferred" then
					data.StirsText = string.format("[Deferred] %s waiting on %s", bossName, islandName)
				elseif state == "Armed" or state == "Triggered" then
					data.StirsText = string.format("[Active] %s on %s", bossName, islandName)
					data.ActiveAwakenedBoss = bossName
				else
					data.StirsText = string.format("%s on %s in ~%dm", bossName, islandName, mins)
				end
			end
		end

		local function checkAwakenedModel(e)
			if not e or not e:IsA("Model") then
				return false
			end
			local hum = e:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				if
					e:GetAttribute("IsAwakened")
					or e:GetAttribute("Awakened")
					or e:GetAttribute("BossPrimed")
					or e:FindFirstChild("BossHealthBar")
				then
					data.ActiveAwakenedBoss = e.Name
					local statusPrefix = "[Boss]"
					data.StirsText = string.format(
						"%s %s (HP: %d/%d)",
						statusPrefix,
						e.Name,
						math.floor(hum.Health),
						math.floor(hum.MaxHealth)
					)
					return true
				end
			end
			return false
		end

		local enemiesFolder = workspace:FindFirstChild("Enemies")
		local foundAwakened = false
		if enemiesFolder then
			for _, e in ipairs(enemiesFolder:GetChildren()) do
				if checkAwakenedModel(e) then
					foundAwakened = true
					break
				end
			end
		end

		-- Check unrendered / culled models in ReplicatedStorage containers
		if not foundAwakened then
			for _, container in ipairs(enemyContainerPaths) do
				if container then
					for _, e in ipairs(container:GetChildren()) do
						if checkAwakenedModel(e) then
							foundAwakened = true
							break
						end
					end
				end
				if foundAwakened then
					break
				end
			end
		end

		local weatherEvents = {}
		local celestialCd = workspace:GetAttribute("CelestialEventCountdown")
		local celestialActive = workspace:GetAttribute("CelestialEventActive")
		local lightningTime = workspace:GetAttribute("LightningEventTimeLeft")
		local corruptedTime = workspace:GetAttribute("CorruptedEventTimeLeft")
		local seaTheme = workspace.Terrain and workspace.Terrain:GetAttribute("SeaTheme") or "Default"

		if celestialActive then
			table.insert(weatherEvents, "Celestial Surge (Active)")
		elseif celestialCd and celestialCd > 0 then
			table.insert(weatherEvents, string.format("Celestial Surge (%ds)", math.floor(celestialCd)))
		end

		if lightningTime and lightningTime > 0 then
			table.insert(weatherEvents, string.format("Lightning Event (%ds)", math.floor(lightningTime)))
		end

		if corruptedTime and corruptedTime > 0 then
			table.insert(weatherEvents, string.format("Corrupted Event (%ds)", math.floor(corruptedTime)))
		end

		if seaTheme and seaTheme ~= "Default" then
			table.insert(weatherEvents, "Theme: " .. tostring(seaTheme))
		end

		if #weatherEvents > 0 then
			data.WeatherText = table.concat(weatherEvents, " | ")
		else
			data.WeatherText = "Clear Sky"
		end

		local magnetTokensFolder = workspace:FindFirstChild("_WorldOrigin")
			and workspace._WorldOrigin:FindFirstChild("InteractiveEffects")
			and workspace._WorldOrigin.InteractiveEffects:FindFirstChild("MagnetEventTokens")
		local magnetCfg = game.ReplicatedStorage:FindFirstChild("EventConfig")
			and game.ReplicatedStorage.EventConfig:FindFirstChild("MagnetEvent26")

		if magnetCfg then
			local ok, cfgData = pcall(function()
				return require(magnetCfg)
			end)
			if ok and cfgData and cfgData.ENABLED then
				local tokenCount = 0
				if magnetTokensFolder then
					for _, f in ipairs(magnetTokensFolder:GetChildren()) do
						tokenCount = tokenCount + #f:GetChildren()
					end
				end
				if tokenCount > 0 then
					data.MagnetEvent = string.format("Active (%d Tokens)", tokenCount)
				else
					data.MagnetEvent = "Inactive"
				end
			else
				data.MagnetEvent = "Inactive"
			end
		else
			data.MagnetEvent = "Inactive"
		end
	end)

	return data
end

task.spawn(function()
	while ScriptContext.Running do
		pcall(function()
			local info = GetServerStirsAndWeather()
			getgenv().lastStirsText = info.StirsText
			getgenv().lastWeatherText = info.WeatherText
			getgenv().lastMagnetEventText = info.MagnetEvent or "Inactive"
			getgenv().lastSystemText = info.SystemText
			getgenv().lastAwakenedBossData = info

			if SystemLabel and SystemLabel.SetText then
				SystemLabel:SetText("System: " .. info.SystemText)
			end
			if StirsLabel and StirsLabel.SetText then
				StirsLabel:SetText("Stirs: " .. info.StirsText)
			end
			if WeatherLabel and WeatherLabel.SetText then
				WeatherLabel:SetText("Weather: " .. info.WeatherText)
			end
			if MagnetEventLabel and MagnetEventLabel.SetText then
				MagnetEventLabel:SetText("Magnet Event: " .. (info.MagnetEvent or "Inactive"))
			end
		end)
		task.wait(1.5)
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
				task.wait(1.5)
				pcall(function()
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
		ShowStirs = true,
		ShowWeather = true,
		ShowMagnetEvent = true,
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
					local phaseName = "Moon: 0/5"
					pcall(function()
						local sky = game:GetService("Lighting"):FindFirstChildOfClass("Sky")
							or game:GetService("Lighting"):FindFirstChild("Sky")
						if sky and sky.MoonTextureId then
							local tid = tostring(sky.MoonTextureId)
							if string.find(tid, "9709149431") then
								phaseName = "Moon: 5/5 (Full Moon)"
							elseif string.find(tid, "9709149052") then
								phaseName = "Moon: 4/5"
							elseif string.find(tid, "9709143733") then
								phaseName = "Moon: 3/5"
							elseif string.find(tid, "9709150401") then
								phaseName = "Moon: 2/5"
							elseif string.find(tid, "9709149680") then
								phaseName = "Moon: 1/5"
							else
								phaseName = "Moon: 0/5"
							end
						else
							local phaseNum = Lighting:GetAttribute("MoonPhase") or 0
							phaseName = MoonPhases[phaseNum] or (tostring(phaseNum) .. " (Unknown)")
						end
					end)
					local isBlueMoon = Lighting:GetAttribute("IsBlueMoon") or false
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
					if getgenv().HUD_Config.ShowStirs then
						table.insert(hudLines, "Stirs: " .. tostring(getgenv().lastStirsText or "None / Inactive"))
					end
					if getgenv().HUD_Config.ShowWeather then
						table.insert(hudLines, "Weather: " .. tostring(getgenv().lastWeatherText or "Clear Sky"))
					end
					if getgenv().HUD_Config.ShowMagnetEvent then
						table.insert(
							hudLines,
							"Magnet Event: " .. tostring(getgenv().lastMagnetEventText or "Inactive")
						)
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
	Name = "HUD: Stirs",
	CurrentValue = true,
	Flag = "HUD_ShowStirs",
	Callback = function(v)
		getgenv().HUD_Config.ShowStirs = v
	end,
})
Tabs.Status:CreateToggle({
	Name = "HUD: Weather",
	CurrentValue = true,
	Flag = "HUD_ShowWeather",
	Callback = function(v)
		getgenv().HUD_Config.ShowWeather = v
	end,
})
Tabs.Status:CreateToggle({
	Name = "HUD: Magnet Event",
	CurrentValue = true,
	Flag = "HUD_ShowMagnetEvent",
	Callback = function(v)
		getgenv().HUD_Config.ShowMagnetEvent = v
	end,
})

Lonum:Notify({
	Title = "Mega Farm Loaded",
	Content = "Script is ready with optimized cross-platform support.",
	Duration = 5,
})

getgenv().LonumObject = Lonum
