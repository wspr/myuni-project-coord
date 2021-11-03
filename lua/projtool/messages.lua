
local proj = {}

proj.message         = {}
proj.message.interim = {}
proj.message.prelim  = {}
proj.message.final   = {}


proj.message.signoff = "\n" .. [[
Best regards,
William Robertson, on behalf of the Project Coordination Team
]]

proj.message.prelim.body_opening = [[
As an honours project supervisor, you are now required to assess the following preliminary reports.

Marks are due by Monday 5 July, 2021. This is an semi-automated reminder.

Follow the links below to take you straight to the reports for assessment in MyUni. If the link doesn't work first time, you will now be logged into MyUni and following the link again will work correctly.
]]

proj.message.prelim.body_close = "\n" .. [[
For traceability, the grade MUST be entered via the marking rubric in MyUni, and short written feedback provided in the MyUni comment box next to the rubric. If you wish to annotate their report, use either the "SpeedGrader" interface or mark up separately and upload via the comments form. Annotated feedback will be directly visible to the students once the marks are released.

Do NOT apply any kind of adjustment for late penalty or other non-compliance for the assessment unless it is explicitly addressed in the marking rubric. These penalties will be applied by the course coordinator.

Please DO highlight any substantial evidence of plagiarism with the course coordinator and they will escalate to Academic Integrity as required.

Any students/groups who have not yet submitted will not be shown and will be included in future reminders.

Note that separate reminders are sent separately for MEng and BEng reports/papers in each semester.

Your continued efforts to make these courses a success are much appreciated.
]]

proj.message.interim.body_opening = [[
As a supervisor, you are now required to assess of the following deliverables.

Marks are due by Monday 5 July, 2021. This is an semi-automated reminder.

The Interim Paper is a HURDLE requirement for the course. If the student receives a fail mark they may eligible for an Additional Assessment to resubmit. Please contact your School's project coordinator to organise this.

If the student ultimately fails this assessment they must repeat Part A of the course next semester before continuing with Part B.

Follow the links below to take you straight to the reports for assessment in MyUni. CHECK THE STUDENT YOU ARE TAKEN TO. If the link doesn't work first time, you will now be logged into MyUni and following the link again will work correctly.
]]

proj.message.interim.body_close = "\n" .. [[
For traceability, the grade MUST be entered via the marking rubric in MyUni, and short written feedback provided in the MyUni comment box next to the rubric. If you wish to annotate their report, use either the "SpeedGrader" interface or mark up separately and upload via the comments form. Annotated feedback will be directly visible to the students once the marks are released.

Do NOT apply any kind of adjustment for late penalty or other non-compliance for the assessment unless it is explicitly addressed in the marking rubric. These penalties will be applied by the course coordinator.

Please DO highlight any substantial evidence of plagiarism with the course coordinator and they will escalate to Academic Integrity as required.

Any students/groups who have not yet submitted will not be shown and will be included in future reminders.

Note that separate reminders are sent separately for MEng and BEng reports/papers in each semester.

Your continued efforts to make these courses a success are much appreciated.
]]

proj.message.final.body_opening =
[[
As a supervisor/moderator, you are now required to assess of the following deliverables.

Marks are due by Monday 28 June, 2021. This is an semi-automated reminder.

Please attempt to complete this task as soon as possible to ensure there is time to compare the supervisor and moderator marks for this report. Late assessment will result in a delay to release the marks to the students.

Follow the links below to take you straight to the reports for assessment in MyUni. CHECK THE STUDENT YOU ARE TAKEN TO. If the link doesn't work first time, you will now be logged into MyUni and following the link again will work correctly.
]]

proj.message.final.body_close = "\n" .. [[
For traceability, the grade MUST be entered via the marking rubric in MyUni, and short written feedback provided in the MyUni comment box next to the rubric. If you wish to annotate their report, use either the "SpeedGrader" interface or mark up separately and upload via the comments form. Annotated feedback is NOT directly visible to the students.

Do NOT apply any kind of adjustment for late penalty or other non-compliance for the assessment unless it is explicitly addressed in the marking rubric. These penalties will be applied by the course coordinator.

Please DO highlight any substantial evidence of plagiarism with the course coordinator and they will escalate to Academic Integrity as required.

Any students/groups who have not yet submitted will not be shown and will be included in future reminders.

Note that separate reminders are sent separately for MEng and BEng reports/papers in each semester.

Your continued efforts to make these courses a success are much appreciated.
]]


return proj