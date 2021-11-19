

local csv     = require("csv")
local pretty  = require("pl.pretty")
local path    = require("pl.path")
local canvas  = require("canvas-lms")


local proj = {}





function proj:dl_check(opt,str)

  local check_bool = false
  if opt.download == "ask" then
    print(str .. " Type y to do so:")
    if io.read() == "y" then
      check_bool = true
    end
  elseif opt.download == "always" then
    print(str .. " User requested 'Always'.")
    check_bool = true
  elseif opt.download == "never" then
    print(str .. " User requested 'Never'.")
  else
    error("Interface: { download = 'ask' (default) | 'always' | 'never' } ")
  end
  return check_bool
end





function proj:get_submissions(get_bool,cvs)

  local subm
  if self.assign_grouped then
    subm = canvas:get_assignment(get_bool,self.assign_name_canvas,{grouped=true,include={"group","user","rubric_assessment","submission_comments"}})
  else
    subm = canvas:get_assignment(get_bool,self.assign_name_canvas,{include={"provisional_grades","user","rubric_assessment","submission_comments"}})
  end
  subm = self:subm_remove(subm)

  if csv then
    self.assignment_setup = cvs.assignments[self.assign_name_canvas]
  end

  return subm

end



function proj:subm_remove(subm)
  local subout = {}
  local to_keep = true
  for i,j in ipairs(subm) do
    if string.sub(j.user.sis_user_id,1,2) == "sv" then
      print(" - Academic student view (SV) user: "..subm[i].user.name)
      to_keep = false
    end
    if j.user.sis_user_id == nil then -- maybe check against a black list, or similar
      print(" - Student has no login id: "..subm[i].user.name)
      to_keep = false
    end
    if j.excused then
      print(" - Student excused: "..subm[i].user.name)
      to_keep = false
    end
    if to_keep then
      subout[#subout+1] = j
    end
  end
  return subout
end



function proj:add_assessment_metadata(canvas_subm)

  local resolve = {}
  local override = {}
  local comments = {}
  if path.exists(self.marks_csv) then
    local f = csv.open(self.marks_csv)
    -- TODO: use {header=true}
    for fields in f:lines() do
      resolve[fields[2]]  = fields[9]
      override[fields[2]] = fields[10]
      comments[fields[2]] = fields[11]
    end
  end

  local subm = {}
  for i,subm_entry in ipairs(canvas_subm) do
    print(i..": Processing submission by: "..subm_entry.user.name)

    local student_id = subm_entry.user.sis_user_id
    local ind = self.student_ind[student_id]

    subm[student_id] = subm_entry
    if ind then
      local url = canvas.url .. canvas.course_prefix ..
                  "gradebook/speed_grader?assignment_id=" .. subm_entry.assignment_id ..
                  "&student_id=" .. subm_entry.user_id
      subm[student_id].metadata = {}
      subm[student_id].metadata.proj_id     = self.proj_data[ind].proj_id
      subm[student_id].metadata.proj_title  = self.proj_data[ind].proj_title
      subm[student_id].metadata.supervisor  = self.proj_data[ind].supervisor
      subm[student_id].metadata.moderator   = self.proj_data[ind].moderator
      subm[student_id].metadata.school      = self.proj_data[ind].school
      subm[student_id].metadata.url         = url
      subm[student_id].metadata.resolve     = resolve[student_id]  or ""
      subm[student_id].metadata.override    = override[student_id] or ""
      subm[student_id].metadata.comments    = comments[student_id] or ""
    else
      print("No metadata found for this student/group.")
    end

  end

  return subm
end




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

end









return proj
