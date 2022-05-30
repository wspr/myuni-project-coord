

local csv     = require("csv")
local pretty  = require("pl.pretty")
local path    = require("pl.path")
local canvas  = require("canvas-lms")


local proj = {}





function proj:dl_check(opt,str)

  local check_bool = false
  if opt.download == "ask" then
    print(str .. " Type y to do so:")
    if io.read() == "y" then
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





function proj:get_submissions(get_bool,cvs)

  local subm
  if self.assign_grouped then
    subm = canvas:get_assignment(get_bool,self.assign_name_canvas,{grouped=true,include={"group","user","rubric_assessment","submission_comments"}})
  else
    subm = canvas:get_assignment(get_bool,self.assign_name_canvas,{include={"provisional_grades","user","rubric_assessment","submission_comments"}})
  end
  subm = self:subm_remove(subm)

  if cvs then
    self.assignment_setup = cvs.assignments[self.assign_name_canvas]
  end

  return subm

end



function proj:subm_remove(subm)
  local subout = {}
  local to_keep = true
  for i,j in ipairs(subm) do
    if string.sub(j.user.sis_user_id,1,2) == "sv" then
      print(" - Academic student view (SV) user: "..subm[i].user.name)
      to_keep = false
    end
    if j.user.sis_user_id == nil then -- maybe check against a black list, or similar
      print(" - Student has no login id: "..subm[i].user.name)
      to_keep = false
    end
    if j.excused then
      print(" - Student excused: "..subm[i].user.name)
      to_keep = false
    end
    if to_keep then
      subout[#subout+1] = j
    end
  end
  return subout
end







return proj
