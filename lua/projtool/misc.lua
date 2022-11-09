

local csv     = require("csv")
local canvas  = require("canvas-lms")
local pretty  = require("pl.pretty")
local path    = require("pl.path")
local file    = require("pl.file")



local proj = {}



function proj:info(s)

  if self.verbose > 0 then
    print("INFO:  "..s)
  end

end



function proj:list_students(semnow,cohorts)


  local sonia_path = "../"
  local sonia_csv = sonia_path .. "csv/erp-projects-export.csv"
  local moderators_csv = sonia_path .. "csv/erp-"..semnow.."-moderators.csv"

  local function checkpath(s,p)
    if not(path.exists(p)) then
      error("Path to "..s.." not found: \n\n    ".. p .."\n")
    end
  end
  checkpath("SONIA OneDrive folder",sonia_path)
  checkpath("SONIA CSV file",sonia_csv)
  checkpath("moderators CSV file",moderators_csv)

  local f = csv.open(sonia_csv,{header=true})
  local lookup_groups = {}
  for fields in f:lines() do
    if not(fields.Cohort==nil) then
      lookup_groups[fields["MyUni Project ID"]] = fields
    end
  end

  local f = csv.open(moderators_csv,{header=true})
  local lookup_mods = {}
  for fields in f:lines() do
    if not(fields["MyUni Project ID"]==nil) then
      lookup_mods[fields["MyUni Project ID"]] = fields
    end
  end


  print("Download all groups and users from MyUni (a bit slow)? 'y' to do so, anything else to use cache.")
  dl_bool = io.read()

  for _,UGPG in ipairs{"UG","PG"} do
    for _,cohort in ipairs(cohorts) do

      print("============")
      print(cohort, UGPG)
      print("============")

      self:set_cohort(cohort)
      self:set_course_id(canvas_id[cohort][UGPG])

      myuni_groups = self:get_groups_by_cat(dl_bool == "y","Project Groups")
      for grp,v in pairs(myuni_groups) do
        if grp:sub(-5,-1) == "00000" then
          myuni_groups[grp] = nil
        end
      end

      local f = csv.open(sonia_csv,{header=true})
      local sonia_groups  = {}
      for fields in f:lines() do
        if not(fields.Cohort==nil) then
          if (fields.Cohort == self.cohort) and (fields.UGPG == UGPG) then
            sonia_groups[#sonia_groups+1] = fields
          end
        end
      end

      print("Consistency check of data\n___________________________\n")

      local count = 0
      local sonia_names = {}
      for k,v in pairs(sonia_groups) do
        count = count + 1
        local grp = v["MyUni Project ID"]
        if myuni_groups[grp] == nil then
          print("• CSV group not found in MyUni: "..grp)
        else
          if not( tonumber( v["N students"] ) == myuni_groups[grp].Nstudents ) then
          print("• "..grp.." : check group size : MyUni = "..myuni_groups[grp].Nstudents.." | CSV = "..v["N students"] )
          end
        end
        sonia_names[grp] = v
      end


      local count2 = 0
      for grp,v in pairs(myuni_groups) do
        count2 = count2 + 1
        if (sonia_names[grp] == nil) then
          print("• MyUni group not found in CSV: "..grp.." ("..myuni_groups[grp].Nstudents.." students)")
        end
      end

      print("# Total number of  CSV  groups: "..count)
      print("# Total number of MyUni groups: "..count2)
      if count == count2 then
        print("Good!")
      end

      print("Constructing student list:")

      csvfile = "csv/"..UGPG.."-"..cohort.."-student-list.csv"

      file.copy(csvfile,("backup-"..csvfile))
      local ff = io.output(csvfile)

      local function qq(str) return '"'..str..'"' end
      local function csvrow(tbl)
        local str = ""
        local sep = ","
        local count = 0
        for _,v in ipairs(tbl) do
          count = count + 1
          if count > 1 then
            str = str..sep
          end
          str = str..v
        end
        return str.."\n"
      end

      io.write(csvrow{"Name","ID","ProjID","ProjTitle","School","Supervisor","SupervisorID","Moderator","ModeratorID"})
      for k,v in pairs(myuni_groups) do
        for _,u in ipairs(v.users) do
          lookup_mods[k] = lookup_mods[k] or {}
          io.write(csvrow{
            qq(u.sortable_name),
            u.sis_user_id,
            k,
            qq(lookup_groups[k]["Project title"]),
            lookup_groups[k]["Project School"],
            qq(lookup_groups[k]["Project supervisor"]),
            lookup_groups[k]["Supervisor ID"],
            qq(lookup_mods[k]["Moderator"] or ""),
            lookup_mods[k]["Moderator ID"] or ""
          })
        end
      end

      io.close(ff)
      print("...done.")

    end
  end



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
