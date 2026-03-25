local replicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")
local serverStorage = game:GetService("ServerStorage")

local source = replicatedStorage.Source
local SERVER_MODULE_TAG = "ServerModule"

local tagUtils = require(replicatedStorage.Packages.Utils.TagUtils)
local initializer = require(replicatedStorage.Initializer)
local replicator = require(source.Server.Replicator)
local network = require(source.Shared.Network)

local modules = initializer.get_modules(true, source.Shared, source.Server)
initializer.load_modules(modules)
initializer.setup_systems(source.Shared, source.Server)

local function transfer_module(module: ModuleScript)
	local newModule = script.ServerModuleTemplate:Clone()
	newModule.Name = module.Name
	newModule.Module.Value = module
	newModule.Parent = module.Parent
	
	module.Parent = serverStorage.TransferedModules
end

for _, descendant in source.Server:QueryDescendants("ModuleScript") do
	descendant:AddTag(SERVER_MODULE_TAG)
end
tagUtils.for_all_tagged(SERVER_MODULE_TAG, transfer_module)

network.recieve_full:onRequest(function(player)
	replicator:mark_player_ready(player)
	return {replicator:get_full(player)}
end)