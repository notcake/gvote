setmetatable (GVote, getmetatable (GVote) or {})
local self = getmetatable (GVote)

function self:__call (question, ...)
	GVote.Vote (question, ...)
end

function GVote.Vote (question, ...)
	local choices = {...}
	local callback = nil
	if type (choices [#choices]) == "function" then
		callback = choices [#choices]
		choices [#choices] = nil
	end
	
	local vote = GVote.VoteTypes:Create ("SingleChoiceVote")
	if not vote then return end
	vote:SetText (question)
	vote:AddChoices (choices)
	
	if callback then
		vote:AddEventListener ("VoteEnded",
			function ()
				local results = {}
				results [0] = {}
				for choiceId, choiceText in vote:GetChoiceEnumerator () do
					results [choiceId]   = {}
					results [choiceText] = results [choiceId]
				end
				local userVotes = {}
				
				for userId, choiceId in vote:GetUserVoteEnumerator () do
					userVotes [userId] = choiceId
					results [choiceId] [#results [choiceId] + 1] = userId
				end
				
				for userId, ply in GLib.Net.PlayerMonitor:GetPlayerEnumerator () do
					if not userVotes [userId] then
						results [0] [#results [0] + 1] = userId
					end
				end
				
				callback (results)
			end
		)
	end
	
	GVote.VoteQueue:Enqueue (vote)
	
	return vote
end