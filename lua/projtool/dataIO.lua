

local csv     = require("csv")
local pretty  = require("pl.pretty")
local path    = require("pl.path")
local canvas  = require("canvas-lms")


local proj = {}



function proj:add_assessment_metadata(canvas_subm)

  if self.assign_individual_submission==nil then
    self.assign_individual_submission = true
  end

  local resolve = {}
  local override = {}
  local comments = {}
  if path.exists(self.marks_csv) then
    print("Loading marks resolutions and comments from: "..self.marks_csv)
    local f = csv.open(self.marks_csv)
    -- TODO: use {header=true}
    for fields in f:lines() do
      local ind
      if self.assign_individual_submission then
        ind = 2
      else
        ind = 5
      end
      resolve[fields[ind]]  = fields[9]
      override[fields[ind]] = fields[10]
      comments[fields[ind]] = fields[11]
    end
  end

  local subm = {}
  for i,subm_entry in ipairs(canvas_subm) do
    print(i..": Processing submission by: "..subm_entry.user.name)

    local student_id = subm_entry.user.sis_user_id
    local ind = self.student_ind[student_id]

    if ind then

      local hash_index
      local group_id = self.proj_data[ind].proj_id
      if self.assign_individual_submission then
        hash_index = student_id
      else
        hash_index = group_id
      end

      subm[hash_index] = subm_entry

      local url = canvas.url .. canvas.course_prefix ..
                  "gradebook/speed_grader?assignment_id=" .. subm_entry.assignment_id ..
                  "&student_id=" .. subm_entry.user_id
      subm[hash_index].metadata = {}
      subm[hash_index].metadata.proj_id     = self.proj_data[ind].proj_id
      subm[hash_index].metadata.proj_title  = self.proj_data[ind].proj_title
      subm[hash_index].metadata.supervisor  = self.proj_data[ind].supervisor
      subm[hash_index].metadata.moderator   = self.proj_data[ind].moderator
      subm[hash_index].metadata.school      = self.proj_data[ind].school
      subm[hash_index].metadata.url         = url
      subm[hash_index].metadata.resolve     = resolve[hash_index]  or ""
      subm[hash_index].metadata.override    = override[hash_index] or ""
      subm[hash_index].metadata.comments    = comments[hash_index] or ""
    else
      print("No metadata found for this student/group: "..student_id)
    end

  end

  return subm
end






--[[
local ok, msg = pcall(function ()
--some code
if unexpected_condition then error() end
--some code
print(a[i])    -- potential error: 'a' may not be a table
--some code
end)
if ok then    -- no errors while running protected code
--regular code
else   -- protected code raised an error: take appropriate action
--error-handling code
end
--]]

function proj:export_csv_marks_moderated(subm,arg)

  local weightings = arg.weightings or {0.5,0.5}

  local ff = io.output(self.marks_csv)
  io.write("INDEX,USERID,NAME,SCHOOL,PROJID,TITLE,MARK,DIFF,RESOLVED,OVERRIDE,COMMENTS,SUPERVISOR,SUPMARK,MODERATOR,MODMARK,SUPURL,MODURL,ASSESSOR1,SCORE1,ASSESSOR2,SCORE2,ASSESSOR3,SCORE3,ASSESSOR4,SCORE4,ASSESSOR5,SCORE5,\n")

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

  for cc,n in ipairs(nameind) do
    local j = subm[n]
    j.metadata = j.metadata or {}

    local mark, diff
    if j.metadata.supervisor_mark and j.metadata.moderator_mark then
      mark = weightings[1]*j.metadata.supervisor_mark + weightings[2]*j.metadata.moderator_mark
      diff = j.metadata.supervisor_mark-j.metadata.moderator_mark
    end

    local writestr = cc..","..
      (j.user.sis_user_id or "")..","..
      (j.user.name or "")..","..
      (j.metadata.school or "")..","..
      (j.metadata.proj_id or "")..","..
      "\"'"..(j.metadata.proj_title or "").."'\""..","..
      (mark or "")..","..
      (diff or "")..","..
      (j.metadata.resolve  or "")..","..
      (j.metadata.override or "")..","..
      (j.metadata.comments or "")..","..
      (j.metadata.supervisor or "")..","..
      (j.metadata.supervisor_mark or "")..","..
      (j.metadata.moderator or "")..","..
      (j.metadata.moderator_mark or "")..","..
      (j.metadata.supervisor_url or "")..","..
      (j.metadata.moderator_url or "")..","

    for kk,vv in pairs(j.metadata.super_marks) do
      writestr = writestr..kk..","..vv..","
    end
    for kk,vv in pairs(j.metadata.moder_marks) do
      writestr = writestr..kk..","..vv..","
    end

    io.write(writestr.."\n")
  end
  io.close(ff)

end



function proj:export_csv_marks(subm)

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

  print("Writing marks to file: '"..self.marks_csv"'...")
  local ff = io.output(self.marks_csv)
  io.write("INDEX,USERID,NAME,SCHOOL,PROJID,TITLE,SUPERVISOR,MARK,URL\n")

  for cc,n in ipairs(nameind) do
    local j = subm[n]
    j.metadata = j.metadata or {}
    local writestr = cc..","..
      (j.user.sis_user_id or "")..","..
      (j.user.name or "")..","..
      (j.metadata.school or "")..","..
      (j.metadata.proj_id or "")..","..
      "\"'"..(j.metadata.proj_title or "").."'\""..","..
      (j.metadata.supervisor or "")..","..
      (j.grade or "")..","..
      (j.metadata.url or "")

    io.write(writestr.."\n")
  end

  io.close(ff)
  print("...done.")

end





return proj
