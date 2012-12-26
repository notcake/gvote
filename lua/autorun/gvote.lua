if SERVER or
   file.Exists ("gvote/gvote.lua", "LUA") or
   file.Exists ("gvote/gvote.lua", "LCL") and GetConVar ("sv_allowcslua"):GetBool () then
	include ("gvote/gvote.lua")
end