local jecs = require("@Packages/jecs")
require("@Packages/replecs") -- preregister replecs components before creating the world.

return jecs.world() :: jecs.World
