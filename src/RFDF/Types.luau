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

export type ReplicatedRegistryServerEndpoint = RFDF.ReplicatedRegistryServerEndpoint
export type ReplicatedRegistryClientEndpoint = RFDF.ReplicatedRegistryClientEndpoint
export type ServerNetworkEndpoint = RFDF.ServerNetworkEndpoint
export type ClientNetworkEndpoint = RFDF.ClientNetworkEndpoint

export type ServerReplicatedRegistryEndpoint = RFDF.ReplicatedRegistryServerEndpoint
export type ClientReplicatedRegistryEndpoint = RFDF.ReplicatedRegistryClientEndpoint

return{}