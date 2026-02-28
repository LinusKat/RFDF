--!strict
local CommonTypes = require(script.Parent.Parent.Parent.Parent.CommonTypes)
local RFDF = require(script.Parent.Parent.Parent.Parent)

-- // TYPES
type StartupData = CommonTypes.StartupData
type RFDF = RFDF.RFDF

local SRC = "Unit Test 6.2"

local module = {}
module.__index = module

function module.Start(StartupData: StartupData)
	local self = setmetatable({}:: self, module)
	self._RFDF = StartupData.RFDF
	
	self.Variable = `Variable from {SRC}`

	return self
end

function module.Init(self)
	local RFDF = self._RFDF:: RFDF
	local Service = RFDF:GetService("Test 6.1"):: any

	RFDF:Log(`{SRC} accessing RFDF to log`, "WARNING", SRC)
	RFDF:Log(`{SRC} accessing RFDF for [Unit Test 6.1] Variable: {Service.Variable}`, Color3.new(0, 1, 0), SRC)
end

export type module = {_RFDF: RFDF, Variable: string} & typeof(module)
type self = module

return module