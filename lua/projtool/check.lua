

local pretty  = require("pl.pretty")
local canvas  = require("canvas-lms")

local proj = {}


function proj:check_assignment(assign_data,check_bool,assgn_lbl)

  local loginfo
  loginfo = function(x) print(x) end

  print("CHECKING ASSIGNMENT MARKING")

  local Nrubric = #canvas.assignments[self.assign_name_canvas].rubric

  for _,j in pairs(assign_data) do
    if j.metadata == nil then
      pretty.dump(j)
      error("No CSV metadata for student '"..j.user.name.."'  ("..j.user.sis_user_id..")")
    end
  end

  for i,j in pairs(assign_data) do

    local assr
    local grade = j.grade

    local marks_lost   = 0
    local rubric_count = 0
    local rubric_sum   = 0
    local rubric_fail  = false

    if grade then

      loginfo("\n"..i..". Student: "..j.user.name.."  ("..j.user.sis_user_id..")")
      loginfo("Supervisor: "..j.metadata.supervisor.." | Moderator: "..j.metadata.moderator)
      loginfo("URL: "..j.metadata.url)

      j.metadata.assessment_check = {}
      j.metadata.assessment_check.graded = false
      j.metadata.assessment_check.rubric = false
      j.metadata.assessment_check.rubric_incomplete = false
      j.metadata.assessment_check.rubric_sum = 0
      j.metadata.assessment_check.rubric_error = false

      assign_data[i].marks = assign_data[i].marks or {}

      assr = self.all_staff[j.grader_id]
      if assr == nil then
        local usr = canvas:get(canvas.course_prefix.."users/"..j.grader_id)
        assr = usr.name
        self.all_staff[j.grader_id] = usr.name
      end

      j.metadata.assessment_check.graded = true
      loginfo("Grade: "..grade.." | Entered grade: "..j.entered_grade)
      if j.late then
        marks_lost = j.points_deducted
        loginfo("LATE - points deducted: "..marks_lost.." - late by: "..(j.seconds_late/60).." min = "..(j.seconds_late/60/60).." hrs = "..(j.seconds_late/60/60/24).." days")
        if j.seconds_late < 3600 then
          error("Late penalty should be waived (<2hrs) -- correct manually")
        end
      end
      if j.rubric_assessment then
        j.metadata.assessment_check.rubric = true
        for _,jj in pairs(j.rubric_assessment) do
          if jj.points then
            rubric_sum   = rubric_sum + jj.points
            rubric_count = rubric_count+1
          end
          j.metadata.assessment_check.rubric_sum = rubric_sum
        end
        if rubric_count == Nrubric then
          loginfo("Rubric complete: " .. rubric_count .. " of " .. Nrubric .. " entries.")
          if math.abs(rubric_sum-grade-marks_lost)>=0.5 then
            j.metadata.assessment_check.rubric_error = true
            loginfo("ERROR: rubric sum ("..rubric_sum..") does not match final mark awarded ("..grade..")")
            rubric_fail = true
          end
        elseif rubric_count < Nrubric then
          j.metadata.assessment_check.rubric_incomplete = true
          loginfo("ERROR: Only "..rubric_count.." of "..Nrubric.." rubric entries completed.")
          rubric_fail = true
        end
      else
        loginfo("ERROR: Grade entered but no rubric information.")
        rubric_fail = true
      end

      if rubric_fail then
        if check_bool then
          loginfo("Rubric fail: send message? Type y to do so:")
          self:message_rubric_fail( io.read()=="y" ,j,grade,rubric_sum,rubric_count,Nrubric)
        end
      end
    else
      if j.rubric_assessment then

        loginfo("\n"..i..". Student: "..j.user.name.."  ("..j.user.sis_user_id..")")
        loginfo("Supervisor: "..j.metadata.supervisor.." | Moderator: "..j.metadata.moderator)
        loginfo("URL: "..j.metadata.url)

        loginfo("Checking rubric:")
        for _,jj in pairs(j.rubric_assessment) do
          if jj.points then
            rubric_count = rubric_count+1
          end
        end
        if rubric_count < Nrubric then
          loginfo("Assessment started but not yet complete; no grade and only "..rubric_count.." of "..Nrubric.." rubric entries.")
        else
          if check_bool then
            print("Rubric complete but no grade: send message? Type y to do so:")
            self:message_rubric_no_grade( io.read()=="y" ,j)
          end
        end
      end
    end

    if grade then
      assign_data[i].metadata[assgn_lbl.."_mark"] = grade
      assign_data[i].metadata[assgn_lbl.."_mark_entered"] = (j.entered_grade or grade)
      assign_data[i].metadata[assgn_lbl.."_penalty"] = marks_lost
      assign_data[i].metadata[assgn_lbl.."_seconds_late"] = (j.seconds_late or 0)
    end

    -- for debugging:
