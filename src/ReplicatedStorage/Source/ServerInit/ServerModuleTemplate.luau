local serverStorage = game:GetService("ServerStorage")
local runService = game:GetService("RunService")

assert(runService:IsServer(), "This module can only be required on the server")
return require(script.Module.Value)