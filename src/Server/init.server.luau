--!strict
const insert = table.insert
const find = table.find

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Workspace = game:GetService("Workspace")

const RFDF = require(ReplicatedStorage.RFDF)

const SOURCE = script
const PRIORITY_LOAD: {ModuleScript} = {
}

for _, v: any in SOURCE:GetChildren() do
    if not find(PRIORITY_LOAD, v) then
        insert(PRIORITY_LOAD, v)
    end
end

local root = RFDF.root()
root:Init()

root:LoadServicesFromArray(PRIORITY_LOAD)

root:Print("SERVER LOADED", "ROOT")
Workspace:SetAttribute("SERVER_LOADED", true)

game.Close:Connect(function()
    root:KillRFDFInstance()
end)