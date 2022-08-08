
local pretty  = require("pl.pretty")

local canvas = require("canvas-lms")
local proj = {}





function proj:message_reminder_add(j,markers_msg,args)

  local sup_or_mod = args.whom
  local assign_grouped = args.grouped or false

  local acad_name = j.metadata[sup_or_mod]

  if markers_msg[acad_name] == nil then
    markers_msg[acad_name] = {}
    markers_msg[acad_name].supervisor = ""
    markers_msg[acad_name].moderator  = ""
    markers_msg[acad_name].school = {}
  end

  local assess_str
  if assign_grouped then
    assess_str = ""
  else
    assess_str =
      j.user.name .. "\n" ..
      "   Project title: "
  end

  markers_msg[acad_name].school[j.metadata.school] = true

  j.submitted_at = j.submitted_at or "NOT SUBMITTED YET"
  markers_msg[acad_name][sup_or_mod] = markers_msg[acad_name][sup_or_mod] .. "\n" ..
    " • " .. assess_str ..
    j.metadata.proj_title .. " (ID: " .. j.metadata.proj_id .. ") \n" ..
    "   Submitted: " .. j.submitted_at .. "\n" ..
    "   SpeedGrader link: <" .. j.metadata.url .. ">\n"

  return markers_msg
end




function proj:assessor_reminder_interim(remind_check,subm,only_them)

  local markers_msg = {}
  for _,j in pairs(subm) do
    if not(j.grade) then
      markers_msg = self:message_reminder_add(j,markers_msg,{whom="supervisor",grouped=false})
    end
  end

  for acad_name,j in pairs(markers_msg) do

    local salutation = "Dear " .. acad_name .. ",\n\n"
    local body = j.supervisor

    local proceed = false
    if only_them == nil then
      proceed = true
    else
      if acad_name == only_them then
        proceed = true
      end
    end
    if proceed then
      local recip = {}
      for i in pairs(j.school) do
        print("School: "..i)
        local coord = self.coordinators[i]
        print("Coordinator: "..coord)
        recip[#recip+1] = self.all_staff[coord].id
      end
      if self.all_staff[acad_name].id == nil then
        error("Assessor '"..acad_name.."' not found in staff list.")
      end
      recip[#recip+1] = self.all_staff[acad_name].id
      canvas:message_user(remind_check,{
        canvasid  = recip ,
        subject   = self.assign_name_colloq.." marking",
        body      = salutation .. self.message.interim.body_opening .. body .. self.message.body_close .. self.message.signoff
      })
    end

  end

end



function proj:assessor_reminder_prelim(remind_check,subm,only_them)

  local markers_msg = {}
  for _,j in pairs(subm) do
    if not(j.grade) then
      markers_msg = self:message_reminder_add(j,markers_msg,{whom="supervisor",grouped=true})
    end
  end

  for acad_name,j in pairs(markers_msg) do

    local salutation = "Dear " .. acad_name .. ",\n\n"
    local body = j.supervisor

    local proceed = false
    if only_them == nil then
      proceed = true
    else
      if acad_name == only_them then
        proceed = true
      end
    end
    if proceed then
      local recip = {}
      for i in pairs(j.school) do
        print("School: "..i)
        pretty.dump(self.coordinators)
        local coord = self.coordinators[i]
        print("Coordinator: "..coord)
--        recip[#recip+1] = self.all_staff[coord].id
      end
      if self.all_staff[acad_name].id == nil then
        error("Assessor '"..acad_name.."' not found in staff list.")
      end
      recip[#recip+1] = self.all_staff[acad_name].id
      local this_body =
        salutation ..
        self.message.prelim.body_opening ..
        body ..
        self.message.body_close ..
        self.message.signoff

      canvas:message_user(remind_check,{
        canvasid  = recip ,
        subject   = self.assign_name_colloq.." marking",
        body      = this_body
      })
    end

  end

end



function proj:assessor_reminder_plan(remind_check,subm,only_them)

  local markers_msg = {}
  for _,j in pairs(subm) do
    if not(j.grade) then
      markers_msg = self:message_reminder_add(j,markers_msg,{whom="supervisor",grouped=true})
    end
  end

  for acad_name,j in pairs(markers_msg) do

    local salutation = "Dear " .. acad_name .. ",\n\n"
    local body = j.supervisor

    local proceed = false
    if only_them == nil then
      proceed = true
    else
      if acad_name == only_them then
        proceed = true
      end
    end
    if proceed then
      local recip = {}
      for i in pairs(j.school) do
        print("School: "..i)
        pretty.dump(self.coordinators)
        local coord = self.coordinators[i]
        print("Coordinator: "..coord)
        recip[#recip+1] = self.all_staff[coord].id
      end
      if self.all_staff[acad_name].id == nil then
        error("Assessor '"..acad_name.."' not found in staff list.")
      end
      recip[#recip+1] = self.all_staff[acad_name].id
      local this_body =
        salutation ..
        self.message.plan.body_opening ..
        body ..
        self.message.body_close ..
        self.message.signoff

      canvas:message_user(remind_check,{
        canvasid  = recip ,
        subject   = self.assign_name_colloq.." marking" ,
        body      = this_body ,
      })
    end

  end

end



function proj:assessor_reminder_final(remind_check,subm1,subm2,args)

  print("Add an intro message:")
  local additional_message = io.read()
  if not(additional_message == "") then
    additional_message = additional_message .. "\n\n"
  end

  local args = args or {}
  local only_them = args.only_them
  local grouped = args.grouped or false

  local sup_lede = "\n# Supervisor assessment\n"
  local mod_lede = "\n# Moderator assessment\n"

  local markers_msg = {}

  for _,j in pairs(subm1) do
   if not(j.metadata==nil) then
     if not(j.metadata.supervisor_mark) then
       markers_msg = self:message_reminder_add(j,markers_msg,{whom="supervisor",grouped=grouped})
     end
   end
  end
  for _,j in pairs(subm2) do
   if not(j.metadata==nil) then
     if not(j.metadata.moderator_mark) then
       markers_msg = self:message_reminder_add(j,markers_msg,{whom="moderator",grouped=grouped})
     end
   end
  end

  for acad_name,j in pairs(markers_msg) do

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

    local recip = { self.all_staff[acad_name].id }
    if self.coordinators then
      for i in pairs(j.school) do
        print("School: "..i)
        local coord = self.coordinators[i]
        print("Coordinator: "..coord)
        recip[#recip+1] = self.all_staff[coord].id
      end
    end

    local proceed = false
    if only_them == nil then
      proceed = true
    else
      if acad_name == only_them then
        proceed = true
      end
    end
    if proceed then
      local this_body =
        salutation .. additional_message .. self.message.final.body_opening .. body .. self.message.body_close .. self.message.signoff

      canvas:message_user(remind_check,{
        canvasid  = recip ,
        subject   = self.assign_name_colloq.." marking",
        body      = this_body
      })
    end


  end

end



function proj:assessor_reminder(remind_check,subm1,subm2,args)

  local assm = self.deliverable or "final"

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

  local args = args or {}
  local only_them = args.only_them
  local grouped = args.grouped or false

  local sup_lede = "\n# Supervisor assessment\n"
  local mod_lede = "\n# Moderator assessment\n"

  local markers_msg = {}

  if subm2 then
    for _,j in pairs(subm1) do
     if not(j.metadata==nil) then
       if not(j.metadata.supervisor_mark) then
         markers_msg = self:message_reminder_add(j,markers_msg,{whom="supervisor",grouped=grouped})
       end
     end
    end
    for _,j in pairs(subm2) do
     if not(j.metadata==nil) then
       if not(j.metadata.moderator_mark) then
         markers_msg = self:message_reminder_add(j,markers_msg,{whom="moderator",grouped=grouped})
       end
     end
    end
  else
    for _,j in pairs(subm) do
      if not(j.grade) then
        markers_msg = self:message_reminder_add(j,markers_msg,{whom="supervisor",grouped=grouped})
      end
    end
  end

  for acad_name,j in pairs(markers_msg) do

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
        print("Coordinator: "..coord)
        if self.all_staff[coord].id ~= self.all_staff[acad_name].id then
          recip[#recip+1] = self.all_staff[coord].id
        end
      end
    end

    local proceed = false
    if only_them == nil then
      proceed = true
    else
      if acad_name == only_them then
        proceed = true
      end
    end
    if proceed then
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
