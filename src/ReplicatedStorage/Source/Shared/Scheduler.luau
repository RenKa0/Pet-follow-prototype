local replicated_storage = game:GetService("ReplicatedStorage")

local packages = replicated_storage.Packages
local planck_modules = packages.Planck

local planck_run_service = require(planck_modules.PlanckRunService)
local matter_hooks = require(planck_modules.PlanckMatterHooks)
local planck_jabby = require(planck_modules.PlanckJabby)
local planck = require(planck_modules.Planck)

local world = require("./World")

local runServicePlugin = planck_run_service.Plugin.new()
local hooksPlugin = matter_hooks.Plugin.new()
local jabbyPlugin = planck_jabby.new()

return planck.Scheduler.new(world)
	:addPlugin(jabbyPlugin)
	:addPlugin(runServicePlugin)
	:addPlugin(hooksPlugin)