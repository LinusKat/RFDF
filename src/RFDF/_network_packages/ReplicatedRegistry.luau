--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local src = script.Parent

local DeepDelta = require(src.Parent._packages.DeepDelta)
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

--[[
    HAS TO BE JSON SERIALIZABLE DATA, NO ROBLOX USERDATAS
]]
function Endpoint.new(RFDF: RFDF, Registry: Registry, u8id: number)
    local self = setmetatable({}:: self, Endpoint)
    self.Endpoint = RFDF.Network.NetworkEndpoint.new(RFDF.Network, u8id, SCHEMA, {
        BATCH_LIMIT = 0,
        EXPECT = nil,
        STRICT = false,
    })
    self.Registry = Registry

    if IsServer then
        self:_server_init()
    else
        self:_client_init()
    end

    return self
end

function Endpoint._client_init(self: self & ClientExposed)
    self.OnClientReceive = LemonSignal.new()

    self.Endpoint.OnClientEvent:Connect(function(delta)
        print(delta)
        DeepDelta.apply(self.Registry, delta)
        self.OnClientReceive:Fire()
    end)
end

function Endpoint._server_init(self: self & ServerExposed)
    self._snapshot = DeepDelta.clone(self.Registry)

    Players.PlayerAdded:Connect(function(...)
        self:_client_added(...)
    end)
end

function Endpoint._client_added(self: self & ServerExposed, Client: Player)
    local delta, _ = DeepDelta.diff(self.Registry, self._snapshot)
    self._snapshot = DeepDelta.clone(self.Registry)

    self.Endpoint:FireClient(Client, delta)
end

function Endpoint.Push(self: self & ServerExposed)
    assert(IsServer, "Replicated Registry Endpoints on the client are read only")

    local delta, deltas = DeepDelta.diff(
        self.Registry,
        self._snapshot
    )

    if Sift.isEmpty(deltas) then
        return
    end

    self._snapshot = DeepDelta.clone(self.Registry)

    self.Endpoint:FireAllClients(delta)
end

type RFDF = any

export type Registry = CommonTypes.Dictionary<any, any>

export type ServerExposed = {
    _snapshot: Registry,
    Endpoint: ServerNetwork.NetworkEndpoint,
}
export type ClientExposed = {
    Endpoint: ClientNetwork.NetworkEndpoint,
    OnClientReceive: LemonSignal.Signal,
}

export type Endpoint = {
    Registry: Registry,
} & typeof(Endpoint)
type self = Endpoint

return Endpoint