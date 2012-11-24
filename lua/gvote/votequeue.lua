local self = {}
GVote.VoteQueue = GVote.MakeConstructor (self)

function self:ctor ()
	self.NextVoteId = 1
	
	self.Queue     = {}
	self.VotesById = {}
	
	hook.Add ("Think", "GVote.VoteQueue",
		function ()
			self:Think ()
		end
	)
end

function self:dtor ()
	hook.Remove ("Think", "GVote.VoteQueue")
end

function self:Dequeue ()
	if #self.Queue == 0 then return end
	self.VotesById [self.Queue [1]:GetId ()] = nil
	table.remove (self.Queue, 1)
	
	GVote.CurrentVote = self.Queue [1]
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
	
	GVote.CurrentVote = self.Queue [1]
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
	end
	if self.Queue [1]:HasStarted () then
		self.Queue [1]:Tick ()
	end
end

GVote.VoteQueue = GVote.VoteQueue ()