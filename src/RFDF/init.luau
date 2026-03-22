--[[
	Started working on:
		Ridiculously - Fast - Debuggable - Framework [RFDF]
		02-12-2025 [DD/MM/YYYY]
	
	Rules of coding for producing RFDF
		1: MAX OF 3 INDENTS WITHIN FUNCTIONS (ONLY EXCEPTION BEING IRIS)
		
		2: MAX 50 CHARACTERS PER LINE
		
		3: REFRAIN FROM USING LANGUAGES OTHER THAN ENGLISH.
		
		2: NO OTHER VARIABLE WITH NO SEPERATION AFTER A COMMA 
			NO 			[index,value]
			YES 	 	[index, value]
			
		3: NO EMOJIS IN CODE IT COULD CORRUPT FILE
		
		4: FUNCTIONS USE . WITH SELF BEING TYPE CHECKED WITH SELF
			NO			[function RFDF:Hello(...)]
			YES			[function RFDF.Hello(self: self, ...)]
			
		5: USE SEMI COLON AFTER EVERY CONTINUING LINE;
		
		6: USE PROMISES BY ERYN 
			https://eryn.io/roblox-lua-promise
		
		6: Be healthy.
			* Stand up every hour for atleast a minute
			* Drink 1.5 litres of water every day
			* Eat 3 meals a day
]]

--!strict
local RunService = game:GetService("RunService")

-- // Dependencies
local IrisTypes = require(script._packages._Index["linuskat_iris-implot@1.0.4"]["iris-implot"].Types)
local Iris = require(script._packages.Iris)

local Promise = require(script._packages.Promise)
-- local Squash = require(script._packages.Squash)

local CommonTypes = require(script.CommonTypes)

local Interface = require(script._internal.Interface)

local ReplicatedRegistry = require(script._network_packages.ReplicatedRegistry)
local ServerNetwork = require(script._network_packages.Server)
local ClientNetwork = require(script._network_packages.Client)
local Memory = require("@self/Util/Memory")

-- // VARIABLES
local IsServer = RunService:IsServer()
local RunTypeString = IsServer and "Server" or "Client"

local RFDF_SETTINGS = {
	LOAD_SERVICE_TIMEOUT = 15,
	KILL_SERVICE_TIMEOUT = 1,

	LOG_HISTORY = 1000,
	LOG_VERBOSE = true,
}

local ERROR_MESSAGES = {
	-- // @STARTUP
	INITIALIZE_ALREADY_INITIALIZED = string.format(
		"RFDF - %s: Tried to intialize RFDF however RFDF is already initialized",
		RunTypeString
	),

	-- // @LOGGING
	FORMAT_DIRTY_LOG_STRING_TYPE_ERROR = string.format(
		"RFDF - %s: Tried to format log except invalid [string] type",
		RunTypeString
	),

	LOG_INTERNAL_STRING_TYPE_FAULTY = string.format(
		"RFDF - %s: Tried to internally log issue however str is not a string ",
		RunTypeString
	),

	-- // @REGISTER SERVICE
	REGISTER_SERVICE_NOT_TABLE = "Register Service Invalid type of tbl",
	REGISTER_SERVICE_MISSING_START_FUNCTION = "Register Service Invalid type of tbl.new",

	SERVICE_AWAIT_TIMEOUT = "Tried to start or intialize service however took longer than allowed",

	SERVICE_MISSING_INIT_FUNCTION = "Tried to initialize service however service does not have an Init function, ignore if service doesn't need an initialize function",

	INVALID_REMOTE_TYPE = "An error occurred while registering remote %s! %s is not a valid remote type!",
}

local LOG_COLORS = {
	ERROR = Color3.new(1, 0, 0),
	WARNING = Color3.new(1, 0.5, 0),
	PRINT = Color3.new(1, 1, 1),
}

-- // PRIVATE
local raw_middleware: Middleware = {}

local function FormatDirtyLog(str: string, TracebackLevel: number?)
	assert(typeof(str) == "string", ERROR_MESSAGES.FORMAT_DIRTY_LOG_STRING_TYPE_ERROR)
	return debug.traceback(string.format("RFDF - %s: %s", RunTypeString, str), TracebackLevel or 5)
end

-- // PUBLIC
local RFDF = {}
RFDF.__index = RFDF

