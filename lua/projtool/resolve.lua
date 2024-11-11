

local pretty  = require("pl.pretty")
local canvas  = require("canvas-lms")


local proj = {}



local resolve_msg = {
  {
    threshold = 5 ,
    subject = "Marking thanks" ,
    rank = "Close",
    flag = "Y",
    body = [[
These grades are very consistent and will be taken to calculate the final grade for the student/group.]]
  } ,
  {
    threshold = 10 ,
    subject = "Marking thanks" ,
    rank = "Near",
    flag = "Y",
    body = [[
These grades are quite consistent and will be taken to calculate the final grade for the student/group.]]
  } ,
  {
    threshold = 15 ,
    subject = "Marking concern" ,
    rank = "Far",
    flag = "Y",
    body = [[
These grades are somewhat inconsistent and must be resolved. I invite you to view the assessment of your colleague, and discuss with them, to consider the discrepancy.

After discussion, update your mark against the rubric in MyUni as needed. Your marks do not need to be identical; we will still take an average of the two to calculate the final mark for the student/group.

If you cannot come to a sufficiently close assessment we will organise a third assessment by another independent moderator, but this is not our preferred approach in this case.]]
  } ,
  {
    threshold = 20 ,
    subject = "Marking resolution needed" ,
    rank = "Problem",
    flag = "N",
    body = [[
These grades are quite inconsistent and must be resolved. Please discuss with your colleague to reappraise your assessments.

After discussion, update your mark against the rubric in MyUni as needed. Your marks do not need to be identical; we will still take an average of the two to calculate the final mark for the student/group.

If you cannot come to a sufficiently close assessment we will organise a third assessment by another independent moderator.

If this is necessary, please advise ASAP to allow us to resolve the situation in a timely fashion.]]
  } ,
  {
    threshold = 99 ,
    subject = "Marking 3rd moderator" ,
    rank = "Critical",
    flag = "N",
    body = [[
These grades are highly inconsistent and must be resolved. This will be done using a third assessor if necessary. Before we go to that step, please discuss with your colleague to reappraise your assessments.

After discussion, if appropriate please update your mark against the rubric in MyUni. Your marks do not need to be identical; if the discrepancy remains we will assign a third assessor.

If this is necessary, please advise ASAP to allow us to resolve the situation in a timely fashion.]]
  } ,
  -- from here these messages should never be reached:
  ["both fail"] = {
    threshold = 999 ,
    subject = "Marking thanks" ,
    rank = "Fail",
    flag = "Y",
    body = [[
Both assessors have awarded a fail mark. These values will be used to calculate the final grade for the student/group.]]
  } ,
  ["one fail"] = {
    threshold = 999 ,
    subject = "Marking fail inconsistency" ,
    rank = "Fail",
    flag = "Y",
    body = [[
One assessor has awarded a fail mark. Our new marking policy requires that either both assessors award a fail mark, or neither do.

Therefore, these grades are inconsistent and must be resolved. This will be done using a third assessor if necessary. Before we go to that step, please discuss with your colleague to reappraise your assessments.

After discussion, if appropriate please update your mark against the rubric in MyUni. Your marks do not need to be identical; if the discrepancy remains we will assign a third assessor.

If this is necessary, please advise ASAP to allow us to resolve the situation in a timely fashion.
]]
  } ,
}


local resolve_msg_hd = {
  {
    threshold = 5 ,
    subject = "Marking thanks" ,
    rank = "Close",
    flag = "Y",
    body = [[
These grades are very consistent and will be taken to calculate the final grade for the student/group.]]
  } ,
  {
    threshold = 10 ,
    subject = "Marking concern" ,
    rank = "Far",
    flag = "Y",
    body = [[
One assessor has awarded a mark of ≥90, which now requires a tighter tolerance for agreement (within 5 marks). Please discuss with your colleague to reappraise your assessments.

After discussion, update your mark against the rubric in MyUni as needed. Your marks do not need to be identical; we will still take an average of the two to calculate the final mark for the student/group.

If you cannot come to a sufficiently close assessment we will organise a third assessment by another independent moderator, but this is not our preferred approach.]]
  } ,
  {
    threshold = 20 ,
    subject = "Marking resolution needed" ,
    rank = "Problem",
    flag = "N",
    body = [[
These grades are highly inconsistent and must be resolved. One assessor has awarded a mark of ≥90, which now requires a tighter tolerance for agreement (within 5 marks). Please discuss with your colleague to reappraise your assessments.

After discussion, update your mark against the rubric in MyUni as needed. Your marks do not need to be identical; we will still take an average of the two to calculate the final mark for the student/group.

If you cannot come to a sufficiently close assessment we will organise a third assessment by another independent moderator.

If this is necessary, please advise ASAP to allow us to resolve the situation in a timely fashion.]]
  } ,
  {
    threshold = 99 ,
    subject = "Marking 3rd moderator" ,
    rank = "Critical",
    flag = "N",
    body = [[
These grades are extremely inconsistent and must be resolved. This will be done using a third assessor if necessary. Before we go to that step, please discuss with your colleague to reappraise your assessments. Note that one assessor has awarded a mark of ≥90, which now requires a tighter tolerance for agreement (within 5 marks).

After discussion, if appropriate please update your mark against the rubric in MyUni. Your marks do not need to be identical; if the discrepancy remains we will assign a third assessor.

If this is necessary, please advise ASAP to allow us to resolve the situation in a timely fashion.]]
  } ,
}



