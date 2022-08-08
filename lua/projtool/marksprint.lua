
local path   = require("pl.path")

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

function proj:summarise_marks(assign_data,assign_data2,args)

  args = args or {}
  local who = args.who
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

    if j.user.name == (who or j.user.name) then

      local filename = j.metadata.proj_id.."-"..j.user.login_id.."-rubrics"

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
\documentclass{article}
\usepackage{longtable,booktabs,needspace}
\usepackage[margin=2.5cm,landscape]{geometry}
\usepackage{siunitx}
\begin{document}
\section*{%
]]
      io.write(self.assign_name_colloq .. " assessment summary")
      io.write [[
}
]]
      io.write(string.format([[
\begin{description}
\item[School] %s
\item[Project ID] %s
\item[Project title] %s
\item[Submitting student] %s
\item[Supervisor] %s
\item[Moderator] %s
\end{description}
\newpage
]]
  , j.metadata.school
  , j.metadata.proj_id
  , texencode(j.metadata.proj_title)
  , j.user.name
  , j.metadata.supervisor
  , j.metadata.moderator
))

      for _,prov_grade in ipairs(assign_data[i].provisional_grades) do
        self:assessor_print(prov_grade)
      end
      for _,prov_grade in ipairs(assign_data2[i].provisional_grades) do
        self:assessor_print(prov_grade)
      end
      io.write [[
\end{document}
]]
      io.close(ff)
      for _ = 1,runs do
        os.execute("cd "..buildpath.."; /Library/TeX/texbin/pdflatex "..filename.." ;")
      end
      os.execute("cp "..buildpath.."/"..filename..".pdf "..subpath.." ;")
    end
  end
end

function proj:assessor_print(prov_grade)

      local jd = prov_grade.rubric_assessments[#prov_grade.rubric_assessments]
      -- only take the last entry from an assessor

      if jd then

        io.write [[
\Needspace{0.4\textheight}
\subsection*{Assessor ---
]]
        io.write(jd.assessor_name)
        io.write [[
}
]]
        io.write [[
\begin{longtable}{lllSp{9cm}}
\toprule
\# & Rubric entry & Band awarded & Points & Comments \\
\midrule
\endhead
]]
        for iid,jjd in ipairs(jd.data) do
          local descr = jjd.description
          if descr == "No description" then
            descr = "---"
          end
          local comments = (jjd.comments or "")
          if comments == "" then
            comments = "[none]"
          end
          io.write(
              iid.."&"..
              texencode(self.assignment_setup.rubric[iid].description).."&"..
              texencode(descr).."&"..
              (jjd.points or "").."&"..
              texencode(comments)..
              "\\\\\n")
        end
        io.write("\\midrule\n"..
              "".."&&"..
              "\\textbf{Total}".."&"..
              "\\textbf{"..(jd.score or "").."}".."&"..
              ""..
              "\\\\\n")

        io.write [[
\bottomrule
\end{longtable}
]]
        for _,jjd in ipairs(prov_grade.submission_comments) do
          if jd.assessor_name == jjd.author_name then
            io.write("\\subsubsection*{Comments}\\begingroup\\parskip=5pt\\parindent=0pt")
            local comment = (jjd.comment or "")
            io.write(texencode(comment))
            io.write("\\subsubsection*{Comments}\\endgroup")
          end
        end
      end

end

return proj
