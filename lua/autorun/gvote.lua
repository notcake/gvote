if CLIENT and not file.Exists ("gvote/gvote.lua", "LCL") then return end
if CLIENT and not GetConVar ("sv_allowcslua"):GetBool () then return end
include ("gvote/gvote.lua")