function proj:copy_mod_grades(canvas_subfin,canvas_submod)

  for i in pairs(canvas_submod) do
    if (canvas_subfin[i] == nil) then
      self:print("MISSING SUBMISSION FOR SUPERVISOR")
      self:print("Student/group: "..canvas_submod[i].user.name.."/"..canvas_submod[i].metadata.myuni_proj_id)
      self:print("Project title: "..canvas_submod[i].metadata.proj_title)
      self:print("Supervisor: "..canvas_submod[i].metadata.supervisor)
      self:print("URL: "..canvas_submod[i].metadata.url)
      print("Send message to student?")
      self:message_student_no_submission_sup(io.read()=="y",canvas_submod[i])
    end
    if (canvas_submod[i].metadata == nil) then
      error("No metadata for moderator assessment: should not happen?")
    end
  end

  for i in pairs(canvas_submod) do
    if not(canvas_subfin[i] == nil) then
      if not(canvas_subfin[i].attachments==nil) and (canvas_submod[i].attachments==nil) then
        self:print("MISSING SUBMISSION FOR MODERATOR")
        self:print("Student/group: "..canvas_subfin[i].user.name.."/"..canvas_subfin[i].metadata.myuni_proj_id)
        self:print("Project title: "..canvas_subfin[i].metadata.proj_title)
        self:print("Supervisor: "..canvas_subfin[i].metadata.supervisor)
        self:print("URL: "..canvas_submod[i].metadata.url)
        print("Send message to student?")
        self:message_student_no_submission(io.read()=="y",canvas_submod[i])
      end
      canvas_subfin[i].metadata.moderator = canvas_submod[i].metadata.moderator
      canvas_subfin[i].metadata.moderator_mark = canvas_submod[i].metadata.moderator_mark
      canvas_subfin[i].metadata.moderator_mark_entered = canvas_submod[i].metadata.moderator_mark_entered
      canvas_subfin[i].metadata.moderator_penalty = canvas_submod[i].metadata.moderator_penalty
      canvas_subfin[i].metadata.supervisor_url = canvas_subfin[i].metadata.url
      canvas_subfin[i].metadata.moderator_url  = canvas_submod[i].metadata.url
      canvas_subfin[i].metadata.super_marks    = canvas_subfin[i].marks
      canvas_subfin[i].metadata.moder_marks    = canvas_submod[i].marks
    end
  end
  return canvas_subfin
end

