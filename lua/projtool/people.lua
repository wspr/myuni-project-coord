
local csv     = require("csv")
local pretty  = require("pl.pretty")
local path    = require("pl.path")
local binser  = require("binser")
local canvas  = require("canvas-lms")

local proj = {}



function proj:staff_lookup(acad_id)

  local acad_name = self.all_staff[acad_id]
  if acad_name == nil then
    pretty.dump(self.all_staff)
    error("Staff member not found by ID: "..acad_id)
  end
  local staff_lookup = self.all_staff[acad_name]
  if staff_lookup.login_id == nil then
    pretty.dump(staff_lookup)
    error("Staff member not found: "..acad_name)
  end
  if staff_lookup.email == nil then
    staff_lookup.email = staff_lookup.login_id.."@adelaide.edu.au"
  end
  return staff_lookup, acad_name

end


function proj:read_csv_data(csvfile)

  print("Reading CSV data of students/projects/supervisors/moderators: "..csvfile)

  self.projects = {}
  self.proj_data = {}
  self.student_ind = {}
  self.all_staff = {}
  self.all_staff_ids = {}

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
      local super = self.proj_data[nn].supervisor

      self.student_ind[student_id] = nn

      self.all_staff[super] = {}
      self.all_staff_ids[super] = self.proj_data[nn].supervisor_id
      self.assessors = self.assessors or {}
      self.assessors[super] = self.assessors[super] or {}
      self.assessors[super][csvfile] = self.assessors[super][csvfile] or {}
      self.assessors[super][csvfile].supervisor = self.assessors[super][csvfile].supervisor or {}
      self.assessors[super][csvfile].supervisor[student_id] = nn

      if self.assign_canvas_moderated then
        self.proj_data[nn].moderator     = fields["Moderator"] or ""
        self.proj_data[nn].moderator_id  = fields["ModeratorID"] or ""
        local moder = self.proj_data[nn].moderator
        self.all_staff[moder]  = {}
        self.all_staff_ids[moder] = self.proj_data[nn].moderator_id
        self.assessors[moder] = self.assessors[moder] or {}
        self.assessors[moder][csvfile] = self.assessors[moder][csvfile] or {}
        self.assessors[moder][csvfile].moderator  = self.assessors[moder][csvfile].moderator  or {}
        self.assessors[moder][csvfile].moderator[student_id]  = nn
      end
  end
end


function proj:find_user(name,staff_uoa_id)

  local search_term = name

  staff_uoa_id = staff_uoa_id or ""
  if staff_uoa_id == "" then
    print("Searching for name:  '"..search_term.."'")
  else
    search_term = staff_uoa_id
    print("Searching for name:  '"..name.."' using ID: "..staff_uoa_id)
  end
  local tmp = canvas:find_user(search_term)
  local match_ind = 0
  for _,j in ipairs(tmp) do
    print("Found:  '"..j.name.."' ("..j.login_id..")")
  end
  if #tmp == 1 then
    match_ind = 1
  elseif #tmp > 1 then
    local count_exact = 0
    for i,j in ipairs(tmp) do
      if j.name == name then
        count_exact = count_exact + 1
        match_ind = i
      end
    end
    if count_exact > 1 then
      error("Multiple exact matches for name found. This is a problem! New code needed to identify staff members by their ID number as well.")
    end
  end

  if match_ind > 0 then
    return tmp[match_ind]
  else
    print("No user found for name: "..name)
  end

end


function proj:get_canvas_ids(opt)

  opt = opt or {download="ask"}

  local cache_path = canvas.cache_dir..canvas.courseid.."-staff.lua"
  print("Searching for supervisors/moderators in Canvas: "..cache_path)

  local download_check
  if path.exists(cache_path) then
    download_check = self:dl_check(opt,"Look up all supervisor/moderator Canvas IDs?")
  else
    print "Staff Canvas IDs not found, downloading."
    download_check = true
  end

  local id_lookup = {}

  if download_check then
    local not_found_canvas = ""
    for name in pairs(self.all_staff) do
      if not(name == "") then
        local tbl = self:find_user(name,self.all_staff_ids[name])
        if tbl == nil then
          not_found_canvas = not_found_canvas.."    "..name.."   "..self.all_staff_ids[name].."\n"
        else
          self.all_staff[name] = tbl
          id_lookup[tbl.id] = name
        end
      end
    end
    for kk,vv in pairs(id_lookup) do
      self.all_staff[kk] = vv
    end
    if not_found_canvas ~= "" then
      error("\n\n## Canvas users not found, check their names and/or add them via Toolkit:\n\n"..not_found_canvas)
    end
    binser.writeFile(cache_path,self.all_staff)
  end

  local all_staff_from_file = binser.readFile(cache_path)
  self.all_staff = all_staff_from_file[1]

end


return proj
