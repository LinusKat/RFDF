--!strict
local RFDF = require(script.Parent.Parent)

type RFDF = RFDF.RFDF

local module = {}

function module.TestLoading(RFDF: RFDF)
	local services = script._loading_test_services
	RFDF:LoadServicesFromFolder(services)

	print(string.format("Unit Test Issues: %f", #RFDF._issues))

	if #RFDF._issues ~= 0 then
		error("RFDF SERVICE LOAD UNIT TEST FAILED")
	end
end

return module