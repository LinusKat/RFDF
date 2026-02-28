local module = {}
module.__index = module

function module.Start()
	local self = setmetatable({}, module)
	error("Issue!")
	return self
end

function module.Init(self)
	print("I initialized!")
end

return module