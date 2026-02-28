local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Squash = require(ReplicatedStorage.RFDF._packages.Squash)

local Schemas = {
    Batch = Squash.map(Squash.u8(), Squash.array(Squash.buffer())),
}

return Schemas