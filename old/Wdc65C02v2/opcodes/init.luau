local opcodes = {}

local function merge(t: { any })
	for k, v in t do
		opcodes[k] = v
	end
end

merge(require("@self/arithmetic"))
merge(require("@self/control"))
merge(require("@self/flags"))
merge(require("@self/increment"))
merge(require("@self/load"))
merge(require("@self/logic"))
merge(require("@self/other"))
merge(require("@self/shift"))
merge(require("@self/stack"))
merge(require("@self/transfer"))

return opcodes
