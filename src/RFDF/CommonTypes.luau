local mt = {}
mt.__index = mt

export type Dictionary<K, V> = {[K]: V}
export type Array<T> = {T}

export type StartupData = {
	RFDF: any,
}

export type newCallback = (StartupData: StartupData, ...any) -> CommonServiceFunctions
export type InitCallback = (self: CommonServiceFunctions, ...any) -> any
export type KillCallback = (self: CommonServiceFunctions, ...any) -> any
export type DebugInterfaceCallback = (self: CommonServiceFunctions, Iris: any, ...any) -> any

export type CommonServiceType = typeof(mt)
export type CommonServiceFunctions = {
	new: newCallback,
	Init: InitCallback,
	Kill: KillCallback,

	_debug_interface: DebugInterfaceCallback,
} & CommonServiceType

export type Middleware = {[string]: CommonServiceFunctions}

return{}