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

local SCHEMA = Squash.opt(Squash.buffer())

local Endpoint = {}
Endpoint.__index = Endpoint

function Endpoint.new(RFDF: RFDF, Registry: Registry, u8id: number, tag: string, allow_write: boolean): Endpoint
	local self = setmetatable({}, Endpoint):: any
	self._allow_write = allow_write
	
    self.Endpoint = RFDF.Network.NetworkEndpoint.new(RFDF.Network, u8id, tag, SCHEMA, {
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

function Endpoint._send_initial(self: self, Client: Player?)
	local initial_commit = DeltaCompress.diffImmutable(nil, self.Registry)
	
	if IsServer then
		self.Endpoint:FireClient(Client, initial_commit)
	elseif not IsServer then
		self.Endpoint:FireServer(initial_commit)
	end
end

function Endpoint._apply_delta(self: self, delta: buffer)
	local diff = DeltaCompress.applyImmutable(self.Registry, delta)
	for k, v in pairs(diff) do
		self.Registry[k] = v
	end
end

function Endpoint._client_init(self: self)
    self.OnReceive = LemonSignal.new()

	self.Endpoint.OnClientEvent:Connect(function(delta: buffer?)
		print(delta)
		if not delta then
			self:_send_initial()
			return
		end
		if not self._allow_write then
			return
		end
		
		self:_apply_delta(delta)
		self.OnReceive:Fire()
	end)
	
	self:_send_initial()
end

function Endpoint._server_init(self: self)
	self.Endpoint.OnServerEvent:Connect(function(Origin: Player, delta: buffer?)
		if not delta then
			self:_send_initial(Origin)
			return
		end
		if not self._allow_write then
			return
		end
		
		self:_apply_delta(delta)
		self.OnReceive:Fire()
	end)
	
    Players.PlayerAdded:Connect(function(...)
		self:_send_initial(...)
	end)
end

function Endpoint.Fetch(self: self)
	self.Endpoint:FireServer(nil)
end

function Endpoint.Push(self: self)
    local diff, old = DeltaCompress.diffMutable(self._snapshot, self.Registry)

    if not diff then
        return
    end

    self._snapshot = old

	if IsServer then
		self.Endpoint:FireAllClients(diff)
	elseif not IsServer then
		self.Endpoint:FireServer(diff)
	end
end

type RFDF = any

export type Registry = CommonTypes.Dictionary<any, any>

export type Endpoint = {
	_snapshot: any?,
	_allow_write: boolean,
	
	Endpoint: any,
	
	Registry: Registry,
	OnReceive: any,
} & typeof(Endpoint)
type self = Endpoint

return Endpoint