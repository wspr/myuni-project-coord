
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
  self.coordinators = tbl
end

--[[ OO --]]

function proj:new(newcourse)
  setmetatable(self,{__index=newcourse}) -- PROJ inherits from COURSE INSTANCE
  return setmetatable({},{__index = self}) -- PROJ INSTANCE inherits from PROJ
end


return proj
