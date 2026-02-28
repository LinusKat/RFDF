local module = {}
module.__index = module

function module.Start()
	local self = setmetatable({}, module)
	print("I started!")
	return self
end

function module.Init(self)
	error("Issue!")
end

return module