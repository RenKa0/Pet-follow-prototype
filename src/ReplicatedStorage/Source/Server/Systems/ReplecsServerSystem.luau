local replicated_storage = game:GetService("ReplicatedStorage")
local packages = replicated_storage.Packages

local interval = require(packages.Utils.Interval)
local network = require("../../Shared/Network")
local replicator = require("../Replicator")

local updatesInterval = interval(1 / 20)
local unreliablesInterval = interval(1 / 30)

local module = {}

function module.system()
	if updatesInterval() then
		for player, buf, variants in replicator:collect_updates() do
			network.reliable_updates:fire(player, buf, variants)
		end
	end
	
	if unreliablesInterval() then
		for player, buf, variants in replicator:collect_unreliable() do
			network.unreliable_updates:fire(player, buf, variants)
		end
	end
end

return module