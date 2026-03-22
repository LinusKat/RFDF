--!strict
local RunService = game:GetService("RunService")

local src = script.Parent

local RemotePacketSizeCounter = require(src.Parent._packages.RemotePacketSizeCounter)
local NetworkInternalSchemas = require(src.InternalSchemas)
local CommonTypes = require(src.Parent.CommonTypes)

local Squash = require(src.Parent._packages.Squash)
local Sift = require(src.Parent._packages.Sift)

local Memory = require(src.Parent.Util.Memory)
local Util = require(src.Util)

local LemonSignal = require(src.Parent._packages.LemonSignal)

local BANDWIDTH_MEMORY_LENGTH = 60
local FLUSH_RATE = 1 / 60

local NetworkEndpoint = {}
NetworkEndpoint.__index = NetworkEndpoint

function NetworkEndpoint.new(Network: Network, u8id: number, tag: string, Schema: SquashCursor)
    assert(RunService:IsClient(), "Net Client cannot be ran on server.")

    local self = setmetatable({}, NetworkEndpoint):: NetworkEndpoint
    self._schema = Schema
    
    self._network = Network
    self._u8id = u8id
    self._tag = tag

    self._network:_register_endpoint(u8id, self)

    self.OnClientEvent = LemonSignal.new()

    return self
end

function NetworkEndpoint._rcv(self: NetworkEndpoint, Batch: CommonTypes.Array<buffer>)
	debug.profilebegin("rcv_endpoint_batch")
	
    for _, packet in ipairs(Batch) do
        debug.profilebegin("deserialize_packet_and_dispatch")

		local cursor = Squash.frombuffer(packet)
		local tuple_packed = table.pack{self._schema.des(cursor)}

        local raw = Util.RecursivePacketInstanceProcessing(false, tuple_packed[1])

        self.OnClientEvent:Fire(table.unpack(raw))

        debug.profileend()
    end

    debug.profileend()
end

function NetworkEndpoint._send(self: NetworkEndpoint, ...)
    local raw = table.unpack(Util.RecursivePacketInstanceProcessing(true, {...}))

    local cursor = Squash.cursor()
    self._schema.ser(cursor, raw)

    local serialized = Squash.tobuffer(cursor)

    if not self._network._batch[self._u8id] then
        self._network._batch[self._u8id] = {}
    end
    
    table.insert(self._network._batch[self._u8id], serialized)
end

function NetworkEndpoint.FireServer(self: NetworkEndpoint, ...: any)
    self:_send(...)
end

export type Connection = any

export type NetworkEndpoint = {
    _schema: SquashSerDes,

    _network: Network,
    _u8id: number,
    _tag: string,

    OnClientEvent: any,
} & typeof(NetworkEndpoint)

local Network = {}
Network.__index = Network

function Network.new(): Network
    assert(RunService:IsClient(), "Net Client cannot be ran on server.")

    local self = setmetatable({}, Network):: self
    self._remote = src:WaitForChild("_com", 100):: RemoteEvent

    self._registered_endpoints = {}
    
    self._bandwidth_history = {rcv = Memory.new(BANDWIDTH_MEMORY_LENGTH), snd = Memory.new(BANDWIDTH_MEMORY_LENGTH), rcv_calls = {}}

    self._previous_flush = tick()
    self._batch = {}

    self.NetworkEndpoint = NetworkEndpoint
    
    self:_initialize_client()

    return self
end

function Network._initialize_client(self: self)
   self._remote.OnClientEvent:Connect(function(...)
        debug.profilebegin("RFDF_Net_client/rcv")

        local bytes = RemotePacketSizeCounter.GetPacketSize{RunContext = "Server", RemoteType = "RemoteEvent", PacketData = {...}}
        table.insert(self._bandwidth_history.rcv_calls, bytes)
        
        self:_on_receive(...)

        debug.profileend()
   end)

    RunService.Heartbeat:Connect(function(dt: number)
        task.defer(self._on_heartbeat, self, dt)
    end)
end

function Network._on_receive(self: self, ...)
    debug.profilebegin("deserialize_batch")

    local batch_cursor = Squash.frombuffer(...)
	local events = NetworkInternalSchemas.Batch.des(batch_cursor)
	
    for key, sub_batch in pairs(events) do
		local endpoint = self._registered_endpoints[key]
        if not endpoint then continue end

        endpoint:_rcv(sub_batch)
    end

    debug.profileend()
end

function Network._register_endpoint(self: self, u8id: number, Endpoint: NetworkEndpoint)
    assert(self._registered_endpoints[u8id] == nil, string.format("Endpoint already exists at ID: %s", tostring(u8id)))
    assert(
        typeof(u8id) == "number"
        and u8id % 1 == 0
        and u8id >= 0
        and u8id <= 255,
        "ID must be an unsigned 8-bit integer (0-255)"
    )

    self._registered_endpoints[u8id] = Endpoint
end

function Network._on_heartbeat(self: self, _: number)
    debug.profilebegin("RFDF_Net_client/on_heartbeat")

    local t = tick()
    local do_flush = (t - self._previous_flush) >= FLUSH_RATE

    if do_flush then
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

    local cursor = Squash.cursor()
    NetworkInternalSchemas.Batch.ser(cursor, self._batch)

    local serialized = Squash.tobuffer(cursor)

    local snd_bytes = RemotePacketSizeCounter.GetPacketSize{RunContext = "Client", RemoteType = "RemoteEvent", PacketData = {serialized}}
    self._bandwidth_history.snd:Feed(snd_bytes)

	self._remote:FireServer(serialized)

    local rcv_bytes = 0
    for _, v in ipairs(self._bandwidth_history.rcv_calls) do
        rcv_bytes += v
    end

    table.clear(self._bandwidth_history.rcv_calls)
    self._bandwidth_history.rcv:Feed(rcv_bytes)

    debug.profileend()
end

type SquashSerDes = any --Squash.SerDes
type SquashCursor = any --Squash.Cursor

export type Network = {
    _remote: RemoteEvent,

    _registered_endpoints: CommonTypes.Dictionary<number, NetworkEndpoint>,

    _bandwidth_history: {rcv: Memory.Memory, snd: Memory.Memory, rcv_calls: CommonTypes.Array<number>},

    _previous_flush: number,
    _batch: CommonTypes.Dictionary<number, CommonTypes.Array<buffer>>,

    NetworkEndpoint: typeof(NetworkEndpoint),
} & typeof(Network)
type self = Network

return Network