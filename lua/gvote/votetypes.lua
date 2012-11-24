local self = {}
GVote.VoteTypes = GVote.MakeConstructor (self)

function self:ctor ()
	self.Constructors = {}
	self.NetworkerConstructors = {}
end

function self:Create (type, ...)
	if not self.Constructors [type] then return end
	return self.Constructors [type] (...)
end

function self:CreateNetworker (type, vote, ...)
	if not self.NetworkerConstructors [type] then return end
	return self.NetworkerConstructors [type] (vote, ...)
end

function self:CreateType (type)
	local metatable = {}
	self.Constructors [type] = GVote.MakeConstructor (metatable, GVote.Vote)
	metatable.__Type = type
	return metatable
end

function self:CreateNetworkerType (type)
	local metatable = {}
	self.NetworkerConstructors [type] = GVote.MakeConstructor (metatable, GVote.VoteNetworker)
	metatable.__Type = type
	return metatable
end

function self:TypeExists (type)
	return self.Constructors [type] and true or false
end

GVote.VoteTypes = GVote.VoteTypes ()

GVote.IncludeDirectory ("gvote/votes")