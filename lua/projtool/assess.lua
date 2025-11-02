

local csv     = require("csv")
-- local pretty  = require("pl.pretty")
local path    = require("pl.path")
-- local file    = require("pl.file")
-- local canvas  = require("canvas-lms")


local proj = {}



function proj:get_submissions(get_bool,args)

  args = args or {}
  if args.only_submitted == nil then
    args.only_submitted = true -- default
  end

  local subm
  -- we just ask for everything; if it's not there it won't be returned:
  subm = self:get_assignment(get_bool,self.assign_name_canvas,{grouped=true,include={"provisional_grades","group","user","rubric_assessment","submission_comments"}},args)
  subm = self:subm_remove(subm)

  return subm

end

function proj:subm_remove(subm)
  local verbose = self.verbose > 0
  local subout = {}
  local to_keep
  if verbose then print("Number of submissions: "..#subm) end
  for i,j in ipairs(subm) do
    to_keep = true
    j.user.sis_user_id = j.user.sis_user_id or ""
    if string.sub(j.user.sis_user_id,1,2) == "sv" then
      if verbose then print(" - Academic student view (SV) user: "..subm[i].user.name) end
      to_keep = false
    end
    if j.user.sis_user_id == nil then -- maybe check against a black list, or similar
      if verbose then print(" - Student has no login id: "..subm[i].user.name) end
      to_keep = false
    end
    if j.excused then
      if verbose then print(" - Student excused: "..subm[i].user.name) end
      to_keep = false
    end
    if to_keep then
      subout[#subout+1] = j
    end
  end
  if verbose then print("Number of valid submissions: "..#subout) end
  return subout
end



function proj:add_assessment_metadata(canvas_subm,verbose)

  verbose = verbose or false
  self.marks_csv = self.marks_csv or string.lower("csv/"..self.cohort.."-marks-"..self.deliverable..".csv")

  local resolve = {}
  if path.exists(self.marks_csv) then
    print("Loading marks resolutions from: "..self.marks_csv)
    local f = csv.open(self.marks_csv,{header=true})
    for fields in f:lines() do
      local ind = 'USERID'
      if self.assign_grouped then
        ind = 'PROJID'
      end
      if fields[ind] then
        resolve[fields[ind]]  = fields['RESOLVED']
      end
    end
  end

  local subm = {}
  for i,subm_entry in ipairs(canvas_subm) do

    local student_id   = subm_entry.user.sis_user_id
    if student_id == "" then -- sometimes this entry is not populated (grr)
      student_id   = string.sub(subm_entry.user.login_id,2) -- "a1063023" -> "1063023"

    end
    local student_name = subm_entry.user.name
    local ind          = self.student_ind[student_id]

    if verbose then
      print(i..": Processing submission/assessment by: '"..student_name.."' ID: "..student_id)
    end

    if ind then

      local hash_index
      local group_id = self.proj_data[ind].proj_id
      if self.assign_grouped then
        hash_index = group_id
      else
        hash_index = student_id
      end

      subm[hash_index] = subm_entry

      local url = self.url .. self.course_prefix ..
                  "gradebook/speed_grader?assignment_id=" .. subm_entry.assignment_id ..
                  "&student_id=" .. subm_entry.user_id
      subm[hash_index].metadata = {}
      for kk,vv in pairs(self.proj_data[ind]) do
        subm[hash_index].metadata[kk] = vv
      end
      subm[hash_index].metadata.url         = url
      subm[hash_index].metadata.resolve     = resolve[hash_index]  or ""
    else
      print("WARNING!!! No metadata found for submission by: "..student_name.." (ID: "..student_id..")")
    end

  end

  return subm
end




return proj
