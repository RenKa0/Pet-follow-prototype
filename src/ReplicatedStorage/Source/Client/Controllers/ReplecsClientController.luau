local network = require("../../Shared/Network")
local replicator = require("../Replicator")

local module = {}

function module.init()
	network.reliable_updates:connect(function(...)
		replicator:apply_updates(...)
	end)
	
	network.unreliable_updates:connect(function(...)
		replicator:apply_unreliable(...)
	end)
end

return module