function proj:resolve_grades(resolve_bool,canvas_subfin,canvas_submod,debug_user)

  local assm = self.deliverable
  if assm == nil then
    error("Must define assessment deliverable")
  end

  if next(canvas_subfin)==nil then
    error("Submissions (supervisor) table should not be empty")
  end
  if next(canvas_submod)==nil then
    error("Submissions (moderator) table should not be empty")
  end

  canvas_subfin = self:copy_mod_grades(canvas_subfin,canvas_submod)

  if not(resolve_bool) then
    self:print("* Skipping marks resolution process")
    return canvas_subfin
  end

  local skip_all_bool = false

  self:print("## RESOLVING MARKS BETWEEN SUPERVISOR & MODERATOR: "..assm)
  for i,j in pairs(canvas_subfin) do

    if (j.metadata.supervisor_mark and j.metadata.moderator_mark) then

      local csv_resolve = j.metadata.resolve
      local grade_diff = math.abs(j.metadata.supervisor_mark - j.metadata.moderator_mark)

      if csv_resolve == "" then

        local close_rank
        if (math.abs(j.metadata.supervisor_mark)<50) and (math.abs(j.metadata.moderator_mark)<50) then
          close_rank = "both fail"
          canvas_subfin[i].metadata.resolve = "Y"
        elseif (math.abs(j.metadata.supervisor_mark)<50) and (math.abs(j.metadata.moderator_mark)>=50) then
          close_rank = "one fail"
          canvas_subfin[i].metadata.resolve = "N"
        elseif (math.abs(j.metadata.supervisor_mark)>=90) or (math.abs(j.metadata.moderator_mark)>=90) then
          for gg = 1,#resolve_msg_hd do
            if grade_diff < resolve_msg_hd[gg].threshold then
              close_rank = gg
              canvas_subfin[i].metadata.resolve = resolve_msg_hd[close_rank].flag
              break
            end
          end
        else
          for gg = 1,#resolve_msg do
            if grade_diff < resolve_msg[gg].threshold then
              close_rank = gg
              canvas_subfin[i].metadata.resolve = resolve_msg[close_rank].flag
              break
            end
          end
        end

        if close_rank then
          print("=====================================")
          print("### Assessment resolution: "..j.user.name..", "..j.metadata.proj_title.." ("..j.metadata.proj_id..")")
          print("Supervisor - "..j.metadata.supervisor_mark.." - "..j.metadata.supervisor)
          print("Moderator  - "..j.metadata.moderator_mark.." - "..j.metadata.moderator)
          print("Supervisor - "..j.metadata.supervisor_url)
          print("Moderator  - "..j.metadata.moderator_url)
          print("Difference - "..grade_diff.." - "..resolve_msg[close_rank].rank)
          print("Resolve flag - "..j.metadata.resolve)

          print("Confirm resolution? Type y to do so and send response, q to do so without a response ('quiet'), s to skip this and all the rest, and anything else to move on:")
          local resolve_str
          if not(skip_all_bool) then
            resolve_str = io.read()
          else
            resolve_str = ""
          end
          if resolve_str == "s" then
            skip_all_bool = true
            resolve_str = ""
          end

          if j.metadata.resolve == "Y" and self.assignments[self.assign_name_canvas].moderated_grading then
            local canv_assign_id = self.assignments[self.assign_name_canvas].id

            if resolve_str=="y" or resolve_str=="q" then
--              self:put(self.course_prefix.."assignments/"..canv_assign_id.."/provisional_grades/"..j.metadata.supervisor_provisional_id.."/select")
--              self:put(self.course_prefix.."assignments/"..canv_assign_id.."/provisional_grades/"..j.metadata.moderator_provisional_id.."/select")
            end
          end

          if resolve_str=="y" then
            self:message_resolution(true,j,close_rank,false)
          elseif resolve_str=="q" then
            -- nothing
          else
            -- reset the flag
            self:message_resolution(false,j,close_rank,false)
            canvas_subfin[i].metadata.resolve = ""
          end
        end

      elseif csv_resolve == "N" then

        local close_rank
        for gg = 1,#resolve_msg do
          if grade_diff <= resolve_msg[gg].threshold then
            close_rank = gg
            canvas_subfin[i].metadata.resolve = resolve_msg[close_rank].flag
            break
          end
        end

        if (csv_resolve == "N") and (resolve_msg[close_rank].flag == "Y") then
          print("=====================================")
          print("# Assessment resolution: "..j.user.name..", "..j.metadata.proj_title.." ("..j.metadata.proj_id..")")
          print("INCONSISTENCY RESOLVED")
          print("Supervisor - "..j.metadata.supervisor_mark.." - "..j.metadata.supervisor)
          print("Moderator  - "..j.metadata.moderator_mark.." - "..j.metadata.moderator)
          print("Supervisor - "..j.metadata.supervisor_url)
          print("Moderator  - "..j.metadata.moderator_url)
          print("Difference - "..grade_diff.." - "..resolve_msg[close_rank].rank)

          print("## Confirm updated resolution? Type y to do so and send response, q to do so without a response ('quiet'), and anything else to move on:")
          local resolve_str = io.read()

          if resolve_str=="y" then
            local canv_assign_id = self.assignments[self.assign_name_canvas].id
            if resolve_str=="y" or resolve_str=="q" then
--              self:put(self.course_prefix.."assignments/"..canv_assign_id.."/provisional_grades/"..j.metadata.supervisor_provisional_id.."/select")
--              self:put(self.course_prefix.."assignments/"..canv_assign_id.."/provisional_grades/"..j.metadata.moderator_provisional_id.."/select")
            end
            self:message_resolution(true,j,close_rank,true)
          elseif resolve_str=="q" then
            local canv_assign_id = self.assignments[self.assign_name_canvas].id
            if resolve_str=="y" or resolve_str=="q" then
