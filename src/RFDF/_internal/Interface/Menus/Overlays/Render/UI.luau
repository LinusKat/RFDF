local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local CeiveImOverlay = require(script.Parent.Parent.Parent.Parent.CeiveImOverlay)

return function(_, ImOverlay: CeiveImOverlay.CImOverlay)
    ImOverlay:Text(string.format(`UI 2D Draw Calls: %.0f`, Stats.UI2DDrawcallCount))
    ImOverlay:Text(string.format(`UI 2D Triangles: %.0f`, Stats.UI2DTriangleCount))
    ImOverlay:Text(string.format(`UI 3D Draw Calls: %.0f`, Stats.UI3DDrawcallCount))
    ImOverlay:Text(string.format(`UI 3D Triangles: %.0f`, Stats.UI3DTriangleCount))
end