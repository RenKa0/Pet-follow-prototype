local replicated_storage = game:GetService("ReplicatedStorage")
local packages = replicated_storage.Packages

local replecs = require(packages.replecs)
local world = require("./World")

return replecs.create(world)