--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local src = script.Parent

local DeltaCompress = require(src.Parent._packages.DeltaCompress)
local Squash = require(src.Parent._packages.Squash)
local Sift = require(src.Parent._packages.Sift)

local CommonTypes = require(src.Parent.CommonTypes)

local LemonSignal = require(src.Parent._packages.LemonSignal)
local Promise = require(src.Parent._packages.Promise)

local ServerNetwork = require(src.Parent._network_packages.Server)
local ClientNetwork = require(src.Parent._network_packages.Client)

local IsServer = RunService:IsServer()

local SCHEMA = Squash.opt(Squash.buffer())

local Endpoint = {}
Endpoint.__index = Endpoint

function Endpoint.new(Network: Network, Registry: Registry, u8id: number, tag: string, allow_write: boolean): Endpoint
	local self = setmetatable({}, Endpoint):: any
	self._snapshots = {}
	self._allow_write = allow_write
	
    self.Endpoint = Network.NetworkEndpoint.new(Network, u8id, tag, SCHEMA, {
        BATCH_LIMIT = 0,
        EXPECT = nil,
        STRICT = false,
    })
	self.Registry = Registry
	
	self.OnReceive = LemonSignal.new()

    if IsServer then
        self:_server_init()
    else
        self:_client_init()
    end

    return self
end

function Endpoint._resolve(self: self, Target: Player?): Registry
	if Target then
		local sub = (self.Registry :: any)[Target]
		if type(sub) == "table" then
			return sub
		end
	end
	
	return self.Registry:: Registry
end

function Endpoint._send_initial(self: self, Client: Player?)
	local registry = if IsServer then self:_resolve(Client) else self.Registry
	local initial_commit = DeltaCompress.diffImmutable(nil, registry)
	
	if IsServer then
		self.Endpoint:FireClient(Client, initial_commit)
	elseif not IsServer then
		self.Endpoint:FireServer(initial_commit)
	end
end

function Endpoint._apply_delta(self: self, Delta: buffer, Origin: Player)
	local registry = self:_resolve(Origin)
	local diff = DeltaCompress.applyImmutable(registry, Delta)
	
	for k, v in pairs(diff) do
		registry[k] = v
	end
end

function Endpoint._client_init(self: self)
	self.Endpoint.OnClientEvent:Connect(function(delta: buffer?)
		if not delta then
			self:_send_initial()
			return
		end
		if not self._allow_write then
			return
		end
		
		self:_apply_delta(delta, nil)
		self.OnReceive:Fire()
	end)
	
	self:_send_initial()
end

function Endpoint._server_init(self: self)
	self.Endpoint.OnServerEvent:Connect(function(Origin: Player, Delta: buffer?)
		if not Delta then
			self:_send_initial(Origin)
			return
		end
		if not self._allow_write then
			return
		end
		
		self:_apply_delta(Delta, Origin)
		self.OnReceive:Fire()
	end)
	
    Players.PlayerAdded:Connect(function(...)
		self:_send_initial(...)
	end)
	Players.PlayerRemoving:Connect(function(...)
		self._snapshots[...] = nil
	end)
end

function Endpoint._local_push(self: self, Target: any)
	local player = if typeof(Target) == "Instance" and Target:IsA("Player") then Target else nil
	local registry = self:_resolve(player)
	
	local diff, old = DeltaCompress.diffMutable(self._snapshots[Target], registry)

	if not diff then
		return
	end

	self._snapshots[Target] = old

	if IsServer then
		self.Endpoint:FireClient(Target, diff)
	elseif not IsServer then
		self.Endpoint:FireServer(diff)
	end
end

function Endpoint.PromiseFilledRegistry(self: self, Timeout: number, Tries: number, Sleep: number)
	return Promise.retryWithDelay(function()
		return Promise.new(function(resolve, reject)
			if not Sift.isEmpty(self.Registry) then
				resolve("Already resolved")
				return
			end

			self:Fetch()
			self.OnReceive:Wait()

			if Sift.isEmpty(self.Registry) then
				reject("Empty, retry fetch")
			else
				resolve("Filled, resolve")
			end
		end):timeout(Timeout)
	end, Tries, Sleep):awaitStatus()
end

function Endpoint.Fetch(self: self)
	self.Endpoint:FireServer(nil)
end

function Endpoint.Push(self: self, Targets: {Player}?)
	if not IsServer then
		self:_local_push("SERVER")
		return
	end
	
	local list = Targets or Players:GetPlayers()
	for _, player in ipairs(list) do
		self:_local_push(player)
	end
end

type Network = any

export type Registry = CommonTypes.Dictionary<any, any>

export type Endpoint = {
	_snapshots: {[Player]: any},
	_allow_write: boolean,
	
	Endpoint: any,
	
	Registry: {[Player]: Registry} | Registry,
	OnReceive: any,
} & typeof(Endpoint)
type self = Endpoint

return Endpoint