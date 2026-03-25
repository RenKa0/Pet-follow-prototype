local replicated_storage = game:GetService("ReplicatedStorage")
local packages = replicated_storage.Packages

local jecs = require(packages.jecs)

local components = require("../../../Shared/Components")
local replicator = require("../../Replicator")
local world = require("../../../Shared/World")

--[[
	Note: this could be named, pet controller if more content gets added.
]]
local module = {}

function module.create_pet(owner: jecs.Entity)
	local pet = world:entity()
	world:add(pet, components.pet_tag)
	world:add(pet, jecs.pair(jecs.ChildOf, owner))
	
	replicator:set_networked(pet)
	replicator:set_reliable(pet, components.pet_tag)
	replicator:set_pair(pet, jecs.ChildOf)
	
	return pet
end

return module