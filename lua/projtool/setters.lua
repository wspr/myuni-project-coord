
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
function proj:set_assign_grouped(str)
  self.assign_grouped = str
end

return proj
