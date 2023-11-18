

local pretty  = require("pl.pretty")
local canvas  = require("canvas-lms")

local proj = {}


function proj:check_marking(assign_data,check_bool,assgn_lbl,debug_user)

  assgn_lbl = assgn_lbl or self.deliverable -- argument to customise if needed to differentiate supervisor/moderator, say

  if self.assignments[self.assign_name_canvas] == nil then
    pretty.dump(self.assignments)
    error("Something wrong! Can't find: "..self.assign_name_canvas)
  end

  if self.assignments[self.assign_name_canvas].rubric == nil then
    pretty.dump(self.assignments[self.assign_name_canvas])
    error("No rubric data in this assignment?")
  end

  for _,j in pairs(assign_data) do
    if j.metadata == nil then
      pretty.dump(j)
      error("No CSV metadata for student '"..j.user.name.."'  ("..j.user.sis_user_id..")")
    end
  end

  if self.assignments[self.assign_name_canvas].moderated_grading then
    self:print("\n## CHECKING ASSIGNMENT MARKING (MODERATED): "..self.assign_name_canvas)
    assign_data = self:check_moderated(assign_data,check_bool,assgn_lbl,debug_user)
  else
    self:print("\n## CHECKING ASSIGNMENT MARKING (NOT MODERATED): "..self.assign_name_canvas)
    assign_data = self:check_assignment(assign_data,check_bool,assgn_lbl,debug_user)
  end

  return assign_data
end


function proj:check_assignment(assign_data,check_bool,assgn_lbl,debug_user)

  assgn_lbl = assgn_lbl or self.deliverable -- argument to customise if needed to differentiate supervisor/moderator, say
  local Nrubric = #self.assignments[self.assign_name_canvas].rubric

  for i,j in pairs(assign_data) do

--    self:print("* SUBMISSION: "..i..". Student: "..j.user.name.."  ("..j.user.sis_user_id..")")

    local assr
    local grade = j.grade
    local grader_cid = j.grader_id

    local marks_lost   = 0
    local rubric_count = 0
    local rubric_sum   = 0
    local rubric_fail  = false

    local logmessage = ""

    if grade then

      logmessage = logmessage .. "\n" ..("\n"..i..". Student: "..j.user.name.."  ("..j.user.sis_user_id..")")
      if self.assign_moderated then
        logmessage = logmessage .. "\n" ..("Supervisor: "..j.metadata.supervisor.." | Moderator: "..j.metadata.moderator)
      else
        logmessage = logmessage .. "\n" ..("Supervisor: "..j.metadata.supervisor)
      end
      logmessage = logmessage .. "\n" ..("URL: "..j.metadata.url)

      j.metadata.assessment_check = {}
      j.metadata.assessment_check.graded = false
      j.metadata.assessment_check.rubric = false
      j.metadata.assessment_check.rubric_incomplete = false
      j.metadata.assessment_check.rubric_sum = 0
      j.metadata.assessment_check.rubric_error = false

      assign_data[i].marks = assign_data[i].marks or {}

      _,assr = self:staff_lookup_cid(grader_cid)

      j.metadata.assessment_check.graded = true
      logmessage = logmessage .. "\n" ..("Grade: "..grade.." | Entered grade: "..j.entered_grade)
      if j.late then
        marks_lost = j.points_deducted or marks_lost
        logmessage = logmessage .. "\n" ..("LATE - points deducted: "..marks_lost.." - late by: "..(j.seconds_late/60).." min = "..(j.seconds_late/60/60).." hrs = "..(j.seconds_late/60/60/24).." days")
        if j.seconds_late < 60*60 then
          print(logmessage)
          print("Late penalty should be waived (<1hr) -- correct manually")
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
          logmessage = logmessage .. "\n" ..("Rubric complete: " .. rubric_count .. " of " .. Nrubric .. " entries.")
          if math.abs(rubric_sum-grade-marks_lost)>=0.5 then
            j.metadata.assessment_check.rubric_error = true
            logmessage = logmessage .. "\n" ..("ERROR: rubric sum ("..rubric_sum..") does not match final mark awarded ("..grade..")")
            rubric_fail = true
          end
        elseif rubric_count < Nrubric then
          j.metadata.assessment_check.rubric_incomplete = true
          logmessage = logmessage .. "\n" ..("ERROR: Only "..rubric_count.." of "..Nrubric.." rubric entries completed.")
          rubric_fail = true
        end
      else
        logmessage = logmessage .. "\n" ..("ERROR: Grade entered but no rubric information.")
        rubric_fail = true
      end

      if rubric_fail then
        if check_bool then
          logmessage = logmessage .. "\n" ..("Rubric fail: send message? Type y to do so:")
          print(logmessage)
          self:message_rubric_fail( io.read()=="y" ,j,grade,rubric_sum,rubric_count,Nrubric)
        end
      end
    else
      if j.rubric_assessment then

        logmessage = logmessage .. "\n" ..("\n"..i..". Student: "..j.user.name.."  ("..j.user.sis_user_id..")")
        if self.assign_moderated then
          logmessage = logmessage .. "\n" ..("Supervisor: "..j.metadata.supervisor.." | Moderator: "..j.metadata.moderator)
        else
          logmessage = logmessage .. "\n" ..("Supervisor: "..j.metadata.supervisor)
        end
        logmessage = logmessage .. "\n" ..("URL: "..j.metadata.url)

        logmessage = logmessage .. "\n" ..("Checking rubric:")
        for _,jj in pairs(j.rubric_assessment) do
          if jj.points then
            rubric_count = rubric_count+1
          end
        end
        if rubric_count < Nrubric then
          logmessage = logmessage .. "\n" ..("Assessment started but not yet complete; no grade and only "..rubric_count.." of "..Nrubric.." rubric entries.")
        else
          if check_bool then
            print(logmessage)
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
      assign_data[i].metadata[assgn_lbl.."_graded_at"] = (j.graded_at or "")
    end

    if j.user.name == debug_user then
      pretty.dump(j)
      error()
    end

  end

  return assign_data

