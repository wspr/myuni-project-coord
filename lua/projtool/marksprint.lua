
--local pretty = require("pl.pretty")
local proj = {}

function proj:print_marks(assign_data,args)

  local who = args.who
  local cc = 0

  for i,j in pairs(assign_data) do
    cc = cc+1

    if j.user.name == who then

      if j.provisional_grades == nil then
        error("No provisional grades? This shouldn't happen.")
      end

      assign_data[i].marks = assign_data[i].marks or {}

      print("\n"..cc..". Student: "..j.user.name)
      print("Project: "..j.metadata.proj_title)
      print("Supervisor: "..j.metadata.supervisor)
      print("Moderator: "..j.metadata.moderator)
      print("URL: "..j.metadata.url)

      local ff = io.output("assessments/"..j.user.login_id..".tex")
      io.write [[
\documentclass{article}
\usepackage{booktabs}
\usepackage[margin=2.5cm]{geometry}
\usepackage{siunitx}
\begin{document}
\section*{Final paper assessment ---
]]
      io.write(j.user.name)
      io.write [[
}
]]

      for _,prov_grade in ipairs(j.provisional_grades) do

        local jd = prov_grade.rubric_assessments[#prov_grade.rubric_assessments]
        -- only take the last entry from an assessor

        io.write [[
\subsection*{Assessor ---
]]
        io.write(jd.assessor_name)
        io.write [[
}
]]
        io.write [[
\begin{tabular}{llSp{9cm}}
\toprule
\# & Rubric entry & Points & Comments \\
\midrule
]]
        for iid,jjd in ipairs(jd.data) do
          io.write(
              iid.."&"..
              jjd.description.."&"..
              (jjd.points or "").."&"..
              (jjd.comments or "")..
              "\\\\\n")
        end
        io.write("\\midrule\n"..
              "".."&"..
              "\\textbf{Total}".."&"..
              "\\textbf{"..(jd.score).."}".."&"..
              ""..
              "\\\\\n")

        io.write [[
\bottomrule
\end{tabular}
]]
        for _,jjd in ipairs(prov_grade.submission_comments) do
          if jd.assessor_name == jjd.author_name then
            io.write("\\subsubsection*{Comments}")
            io.write(jjd.comment)
          end
        end
      end
      io.write [[
\end{document}
]]
      io.close(ff)
    end
  end
end


return proj
