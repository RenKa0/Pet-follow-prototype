--!optimize 2
local jecs = require("../../jecs")
local refs: { [any]: any } = {}

local set_world = (nil :: any) :: jecs.World

local function get(key: any, initer: ((entity: jecs.Entity) -> ())?): jecs.Entity
	if not key then
		local entity = set_world:entity()
		if initer then
			initer(entity)
		end
		return entity
	end

	local entity = refs[key]
	if not entity then
		entity = set_world:entity()

		if initer then
			initer(entity)
		end

		refs[key] = entity
	end

	return entity
end

local function find(key: any): jecs.Entity?
	if not key then
		return nil
	end
	local entity = refs[key]

	if not entity then
		return nil
	end

	return entity
end

function set(key: any, entity: jecs.Entity)
	refs[key] = entity
end

function delete(key: any)
	if not key then
		return
	end
	refs[key] = nil
end

function world(wrld: jecs.World)
	set_world = wrld
end

return {
	get = get,
	set = set,
	find = find,
	delete = delete,
	world = world,
}