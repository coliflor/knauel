-- helper functions
local helper = {}

function helper.dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. helper.dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function helper.print(o)
	 print(helper.dump(o))
end

return helper
