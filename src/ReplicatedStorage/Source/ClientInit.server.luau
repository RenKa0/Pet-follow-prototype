local contextActionService = game:GetService("ContextActionService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local packages = replicatedStorage.Packages
local source = replicatedStorage.Source

local initializer = require(replicatedStorage.Initializer)
local replicator = require(source.Client.Replicator)
local network = require(source.Shared.Network)
local jabby = require(packages.jabby)

local modules = initializer.get_modules(true, source.Shared, source.Client)
initializer.load_modules(modules)
initializer.setup_systems(source.Shared, source.Client)

local client = jabby.obtain_client()
contextActionService:BindActionAtPriority("Open_Jabby", function(_, inputState: Enum.UserInputState)
	if inputState ~= Enum.UserInputState.Begin then
		return
	end

	client.spawn_app(client.apps.home, nil)
end, false, 1000, Enum.KeyCode.F4)

network.recieve_full:request():andThen(function(data)
	replicator:apply_full(table.unpack(data))
end)