function RFDF.root()
	local self = setmetatable({}, RFDF):: self
	self._issues = {}

	self._log_stack = {}

	self._intialized = false
	self._killed = false
	
	self.Iris = Iris

	return self
end

function RFDF._initialize_client(self: self & ClientExposed)
	print("rfdf/new/init-client")

	self.Network = ClientNetwork.new()

	self.NetworkEndpoint = self.Network.NetworkEndpoint:: any
	self.ReplicatedRegistryEndpoint = ReplicatedRegistry:: any

	self.Iris.Init()

	local interface = Interface.new(self)
	interface:Init()

	self.Iris:Connect(function()
		interface:Render(raw_middleware)
	end)
end

function RFDF._intialize_server(self: self & ServerExposed)
	print("rfdf/new/init-server")

	self.Network = ServerNetwork.new()

	self.NetworkEndpoint = self.Network.NetworkEndpoint:: any
	self.ReplicatedRegistryEndpoint = ReplicatedRegistry:: any
end

function RFDF._register_service(self: self, Name: string, tbl: CommonServiceFunctions)
	assert(typeof(tbl) == "table", FormatDirtyLog(ERROR_MESSAGES.REGISTER_SERVICE_NOT_TABLE))
	assert(
		typeof(tbl.new) == "function",
		FormatDirtyLog(ERROR_MESSAGES.REGISTER_SERVICE_MISSING_START_FUNCTION)
	)

	local started_service = tbl.new{RFDF = self}
	raw_middleware[Name] = started_service

	return started_service
end

function RFDF._init_service(self: self, started_service: CommonServiceFunctions)
	--assert(typeof(started_service.Init) == "function", ERROR_MESSAGES.SERVICE_MISSING_INIT_FUNCTION)
	if typeof(started_service.Init) ~= "function" then
		return print(ERROR_MESSAGES.SERVICE_MISSING_INIT_FUNCTION)
	end
	
	started_service:Init()
end

function RFDF.Init(self: self)
	assert(not self._intialized, ERROR_MESSAGES.INITIALIZE_ALREADY_INITIALIZED)

	if IsServer then
		self:_intialize_server()
	elseif not IsServer then
		self:_initialize_client()
	end

	debug.setmemorycategory("RFDF")

	self._intialized = true
	self._init_time = os.clock()
end

-- // SERVICE FUNCTIONS
function RFDF.RegisterService(self: self, Module: ModuleScript)
	self:Log(string.format("Attempting to create service instance: %s", Module.Name), "WARNING", "RFDF")
	
	return Promise.new(function(resolve)
		local started_service = self:_register_service(Module.Name, require(Module) :: CommonServiceFunctions)
		resolve(started_service)
	end)
end

function RFDF.InitializeService(self: self, name: string, started_service: CommonServiceFunctions)
	self:Log(string.format("Attempting to initialize service instance: %s", name), "WARNING", "RFDF")
	
	return Promise.new(function(resolve)
		self:_init_service(started_service)
		resolve()
	end)
end

function RFDF.KillService(self: self, started_service: CommonServiceFunctions)
	return Promise.new(function(resolve)
		started_service:Kill()
		resolve()
	end)
end

function RFDF.LoadServicesFromFolder(self: self, Folder: Folder)
	local function catch_load_issue(err)
		if Promise.Error.isKind(err, Promise.Error.Kind.TimedOut) then
			self:Log(FormatDirtyLog(ERROR_MESSAGES.SERVICE_AWAIT_TIMEOUT), "WARNING", "RFDF")
		else
			self:Log(tostring(err), "ERROR", "RFDF")
		end
	end
	
	for _, instance: ModuleScript | any in ipairs(Folder:GetChildren()) do
		if not instance:IsA("ModuleScript") or string.match(instance.Name, ".rfdf_ignore") then
			continue
		end
		
		self:RegisterService(instance :: ModuleScript)
			:timeout(RFDF_SETTINGS.LOAD_SERVICE_TIMEOUT)
			:catch(catch_load_issue)
	end
	
	for name, started_service: CommonServiceFunctions in pairs(raw_middleware) do
		self:InitializeService(name, started_service)
			:timeout(RFDF_SETTINGS.LOAD_SERVICE_TIMEOUT)
			:catch(catch_load_issue)
	end
end

