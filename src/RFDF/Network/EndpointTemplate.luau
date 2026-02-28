--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = require(ReplicatedStorage.RFDF._network_packages.Server)
local Squash = require(ReplicatedStorage.RFDF._packages.Squash)

--[[
        BATCH_LIMIT: number,                 -- // We limit the batched data the player can send (reverse the batch deserialize up to the point of the batch limit)
        EXPECT: ((...: any) -> boolean?)?,   -- // Return true if deserialized data is correct
        STRICT: boolean,                     -- // Determines if we kick the player if the deserialized data is not what we expected.
]]

local Endpoint = {
    DDoS_ProtectionSettings = {
        BATCH_LIMIT = 5,
        EXPECT = nil,
        STRICT = false,
    }:: Server.DDoS_ProtectionSettings,
    Schema = {}:: Squash.SerDes,
}

return Endpoint