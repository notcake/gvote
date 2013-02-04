local self = {}
GVote.Vote = GVote.MakeConstructor (self)

--[[
	Events:
		EndTimeChanged (endTime)
			Fired when the vote end time has changed.
		TextChanged (text)
			Fired when the vote text has changed.
		VoteStarted ()
			Fired when the vote has started.
		VoteEnded (VoteEndReason voteEndReason)
			Fired when the vote has started.
]]

function self:ctor (id)
	self.Id = id
	
	self.Text = ""
	
	self.Started   = false
	self.Ended     = false
	self.StartTime = 0
	self.EndTime   = 0
	
	self.LastTickTime = 0
	
	GVote.EventProvider (self)
end

function self:dtor ()
	if self:IsInProgress () then
		self:DispatchEvent ("VoteEnded")
	end
end

-- Serialization
function self:Serialize (outBuffer)
	outBuffer:String (self.Text)
	outBuffer:Boolean (self.Started)
	outBuffer:Float (self.StartTime)
	outBuffer:Float (self.EndTime)
end

function self:Deserialize (inBuffer)
	self:SetText (inBuffer:String ())
	
	self.Started   = inBuffer:Boolean ()
	self.StartTime = inBuffer:Float ()
	self.EndTime   = inBuffer:Float ()
	
	if self:HasStarted () then
		self:DispatchEvent ("VoteStarted")
	end
	if self:HasEnded () then
		self:DispatchEvent ("VoteEnded")
	end
end

function self:Abort ()
	self:End (GVote.VoteEndReason.Aborted)
end

function self:AddTime (t)
	if self:HasEnded () then return end
	
	self:SetEndTime (self:GetEndTime () + t)
end

function self:End (voteEndReason)
	if self.Ended then return end
	
	self.Ended = true
	self.EndTime = CurTime ()
	
	self:DispatchEvent ("VoteEnded", voteEndReason or GVote.VoteEndReason.Aborted)
end

function self:GetElapsedTime ()
	if CurTime () > self.EndTime then
		return self.EndTime - self.StartTime
	end
	return CurTime () - self.StartTime
end

function self:GetEndTime ()
	return self.EndTime
end

function self:GetId ()
	return self.Id
end

function self:GetRemainingTime ()
	return math.max (0, self.EndTime - CurTime ())
end

function self:GetStartTime ()
	return self.StartTime
end

function self:GetText ()
	return self.Text
end

function self:GetType ()
	return self.__Type
end

function self:HasStarted ()
	return self.Started
end

function self:HasEnded ()
	if self.Ended then return true end
	return self.Started and CurTime () > self.EndTime
end

function self:IsInProgress ()
	return self:HasStarted () and not self:HasEnded ()
end

function self:SetEndTime (t)
	t = t or self.EndTime
	if self.EndTime == t then return end
	
	self.EndTime = t
	self:DispatchEvent ("EndTimeChanged", self.EndTime)
end

function self:SetId (id)
	self.Id = id
end

function self:SetText (text)
	text = text or ""
	if self.Text == text then return end
	
	self.Text = text
	self:DispatchEvent ("TextChanged", self.Text)
end

function self:Start (duration)
	duration = duration or 30
	
	self.Started = true
	self.StartTime = CurTime ()
	self.EndTime = self.StartTime + duration
	
	self:DispatchEvent ("VoteStarted")
end

function self:Tick ()
	if self.LastTickTime < self:GetEndTime () and self:HasEnded () then
		self.LastTickTime = CurTime ()
		self:End (GVote.VoteEndReason.Timeout)
	end
end

function self:ToString ()
	local vote = "[Vote]\n"
	vote = vote .. self:GetText ()
	return vote
end