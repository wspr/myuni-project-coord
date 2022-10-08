
local proj = {}

local function copy_functions(name)
  local new = require(name)
  for k,v in pairs(new) do
    proj[k] = v
  end
end

copy_functions("projtool.setters")
copy_functions("projtool.people")
copy_functions("projtool.messages")
copy_functions("projtool.check")
copy_functions("projtool.resolve")
copy_functions("projtool.reminders")
copy_functions("projtool.dataIO")
copy_functions("projtool.misc")
copy_functions("projtool.marksprint")


return proj
