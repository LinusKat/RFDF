--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local src = script.Parent

local RemotePacketSizeCounter = require(src.Parent._packages.RemotePacketSizeCounter)
local NetworkInternalSchemas = require(src.InternalSchemas)
local CommonTypes = require(src.Parent.CommonTypes)

local Squash = require(src.Parent._packages.Squash)
local Sift = require(src.Parent._packages.Sift)

local Memory = require(src.Parent.Util.Memory)
local Util = require(src.Util)

local LemonSignal = require(src.Parent._packages.LemonSignal)

local RateLimit = require(script.Parent.RateLimit)

const BANDWIDTH_MEMORY_LENGTH = 60
const FLUSH_RATE = 1 / 60

const MAXIMUM_DATA_SIZE = 10 * 1024

const BROADCAST_TYPE_ENUM = {
	ALL_CLIENTS = 1,
	PRIVATE = 2,
	WHITELIST = 3,
}

const Enums = {
	BROADCAST_TYPE_ENUM = BROADCAST_TYPE_ENUM,
}

const VERBOSE = false

local print_limit = RateLimit(5, 0.04)
local raw_print = print

const function print(...: any)
	if not VERBOSE then
		return
	end
	if not print_limit() then
		return
	end
	raw_print(...)
end

const function print_cursor(cursor: any)
	if not VERBOSE then
		return
	end
	if not print_limit() then
		return
	end
	Squash.print(cursor)
end

local NetworkEndpoint = {}
NetworkEndpoint.__index = NetworkEndpoint

function NetworkEndpoint.new(
	Network: Network,
	u8id: number,
	tag: string,
	Schema: SquashCursor,
	DDoS_Settings: DDoS_ProtectionSettings
)
	assert(RunService:IsServer(), "Net Server cannot be ran on client.")

	local self = setmetatable({}, NetworkEndpoint) :: NetworkEndpoint
	self._ddos_protection_settings = Sift.Dictionary.copyDeep(DDoS_Settings)
	self._rcv_history = {}

	self._schema = Schema

	self._network = Network
	self._u8id = u8id
	self._tag = tag

	self.Enums = Enums

	self._network:_register_endpoint(tag, u8id, self)

	self.OnServerEvent = LemonSignal.new()

	return self
end

function NetworkEndpoint._rcv(self: NetworkEndpoint, Origin: Player, Batch: CommonTypes.Array<buffer>)
	debug.profilebegin("rcv_endpoint_batch")

	for k, packet in ipairs(Batch) do
		debug.profilebegin("deserialize_packet_and_dispatch")

		local cursor = Squash.frombuffer(packet)
		print_cursor(cursor)
		local raw = { self._schema.des(cursor) }
		print(raw)

		local processed = Util.RecursivePacketInstanceProcessing(false, raw)
		print(processed)

		print("ok")
		print("fire")
		task.spawn(function()
			self.OnServerEvent:Fire(Origin, table.unpack(processed))
		end)
		print("done")

		debug.profileend()
	end

	debug.profileend()
end

function NetworkEndpoint._send(self: NetworkEndpoint, BroadcastType: number, Whitelist: CommonTypes.Array<Player>?, ...)
	local raw = Util.RecursivePacketInstanceProcessing(true, { ... })

	local cursor = Squash.cursor()
	self._schema.ser(cursor, table.unpack(raw))

	local serialized = Squash.tobuffer(cursor)
	print_cursor(cursor)
	print(serialized)

	table.insert(self._network._batch, {
		ID = self._u8id,
		Packet = serialized,
		Type = BroadcastType,
		Whitelist = Whitelist,
	})
end
--[=[
@within Endpoint
]=]
function NetworkEndpoint.FireClient(self: NetworkEndpoint, Target: Player, ...: any)
	self:_send(BROADCAST_TYPE_ENUM.PRIVATE, { Target }, ...)
end
--[=[
@within Endpoint
]=]
function NetworkEndpoint.FireAllClients(self: NetworkEndpoint, ...: any)
	self:_send(BROADCAST_TYPE_ENUM.ALL_CLIENTS, {}, ...)
end
--[=[
@within Endpoint
]=]
function NetworkEndpoint.FireClients(self: NetworkEndpoint, Clients: CommonTypes.Array<Player>, ...: any)
	self:_send(BROADCAST_TYPE_ENUM.WHITELIST, Sift.Array.copy(Clients), ...)
end

export type Callback = (Origin: Player, ...any) -> nil
export type Connection = { Disconnect: (self: any) -> nil }

export type DDoS_ProtectionSettings = {
	MAX_CALLS_PER_HISTORY: number,
	HISTORY_LENGTH_FRAMES: number,

	MAX_BYTES_PER_CALL: number,

	EXPECT: ((...any) -> boolean)?,
	STRICT: boolean,
}

export type NetworkEndpoint = typeof(NetworkEndpoint) & {
	_ddos_protection_settings: DDoS_ProtectionSettings,
	_rcv_history: CommonTypes.Dictionary<Player, { Tick: number, Size: number }>,

	_schema: SquashSerDes,

	_network: Network,
	_u8id: number,
	_tag: string,

	Enums: Enums,
	OnServerEvent: any,
}

local Network = {}
Network.__index = Network

