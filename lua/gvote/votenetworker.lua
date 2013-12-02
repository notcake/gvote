local self = {}
GVote.VoteNetworker = GVote.MakeConstructor (self)

function self:ctor (vote)
	self.Vote = vote
	
	self.Vote:AddEventListener ("ChoiceAdded", self:GetHashCode (),
		function (vote, choiceId, text)
			self:OnChoiceAdded (vote, choiceId, text)
		end
	)
	
	self.Vote:AddEventListener ("ChoiceRemoved", self:GetHashCode (),
		function (vote, choiceId)
			self:OnChoiceRemoved (vote, choiceId, text)
		end
	)
	
	self.Vote:AddEventListener ("ChoiceTextChanged", self:GetHashCode (),
		function (vote, choiceId, text)
			self:OnChoiceTextChanged (vote, choiceId, text)
		end
	)
	
	self.Vote:AddEventListener ("EndTimeChanged", self:GetHashCode (),
		function (vote, endTime)
			self:OnEndTimeChanged (vote, endTime)
		end
	)
	
	self.Vote:AddEventListener ("VoteEnded", self:GetHashCode (),
		function (vote, voteEndReason)
			self:OnVoteEnded (vote, voteEndReason)
		end
	)
	
	self.Vote:AddEventListener ("VoteStarted", self:GetHashCode (),
		function (vote)
			self:OnVoteStarted (vote)
		end
	)
	
	self.Vote:AddEventListener ("TextChanged", self:GetHashCode (),
		function (vote, text)
			self:OnTextChanged (vote, text)
		end
	)
	
	self.Vote:AddEventListener ("UserVoteChanged", self:GetHashCode (),
		function (vote, userId, oldChoiceId, choiceId)
			self:OnUserVoteChanged (vote, userId, oldChoiceId, choiceId)
		end
	)
	
	if self.Vote:HasStarted () then
		self:OnVoteStarted (self.Vote)
	end
end

-- Internal, do not call
function self:DispatchPacket (outBuffer)
	GVote.Net.DispatchPacket (GLib.GetEveryoneId (), "gvote", outBuffer)
end

function self:OnChoiceAdded (vote, choiceId, text)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (vote:GetId ())
	outBuffer:String ("ChoiceAdded")
	outBuffer:UInt16 (choiceId)
	outBuffer:String (text)
	self:DispatchPacket (outBuffer)
end

function self:OnChoiceRemoved (vote, choiceId)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (vote:GetId ())
	outBuffer:String ("ChoiceRemoved")
	outBuffer:UInt16 (choiceId)
	self:DispatchPacket (outBuffer)
end

function self:OnChoiceTextChanged (vote, choiceId, text)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (vote:GetId ())
	outBuffer:String ("ChoiceTextChanged")
	outBuffer:UInt16 (choiceId)
	outBuffer:String (text)
	self:DispatchPacket (outBuffer)
end

function self:OnEndTimeChanged (vote, endTime)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (vote:GetId ())
	outBuffer:String ("EndTimeChanged")
	outBuffer:Float (endTime)
	self:DispatchPacket (outBuffer)
end

function self:OnTextChanged (vote, text)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (vote:GetId ())
	outBuffer:String ("TextChanged")
	outBuffer:String (text)
	self:DispatchPacket (outBuffer)
end

function self:OnUserVoteChanged (vote, userId, oldChoiceId, choiceId)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (vote:GetId ())
	outBuffer:String ("UserVoteChanged")
	outBuffer:String (userId)
	outBuffer:UInt16 (oldChoiceId and oldChoiceId or 0xFFFF)
	outBuffer:UInt16 (choiceId and choiceId or 0xFFFF)
	self:DispatchPacket (outBuffer)
end

function self:OnVoteEnded (vote, voteEndReason)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (vote:GetId ())
	outBuffer:String ("VoteEnded")
	outBuffer:UInt8 (voteEndReason)
	self:DispatchPacket (outBuffer)
end

function self:OnVoteStarted (vote)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (vote:GetId ())
	outBuffer:String ("VoteCreated")
	outBuffer:String (vote:GetType ())
	vote:Serialize (outBuffer)
	self:DispatchPacket (outBuffer)
end