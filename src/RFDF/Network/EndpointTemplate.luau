--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = require(ReplicatedStorage.RFDF._network_packages.Server)
local Squash = require(ReplicatedStorage.RFDF._packages.Squash)

--[[
    u8id -- // 0 > 255, number cannot conflict with other endpoint ids, spreadsheet https://docs.google.com/spreadsheets/d/1wkedlKjiQtiPz3NFX282tG3yJI_TlnSBTlmxeRq_C6E/edit?gid=0#gid=0
	Tag  -- // human readable tag serves no purpose
	
	DDoS_ProtectionSettings: -- // NOT IMPLEMENTED YET
        BATCH_LIMIT: number,                 -- // We limit the batched data the player can send (reverse the batch deserialize up to the point of the batch limit)
        EXPECT: ((...: any) -> boolean?)?,   -- // Return true if deserialized data is correct
        STRICT: boolean,                     -- // Determines if we kick the player if the deserialized data is not what we expected.
    
	ClientAllowWrite -- // only add if its a registry, when true client can write to server data
	ServerAllowWrite -- // only add if its a registry, when true server can write to client data
	
	Timeout -- only add if its a remote function, promise timeout after this amount of time seconds
	
	RequestSchema -- only add if its a remote function
	ReplySchema -- only add if its a remote function
	Schema -- only add if its a normal endpoint to send reliable data with no packet loss, schema requires u to use Squash. type Squash.opt for optionals, API: https://data-oriented-house.github.io/Squash/api/Squash
]]

local Endpoint = {
	u8id = 0,
	Tag = "",

	DDoS_ProtectionSettings = {
		BATCH_LIMIT = 5,
		EXPECT = nil,
		STRICT = false,
	},

	ClientAllowWrite = nil,
	ServerAllowWrite = nil,

	Timeout = nil,

	RequestSchema = nil,
	ReplySchema = nil,
	Schema = nil,
}

return Endpoint