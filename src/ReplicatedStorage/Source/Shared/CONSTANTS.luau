local run_service = game:GetService("RunService")

local module = {}
module.IS_SERVER = run_service:IsServer()

local function freeze(t)
	for k, v in t do
		if type(v) == "table" then
			t[k] = freeze(v)
		end
	end
	return table.freeze(t)
end
return freeze(module) :: typeof(module)