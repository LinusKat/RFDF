--!strict
const os_clock = os.clock

return function(): () -> string
	const t0 = os_clock()
	return function()
		local et = os_clock() - t0
		return string.format("%.2fμs", et * 1e6)
	end
end