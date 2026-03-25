local replicated_storage = game:GetService("ReplicatedStorage")
local run_service = game:GetService("RunService")

local packages = replicated_storage.Packages

local jecs = require(packages.jecs)

local object_cache_controller = require("../../Shared/Controllers/ObjectCacheController")
local components = require("../../Shared/Components")
local world = require("../../Shared/World")

local SPACING = 3

local FLOOR_RAY_HEIGHT = 12
local FLOOR_RAY_DISTANCE = 30

local module = {}

type PetAnimData = {
	cframe: CFrame,
	bobCycle: number,
	bobSpeed: number,
	bobDirection: number,
	teleport: boolean,
}

local pet_data = {} :: {[jecs.Entity]: PetAnimData}

local raycast_params = RaycastParams.new()
raycast_params.FilterType = Enum.RaycastFilterType.Include
raycast_params.FilterDescendantsInstances = {workspace.Map}
raycast_params.IgnoreWater = true

local function dt_lerp(a: CFrame, b: CFrame, fraction: number, dt: number): CFrame
	local f = 1 - math.pow(1 - fraction, dt)
	return a:Lerp(b, f)
end

local function update_animation_cframe(data: PetAnimData, distance: number, dt: number): CFrame
	data.bobCycle += dt * data.bobSpeed * 10

	if distance < 1 then
		if data.bobCycle > math.pi then
			data.bobCycle = math.pi
		end
	else
		if data.bobCycle > math.pi then
			data.bobCycle -= math.pi
			data.bobDirection *= -1
		end
	end

	local bob = math.abs(math.sin(data.bobCycle))
	return CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, bob * data.bobDirection * 0.2)
end

local delta_time = 0
function module.system()
	task.spawn(function()
		delta_time = run_service.Heartbeat:Wait()
	end)

	for pet in world:query(components.pet_tag):without(components.instance) do
		local player_entity = world:parent(pet)
		local player = world:get(pet, components.player)
		
		local character = player and player.Character
		if not character or not character.PrimaryPart then
			continue
		end

		local pet_scale = world:get(pet, components.scale) or 1

		local character_pivot = character:GetPivot()
		local model = object_cache_controller.get_object("pet", character_pivot) :: Model

		model:SetAttribute("ID", pet)
		model:ScaleTo(pet_scale)

		world:set(pet, components.instance, model)

		pet_data[pet] = {
			cframe = character_pivot,
			bobCycle = 0,
			bobSpeed = 1 + math.random(),
			bobDirection = math.random() > 0.5 and 1 or -1,
			teleport = true,
		}

		world:set(pet, components.cleanup, function()
			model:SetAttribute("ID", nil)
			model:ScaleTo(1)
			object_cache_controller.return_object("pet", model)
			pet_data[pet] = nil
		end)
	end

	local bulk_parts = {} :: {BasePart}
	local bulk_cframes = {} :: {CFrame}

	for pet in world:query(components.pet_tag):with(components.instance) do
		local player_entity = world:parent(pet)
		local player = world:get(pet, components.player)
		local character = player and player.Character
		if not character or not character.PrimaryPart then
			continue
		end

		local pet_model = world:get(pet, components.instance) :: Model
		local primary_part = pet_model.PrimaryPart
		if not primary_part then
			continue
		end

		local data = pet_data[pet]
		if not data then
			continue
		end

		local count = world:get(player_entity, components.pet_count)
		local index = world:get(pet, components.index)

		local columns = math.max(1, math.ceil(math.sqrt(count)))
		local rows = math.ceil(count / columns)

		local total_width = (columns - 1) * SPACING
		local total_depth = (rows - 1) * SPACING

		local offset = Vector3.new(-total_width / 2, 0, 6)
		local top_center_pos = offset + Vector3.new(total_width / 2, 0, 0)

		local column = index % columns
		local row = math.floor(index / columns)

		local target_position = offset + Vector3.new(column * SPACING, 0, row * SPACING)
		local target_cframe = character.PrimaryPart.CFrame * CFrame.new(target_position)

		local ray_origin = target_cframe.Position + Vector3.new(0, FLOOR_RAY_HEIGHT, 0)
		local ray_direction = Vector3.new(0, -FLOOR_RAY_DISTANCE, 0)
		local ray_result = workspace:Raycast(ray_origin, ray_direction, raycast_params)

		if ray_result then
			local y = ray_result.Position.Y + primary_part.Size.Y * 0.5
			target_cframe = CFrame.new(target_cframe.X, y, target_cframe.Z) * target_cframe.Rotation
		end

		if data.teleport then
			data.cframe = target_cframe
			data.teleport = false
		end

		local max_distance = Vector3.new(total_width, 0, total_depth).Magnitude
		local distance = (top_center_pos - target_position).Magnitude
		local _normalized_distance = max_distance > 0 and (distance / max_distance) or 0

		local movement_distance = (target_cframe.Position - data.cframe.Position).Magnitude
		local animation_cframe = update_animation_cframe(data, movement_distance, delta_time)

		data.cframe = dt_lerp(data.cframe, target_cframe, 0.9, delta_time)

		local final_cframe = data.cframe * animation_cframe

		table.insert(bulk_parts, primary_part)
		table.insert(bulk_cframes, final_cframe)
	end

	workspace:BulkMoveTo(bulk_parts, bulk_cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

return module