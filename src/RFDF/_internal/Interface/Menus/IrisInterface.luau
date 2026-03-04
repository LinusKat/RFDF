local root = script.Parent.Parent.Parent.Parent

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local CommonTypes = require(root.CommonTypes)

local Versions = require(root.VersionHistory)

local IsServer = RunService:IsServer()
local RunTypeString = IsServer and "Server" or "Client"

local InterfaceBucket = {}
local InterfaceBucketToggles = {}

local Switches = {
	ShowRegistry = false,
	ShowLogs = false,
	ShowVersionHistory = false,
	ShowStatistics = false,

	ShowIrisDemoWindow = false,
}
local Master = false

local Initialised = false

function MenuBar(Iris, RFDF)
	Iris.MenuBar()
	do
		Iris.Menu({ `RFDF` })
		do
			if Iris.MenuItem({ "Show Registry" }).clicked() then
				Switches.ShowRegistry = not Switches.ShowRegistry
			end
			if Iris.MenuItem({ "Show Logs" }).clicked() then
				Switches.ShowLogs = not Switches.ShowLogs
			end
			if Iris.MenuItem({ "Show Version History" }).clicked() then
				Switches.ShowVersionHistory = not Switches.ShowVersionHistory
			end
			if Iris.MenuItem({ "Show Statistics" }).clicked() then
				Switches.ShowStatistics = not Switches.ShowStatistics
			end

			if Iris.MenuItem({ "Master Toggle" }).clicked() then
				Master = not Master

				for k, _ in pairs(Switches) do
					if k == "ShowIrisDemoWindow" then
						continue
					end
					Switches[k] = Master
				end
			end

			Iris.Separator()

			if Iris.MenuItem({ "Shutdown RFDF" }).clicked() then
				RFDF:KillRFDFInstance()
			end

			Iris.Separator()

			if Iris.MenuItem({ "Show Iris Demo Window" }).clicked() then
				Switches.ShowIrisDemoWindow = not Switches.ShowIrisDemoWindow
			end
		end
		Iris.End()

		Iris.Menu({ `SDIB` })
		do
			for key, service in pairs(InterfaceBucket) do
				if Iris.MenuItem({ key }).clicked() then
					InterfaceBucketToggles[key] = not InterfaceBucketToggles[key]
				end
			end
		end
		Iris.End()
	end
	Iris.End()
end

function VersionHistory(Iris)
	local version_history_transform =
		{ Size = Iris.State(Vector2.new(400, 300)), Position = Iris.State(Vector2.new(361, 222)) }
	Iris.Window(
		{ `Version History` },
		{ size = version_history_transform.Size, position = version_history_transform.Position }
	)
	do
		for index, v in ipairs(Versions) do
			Iris.CollapsingHeader({ v.Name, index == 1 and true or false })

			Iris.Table({ 3, unpack({ true, true, true, false, false, false, true, true } :: { any }) })
			do -- // NumColumns | Header | Background | OuterBorder | InnerBorder | FixedWidth | ProportionalWidth | LimitWidth
				Iris.SetHeaderColumnIndex(1)
				do
					Iris.Text({ "Info" })
					Iris.NextColumn()

					Iris.Text({ "Author" })
					Iris.NextColumn()

					Iris.Text({ "Date" })
					Iris.NextColumn()
				end

				for _, change in ipairs(v.Data) do
					Iris.Text({ change.Info })
					Iris.NextColumn()

					Iris.Text({ change.Author })
					Iris.NextColumn()

					Iris.Text({ change.Date })
					Iris.NextColumn()
				end
			end
			Iris.End()

			Iris.End()
		end
	end
	Iris.End()
end

