--!native
local FAR_AWAY_CFRAME = CFrame.new(2^24, 2^24, 2^24)
local EXTEND_SIZE = 100

local hidden_container = Instance.new("Folder")
hidden_container.Name = "ObjectCache_Hidden"
hidden_container.Parent = script

local pending_parts: {BasePart} = table.create(10_000)
local pending_cframes: {CFrame} = table.create(10_000)
local movement_scheduled = false

local function flush_movement()
	while true do
		workspace:BulkMoveTo(pending_parts, pending_cframes, Enum.BulkMoveMode.FireCFrameChanged)
		table.clear(pending_parts)
		table.clear(pending_cframes)
		movement_scheduled = false
		coroutine.yield()
	end
end

local movement_thread = coroutine.create(flush_movement)

local function schedule_move(part: BasePart, cf: CFrame)
	table.insert(pending_parts, part)
	table.insert(pending_cframes, cf)
	if not movement_scheduled then
		movement_scheduled = true
		task.defer(movement_thread)
	end
end

local function get_root_part(obj: Instance): BasePart?
	if obj:IsA("BasePart") then
		return obj :: BasePart
	elseif obj:IsA("Model") then
		local mdl = obj :: Model
		assert(mdl.PrimaryPart, `ObjectCache: Model '{mdl.Name}' has no PrimaryPart set!`)
		return mdl.PrimaryPart :: BasePart
	end
	return nil
end

local function hide_object(obj: Instance, cache_parent: Instance)
	local root = get_root_part(obj)
	if root then
		schedule_move(root, FAR_AWAY_CFRAME)
	else
		obj.Parent = hidden_container
	end
end

local function show_object(obj: Instance, cf: CFrame, cache_parent: Instance)
	local root = get_root_part(obj)
	if root then
		schedule_move(root, cf)
	else
		obj.Parent = cache_parent
	end
end

local module = {}

module.registry = {} :: {[string]: {
	InUse: {[Instance]: true},
	Available: {Instance},
	Template: Instance,
	Parent: Instance,
}}

function module.create_cache(name: string, template: Instance, amount: number, parent: Instance?)
	assert(not module.registry[name], `ObjectCache: cache '{name}' already exists`)
	if template:IsA("Model") then
		assert((template :: Model).PrimaryPart, `ObjectCache: template Model has no PrimaryPart set!`)
	end

	local cache = {
		InUse = {},
		Available = {},
		Template = template,
		Parent = parent or script,
	}
	module.registry[name] = cache
	module.extend_cache(name, amount)
	return cache
end

function module.extend_cache(name: string, amount: number)
	local cache = assert(module.get_cache(name), `ObjectCache: cache '{name}' does not exist`)

	local bulk_parts = table.create(amount)
	local bulk_cframes = table.create(amount)
	local all_objects = table.create(amount)

	for i = 1, amount do
		local clone = cache.Template:Clone()
		local root = get_root_part(clone)
		if root then
			table.insert(bulk_parts,   root)
			table.insert(bulk_cframes, FAR_AWAY_CFRAME)
		else
			clone.Parent = hidden_container
		end
		all_objects[i] = clone
	end

	if #bulk_parts > 0 then
		workspace:BulkMoveTo(bulk_parts, bulk_cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end

	for _, obj in all_objects do
		local root = get_root_part(obj)
		if root and obj.Parent == nil then
			obj.Parent = cache.Parent
		end
		table.insert(cache.Available, obj)
	end
end

function module.get_cache(name: string)
	return module.registry[name]
end

function module.get_object(name: string, cf: CFrame?)
	local cache = module.get_cache(name)
	assert(cache, `ObjectCache: cache '{name}' does not exist`)

	if #cache.Available <= 0 then
		warn(`ObjectCache: '{name}' exhausted, extending by {EXTEND_SIZE}`)
		module.extend_cache(name, EXTEND_SIZE)
	end

	local obj = table.remove(cache.Available) :: Instance
	cache.InUse[obj] = true
	show_object(obj, cf or FAR_AWAY_CFRAME, cache.Parent)
	return obj
end

function module.return_object(name: string, obj: Instance)
	local cache = module.get_cache(name)
	assert(cache, `ObjectCache: cache '{name}' does not exist`)

	if not cache.InUse[obj] then
		warn(`ObjectCache: attempt to return an object that is not in use`)
		return
	end

	cache.InUse[obj] = nil
	table.insert(cache.Available, obj)
	hide_object(obj, cache.Parent)
end

function module.delete_cache(name: string)
	local cache = module.get_cache(name)
	assert(cache, `ObjectCache: cache '{name}' does not exist`)

	for obj in cache.InUse do
		obj:Destroy()
	end
	for _, obj in cache.Available do
		obj:Destroy()
	end

	module.registry[name] = nil
	table.clear(cache)
end

return module