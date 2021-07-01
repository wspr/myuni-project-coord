

local csv     = require("csv")
local pretty  = require("pl.pretty")
local data    = require("pl.data")
local path    = require("pl.path")
local binser  = require("binser")
local canvas  = require("canvas-lms")


local proj = {}





function proj:dl_check(opt,str)

  local check_bool = false
  if opt.download == "ask" then
    print(str .. " Type y to do so:")
    check_str = io.read()
    if check_str == "y" then
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





function proj:get_submissions(get_bool)

  local subm
  if self.assign_grouped then
    subm = canvas:get_assignment(get_bool,self.assign_name_canvas,{grouped=true,include={"group","user","rubric_assessment"}})
  else
    subm = canvas:get_assignment(get_bool,self.assign_name_canvas,{include={"provisional_grades","user","rubric_assessment"}})
  end
  subm = self:subm_remove(subm)

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
    for fields in f:lines() do
      resolve[fields[2]]  = fields[9]
      override[fields[2]] = fields[10]
      comments[fields[2]] = fields[11]
    end
  end

  subm = {}
  for i,subm_entry in ipairs(canvas_subm) do
    print(i..": Processing submission by: "..subm_entry.user.name)

    local student_id = subm_entry.user.sis_user_id
    local ind = self.student_ind[student_id]

    subm[student_id] = subm_entry
    if ind then
      local url = canvas.url .. canvas.course_prefix ..
                  "gradebook/speed_grader?assignment_id=" .. subm_entry.assignment_id ..
                  "#%7B%22student_id%22%3A%22" .. subm_entry.user_id .. "%22%7D"
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
  io.write("INDEX,USERID,NAME,SCHOOL,PROJID,TITLE,MARK,DIFF,RESOLVED,OVERRIDE,COMMENTS,SUPERVISOR,SUPMARK,MODERATOR,MODMARK,URL,ASSESSOR1,SCORE1,ASSESSOR2,SCORE2,ASSESSOR3,SCORE3,ASSESSOR4,SCORE4,\n")

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
    j = subm[n]
    j.metadata = j.metadata or {}

    local mark, diff, resolved
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
      (j.metadata.url or "")..","

    for kk,vv in pairs(j.marks) do
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
    j = subm[n]
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







local resolve_msg = {
  {
    threshold = 5 ,
    subject = "Marking thanks" ,
    rank = "Close",
    flag = "Y",
    body = [[
These grades are very close and will be taken to calculate the final grade for the group.]]
  } ,
  {
    threshold = 10 ,
    subject = "Marking thanks" ,
    rank = "Near",
    flag = "Y",
    body = [[
These grades are quite consistent and will be taken to calculate the final grade for the group.]]
  } ,
  {
    threshold = 15 ,
    subject = "Marking concern" ,
    rank = "Far",
    flag = "y",
    body = [[
These grades are rather inconsistent but are close enough that, unless I hear otherwise from you, they will be taken to calculate the final grade for the student/group. I invite you to view the assessment of your colleague, and discuss with them, to consider the discrepancy.]]
  } ,
  {
    threshold = 20 ,
    subject = "Marking resolution needed" ,
    rank = "Problem",
    flag = "n",
    body = [[
These grades are inconsistent and must be resolved. Please discuss with your colleague to reappraise your assessments.

After discussion, update your mark against the rubric in MyUni as needed. Your marks do not need to be identical; we will still take an average of the two to calculate the final mark for the student/group.

If you cannot come to a sufficiently close assessment we will organise a third assessment by another independent moderator.]]
  } ,
  {
    threshold = 99 ,
    subject = "Marking 3rd moderator" ,
    rank = "Critical",
    flag = "N",
    body = [[
These grades are inconsistent and must be resolved. Please discuss with your colleague to reappraise your assessments.

After discussion, update your mark against the rubric in MyUni as needed. Your marks do not need to be identical; we will still take an average of the two to calculate the final mark for the student/group.

We will also organise a third assessment by another independent moderator.]]
  } ,
}


