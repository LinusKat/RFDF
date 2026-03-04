local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UnitTest = require(ReplicatedStorage.RFDF.Util.UnitTest)
local RFDF = require(ReplicatedStorage.RFDF)

local root = RFDF.root()
root:Init()

UnitTest.TestLoading(root)

game.Close:Connect(function()
    root:KillRFDFInstance()
end)