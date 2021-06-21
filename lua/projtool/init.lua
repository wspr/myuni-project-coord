

local csv     = require("csv")
local pretty  = require("pl.pretty")
local data    = require("pl.data")
local path    = require("pl.path")
local binser  = require("binser")
local canvas  = require("canvas-lms")


local proj = {}



function proj:set_cohort(str)
  self.cohort = str
end
function proj:set_assign_name_colloq(str)
  self.assign_name_colloq = str
end
function proj:set_assign_name_canvas(str)
  self.assign_name_canvas = str
end
function proj:set_marks_csv(str)
  self.marks_csv = str
end




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



function proj:read_csv_data(csvfile)

  print("Reading CSV data of students/projects/supervisors/moderators")

  self.proj_data = {}
  self.student_ind = {}
  self.all_staff = {}
  self.all_staff_ids = {}

  local f = csv.open(csvfile)

  local cc = 0
  local nn = 0
  for fields in f:lines() do
    cc = cc+1
    if ( cc > 1 ) and not( fields[1] == "" ) then
      nn = nn+1
      self.proj_data[nn] = {}
      self.proj_data[nn].student_name  = fields[1] or ""
      self.proj_data[nn].student_id    = fields[2] or ""
      self.proj_data[nn].proj_id       = fields[3] or ""
      self.proj_data[nn].proj_title    = fields[4] or ""
      self.proj_data[nn].school        = fields[5] or ""
      self.proj_data[nn].supervisor    = fields[6] or ""
      self.proj_data[nn].supervisor_id = fields[7] or ""
      self.proj_data[nn].moderator     = fields[8] or ""
      self.proj_data[nn].moderator_id  = fields[9] or ""

      self.student_ind[self.proj_data[nn].student_id] = nn
      self.all_staff[self.proj_data[nn].supervisor] = {}
      self.all_staff[self.proj_data[nn].moderator]  = {}

      self.all_staff_ids[self.proj_data[nn].supervisor] = self.proj_data[nn].supervisor_id
      self.all_staff_ids[self.proj_data[nn].moderator]  = self.proj_data[nn].moderator_id
    end
  end

end




function proj:get_canvas_ids(opt)

  print("Searching for supervisors/moderators in Canvas")

  local cache_path = canvas.cache_dir.."AllStaff.lua"

  local download_check = true
  if path.exists(cache_path) then
    local opt = opt or {download="ask"}
    download_check = proj:dl_check(opt,"Look up all supervisor/moderator Canvas IDs?")
  else
    print "Staff Canvas IDs not found, downloading."
    download_check = true
  end

  local id_lookup = {}

  if download_check then
    local not_found_canvas = ""
    for k,v in pairs(self.all_staff) do
      if not(k == "") then
      print(k)
      local search_term = k
      local staff_uoa_id = self.all_staff_ids[k]
      if staff_uoa_id == "" then
        search_term = k
        print("Searching for name:  '"..search_term.."'")
      else
        search_term = staff_uoa_id
        print("Searching for name:  '"..k.."' (ID: "..staff_uoa_id..")")
      end
      local tmp = canvas:find_user(search_term)
      local match_ind = 0
      for i,j in ipairs(tmp) do
        print("Found:  '"..j.name.."' ("..j.login_id..")")
      end
      if #tmp == 1 then
        match_ind = 1
      elseif #tmp > 1 then
        local count_exact = 0
        for i,j in ipairs(tmp) do
          if j.name == k then
            count_exact = count_exact + 1
            match_ind = i
          end
        end
        if count_exact > 1 then
          error("Multiple exact matches for name found. This is a problem! New code needed to identify staff members by their ID number as well.")
        end
      end
      if match_ind > 0 then
        self.all_staff[k] = tmp[match_ind]
        id_lookup[tmp[match_ind].id] = k
      else
        print("No user found for name: "..k)
        not_found_canvas = not_found_canvas.."    "..search_term.."\n"
      end
      end
    end
    for k,v in pairs(id_lookup) do
      self.all_staff[k] = v
    end
    if not_found_canvas ~= "" then
      error("## Canvas users not found, check their names and/or add them via Toolkit:\n\n"..not_found_canvas)
    end
    binser.writeFile(cache_path,self.all_staff)
  end

  local all_staff_from_file = binser.readFile(cache_path)
  self.all_staff = all_staff_from_file[1]

