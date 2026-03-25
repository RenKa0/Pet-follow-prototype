local replicated_storage = game:GetService("ReplicatedStorage")

local packages = replicated_storage.Packages

local replicator = require("./CurrentReplicator")
local replecs = require(packages.replecs)
local jecs = require(packages.jecs)
local world = require("./World")

local module = {}
module.instance = world:component() :: jecs.Entity<Instance>
module.player = world:component() :: jecs.Entity<Player>

module.pet_count = world:component() :: jecs.Entity<number>
module.pet_tag = world:entity()

module.index = world:component() :: jecs.Entity<number>

module.player_tag = world:entity()
module.cleanup = world:component() :: jecs.Entity<(jecs.Entity) -> ()>

for compName, comp in module :: {[string]: jecs.Entity} do
	world:set(comp, jecs.Name, compName)
	world:add(comp, replecs.shared)
end
world:add(jecs.Name, replecs.shared)

world:removed(module.cleanup, function(entity: jecs.Entity)
	local callback = world:get(entity, module.cleanup)

	if callback then
		callback(entity)
	end
end)

replicator:init_replicator()

return module