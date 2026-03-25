local replicated_storage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local packages = replicated_storage.Packages
local utils = packages.Utils
local ecs_utils = utils.ECS

local replecs = require(packages.replecs)
local jecs = require(packages.jecs)
local ref = require(ecs_utils.Ref)

local components = require("../../Shared/Components")
local create_pet = require("./Creators/CreatePet")
local replicator = require("../Replicator")
local world = require("../../Shared/World")

local PET_COUNT = 2_700
local random = Random.new()

local module = {}

local function on_player_added(player: Player)
	ref.get(player, function(entity)
		player:SetAttribute("ID", entity)
		print(`Player entity created {entity}`)
		
		world:add(entity, components.player_tag)
		
		for i = 1, PET_COUNT do
			local pet = create_pet.create_pet(entity)
			world:set(pet, components.index, i)
			world:set(pet, components.player, player)
			
			replicator:set_reliable(pet, components.index)
			replicator:set_reliable(pet, components.player)
		end
		
		--Can be dynamic, but all players will have the same amount of pets to just this
		world:set(entity, components.pet_count, PET_COUNT)
		
		replicator:set_networked(entity)
		replicator:set_reliable(entity, components.player_tag)
		replicator:set_reliable(entity, components.pet_count)
	end)
end

function module.init()
	for _, player in players:GetPlayers() do
		on_player_added(player)
	end
	players.PlayerAdded:Connect(on_player_added)
	players.PlayerRemoving:Connect(function(player)
		local player_entity = ref.find(player)
		if player_entity then
			world:delete(player_entity)
		end
	end)
end

return module