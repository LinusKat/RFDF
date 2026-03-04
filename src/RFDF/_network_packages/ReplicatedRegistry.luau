--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local src = script.Parent

local DeltaCompress = require(src.Parent._packages.DeltaCompress)
local Squash = require(src.Parent._packages.Squash)
local Sift = require(src.Parent._packages.Sift)

local CommonTypes = require(src.Parent.CommonTypes)

local LemonSignal = require(src.Parent._packages.LemonSignal)

local ServerNetwork = require(src.Parent._network_packages.Server)
local ClientNetwork = require(src.Parent._network_packages.Client)

local IsServer = RunService:IsServer()

local SCHEMA = Squash.buffer()

local Endpoint = {}
Endpoint.__index = Endpoint

function Endpoint.new(RFDF: RFDF, Registry: Registry, u8id: number, tag: string)
    local self = setmetatable({}, Endpoint):: self & (ClientExposed | ServerExposed)
    self.Endpoint = RFDF.Network.NetworkEndpoint.new(RFDF.Network, u8id, tag, SCHEMA, {
        BATCH_LIMIT = 0,
        EXPECT = nil,
        STRICT = false,
    })
    self.Registry = Registry

    if IsServer then
        (self:: any):_server_init()
    else
        (self:: any):_client_init()
    end

    return self
end

function Endpoint._client_init(self: self & ClientExposed)
    self.OnClientReceive = LemonSignal.new()

    self.Endpoint.OnClientEvent:Connect(function(delta: buffer)
        self.Registry = DeltaCompress.applyImmutable(self.Registry, delta)
        self.OnClientReceive:Fire()
    end)
end

function Endpoint._client_added(self: self & ServerExposed, Client: Player)
    local initial_commit = DeltaCompress.diffImmutable(nil, self.Registry)
    self.Endpoint:FireClient(Client, initial_commit)
end

function Endpoint._server_init(self: self & ServerExposed)
    Players.PlayerAdded:Connect(function(...)
        self:_client_added(...)
    end)
end

function Endpoint.Push(self: self & ServerExposed)
    assert(IsServer, "Replicated Registry Endpoints on the client are read only")

    local diff, old = DeltaCompress.diffMutable(self._snapshot, self.Registry)

    print(diff, old)
    if not diff then
        return
    end

    self._snapshot = old

    self.Endpoint:FireAllClients(diff)
end

type RFDF = any

export type Registry = CommonTypes.Dictionary<any, any>

export type ServerExposed = {
    _snapshot: any?,
    Endpoint: ServerNetwork.NetworkEndpoint,
}
export type ClientExposed = {
    Endpoint: ClientNetwork.NetworkEndpoint,
    OnClientReceive: any,
}

export type Endpoint = {
    Registry: Registry,
} & typeof(Endpoint)
type self = Endpoint

return Endpoint