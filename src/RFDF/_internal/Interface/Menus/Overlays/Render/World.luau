local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local CeiveImOverlay = require(script.Parent.Parent.Parent.Parent.CeiveImOverlay)

return function(_, ImOverlay: CeiveImOverlay.CImOverlay)
    ImOverlay:Text(string.format(`Instances: %.0f`, Stats.InstanceCount))
    ImOverlay:Text(string.format(`World Draw Calls: %.0f`, Stats.SceneDrawcallCount))
    ImOverlay:Text(string.format(`World Triangles: %.0f`, Stats.SceneTriangleCount))
    ImOverlay:Text(string.format(`Shadow Draw Calls: %.0f`, Stats.ShadowsDrawcallCount))
    ImOverlay:Text(string.format(`Shadow Triangles: %.0f`, Stats.ShadowsTriangleCount))
end