local ref = require("../../Packages/Utils/ECS/Ref")
local jecs = require("../../Packages/jecs")
require("../../Packages/replecs")

local world = jecs.world()
ref.world(world)

return world