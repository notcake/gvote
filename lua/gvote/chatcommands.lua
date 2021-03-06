function GVote.CanPlayerCreateVote (ply)
	if not ply or not ply:IsValid () then return true end
	if ply:IsAdmin () then return true end
	return false
end

if SERVER then
	local function registerAowlCommands ()
		aowl.AddCommand ("vote",
			function (ply, _, question, ...)
				local choices = {...}
				local currentVote = GVote.CurrentVote
				
				-- Only allow choice selection for SingleChoiceVotes
				if currentVote and
				   currentVote:GetType () ~= "SingleChoiceVote" then
					currentVote = nil
				end
				
				if #choices > 0 or not currentVote then
					-- Creating a vote
					if not GVote.CanPlayerCreateVote (ply) then
						ply:ChatPrint ("You are not allowed to create votes.")
						return
					end
					
					if not question then
						ply:ChatPrint ("You need to provide a question and at least 2 choices.")
						return
					end
					
					if #choices < 2 then
						ply:ChatPrint ("You need to provide at least 2 choices.")
						return
					end
					
					local ownerId = GLib.GetPlayerId (ply)
					if not ply or not ply:IsValid () then
						ownerId = GLib.GetServerId ()
					end
					
					GVote.Vote (question, ...)
						:SetOwnerId (ownerId)
				else
					-- Voting
					if currentVote:HasEnded () then
						ply:ChatPrint ("The current vote has ended!")
						return
					end
					
					local choiceIndex = tonumber (question)
					if not choiceIndex or not currentVote:GetChoice (choiceIndex) then
						ply:ChatPrint ("You did not provide a valid choice number!")
						return
					end
					
					local choiceId = currentVote:GetChoice (choiceIndex)
					currentVote:SetUserVote (GLib.GetPlayerId (ply), choiceId)
				end
			end,
			"players"
		)
		
		aowl.AddCommand ("voteadd",
			function (ply, args)
				if not GVote.CurrentVote then
					ply:ChatPrint ("No vote is in progress.")
					return
				end
				if not GVote.CurrentVote:IsMolestationAllowed () and
				   GLib.GetPlayerId (ply) ~= GVote.CurrentVote:GetOwnerId () then
					ply:ChatPrint ("Molestation of this vote is prohibited.")
					return
				end
				GVote.CurrentVote:AddChoice (args)
			end,
			"developers"
		)
		
		aowl.AddCommand ("voteaddtime",
			function (ply, args)
				if not GVote.CurrentVote then
					ply:ChatPrint ("No vote is in progress.")
					return
				end
				if not GVote.CurrentVote:IsMolestationAllowed () and
				   GLib.GetPlayerId (ply) ~= GVote.CurrentVote:GetOwnerId () then
					ply:ChatPrint ("Molestation of this vote is prohibited.")
					return
				end
				if GVote.CurrentVote:HasEnded () then
					ply:ChatPrint ("The current vote has ended!")
					return
				end
				local duration = tonumber (args)
				if not duration then
					ply:ChatPrint ("Invalid duration specified.")
					return
				end
				GVote.CurrentVote:AddTime (duration)
			end,
			"developers"
		)

		aowl.AddCommand ("voteabort",
			function (ply, args)
				if not GVote.CurrentVote then
					ply:ChatPrint ("No vote is in progress.")
					return
				end
				if not GVote.CurrentVote:IsMolestationAllowed () and
				   GLib.GetPlayerId (ply) ~= GVote.CurrentVote:GetOwnerId () then
					ply:ChatPrint ("Molestation of this vote is prohibited.")
					return
				end
				GVote.CurrentVote:Abort ()
			end,
			"developers"
		)
	end
	
	if aowl then
		registerAowlCommands ()
	else
		hook.Add ("AowlInitialized", "GVote", registerAowlCommands)
	end
end