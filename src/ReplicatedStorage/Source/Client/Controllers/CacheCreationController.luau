local replicated_storage = game:GetService("ReplicatedStorage")
local assets = replicated_storage.Assets

local object_cache_controller = require("../../Shared/Controllers/ObjectCacheController")

local module = {}

function module.init()
	object_cache_controller.create_cache("pet", assets.Pet, 3_000, workspace.Terrain)
end

return module