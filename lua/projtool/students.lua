

local csv     = require("csv")
local canvas  = require("canvas-lms")
local pretty  = require("pl.pretty")
local path    = require("pl.path")
local file    = require("pl.file")



local proj = {}






function proj:list_students(dl_bool,semnow,cohort,UGPG)


  local csv_path       = "../csv/"
  local local_csv_path = "./csv/"
  local sonia_csv      = csv_path .. "erp-projects-export.csv"
  local moderators_csv = csv_path .. "erp-moderators-export.csv"
  local group_name     = self.group_name or "Project Groups"

  local function checkpath(s,p)
    if not(path.exists(p)) then
      error("Path to "..s.." not found: \n\n    ".. p .."\n")
    end
  end
  checkpath("OneDrive folder",csv_path)
  checkpath("CSV file",sonia_csv)
  checkpath("Moderators file",moderators_csv)

  local f = csv.open(sonia_csv,{header=true})
  local lookup_groups = {}
  for fields in f:lines() do
    if not(fields.Cohort==nil) and (fields.Active=="True") then
      lookup_groups[fields["MyUni Project ID"]] = fields
    end
  end

  local lookup_mods = {}
  local f = csv.open(moderators_csv,{header=true})
  if f then
    for fields in f:lines() do
      if not(fields["MyUni Project ID"]==nil) then
        lookup_mods[fields["MyUni Project ID"]] = fields
      end
    end
  end

  myuni_groups = self:get_groups_by_cat(dl_bool,group_name)
  for grp,v in pairs(myuni_groups) do
    if grp:sub(-5,-1) == "00000" then
      myuni_groups[grp] = nil
    end
  end

  local f = csv.open(sonia_csv,{header=true})
  local sonia_groups  = {}
  for fields in f:lines() do
    if not(fields.Cohort==nil) then
      if (fields.Cohort == self.cohort) and (fields.UGPG == UGPG) and (fields.Active=="True") then
        sonia_groups[#sonia_groups+1] = fields
      end
    end
  end

  print("# Consistency check of data\n")
  consistency_error = false

  local count = 0
  local sonia_names = {}
  for k,v in pairs(sonia_groups) do
    count = count + 1
    local grp = v["MyUni Project ID"]
    if myuni_groups[grp] == nil then
      print("• CSV group not found in MyUni: "..grp)
      consistency_error = true
    else
      if not( tonumber( v["N students"] ) == myuni_groups[grp].Nstudents ) then
        print("• "..grp.." : check group size : MyUni = "..myuni_groups[grp].Nstudents.." | CSV = "..v["N students"] )
        consistency_error = true
      end
    end
    sonia_names[grp] = v
  end


  local count2 = 0
  for grp,v in pairs(myuni_groups) do
    count2 = count2 + 1
    if (sonia_names[grp] == nil) then
      print("• MyUni group not found in CSV: "..grp.." ("..myuni_groups[grp].Nstudents.." students)")
      consistency_error = true
    end
  end

  print("• Total number of  CSV  groups: "..count)
  print("• Total number of MyUni groups: "..count2)
  if count == count2 then
    print("Good!")
  else
    print("Mismatch -- check!")
    consistency_error = true
  end


  local student_list_filename = UGPG.."-"..cohort.."-student-list.csv"
  local student_list_filepath = local_csv_path .. student_list_filename

  print("Constructing student list: "..student_list_filepath)

  file.copy(student_list_filepath,("backup-"..student_list_filepath))
  local ff = io.output(student_list_filepath)

  local function qq(str) return '"'..str..'"' end
  local function csvrow(tbl)
    local str = table.concat(tbl,",").."\n"
    return str
  end

  io.write(csvrow{"Name","ID","ProjID","ShortID","ProjTitle","School","Supervisor","SupervisorID","Assessor","AssessorID","Moderator","ModeratorID"})
  for k,v in pairs(myuni_groups) do
    for _,u in ipairs(v.users) do
      local id = u.sis_user_id or string.sub(u.login_id,2,-1) or ""
      lookup_mods[k] = lookup_mods[k] or {}
      local this_group = lookup_groups[k]
      if this_group then
        io.write(csvrow{
          qq(u.sortable_name),
          id,
          k,
          this_group["Short Project ID"],
          qq(this_group["Project title"]),
          this_group["Project School"],
          qq(this_group["Project supervisor"]),
          this_group["Supervisor ID"],
          qq(lookup_mods[k]["AssessorName"] or ""),
          lookup_mods[k]["AssessorID"] or "",
          qq(lookup_mods[k]["Moderator"] or ""),
          lookup_mods[k]["Mod ID"] or "",
        })
      end
    end
  end

  io.close(ff)
  print("...done.")

  return consistency_error

end


    -- CSV field format:
    --[[
     {
       ["@odata.etag"] = "",
       ["Co ID 1"] = "a1785555",
       ["Co ID 2"] = "",
       ["Co ID 3"] = "",
       ["Co-supervisor 1"] = "Juri, Afifah",
       ["Co-supervisor 2"] = "",
       ["Co-supervisor 3"] = "",
       Cohort = "2022s2",
       ItemInternalId = "e0d0a898-e4c0-4bc8-984f-cfa5f8da7457",
       ["MyUni Project ID"] = "2022s2-ME-Yin-UG-64282",
       ["N students"] = "1",
       ["Project School"] = "ME",
       ["Project supervisor"] = "Yin, Ling",
       ["Project title"] = "Development of new manufacturing and characterization techniques for dental materials",
       ["Short Project ID"] = "64282",
       ["Supervisor ID"] = "a1728037",
       ["Supervisor email"] = "a1728037@adelaide.edu.au",
       UGPG = "UG"
     }
    --]]


return proj
