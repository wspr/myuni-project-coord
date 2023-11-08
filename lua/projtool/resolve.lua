

local pretty  = require("pl.pretty")
local canvas  = require("canvas-lms")


local proj = {}



local resolve_msg = {}

resolve_msg.final = {
  {
    threshold = 4 ,
    subject = "Marking thanks" ,
    rank = "Close",
    flag = "Y",
    body = [[
These grades are very close and will be taken to calculate the final grade for the group.]]
  } ,
  {
    threshold = 8 ,
    subject = "Marking thanks" ,
    rank = "Near",
    flag = "Y",
    body = [[
These grades are quite consistent and will be taken to calculate the final grade for the group.]]
  } ,
  {
    threshold = 12 ,
    subject = "Marking concern" ,
    rank = "Far",
    flag = "Y",
    body = [[
These grades are rather inconsistent but are close enough that, unless I hear otherwise from you, they will be taken to calculate the final grade for the student/group. I invite you to view the assessment of your colleague, and discuss with them, to consider the discrepancy.]]
  } ,
  {
    threshold = 20 ,
    subject = "Marking resolution needed" ,
    rank = "Problem",
    flag = "N",
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
These grades are highly inconsistent and must be resolved. This will be done using a third assessor if necessary. Before we go to that step, please discuss with your colleague to reappraise your assessments.

After discussion, if appropriate please update your mark against the rubric in MyUni. Your marks do not need to be identical; if the discrepancy remains we will assign a third assessor.

If this is necessary, please advise ASAP to allow us to resolve the situation in a timely fashion.]]
  } ,
}

resolve_msg.paper = resolve_msg.final

resolve_msg.progress = {
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
    threshold = 20 ,
    subject = "Marking concern" ,
    rank = "Far",
    flag = "Y",
    body = [[
These grades are rather inconsistent but are close enough that, unless I hear otherwise from you, they will be taken to calculate the final grade for the student/group. I invite you to view the assessment of your colleague, and discuss with them, to consider the discrepancy.]]
  } ,
  {
    threshold = 99 ,
    subject = "Marking review needed" ,
    rank = "Critical",
    flag = "N",
    body = [[
These grades are inconsistent and should be reviewed. Please discuss with your colleague to reappraise your assessments.

After discussion, if appropriate please update your mark against the rubric in MyUni. Your marks do not need to be identical; if the discrepancy remains we can assign a third assessor.

If this is necessary, please advise ASAP to allow us to resolve the situation in a timely fashion.]]
  } ,
}

resolve_msg.interim = resolve_msg.progress


function proj:copy_mod_grades(canvas_subfin,canvas_submod)

  for i in pairs(canvas_submod) do
    if (canvas_subfin[i] == nil) then
      print("Student/group: "..i)
      pretty.dump(canvas_submod[i])
      pretty.dump(canvas_subfin)
      error("Processing moderating submission: no matching supervisor assessment found?\nStudent/Project: "..i)
    end
    if (canvas_submod[i].metadata == nil) then
      error("No metadata for moderator assessment: should not happen?")
    end
  end

  for i in pairs(canvas_submod) do
    canvas_subfin[i].metadata.moderator = canvas_submod[i].metadata.moderator
    canvas_subfin[i].metadata.moderator_mark = canvas_submod[i].metadata.moderator_mark
    canvas_subfin[i].metadata.moderator_mark_entered = canvas_submod[i].metadata.moderator_mark_entered
    canvas_subfin[i].metadata.moderator_penalty = canvas_submod[i].metadata.moderator_penalty
    canvas_subfin[i].metadata.supervisor_url = canvas_subfin[i].metadata.url
    canvas_subfin[i].metadata.moderator_url  = canvas_submod[i].metadata.url
    canvas_subfin[i].metadata.super_marks    = canvas_subfin[i].marks
    canvas_subfin[i].metadata.moder_marks    = canvas_submod[i].marks
  end

  return canvas_subfin
end

