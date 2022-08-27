
local proj = {}

proj.message         = {}
proj.message.interim = {}
proj.message.prelim  = {}
proj.message.progress= {}
proj.message.final   = {}
proj.message.plan    = {}


proj.message.signoff = "\n" .. [[
Best regards,
William Robertson, on behalf of the Project Coordination Team
]]

proj.message.plan.body_opening = [[
As an honours project supervisor, you are now required to assess the following Project Plans. This is a semi-automated reminder.

Follow the links below to take you straight to the reports for assessment in MyUni.
]]


proj.message.prelim.body_opening = [[
As an honours project supervisor, you are now required to assess the following reports. This is a semi-automated reminder.

The Progress Report is a HURDLE requirement for the course. If the student/group receives a fail mark they will be eligible for an Additional Assessment to resubmit. Please contact your School's project coordinator to organise this. If the student/group ultimately fails this assessment they must repeat Part A of the course next semester before continuing with Part B.

Follow the links below to take you straight to the reports for assessment in MyUni.
]]

proj.message.interim.body_opening = [[
As a supervisor, you are now required to assess of the following deliverables. This is a semi-automated reminder.

The Interim Paper is a HURDLE requirement for the course. If the student receives a fail mark they may be eligible for an Additional Assessment to resubmit. Please contact your School's project coordinator to organise this.

If the student ultimately fails this assessment they must repeat Part A of the course next semester before continuing with Part B.

Follow the links below to take you straight to the reports for assessment in MyUni.
]]

proj.message.final.body_opening =
[[
As a supervisor/moderator, you are now required to assess of the following deliverables. This is a semi-automated reminder.

Please attempt to complete this task as soon as possible to ensure there is time to compare the supervisor and moderator marks for this assessment. Late marking will result in a delay to release the results to the students.

Follow the links below to take you straight to the reports/papers for assessment in MyUni.
]]

proj.message.progress.body_opening =
[[
This is a semi-automated reminder. As a supervisor/moderator, you are now required to assess of the following deliverables (links below). Please attempt to complete this task as soon as possible.
]]

proj.message.body_close = "\n" .. [[
For traceability, the marks MUST be entered via the marking rubric in MyUni, with written feedback best provided through the rubric comments against each marking criterion.

Do NOT apply any kind of adjustment for late penalty or other non-compliance for the assessment unless it is explicitly addressed in the marking rubric. These penalties will be applied by the course coordinator.

Please DO highlight any substantial evidence of plagiarism with the course coordinator and they will escalate to Academic Integrity as required.

Any students/groups who have not yet submitted will not be shown and will be included in future reminders.

Your continued efforts to make these courses a success are much appreciated.
]]


return proj
