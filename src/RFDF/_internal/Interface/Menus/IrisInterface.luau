local root = script.Parent.Parent.Parent.Parent

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local CommonTypes = require(root.CommonTypes)

local Versions = require(root.VersionHistory)

local IsServer = RunService:IsServer()
local RunTypeString = IsServer and "Server" or "Client"

function MenuBar(Iris, rfdf)
	Iris.MenuBar()
	do
		Iris.Menu({ `RFDF` })
		do
			if Iris.MenuItem({ "Show Registry" }).clicked() then
				rfdf.Debug.ShowRegistry = not rfdf.Debug.ShowRegistry
			end
			if Iris.MenuItem({ "Show Logs" }).clicked() then
				rfdf.Debug.ShowLogs = not rfdf.Debug.ShowLogs
			end
			if Iris.MenuItem({ "Show Version History" }).clicked() then
				rfdf.Debug.ShowVersionHistory = not rfdf.Debug.ShowVersionHistory
			end

			if Iris.MenuItem({ "Master Toggle" }).clicked() then
				rfdf.DebugWindowsMasterToggle = not rfdf.DebugWindowsMasterToggle

				for k, _ in pairs(rfdf.Debug) do
					if k == "ShowIrisDemoWindow" then
						continue
					end
					rfdf.Debug[k] = rfdf.DebugWindowsMasterToggle
				end
			end

			Iris.Separator()

			if Iris.MenuItem({ "Shutdown RFDF" }).clicked() then
				rfdf:KillRFDFInstance()
			end

			Iris.Separator()

			if Iris.MenuItem({ "Show Iris Demo Window" }).clicked() then
				rfdf.Debug.ShowIrisDemoWindow = not rfdf.Debug.ShowIrisDemoWindow
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

function Registry(Iris, raw_middleware: CommonTypes.Middleware)
	local registry_transform =
		{ Size = Iris.State(Vector2.new(400, 300)), Position = Iris.State(Vector2.new(361, 526)) }
	Iris.Window(
		{ `RFDF Registry {RunTypeString}` },
		{ size = registry_transform.Size, position = registry_transform.Position }
	)
	do
		Iris.CollapsingHeader({ "Registered Services", true :: any })
		do
			Iris.Table({ 1, unpack({ true, true, true, false, false, false, true, true } :: any) })
			do -- // NumColumns | Header | Background | OuterBorder | InnerBorder | FixedWidth | ProportionalWidth | LimitWidth
				Iris.SetHeaderColumnIndex(1)
				do
					Iris.Text({ "Service Name" })
					Iris.NextColumn()
				end

				for Service in pairs(raw_middleware) do
					Iris.Text({ Service })
					Iris.NextColumn()
				end
			end
			Iris.End()
		end
		Iris.End()
	end
	Iris.End()
end

function Logs(Iris, rfdf)
	local console_transform = { Size = Iris.State(Vector2.new(400, 603)), Position = Iris.State(Vector2.new(763, 222)) }
	Iris.Window({ `RFDF Console` }, { size = console_transform.Size, position = console_transform.Position })
	do
		local filter = ""

		Iris.SameLine()
		do
			if Iris.Button({ "Clear" }).clicked() then
				rfdf:ClearLogs()
			end

			if Iris.Button({ "Dump JSON" }).clicked() then
				local array = {}
				for _, log in ipairs(rfdf._log_stack) do
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
				rfdf:Log("-------------------------------------------------", "PRINT", "Iris Import Logs Start")

				local raw_logs = text_input.state.text.value
				local json = string.match(raw_logs, "%b[]")

				local logs = HttpService:JSONDecode(json)

				for _, log in ipairs(logs) do
					local color = log.color and Color3.new(log.color.r, log.color.g, log.color.b) or Color3.new(1, 1, 1)
					rfdf:Log(log.info, color, log.origin, false, log.datetime)
				end

				input_field.Text = ""

				rfdf:Log("-------------------------------------------------", "PRINT", "Iris Import Logs End")
			end
		end
		Iris.End()

		Iris.SameLine()
		do
			local debug_log = Iris.Button({ "Debug Log" })
			local text_input = Iris.InputText({ "", "Log" })

			if debug_log.clicked() then
				rfdf:Log(text_input.state.text.value, "PRINT", "Iris Debug Log")
			end
		end
		Iris.End()

		Iris.Table({ 1, unpack({ true, true, true, false, false, false, true, true } :: { any }) })
		do -- // NumColumns | Header | Background | OuterBorder | InnerBorder | FixedWidth | ProportionalWidth | LimitWidth
			for index = #rfdf._log_stack, 1, -1 do
				local log = rfdf._log_stack[index]

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

return function(self, raw_middleware: CommonTypes.Middleware)
	local Iris = self.Iris

	MenuBar(Iris, self)

	if self.Debug.ShowVersionHistory then
		VersionHistory(Iris)
	end

	if self.Debug.ShowRegistry then
		Registry(Iris, raw_middleware)
	end

	if self.Debug.ShowLogs then
		Logs(Iris, self)
	end

	if self.Debug.ShowIrisDemoWindow then
		self.Iris.ShowDemoWindow()
	end
end
