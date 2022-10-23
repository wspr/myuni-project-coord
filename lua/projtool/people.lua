
local csv     = require("csv")
local pretty  = require("pl.pretty")
local path    = require("pl.path")
local canvas  = require("canvas-lms")

local proj = {}



function proj:staff_lookup(acad_id)

  local acad_lookup = self.staff[acad_id]
  if acad_lookup == nil then
    pretty.dump(self.staff)
    error("Staff member not found by ID: "..acad_id)
  end
  local acad_name = acad_lookup.name
  if acad_name == nil then
    pretty.dump(acad_lookup)
    error("Staff member missing name: "..acad_id)
  end
  if acad_lookup.email == nil then
    acad_lookup.email = acad_lookup.login_id.."@adelaide.edu.au"
  end
  return acad_lookup, acad_name

end

function proj:staff_lookup_cid(acad_cid)

  acad_uid = self.all_staff_id_by_cid[acad_cid]
  if acad_uid == nil then
    pretty.dump(self.staff)
    pretty.dump(self.all_staff_id_by_cid)
    error("Assessor with Canvas ID "..acad_cid.." not found in staff list.")
  end

  acad_lookup, acad_name = self:staff_lookup(acad_uid)
  return acad_lookup, acad_name

end


function proj:read_csv_data(csvfile)

  csvfile = csvfile or ("csv/"..self.cohort.."-student-list.csv")

  self:get_staff()

  print("Reading CSV data of students/projects/supervisors/moderators: "..csvfile)

  self.projects = {}
  self.proj_data = {}
  self.student_ind = {}
  self.all_staff = {}
  self.all_staff_id_by_name = {}
  self.all_staff_id_by_cid = {}

  local f = csv.open(csvfile,{header=true})
  if f == nil then
    error("CSV file '"..csvfile.."' not found.")
  end

  local nn = 0
  for fields in f:lines() do
      nn = nn+1
      self.proj_data[nn] = {}
      self.proj_data[nn].student_name  = fields["Name"] or ""
      self.proj_data[nn].student_id    = fields["ID"] or ""
      self.proj_data[nn].proj_id       = fields["ProjID"] or ""
      self.proj_data[nn].proj_title    = fields["ProjTitle"] or ""
      self.proj_data[nn].school        = fields["School"] or ""
      self.proj_data[nn].supervisor    = fields["Supervisor"] or ""
      self.proj_data[nn].supervisor_id = fields["SupervisorID"] or ""
      self.proj_data[nn].myuni_proj_id = fields["MyUniProjID"] or ""
      if self.proj_data[nn].myuni_proj_id == "" then
        self.proj_data[nn].myuni_proj_id = self.proj_data[nn].proj_id
      end

      local jj = self.proj_data[nn]
      self.projects[jj.proj_id] = self.projects[jj.proj_id] or {}
      self.projects[jj.proj_id].proj_title    = self.projects[jj.proj_id].proj_title    or jj.proj_title
      self.projects[jj.proj_id].proj_id       = self.projects[jj.proj_id].proj_id       or jj.myuni_proj_id
      self.projects[jj.proj_id].school        = self.projects[jj.proj_id].school        or jj.school
      self.projects[jj.proj_id].supervisor    = self.projects[jj.proj_id].supervisor    or jj.supervisor
      self.projects[jj.proj_id].supervisor_id = self.projects[jj.proj_id].supervisor_id or jj.supervisor_id
      self.projects[jj.proj_id].student_ids   = self.projects[jj.proj_id].student_ids   or {}
      self.projects[jj.proj_id].student_names = self.projects[jj.proj_id].student_names or {}
      self.projects[jj.proj_id].student_ids[#self.projects[jj.proj_id].student_ids+1]     = self.proj_data[nn].student_id
      self.projects[jj.proj_id].student_names[#self.projects[jj.proj_id].student_names+1] = self.proj_data[nn].student_name

      local student_id = self.proj_data[nn].student_id
      local super      = self.proj_data[nn].supervisor_id
      local super_name = self.proj_data[nn].supervisor

      self.student_ind[student_id] = nn

      self.all_staff[super] = {}
      self.all_staff_id_by_name[super_name] = super
      self.assessors = self.assessors or {}
      self.assessors[super] = self.assessors[super] or {}
      self.assessors[super][csvfile] = self.assessors[super][csvfile] or {}
      self.assessors[super][csvfile].supervisor = self.assessors[super][csvfile].supervisor or {}
      self.assessors[super][csvfile].supervisor[student_id] = nn

      if self.assign_canvas_moderated then
        self.proj_data[nn].moderator     = fields["Moderator"] or ""
        self.proj_data[nn].moderator_id  = fields["ModeratorID"] or ""
        local moder      = self.proj_data[nn].moderator_id
        local moder_name = self.proj_data[nn].moderator
        self.all_staff[moder]  = {}
        self.all_staff_id_by_name[moder_name] = moder
        self.assessors[moder] = self.assessors[moder] or {}
        self.assessors[moder][csvfile] = self.assessors[moder][csvfile] or {}
        self.assessors[moder][csvfile].moderator  = self.assessors[moder][csvfile].moderator  or {}
        self.assessors[moder][csvfile].moderator[student_id]  = nn
      end
  end



  for uid,v in pairs(self.staff) do
    self.all_staff_id_by_cid[v.id] = uid
    self.all_staff_id_by_name[v.sortable_name] = uid
  end

  local not_found_canvas = ""
  for id,dat in pairs(self.all_staff) do
    if not(id == "") then
      local tbl = self.staff[id]
      if tbl == nil then
        print("No user found for user: "..id)
        not_found_canvas = not_found_canvas .. "    " .. id .. "\n"
      else
        print("User found: '"..tbl.name.."' ("..tbl.login_id..")")
        self.all_staff[id] = tbl
      end
    end
  end
  if not_found_canvas ~= "" then
    error("\n\n## Canvas users not found, check their names and/or add them via Toolkit:\n\n" .. not_found_canvas)
  end

end


return proj
