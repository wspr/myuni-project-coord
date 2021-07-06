

local pretty  = require("pl.pretty")
local canvas  = require("canvas-lms")

local proj = {}


function proj:check_assignment(assign_data,check_bool)
  print("CHECKING ASSIGNMENT MARKING")

  local Nrubric = #canvas.assignments[self.assign_name_canvas].rubric

  local cc = 0
  for _,j in pairs(assign_data) do
    if j.metadata == nil then
      cc = cc+1
      pretty.dump(j)
      error("No metadata for student '"..j.user.name.."'  ("..j.user.sis_user_id..")")
    end
  end
  if cc>0 then
    error("Student submission(s) above missing METADATA. Resolve errors above before continuing.")
  end

  for _,j in pairs(assign_data) do

    print("\nStudent: "..j.user.name.."  ("..j.user.sis_user_id..")")
    print("Supervisor: "..j.metadata.supervisor)
    print("URL: "..j.metadata.url)
    local rubric_count = 0
    local rubric_sum   = 0
    local rubric_fail  = false
    j.metadata.assessment_check = {}
    j.metadata.assessment_check.graded = false
    j.metadata.assessment_check.rubric = false
    j.metadata.assessment_check.rubric_incomplete = false
    j.metadata.assessment_check.rubric_sum = 0
    j.metadata.assessment_check.rubric_error = false
    local grade = j.grade
    if grade then
      j.metadata.assessment_check.graded = true
      print("Grade: "..grade)
      if j.rubric_assessment then
        j.metadata.assessment_check.rubric = true
        for _,jj in pairs(j.rubric_assessment) do
          if jj.points then
            rubric_sum = rubric_sum + jj.points
--            print("  Rubric mark: " .. jj.points)
            rubric_count = rubric_count+1
          end
          j.metadata.assessment_check.rubric_sum = rubric_sum
        end
        if rubric_count == Nrubric then
          print("Rubric complete: " .. rubric_count .. " of " .. Nrubric .. " entries.")
          if math.abs(rubric_sum-grade)>=0.5 then
            j.metadata.assessment_check.rubric_error = true
            print("ERROR: rubric sum ("..rubric_sum..") does not match final mark awarded ("..grade..")")
            rubric_fail = true
          end
        elseif rubric_count < Nrubric then
          j.metadata.assessment_check.rubric_incomplete = true
          print("ERROR: Only "..rubric_count.." of "..Nrubric.." rubric entries completed.")
          rubric_fail = true
        end
      else
        print("ERROR: Grade entered but no rubric information.")
        rubric_fail = true
      end

      if rubric_fail then
        if check_bool then
          print("Rubric fail: send message? Type y to do so:")
          self:message_rubric_fail( io.read()=="y" ,j,grade,rubric_sum,rubric_count,Nrubric)
        end
      end
    else
      if j.rubric_assessment then
        print("Checking rubric:")
        for _,jj in pairs(j.rubric_assessment) do
          if jj.points then
            rubric_count = rubric_count+1
          end
        end
        if rubric_count < Nrubric then
          print("Assessment started but not yet complete; no grade and only "..rubric_count.." of "..Nrubric.." rubric entries.")
        else
          if check_bool then
            print("Rubric complete but no grade: send message? Type y to do so:")
            self:message_rubric_no_grade( io.read()=="y" ,j)
          end
        end
      else
        print("Assessment not started yet.")
      end
    end

  end

  return

end




function proj:check_moderated(assign_data)
  print("CHECKING MODERATED ASSIGNMENT MARKING")

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
      error("Student information not included in CSV file. Check?")
    end
    print("Project: "..j.metadata.proj_title)
    print("Supervisor: "..j.metadata.supervisor)
    print("Moderator: "..j.metadata.moderator)
    print("URL: "..j.metadata.url)

    for _,jg in ipairs(j.provisional_grades) do
--      print("Grade "..ig)
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
        print("Rubric fail: send message? Type y to do so:")
        self:message_rubric_no_grade(io.read()=="y",j,assr)
      elseif #jg.rubric_assessments > 0 then

        do
          local jj = jg.rubric_assessments[#jg.rubric_assessments]

          local rubric_count = #jj.data
          local rubric_sum   = 0
          local rubric_fail  = false

          for _,jjj in pairs(jj.data) do
            if jjj.points then
              rubric_sum   = rubric_sum + jjj.points
              rubric_count = rubric_count + 1
            end
          end

          if jj.score==nil then
            print("      Assessor: "..jj.assessor_name.." - rubric entries but no score.")
            print("Rubric fail: send message? Type y to do so:")
            local remind_check = io.read()
            if rubric_count == Nrubric then
              print("      Assessor: "..jj.assessor_name.." ("..rubric_sum..") - rubric complete but no SCORE.")
              self:message_rubric_no_grade(remind_check=="y",j,jj.assessor_name)
            end
          else

            if rubric_count == Nrubric then
              print("      Assessor: "..jj.assessor_name.." ("..jj.score..") - rubric complete.")
              if rubric_sum-jj.score>0.5 or rubric_sum-jj.score<-0.5 then
                print("      Assessor: "..jj.assessor_name.." ("..jj.score..") - ERROR: rubric sum ("..rubric_sum..") does not match final mark awarded ("..jj.score..")")
                rubric_fail = true
              end
            elseif rubric_count < Nrubric then
              print("      Assessor: "..jj.assessor_name.." ("..jj.score..") - ERROR: Only "..rubric_count.." of "..Nrubric.." rubric entries completed.")
              rubric_fail = true
            end

            if rubric_fail then
                print("Rubric fail: send message? Type y to do so:")
                self:message_rubric_fail(io.read()=="y",j,jj.score,rubric_sum,rubric_count,Nrubric,jj.assessor_name)
            end

          end

          assr = jj.assessor_name
          scr  = jj.score
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

    -- for debugging:
    if j.user.name == "Jane Doe" then
      pretty.dump(assign_data[i])
      error()
    end

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
j.metadata.url .. self.message.signoff
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
j.metadata.url .. self.message.signoff
          })

end






return proj
