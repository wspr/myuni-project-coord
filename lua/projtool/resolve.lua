

local csv     = require("csv")
local pretty  = require("pl.pretty")
local path    = require("pl.path")
local canvas  = require("canvas-lms")


local proj = {}




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
These grades are highly inconsistent and must be resolved. This will be done using a third assessor if necessary. Before we go to that step, please discuss with your colleague to reappraise your assessments.

After discussion, if appropriate please update your mark against the rubric in MyUni. Your marks do not need to be identical; if the discrepancy remains we will assign a third assessor.

If this is necessary, please advise ASAP to allow us to resolve the situation in a timely fashion.]]
  } ,
}


function proj:resolve_grades(canvas_subfin,canvas_submod)

  for i,j in pairs(canvas_submod) do
    print("Processing moderated paper: "..i)
    if not(canvas_submod[i].metadata == nil) then
      print(canvas_subfin[i].metadata.proj_title)
      print(canvas_submod[i].metadata.proj_title)
      canvas_subfin[i].metadata.moderator_mark = canvas_submod[i].metadata.moderator_mark
      canvas_subfin[i].metadata.supervisor_url = canvas_subfin[i].metadata.url
      canvas_subfin[i].metadata.moderator_url  = canvas_submod[i].metadata.url
      canvas_subfin[i].metadata.super_marks    = canvas_subfin[i].marks
      canvas_subfin[i].metadata.moder_marks    = canvas_submod[i].marks
    end
  end

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
          local resolve_check = io.read()=="y"

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
          local resolve_check = io.read()=="y"

          self:message_resolution(resolve_check,j,close_rank,true)
          if not(resolve_check) then
            canvas_subfin[i].metadata.resolve = csv_resolve
          end
        end

      end

    end
  end

  return canvas_subfin

end



function proj:message_resolution(send_bool,j,close_rank,inconsistent_resolved)

  local body_text = "\n\n" .. [[
You have assessed the following student/group:]] .. "\n\n" ..
" • " .. j.user.name .. ": " .. j.metadata.proj_title .. " ("..j.metadata.proj_id..")" .. "\n\n" ..
    "They have been awarded marks of: " .. "\n\n" ..
    " • Supervisor - "..j.metadata.supervisor_mark..    " (" .. j.metadata.supervisor .. ")\n" ..
    " • Moderator  - "..j.metadata.moderator_mark.." (" .. j.metadata.moderator .. ")\n\n"

  local body_end = "\n\n" .. [[
You may view your own assessment at the following links: (note you will not be able to see the rubric of the other assessor)

    • Supervisor: ]] .. j.metadata.supervisor_url .. "\n" .. [[
    • Moderator: ]] .. j.metadata.moderator_url .. "\n" .. [[

If you wish to update your assessment, please make the changes directly in MyUni and let us know by email.

Thank you for your significant contributions towards the success of our capstone project courses.]]

  local close_text
  if inconsistent_resolved then
    close_text =  "Thank you for re-assessing and/or reviewing your marks for this project, they are now close enough to be resolved without a third assessor."
  else
    close_text = resolve_msg[close_rank].body
  end

  if self.all_staff[j.metadata.supervisor] == nil then
    error("Assessor '"..j.metadata.supervisor.."' not found in staff list.")
  end
  if self.all_staff[j.metadata.moderator] == nil then
    error("Assessor '"..j.metadata.moderator.."' not found in staff list.")
  end
  local recip = {
        self.all_staff[j.metadata.supervisor].id ,
        self.all_staff[j.metadata.moderator].id  ,
  }
  if self.coordinators then
    local coord = self.coordinators[j.metadata.school]
    local coord_id = self.all_staff[coord].id
    recip[#recip+1] = coord_id
  end

  canvas:message_user(send_bool,{
    canvasid  = recip ,
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
