

local csv     = require("csv")
local pretty  = require("pl.pretty")
local path    = require("pl.path")
local file    = require("pl.file")
local canvas  = require("canvas-lms")


local proj = {}




function proj:dl_check(opt,str)
  opt.download = opt.download or "ask"
  local check_bool = false
  if opt.download == "ask" then
    print(str .. " Type y to do so:")
    if io.read() == "y" then
      check_bool = true
    end
  elseif (opt.download == "always") or (opt.download == true) then
    print(str .. " User requested 'Always'.")
    check_bool = true
  elseif (opt.download == "never") or (opt.download == false) then
    print(str .. " User requested 'Never'.")
  else
    error("Interface: { download = 'ask' (default) | 'always' | 'never' } ")
  end
  return check_bool
end







function proj:get_submissions(get_bool,args)

  args = args or {}
  if args.only_submitted == nil then
    args.only_submitted = false -- default
  end

  local subm
  if self.assign_grouped then
    subm = self:get_assignment(get_bool,self.assign_name_canvas,{grouped=true,include={"group","user","rubric_assessment","submission_comments"}},args)
  else
    subm = self:get_assignment(get_bool,self.assign_name_canvas,{include={"provisional_grades","user","rubric_assessment","submission_comments"}},args)
  end
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

  local resolve = {}
  local override = {}
  local comments = {}
  if path.exists(self.marks_csv) then
    print("Loading marks resolutions and comments from: "..self.marks_csv)
    local f = csv.open(self.marks_csv,{header=true})
    for fields in f:lines() do
      local ind = 'USERID'
      if self.assign_grouped then
        ind = 'PROJID'
      end
      if fields[ind] then
        resolve[fields[ind]]  = fields['RESOLVED']
        override[fields[ind]] = fields['OVERRIDE']
        comments[fields[ind]] = fields['COMMENTS']
      end
    end
  end

  local subm = {}
  for i,subm_entry in ipairs(canvas_subm) do
    if verbose then
      print(i..": Processing submission by: "..subm_entry.user.name)
    end

    local student_id   = subm_entry.user.sis_user_id
    local student_name = subm_entry.user.name
    local ind = self.student_ind[student_id]

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
      subm[hash_index].metadata.proj_id     = self.proj_data[ind].proj_id
      subm[hash_index].metadata.proj_title  = self.proj_data[ind].proj_title
      subm[hash_index].metadata.supervisor  = self.proj_data[ind].supervisor
      subm[hash_index].metadata.moderator   = self.proj_data[ind].moderator
      subm[hash_index].metadata.supervisor_id  = self.proj_data[ind].supervisor_id
      subm[hash_index].metadata.moderator_id   = self.proj_data[ind].moderator_id
      subm[hash_index].metadata.school      = self.proj_data[ind].school
      subm[hash_index].metadata.url         = url
      subm[hash_index].metadata.resolve     = resolve[hash_index]  or ""
      subm[hash_index].metadata.override    = override[hash_index] or ""
      subm[hash_index].metadata.comments    = comments[hash_index] or ""
    else
      print("WARNING!!! No metadata found for submission by: "..student_name.." (ID: "..student_id..")")
    end

  end

  return subm
end






