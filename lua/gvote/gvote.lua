if GVote then return end
GVote = GVote or {}

include ("glib/glib.lua")

GLib.Initialize ("GVote", GVote)
GLib.AddCSLuaPackFile ("autorun/gvote.lua")
GLib.AddCSLuaPackFolderRecursive ("gvote")
GLib.AddCSLuaPackSystem ("GVote")

include ("vote.lua")
include ("votenetworker.lua")
include ("votereceiver.lua")

include ("votetypes.lua")
include ("votequeue.lua")

if CLIENT then
	include ("gooey/gooey.lua")
	GVote.IncludeDirectory ("gvote/ui")
end

GVote.AddReloadCommand ("gvote/gvote.lua", "gvote", "GVote")

if SERVER then
	timer.Simple (1,
		function ()
			if not aowl then return end
			aowl.AddCommand ("vote",
				function (ply, _, question, ...)
					if not question then
						ply:ChatPrint ("You need to provide a question and at least 2 choices.")
						return
					end
					
					local choices = {...}
					if #choices < 2 then
						ply:ChatPrint ("You need to provide at least 2 choices.")
						return
					end
					
					local vote = GVote.VoteTypes:Create ("SingleChoiceVote")
					if not vote then return end
					vote:SetText (question)
					
					for i = 1, #choices do
						vote:AddChoice (tostring (choices [i]))
					end
					
					GVote.VoteQueue:Enqueue (vote)
				end,
				"developers"
			)
		end
	)
end