function Registry(RFDF, Iris, raw_middleware: CommonTypes.Middleware)
	local registry_transform =
		{ Size = Iris.State(Vector2.new(400, 300)), Position = Iris.State(Vector2.new(361, 526)) }
	Iris.Window(
		{ `RFDF Registry {RunTypeString}` },
		{ size = registry_transform.Size, position = registry_transform.Position }
	)
	do
		Iris.CollapsingHeader({ "Registered Services", true :: any })
		do
			Iris.Table({ 2, unpack({ true, true, true, false, false, false, true, true } :: any) })
			do -- // NumColumns | Header | Background | OuterBorder | InnerBorder | FixedWidth | ProportionalWidth | LimitWidth
				Iris.SetHeaderColumnIndex(1)
				do
					Iris.Text({ "Service Name" })
					Iris.NextColumn()
					Iris.Text({ "Debug Menu Toggle" })
					Iris.NextColumn()
				end

				for key, _ in pairs(raw_middleware) do
					Iris.Text({ key })
					Iris.NextColumn()
					if InterfaceBucket[key] ~= nil then
						if Iris.Button({ "Toggle" }).clicked() then
							InterfaceBucketToggles[key] = not InterfaceBucketToggles[key]
						end
					end
					Iris.NextColumn()
				end
			end
			Iris.End()
		end
		Iris.End()

		Iris.CollapsingHeader({ "Registered Network Endpoints", true :: any })
		do
			Iris.Table({ 2, unpack({ true, true, true, false, false, false, true, true } :: any) })
			do -- // NumColumns | Header | Background | OuterBorder | InnerBorder | FixedWidth | ProportionalWidth | LimitWidth
				Iris.SetHeaderColumnIndex(1)
				do
					Iris.Text({ "unique u8id" })
					Iris.NextColumn()
					Iris.Text({ "tag" })
					Iris.NextColumn()
				end

				for u8id, endpoint in pairs(RFDF.Network._registered_endpoints) do
					Iris.Text({ string.format("%f", u8id) })
					Iris.NextColumn()
					Iris.Text({ endpoint._tag or "" })
					Iris.NextColumn()
				end
			end
			Iris.End()
		end
		Iris.End()
	end
	Iris.End()
end

function Logs(RFDF, Iris)
	local console_transform = { Size = Iris.State(Vector2.new(400, 603)), Position = Iris.State(Vector2.new(763, 222)) }
	Iris.Window({ `RFDF Console` }, { size = console_transform.Size, position = console_transform.Position })
	do
		local filter = ""

		Iris.SameLine()
		do
			if Iris.Button({ "Clear" }).clicked() then
				RFDF:ClearLogs()
			end

			if Iris.Button({ "Dump JSON" }).clicked() then
				local array = {}
				for _, log in ipairs(RFDF._log_stack) do
					table.insert(array, {
						datetime = log.datetime,
						origin = log.origin,
						info = log.info,
						color = log.color and { r = log.color.R, g = log.color.G, b = log.color.B }
							or { r = 1, g = 1, b = 1 },
					})
				end

				print(HttpService:JSONEncode(array))
			end

			local filter_input = Iris.InputText({ "", "Filter" })
			local input_field = (filter_input.Instance :: any).InputField
			filter = input_field.Text
		end
		Iris.End()

		Iris.SameLine()
		do
			local import = Iris.Button({ "Import Logs" })
			local text_input = Iris.InputText({ "", "Input" })
			local input_field = (text_input.Instance :: any).InputField

			if import.clicked() then
				RFDF:Log("-------------------------------------------------", "PRINT", "Iris Import Logs Start")

				local raw_logs = text_input.state.text.value
				local json = string.match(raw_logs, "%b[]")

				local logs = HttpService:JSONDecode(json)

				for _, log in ipairs(logs) do
					local color = log.color and Color3.new(log.color.r, log.color.g, log.color.b) or Color3.new(1, 1, 1)
					RFDF:Log(log.info, color, log.origin, false, log.datetime)
				end

				input_field.Text = ""

				RFDF:Log("-------------------------------------------------", "PRINT", "Iris Import Logs End")
			end
		end
		Iris.End()

		Iris.SameLine()
		do
			local debug_log = Iris.Button({ "Debug Log" })
			local text_input = Iris.InputText({ "", "Log" })

			if debug_log.clicked() then
				RFDF:Log(text_input.state.text.value, "PRINT", "Iris Debug Log")
			end
		end
		Iris.End()

		Iris.Table({ 1, unpack({ true, true, true, false, false, false, true, true } :: { any }) })
		do -- // NumColumns | Header | Background | OuterBorder | InnerBorder | FixedWidth | ProportionalWidth | LimitWidth
			for index = #RFDF._log_stack, 1, -1 do
				local log = RFDF._log_stack[index]

				if not string.match(string.lower(log.info), filter) then
					continue
				end

				Iris.PushConfig({ TextColor = log.color })
				do
					Iris.Text({
						string.format("[%s] [%s] %s", tostring(log.datetime), log.origin, log.info),
					})
				end
				Iris.PopConfig()
				Iris.NextColumn()
			end
		end
		Iris.End()
	end
	Iris.End()
