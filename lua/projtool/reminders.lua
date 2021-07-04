
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

  local assess_str = ""
  if assign_grouped then
    assess_str = ""
  else
    assess_str =
      j.user.name .. "\n" ..
      "   Project title: "
  end

  markers_msg[acad_name].school[j.metadata.school] = true

  markers_msg[acad_name][sup_or_mod] = markers_msg[acad_name][sup_or_mod] .. "\n" ..
    " • " .. assess_str ..
    j.metadata.proj_title .. " (ID: " .. j.metadata.proj_id .. ") \n" ..
    "   Submitted: " .. j.submitted_at .. "\n" ..
    "   SpeedGrader link: <" .. j.metadata.url .. ">\n"

  return markers_msg
end




function proj:assessor_reminder_interim(remind_check,subm,only_them)

  local markers_msg = {}
  for i,j in pairs(subm) do
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
      recip[#recip+1] = self.all_staff[acad_name].id
      canvas:message_user(remind_check,{
        course    = canvas.courseid,
        canvasid  = recip ,
        subject   = self.assign_name_colloq.." marking",
        body      = salutation .. self.message.interim.body_opening .. body .. self.message.interim.body_close .. self.message.signoff
      })
    end

  end

end



function proj:assessor_reminder_prelim(remind_check,subm,only_them)

  local markers_msg = {}
  for i,j in pairs(subm) do
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
      local this_body =
        salutation ..
        self.message.prelim.body_opening ..
        body ..
        self.message.prelim.body_close ..
        self.message.signoff

      canvas:message_user(remind_check,{
        course    = canvas.courseid,
        canvasid  = self.all_staff[acad_name].id ,
        subject   = self.assign_name_colloq.." marking",
        body      = this_body
      })
    end

  end

end



function proj:assessor_reminder_final(remind_check,subm)

  local sup_lede = "\n# Supervisor assessment\n"
  local mod_lede = "\n# Moderator assessment\n"

  local markers_msg = {}

  for i,j in pairs(subm) do
   if not(j.metadata==nil) then
     if not(j.metadata.supervisor_mark) then
       markers_msg = self:message_reminder_add(j,markers_msg,{whom="supervisor",grouped=false})
     end
     if not(j.metadata.moderator_mark) then
       markers_msg = self:message_reminder_add(j,markers_msg,{whom="moderator",grouped=false})
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
      canvasid  = self.all_staff[acad_name].id ,
      subject   = self.assign_name_colloq.." marking",
      body      = salutation .. self.message.final.body_opening .. body .. self.message.final.body_close .. self.message.signoff
    })

  end

end


return proj
