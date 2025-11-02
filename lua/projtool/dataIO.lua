

local csv     = require("csv")
--local pretty  = require("pl.pretty")
local path    = require("pl.path")
local file    = require("pl.file")

local proj = {}


function proj:dl_check(opt,str)
  opt.download = opt.download or "ask"
  local check_bool = false
  if opt.download == "ask" then
    self:print(str .. " Type y to do so:")
    if io.read() == "y" then
      check_bool = true
    end
  elseif (opt.download == "always") or (opt.download == true) then
    self:print(str .. " User requested 'Always'.")
    check_bool = true
  elseif (opt.download == "never") or (opt.download == false) then
    self:print(str .. " User requested 'Never'.")
  else
    error("Interface: { download = 'ask' (default) | 'always' | 'never' } ")
  end
  return check_bool
end


function proj:check_csv_exists()

  self.marks_csv = self.marks_csv or string.lower("csv/"..self.cohort.."-marks-"..self.deliverable..".csv")
  return path.exists(self.marks_csv)

end


function proj:check_assessment_flags(verbose)

  verbose = verbose or false
  self.marks_csv = self.marks_csv or string.lower("csv/"..self.cohort.."-marks-"..self.deliverable..".csv")

  if verbose then
    self:print("### Checking assessment flags")
  end

  local resolve = {}

  if not(path.exists(self.marks_csv)) then
    self:print("Marks not found: "..self.marks_csv)
    return true
  end

  self:print("Loading marks resolutions and comments from: "..self.marks_csv)
  local f = csv.open(self.marks_csv,{header=true})

  local count_lines = 0
  for fields in f:lines() do
    count_lines = count_lines + 1
    local ind = 'USERID'
    if self.assign_grouped then
      ind = 'PROJID'
    end
    if fields[ind] then
      if self.assign_moderated then
        resolve[fields[ind]] = fields['RESOLVED']
      else
        resolve[fields[ind]] = fields['MARK'] ~= "" and "Y" or "N"
      end
    end
  end
  self:info("Lines: ",count_lines)

  local some_missing = false
  if (count_lines < 2) then
    self:print("Zero lines in marks file")
    some_missing = true
  end
  for _,v in pairs(resolve) do
    if v ~= "Y" then
      some_missing = true
      break
    end
  end

  return some_missing

end