end

local function Statistics(RFDF, Iris)
	local transform = { Size = Iris.State(Vector2.new(400, 603)), Position = Iris.State(Vector2.new(1167, 222)) }

	Iris.Window({"Statistics"}, { size = transform.Size, position = transform.Position }); do
		Iris.Text{string.format(`FPS: %.0fms`, 1 / Stats.FrameTime)}
		Iris.Text{string.format(`Render: %.4fms`, Stats.RenderCPUFrameTime * 1000)}
		Iris.Text{string.format(`Physics: %.4fms`, Stats.PhysicsStepTime * 1000)}

		Iris.SeparatorText{"World"}
		Iris.Text{string.format(`Instances: %.0f`, Stats.InstanceCount)}
		Iris.Text{string.format(`World Draw Calls: %.0f`, Stats.SceneDrawcallCount)}
		Iris.Text{string.format(`World Triangles: %.0f`, Stats.SceneTriangleCount)}
		Iris.Text{string.format(`Shadow Draw Calls: %.0f`, Stats.ShadowsDrawcallCount)}
		Iris.Text{string.format(`Shadow Triangles: %.0f`, Stats.ShadowsTriangleCount)}

		Iris.SeparatorText{"UI"}
		Iris.Text{string.format(`UI 2D Draw Calls: %.0f`, Stats.UI2DDrawcallCount)}
		Iris.Text{string.format(`UI 2D Triangles: %.0f`, Stats.UI2DTriangleCount)}
		Iris.Text{string.format(`UI 3D Draw Calls: %.0f`, Stats.UI3DDrawcallCount)}
		Iris.Text{string.format(`UI 3D Triangles: %.0f`, Stats.UI3DTriangleCount)}

		Iris.SeparatorText{"Network"}
		Iris.Text{string.format(`Data Send: %.2fkbps`, Stats.DataSendKbps)}
		Iris.Text{string.format(`Data Receive: %.2fkbps`, Stats.DataReceiveKbps)}
		Iris.Text{string.format(`Physics Send: %.2fkbps`, Stats.PhysicsSendKbps)}
		Iris.Text{string.format(`Physics Receive: %.2fkbps`, Stats.PhysicsReceiveKbps)}
	end; Iris.End()
end

return function(self, raw_middleware: CommonTypes.Middleware)
	local Iris = self.Iris

	if not Initialised then
		for Key, Service in pairs(raw_middleware) do
			if typeof(Service._debug_interface) ~= "function" then continue end
			InterfaceBucket[Key] = Service
			InterfaceBucketToggles[Key] = false
		end

		Initialised = true
	end

	MenuBar(Iris, self)

	for key, service in pairs(InterfaceBucket) do
		if InterfaceBucketToggles[key] then
			service:_debug_interface(Iris)
		end
	end

	if Switches.ShowVersionHistory then
		VersionHistory(Iris)
	end

	if Switches.ShowRegistry then
		Registry(self, Iris, raw_middleware)
	end

	if Switches.ShowLogs then
		Logs(self, Iris)
	end

	if Switches.ShowStatistics then
		Statistics(self, Iris)
	end

	if Switches.ShowIrisDemoWindow then
		self.Iris.ShowDemoWindow()
	end
end
