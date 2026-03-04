--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local IrisTypes = require(ReplicatedStorage.RFDF._packages._Index["linuskat_iris-implot@1.0.4"]["iris-implot"].Types)
local CeiveImOverlay = require(ReplicatedStorage.RFDF._internal.Interface.CeiveImOverlay)
local Sift = require(ReplicatedStorage.RFDF._packages.Sift)

local Types = require(ReplicatedStorage.RFDF.Types)

local RETURN_ROOT_KEY = Enum.KeyCode.F1
local RETURN_KEY = Enum.KeyCode.F2
local TOGGLE_KEY = Enum.KeyCode.F3

local CHILD_KEYS = {
	Enum.KeyCode.F4,
	Enum.KeyCode.F5,
	Enum.KeyCode.F6,
	Enum.KeyCode.F7,
	Enum.KeyCode.F8,
	Enum.KeyCode.F9,
	Enum.KeyCode.F10,
	Enum.KeyCode.F11,
	Enum.KeyCode.F12,
}

local DebugNode = {}
DebugNode.__index = DebugNode

function DebugNode.new(Name: string, Render: any)
    local self = setmetatable({}, DebugNode):: DebugNode

    self.Name = Name

    self.Children = {}
    
    self.Render = Render
    self.Parent = nil

    return self
end

function DebugNode.AddChild(self: DebugNode, Child: DebugNode)
    local key = CHILD_KEYS[Sift.Dictionary.count(self.Children) + 1]
    if not key then return end
    
    Child.Parent = self
    self.Children[key] = Child
end

type DebugNode = {
    Name: string,

    Children: {[Enum.KeyCode]: DebugNode},

    Render: (self: DebugNode, RFDF: Types.RFDF, ImOverlay: CeiveImOverlay.CImOverlay) -> any,
    Parent: DebugNode?,
} & typeof(DebugNode)

local RootNode = DebugNode.new("Root", function(_, _: CeiveImOverlay.CImOverlay)
end)

local function RegisterOverlays(Path: ModuleScript, ParentNode: any)
    local child_node = DebugNode.new(Path.Name, require(Path):: any)
    ParentNode:AddChild(child_node)

    for _, v in ipairs(Path:GetChildren()) do
        if not v:IsA("ModuleScript") then continue end
        RegisterOverlays(v, child_node)
    end
end

for _, v in ipairs(script:GetChildren()) do
    if not v:IsA("ModuleScript") then continue end
    RegisterOverlays(v, RootNode)
end

local CurrentNode = RootNode
local Visible = true

UserInputService.InputBegan:Connect(function(Input: InputObject)
    local KeyCode = Input.KeyCode

    if KeyCode == TOGGLE_KEY then
        Visible = not Visible
    end

    if KeyCode == RETURN_ROOT_KEY then
        CurrentNode = RootNode
    elseif KeyCode == RETURN_KEY then
        CurrentNode = CurrentNode.Parent or CurrentNode
    elseif CurrentNode.Children[KeyCode] then
        CurrentNode = CurrentNode.Children[KeyCode]
    end
end)

return function(RFDF: Types.RFDF, _: IrisTypes.Iris, ImOverlay: CeiveImOverlay.CImOverlay)
    local overlays = ImOverlay:GetLayer("Debug", UDim2.fromScale(0, 0) + UDim2.fromOffset(0, 50))
    ImOverlay:SetActiveLayer(overlays)

    ImOverlay:PushStyle({BackgroundTransparency = 0, Padding = 0})

    if Visible then
        ImOverlay:Text(string.format("[%s] Root", RETURN_ROOT_KEY.Name))
        ImOverlay:Text(string.format("[%s] Back", RETURN_KEY.Name))
        ImOverlay:Text(string.format("[%s] Toggle", TOGGLE_KEY.Name))

        ImOverlay:Begin(CurrentNode.Name); do
            CurrentNode.Render(RFDF, ImOverlay)
            
            for key, node in pairs(CurrentNode.Children) do
                ImOverlay:Text(string.format("[%s] %s", key.Name, node.Name))
            end
        end
        ImOverlay:End()
    end

    ImOverlay:PopStyle()

    ImOverlay:PopActiveLayer()
end