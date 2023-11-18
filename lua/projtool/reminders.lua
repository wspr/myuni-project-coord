
local pretty  = require("pl.pretty")
local Date    = require("pl.Date")
local file    = require("pl.file")
local canvas  = require("canvas-lms")


local proj = {}



function proj:message_reminder_add(j,rem_table,args)

  self:info("<================ Adding reminder:")
  self:info("ID: " .. j.metadata.proj_id)
  self:info(j.metadata.proj_title)

  local sup_or_mod = args.whom
  local assign_grouped = args.grouped or self.assign_grouped or false
  local assm = self.deliverable

  local acad_id   = j.metadata[sup_or_mod.."_id"]
  local staff_lookup, acad_name
  if (acad_id == nil) or (acad_id == "") then
    pretty.dump(j.metadata)
    print("!!!!!!!!!!!! Huh? Missing metadata: '"..sup_or_mod.."_id'")
    staff_lookup = {}
    acad_name = "MISSING"
  else
    staff_lookup, acad_name = self:staff_lookup(acad_id)
  end

  local school = j.metadata.school
  self:info("School: "..school)
  local coord = self.coordinators[school]
  if coord == nil then
    pretty.dump(self.coordinators)
    error("No coordinator entry for school '"..school.."'")
  end
  if type(coord) == "table" then
    coord = coord[2]
  else
    print("Coordinator data/name: "..coord)
    error("Coordinator table must list UoA ID as second entry")
  end

  local coord_str = self.staff[coord].name.." <"..self.staff[coord].login_id.."@adelaide.edu.au>"
  self:info("Coordinator: "..coord_str)

  rem_table[acad_name]         = rem_table[acad_name] or {}
  rem_table[acad_name].details = staff_lookup
  rem_table[acad_name].marking = rem_table[acad_name].marking or {}

  if rem_table[acad_name].marking[assm] == nil then
    rem_table[acad_name].marking[assm] = {}
    rem_table[acad_name].marking[assm].supervisor = ""
    rem_table[acad_name].marking[assm].moderator  = ""
    rem_table[acad_name].marking[assm].projects   = {}
    rem_table[acad_name].marking[assm].assessment = self.assign_name_colloq
    rem_table[acad_name].marking[assm].assign_grouped = self.assign_grouped
    rem_table[acad_name].marking[assm].courseid   = self.courseid
    rem_table[acad_name].marking[assm].school     = school
    rem_table[acad_name].marking[assm].coordinator = coord_str
    rem_table[acad_name].marking[assm].coord_cid   = self.staff[coord].id
  end

  local assess_student_str
  local assess_proj_str
  if assign_grouped then
    assess_student_str = ""
    assess_proj_str = string.upper(j.metadata.proj_title) .. "\n            Project ID: " .. j.metadata.proj_id .. "\n"
  else
    assess_student_str =
      string.upper(j.user.name) .. " (student ID: "..j.user.login_id..")\n" ..
      "         Project title: "
    assess_proj_str = j.metadata.proj_title .. "\n            Project ID: " .. j.metadata.proj_id .. "\n"
  end

  local not_submitted_str = ""
  local remind_submitted_str = ""
  local remind_url_str = ""
  local remind_due_str = ""
  local df = Date.Format()
  local dfformat = "yyyy-mm-dd HH:MM"
  local nicedate
  if self.assign_has_submission then
    not_submitted_str = "~~ NOT SUBMITTED YET ~~"
  end
  j.metadata.submitted_at = j.submitted_at or not_submitted_str
  if j.metadata.submitted_at == not_submitted_str then
    j.metadata.since = "N/A"
    if self.assign_has_submission then
      remind_url_str = "      SpeedGrader link: <NOT YET SUBMITTED>\n"
    else
      remind_url_str = "      SpeedGrader link: <" .. j.metadata.url .. ">\n"
    end
  else
    j.metadata.since = tostring(Date{} - df:parse(j.metadata.submitted_at))
    local nicedate = Date.Format(dfformat):tostring(df:parse(j.metadata.submitted_at))
    remind_submitted_str = "             Submitted: " .. j.metadata.submitted_at .. " (".. j.metadata.since .."ago)\n"
    remind_submitted_str = "             Submitted: " .. j.metadata.submitted_at .. "\n"
    if self.assign_has_submission then
      remind_url_str = "      SpeedGrader link: <" .. j.metadata.url .. ">\n"
    end
  end
  if j.cached_due_date then
    nicedate = Date.Format(dfformat):tostring(Date.toLocal(df:parse(j.cached_due_date)))
    remind_due_str = "                   Due: " .. j.cached_due_date .. "\n"
  else
    nicedate = nil
    remind_due_str = ""
  end

  rem_table[acad_name].marking[assm][sup_or_mod] =
    rem_table[acad_name].marking[assm][sup_or_mod] .. "\n" ..
    " • " .. assess_student_str .. assess_proj_str .. remind_due_str .. remind_submitted_str .. remind_url_str

  local N = #rem_table[acad_name].marking[assm].projects
  rem_table[acad_name].marking[assm].projects[N+1] = j.metadata

  self:info(">================")

  return rem_table

