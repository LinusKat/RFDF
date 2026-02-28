local mt = {}
mt.__index = mt

export type Dictionary<K, V> = {[K]: V}
export type Array<T> = {T}

export type StartupData = {
	RFDF: any,
}

export type StartCallback = (StartupData: StartupData, ...any) -> CommonServiceFunctions
export type InitCallback = (self: CommonServiceFunctions, ...any) -> any
export type KillCallback = (self: CommonServiceFunctions, ...any) -> any

export type CommonServiceType = typeof(mt)
export type CommonServiceFunctions = {
	Start: StartCallback,
	Init: InitCallback,
	Kill: KillCallback,
} & CommonServiceType

export type EndpointType = "Event" | "Function"

export type Middleware = {[string]: CommonServiceFunctions}

return{}