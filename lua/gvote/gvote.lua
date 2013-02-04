if GVote then return end
GVote = GVote or {}

include ("glib/glib.lua")
include ("gooey/gooey.lua")

GLib.Initialize ("GVote", GVote)
GLib.AddCSLuaPackFile ("autorun/gvote.lua")
GLib.AddCSLuaPackFolderRecursive ("gvote")
GLib.AddCSLuaPackSystem ("GVote")

include ("vote.lua")
include ("voteendreason.lua")
include ("votenetworker.lua")
include ("votereceiver.lua")

include ("votetypes.lua")
include ("votequeue.lua")

include ("api.lua")
include ("chatcommands.lua")

if CLIENT then
	GVote.IncludeDirectory ("gvote/ui")
end

GVote.AddReloadCommand ("gvote/gvote.lua", "gvote", "GVote")