end




function proj:check_moderated(assign_data,check_bool,assgn_lbl,debug_user)

  -- Ensure canvas moderation settings are "correct"
  local fixme = false
  if self.assignments[self.assign_name_canvas].grader_count < 999 then
    fixme = true
  end
  if self.assignments[self.assign_name_canvas].grader_comments_visible_to_graders == true then
    fixme = true
  end
  if fixme then
    pretty.dump(self.assignments[self.assign_name_canvas])
    self:print("Fixing moderated assignment settings:")
    self:create_assignment{
       name  = self.assign_name_canvas ,
       grader_comments_visible_to_graders = false,
       grader_count = 999,
      }
  end

  local Nrubric = #self.assignments[self.assign_name_canvas].rubric

  for i,j in pairs(assign_data) do

    local logmessage = ""

    assign_data[i].marks = assign_data[i].marks or {}

    logmessage = logmessage .. ("\n"..i.."\nStudent: "..j.user.name)
    if j.metadata == nil then
      pretty.dump(j)
      pretty.dump(self.student_ind)
      self:print(logmessage)
      self:print("Student information not included in CSV file. Type y to abort, anything else to continue:")
      if io.read()=="y" then
        error("You aborted")
      end
    else
      logmessage = logmessage .. "\n" .. ("Project: "..j.metadata.proj_title)
      logmessage = logmessage .. "\n" .. ("Supervisor: "..j.metadata.supervisor .. " | Moderator: "..j.metadata.moderator)
      logmessage = logmessage .. "\n" .. ("URL: "..j.metadata.url)

      if j.late then
        marks_lost = j.points_deducted
        logmessage = logmessage .. "\n" .. ("LATE - points deducted: "..marks_lost.." - late by: "..(j.seconds_late/60).." min = "..(j.seconds_late/60/60).." hrs = "..(j.seconds_late/60/60/24).." days")
        if j.seconds_late < 60*60 then
          print(logmessage)
          print("Late penalty should be waived (<1hr) -- correct manually")
        end
      end

      j.provisional_grades = j.provisional_grades or {}
      for ig,jg in ipairs(j.provisional_grades) do
        local assr
        local assr_uid
        local scr
        local marks_lost   = 0
        local rubric_count = 0
        local rubric_sum   = 0
        local rubric_fail  = false

        if #jg.rubric_assessments > 0 then

          -- always take most recent assessment (in fact, not sure when there ever would be more than one but sometimes it seems to happen)
          local jj = jg.rubric_assessments[#jg.rubric_assessments]

          assr = jj.assessor_name
          assessor_lookup = self:staff_lookup_cid(jj.assessor_id)
          assr_uid = assessor_lookup.login_id

          logmessage = logmessage .. "\n" .. ("Assessor "..ig..": "..assr.." ("..assr_uid..")")

          for _,jjj in pairs(jj.data) do
            if jjj.points then
              rubric_sum   = rubric_sum + jjj.points
              rubric_count = rubric_count + 1
            end
          end

          if jj.score==nil then
            if rubric_count == Nrubric then
              logmessage = logmessage .. "\n" .. ("      Assessor: "..assr.." ("..rubric_sum..") - rubric complete but no score.")
              if check_bool then
                self:print(logmessage)
                self:print("Rubric complete but no score: send message? Type y to do so:")
                self:message_rubric_no_grade(io.read()=="y",j,assr)
              end
            else
              logmessage = logmessage .. "\n" .. ("      Assessor: "..assr.." - "..rubric_count.." of "..Nrubric.." rubric entries and no score.")
            end
            if jg.score then
              scr  = jg.score
              logmessage = logmessage .. "\n" .. ("      Score manually entered by assessor ("..scr..")")
              rubric_fail = true
            end
          else
            scr  = jj.score
            if rubric_count == Nrubric then
              logmessage = logmessage .. "\n" .. ("      Assessor: "..assr.." ("..scr..") - rubric complete.")
              if rubric_sum-jj.score>0.5 or rubric_sum-scr<-0.5 then
                logmessage = logmessage .. "\n" .. ("      Assessor: "..assr.." ("..scr..") - ERROR: rubric sum ("..rubric_sum..") does not match final mark awarded ("..jj.score..")")
                rubric_fail = true
              end
            elseif rubric_count < Nrubric then
              logmessage = logmessage .. "\n" .. ("      Assessor: "..assr.." ("..scr..") - ERROR: Only "..rubric_count.." of "..Nrubric.." rubric entries completed.")
              rubric_fail = true
            end

          end

        elseif #jg.rubric_assessments == 0 and not(jg.score==nil) then

          scr  = jg.score
          assessor_lookup, assr = self:staff_lookup_cid(jg.scorer_id)
          assr_uid = assessor_lookup.login_id

          logmessage = logmessage .. "\n" .. ("      Assessor: "..assr.." ("..scr..") - score but no rubric.")

        else
          logmessage = logmessage .. "\n" .. ("      Assessment started (?) but not yet complete.")
        end

        if rubric_fail and check_bool then
          self:print(logmessage)
          self:print("Rubric fail: send message? Type y to do so:")
          self:message_rubric_fail(io.read()=="y",j,scr,rubric_sum,rubric_count,Nrubric,assr)
        else
          if self.verbose > 1 then
            self:print(logmessage)
          end
        end

        local assgn_lbl = nil
        if self.verbose > 0 then print("Assessor: "..(assr or "").." | Score: "..(scr or "").." | rubric_fail: "..(rubric_fail and "TRUE" or "FALSE")) end
        if assr and scr and not(rubric_fail) then
          assign_data[i].marks[assr_uid] = {assr,scr}
          if not(assign_data[i].metadata==nil) then
            if assign_data[i].metadata.supervisor_id == assr_uid then
              assgn_lbl = "supervisor"
            elseif assign_data[i].metadata.moderator_id == assr_uid then
              assgn_lbl = "moderator"
            end
          end
        end
        if assgn_lbl then
          assign_data[i].metadata[assgn_lbl.."_mark"] = scr
          assign_data[i].metadata[assgn_lbl.."_provisional_id"] = jg.provisional_grade_id
          assign_data[i].metadata[assgn_lbl.."_mark_entered"] = scr
          assign_data[i].metadata[assgn_lbl.."_penalty"] = marks_lost
          assign_data[i].metadata[assgn_lbl.."_seconds_late"] = (j.seconds_late or 0)
          assign_data[i].metadata[assgn_lbl.."_graded_at"] = (graded_at or "")
        end

      end

      if j.user.name == debug_user then
        pretty.dump(j.metadata)
        error()
      end

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
    rubric_fail_str = "only " .. rubric_count .. " of " .. Nrubric .. " rubric entries have been completed."
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

  self:message_user(remind_check,{
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

  self:message_user(remind_check,{
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
