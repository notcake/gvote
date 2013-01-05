local self = GVote.VoteTypes:CreateType ("SingleChoiceVote")
GVote.VoteTypes:CreateNetworkerType ("SingleChoiceVote")

--[[
	Events:
		ChoiceAdded (choiceId, text)
			Fired when a choice has been added.
		ChoiceRemoved (choiceId)
			Fired when a choice has been removed.
		ChoiceTextChanged (choiceId, text)
			Fired when a choice's text has been changed.
		UserVoteChanged (userId, oldChoiceId, choiceId)
			Fired when a user has changed their choice.
]]

function self:ctor (id)
	self.NextChoiceId = 1
	self.Choices = {}
	self.ChoicesById = {}
	self.UserVotes = {}
end

function self:dtor ()
end

-- Serialization
function self:Serialize (outBuffer)
	self.__base.Serialize (self, outBuffer)
	
	outBuffer:UInt16 (self.NextChoiceId)
	outBuffer:UInt16 (#self.Choices)
	for i = 1, #self.Choices do
		outBuffer:UInt16 (self.Choices [i])
	end
	for choiceId, text in pairs (self.ChoicesById) do
		outBuffer:UInt16 (choiceId)
		outBuffer:String (text)
	end
	outBuffer:UInt16 (0x0000)
	for userId, choiceId in pairs (self.UserVotes) do
		outBuffer:String (userId)
		outBuffer:UInt16 (choiceId)
	end
	outBuffer:String ("")
end

function self:Deserialize (inBuffer)
	self.__base.Deserialize (self, inBuffer)
	
	self.NextChoiceId = inBuffer:UInt16 ()
	local choiceCount = inBuffer:UInt16 ()
	for i = 1, choiceCount do
		self.Choices [i] = inBuffer:UInt16 ()
	end
	
	local choiceId = inBuffer:UInt16 ()
	while choiceId ~= 0x0000 do
		self.ChoicesById [choiceId] = inBuffer:String ()
		choiceId = inBuffer:UInt16 ()
	end
	
	for choiceId, text in self:GetChoiceEnumerator () do
		self:DispatchEvent ("ChoiceAdded", choiceId, text)
	end
	
	local userId = inBuffer:String ()
	while userId ~= "" do
		self:SetUserVote (userId, inBuffer:UInt16 ())
		userId = inBuffer:String ()
	end
end

function self:AddChoice (choiceText)
	if #self.Choices >= 150 then
		GVote.Error ("SingleChoiceVote:AddChoice : Too many vote choices.")
		error ("SingleChoiceVote:AddChoice : Too many vote choices.")
		return
	end
	
	local choiceId = self.NextChoiceId
	self.NextChoiceId = self.NextChoiceId + 1
	
	choiceText = tostring (choiceText)
	local choice = choiceText
	self.ChoicesById [choiceId] = choice
	self.Choices [#self.Choices + 1] = choiceId
	self:DispatchEvent ("ChoiceAdded", choiceId, choiceText)
end

function self:AddChoices (choices)
	for _, choiceText in ipairs (choices) do
		self:AddChoice (tostring (choiceText))
	end
end

function self:GetChoice (index)
	return self.Choices [index], self:GetChoiceText (self.Choices [index])
end

function self:GetChoiceCount ()
	return #self.Choices
end

function self:GetChoiceEnumerator ()
	local next, tbl, key = ipairs (self.Choices)
	return function ()
		key = next (tbl, key)
		return tbl [key], self.ChoicesById [tbl [key]]
	end
end

function self:GetChoiceId (index)
	return self.Choices [index]
end

function self:GetChoiceIndex (choiceId)
	for k, v in ipairs (self.Choices) do
		if v == choiceId then
			return k
		end
	end
	return nil
end

function self:GetChoiceText (choiceId)
	return self.ChoicesById [choiceId]
end

function self:GetChoiceUsers (choiceId)
	local users = {}
	for userId, v in pairs (self.UserVotes) do
		if v == choiceId then
			users [#users + 1] = userId
		end
	end
	return users
end

function self:GetChoiceVoteCount (choiceId)
	local voteCount = 0
	for userId, v in pairs (self.UserVotes) do
		if v == choiceId then
			voteCount = voteCount + 1
		end
	end
	return voteCount
end

function self:GetTotalVotes ()
	local count = 0
	for _, _ in pairs (self.UserVotes) do
		count = count + 1
	end
	return count
end

function self:GetUserVote (userId)
	local choiceId = self.UserVotes [userId]
	return self.Choices [choiceId]
end

function self:GetUserVoteEnumerator ()
	local next, tbl, key = pairs (self.UserVotes)
	return function ()
		key = next (tbl, key)
		return key, tbl [key]
	end
end

function self:RemoveChoice (choiceId)
	if not self.ChoicesById [choiceId] then return end
	
	self.ChoicesById [choiceId] = nil
	for k, v in ipairs (self.Choices) do
		if v == choiceId then
			table.remove (self.Choices, k)
			break
		end
	end
	
	for k, v in pairs (self.UserVotes) do
		if v == choiceId then
			self:SetUserVote (k, nil)
		end
	end
	
	self:DispatchEvent ("ChoiceRemoved", choiceId)
end

function self:SetChoiceText (choiceId, text)
	text = text or self.ChoicesById [choiceId]
	text = tostring (text)
	
	if not self.ChoicesById [choiceId] then return end
	if self.ChoicesById [choiceId] == text then return end
	
	self.ChoicesById [choiceId] = text
	
	self:DispatchEvent ("ChoiceTextChanged", choiceId, text)
end

function self:SetUserVote (userId, choiceId)
	if not userId then return end
	if choiceId and not self.ChoicesById [choiceId] then return end
	if self.UserVotes [userId] == choiceId then return end
	
	local oldChoiceId = self.UserVotes [userId]
	self.UserVotes [userId] = choiceId
	
	self:DispatchEvent ("UserVoteChanged", userId, oldChoiceId, choiceId)
end

function self:ToString ()
	local vote = "[Vote]\n"
	vote = vote .. self:GetText () .. "\n"
	for choiceId, text in self:GetChoiceEnumerator () do
		local users = self:GetChoiceUsers (choiceId)
		vote = vote .. "\t [" .. string.format ("%2d", #users) .. "] " .. tostring (text):gsub ("[\r\n]", " ") .. "\n"
		for i = 1, #users do
			local name = GLib.Net.PlayerMonitor:GetUserName (users [i])
			if name == users [i] then name = nil end
			vote = vote .. "\t\t" .. users [i] .. (name and (" (" .. name .. ")") or "") .. "\n"
		end
	end
	return vote
end