end



function proj:get_submissions(get_bool)

  local canvas_subfin = canvas:get_assignment(get_bool,self.assign_name_canvas,{include={"provisional_grades","user","rubric_assessment"}})
  canvas_subfin = proj:subm_remove(canvas_subfin)

  return canvas_subfin

end



function proj:subm_remove(subm)
  local to_remove = {}
  for i,j in ipairs(subm) do
    if j.excused == nil then
      if j.user.sis_user_id == nil then -- maybe check against a black list, or similar
        print("Student has no login id: "..subm[i].user.name)
        to_remove[#to_remove+1] = i
      end
    else
      if j.excused then
        print("Student excused: "..subm[i].user.name)
        to_remove[#to_remove+1] = i
      end
    end
  end
  for i=#to_remove,1,-1 do
    table.remove(subm,to_remove[i])
  end
  return subm
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
  for _,subm_entry in ipairs(canvas_subm) do
    print("Processing submission by: "..subm_entry.user.name)

    local student_id = subm_entry.user.sis_user_id
    local ind = proj.student_ind[student_id]

    subm[student_id] = subm_entry
    if ind then
      subm[student_id].metadata = {}
      subm[student_id].metadata.proj_id     = proj.proj_data[ind].proj_id
      subm[student_id].metadata.proj_title  = proj.proj_data[ind].proj_title
      subm[student_id].metadata.supervisor  = proj.proj_data[ind].supervisor
      subm[student_id].metadata.moderator   = proj.proj_data[ind].moderator
      subm[student_id].metadata.school      = proj.proj_data[ind].school
      subm[student_id].metadata.url  = canvas.url .. canvas.course_prefix .. "gradebook/speed_grader?assignment_id="..subm_entry.assignment_id.."#%7B%22student_id%22%3A%22"..subm_entry.user_id.."%22%7D"
      subm[student_id].metadata.resolve  = resolve[student_id]  or ""
      subm[student_id].metadata.override = override[student_id] or ""
      subm[student_id].metadata.comments = comments[student_id] or ""
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
  local cc = 0
  for i,j in pairs(subm) do
    cc = cc+1
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



function proj:check_assignment(assign_data,check_bool)
  print("CHECKING ASSIGNMENT MARKING")

  local Nrubric = #canvas.assignments[proj.assign_name_canvas].rubric

  local cc = 0
  for i,j in pairs(assign_data) do
    if j.metadata == nil then
      cc = cc+1
      pretty.dump(j)
      error("Student: "..j.user.name.."  ("..j.user.sis_user_id..")")
    end
  end
  if cc>0 then
    error("Student submission(s) above missing METADATA. Resolve errors above before continuing.")
  end

  for i,j in pairs(assign_data) do

    print("Student: "..j.user.name.."  ("..j.user.sis_user_id..")")
    print("Supervisor: "..j.metadata.supervisor)
    local rubric_data  = {}
    local rubric_count = 0
    local rubric_sum   = 0
    local rubric_fail  = false
    j.metadata.assessment_check = {}
    j.metadata.assessment_check.graded = false
    j.metadata.assessment_check.rubric = false
    j.metadata.assessment_check.rubric_incomplete = false
    j.metadata.assessment_check.rubric_sum = 0
    j.metadata.assessment_check.rubric_error = false
    if j.metadata.supervisor_mark then
      j.metadata.assessment_check.graded = true
      print("Grade: "..j.metadata.supervisor_mark)
      if j.rubric_assessment then
        j.metadata.assessment_check.rubric = true
        for ii,jj in pairs(j.rubric_assessment) do
          rubric_data[ii] = jj.points
          if jj.points then
            rubric_sum = rubric_sum + jj.points
--            print("  Rubric mark: " .. jj.points)
            rubric_count = rubric_count+1
          end
          j.metadata.assessment_check.rubric_sum = rubric_sum
        end
        if rubric_count == Nrubric then
          print("Rubric complete: " .. rubric_count .. " of " .. Nrubric .. " entries.")
          if math.abs(rubric_sum-j.metadata.supervisor_mark)>=0.5 then
            j.metadata.assessment_check.rubric_error = true
            print("ERROR: rubric sum ("..rubric_sum..") does not match final mark awarded ("..j.metadata.supervisor_mark..")")
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
          proj:message_rubric_fail( io.read()=="y" ,j,j.metadata.supervisor_mark,rubric_sum,rubric_count,Nrubric)
        end
      end
    else
      if j.rubric_assessment then
        for ii,jj in pairs(j.rubric_assessment) do
          rubric_data[ii] = jj.points
          if jj.points then
            rubric_count = rubric_count+1
          end
        end
        if rubric_count < Nrubric then
          print("Assessment started but not yet complete; no grade and only "..rubric_count.." of "..Nrubric.." rubric entries.")
        else
          if check_bool then
            print("Rubric complete but no grade: send message? Type y to do so:")
            proj:message_rubric_no_grade( io.read()=="y" ,j)
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

    local rubric_data  = {}
    local rubric_count = 0
    local rubric_sum   = 0
    local rubric_fail  = false
    local grade_count = 0

    assign_data[i].marks = assign_data[i].marks or {}

    print("\n"..cc..". Student: "..j.user.name)
    if j.metadata == nil then
      pretty.dump(j)
      pretty.dump(proj.student_ind)
      error("Student information not included in CSV file. Check?")
    end
    print("Project: "..j.metadata.proj_title)
    print("Supervisor: "..j.metadata.supervisor)
    print("Moderator: "..j.metadata.moderator)

    for ig,jg in ipairs(j.provisional_grades) do
--      print("Grade "..ig)
      local assr
      local scr
      if #jg.rubric_assessments == 0 and not(jg.score==nil) then
        assr = (jg.assessor_name or proj.all_staff[jg.scorer_id])
        if assr == nil then
          local usr = canvas:get(canvas.course_prefix.."users/"..jg.scorer_id)
          assr = usr.name
          proj.all_staff[jg.scorer_id] = usr.name
        end
        scr  = jg.score
        print("      Assessor: "..assr.." ("..scr..") - score but no rubric.")
            print("Rubric fail: send message? Type y to do so:")
            proj:message_rubric_no_grade(io.read()=="y",j,assr)
      else
        for ii,jj in ipairs(jg.rubric_assessments) do

          if jj.score==nil then
            error("      Assessor: "..jj.assessor_name.." - rubric entries but no score.")
            print("Rubric fail: send message? Type y to do so:")
            local remind_check = io.read()
            proj:message_rubric_no_grade(remind_check=="y",j,jj.assessor_name)
          end

          for iii,jjj in pairs(jj.data) do
            rubric_data[iii] = jjj.points
            if jjj.points then
              rubric_sum = rubric_sum + jjj.points
  --            print("  Rubric mark: " .. jjj.points)
              rubric_count = rubric_count+1
            end
          end

          if rubric_count == Nrubric then
            print("      Assessor: "..jj.assessor_name.." ("..jj.score..") - rubric complete.")
            if jj.score==nil then
              pretty.dump(jj)
              error("No SCORE table entry? This shouldn't happen.")
            end
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
            local remind_check = io.read()
            proj:message_rubric_fail(remind_check=="y",j,jj.score,rubric_sum,rubric_count,Nrubric,jj.assessor_name)
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




function proj:message_reminder_add(j,markers_msg)

  local acad_name    = j.metadata.supervisor
  if markers_msg[acad_name] == nil then
    markers_msg[acad_name] = {}
    markers_msg[acad_name].cid = proj.all_staff[j.metadata.supervisor].id
    markers_msg[acad_name].msg = ""
  end

  markers_msg[acad_name].msg = markers_msg[acad_name].msg ..
    "\n • " .. j.user.name .. ": " .. j.metadata.proj_title .. " ("..j.metadata.proj_id..")" ..
    "\n     <" .. j.metadata.url .. ">\n"

end



function proj:assessor_reminder_interim(remind_check,markers_msg,only_them)

  for acad_name,j in pairs(markers_msg) do

    local proceed = false
    if only_them == nil then
      proceed = true
    else
      if acad_name == only_them then
        proceed = true
      end
    end

    if proceed then
      canvas:message_user(remind_check,{
        canvasid  = proj.all_staff[acad_name].id ,
        subject   = proj.assign_name_colloq .. " marking",
        body      = "Dear " .. acad_name .. ",\n\n" .. proj.message.body_opening_interim .. j.msg .. proj.message.body_close_interim .. proj.message.signoff
              })
    end

  end

end






proj.message = {}
proj.message.signoff = [[
Best regards,
William Robertson, on behalf of the Project Coordination Team
]]

proj.message.body_opening_interim = [[
This assessment has now been submitted and is ready for marking. This is an semi-automated reminder.

Please attempt to complete this task as soon as possible.

The Interim Paper is a HURDLE requirement for the course. If the student receives a fail mark they may eligible for an Additional Assessment to resubmit. Please contact your School's MEng Research Project coordinator to organise this.

If the student ultimately fails this assessment they must repeat Part A of the course next semester before continuing with Part B.

Follow the links below to take you straight to the reports for assessment in MyUni. If it doesn't work first time, log into MyUni and follow the link again.
]]

proj.message.body_close_interim = [[

For traceability, the grade MUST be entered via the marking rubric in MyUni and at minimum some written feedback provided in the MyUni comment box next to the rubric. If you wish to annotate their report, use either the "SpeedGrader" interface or mark up separately and upload via the comments form. This feedback, along with the raw mark you assign, will be made available to the students at the completion of the assessment period.

Any students who have not yet submitted will not be shown and will be included in future reminders. Note that this list does NOT include completing projects or honours project reports. Separate reminders will be circulated for these (if applicable).

Your continued efforts to make the MEng Research Project course a success are much appreciated.

]]






function proj:message_rubric_fail(remind_check,j,score,rubric_sum,rubric_count,Nrubric,assessor_name)

  local assessor_name = assessor_name or j.metadata.supervisor

  local rubric_fail_str = ""
  if rubric_count == 0 then
    rubric_fail_str = "no rubric entries have been completed. For traceability we require all assessors to use the rubric explicitly."
  elseif rubric_count < Nrubric then
    rubric_fail_str = "only " .. rubric_count .. " of " .. Nrubric .. " rubric entries have been completed. This indicates you may have overlooked an aspect of their assessment."
  elseif rubric_count == Nrubric then
    rubric_fail_str = "the sum of your rubric entries is " .. rubric_sum .. ". Please correct the total and/or the rubric to ensure these are consistent."
  else
    error("This shouldn't happen")
  end

  canvas:message_user(remind_check,{
    canvasid  = proj.all_staff[assessor_name].id ,
    subject   = proj.assign_name_colloq.." marking: " .. j.user.name ,
    body      = "Dear " .. assessor_name .. ",\n\n" .. [[
This is an semi-automated reminder. ]]  .. "\n\n" .. [[
You have assessed the following student/group:]] .. "\n\n" ..
j.user.name .. ": " .. j.metadata.proj_title .. " ("..j.metadata.proj_id..")" .. "\n\n" .. [[
You have awarded them a grade of ]] .. score .. "/100 but " .. rubric_fail_str .. "\n\n" .. [[
Please correct this at the assessment page via the following link:]] .. "\n\n" ..
j.metadata.url .. "\n\n" .. proj.message.signoff
          })

end

function proj:message_rubric_no_grade(remind_check,j,assessor_name)

  canvas:message_user(remind_check,{
    canvasid  = proj.all_staff[assessor_name].id ,
    subject   = proj.assign_name_colloq.." marking: " .. j.user.name ,
    body      = "Dear " .. assessor_name .. ",\n\n" .. [[
This is an semi-automated reminder. ]]  .. "\n\n" .. [[
You have assessed the following student/group:]] .. "\n\n" ..
j.user.name .. ": " .. j.metadata.proj_title .. " ("..j.metadata.proj_id..")" .. "\n\n" .. [[
You have not yet awarded them a total mark but all rubric entries have been completed.]] .. "\n\n" .. [[
Once you are ready to finalise their mark, enter it in the assessment page via the following link:]] .. "\n\n    " ..
j.metadata.url .. "\n\n" .. proj.message.signoff
          })

end



local reminder_body_opening =
    "As a supervisor/moderator, you are now required to assist in the assessment of the following final assessments. Marks are due by Monday 28 June, 2021. " ..
    "This is an semi-automated reminder. " ..
[[
Please attempt to complete this task as soon as possible to ensure there is time to compare the supervisor and moderator marks for this report. Late assessment will result in a delay to release the marks to the students.

Follow the links below to take you straight to the reports for assessment in MyUni. CHECK THE STUDENT YOU ARE TAKEN TO. If the link doesn't work first time, you will now be logged into MyUni and following the link again will work correctly.
]]

local reminder_body_close = [[

For traceability, the grade MUST be entered via the marking rubric in MyUni and at minimum some written feedback provided in the MyUni comment box next to the rubric. If you wish to annotate their report, use either the "SpeedGrader" interface or mark up separately and upload via the comments form. This feedback, along with the raw mark you assign, will be made available to the students at the completion of the assessment period.

Your continued efforts to make these courses a success are much appreciated.

Note that separate reminders are sent separately for MEng and BEng reports/papers in each semester.]]


function proj:assessor_reminder_final(remind_check,subm)

  local message_reminder_add = function(j,sup_or_mod,markers_msg)

    local acad_name = j.metadata[sup_or_mod]

    if markers_msg[acad_name] == nil then
      markers_msg[acad_name] = {}
      markers_msg[acad_name].supervisor = ""
      markers_msg[acad_name].moderator  = ""
    end

    markers_msg[acad_name][sup_or_mod] = markers_msg[acad_name][sup_or_mod] ..
      "\n • " .. j.user.name .. ": " .. j.metadata.proj_title .. " ("..j.metadata.proj_id..")" .. "\n     <" .. j.metadata.url .. ">\n"

  end

  local sup_lede = "# Supervisor assessment\n"
  local mod_lede = "# Moderator assessment\n"

  local markers_msg = {}

  for i,j in pairs(subm) do
   if not(j.metadata==nil) then
     if not(j.metadata.supervisor_mark) then
       message_reminder_add(j,"supervisor",markers_msg)
     end
     if not(j.metadata.moderator_mark) then
       message_reminder_add(j,"moderator",markers_msg)
     end
   end
  end

  for acad_name,j in pairs(markers_msg) do

    local salutation = "Dear " .. acad_name .. ",\n\n"
    local body = ""

    if not(j.supervisor == "") then
      body = body .. sup_lede .. j.supervisor
    end
    if not(j.supervisor == "") and not(j.moderator == "") then
      body = body .. "\n"
    end
    if not(j.moderator == "") then
      body = body .. mod_lede .. j.moderator
    end

    canvas:message_user(remind_check,{
      course    = canvas.courseid,
      canvasid  = proj.all_staff[acad_name].id ,
      subject   = proj.assign_name_colloq.." marking",
      body      = salutation .. reminder_body_opening .. "\n" .. body .. reminder_body_close .. "\n\n" .. proj.message.signoff
    })

  end

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

  if inconsistent_resolved then
    body_text = body_text .. "Thank you for re-assessing and/or reviewing your marks for this project, they are now close enough to be resolved without a third assessor." .. "\n\n"
  end

  local body_end = "\n\n" .. [[
You may view your own assessment at the following link after logging into MyUni:

    • ]] .. j.metadata.url .. "\n" .. [[

If you wish to update your assessment, please make the changes directly in MyUni and let us know by email.

Thank you for your significant contributions towards the success of our capstone project courses.]]

  canvas:message_user(send_bool,{
    canvasid  = proj.all_staff[j.metadata.supervisor].id ,
    subject   = proj.assign_name_colloq.." marking: " .. resolve_msg[close_rank].subject .. " ("..j.metadata.proj_id..")" ,
    body      = "Dear " .. j.metadata.supervisor .. body_text .. resolve_msg[close_rank].body .. body_end .. "\n\n" .. proj.message.signoff
          })

  canvas:message_user(send_bool,{
    canvasid  = proj.all_staff[j.metadata.moderator].id ,
    subject   = proj.assign_name_colloq.." marking: " .. resolve_msg[close_rank].subject .. " ("..j.metadata.proj_id..")" ,
    body      = "Dear " .. j.metadata.moderator .. body_text .. resolve_msg[close_rank].body .. body_end .. "\n\n" .. proj.message.signoff
          })

end






return proj
