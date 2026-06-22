--!strict
const insert = table.insert
const find = table.find

const ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

const RateLimit = require(ReplicatedStorage.RFDF._network_packages.RateLimit)
const RFDF = require(ReplicatedStorage.RFDF)

const SOURCE = script
const PRIORITY_LOAD: {ModuleScript} = {
}

for _, v: any in SOURCE:GetChildren() do
    if not find(PRIORITY_LOAD, v) then
        insert(PRIORITY_LOAD, v)
    end
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local root = RFDF.root()
root:Print("CHECK SERVER INIT", "ROOT")
local rate_limiter = RateLimit(1, .1)
if not Workspace:GetAttribute("SERVER_LOADED") then
    repeat task.wait() if rate_limiter() then root:Print("FALSE -- CONTINUE POLLING", "ROOT") end until Workspace:GetAttribute("SERVER_LOADED")
end
root:Print("OK -- BEGIN CLIENT SERVICE INGEST", "ROOT")

root:Init()
root:LoadServicesFromArray(PRIORITY_LOAD)

game.Close:Connect(function()
    root:KillRFDFInstance()
end)