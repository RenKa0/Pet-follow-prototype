local replicatedStorage = game:GetService("ReplicatedStorage")
local serverStorage = game:GetService("ServerStorage")
local runService = game:GetService("RunService")

local packages = replicatedStorage.Packages
local source = replicatedStorage.Source
local shared = source.Shared

local planck_utils = require(packages.Planck.Planck.utils)
local CONSTANTS = require(shared.CONSTANTS)
local jabby = require(packages.jabby)

local scheduler = require(shared.Scheduler)
local world = require(shared.World)

local IS_CLIENT = runService:IsClient()

local module = {}

function module.get_modules(recursive: boolean, ...: Instance)
	local modules = {}

	for _, parent in {...} do
		for _, child in parent:GetChildren() do
			if child:IsA("Configuration") and recursive then
				modules[`{child:GetFullName()}_Root`] = module.get_modules(recursive, child)
			elseif child:IsA("ModuleScript") then
				local data = require(child)
				if data == nil then
					continue
				end
				modules[child:GetFullName()] = data
			end
		end
	end

	return modules
end

function module.load_modules(modules: {[string]: any})
	local function load(index: string, data: any, methodName: string)
		if index:find("_Root") then
			for _index, _data in data do
				load(_index, _data, methodName)
			end
		else
			local callback = data[methodName]
			local context_callback = data[methodName[`{CONSTANTS.IS_SERVER and "server" or "client"}`]]
			
			if typeof(callback) == "function" then
				callback(data)
			end
			
			if typeof(context_callback) == "function" then
				context_callback(data)
			end
		end
	end
	
	for index, data in modules do
		load(index, data, "init")
	end
	
	for index, data in modules do
		load(index, data, "start")
	end
end

function module.setup_systems(...)
	local systems = {}
	
	for _, parent in {...} :: {Instance} do
		for _, system_module in parent:QueryDescendants("ModuleScript") do
			if not system_module.Name:match("System$") then
				continue
			end
			
			local system_data = require(system_module)
			
			if planck_utils.getSystem(system_data) then
				system_data.name = system_module.Name:gsub("System", "")
				table.insert(systems, system_data)
			end
		end
	end
	
	table.sort(systems, function(a, b)
		return (a.scheduler_priority or 0) < (b.scheduler_priority or 0)
	end)
	
	for i = 1, #systems do
		scheduler:addSystem(systems[i])
	end
	
	jabby.register({
		applet = jabby.applets.world,
		name = "World",
		configuration = {
			world = world,
		}
	})
end

return module