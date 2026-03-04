local src = script.Parent
local Squash = require(src.Parent._packages.Squash)

local Schemas = {
    Batch = Squash.map(Squash.u8(), Squash.array(Squash.buffer())),
}

return Schemas