function proj:resolve_grades(resolve_bool,canvas_subfin,canvas_submod)

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

  self:print("## RESOLVING MARKS BETWEEN SUPERVISOR & MODERATOR: "..assm)
  for i,j in pairs(canvas_subfin) do

    if (j.metadata.supervisor_mark and j.metadata.moderator_mark) then

      local csv_resolve = j.metadata.resolve
      local grade_diff = math.abs(j.metadata.supervisor_mark - j.metadata.moderator_mark)

      if csv_resolve == "" then

        local close_rank
        for gg = 1,#resolve_msg[assm] do
          if grade_diff <= resolve_msg[assm][gg].threshold then
            close_rank = gg
            canvas_subfin[i].metadata.resolve = resolve_msg[assm][close_rank].flag
            break
          end
        end

        if close_rank then
          print("=====================================")
          print("# Assessment resolution: "..j.user.name..", "..j.metadata.proj_title.." ("..j.metadata.proj_id..")")
          print("Supervisor - "..j.metadata.supervisor_mark.." - "..j.metadata.supervisor)
          print("Moderator  - "..j.metadata.moderator_mark.." - "..j.metadata.moderator)
          print("Supervisor - "..j.metadata.supervisor_url)
          print("Moderator  - "..j.metadata.moderator_url)
          print("Difference - "..grade_diff.." - "..resolve_msg[assm][close_rank].rank)
          print("Resolve flag - "..j.metadata.resolve)

          print("## Confirm resolution? Type y to do so and send response, q to do so without a response ('quiet'), and anything else to move on:")
          local resolve_str = io.read()

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
        for gg = 1,#resolve_msg[assm] do
          if grade_diff <= resolve_msg[assm][gg].threshold then
            close_rank = gg
            canvas_subfin[i].metadata.resolve = resolve_msg[assm][close_rank].flag
            break
          end
        end

        if (csv_resolve == "N") and (resolve_msg[assm][close_rank].flag == "Y") then
          print("=====================================")
          print("# Assessment resolution: "..j.user.name..", "..j.metadata.proj_title.." ("..j.metadata.proj_id..")")
          print("INCONSISTENCY RESOLVED")
          print("Supervisor - "..j.metadata.supervisor_mark.." - "..j.metadata.supervisor)
          print("Moderator  - "..j.metadata.moderator_mark.." - "..j.metadata.moderator)
          print("Supervisor - "..j.metadata.supervisor_url)
          print("Moderator  - "..j.metadata.moderator_url)
          print("Difference - "..grade_diff.." - "..resolve_msg[assm][close_rank].rank)

          print("## Confirm updated resolution? Type y to do so and send response, q to do so without a response ('quiet'), and anything else to move on:")
          local resolve_str = io.read()

          if resolve_str=="y" then
            self:message_resolution(true,j,close_rank,true)
          elseif resolve_str=="q" then
            -- nothing
          else
            -- reset the flag
            self:message_resolution(false,j,close_rank,false)
            canvas_subfin[i].metadata.resolve = csv_resolve
          end

        end

      end

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
You may view your own assessment at the following links: (note you will not be able to see the rubric of the other assessor)

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
    close_text = resolve_msg[assm][close_rank].body
  end

  local recip = {}
  if self.staff[j.metadata.supervisor_id] == nil then
    print("Assessor '"..j.metadata.supervisor_id.."' not found in staff list.")
  else
    recip[#recip+1] = self.staff[j.metadata.supervisor_id].id
  end
  if self.staff[j.metadata.moderator_id] == nil then
    print("Assessor '"..j.metadata.moderator_id.."' not found in staff list.")
  else
    recip[#recip+1] = self.staff[j.metadata.moderator_id].id
  end
  if self.coordinators then
    local coord = self.coordinators[j.metadata.school]
    recip[#recip+1] = self.staff[coord[2]].id
  end

  self:message_user(send_bool,{
    canvasid  = recip ,
    subject   =
      self.assign_name_colloq ..
      " marking: " ..
      resolve_msg[assm][close_rank].subject ..
      " ("..j.metadata.proj_id..")"   ,
    body      =
      "Dear " .. j.metadata.supervisor .. ", " .. j.metadata.moderator ..
      body_text .. penalty_text .. close_text .. body_end .. self.message.signoff   ,
          })

end






return proj
