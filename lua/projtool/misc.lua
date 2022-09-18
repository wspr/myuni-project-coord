

--local pretty  = require("pl.pretty")
local canvas  = require("canvas-lms")


local proj = {}



function proj:info(s)

  if canvas.verbose > 0 then
    print("INFO:  "..s)
  end

end





return proj
