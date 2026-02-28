--!strict
local Memory = {}
Memory.__index = Memory

function Memory.new(MemoryLength: number)
	local self = setmetatable({}:: self, Memory)
	self.Memory = {}
	self.MemoryLength = MemoryLength
	
	return self
end

function Memory._clamp_memory(self: self)
	if #self.Memory >= self.MemoryLength then
		table.remove(self.Memory, 1)
		self:_clamp_memory()
	end
end

function Memory.Feed(self: self, Value: any)
	self:_clamp_memory()
	table.insert(self.Memory, Value)
end

function Memory.Destroy(self: self)
	table.clear(self)
end

export type Memory = {
	Memory: {any},
	MemoryLength: number,
} & typeof(Memory)
type self = Memory
return Memory