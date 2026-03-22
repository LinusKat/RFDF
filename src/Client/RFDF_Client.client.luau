local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RFDF = require(ReplicatedStorage.RFDF)

local root = RFDF.root()
root:Init()

game.Close:Connect(function()
    root:KillRFDFInstance()
end)