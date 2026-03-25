local replicated_storage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local player = players.LocalPlayer
local mouse = player:GetMouse()

local packages = replicated_storage.Packages

local vide = require(packages.vide)

local mouse_vector = vide.source(Vector2.zero)
local mouse_position = vide.source(UDim2.new())

mouse.Move:Connect(function()
	local position = Vector2.new(mouse.X, mouse.Y)
	mouse_position(UDim2.fromOffset(mouse.X, mouse.Y))
	mouse_vector(position)
end)

return {
	mouse_vector = mouse_vector,
	mouse_position = mouse_position,
}