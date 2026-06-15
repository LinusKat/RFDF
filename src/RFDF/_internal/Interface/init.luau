local UserInputService = game:GetService("UserInputService")

local IrisTypes = require(script.Parent.Parent._packages._Index["linuskat_iris-implot@1.0.4"]["iris-implot"].Types)
local CommonTypes = require(script.Parent.Parent.CommonTypes)

local Iris = require(script.Parent.Parent._packages.Iris)
local IrisInterface = require(script.IrisInterface)

local INTERFACE_TOGGLE_KEY = Enum.KeyCode.F3

local RFDFInterface = {}
RFDFInterface.__index = RFDFInterface

function RFDFInterface.new(RFDF: any)
	local self = setmetatable({}, RFDFInterface):: RFDFInterface
	self._rfdf = RFDF

	self._display_states = {}
	self._interface_visible = false

	return self
end

function RFDFInterface.Init(self: self)
	if not Iris.Internal._started then
		Iris.Init()
	end

	UserInputService.InputBegan:Connect(function(Input: InputObject)
		local key_code = Input.KeyCode
		
		if key_code == INTERFACE_TOGGLE_KEY then
			self._interface_visible = not self._interface_visible
		end
	end)
end

function RFDFInterface.Render(self: self, raw_middleware: CommonTypes.Middleware)
	if not self._interface_visible then return end
	IrisInterface(self._rfdf, raw_middleware)
end

type DisplayState = IrisTypes.State<boolean>

export type RFDFInterface = {
	_rfdf: any,

	_display_states: CommonTypes.Dictionary<string, DisplayState>,
	_interface_visible: boolean,
} & typeof(RFDFInterface)
type self = RFDFInterface

return RFDFInterface