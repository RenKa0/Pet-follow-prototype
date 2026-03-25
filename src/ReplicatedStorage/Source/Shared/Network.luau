local replicated_storage = game:GetService("ReplicatedStorage")
local packages = replicated_storage.Packages

local type_checker = require(packages.typeChecker)
local remo = require(packages.remo)

return remo.createRemotes({
	unreliable_updates = remo.remote(type_checker.buffer, type_checker.any),
	reliable_updates = remo.remote(type_checker.buffer, type_checker.any),
	
	recieve_full = remo.remote().returns(type_checker.any)
}) :: remo.Remotes<{
	unreliable_updates: remo.ServerToClient<any>,
	reliable_updates: remo.ServerToClient<any>,
	
	recieve_full: remo.ServerAsync<(), (any)>,
}>