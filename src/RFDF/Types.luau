local CommonTypes = require(script.Parent.CommonTypes)
local RFDF = require(script.Parent)

export type StartupData = {
	RFDF: RFDF,
}

export type newCallback = CommonTypes.newCallback
export type InitCallback = CommonTypes.InitCallback
export type KillCallback = CommonTypes.KillCallback
export type DebugInterfaceCallback = CommonTypes.DebugInterfaceCallback

export type CommonServiceFunctions = CommonTypes.CommonServiceFunctions

export type RFDF = RFDF.RFDF
export type RFDFClientExposed = RFDF.ClientExposed
export type RFDFServerExposed = RFDF.ServerExposed

export type ReplicatedRegistryEndpoint = RFDF.ReplicatedRegistryEndpoint
export type ServerNetworkEndpoint = RFDF.ServerNetworkEndpoint
export type ClientNetworkEndpoint = RFDF.ClientNetworkEndpoint
export type RemoteFunctionEndpoint = RFDF.RemoteFunctionEndpoint

export type AnyEndpoint = RFDF.AnyEndpoint

return{}