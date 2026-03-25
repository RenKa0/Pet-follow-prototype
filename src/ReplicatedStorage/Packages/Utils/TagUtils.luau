local collectionService = game:GetService("CollectionService")
local maidTaskUtils = require("./MaidTaskUtils")

local tagUtils = {}

function tagUtils.for_all_tagged(
	tag: string,
	on_added: (Instance) -> any,
	on_removed: (Instance) -> ()?
)
	local cleanup_map = {}
	local function handled_tagged_instance(instance: Instance)
		local cleanup = on_added(instance)
		if cleanup then
			cleanup_map[instance] = cleanup
		end
	end

	for _, instance in collectionService:GetTagged(tag) do
		handled_tagged_instance(instance)
	end
	table.insert(cleanup_map, collectionService:GetInstanceAddedSignal(tag):Connect(handled_tagged_instance))
	table.insert(cleanup_map, collectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		if cleanup_map[instance] then
			maidTaskUtils.do_task(cleanup_map[instance])
			cleanup_map[instance] = nil
		end

		if on_removed then
			on_removed(instance)
		end
	end))
	
	return function()
		maidTaskUtils.do_list(cleanup_map)
		table.clear(cleanup_map)
	end
end

return tagUtils