local replicated_storage = game:GetService("ReplicatedStorage")
local packages = replicated_storage.Packages

local replecs = require(packages.replecs)
local CONSTANTS = require("./CONSTANTS")

return (CONSTANTS.IS_SERVER and require("../Server/Replicator")
	or require("../Client/Replicator")) :: replecs.Client & replecs.Server