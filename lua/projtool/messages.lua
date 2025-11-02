
local proj = {}


function proj:message_student_no_submission(remind_check,j)

  local assr_uid = j.metadata.supervisor_id

  self:message_user(remind_check,{
    canvasid  = {j.user.id,self.all_staff[assr_uid].id} ,
    subject   = self.assign_name_colloq.." submission: " .. j.user.name ,
    body      = "Dear " .. j.user.name .. ",\n\n" .. [[
This is an automated message. ]]  .. "\n\n" .. [[
The following submission is being assessed for student/group:]] .. "\n\n" ..
j.user.name .. ": " .. j.metadata.proj_title .. " ("..j.metadata.proj_id..")" .. "\n\n" .. [[
You have submitted a report for the supervisor to assess but the submission for the moderator is missing.]] .. "\n\n" .. [[
Please upload a copy of the report for the moderator to assess immediately:]] .. "\n\n    " ..
j.metadata.url .. "\n" .. self.message.signoff
          })

end
function proj:message_student_no_submission_sup(remind_check,j)

  local assr_uid = j.metadata.supervisor_id

  self:message_user(remind_check,{
    canvasid  = {j.user.id,self.all_staff[assr_uid].id} ,
    subject   = self.assign_name_colloq.." submission: " .. j.user.name ,
    body      = "Dear " .. j.user.name .. ",\n\n" .. [[
This is an automated message. ]]  .. "\n\n" .. [[
The following submission is being assessed for student/group:]] .. "\n\n" ..
j.user.name .. ": " .. j.metadata.proj_title .. " ("..j.metadata.proj_id..")" .. "\n\n" .. [[
You have submitted a report for the moderator to assess but the submission for the supervisor is missing.]] .. "\n\n" .. [[
Please upload a copy of the report for the supervisor to assess immediately.]] .. "\n" .. self.message.signoff
          })

end


proj.message         = {}
proj.message.interim = {}
proj.message.progress= {}
proj.message.paper   = {}
proj.message.final   = {}
proj.message.plan    = {}
proj.message.perfA   = {}
proj.message.perfB   = {}
proj.message.draft   = {}


proj.message.signoff = "\n" .. [[
Best regards,
Project Coordination Team
]]

proj.message.body_opening = [[
As an academic and/or supervisor involved with honours/masters research project teaching, the following items are due for assessment; see links below to take your straight to each assessment item.

Your assessment must be entered via each criterion of the marking rubric in MyUni, with written feedback to be provided through the rubric comments against each one.

Be careful to hit "Save" after entering marks into the rubric, and save often to avoid data loss. If you need to come back later without finalising your mark, delete the auto-populated total mark after hitting "Save".

Note the "Submit" button is only connected to the comment box BELOW the rubric -- it is unrelated to the rubric itself!
]]

proj.message.draft.body_opening = [[
The final/progress draft reports are not assessed but provided by the students for broad and general feedback by their supervisor.

Feedback must be provided quickly as the due dates for the students to submit these reports are Monday Week 12.

You should not provide extensive and detailed comments — the students' work is their own and you will be marking their submission, so guidance at this stage is all that is needed.
]]

proj.message.plan.body_opening = [[
The Project Plan is assessed by the project supervisor to provide initial guidance on the direction of the project.
]]

proj.message.perfA.body_opening = [[
The Student Performance mark is awarded by the supervisor at the end of each semester. You won't see a submission from the student -- just click "View Rubric" and enter your marks.
]]
proj.message.perfB.body_opening = [[
The Student Performance mark is awarded by the supervisor at the end of each semester. You won't see a submission from the student -- just click "View Rubric" and enter your marks.
]]

proj.message.interim.body_opening = [[
The Interim Paper is a hurdle requirement for the course. If the student receives a fail mark they may be eligible for an Additional Assessment to resubmit. If the student ultimately fails this assessment they must repeat Part A of the course next semester before continuing with Part B.
]]

proj.message.progress.body_opening =
[[
The Progress Report is assessed by both supervisor and moderator with marks averaged to calculate the total. Passing this assessment is a hurdle requirement for the course.

The page limit of the report scales with number of students in the group. Quantity and extent of achievement are expected to scale similarly. Rubric criteria should be interpreted to take the size of the group into account.

If the student/group receives a fail mark they may be eligible for an Additional Assessment to resubmit. If the student/group ultimately fails this assessment they must repeat Part A of the course next semester before continuing with Part B.
]]

proj.message.final.body_opening =
[[
The Final Report is a group assessment that is marked by both supervisor and moderator, with marks averaged to calculate the final grade. Additional moderation will occur if the marks are not well enough aligned.

The page limit of the report scales with number of students in the group. Quantity and extent of achievement are expected to scale similarly. Rubric criteria should be interpreted to take the size of the group into account.

Please complete this task as soon as possible to ensure there is time to compare the supervisor and moderator marks for this assessment. Late marking will result in a delay to release the results to the students.
]]

proj.message.paper.body_opening =
[[
The Final Paper is an individual assessment that is marked by both supervisor and moderator with marks combined (40%+60%, resp.) to calculate the final grade. Additional moderation will occur if the marks are not well enough aligned.

Please complete this task as soon as possible to ensure there is time to compare the supervisor and moderator marks for this assessment. Late marking will result in a delay to release the results to the students.
]]

proj.message.body_close = "\n" .. [[
# Further information

If you need to change the name of your project, use the following form: https://forms.office.com/r/M3kept7nii

Do not apply any kind of adjustment for late penalty or other non-compliance for the assessment unless it is explicitly addressed in the marking rubric. These penalties will be applied by the course coordinator.

Please do highlight any substantial evidence of plagiarism with the course coordinator and they will escalate to Academic Integrity as required.

Your continued efforts to make these courses a success are much appreciated.
]]


return proj