function RFDF.KillRFDFInstance(self: self)
	self:Log("RFDF Instance Killed", "ERROR")
	
	for _, service: CommonServiceFunctions in pairs(raw_middleware) do
		self:KillService(service)
			:timeout(RFDF_SETTINGS.KILL_SERVICE_TIMEOUT)
			:catch(function(err)
				self:Log(tostring(err), "ERROR", "RFDF")
			end)
	end
	
	self._killed = true
	self.Iris.Shutdown()
end

function RFDF.GetService(self: self, Key: string): (CommonServiceFunctions & any)?
	return raw_middleware[Key]
end

-- // Utility functions
function RFDF.ClearLogs(self: self)
	table.clear(self._log_stack)
end

function RFDF.Log(self: self, info: string, color: LogColor?, origin: string?, is_issue: boolean?, datetime: string?)
	assert(typeof(info) == "string", ERROR_MESSAGES.LOG_INTERNAL_STRING_TYPE_FAULTY)

	local log_color = nil
	if LOG_COLORS[color] then
		log_color = LOG_COLORS[color]
	else
		log_color = color or LOG_COLORS.PRINT
	end

	local log: Log = {
		timestamp = os.clock(),
		datetime = datetime or os.date("%d/%m/%Y %H:%M:%S") :: string,

		is_issue = is_issue or false,

		origin = origin or "Unspecified",
		info = info,

		color = log_color:: Color3,
	}

	if #self._log_stack >= RFDF_SETTINGS.LOG_HISTORY then
		table.remove(self._log_stack, 1)
	end

	table.insert(self._log_stack, log)

	if is_issue then
		table.insert(self._issues, log)
	end
	
	if RFDF_SETTINGS.LOG_VERBOSE then
		print(string.format("%s %s %s %s", origin or "", info, tostring(is_issue), tostring(color)))
	end
end

-- // PRIVATE TYPES
type StartupData = CommonTypes.StartupData
type CommonServiceType = CommonTypes.CommonServiceType
type CommonServiceFunctions = CommonTypes.CommonServiceFunctions
type Middleware = CommonTypes.Middleware

type Iris = IrisTypes.Iris

type Memory = Memory.Memory

-- // PUBLIC TYPES
export type SquashSerDes = any--Squash.SerDes
export type SquashCursor = any--Squash.Cursor

export type ReplicatedRegistryServerEndpoint = ReplicatedRegistry.Endpoint & ReplicatedRegistry.ServerExposed
export type ReplicatedRegistryClientEndpoint = ReplicatedRegistry.Endpoint & ReplicatedRegistry.ClientExposed
export type ServerNetworkEndpoint = ServerNetwork.NetworkEndpoint
export type ClientNetworkEndpoint = ClientNetwork.NetworkEndpoint

export type ServerReplicatedRegistryEndpoint = ReplicatedRegistry.Endpoint & ReplicatedRegistry.ServerExposed
export type ClientReplicatedRegistryEndpoint = ReplicatedRegistry.Endpoint & ReplicatedRegistry.ClientExposed

export type ClientExposed = {
	Network: ClientNetwork.Network,
	NetworkEndpoint: ClientNetwork.NetworkEndpoint,
	ReplicatedRegistryEndpoint: ClientReplicatedRegistryEndpoint,
}
export type ServerExposed = {
	Network: ServerNetwork.Network,
	NetworkEndpoint: ServerNetwork.NetworkEndpoint,
	ReplicatedRegistryEndpoint: ServerReplicatedRegistryEndpoint,
}

export type LogColor = Color3 | "ERROR" | "WARNING" | "PRINT" | string
export type Log = {
	timestamp: number,
	datetime: string,

	is_issue: boolean,

	origin: string,
	info: string,

	color: Color3,
}

export type RFDF = {
	_issues: { Log },
	_log_stack: { Log },

	_intialized: boolean,
	_killed: boolean,

	_init_time: number?,
	
	Network: ClientNetwork.Network | ServerNetwork.Network,
	NetworkEndpoint: ServerNetworkEndpoint | ClientNetworkEndpoint,
	ReplicatedRegistryEndpoint: ServerReplicatedRegistryEndpoint | ClientReplicatedRegistryEndpoint,

	Iris: Iris,
} & typeof(RFDF)
type self = RFDF

return RFDF
