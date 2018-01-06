require("strict")
local hook = require("Hook")
local dbg  = require("Dbg"):dbg()

local mapT =
{
   grouped = {
      ['/Compilers/'] = "Your compiler dependent modules",
      ['/Core.*']     = "Core Modules",
   },
}



function avail_hook(t)
   local availStyle = masterTbl().availStyle
   dbg.print{"avail hook called: availStyle: ",availStyle,"\n"}
   local styleT     = mapT[availStyle]
   if (not availStyle or availStyle == "system" or styleT == nil) then
      return
   end

   for k,v in pairs(t) do
      for pat,label in pairs(styleT) do
         if (k:find(pat)) then
            t[k] = label
            break
         end
      end
   end
end


hook.register("avail",avail_hook)


