
local csv     = require("csv")
local pretty  = require("pl.pretty")
local data    = require("pl.data")
local path    = require("pl.path")
local binser  = require("binser")
local canvas  = require("canvas-lms")

local proj = {}





function proj:read_csv_data(csvfile)

  print("Reading CSV data of students/projects/supervisors/moderators")

  self.proj_data = {}
  self.student_ind = {}
  self.all_staff = self.all_staff or {}
  self.all_staff_ids = {}

  local f = csv.open(csvfile)
  local cc = 0
  local nn = 0
  for fields in f:lines() do
    cc = cc+1
    if cc == 1 then
      local errorcount = {}
      local function checkcol(fields,col,str)
        if not(fields[col] == str) then
          errorcount[#errorcount+1] = " - Column "..col..": expected '"..str.."', found '"..fields[col].."'"
        end
      end
      checkcol(fields,1,"Name")
      checkcol(fields,2,"ID")
      checkcol(fields,3,"ProjID")
      checkcol(fields,4,"ProjTitle")
      checkcol(fields,5,"School")
      checkcol(fields,6,"Supervisor")
      checkcol(fields,7,"SupervisorID")
      checkcol(fields,8,"Moderator")
      checkcol(fields,9,"ModeratorID")
      if #errorcount > 0 then
        for _,j in ipairs(errorcount) do
          print(j)
        end
        error("CSV first line check failed")
      end
    elseif ( cc > 1 ) and not( fields[1] == "" ) then
      nn = nn+1
      self.proj_data[nn] = {}
      self.proj_data[nn].student_name  = fields[1] or ""
      self.proj_data[nn].student_id    = fields[2] or ""
      self.proj_data[nn].proj_id       = fields[3] or ""
      self.proj_data[nn].proj_title    = fields[4] or ""
      self.proj_data[nn].school        = fields[5] or ""
      self.proj_data[nn].supervisor    = fields[6] or ""
      self.proj_data[nn].supervisor_id = fields[7] or ""
      self.proj_data[nn].moderator     = fields[8] or ""
      self.proj_data[nn].moderator_id  = fields[9] or ""

      self.student_ind[self.proj_data[nn].student_id] = nn
      self.all_staff[self.proj_data[nn].supervisor] = {}
      self.all_staff[self.proj_data[nn].moderator]  = {}

      self.all_staff_ids[self.proj_data[nn].supervisor] = self.proj_data[nn].supervisor_id
      self.all_staff_ids[self.proj_data[nn].moderator]  = self.proj_data[nn].moderator_id
    end
  end

end


function proj:find_user(name,staff_uoa_id)

  local search_term = name

  if staff_uoa_id == "" then
    print("Searching for name:  '"..search_term.."'")
  else
    search_term = staff_uoa_id
    print("Searching for name:  '"..name.."' using ID: "..staff_uoa_id)
  end
  local tmp = canvas:find_user(search_term)
  local match_ind = 0
  for i,j in ipairs(tmp) do
    print("Found:  '"..j.name.."' ("..j.login_id..")")
  end
  if #tmp == 1 then
    match_ind = 1
  elseif #tmp > 1 then
    local count_exact = 0
    for i,j in ipairs(tmp) do
      if j.name == k then
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
    print("No user found for name: "..k)
  end

end


function proj:get_canvas_ids(opt)

  print("Searching for supervisors/moderators in Canvas")

  local cache_path = canvas.cache_dir.."AllStaff.lua"

  local download_check = true
  if path.exists(cache_path) then
    local opt = opt or {download="ask"}
    download_check = self:dl_check(opt,"Look up all supervisor/moderator Canvas IDs?")
  else
    print "Staff Canvas IDs not found, downloading."
    download_check = true
  end

  local id_lookup = {}

  if download_check then
    local not_found_canvas = ""
    for k,v in pairs(self.all_staff) do
      if not(k == "") then
        local tbl = self:find_user(k,self.all_staff_ids[k])
        if tbl == nil then
          not_found_canvas = not_found_canvas.."    "..search_term.."\n"
        else
          self.all_staff[k] = tbl
          id_lookup[tbl.id] = k
        end
      end
    end
    for kk,vv in pairs(id_lookup) do
      self.all_staff[kk] = vv
    end
    if not_found_canvas ~= "" then
      error("## Canvas users not found, check their names and/or add them via Toolkit:\n\n"..not_found_canvas)
    end
    binser.writeFile(cache_path,self.all_staff)
  end

  local all_staff_from_file = binser.readFile(cache_path)
  self.all_staff = all_staff_from_file[1]

end


return proj
