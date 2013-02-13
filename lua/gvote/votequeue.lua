local self = {}
GVote.VoteQueue = GVote.MakeConstructor (self)

--[[
	Events:
		VoteDequeued (Vote vote)
			Fired when a vote has been dequeued.
		VoteEnqueued (Vote vote)
			Fired when a vote has been enqueued.
		VoteStarted (Vote vote)
			Fired when a vote has started.
]]

function self:ctor ()
	self.NextVoteId = 1
	
	self.Queue     = {}
	self.VotesById = {}
	
	hook.Add ("Think", "GVote.VoteQueue",
		function ()
			self:Think ()
		end
	)
	
	GVote.EventProvider (self)
end

function self:dtor ()
	hook.Remove ("Think", "GVote.VoteQueue")
end

function self:Dequeue ()
	if #self.Queue == 0 then return end
	
	self.VotesById [self.Queue [1]:GetId ()] = nil
	
	self:UnhookVote (self.Queue [1])
	self:DispatchEvent ("VoteDequeued", self.Queue [1])
	table.remove (self.Queue, 1)
	
	self:StartNextVote ()
end

function self:Enqueue (vote)
	if not vote then return end
	
	if not vote:GetId () then
		vote:SetId (self:GenerateVoteId ())
	end
	
	self.Queue [#self.Queue + 1] = vote
	self.VotesById [vote:GetId ()] = vote
	if SERVER then
		GVote.VoteTypes:CreateNetworker (vote:GetType (), vote)
	end
	
	self:HookVote (vote)
	self:DispatchEvent ("VoteEnqueued", vote)
	
	self:StartNextVote ()
end

function self:GenerateVoteId ()
	local voteId = self.NextVoteId
	self.NextVoteId = (self.NextVoteId + 1) % 4294967296
	return voteId
end

function self:GetVoteById (id)
	return self.VotesById [id]
end

function self:Think ()
	if #self.Queue == 0 then return end
	
	self.Queue [1]:Tick ()
	if self.Queue [1]:HasEnded () and CurTime () - self.Queue [1]:GetEndTime () > 5 then
		self:Dequeue ()
	end
	if #self.Queue == 0 then return end
	
	if SERVER and not self.Queue [1]:HasStarted () then
		self.Queue [1]:Start ()
		self:DispatchEvent ("VoteStarted", GVote.CurrentVote)
	end
	if self.Queue [1]:HasStarted () then
		self.Queue [1]:Tick ()
	end
end

-- Internal, do not call
function self:HookVote (vote)
	if not vote then return end
	
	vote:AddEventListener ("VoteEnded", tostring (self),
		function (_, voteEndReason)
			self:DispatchEvent ("VoteEnded", vote, voteEndReason)
		end
	)
end

function self:UnhookVote (vote)
	if not vote then return end
	
	vote:RemoveEventListener ("VoteEnded", tostring (self))
end

function self:StartNextVote ()
	GVote.CurrentVote = self.Queue [1]
	
	if not GVote.CurrentVote then return end
	
	if self.Queue [1]:HasStarted () then
		self:DispatchEvent ("VoteStarted", self.Queue [1])
	end
end

GVote.VoteQueue = GVote.VoteQueue ()