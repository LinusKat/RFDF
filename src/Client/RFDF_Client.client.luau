local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UnitTest = require(ReplicatedStorage.RFDF.Util.UnitTest)
local RFDF = require(ReplicatedStorage.RFDF)

local root = RFDF.root()

UnitTest.TestLoading(root)
root:Init()

game.Close:Connect(function()
    root:KillRFDFInstance()
end)