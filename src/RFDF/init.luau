--[[
	Made with love by LinusKat

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
local TestService = game:GetService("TestService")
local RunService = game:GetService("RunService")

-- // Dependencies
local IrisTypes = require(script._packages._Index["linuskat_iris-implot@1.0.4"]["iris-implot"].Types)
local Iris = require(script._packages.Iris)

local Promise = require(script._packages.Promise)

local CommonTypes = require(script.CommonTypes)

local Interface = require(script._internal.Interface)

local ReplicatedRegistry = require(script._network_packages.ReplicatedRegistry)
local RemoteFunction = require(script._network_packages.RemoteFunction)
local ServerNetwork = require(script._network_packages.Server)
local ClientNetwork = require(script._network_packages.Client)
local TableToString = require(script.Util.TableToString)
local Benchmark = require(script.Util.Benchmark)
local Memory = require(script.Util.Memory)

-- // VARIABLES
local IsServer = RunService:IsServer()
local IsStudio = RunService:IsStudio()
local RunTypeString = IsServer and "Server" or "Client"

const RFDF_SETTINGS = {
	LOAD_SERVICE_TIMEOUT = 15,
	KILL_SERVICE_TIMEOUT = 2,

	LOG_HISTORY = 1000,
	LOG_VERBOSE = true,
	LOG_VERBOSE_WHITESPACE_MAX = 25,
	LOG_VERBOSE_NETWORK_DUMP_DEPTH = 1,
}

const ERROR_MESSAGES = {
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

const INTERFACE_LOG_COLORS = {
	ERROR = Color3.new(1, 0, 0),
	WARNING = Color3.new(1, 0.5, 0),
	PRINT = Color3.new(1, 1, 1),
}

-- // PRIVATE
local raw_middleware: Middleware = {}
local raw_network = {}

local function FormatDirtyLog(str: string, TracebackLevel: number?)
	assert(typeof(str) == "string", ERROR_MESSAGES.FORMAT_DIRTY_LOG_STRING_TYPE_ERROR)
	return debug.traceback(string.format("RFDF - %s: %s", RunTypeString, str), TracebackLevel or 5)
end

local function LoggingUniformWhitespace(str: string, max: number)
	return string.rep(" ", math.max(0, max - #str))
end

-- // PUBLIC
--[=[
	@class RFDF
	
]=]

local RFDF = {}
RFDF.__index = RFDF

--[=[
	Creates an RFDF instance.

	@return RFDF

]=]
function RFDF.root()
	local self = setmetatable({}, RFDF) :: self
	self._issues = {}

	self._log_stack = {}

	self._intialized = false
	self._killed = false

	self.Iris = Iris

	return self
end

function RFDF._log_verbose(self: self, color: any, describe: string)
	if color == "WARNING" then
		warn(describe)
	elseif color == "ERROR" then
		TestService:Error(describe, script, 140)
	else
		print(describe)
	end
end

function RFDF._initialize_network_folder(self: self, folder)
	local function GetEndpointFromArgs(Data: any): AnyEndpoint
		local is_replicated_registry = not Data.Schema and not Data.Timeout
		local is_remote_function = Data.Timeout

		if is_replicated_registry then
			local local_allow_write = IsServer and Data.ServerAllowWrite or Data.ClientAllowWrite
			return self.ReplicatedRegistryEndpoint.new(self.Network, {}, Data.u8id, Data.Tag, local_allow_write) :: any
		elseif is_remote_function then
			return self.RemoteFunctionEndpoint.new(
				self.Network,
				Data.u8id,
				Data.Tag,
				Data.RequestSchema,
				Data.ReplySchema,
				Data.Timeout
			) :: any
		else
			local NetworkEndpoint = self.NetworkEndpoint :: any
			return NetworkEndpoint.new(self.Network, Data.u8id, Data.Tag, Data.Schema, {}) :: any
		end
	end

	local function Require(current: Instance, cd: string)
		for _, child in current:GetChildren() do
			local childPath = string.format("%s/%s", cd, child.Name)

			if child:IsA("ModuleScript") then
				local args = require(child) :: any
				raw_network[childPath] = GetEndpointFromArgs(args)
			elseif #child:GetChildren() > 0 then
				Require(child, childPath)
			end
		end
	end

	return Require(script.Network, "")
end

function RFDF._initialize_client(self: self & ClientExposed)
	print("rfdf/root/init-client")

	self.Network = ClientNetwork.new()

	self.NetworkEndpoint = self.Network.NetworkEndpoint :: any
	self.ReplicatedRegistryEndpoint = ReplicatedRegistry :: any
	self.RemoteFunctionEndpoint = RemoteFunction :: any

	self.Iris.Init()

	local interface = Interface.new(self)
	interface:Init()

	if IsStudio then
		self.Iris:Connect(function()
			debug.profilebegin("rfdf/interface")
			interface:Render(raw_middleware)
			debug.profileend()
		end)
	end
end

function RFDF._intialize_server(self: self & ServerExposed)
	print("rfdf/root/init-server")

	self.Network = ServerNetwork.new()

	self.NetworkEndpoint = self.Network.NetworkEndpoint :: any
	self.ReplicatedRegistryEndpoint = ReplicatedRegistry :: any
	self.RemoteFunctionEndpoint = RemoteFunction :: any
end

function RFDF._register_service(self: self, Name: string, tbl: CommonServiceFunctions)
	assert(typeof(tbl) == "table", FormatDirtyLog(ERROR_MESSAGES.REGISTER_SERVICE_NOT_TABLE))
	assert(typeof(tbl.new) == "function", FormatDirtyLog(ERROR_MESSAGES.REGISTER_SERVICE_MISSING_START_FUNCTION))

	local started_service = tbl.new({ RFDF = self })
	raw_middleware[Name] = started_service

	return started_service
end

function RFDF._init_service(self: self, started_service: CommonServiceFunctions)
	--assert(typeof(started_service.Init) == "function", ERROR_MESSAGES.SERVICE_MISSING_INIT_FUNCTION)
	if typeof(started_service.Init) ~= "function" then
		return self:Log(ERROR_MESSAGES.SERVICE_MISSING_INIT_FUNCTION, "PRINT", "RFDF")
	end

	started_service:Init()
end

function RFDF._load_modules_from_array(self: self, tbl: any)
	local function catch_load_issue(err)
		if Promise.Error.isKind(err, Promise.Error.Kind.TimedOut) then
			self:Log(FormatDirtyLog(ERROR_MESSAGES.SERVICE_AWAIT_TIMEOUT), "WARNING", "RFDF")
		else
			self:Log(tostring(err), "ERROR", "RFDF")
		end
	end

	for _, instance: ModuleScript | any in tbl do
		if not instance:IsA("ModuleScript") or string.match(instance.Name, ".rfdf_ignore") then
			continue
		end

		self:RegisterService(instance :: ModuleScript)
			:timeout(RFDF_SETTINGS.LOAD_SERVICE_TIMEOUT)
			:catch(catch_load_issue)
			:awaitStatus()
	end

	self:Log("----------------------[INIT]---------------------- <", "PRINT", "")

	for name, started_service: CommonServiceFunctions in raw_middleware do
		self:InitializeService(name, started_service)
			:timeout(RFDF_SETTINGS.LOAD_SERVICE_TIMEOUT)
			:catch(catch_load_issue)
			:awaitStatus()
	end
end

--[=[
	Initializes RFDF for client or server
	
	@return ()

]=]
function RFDF.Init(self: self)
	const profile = Benchmark()

	assert(not self._intialized, ERROR_MESSAGES.INITIALIZE_ALREADY_INITIALIZED)

	if IsServer then
		self:_intialize_server()
	elseif not IsServer then
		self:_initialize_client()
	end
	self:_initialize_network_folder()

	debug.setmemorycategory("RFDF")

	self._intialized = true
	self._init_time = os.clock()

	self:Log(string.format("%s", profile()), "PRINT", "rfdf/root/init")
	self:Log(
		string.format(
			"dump network endpoints %s",
			TableToString.TableToString(raw_network, nil, nil, nil, RFDF_SETTINGS.LOG_VERBOSE_NETWORK_DUMP_DEPTH)
		),
		"PRINT",
		"rfdf/root/init"
	)
end

-- // SERVICE FUNCTIONS

--[=[
	Registers a service to RFDF, and requires it.
	@param Module ModuleScript -- Service module to register and start
 
	@return Promise<CommonServiceFunctions>

	```lua
	self.RFDF:RegisterService(ServiceModuleScript)
	```

]=]
function RFDF.RegisterService(self: self, Module: ModuleScript)
	--self:Log(string.format("Attempting to create service instance: %s", Module.Name), "PRINT", "RFDF")
	return Promise.new(function(resolve)
		const profile = Benchmark()
		local started_service = self:_register_service(Module.Name, require(Module) :: CommonServiceFunctions)

		self:Log(
			string.format(
				`CREATE -- %s %s && %s`,
				Module.Name,
				LoggingUniformWhitespace(Module.Name, RFDF_SETTINGS.LOG_VERBOSE_WHITESPACE_MAX),
				profile()
			),
			"PRINT",
			"RFDF"
		)
		-- // CREATE -- SERVICE_NAME WHITESPACE_HERE && BENCHMARK WHITESPACE_HERE

		resolve(started_service)
	end)
end

--[=[
	Runs initialization functions for the Service.
	@param name string 
	@param started_service CommonServiceFunctions
 
	@return Promise

	```lua
	self.RFDF:RegisterService(ServiceModuleScript)

	local service = self.RFDF:GetService("ServiceKey")

	self.RFDF:InitializeSerivce("ServiceKey", service)
	```

]=]
function RFDF.InitializeService(self: self, name: string, started_service: CommonServiceFunctions)
	--self:Log(string.format("Attempting to initialize service instance: %s", name), "PRINT", "RFDF")
	return Promise.new(function(resolve)
		const profile = Benchmark()
		self:_init_service(started_service)

		self:Log(
			string.format(
				`INIT -- %s %s && %s`,
				name,
				LoggingUniformWhitespace(name, RFDF_SETTINGS.LOG_VERBOSE_WHITESPACE_MAX),
				profile()
			),
			"PRINT",
			"RFDF"
		)
		-- // CREATE -- SERVICE_NAME WHITESPACE_HERE && BENCHMARK

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
	self:_load_modules_from_array(Folder:GetChildren())
end

function RFDF.LoadServicesFromArray(self: self, tbl: { ModuleScript })
	self:_load_modules_from_array(tbl)
end

function RFDF.KillRFDFInstance(self: self)
	self:Log("RFDF Instance Killed", "ERROR")

	for _, service: CommonServiceFunctions in raw_middleware do
		self:KillService(service):timeout(RFDF_SETTINGS.KILL_SERVICE_TIMEOUT):catch(function(err)
			self:Log(tostring(err), "ERROR", "RFDF")
		end)
	end

	self._killed = true
	self.Iris.Shutdown()
end

function RFDF.GetService(self: self, Key: string): (CommonServiceFunctions & any)?
	local index = raw_middleware[Key]
	assert(index, string.format("Couldn't find service @ %s", Key))

	return index
end

function RFDF.RequireEndpoint(self: self, Path: string): AnyEndpoint
	local index = raw_network[Path]
	assert(index, string.format("Couldn't find endpoint @ %s", Path))

	return index
end

-- // Utility functions
function RFDF.SetSetting(self: self, k: string, v: any)
	RFDF_SETTINGS[k] = v
end

function RFDF.GetInitTime(self: self)
	return self._init_time
end

function RFDF.ClearLogs(self: self)
	table.clear(self._log_stack)
end

function RFDF.Log(self: self, info: string, color: LogColor?, origin: string?, is_issue: boolean?, datetime: string?)
	assert(typeof(info) == "string", ERROR_MESSAGES.LOG_INTERNAL_STRING_TYPE_FAULTY)

	local log_color = nil
	if INTERFACE_LOG_COLORS[color] then
		log_color = INTERFACE_LOG_COLORS[color]
	else
		log_color = color or INTERFACE_LOG_COLORS.PRINT
	end

	local log: Log = {
		timestamp = os.clock(),
		datetime = datetime or os.date("%d/%m/%Y %H:%M:%S") :: string,

		is_issue = is_issue or false,

		origin = origin or "Unspecified",
		info = info,
		verbose_log = string.format("%s > %s", origin or "", info),

		color = log_color :: Color3,
	}

	if #self._log_stack >= RFDF_SETTINGS.LOG_HISTORY then
		table.remove(self._log_stack, 1)
	end

	table.insert(self._log_stack, log)

	if RFDF_SETTINGS.LOG_VERBOSE then
		self:_log_verbose(color, log.verbose_log)
	end

	if is_issue then
		table.insert(self._issues, log)
		error("Halt execution")
	end
end

--[[
	Sugar for :Log info "PRINT" origin
]]
function RFDF.Print(self: self, info: string, origin: string?)
	self:Log(info, "PRINT", origin)
end

--[[
	Sugar for :Log info "WARNING" origin
]]
function RFDF.Warn(self: self, info: string, origin: string?)
	self:Log(info, "WARNING", origin)
end

--[[
	Sugar for :Log info "ERROR" origin is_issue
]]
function RFDF.Error(self: self, info: string, origin: string?, is_issue: boolean?)
	self:Log(info, "ERROR", origin, is_issue)
end

-- // PRIVATE TYPES
type StartupData = CommonTypes.StartupData
type CommonServiceType = CommonTypes.CommonServiceType
type CommonServiceFunctions = CommonTypes.CommonServiceFunctions
type Middleware = CommonTypes.Middleware

type Iris = IrisTypes.Iris

type Memory = Memory.Memory

-- // PUBLIC TYPES
export type ReplicatedRegistryEndpoint = ReplicatedRegistry.Endpoint
export type ServerNetworkEndpoint = ServerNetwork.NetworkEndpoint
export type ClientNetworkEndpoint = ClientNetwork.NetworkEndpoint
export type RemoteFunctionEndpoint = RemoteFunction.Endpoint

export type AnyEndpoint =
	ReplicatedRegistryEndpoint
	| ServerNetworkEndpoint
	| ClientNetworkEndpoint
	| RemoteFunctionEndpoint

export type ClientExposed = {
	Network: ClientNetwork.Network,
	NetworkEndpoint: ClientNetwork.NetworkEndpoint,
}
export type ServerExposed = {
	Network: ServerNetwork.Network,
	NetworkEndpoint: ServerNetwork.NetworkEndpoint,
}

export type LogColor = Color3 | "ERROR" | "WARNING" | "PRINT" | string
export type Log = {
	timestamp: number,
	datetime: string,

	is_issue: boolean,

	origin: string,
	info: string,
	verbose_log: string,

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
	ReplicatedRegistryEndpoint: ReplicatedRegistryEndpoint,
	RemoteFunctionEndpoint: RemoteFunctionEndpoint,

	Iris: Iris,
} & typeof(RFDF)
type self = RFDF

return RFDF
