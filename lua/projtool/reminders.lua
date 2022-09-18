
local pretty  = require("pl.pretty")

local canvas = require("canvas-lms")
local proj = {}





function proj:message_reminder_add(j,args)

  self:info("<================ Adding reminder:")
  self:info("ID: " .. j.metadata.proj_id)
  self:info(j.metadata.proj_title)

  local sup_or_mod = args.whom
  local assign_grouped = args.grouped or self.assign_grouped or false
  local assm = self.deliverable

  local acad_name = j.metadata[sup_or_mod]
  local staff_lookup = self:staff_lookup(acad_name)

  self.reminders = self.reminders or {}
  self.reminders[acad_name] = self.reminders[acad_name] or {}
  self.reminders[acad_name].details = staff_lookup
  self.reminders[acad_name].marking = self.reminders[acad_name].marking or {}

  local school = j.metadata.school
  self:info("School: "..school)
  local coord = self.coordinators[school]
  if type(coord) == "table" then
    coord = coord[1]
  end
  local coord_str = self.all_staff[coord].name.." <"..self.all_staff[coord].login_id.."@adelaide.edu.au>"
  self:info("Coordinator: "..coord_str)

  if self.reminders[acad_name].marking[assm] == nil then
    self.reminders[acad_name].marking[assm] = {}
    self.reminders[acad_name].marking[assm].supervisor = ""
    self.reminders[acad_name].marking[assm].moderator  = ""
    self.reminders[acad_name].marking[assm].projects   = {}
    self.reminders[acad_name].marking[assm].assessment  = self.assign_name_colloq
    self.reminders[acad_name].marking[assm].school = school
    self.reminders[acad_name].marking[assm].coordinator = coord_str
  end

  local assess_str
  if assign_grouped then
    assess_str = ""
  else
    assess_str =
      j.user.name .. "\n" ..
      "   Project title: "
  end

  j.submitted_at = j.submitted_at or "NOT SUBMITTED YET"
  self.reminders[acad_name].marking[assm][sup_or_mod] = self.reminders[acad_name].marking[assm][sup_or_mod] .. "\n" ..
    " • " .. assess_str ..
    j.metadata.proj_title .. " (ID: " .. j.metadata.proj_id .. ") \n" ..
    "   Submitted: " .. j.submitted_at .. "\n" ..
    "   SpeedGrader link: <" .. j.metadata.url .. ">\n"

  local N = #self.reminders[acad_name].marking[assm].projects
  self.reminders[acad_name].marking[assm].projects[N+1] = j.metadata

  self:info(">================")

end






function proj:assessor_reminder(remind_check,subm1,subm2,args)

  self:assessor_reminder_collect(remind_check,subm1,subm2)
  self:assessor_reminder_send(remind_check,args)

end


function proj:assessor_reminder_collect(remind_check,subm1,subm2,args)

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
      if not(j.grade) then
         self:message_reminder_add(j,{whom="supervisor"})
      end
    end
  end

end


function proj:assessor_reminder_send(remind_check,args)

  args = args or {}
  local only_them = args.only_them

  local assm = self.deliverable
  if assm == nil then
    error('Missing deliverable; e.g.:\n\nproj:set_deliverable("final")')
  end

  local additional_message
  if remind_check then
    print("Add an intro message:")
    additional_message = io.read()
  else
    additional_message = "[[Additional message would go here.]]"
  end
  if not(additional_message == "") then
    additional_message = additional_message .. "\n\n"
  end

  local sup_lede = "\n# Supervisor assessment\n"
  local mod_lede = "\n# Moderator assessment\n"

  for acad_name,j in pairs(self.reminders) do

    print("MESSAGE: "..acad_name)
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

    local staff_lookup = self.all_staff[acad_name]
    if staff_lookup == nil then
      error("Staff member not found: "..acad_name)
    end
    local recip = { self.all_staff[acad_name].id }
    if self.coordinators then
      for i in pairs(j.school) do
        print("School: "..i)
        local coord = self.coordinators[i]
        if type(coord) == "table" then
          coord = coord[1]
        end
        print("Coordinator: "..coord)
        if self.all_staff[coord].id ~= self.all_staff[acad_name].id then
          recip[#recip+1] = self.all_staff[coord].id
        end
      end
    end

    if (only_them == nil) or (only_them == acad_name) then
      local this_body =
        salutation .. additional_message .. self.message[assm].body_opening .. body .. self.message.body_close .. self.message.signoff

      canvas:message_user(remind_check,{
        canvasid  = recip ,
        subject   = self.assign_name_colloq.." marking",
        body      = this_body
      })
    end


  end

end


return proj