end






function proj:assessor_reminder(remind_check,subm1,subm2,args)

  self.reminders = self.reminders or {}
  self:assessor_reminder_collect(self.reminders,subm1,subm2)
  self:assessor_reminder_send(remind_check,self.reminders,args)

end


function proj:assessor_reminder_collect(rem_table,subm1,subm2)

  rem_table = rem_table or {}

  if subm2 then
    rem_table = self:assessor_reminder_collect_moderated(rem_table,subm1,subm2)
  else
    rem_table = self:assessor_reminder_collect_single(rem_table,subm1)
  end
  return rem_table

end

function proj:assessor_reminder_collect_single(rem_table,subm1)

  local count = 0
  for _,j in pairs(subm1) do
    if not(next(j) == nil) and not(j.grade) then
      count = count + 1
      rem_table = self:message_reminder_add(j,rem_table,{whom="supervisor"})
    end
  end

  if count == 0 then
    print("All assessments graded. Hit Enter/Return to continue.")
--    io.read()
  end

  return rem_table

end

function proj:assessor_reminder_collect_moderated(rem_table,subm1,subm2)

  local count = 0
  for _,j in pairs(subm1) do
    if not(j.metadata==nil) and not(j.metadata.supervisor_mark) then
      count = count + 1
      rem_table = self:message_reminder_add(j,rem_table,{whom="supervisor"})
    end
  end

  for _,j in pairs(subm2) do
    if not(j.metadata==nil) and not(j.metadata.moderator_mark) then
      count = count + 1
      rem_table = self:message_reminder_add(j,rem_table,{whom="moderator"})
    end
  end

  return rem_table

end




function proj:assessor_reminder_summarise(rem_table,args)

  rem_table = rem_table or self.reminders

  args = args or {}
  local only_them = args.only_them

  for acad_name,assr in pairs(rem_table) do
    if (only_them == nil) or (only_them == acad_name) then
      print("ASSESSOR: "..acad_name)

      local body = ""
      for stub,assm in pairs(assr.marking) do

        if not(assm.supervisor == "") then
          body = body .. "\n# "..assm.assessment.." -- Supervisor assessment\n\n" .. assm.supervisor
        end
        if not(assm.supervisor == "") and not(assm.moderator == "") then
          body = body .. "\n"
        end
        if not(assm.moderator == "") then
          body = body .. "\n# "..assm.assessment.." -- Moderator assessment\n\n" .. assm.moderator
        end

      end
      print(body)
    end
  end

end



