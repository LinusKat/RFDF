local CommonTypes = require(script.Parent.CommonTypes)
local RFDF = require(script.Parent)

export type StartupData = {
	RFDF: any,
}

export type StartCallback = CommonTypes.StartCallback
export type InitCallback = CommonTypes.InitCallback
export type KillCallback = CommonTypes.KillCallback

export type CommonServiceFunctions = CommonTypes.CommonServiceFunctions

export type EndpointType = CommonTypes.EndpointType

export type RFDF = RFDF.RFDF

return{}