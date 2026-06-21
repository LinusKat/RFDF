--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local src = script.Parent

local Promise = require(src.Parent._packages.Promise)
local Squash = require(src.Parent._packages.Squash)
local Sift = require(src.Parent._packages.Sift)

local Util = require(script.Parent.Util)

local IsServer = RunService:IsServer()

const PACKET_REQUEST = 0
const PACKET_REPLY = 1

--[=[
@class Endpoint
]=]
local Endpoint = {}
Endpoint.__index = Endpoint

function Endpoint.new(
	Network: Network,
	u8id: number,
	tag: string,
	RequestSchema: any,
	ReplySchema: any,
	timeout: number
): Endpoint
	local self = setmetatable({}, Endpoint) :: any
	self._reply_timeout = timeout
	self._reply_hook = function() end

	self._request_schema = RequestSchema
	self._reply_schema = ReplySchema

	self.Endpoint = Network.NetworkEndpoint.new(
		Network,
		u8id,
		tag,
		Squash.tuple(Squash.literal(0, 1), Squash.opt(Squash.buffer())),
		{
			BATCH_LIMIT = 0,
			EXPECT = nil,
			STRICT = false,
		}
	)

	if IsServer then
		self:_server_init()
	else
		self:_client_init()
	end

	return self
end

function Endpoint._deserialize(self: self, Reply: boolean, Buffer: buffer)
	if not Buffer then
		return nil
	end

	local schema = Reply and self._reply_schema or self._request_schema
	local cursor = Squash.frombuffer(Buffer)

	local deserialized = Util.RecursivePacketInstanceProcessing(false, { schema.des(cursor) })

	return deserialized
end

function Endpoint._serialize(self: self, Reply: boolean, ...: any)
	local filled = not Sift.isEmpty({ ... })

	if not filled then
		return nil
	end

	local processed = Util.RecursivePacketInstanceProcessing(true, { ... })

	local schema = Reply and self._reply_schema or self._request_schema
	local cursor = Squash.cursor()
	schema.ser(cursor, table.unpack(processed))

	local serialized = Squash.tobuffer(cursor)

	return serialized
end

function Endpoint._client_init(self: self)
	self.Endpoint.OnClientEvent:Connect(function(tag: number, Buffer: buffer?)
		if tag ~= PACKET_REQUEST then
			return
		end

		local serialized: buffer?
		if Buffer then
			local deserialized = self:_deserialize(false, Buffer)
			serialized = self:_serialize(true, self._reply_hook(table.unpack(deserialized)))
		else
			serialized = self:_serialize(true, self._reply_hook(nil))
		end
		self.Endpoint:FireServer(PACKET_REPLY, serialized)
	end)
end

function Endpoint._server_init(self: self)
	self.Endpoint.OnServerEvent:Connect(function(Origin: Player, tag: number, Buffer: buffer?)
		if tag ~= PACKET_REQUEST then
			return
		end

		local serialized: buffer?
		if Buffer then
			local deserialized = self:_deserialize(false, Buffer)
			serialized = self:_serialize(true, self._reply_hook(Origin, table.unpack(deserialized)))
		else
			serialized = self:_serialize(true, self._reply_hook(Origin, nil))
		end
		self.Endpoint:FireClient(Origin, PACKET_REPLY, serialized)
	end)
end

function Endpoint._promise_me_an_answer(self: self)
	local status, result = Promise.new(function(resolve, reject, onCancel)
		local event = IsServer and self.Endpoint.OnServerEvent or self.Endpoint.OnClientEvent
		local con

		con = event:Connect(function(...: any)
			local packed = { ... }
			local tag = packed[IsServer and 2 or 1]
			local Buffer = packed[IsServer and 3 or 2]

			if tag ~= PACKET_REPLY then
				return
			end

			con:Disconnect()
			resolve(self:_deserialize(true, Buffer))
		end)

		onCancel(function()
			con:Disconnect()
		end)
	end)
		:timeout(self._reply_timeout)
		:awaitStatus()

	if status == "Resolved" and result then
		return table.unpack(result)
	else
		return nil
	end
end

function Endpoint._request(self: self, Target: Player?, ...: any)
	local serialized = self:_serialize(false, ...)

	if IsServer then
		if Target then
			self.Endpoint:FireClient(Target, PACKET_REQUEST, serialized)
		else
			self.Endpoint:FireAllClients(PACKET_REQUEST, serialized)
		end
	else
		self.Endpoint:FireServer(PACKET_REQUEST, serialized)
	end

	return self:_promise_me_an_answer()
end
--[=[
@within Endpoint

Client -> Server -> Client

```lua
local Endpoint = self.RFDF:RequireEndpoint("\RemoteFunction")

local replyFromServer = Endpoint:RequestFromServer("Oi!")
```

@client
]=]
function Endpoint.RequestFromServer(self: self, ...: any)
	return self:_request(nil, ...)
end

--[=[
@within Endpoint

Server -> Client -> Server

```lua
const Players = game:GetService("Players")

local Endpoint = self.RFDF:RequireEndpoint("\RemoteFunction")

const replyFromClient = Endpoint:RequestFromClient(Players.LinusKat, "Oi!")
```

@server
]=]
function Endpoint.RequestFromClient(self: self, Target: Player?, ...: any)
	return self:_request(Target, ...)
end

--[=[
@within Endpoint

Hook a reply function on the request receiving side

```lua
const Players = game:GetService("Players")

local Endpoint = self.RFDF:RequireEndpoint("\RemoteFunction")

const replyFromClient = Endpoint:RequestFromClient(Players.LinusKat, "Oi!")
Endpoint:Hook(function(...)
	print(...)
	return "Yeah Cibao"
end)
```
]=]
function Endpoint.Hook(self: self, func: (...any) -> any)
	self._reply_hook = func
end

type Network = any

export type Endpoint = {
	_reply_timeout: number,
	_reply_hook: (...any) -> any,

	_request_schema: any,
	_reply_schema: any,

	Endpoint: any,
} & typeof(Endpoint)
type self = Endpoint

return Endpoint