function proj:assessor_reminder_send(remind_check,rem_table,args)

  args = args or {}
  local only_them = args.only_them
  local additional_message = args.lede

  if additional_message == nil then
    if remind_check then
      print("Add an intro message:")
      additional_message = io.read()
    else
      additional_message = "[[Additional message would go here.]]"
    end
  end
  if not(additional_message == "") then
    additional_message = additional_message .. "\n\n"
  end

  for acad_name,assr in pairs(rem_table) do

    self:info("ASSESSOR: "..acad_name)

    local salutation = "Dear " .. assr.details.short_name .. ",\n\n"

    local recip_lookup = { }
    recip_lookup[assr.details.id] = true
    local body = ""

    local context_course
    for stub,assm in pairs(assr.marking) do

      context_course = context_course or assm.courseid
      self:info("COURSE: "..assm.courseid.." | ASSESSMENT: "..assm.assessment.." ("..stub..")")

      if not(assm.supervisor == "") then
        body = body .. "\n# "..assm.assessment.." -- Supervisor assessment\n\n" .. self.message[stub].body_opening .. assm.supervisor
      end
      if not(assm.supervisor == "") and not(assm.moderator == "") then
        body = body .. "\n"
      end
      if not(assm.moderator == "") then
        body = body .. "\n# "..assm.assessment.." -- Moderator assessment\n\n" .. self.message[stub].body_opening .. assm.moderator
      end
      recip_lookup[assm.coord_cid] = true

    end

    local recip = {}
    for i in pairs(recip_lookup) do
      recip[#recip+1] = i
    end

    if (only_them == nil) or (only_them == acad_name) then
      local this_body =
        salutation .. additional_message .. self.message.body_opening .. body .. self.message.body_close .. self.message.signoff

      self:message_user(remind_check,{
        canvasid = recip ,
        subject  = "Capstone project marking",
        body     = this_body,
        courseid = context_course,
      })
    end


  end

end



function proj:assessor_reminder_export(rem_table)

  self:print("# REMINDERS")

  local csvfile       = "csv/assessment-reminders.csv"
  local mailmergefile = "csv/assessment-reminders-mailmerge.csv"

  local function qq(str) return '"'..str..'"' end
  local function csvrow(tbl)
    local str = ""
    local sep = ","
    local count = 0
    for _,v in ipairs(tbl) do
      count = count + 1
      if count > 1 then
        str = str..sep
      end
      str = str..v
    end
    return str.."\n"
  end

  self:print("Constructing reminders list:  "..csvfile)
  file.copy(csvfile,("backup-"..csvfile))
  local ff = io.output(csvfile)

  io.write(csvrow{
    "Sortable name","Name","UoA ID","Email","School",
    "Coordinator","Assessment","Role","Since submission","Student ID","Student name","Project ID","Project title",
    "Speedgrader URL"})

  for k,v in pairs(rem_table) do
    for _,assn in pairs(v.marking) do
      for _,prj in ipairs(assn.projects) do

        local role = "Assessor"
        if prj.supervisor_id == v.details.login_id then
          role = "Supervisor"
        elseif prj.moderator_id == v.details.login_id then
          role = "Moderator"
        end
        io.write(
          csvrow{qq(k),
          v.details.short_name,
          v.details.login_id,
          (v.details.email) or "",
          assn.school,
          qq(assn.coordinator) or "",
          assn.assessment,
          role,
          prj.since,
          "a"..prj.student_id,
          qq(prj.student_name),
          prj.proj_id,
          qq(prj.proj_title),
          prj.url
        })
      end
    end
  end

  io.close(ff)
  self:print("...done.")

  merge_tbl = {}
  for k,v in pairs(rem_table) do
    for _,assn in pairs(v.marking) do
      for _,prj in ipairs(assn.projects) do

        local role = "Assessor"
        if prj.supervisor_id == v.details.login_id then
          role = "Supervisor"
        elseif prj.moderator_id == v.details.login_id then
          role = "Moderator"
        end

        local uid = v.details.login_id
        if uid then
          local rem_text
          if assn.assign_grouped then
            rem_text =
              "Assessment: "..assn.assessment.." (group)\n"..
              "Project: "..prj.proj_id.." - "..prj.proj_title.."\n"..
              "Speedgrader URL: "..prj.url
          else
            rem_text =
              "Assessment: "..assn.assessment.." (individual)\n"..
              "Student: "..prj.student_name.."  ("..prj.student_id..")\n"..
              "Project: "..prj.proj_id.." - "..prj.proj_title.."\n"..
              "Speedgrader URL: "..prj.url
          end

          merge_tbl[uid] = merge_tbl[uid] or {}
          merge_tbl[uid].assessor = v.details.short_name
          merge_tbl[uid].email    = v.details.email or (v.details.login_id.."@adelaide.edu.au")
          if merge_tbl[uid][role] == nil then
            merge_tbl[uid][role] = rem_text
          else
            merge_tbl[uid][role] = merge_tbl[uid][role] .. "\n\n" .. rem_text
          end
        end
      end
    end
  end

  self:print("Constructing mailmerge csv:  "..mailmergefile)
  file.copy(mailmergefile,("backup-"..mailmergefile))
  local ff = io.output(mailmergefile)

  io.write(csvrow{
    "UID","ASSESSOR","EMAIL","SUPERVISED","MODERATED"})

  for k,v in pairs(merge_tbl) do
        io.write(
          csvrow{k,
          v.assessor,
          v.email,
          qq(v.Supervisor or "[none]"),
          qq(v.Moderator or "[none]")
        })
  end

  io.close(ff)
  self:print("...done.")

end



return proj
