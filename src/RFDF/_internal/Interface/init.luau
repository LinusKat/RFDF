local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local IrisTypes = require(script.Parent.Parent._packages._Index["linuskat_iris-implot@1.0.4"]["iris-implot"].Types)
local CommonTypes = require(ReplicatedStorage.RFDF.CommonTypes)
local Iris = require(script.Parent.Parent._packages.Iris)
local CeiveImOverlay = require(script.CeiveImOverlay)

local IrisInterface = require(script.Menus.IrisInterface)

local INTERFACE_TOGGLE_KEY = Enum.KeyCode.F4
local OVERLAY_TOGGLE_KEY = Enum.KeyCode.F3

local RFDFInterface = {}
RFDFInterface.__index = RFDFInterface

function RFDFInterface.new(RFDF: any)
	local self = setmetatable({}, RFDFInterface):: RFDFInterface
	self._rfdf = RFDF
	self._overlay = CeiveImOverlay.new()

	self._display_states = {}
	self._display_registry = {}

	local overlay = Instance.new("ScreenGui")
	overlay.Parent = Players.LocalPlayer.PlayerGui
	overlay.IgnoreGuiInset = false
	
	self._overlay.BackFrame.Parent = overlay

	self._interface_visible = RunService:IsStudio()
	self._overlay_visible = RunService:IsStudio()

	return self
end

function RFDFInterface.Init(self: self)
	if not Iris.Internal._started then
		Iris.Init()
	end

	UserInputService.InputBegan:Connect(function(Input: InputObject)
		local KeyCode = Input.KeyCode
		
		if KeyCode == INTERFACE_TOGGLE_KEY then
			self._interface_visible = not self._interface_visible
		end
		if KeyCode == OVERLAY_TOGGLE_KEY then
			self._overlay_visible = not self._overlay_visible
		end
	end)

	for _, v in ipairs(script.Menus:GetChildren()) do
		if v == script.Menus.IrisInterface then
			continue
		end
		self:RegisterMenu(require(v))
	end
end

function RFDFInterface.RegisterMenu(self: self, Function: RenderFunction)
	table.insert(self._display_registry, Function)
end

function RFDFInterface.Render(self: self, raw_middleware: CommonTypes.Middleware)
	if self._interface_visible then
		IrisInterface(self._rfdf, raw_middleware)
	end

	if self._overlay_visible then
		for _, Render in ipairs(self._display_registry) do
			Render(self._rfdf, Iris, self._overlay)
		end
	end

	self._overlay:Render()
end

type DisplayState = IrisTypes.State<boolean>

export type RenderFunction = () -> nil

export type RFDFInterface = {
	_rfdf: any,
	_overlay: CeiveImOverlay.CImOverlay,

	_display_states: CommonTypes.Dictionary<string, DisplayState>,
	_display_registry: CommonTypes.Array<RenderFunction>,

	_overlay_visible: boolean,
	_interface_visible: boolean,
} & typeof(RFDFInterface)
type self = RFDFInterface

return RFDFInterface