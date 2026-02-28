local STRING_TO_INSTANCE_IDENTIFIER = string.char(129)

local function GetInstanceFromFullName(fullName: string)
	local route = fullName:split(".")
	local current = game

	for _, child: string in ipairs(route) do
		current = current:FindFirstChild(child)

		if not current then
			break
		end
	end

	return current
end

function RecursivePacketInstanceProcessing(Serialize: boolean, Input: any)
	local t = typeof(Input)
	
	if not Serialize and t == "string" then
		local instance_identifier = string.sub(Input, 1, #STRING_TO_INSTANCE_IDENTIFIER) == STRING_TO_INSTANCE_IDENTIFIER
		if instance_identifier then
			return GetInstanceFromFullName(string.split(Input, STRING_TO_INSTANCE_IDENTIFIER)[2])
		end
	end
	
	if Serialize and t == "Instance" then
		return STRING_TO_INSTANCE_IDENTIFIER .. Input:GetFullName()
	end
	
	if t == "table" then
		for key, value in pairs(Input) do
			Input[key] = RecursivePacketInstanceProcessing(Serialize, value)
		end
	end

	return Input
end

return {
    GetInstanceFromFullName = GetInstanceFromFullName,
    RecursivePacketInstanceProcessing = RecursivePacketInstanceProcessing,
}