function proj:export_csv_marks_moderated(subm,arg)

  self:print("## Export CSV marks (moderated): "..self.assign_name_canvas)

  if next(subm)==nil then
    self:print("Problem! Submission data to export is empty!")
    local _ = io.read()
    return
  end

  self.marks_csv = self.marks_csv or string.lower("csv/"..string.lower(self.cohort.."-marks-"..self.deliverable..".csv"))

  local weightings = arg.weightings or {0.5,0.5}

  self:print("* Writing marks to file: '"..self.marks_csv.."'...")
  file.copy(self.marks_csv,("backup-"..self.marks_csv))
  local ff = io.output(self.marks_csv)
  io.write("INDEX,USERID,NAME,SCHOOL,PROJID,TITLE,MARK,DIFF,RESOLVED,LATE_HRS,SIMILARITY,SUPERVISOR,SUPMARK,MODERATOR,MODMARK,SUPID,MODID,SUPURL,MODURL,UID1,ASSESSOR1,SCORE1,UID2,ASSESSOR2,SCORE2,UID3,ASSESSOR3,SCORE3,UID4,ASSESSOR4,SCORE4,UID5,ASSESSOR5,SCORE5,\n")

  local nameind = {}
  for i in pairs(subm) do
    nameind[#nameind+1] = i
  end
  table.sort(nameind,
    function(n1,n2)
      local res
      if (subm[n1].metadata.school == subm[n2].metadata.school) and (subm[n1].metadata.supervisor == subm[n2].metadata.supervisor) then
        res = (subm[n1].metadata.proj_id < subm[n2].metadata.proj_id)
      elseif (subm[n1].metadata.school == subm[n2].metadata.school) then
        res = (subm[n1].metadata.supervisor < subm[n2].metadata.supervisor)
      else
        res = (subm[n1].metadata.school < subm[n2].metadata.school)
      end
      return res
    end
  )

  self:print("* ...Entries sorted: "..#nameind.."...")
  for cc,n in ipairs(nameind) do
    local j = subm[n]
    j.metadata = j.metadata or {}

    local mark, diff
    if (type(j.metadata.supervisor_mark) == "number" and type(j.metadata.moderator_mark) == "number") and (j.metadata.supervisor_mark and j.metadata.moderator_mark) then
      mark = weightings[1]*j.metadata.supervisor_mark + weightings[2]*j.metadata.moderator_mark
      diff = j.metadata.supervisor_mark-j.metadata.moderator_mark
    end

    local similarity_score = ""
    if j.turnitin_data then
      for _,v in pairs(j.turnitin_data) do
        if v.similarity_score then
          similarity_score = v.similarity_score
        end
      end
    end

    local id_num = string.sub(j.user.login_id,2)
    local late_hrs = ""
    if j.seconds_late and j.seconds_late > 0 then
      late_hrs = string.format("%.3f", j.seconds_late / 60 / 60)
      if late_hrs == "0.000" then
        late_hrs = "0.0001"
      end
    end
    local writestr = cc..","..
      (id_num)..","..
      (j.user.name or "")..","..
      (j.metadata.school or "")..","..
      (j.metadata.proj_id or "")..","..
      "\"'"..(j.metadata.proj_title or "").."'\""..","..
      (mark or "")..","..
      (diff or "")..","..
      (j.metadata.resolve  or "")..","..
      (late_hrs)..","..
      (similarity_score)..","..
      "\""..(j.metadata.supervisor or "").."\""..","..
      (j.metadata.supervisor_mark or "")..","..
      "\""..(j.metadata.moderator or "").."\""..","..
      (j.metadata.moderator_mark or "")..","..
      (j.metadata.supervisor_id or "")..","..
      (j.metadata.moderator_id or "")..","..
      (j.metadata.supervisor_url or "")..","..
      (j.metadata.moderator_url or "")..","

    if j.metadata.super_marks then
      for kk,vv in pairs(j.metadata.super_marks) do
        writestr = writestr..'"'..kk..'","'..vv[1]..'","'..vv[2]..'",'
      end
    end
    if j.metadata.moder_marks then
      for kk,vv in pairs(j.metadata.moder_marks) do
        writestr = writestr..'"'..kk..'","'..vv[1]..'","'..vv[2]..'",'
      end
    end

    io.write(writestr.."\n")
  end
  io.close(ff)
  self:print("* ...done: "..self.marks_csv)

end



function proj:export_csv_marks(subm)

  self:print("## Export CSV marks (not moderated): "..self.assign_name_canvas)

  self.marks_csv = self.marks_csv or string.lower("csv/"..string.lower(self.cohort.."-marks-"..self.deliverable..".csv"))

  local nameind = {}
  for i in pairs(subm) do
    nameind[#nameind+1] = i
  end
  table.sort(nameind,function(n1,n2)
    local res
    if (subm[n1].metadata.school == subm[n2].metadata.school) and (subm[n1].metadata.supervisor == subm[n2].metadata.supervisor) then
      res = (subm[n1].metadata.proj_id < subm[n2].metadata.proj_id)
    elseif (subm[n1].metadata.school == subm[n2].metadata.school) then
      res = (subm[n1].metadata.supervisor < subm[n2].metadata.supervisor)
    else
      res = (subm[n1].metadata.school < subm[n2].metadata.school)
    end
    return res
  end)

  self:print("* Writing marks to file: '"..self.marks_csv.."'...")
  file.copy(self.marks_csv,("backup-"..self.marks_csv))
  local ff = io.output(self.marks_csv)
  io.write("INDEX,USERID,NAME,SCHOOL,PROJID,TITLE,SUPERVISOR,MARK,LATE_HRS,URL\n")

  for cc,n in ipairs(nameind) do
    local j = subm[n]

    local id_num = string.sub(j.user.login_id,2)
    local late_hrs = ""
    if j.seconds_late and j.seconds_late > 0 then
      late_hrs = string.format("%.3f", j.seconds_late / 60 / 60)
      if late_hrs == "0.000" then
        late_hrs = "0.0001"
      end
    end

    j.metadata = j.metadata or {}
    local writestr = cc..","..
      (id_num)..","..
      (j.user.name or "")..","..
      (j.metadata.school or "")..","..
      (j.metadata.proj_id or "")..","..
      "\"'"..(j.metadata.proj_title or "").."'\""..","..
      "\""..(j.metadata.supervisor or "").."\""..","..
      (j.grade or "")..","..
      (late_hrs)..","..
      (j.metadata.url or "")

    if j.grade ~= "-1" then
      io.write(writestr.."\n")
	end
  end

  io.close(ff)
  self:print("* ...done: "..self.marks_csv)

end





return proj
