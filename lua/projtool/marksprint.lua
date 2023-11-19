
local path     = require("pl.path")
local pretty   = require("pl.pretty")

local proj = {}

  local function texencode(str)
    str = str:gsub("&","\\&")
    str = str:gsub("_","\\_")
    str = str:gsub("%^","\\^")
    str = str:gsub("%%","\\%%")
    str = str:gsub("#","\\#")
    str = str:gsub("{","\\{")
    str = str:gsub("}","\\}")
    return str
  end

proj.summarise_marks = function(self,assign_data,assign_data2,args)

  self:get_assignments()

  local assm_rubric
  local entr, tabl = next(assign_data)
  aid = tabl.assignment_id
  for i,v in pairs(self.assignments) do
    if v.id == aid then
      assm_rubric = v.rubric
      break
    end
  end

  args = args or {}
  local who = args.who
  local group = args.group
  local prefix = args.prefix or "marks-"
  local runs = args.runs or 2
  local subpath = args.path or "assessments"
  if not (subpath:sub(-1,-1) == "/") then
    subpath = subpath.."/"
  end
  local buildpath = subpath.."build/"
  local cc = 0

  if not path.exists(subpath) then
    os.execute("mkdir "..subpath)
  end
  if not path.exists(subpath.."build") then
    os.execute("mkdir "..subpath.."build")
  end

  for i,j in pairs(assign_data) do
    cc = cc+1

    if (j.user.name == (who or j.user.name)) and
       (j.metadata.proj_id == (group or j.metadata.proj_id)) then

      local filename = prefix..j.metadata.proj_id

      if j.provisional_grades == nil then
        error("No provisional grades? This shouldn't happen.")
      end

      assign_data[i].marks = assign_data[i].marks or {}

      print("\n"..cc..". Student: "..j.user.name)
      print("Project ID: "..j.metadata.proj_id)
      print("Project: "..j.metadata.proj_title)
      print("Supervisor: "..j.metadata.supervisor)
      print("Moderator: "..j.metadata.moderator)
      print("URL: "..j.metadata.url)

      local ff = io.output(buildpath..filename..".tex")
      io.write [[
\def\NOBIB{}
\documentclass{willarticle}
\usepackage{longtable,booktabs,needspace,xcolor,colortbl}
\usepackage[margin=2cm,landscape]{geometry}
\usepackage{siunitx}
\def\SPLIT#1 #2 {%
  \textsc{\MakeLowercase{#1}} & \itshape
  \raggedright\arraybackslash\hangindent=0.8em\relax
}
\begin{document}
\begingroup
\parindent=0pt\relax
\Large
Faculty of Sciences, Engineering and Technology
\par
\Huge\fontspec{palatino-nova-titling}
ENG 4002 Honours Research Project
\par
\endgroup
\section*{%
]]
      io.write(self.assign_name_colloq .. " assessment summary")
      io.write [[
}
]]
      io.write(string.format([[
\begin{description}
\item[Project title] %s
\item[Project ID] %s
\item[Submitting student] %s
\item[Supervisor] %s
\item[Moderator] %s
\end{description}
\newpage
]]
  , texencode(j.metadata.proj_title)
  , j.metadata.proj_id
  , j.user.name
  , j.metadata.supervisor
  , j.metadata.moderator
))

      for _,prov_grade in ipairs(assign_data[i].provisional_grades) do
        self:assessor_print(assm_rubric,prov_grade)
      end
      for _,prov_grade in ipairs(assign_data2[i].provisional_grades) do
        self:assessor_print(assm_rubric,prov_grade)
      end
      io.write [[
\end{document}
]]
      io.close(ff)
      for _ = 1,runs do
        os.execute("cd "..buildpath.."; /Library/TeX/texbin/xelatex -interaction=batchmode "..filename.." ;")
      end
      os.execute("cp "..buildpath.."/"..filename..".pdf "..subpath.." ;")
    end
  end
end

proj.assessor_print = function(self,assm_rubric,prov_grade)

      local jd = prov_grade.rubric_assessments[#prov_grade.rubric_assessments]
      -- only take the last entry from an assessor

      if jd and (jd.score > 1) then

        io.write [[
\Needspace{0.6\textheight}
\subsection*{Assessor --- ]]
        io.write(jd.assessor_name)
        io.write [[
}
]]
        io.write [[
\begin{longtable}{llp{3.5cm}cp{16cm}}
\toprule
   &                   &       & {Points}  &  \\
\# & Category & Criterion   & {awarded} & Comments \\
\midrule
\endhead
]]
        for iid,jjd in ipairs(jd.data) do

          local descr = jjd.description
          if descr == "No Details" then
            descr = "---"
          end
          local comments = (jjd.comments or "")
          if comments == "" then
            comments = "---"
          end
          if iid > 1 then
            io.write("\\arrayrulecolor{lightgray}\\midrule\\arrayrulecolor{black}\n")
          end
          io.write(
              iid.."&"..
              "\\SPLIT "..texencode(assm_rubric[iid].description).."&"..
--              texencode(descr).."&"..
              (jjd.points or "").." / "..assm_rubric[iid].points.." &"..
              "\\raggedright\\arraybackslash\\parindent=1.8em\\relax "..texencode(comments)..
              "\\\\\n")
        end
        io.write("\\midrule\n"..
              "".."&&"..
              "\\textbf{Total}".."&"..
              "\\textbf{"..(jd.score or "").."} / 100".."&"..
              ""..
              "\\\\\n")

        io.write [[
\bottomrule
\end{longtable}
]]
        for _,jjd in ipairs(prov_grade.submission_comments) do
          if jd.assessor_name == jjd.author_name then
            io.write("\\subsubsection*{Comments}\n\\begin{minipage}{0.6\\textwidth}\n\\parskip=5pt\\parindent=0pt\\relax\n")
            local comment = (jjd.comment or "")
            io.write(texencode(comment))
            io.write("\\end{minipage}\n")
          end
        end
      end

end

return proj