function Network.new(): Network
	local self = setmetatable({}, Network) :: self
	self._registered_endpoints = {}

	self._bandwidth_history =
		{ rcv = Memory.new(BANDWIDTH_MEMORY_LENGTH), snd = Memory.new(BANDWIDTH_MEMORY_LENGTH), rcv_calls = {} }

	self._batch = {}
	self._previous_flush = tick()

	self.NetworkEndpoint = NetworkEndpoint
	self.Enums = Enums

	self:_initialize_server()

	return self
end

function Network._initialize_server(self: self)
	if not src:FindFirstChild("_com") then
		local _com = Instance.new("RemoteEvent")
		_com.Parent = src
		_com.Name = "_com"

		self._remote = _com
	end

	self._remote.OnServerEvent:Connect(function(Origin: Player, ...)
		debug.profilebegin("RFDF_Net_server/rcv")

		print("net-rcv from:", Origin)

		local bucket = { ... }
		for _, v in ipairs(bucket) do
			if typeof(v) == "buffer" then
				continue
			end
			Origin:Kick("RFDF/Net/BATCH CONTAINS NON BUFFER TYPES")
		end

		local bytes = RemotePacketSizeCounter.GetPacketSize({
			RunContext = "Client",
			RemoteType = "RemoteEvent",
			PacketData = { ... },
		})
		print(bytes)
		if bytes >= MAXIMUM_DATA_SIZE then
			Origin:Kick("RFDF/Net/DATA SIZE EXCEEDS LIMIT")
		end

		table.insert(self._bandwidth_history.rcv_calls, bytes)

		self:_on_receive(Origin, ...)

		debug.profileend()
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		task.defer(self._on_heartbeat, self, dt)
	end)
end

function Network._on_receive(self: self, Origin: Player, ...)
	debug.profilebegin("deserialize_batch")

	local batch_cursor = Squash.frombuffer(...)
	print_cursor(batch_cursor)
	local events = NetworkInternalSchemas.Batch.des(batch_cursor)
	print(events)

	for key, sub_batch in pairs(events) do
		local endpoint = self._registered_endpoints[key]
		if not endpoint then
			continue
		end

		endpoint:_rcv(Origin, sub_batch)
	end

	debug.profileend()
end

function Network._register_endpoint(self: self, Tag: string, u8id: number, Endpoint: NetworkEndpoint)
	assert(
		self._registered_endpoints[u8id] == nil,
		string.format("Endpoint already exists at ID: %s creation tag: %s", tostring(u8id), Tag)
	)
	assert(
		typeof(u8id) == "number" and u8id % 1 == 0 and u8id >= 0 and u8id <= 255,
		"ID must be an unsigned 8-bit integer (0-255)"
	)

	self._registered_endpoints[u8id] = Endpoint
end

function Network._on_heartbeat(self: self, _: number)
	debug.profilebegin("RFDF_Net_server/on_heartbeat")

	local t = tick()
	local do_flush = (t - self._previous_flush) >= FLUSH_RATE

	if do_flush then
		--print("flush")
		self:_flush()
		self._previous_flush = t

		table.clear(self._batch)
	end

	debug.profileend()
end

function Network._flush(self: self)
	if Sift.isEmpty(self._batch) then
		return
	end

	debug.profilebegin("flush")

	local individual_batches = {} :: { [Player]: { { buffer } } }

	for _, payload in ipairs(self._batch) do
		local targets = Players:GetPlayers()

		if payload.Type == BROADCAST_TYPE_ENUM.PRIVATE or payload.Type == BROADCAST_TYPE_ENUM.WHITELIST then
			targets = payload.Whitelist
		end

		for _, player in ipairs(targets :: CommonTypes.Array<Player>) do
			local endpoint_map = individual_batches[player]
			if not endpoint_map then
				endpoint_map = {}
				individual_batches[player] = endpoint_map
			end

			local bufferList = endpoint_map[payload.ID]
			if not bufferList then
				bufferList = {}
				endpoint_map[payload.ID] = bufferList
			end

			table.insert(bufferList, payload.Packet)
		end
	end

	local snd_bytes = RemotePacketSizeCounter.BaseRemoteOverhead + RemotePacketSizeCounter.TypeOverhead

	for player, endpoint_map in pairs(individual_batches) do
		local cursor = Squash.cursor()
		NetworkInternalSchemas.Batch.ser(cursor, endpoint_map)

		local serialized = Squash.tobuffer(cursor)

		snd_bytes += RemotePacketSizeCounter.GetDataByteSize(serialized)

		self._remote:FireClient(player, serialized)
	end

	self._bandwidth_history.snd:Feed(snd_bytes)

	local rcv_bytes = 0
	for _, v in ipairs(self._bandwidth_history.rcv_calls) do
		rcv_bytes += v
	end

	table.clear(self._bandwidth_history.rcv_calls)
	self._bandwidth_history.rcv:Feed(rcv_bytes)

	debug.profileend()
end

type SquashSerDes = any --Squash.SerDes
type SquashCursor = any -- Squash.Cursor

export type Enums = typeof(Enums)

export type Network = {
	_remote: RemoteEvent,

	_registered_endpoints: CommonTypes.Array<NetworkEndpoint>,

	_bandwidth_history: { rcv: Memory.Memory, snd: Memory.Memory, rcv_calls: CommonTypes.Array<number> },

	_previous_flush: number,
	_batch: CommonTypes.Array<{ ID: number, Packet: buffer, Type: number, Whitelist: CommonTypes.Array<Player>? }>,

	NetworkEndpoint: typeof(NetworkEndpoint),
	Enums: Enums,
} & typeof(Network)
type self = Network

return Network