function proj:export_csv_marks_moderated(subm,arg)

  local weightings = arg.weightings or {0.5,0.5}

  file.copy(self.marks_csv,(self.marks_csv..".backup"))
  local ff = io.output(self.marks_csv)
  io.write("INDEX,USERID,NAME,SCHOOL,PROJID,TITLE,MARK,DIFF,RESOLVED,OVERRIDE,COMMENTS,SIMILARITY,SUPERVISOR,SUPMARK,MODERATOR,MODMARK,SUPID,MODID,SUPURL,MODURL,ASSESSOR1,SCORE1,ASSESSOR2,SCORE2,ASSESSOR3,SCORE3,ASSESSOR4,SCORE4,ASSESSOR5,SCORE5,\n")

  local nameind = {}
  for i in pairs(subm) do
    nameind[#nameind+1] = i
  end
  table.sort(nameind,
    function(n1,n2)
      local res
      if (subm[n1].metadata.school == subm[n2].metadata.school) and (subm[n1].metadata.supervisor == subm[n2].metadata.supervisor) then
        res = (subm[n1].metadata.proj_id < subm[n2].metadata.proj_id)
      elseif (subm[n1].metadata.school == subm[n2].metadata.school) then
        res = (subm[n1].metadata.supervisor < subm[n2].metadata.supervisor)
      else
        res = (subm[n1].metadata.school < subm[n2].metadata.school)
      end
      return res
    end
  )

  for cc,n in ipairs(nameind) do
    local j = subm[n]
    j.metadata = j.metadata or {}

    local mark, diff
    if j.metadata.supervisor_mark and j.metadata.moderator_mark then
      mark = weightings[1]*j.metadata.supervisor_mark + weightings[2]*j.metadata.moderator_mark
      diff = j.metadata.supervisor_mark-j.metadata.moderator_mark
    end

    local similarity_score = ""
    if j.turnitin_data then
      for k,v in pairs(j.turnitin_data) do
        if v.similarity_score then
          if similarity_score == "" then
            similarity_score = v.similarity_score
          else
            similarity_score = similarity_score .. ", " .. v.similarity_score
          end
        end
      end
    end

    local writestr = cc..","..
      (j.user.sis_user_id or "")..","..
      (j.user.name or "")..","..
      (j.metadata.school or "")..","..
      (j.metadata.proj_id or "")..","..
      "\"'"..(j.metadata.proj_title or "").."'\""..","..
      (mark or "")..","..
      (diff or "")..","..
      (j.metadata.resolve  or "")..","..
      (j.metadata.override or "")..","..
      (j.metadata.comments or "")..","..
      (similarity_score)..","..
      "\""..(j.metadata.supervisor or "").."\""..","..
      (j.metadata.supervisor_mark or "")..","..
      "\""..(j.metadata.moderator or "").."\""..","..
      (j.metadata.moderator_mark or "")..","..
      (j.metadata.supervisor_id or "")..","..
      (j.metadata.moderator_id or "")..","..
      (j.metadata.supervisor_url or "")..","..
      (j.metadata.moderator_url or "")..","

    if j.metadata.super_marks then
      for kk,vv in pairs(j.metadata.super_marks) do
        writestr = writestr.."\""..kk.."\","..vv..","
      end
    end
    if j.metadata.moder_marks then
      for kk,vv in pairs(j.metadata.moder_marks) do
        writestr = writestr.."\""..kk.."\","..vv..","
      end
    end

    io.write(writestr.."\n")
  end
  io.close(ff)
  print("\n\n==================\nMarks CSV written:\n    "..self.marks_csv)

end



function proj:export_csv_marks(subm)

  local nameind = {}
  for i in pairs(subm) do
    nameind[#nameind+1] = i
  end
  table.sort(nameind,function(n1,n2)
    local res
    if (subm[n1].metadata.school == subm[n2].metadata.school) and (subm[n1].metadata.supervisor == subm[n2].metadata.supervisor) then
      res = (subm[n1].metadata.proj_id < subm[n2].metadata.proj_id)
    elseif (subm[n1].metadata.school == subm[n2].metadata.school) then
      res = (subm[n1].metadata.supervisor < subm[n2].metadata.supervisor)
    else
      res = (subm[n1].metadata.school < subm[n2].metadata.school)
    end
    return res
  end)

  print("Writing marks to file: '"..self.marks_csv.."'...")
  file.copy(self.marks_csv,(self.marks_csv..".backup"))
  local ff = io.output(self.marks_csv)
  io.write("INDEX,USERID,NAME,SCHOOL,PROJID,TITLE,SUPERVISOR,MARK,URL\n")

  for cc,n in ipairs(nameind) do
    local j = subm[n]

    j.metadata = j.metadata or {}
    local writestr = cc..","..
      (j.user.sis_user_id or "")..","..
      (j.user.name or "")..","..
      (j.metadata.school or "")..","..
      (j.metadata.proj_id or "")..","..
      "\"'"..(j.metadata.proj_title or "").."'\""..","..
      "\""..(j.metadata.supervisor or "").."\""..","..
      (j.grade or "")..","..
      (j.metadata.url or "")

    if not(j.grade == "-1") then
      io.write(writestr.."\n")
	end
  end

  io.close(ff)
  print("...done.")

end





return proj
