
local pretty  = require("pl.pretty")
local path    = require("pl.path")
local binser  = require("binser")
local canvas  = require("canvas-lms")

local proj = {}

function proj:set_canvas(c)
  self.canvas = c
end
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
function proj:set_assign_has_submission(bool)
  self.assign_has_submission = bool
end
proj:set_assign_has_submission(true)

function proj:set_coordinators(tbl)

  local cache_path = self.cache_dir.."Staff Details - Coordinators.lua"
  local coords = {}

  self.coordinators = tbl
  self.all_staff = self.all_staff or {}
  self.all_staff_id_by_name = self.all_staff_id_by_name or {}

  if path.exists(cache_path) then
    coords = binser.readFile(cache_path)
    coords = coords[1]
  end
  for k,j in pairs(tbl) do
    name = j[1]
    id   = j[2]
    coords[id] = coords[id] or self.all_staff[id] or self:find_staff(id)
  end
  binser.writeFile(cache_path,coords)

  for id,v in pairs(coords) do
    self.all_staff[id] = v
    self.all_staff_id_by_name[v.sortable_name] = id
  end
end

--[[ OO --]]

function proj:new(o)
  o = o or {}
  self.__index = self
  setmetatable(o,self)
  return o
end


return proj
