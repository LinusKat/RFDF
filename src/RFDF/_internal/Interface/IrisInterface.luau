-- i am very much aware this code is horrendous however i have not had the time to fix it.
local root = script.Parent.Parent.Parent.Parent

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local CommonTypes = require(root.CommonTypes)
local Versions = require(root.VersionHistory)
local Sift = require(root._packages.Sift)
local Memory = require(root.Util.Memory)

local IsServer = RunService:IsServer()
local RunTypeString = IsServer and "Server" or "Client"

local InterfaceBucket = {}
local InterfaceBucketToggles = {}

local Switches = {
	ShowRegistry = 1,
	ShowLogs = 1,
	ShowVersionHistory = 1,
	ShowStatistics = 1,

	ShowIrisDemoWindow = 1,
}
local Master = false

local Initialised = false

local RenderCPUFrameTimeMemory = Memory.new(60)
local PhysicsStepTimeMemory = Memory.new(60)
local FrameTimeMemory = Memory.new(60)
local MemoryMBMemory = Memory.new(20)

local Frame = 0

MemoryMBMemory:Feed(vector.create(Frame, 0))
MemoryMBMemory:Feed(vector.create(Frame, 1))

--ImOverlay:Text(string.format(`FPS: %.0ffps`, 1 / Stats.FrameTime))
--ImOverlay:Text(string.format(`Render: %.2fms`, Stats.RenderCPUFrameTime * 1000))
--ImOverlay:Text(string.format(`Physics: %.2fms`, Stats.PhysicsStepTime * 1000))

function MenuBar(Iris, RFDF)
	Iris.MenuBar()
	do
		Iris.Menu({ `RFDF` })
		do
			if Iris.MenuItem({ "Show Registry" }).clicked() then
				Switches.ShowRegistry:set(not Switches.ShowRegistry.value)
			end
			if Iris.MenuItem({ "Show Logs" }).clicked() then
				Switches.ShowLogs:set(not Switches.ShowLogs.value)
			end
			if Iris.MenuItem({ "Show Version History" }).clicked() then
				Switches.ShowVersionHistory:set(not Switches.ShowVersionHistory.value)
			end
			if Iris.MenuItem({ "Show Statistics" }).clicked() then
				Switches.ShowStatistics:set(not Switches.ShowStatistics.value)
			end

			if Iris.MenuItem({ "Master Toggle" }).clicked() then
				Master = not Master

				for k, _ in Switches do
					if k == "ShowIrisDemoWindow" then
						continue
					end
					Switches[k]:set(Master)
				end
			end

			Iris.Separator()

			if Iris.MenuItem({ "Shutdown RFDF" }).clicked() then
				RFDF:KillRFDFInstance()
			end

			Iris.Separator()

			if Iris.MenuItem({ "Show Iris Demo Window" }).clicked() then
				Switches.ShowIrisDemoWindow:set(not Switches.ShowIrisDemoWindow)
			end
		end
		Iris.End()

		Iris.Menu({ `VIEW` })
		do
			for key, service in InterfaceBucket do
				if Iris.MenuItem({ key }).clicked() then
					InterfaceBucketToggles[key]:set(not InterfaceBucketToggles[key]:get())
				end
			end
		end
		Iris.End()
	end
	Iris.End()
end

function VersionHistory(Iris)
	local version_history_transform = { Size = Iris.State(Vector2.new(400, 300)), Position = Iris.State(Vector2.new(361, 222)) }
	
	local window = Iris.Window({ `Version History` }, { size = version_history_transform.Size, position = version_history_transform.Position, isOpened = Switches.ShowVersionHistory }); do
		for index, v in Versions do
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

				for _, change in v.Data do
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
	end; Iris.End()
end

function Registry(RFDF, Iris, raw_middleware: CommonTypes.Middleware)
	local registry_transform = { Size = Iris.State(Vector2.new(400, 300)), Position = Iris.State(Vector2.new(361, 526)) }
	
	local window = Iris.Window({ `RFDF Registry {RunTypeString}` }, { size = registry_transform.Size, position = registry_transform.Position, isOpened = Switches.ShowRegistry }); do
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

				for key, _ in raw_middleware do
					Iris.Text({ key })
					Iris.NextColumn()
					if InterfaceBucket[key] ~= nil then
						if Iris.Button({ "Toggle" }).clicked() then
							InterfaceBucketToggles[key]:set(not InterfaceBucketToggles[key]:get())
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

				for u8id, endpoint in RFDF.Network._registered_endpoints do
					Iris.Text({ string.format("%f", u8id) })
					Iris.NextColumn()
					Iris.Text({ endpoint._tag or "" })
					Iris.NextColumn()
				end
			end
			Iris.End()
		end
		Iris.End()
	end; Iris.End()
end

