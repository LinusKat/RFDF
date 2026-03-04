--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local src = script.Parent.Parent.Parent.Parent

local _NET_PING_ENDPOINT = require(src.Network.Ping)

local CommonTypes = require(src.CommonTypes)
local RFDF = require(src)

-- // TYPES
type StartupData = CommonTypes.StartupData
type RFDF = RFDF.RFDF

local SRC = "Unit Test 6.3"

local module = {}
module.__index = module

function module.Start(StartupData: StartupData)
	local self = setmetatable({}:: self, module)
	self._RFDF = StartupData.RFDF

	return self
end

function module._init_client(self: self)
    local RFDF = self._RFDF:: RFDF.RFDF & RFDF.ExposeClient
    local Endpoint = RFDF.NetworkEndpoint.new(RFDF.Network, _NET_PING_ENDPOINT.u8id, _NET_PING_ENDPOINT.Tag, _NET_PING_ENDPOINT.Schema)
    
    local RegistryEndpoint = RFDF.ReplicatedRegistryEndpoint.new(self._RFDF, {}, "replicated-registry", 2)

    local last_rcv = os.clock()

    Endpoint.OnClientEvent:Connect(function(...)
        local t1 = os.clock()
        local rrt = t1 - last_rcv
        last_rcv = t1
        
        RFDF:Log(string.format(`server -> client t: %f`, rrt), "PRINT", SRC)

        Endpoint:FireServer(...)
    end)
    
    RegistryEndpoint.OnClientReceive:Connect(function()
        print(RegistryEndpoint.Registry)
    end)
end

function module._init_server(self: self)
    local RFDF = self._RFDF:: RFDF.RFDF & RFDF.ExposeServer
    local Ping = RFDF.NetworkEndpoint.new(RFDF.Network, _NET_PING_ENDPOINT.u8id, _NET_PING_ENDPOINT.Tag, _NET_PING_ENDPOINT.Schema, _NET_PING_ENDPOINT.DDoS_ProtectionSettings)

    local Registry = {
        ["Number"] = 0,
    }

    local RegistryEndpoint = RFDF.ReplicatedRegistryEndpoint.new(self._RFDF, Registry, 2, "replicated-registry")

    Ping.OnServerEvent:Connect(function(Origin: Player, t0: number)
        local t1 = os.clock()
        local ping = t1 - t0
        RFDF:Log(string.format("RTT: %f", ping), Color3.new(0.984313, 1, 0), SRC)
        print(string.format("RTT: %f", ping))

        task.wait(.25)
        Ping:FireClient(Origin, os.clock())

        print("push")
        Registry.Number += 1
        RegistryEndpoint:Push()
    end)

    local function PlayerAdded(Player: Player)
        task.wait(2)
        RFDF:Log(string.format("Start Pinging: %s", Player.Name), Color3.new(0.984313, 1, 0), SRC)
        Ping:FireClient(Player, os.clock())
    end

    for _, v in ipairs(Players:GetPlayers()) do PlayerAdded(v) end
    Players.PlayerAdded:Connect(PlayerAdded)
end

function module.Init(self: self)
    if RunService:IsServer() then
        self:_init_server()
    elseif RunService:IsClient() then
        self:_init_client()
    end
end

function module._debug_interface(self: self, Iris: any)
    Iris.Window({ "Test 6.3" }); do
    end; Iris.End()
end

export type Service = {_RFDF: RFDF} & typeof(module)
type self = Service

return module