function proj:resolve_grades(canvas_subfin)

  for i,j in pairs(canvas_subfin) do

    if (j.metadata.supervisor_mark and j.metadata.moderator_mark) then

      local csv_resolve = j.metadata.resolve
      local grade_diff = math.abs(j.metadata.supervisor_mark - j.metadata.moderator_mark)

      if j.metadata.resolve == "" then

        local close_rank
        for gg = 1,#resolve_msg do
          if grade_diff <= resolve_msg[gg].threshold then
            close_rank = gg
            canvas_subfin[i].metadata.resolve = resolve_msg[close_rank].flag
            break
          end
        end

        if close_rank then
          print("=====================================")
          print("# Assessment resolution: "..j.user.name..", "..j.metadata.proj_title.." ("..j.metadata.proj_id..")")
          print("Supervisor - "..j.metadata.supervisor_mark.." - "..j.metadata.supervisor)
          print("Moderator  - "..j.metadata.moderator_mark.." - "..j.metadata.moderator)
          print("Difference - "..grade_diff.." - "..resolve_msg[close_rank].rank)
          print("Resolve flag - "..j.metadata.resolve)

          print("## Send resolution? Type y to do so:")
          resolve_check = io.read()=="y"

          self:message_resolution(resolve_check,j,close_rank,false)
          if not(resolve_check) then
            canvas_subfin[i].metadata.resolve = ""
          end
        end

      elseif j.metadata.resolve == "n" then

        local close_rank
        for gg = 1,#resolve_msg do
          if grade_diff <= resolve_msg[gg].threshold then
            close_rank = gg
            canvas_subfin[i].metadata.resolve = resolve_msg[close_rank].flag
            break
          end
        end

        if (csv_resolve == "n" or csv_resolve == "N") and close_rank < 4 then
          print("=====================================")
          print("# Assessment resolution: "..j.user.name..", "..j.metadata.proj_title.." ("..j.metadata.proj_id..")")
          print("INCONSISTENCY RESOLVED")
          print("Supervisor - "..j.metadata.supervisor_mark.." - "..j.metadata.supervisor)
          print("Moderator  - "..j.metadata.moderator_mark.." - "..j.metadata.moderator)
          print("Difference - "..grade_diff.." - "..resolve_msg[close_rank].rank)

          print("## Send resolution? Type y to do so:")
          resolve_check = io.read()=="y"

          self:message_resolution(resolve_check,j,close_rank,true)
          if not(resolve_check) then
            canvas_subfin[i].metadata.resolve = csv_resolve
          end
        end

      end

    end
  end

end



function proj:message_resolution(send_bool,j,close_rank,inconsistent_resolved)

  local body_text = "\n\n" .. [[
You have assessed the following student/group:]] .. "\n\n" ..
" • " .. j.user.name .. ": " .. j.metadata.proj_title .. " ("..j.metadata.proj_id..")" .. "\n\n" ..
    "They have been awarded marks of: " .. "\n\n" ..
    " • Supervisor - "..j.metadata.supervisor_mark..    " (" .. j.metadata.supervisor .. ")\n" ..
    " • Moderator  - "..j.metadata.moderator_mark.." (" .. j.metadata.moderator .. ")\n\n"

  local body_end = "\n\n" .. [[
You may view your own assessment at the following link after logging into MyUni:

    • ]] .. j.metadata.url .. "\n" .. [[

If you wish to update your assessment, please make the changes directly in MyUni and let us know by email.

Thank you for your significant contributions towards the success of our capstone project courses.]]

  local close_text = ""
  if inconsistent_resolved then
    close_text =  "Thank you for re-assessing and/or reviewing your marks for this project, they are now close enough to be resolved without a third assessor."
  else
    close_text = resolve_msg[close_rank].body
  end

  local msg =

  canvas:message_user(send_bool,{
    canvasid  =
      {
        self.all_staff[j.metadata.supervisor].id ,
        self.all_staff[j.metadata.moderator].id  ,
      } ,
    subject   =
      self.assign_name_colloq ..
      " marking: " ..
      resolve_msg[close_rank].subject ..
      " ("..j.metadata.proj_id..")"   ,
    body      =
      "Dear " .. j.metadata.supervisor .. ", " .. j.metadata.moderator ..
      body_text .. close_text .. body_end .. self.message.signoff   ,
          })

end






return proj
