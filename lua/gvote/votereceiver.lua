local self = {}
GVote.VoteReceiver = GVote.MakeConstructor (self)

function self:ctor ()
end

function self:HandlePacket (voteId, messageType, inBuffer)
	local vote = GVote.VoteQueue:GetVoteById (voteId)
	if not vote and messageType ~= "VoteCreated" then return end
	
	if messageType == "VoteCreated" then
		vote = GVote.VoteTypes:Create (inBuffer:String ())
		vote:SetId (voteId)
		vote:Deserialize (inBuffer)
		GVote.VoteQueue:Enqueue (vote)
		
		local menu = vgui.Create ("GVoteMenu")
		menu:SetVote (vote)
		menu:SetVisible (true)
		return
	elseif messageType == "ChoiceAdded" then
		local choiceId = inBuffer:UInt16 ()
		local text     = inBuffer:String ()
		vote:AddChoice (text)
	elseif messageType == "ChoiceRemoved" then
		local choiceId = inBuffer:UInt16 ()
		vote:RemoveChoice (choiceId)
	elseif messageType == "ChoiceTextChanged" then
		local choiceId = inBuffer:UInt16 ()
		local text     = inBuffer:String ()
		vote:SetChoiceText (choiceId, text)
	elseif messageType == "EndTimeChanged" then
		vote:SetEndTime (inBuffer:Float ())
	elseif messageType == "TextChanged" then
		vote:SetText (inBuffer:String ())
	elseif messageType == "UserVoteChanged" then
		local userId = inBuffer:String ()
		local oldChoiceId = inBuffer:UInt16 ()
		local choiceId    = inBuffer:UInt16 ()
		oldChoiceId = oldChoiceId ~= 0xFFFF and oldChoiceId or nil
		choiceId    = choiceId    ~= 0xFFFF and choiceId    or nil
		vote:SetUserVote (userId, choiceId)
	end
end

GVote.Net.RegisterChannel ("gvote",
	function (sourceId, inBuffer)
		local id          = inBuffer:UInt32 ()
		if SERVER then
			local vote = GVote.VoteQueue:GetVoteById (id)
			if not vote then return end
			
			local choiceId = inBuffer:UInt16 ()
			vote:SetUserVote (sourceId, choiceId ~= 0xFFFF and choiceId or nil)
		else
			local messageType = inBuffer:String ()
			
			GVote.VoteReceiver:HandlePacket (id, messageType, inBuffer)
		end
	end
)

GVote.VoteReceiver = GVote.VoteReceiver ()