--  if j.user.name == "Nhu Nguyen" then
--    pretty.dump(j)
--    error()
--  end

  end

  return assign_data

end




function proj:check_moderated(assign_data,args)
  print("CHECKING MODERATED ASSIGNMENT MARKING")

  args = args or {}
  local check_bool = args.check
  if check_bool == nil then
    check_bool = false
  end

  local Nrubric = #canvas.assignments[self.assign_name_canvas].rubric
  local cc = 0

  for i,j in pairs(assign_data) do
    cc = cc+1

    if j.provisional_grades == nil then
      error("No provisional grades? This shouldn't happen.")
    end

    assign_data[i].marks = assign_data[i].marks or {}

    print("\n"..cc..". Student: "..j.user.name)
    if j.metadata == nil then
      pretty.dump(j)
      pretty.dump(self.student_ind)
      print("Student information not included in CSV file. Type y to abort, anything else to continue:")
      if io.read()=="y" then
        error("You aborted")
      end
    else
    print("Project: "..j.metadata.proj_title)
    print("Supervisor: "..j.metadata.supervisor)
    print("Moderator: "..j.metadata.moderator)
    print("URL: "..j.metadata.url)

    for _,jg in ipairs(j.provisional_grades) do
      local assr
      local scr

      if #jg.rubric_assessments == 0 and not(jg.score==nil) then

        assr = (jg.assessor_name or self.all_staff[jg.scorer_id])
        if assr == nil then
          local usr = canvas:get(canvas.course_prefix.."users/"..jg.scorer_id)
          assr = usr.name
          self.all_staff[jg.scorer_id] = usr.name
        end
        scr  = jg.score
        print("      Assessor: "..assr.." ("..scr..") - score but no rubric.")
        if check_bool then
          print("Rubric fail: send message? Type y to do so:")
          self:message_rubric_fail(io.read()=="y",j,scr,0,0,Nrubric,assr)
        end

      elseif #jg.rubric_assessments > 0 then

        -- always take most recent assessment (in fact, not sure when there ever would be more than one but sometimes it seems to happen)
        local jj = jg.rubric_assessments[#jg.rubric_assessments]
        assr = jj.assessor_name

        local rubric_count = 0
        local rubric_sum   = 0
        local rubric_fail  = false

        for _,jjj in pairs(jj.data) do
          if jjj.points then
            rubric_sum   = rubric_sum + jjj.points
            rubric_count = rubric_count + 1
          end
        end

        if jj.score==nil then

          if rubric_count == Nrubric then
            print("      Assessor: "..assr.." ("..rubric_sum..") - rubric complete but no score.")
            if check_bool then
              print("Rubric fail: send message? Type y to do so:")
              self:message_rubric_no_grade(io.read()=="y",j,assr)
            end
          else
            print("      Assessor: "..assr.." - "..rubric_count.." of "..Nrubric.." rubric entries and no score.")
          end

          if jg.score then
            scr  = jg.score
            print("      Score manually entered by assessor ("..scr..")")
          end
        else
          scr  = jj.score

          if rubric_count == Nrubric then
            print("      Assessor: "..assr.." ("..scr..") - rubric complete.")
            if rubric_sum-jj.score>0.5 or rubric_sum-scr<-0.5 then
              print("      Assessor: "..assr.." ("..scr..") - ERROR: rubric sum ("..rubric_sum..") does not match final mark awarded ("..jj.score..")")
              rubric_fail = true
            end
          elseif rubric_count < Nrubric then
            print("      Assessor: "..assr.." ("..scr..") - ERROR: Only "..rubric_count.." of "..Nrubric.." rubric entries completed.")
            rubric_fail = true
          end

          if rubric_fail and check_bool then
              print("Rubric fail: send message? Type y to do so:")
              self:message_rubric_fail(io.read()=="y",j,scr,rubric_sum,rubric_count,Nrubric,assr)
          end

        end

      end

      if assr and scr then
        assign_data[i].marks[assr] = scr
        if not(assign_data[i].metadata==nil) then
          if assign_data[i].metadata.supervisor == assr then
            assign_data[i].metadata.supervisor_mark = scr
          end
          if assign_data[i].metadata.moderator == assr then
            assign_data[i].metadata.moderator_mark = scr
          end
        end
      end
    end
    end

    -- for debugging:
--    if j.user.name == "Flynn Pisani" then
--      pretty.dump(assign_data[i])
--      error()
--    end

  end

  return assign_data
end




function proj:message_rubric_fail(remind_check,j,score,rubric_sum,rubric_count,Nrubric,assessor_name)

  local assr = assessor_name or j.metadata.supervisor

  local rubric_fail_str = ""
  if rubric_count == 0 then
    rubric_fail_str = "no rubric entries have been completed. For traceability we require all assessors to use the rubric explicitly."
  elseif rubric_count < Nrubric then
    rubric_fail_str = "only " .. rubric_count .. " of " .. Nrubric .. " rubric entries have been completed. This indicates you may have overlooked an aspect of their assessment."
  elseif rubric_count == Nrubric then
    rubric_fail_str = "the sum of your rubric entries is " .. rubric_sum .. ". Please correct the total and/or the rubric to ensure these are consistent."
  else
    print("rubric_count = "..rubric_count)
    print("Nrubric = "..Nrubric)
    error("Rubric count does not compare properly. This shouldn't happen")
  end

  local coord = self.coordinators[j.metadata.school]
  if coord == nil then
    error("Coordinator not found.")
  end
  local coord_id = self.all_staff[coord].id

  canvas:message_user(remind_check,{
    canvasid  = {self.all_staff[assr].id,coord_id} ,
    subject   = self.assign_name_colloq.." marking: " .. j.user.name ,
    body      = "Dear " .. assr .. ",\n\n" .. [[
This is an semi-automated reminder. ]]  .. "\n\n" .. [[
You have assessed the following student/group:]] .. "\n\n" ..
j.user.name .. ": " .. j.metadata.proj_title .. " ("..j.metadata.proj_id..")" .. "\n\n" .. [[
You have awarded them a grade of ]] .. score .. "/100 but " .. rubric_fail_str .. "\n\n" .. [[
Please correct this at the assessment page via the following link:]] .. "\n\n" ..
j.metadata.url .. "\n\n" .. self.message.signoff
          })

end

function proj:message_rubric_no_grade(remind_check,j,assessor_name)

  local assr = assessor_name or j.metadata.supervisor

  local coord = self.coordinators[j.metadata.school]
  local coord_id = self.all_staff[coord].id

  canvas:message_user(remind_check,{
    canvasid  = {self.all_staff[assr].id,coord_id} ,
    subject   = self.assign_name_colloq.." marking: " .. j.user.name ,
    body      = "Dear " .. assr .. ",\n\n" .. [[
This is an semi-automated reminder. ]]  .. "\n\n" .. [[
You have assessed the following student/group:]] .. "\n\n" ..
j.user.name .. ": " .. j.metadata.proj_title .. " ("..j.metadata.proj_id..")" .. "\n\n" .. [[
You have not yet awarded them a total mark but all rubric entries have been completed.]] .. "\n\n" .. [[
Once you are ready to finalise their mark, enter it in the assessment page via the following link:]] .. "\n\n    " ..
j.metadata.url .. "\n\n" .. self.message.signoff
          })

end






return proj
