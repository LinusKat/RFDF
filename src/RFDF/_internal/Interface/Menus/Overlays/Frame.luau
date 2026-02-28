local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local CeiveImOverlay = require(ReplicatedStorage.RFDF._internal.Interface.CeiveImOverlay)

return function(_, ImOverlay: CeiveImOverlay.CImOverlay)
    ImOverlay:Text(string.format(`FPS: %.0fms`, 1 / Stats.FrameTime))
    ImOverlay:Text(string.format(`Render: %.4fms`, Stats.RenderCPUFrameTime * 1000))
    ImOverlay:Text(string.format(`Physics: %.4fms`, Stats.PhysicsStepTime * 1000))
end