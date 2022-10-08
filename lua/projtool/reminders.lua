
local pretty  = require("pl.pretty")
local Date    = require("pl.Date")
local file    = require("pl.file")
local canvas  = require("canvas-lms")


local proj = {}



function proj:message_reminder_add(j,args)

  self:info("<================ Adding reminder:")
  self:info("ID: " .. j.metadata.proj_id)
  self:info(j.metadata.proj_title)

  local sup_or_mod = args.whom
  local assign_grouped = args.grouped or self.assign_grouped or false
  local assm = self.deliverable

  local acad_id   = j.metadata[sup_or_mod.."_id"]
  if (acad_id == nil) or (acad_id == "") then
    pretty.dump(j.metadata)
    error("Huh? Missing metadata: '"..sup_or_mod.."_id'")
  end
  local staff_lookup, acad_name = self:staff_lookup(acad_id)

  local school = j.metadata.school
  self:info("School: "..school)
  local coord = self.coordinators[school]
  if type(coord) == "table" then
    coord = coord[2]
  end
  local coord_str = self.all_staff[coord].name.." <"..self.all_staff[coord].login_id.."@adelaide.edu.au>"
  self:info("Coordinator: "..coord_str)

  self.reminders = self.reminders or {}
  self.reminders[acad_name] = self.reminders[acad_name] or {}

  self.reminders[acad_name].details = staff_lookup

  self.reminders[acad_name].marking = self.reminders[acad_name].marking or {}
  if self.reminders[acad_name].marking[assm] == nil then
    self.reminders[acad_name].marking[assm] = {}
    self.reminders[acad_name].marking[assm].supervisor = ""
    self.reminders[acad_name].marking[assm].moderator  = ""
    self.reminders[acad_name].marking[assm].projects   = {}
    self.reminders[acad_name].marking[assm].assessment = self.assign_name_colloq
    self.reminders[acad_name].marking[assm].courseid   = self.courseid
    self.reminders[acad_name].marking[assm].school     = school
    self.reminders[acad_name].marking[assm].coordinator = coord_str
    self.reminders[acad_name].marking[assm].coord_id   = coord
  end

  local assess_student_str
  if assign_grouped then
    assess_student_str = ""
  else
    assess_student_str =
      j.user.name .. " (student ID: "..j.user.login_id..")\n" ..
      "   Project title: "
  end
  local assess_proj_str = j.metadata.proj_title .. " (project ID: " .. j.metadata.proj_id .. ") \n"

  local not_submitted_str = ""
  local remind_submitted_str = ""
  local remind_url_str = ""
  if self.assign_has_submission then
    not_submitted_str = "~~ NOT SUBMITTED YET ~~"
  end
  j.metadata.submitted_at = j.submitted_at or not_submitted_str
  if j.metadata.submitted_at == not_submitted_str then
    j.metadata.since = "N/A"
    if self.assign_has_submission then
      remind_url_str = "   SpeedGrader link: <NOT YET SUBMITTED>\n"
    else
      remind_url_str = "   SpeedGrader link: <" .. j.metadata.url .. ">\n"
    end
  else
    local df = Date.Format()
    j.metadata.since = tostring(Date{} - df:parse(j.metadata.submitted_at))
    local nicedate = Date.Format("yyyy-mm-dd HH:MM"):tostring(df:parse(j.metadata.submitted_at))
    remind_submitted_str = "   Submitted: " .. nicedate .. " (".. j.metadata.since .."ago)\n"
    if self.assign_has_submission then
      remind_url_str = "   SpeedGrader link: <" .. j.metadata.url .. ">\n"
    end
  end

  self.reminders[acad_name].marking[assm][sup_or_mod] =
    self.reminders[acad_name].marking[assm][sup_or_mod] .. "\n" ..
    " • " .. assess_student_str .. assess_proj_str .. remind_submitted_str .. remind_url_str

  local N = #self.reminders[acad_name].marking[assm].projects
  self.reminders[acad_name].marking[assm].projects[N+1] = j.metadata

  self:info(">================")

end






function proj:assessor_reminder(remind_check,subm1,subm2,args)

  self:assessor_reminder_collect(subm1,subm2)
  self:assessor_reminder_send(remind_check,args)

end


function proj:assessor_reminder_collect(subm1,subm2)

  self.reminders = self.reminders or {}

  if subm2 then
    for _,j in pairs(subm1) do
     if not(j.metadata==nil) then
       if not(j.metadata.supervisor_mark) then
         self:message_reminder_add(j,{whom="supervisor"})
       end
     end
    end
    for _,j in pairs(subm2) do
     if not(j.metadata==nil) then
       if not(j.metadata.moderator_mark) then
         self:message_reminder_add(j,{whom="moderator"})
       end
     end
    end
  else
    for _,j in pairs(subm1) do
      if not(next(j) == nil) then
        if not(j.grade) then
           self:message_reminder_add(j,{whom="supervisor"})
        end
      end
    end
  end

end




function proj:assessor_reminder_summarise()

  args = args or {}
  local only_them = args.only_them


  for acad_name,assr in pairs(self.reminders) do

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



function proj:assessor_reminder_send(remind_check,args)

  args = args or {}
  local only_them = args.only_them
  local additional_message = args.lede

  local assm = self.deliverable
  if assm == nil then
    error('Missing deliverable; e.g.:\n\nproj:set_deliverable("final")')
  end

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

  for acad_name,assr in pairs(self.reminders) do

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
      recip_lookup[assm.coord_id] = true

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



function proj:assessor_reminder_export(csvfile)

  print("Constructing reminders list:  "..csvfile)
  file.copy(csvfile,(csvfile..".backup"))
  local ff = io.output(csvfile)

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

  io.write(csvrow{
    "Sortable name","Name","UoA ID","Email","School",
    "Coordinator","Assessment","Role","Since submission","Project ID","Project title",
    "Speedgrader URL"})

  for k,v in pairs(self.reminders) do
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
          prj.proj_id,
          qq(prj.proj_title),
          prj.url
        })
      end
    end
  end

  io.close(ff)
  print("...done.")

end



return proj
