
local pretty  = require("pl.pretty")

local proj = {}

function proj:set_cohort(str)
  self.cohort = str
end
function proj:set_marks_csv(str)
  self.marks_csv = str
end
function proj:set_assign_name_colloq(str)
  self.assign_name_colloq = str
end
function proj:set_assign_name_canvas(str)
  self.assign_name_canvas = str
end
function proj:set_assign_grouped(bool)
  self.assign_grouped = bool
end
function proj:set_coordinators(tbl)
  self.coordinators = tbl
  if self.all_staff == nil then
    error("Load staff data before setting coordinators")
  end
  for _,j in pairs(tbl) do
    local name = j
    local id = ""
    if type(j) == "table" then
      name = j[1]
      id   = j[2]
    end
    if self.all_staff[name] == nil then
      self.all_staff[name] = self:find_user(name,id)
      self.all_staff[self.all_staff[name].id] = name
    end
  end
end

return proj
