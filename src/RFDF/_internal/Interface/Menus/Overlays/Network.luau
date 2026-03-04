local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")

local CeiveImOverlay = require(script.Parent.Parent.Parent.CeiveImOverlay)

return function(_, ImOverlay: CeiveImOverlay.CImOverlay)
    ImOverlay:Text(string.format(`Data Send: %.2fkbps`, Stats.DataSendKbps))
    ImOverlay:Text(string.format(`Data Receive: %.2fkbps`, Stats.DataReceiveKbps))

    ImOverlay:Text(string.format(`Physics Send: %.2fkbps`, Stats.PhysicsSendKbps))
    ImOverlay:Text(string.format(`Physics Receive: %.2fkbps`, Stats.PhysicsReceiveKbps))
end