function Logs(RFDF, Iris)
	local console_transform = { Size = Iris.State(Vector2.new(400, 603)), Position = Iris.State(Vector2.new(763, 222)) }
	
	local window = Iris.Window({ `RFDF Console` }, { size = console_transform.Size, position = console_transform.Position, isOpened = Switches.ShowLogs }); do
		local filter = ""

		Iris.SameLine()
		do
			if Iris.Button({ "Clear" }).clicked() then
				RFDF:ClearLogs()
			end

			if Iris.Button({ "Dump JSON" }).clicked() then
				local array = {}
				for _, log in RFDF._log_stack do
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
			
			if Iris.Button({ "Dump Formatted" }).clicked() then
				for _, log in RFDF._log_stack do
					RFDF:_log_verbose(log.color, log.verbose_log)
				end
			end

			local filter_input = Iris.InputText({ "", "Filter" })
			local input_field = (filter_input.Instance :: any).InputField
			filter = input_field.Text
		end
		Iris.End()

		Iris.SameLine()
		do
			local import = Iris.Button({ "Import Logs From Json" })
			local text_input = Iris.InputText({ "", "Input" })
			local input_field = (text_input.Instance :: any).InputField

			if import.clicked() then
				RFDF:Print("-------------------------------------------------", "Iris Import Logs Start")

				local raw_logs = text_input.state.text.value
				local json = string.match(raw_logs, "%b[]")

				local logs = HttpService:JSONDecode(json)

				for _, log in logs do
					local color = log.color and Color3.new(log.color.r, log.color.g, log.color.b) or Color3.new(1, 1, 1)
					RFDF:Log(log.info, color, log.origin, false, log.datetime)
				end

				input_field.Text = ""

				RFDF:Print("-------------------------------------------------", "Iris Import Logs End")
			end
		end
		Iris.End()

		Iris.SameLine()
		do
			local debug_log = Iris.Button({ "Debug Log" })
			local text_input = Iris.InputText({ "", "Log" })

			if debug_log.clicked() then
				RFDF:Print(text_input.state.text.value, "Iris Debug Log")
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
	end; Iris.End()
end

local function Statistics(RFDF, Iris)
	local transform = { Size = Iris.State(Vector2.new(400, 603)), Position = Iris.State(Vector2.new(1167, 222)) }

	local frame_plots = Iris.State({})
	local fps_plots = Iris.State({})
	
	local memory_plots = Iris.State({})

	local window = Iris.Window({"Statistics"}, { size = transform.Size, position = transform.Position, isOpened = Switches.ShowStatistics }); do
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
		
		Iris.SeparatorText{"Profiler"}
		Iris.Text{string.format(`FPS: %.0ffps`, 1 / Stats.FrameTime)}
		Iris.Text{string.format(`Render: %.4fms`, Stats.RenderCPUFrameTime * 1000)}
		Iris.Text{string.format(`Physics: %.4fms`, Stats.PhysicsStepTime * 1000)}
		
		Frame += 1
		
		RenderCPUFrameTimeMemory:Feed(vector.create(Frame, Stats.RenderCPUFrameTime * 1000))
		PhysicsStepTimeMemory:Feed(vector.create(Frame, Stats.PhysicsStepTime * 1000))
		FrameTimeMemory:Feed(vector.create(Frame, Stats.FrameTime))
		
		frame_plots:set{{
			Data = RenderCPUFrameTimeMemory.Memory,
			Name = "Render CPU Frame Time",
			GraphStyle = {
				Color = Color3.new(1, 0, 0),
				Thickness = 1,
			},
		}, 
		{
			Data = PhysicsStepTimeMemory.Memory,
			Name = "Physics Step Time",
			GraphStyle = {
				Color = Color3.new(0, 1, 0),
				Thickness = 1,
			},
		}}
	
		fps_plots:set{{
			Data = FrameTimeMemory.Memory,
			Name = "FPS",
			GraphStyle = {
				Color = Color3.new(0, 0, 1),
				Thickness = 1,
			},
		}}
		
		Iris.ImPlotGraph({
			"Frame Time",
			{ X = "frame", Y = "ms", XScale = 1, YScale = .8 } 
		},
			{ plots = frame_plots, showDataInformation = Iris.State(true) }
		)
		
		Iris.ImPlotGraph({
			"FPS",
			{ X = "frame", Y = "FPS", XScale = 1, YScale = .8 } 
		},
			{ plots = fps_plots, showDataInformation = Iris.State(false) }
		)
		
		if Stats.MemoryTrackingEnabled then
			if Frame % 500 == 0 then
				MemoryMBMemory:Feed(vector.create(Frame, Stats:GetTotalMemoryUsageMb()))
			end
			
			memory_plots:set{{
				Data = MemoryMBMemory.Memory,
				Name = "Memory",
				GraphStyle = {
					Color = Color3.new(1, 0.929412, 0.14902),
					Thickness = 1,
				},
			}}
			
			Iris.ImPlotGraph({
				"Memory Usage MB",
				{ X = "Frame", Y = "MB", XScale = 1, YScale = .8 }},
			{ plots = memory_plots, showDataInformation = Iris.State(true) }
			)
		else
			Iris.Text({"Memory Tracking is Disabled, join with MicroProfiler on (Shift + F6) to ensure it is enabled"})
		end
	end; Iris.End()
end

return function(self, raw_middleware: CommonTypes.Middleware)
	local Iris = self.Iris

	if not Initialised then
		for Key, Service in raw_middleware do
			if typeof(Service._debug_interface) ~= "function" then continue end
			InterfaceBucket[Key] = Service
			InterfaceBucketToggles[Key] = Iris.State(false)
		end
		
		for k, v in Switches do
			Switches[k] = Iris.State(false)
		end

		Initialised = true
	end
	
	for _, v in Iris.Internal._rootInstance:GetChildren() do
		v:AddTag("FreecamIgnoreDisable")
	end

	MenuBar(Iris, self)

	for key, service in InterfaceBucket do
		service:_debug_interface(Iris, InterfaceBucketToggles[key])
	end

	VersionHistory(Iris)
	Registry(self, Iris, raw_middleware)
	Logs(self, Iris)
	Statistics(self, Iris)

	if Switches.ShowIrisDemoWindow:get() then
		self.Iris.ShowDemoWindow()
	end
end
