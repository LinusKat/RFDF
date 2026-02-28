--[[
	Started working on:
		Ridiculously - Fast - Debuggable - Framework [RFDF]
		2-12-2025 [DD/MM/YYYY]
	
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
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- // DEPENDANCIES
local IrisTypes = require(script._packages._Index["linuskat_iris-implot@1.0.4"]["iris-implot"].Types)
local Iris = require(script._packages.Iris)

local Promise = require(script._packages.Promise)
-- local Squash = require(script._packages.Squash)

local CommonTypes = require(script.CommonTypes)

local Versions = require(script.VersionHistory)
local Interface = require(script._internal.Interface)

local ReplicatedRegistry = require(script._network_packages.ReplicatedRegistry)
local ServerNetwork = require(script._network_packages.Server)
local ClientNetwork = require(script._network_packages.Client)
local Memory = require(script.Util.Memory)

-- // VARIABLES
local IsServer = RunService:IsServer()
local RunTypeString = IsServer and "Server" or "Client"

local RFDF_SETTINGS = {
	LOAD_SERVICE_TIMEOUT = 5,
	KILL_SERVICE_TIMEOUT = 1,

	LOG_HISTORY = 1000,
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
	REGISTER_SERVICE_MISSING_START_FUNCTION = "Register Service Invalid type of tbl.Start",

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
	local self = setmetatable({}:: self, RFDF)
	self._issues = {}

	self._log_stack = {}

	self._intialized = false
	self._killed = false

	self.ReplicatedRegistryEndpoint = ReplicatedRegistry:: any
	
	self.Iris = Iris
	self.Debug = {
		ShowRegistry = false,
		ShowLogs = false,
		ShowVersionHistory = false,

		ShowIrisDemoWindow = false,
	}
	self.DebugWindowsMasterToggle = false

	return self
end

function RFDF._rfdf_interface(self: self)
	local version_history_transform =
		{ Size = Iris.State(Vector2.new(400, 300)), Position = Iris.State(Vector2.new(361, 222)) }
	local registry_transform =
		{ Size = Iris.State(Vector2.new(400, 300)), Position = Iris.State(Vector2.new(361, 526)) }
	local console_transform = { Size = Iris.State(Vector2.new(400, 603)), Position = Iris.State(Vector2.new(763, 222)) }

	Iris.MenuBar()
	do
		Iris.Menu({ `RFDF` })
		do
			if Iris.MenuItem({ "Show Registry" }).clicked() then
				self.Debug.ShowRegistry = not self.Debug.ShowRegistry
			end
			if Iris.MenuItem({ "Show Logs" }).clicked() then
				self.Debug.ShowLogs = not self.Debug.ShowLogs
			end
			if Iris.MenuItem({ "Show Version History" }).clicked() then
				self.Debug.ShowVersionHistory = not self.Debug.ShowVersionHistory
			end

			if Iris.MenuItem({ "Master Toggle" }).clicked() then
				self.DebugWindowsMasterToggle = not self.DebugWindowsMasterToggle

				for k, _ in pairs(self.Debug) do
					if k == "ShowIrisDemoWindow" then
						continue
					end
					self.Debug[k] = self.DebugWindowsMasterToggle
				end
			end

			Iris.Separator()

			if Iris.MenuItem({ "Shutdown RFDF" }).clicked() then
				self:KillRFDFInstance()
			end

			Iris.Separator()

			if Iris.MenuItem({ "Show Iris Demo Window" }).clicked() then
				self.Debug.ShowIrisDemoWindow = not self.Debug.ShowIrisDemoWindow
			end
		end
		Iris.End()
	end
	Iris.End()

	if self.Debug.ShowVersionHistory then
		Iris.Window(
			{ `Version History` },
			{ size = version_history_transform.Size, position = version_history_transform.Position }
		)
		do
			for index, v in ipairs(Versions) do
				Iris.CollapsingHeader({ v.Name, index == 1 and true or false })

				Iris.Table({ 3, unpack({ true, true, true, false, false, false, true, true } :: { any }) })
				do -- // NumColumns | Header | Background | OuterBorder | InnerBorder | FixedWidth | ProportionalWidth | LimitWidth
					Iris.SetHeaderColumnIndex(1)
					do
						Iris.Text({ "Info" })
						Iris.NextColumn()

						Iris.Text({ "Author" })
						Iris.NextColumn()

						Iris.Text({ "Date" })
						Iris.NextColumn()
					end

					for _, change in ipairs(v.Data) do
						Iris.Text({ change.Info })
						Iris.NextColumn()

						Iris.Text({ change.Author })
						Iris.NextColumn()

						Iris.Text({ change.Date })
						Iris.NextColumn()
					end
				end
				Iris.End()

				Iris.End()
			end
		end
		Iris.End()
	end

	if self.Debug.ShowRegistry then
		Iris.Window(
			{ `RFDF Registry {RunTypeString}` },
			{ size = registry_transform.Size, position = registry_transform.Position }
		)
		do
			Iris.CollapsingHeader({ "Registered Services", true :: any })
			do
				Iris.Table({ 1, unpack({ true, true, true, false, false, false, true, true } :: any) })
				do -- // NumColumns | Header | Background | OuterBorder | InnerBorder | FixedWidth | ProportionalWidth | LimitWidth
					Iris.SetHeaderColumnIndex(1)
					do
						Iris.Text({ "Service Name" })
						Iris.NextColumn()
					end

					for Service in pairs(raw_middleware) do
						Iris.Text({ Service })
						Iris.NextColumn()
					end
				end
				Iris.End()
			end
			Iris.End()
		end
		Iris.End()
	end

	if self.Debug.ShowLogs then
		Iris.Window({ `RFDF Console` }, { size = console_transform.Size, position = console_transform.Position })
		do
			local filter = ""

			Iris.SameLine()
			do
				if Iris.Button({ "Clear" }).clicked() then
					self:ClearLogs()
				end

				if Iris.Button({ "Dump JSON" }).clicked() then
					local array = {}
					for _, log in ipairs(self._log_stack) do
						table.insert(array, {
							datetime = log.datetime,
							origin = log.origin,
							info = log.info,
							color = log.color and { r = log.color.R, g = log.color.G, b = log.color.B }
								or { r = 1, g = 1, b = 1 },
						})
					end

					print(HttpService:JSONEncode(array))
				end

				local filter_input = Iris.InputText({ "", "Filter" })
				local input_field = (filter_input.Instance :: any).InputField
				filter = input_field.Text
			end
			Iris.End()

			Iris.SameLine()
			do
				local import = Iris.Button({ "Import Logs" })
				local text_input = Iris.InputText({ "", "Input" })
				local input_field = (text_input.Instance :: any).InputField

				if import.clicked() then
					self:Log("-------------------------------------------------", "PRINT", "Iris Import Logs Start")

					local raw_logs = text_input.state.text.value
					local json = string.match(raw_logs, "%b[]")

					local logs = HttpService:JSONDecode(json)

					for _, log in ipairs(logs) do
						local color = log.color and Color3.new(log.color.r, log.color.g, log.color.b)
							or Color3.new(1, 1, 1)
						self:Log(log.info, color, log.origin, false, log.datetime)
					end

					input_field.Text = ""

					self:Log("-------------------------------------------------", "PRINT", "Iris Import Logs End")
				end
			end
			Iris.End()

			Iris.SameLine()
			do
				local debug_log = Iris.Button({ "Debug Log" })
				local text_input = Iris.InputText({ "", "Log" })

				if debug_log.clicked() then
					self:Log(text_input.state.text.value, "PRINT", "Iris Debug Log")
				end
			end
			Iris.End()

			Iris.Table({ 1, unpack({ true, true, true, false, false, false, true, true } :: { any }) })
			do -- // NumColumns | Header | Background | OuterBorder | InnerBorder | FixedWidth | ProportionalWidth | LimitWidth
				for index = #self._log_stack, 1, -1 do
					local log = self._log_stack[index]

					if not string.match(string.lower(log.info), filter) then
						continue
					end

					Iris.PushConfig({ TextColor = log.color })
					do
						Iris.Text({
							string.format("[%s] [%s] %s", tostring(log.datetime), log.origin, log.info),
						})
					end
					Iris.PopConfig()
					Iris.NextColumn()
				end
			end
			Iris.End()
		end
		Iris.End()
	end

	if self.Debug.ShowIrisDemoWindow then
		self.Iris.ShowDemoWindow()
	end
end

function RFDF._initialize_client(self: self)
	self.Network = ClientNetwork.new()
	self.NetworkEndpoint = self.Network.NetworkEndpoint:: any

	self.Iris.Init()

	local interface = Interface.new(self)
	interface:Init()

	self.Iris:Connect(function()
		interface:Render()
		self:_rfdf_interface()
	end)
end

function RFDF._intialize_server(self: self)
	self.Network = ServerNetwork.new()
	self.NetworkEndpoint = self.Network.NetworkEndpoint:: any
end

function RFDF._register_service(self: self, Name: string, tbl: CommonServiceFunctions)
	assert(typeof(tbl) == "table", FormatDirtyLog(ERROR_MESSAGES.REGISTER_SERVICE_NOT_TABLE))
	assert(
		typeof(tbl.Start) == "function",
		FormatDirtyLog(ERROR_MESSAGES.REGISTER_SERVICE_MISSING_START_FUNCTION)
	)

	local started_service = tbl.Start{RFDF = self}
	raw_middleware[Name] = started_service

	return started_service
end

function RFDF._init_service(self: self, started_service: CommonServiceFunctions)
	assert(typeof(started_service.Init) == "function", ERROR_MESSAGES.SERVICE_MISSING_INIT_FUNCTION)
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
	return Promise.new(function(resolve)
		local started_service = self:_register_service(Module.Name, require(Module) :: CommonServiceFunctions)
		resolve(started_service)
	end)
end

function RFDF.InitializeService(self: self, started_service: CommonServiceFunctions)
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
			self:Log(FormatDirtyLog(ERROR_MESSAGES.SERVICE_AWAIT_TIMEOUT), "WARNING")
		else
			self:Log(tostring(err), "ERROR")
		end
	end
	
	for _, instance: ModuleScript | any in ipairs(Folder:GetChildren()) do
		if not instance:IsA("ModuleScript") then
			continue
		end
		
		self:RegisterService(instance :: ModuleScript)
			:timeout(RFDF_SETTINGS.LOAD_SERVICE_TIMEOUT)
			:catch(catch_load_issue)
	end
	
	for _, started_service: CommonServiceFunctions in pairs(raw_middleware) do
		self:InitializeService(started_service)
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
				self:Log(tostring(err), "ERROR")
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

export type ExposeClient = {
	Network: ClientNetwork.Network,
	NetworkEndpoint: ClientNetwork.NetworkEndpoint,
}
export type ExposeServer = {
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

	color: Color3,
}

export type RFDF = {
	_issues: { Log },
	_log_stack: { Log },

	_intialized: boolean,
	_killed: boolean,

	_init_time: number?,

	Network: ServerNetwork.Network | ClientNetwork.Network,
	NetworkEndpoint: ClientNetwork.NetworkEndpoint | ServerNetwork.NetworkEndpoint,
	ReplicatedRegistryEndpoint: ReplicatedRegistry.Endpoint,

	Iris: Iris,
	Debug: {
		ShowRegistry: boolean,
		ShowLogs: boolean,
		ShowVersionHistory: boolean,
		ShowIrisDemoWindow: boolean,
	} & { [string]: boolean },
	DebugWindowsMasterToggle: boolean,
} & typeof(RFDF)
type self = RFDF
return RFDF
