
local proj = {}

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
William Robertson, on behalf of the Project Coordination Team
]]

proj.message.body_opening = [[
Reminders for ENG 4001/7001 are now consolidated into a single message. This is a semi-automated reminder.

As an academic and/or supervisor involved with honours/masters research project teaching, the following items are due for assessment; see links below to take your straight to each assessment item.

Your assessment must be entered via each criterion of the marking rubric in MyUni, with written feedback to be provided through the rubric comments against each one.

Be careful to hit "Save" after entering marks into the rubric, and save often to avoid data loss. If you need to come back later without finalising your mark, delete the auto-populated total mark after hitting "Save". Avoid the "Submit" button -- it is not connected to the rubric!
]]

proj.message.draft.body_opening = [[
The final/progress draft reports are not assessed but provided by the students for broad and general feedback by their supervisor.

Feedback must be provided quickly as the due dates for these reports are Monday Week 12. 

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
The Progress Report is assessed by both supervisor and moderator with marks averaged to calculate the total. Passing this assessment is a hurdle requirement for the course. If the student/group receives a fail mark they may be eligible for an Additional Assessment to resubmit. If the student/group ultimately fails this assessment they must repeat Part A of the course next semester before continuing with Part B.
]]

proj.message.final.body_opening =
[[
The Final Report is a group assessment that is marked by both supervisor and moderator, with marks averaged to calculate the final grade. Additional moderation will occur if the marks are not well enough aligned.

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
