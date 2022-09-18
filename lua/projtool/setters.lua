
local pretty  = require("pl.pretty")
local path    = require("pl.path")
local binser  = require("binser")
local canvas  = require("canvas-lms")

local proj = {}

function proj:set_deliverable(str)
  self.deliverable = str
end
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
function proj:set_assign_canvas_moderated(bool)
  self.assign_canvas_moderated = bool
end
function proj:set_coordinators(tbl)

  local cache_path = canvas.cache_dir.."Staff Details - Coordinators.lua"
  local coords = {}

  self.coordinators = tbl
  if self.all_staff == nil then
    error("Load staff data before setting coordinators")
  end

  if path.exists(cache_path) then
    coords = binser.readFile(cache_path)
    coords = coords[1]
  end
  for k,j in pairs(tbl) do
    local name = j
    local id = ""
    if type(j) == "table" then
      name     = j[1]
      id       = j[2]
    end
    coords[name] = coords[name] or self.all_staff[name] or self:find_user(name,id)
  end
  binser.writeFile(cache_path,coords)

  for _,v in pairs(coords) do
    self.all_staff[v.sortable_name] = v
    self.all_staff[v.login_id] = v.sortable_name
  end
end

return proj