--              self:put(self.course_prefix.."assignments/"..canv_assign_id.."/provisional_grades/"..j.metadata.supervisor_provisional_id.."/select")
--              self:put(self.course_prefix.."assignments/"..canv_assign_id.."/provisional_grades/"..j.metadata.moderator_provisional_id.."/select")
            end
          else
            -- reset the flag
            self:message_resolution(false,j,close_rank,false)
            canvas_subfin[i].metadata.resolve = csv_resolve
          end

        end

      end

    end

    if j.user.name == debug_user then
      pretty.dump(j)
      io.read()
    end

  end

  print("DONE.")
  return canvas_subfin

end



function proj:message_resolution(send_bool,j,close_rank,inconsistent_resolved)

  local assm = self.deliverable or "final"

  local body_text = "\n\n" .. [[
You have assessed the following student/group:]] .. "\n\n" ..
" • " .. j.user.name .. ": " .. j.metadata.proj_title .. " ("..j.metadata.proj_id..")" .. "\n\n" ..
    "They have been awarded marks of: " .. "\n\n" ..
    " • Supervisor - "..j.metadata.supervisor_mark_entered.." (" .. j.metadata.supervisor .. ")\n" ..
    " • Moderator  - "..j.metadata.moderator_mark_entered .." (" .. j.metadata.moderator  .. ")\n\n"

  local penalty_text = ""
  if j.late then
    if j.metadata.supervisor_penalty ~= j.metadata.moderator_penalty then
      print("Late penalties not equal. Manual fix needed.")
    end
    penalty_text =
      "This report was submitted late with the following penalty (not included in the marks shown above):\n\n"..
      " • Days late: "..string.format("%1.2f",j.metadata.supervisor_seconds_late/60/60/24).."\n"..
      " • Penalty:  -"..string.format("%2.0f",j.metadata.supervisor_penalty).."\n\n"
  end

  local body_end
  if self.assign_moderated then
    body_end = "\n\n" .. [[
You may view both assessments at the following links:

    • Supervisor: ]] .. j.metadata.supervisor_url .. "\n" .. [[
    • Moderator: ]] .. j.metadata.moderator_url .. "\n" .. [[

If you wish to update your assessment, please make the changes directly in MyUni via the rubric.

Thank you for your significant contributions towards the success of our capstone project courses.]]
  else
    body_end = "\n\n" .. [[
You may view each assessment at the following links:

    • Supervisor: ]] .. j.metadata.supervisor_url .. "\n" .. [[
    • Moderator: ]] .. j.metadata.moderator_url .. "\n" .. [[

If you wish to update your assessment, please make the changes directly in MyUni via the rubric.

Thank you for your significant contributions towards the success of our capstone project courses.]]
  end

  local close_text
  if inconsistent_resolved then
    close_text =  "Thank you for re-assessing and/or reviewing your marks for this project, they are now close enough to be resolved."
  else
    close_text = resolve_msg[close_rank].body
  end

  local recip = {}
  if self.staff[j.metadata.supervisor_id] == nil then
    print("Assessor '"..j.metadata.supervisor_id.."' not found in staff list.")
  else
    recip[#recip+1] = tostring(self.staff[j.metadata.supervisor_id].id)
  end
  if self.staff[j.metadata.moderator_id] == nil then
    print("Assessor '"..j.metadata.moderator_id.."' not found in staff list.")
  else
    recip[#recip+1] = tostring(self.staff[j.metadata.moderator_id].id)
  end
  if self.coordinators then
    local coord = self.coordinators[j.metadata.school]
    recip[#recip+1] = tostring(self.staff[coord[2]].id)
  end

  xx = self:message_user(send_bool,{
    canvasid  = recip ,
    subject   =
      self.assign_name_colloq ..
      " marking: " ..
      resolve_msg[close_rank].subject ..
      " ("..j.metadata.proj_id..")"   ,
    body      =
      "Dear " .. j.metadata.supervisor .. " and " .. j.metadata.moderator ..
      body_text .. penalty_text .. close_text .. body_end .. self.message.signoff   ,
          })

  if xx and xx[1] and xx[1]["audience"] == nil then
    print(">>>> LIKELY ERROR >>>>")
    pretty.dump(xx)
    print("<<<< LIKELY ERROR <<<<")
  end

end







return proj
