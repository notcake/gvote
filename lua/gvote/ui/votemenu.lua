local PANEL = {}

local itemColors = {}
itemColors [0] = GLib.Colors.CornflowerBlue
itemColors [1] = GLib.Colors.Red
itemColors [2] = GLib.Colors.Green
itemColors [3] = GLib.Colors.Blue
itemColors [4] = GLib.Colors.Orange
itemColors [5] = GLib.Colors.Pink
itemColors [6] = GLib.Colors.Cyan
itemColors [7] = GLib.Colors.White
itemColors [8] = GLib.Colors.Silver
itemColors [9] = GLib.Colors.SlateBlue

local gayColors =
{
	Color (255,   0,   0, 255),
	Color (255, 128,   0, 255),
	Color (255, 255,   0, 255),
	Color (  0, 128,   0, 255),
	Color (  0,   0, 255, 255),
	Color (148,   0, 211, 255)
}

local creditTexts =
{
	"Provided by Metabold Systems Incorporated.",
	"\"If the vote were legitimately rigged, the server would have ways of shutting it down.\"",
	"Endorsed by Mitt Romney.",
	"Metabold Systems - Fair and Balanced.",
	"Metabold Systems - Totally not rigged.",
	"Democratic vote rigging in progress..."
}

function PANEL:Init ()
	self.Vote = nil
	self.LastBeepSecond = 0
	
	self.TickProvider = Gooey.TickProvider ()
	
	self.FooterY = 0
	
	self.TitleLabel = vgui.Create ("GLabelX", self)
	self.TitleLabel:SetText ("Menu")
	self.TitleLabel:SetFont ("DermaDefaultBold")
	
	self.Items = {}
	self.CancelItem = vgui.Create ("GLabelX", self)
	self.CancelItem:SetText ("0. Cancel")
	self.CancelItem:SetFont ("DermaDefaultBold")
	self.CancelAlphaController = Gooey.AlphaController ()
	self.CancelAlphaController:SetAlpha (128)
	self.CancelAlphaController:SetTargetAlpha (128)
	self.CancelAlphaController:SetTickController (self.TickProvider)
	self.CancelAlphaController:AddControl (self.CancelItem)
	
	self.LastNotificationTimes = {}
	
	self.CountdownIcon = vgui.Create ("GImage", self)
	self.CountdownIcon:SetImage ("icon16/clock.png")
	self.CountdownLabel = vgui.Create ("GLabel", self)
	self.CountdownLabel:SetText ("00:00")
	self.CountdownLabel:SetFont ("DermaDefaultBold")
	self.CountdownAlphaController = Gooey.AlphaController ()
	self.CountdownAlphaController:SetAlpha (255)
	self.CountdownAlphaController:SetTargetAlpha (255)
	self.CountdownAlphaController:SetTickController (self.TickProvider)
	self.CountdownAlphaController:AddControl (self.CountdownLabel)
	self.CreditsLabel = vgui.Create ("GLabel", self)
	self.CreditsLabel:SetText (creditTexts [math.random (1, #creditTexts)])
	self.CreditsLabel:SetFont ("DefaultBold")
	self.CreditsAlphaController = Gooey.AlphaController ()
	self.CreditsAlphaController:SetAlpha (0)
	self.CreditsAlphaController:SetTargetAlpha (0)
	self.CreditsAlphaController:SetTickController (self.TickProvider)
	self.CreditsAlphaController:AddControl (self.CreditsLabel)
	
	self:SetVisible (false)
	
	self.AlphaController = Gooey.AlphaController ()
	self.AlphaController:SetAlpha (0)
	self.AlphaController:SetTargetAlpha (0)
	self.AlphaController:SetTickController (self.TickProvider)
	self.AlphaController:AddControl (self)
	
	self.KeyboardMonitor = Gooey.KeyboardMonitor ()
	for i = 0, 9 do
		self.KeyboardMonitor:RegisterKey (_G ["KEY_" .. tostring (i)])
	end
	self.KeyboardMonitor:AddEventListener ("KeyPressed",
		function (_, key)
			for i = 0, 9 do
				if _G ["KEY_" .. tostring (i)] == key then
					self:OnNumberPressed (i)
					break
				end
			end
		end
	)
	
	self:AddEventListener ("VisibleChanged",
		function (_, visible)
			if visible then
				self.AlphaController:SetTargetAlpha (255)
				
				hook.Add ("HUDPaint", "GVote.Menu." .. tostring (self:GetTable ()),
					function ()
						local x, y = self:GetPos ()
						
						surface.SetAlphaMultiplier (self:GetAlpha () / 255)
						
						for k, itemEntry in ipairs (self.Items) do
							local _, cy = itemEntry.Control:GetPos ()
							
							local h = itemEntry.Control:GetTall ()
							w = itemEntry.BarController:GetValue ()
							
							local round = 4
							if w < round * 2 then
								round = math.floor (w * 0.25) * 2
							end
							
							if h > 12 then h = 12 end
							cy = cy + itemEntry.Control:GetTall () * 0.5 - h * 0.5
							
							if itemEntry.Gay then
								local dh = h / #gayColors
								if dh < round * 2 then
									round = math.floor (dh * 0.25) * 2
								end
								for i = 1, #gayColors do
									draw.RoundedBoxEx (round, x - w, y + cy, w, dh, gayColors [i], i == 1, false, i == #gayColors, false)
									cy = cy + dh
								end
							else
								draw.RoundedBoxEx (round, x - w, y + cy, w, h, itemColors [k % #itemColors], true, false, true, false)
							end
						end
						
						surface.SetAlphaMultiplier (1)
					end
				)
				hook.Add ("PlayerBindPress", "GVote.Menu." .. tostring (self:GetTable ()),
					function (ply, bind, pressed)
						if not pressed then return end
						if not self or not self:IsValid () then return end
						
						local number
						for i = 0, 9 do
							if input.IsKeyDown (KEY_0 + i) then
								number = i
							end
						end
						if not number then return end
						return self:OnNumberPressed (number)
					end
				)
			else
				self.AlphaController:SetTargetAlpha (0)
				
				hook.Remove ("HUDPaint",        "GVote.Menu." .. tostring (self:GetTable ()))
				hook.Remove ("PlayerBindPress", "GVote.Menu." .. tostring (self:GetTable ()))
				hook.Remove ("Think",           "GVote.Menu." .. tostring (self:GetTable ()))
			end
		end
	)
	
	GVote:AddEventListener ("Unloaded", tostring (self:GetTable ()),
		function ()
			self:Remove ()
		end
	)
end

function PANEL:GetVote ()
	return self.Vote
end

local backgroundColor       = Color ( 64,  64,  64, 216)
local titleBackgroundColor  = Color ( 96,  96,  96, 216)
local footerBackgroundColor = Color ( 84,  84,  84, 216)
function PANEL:Paint (w, h)
	draw.RoundedBoxEx (8, 0, 0, w, h, backgroundColor, true, false, true, false)
	
	local x, y = self.TitleLabel:GetPos ()
	local _, h = self.TitleLabel:GetSize ()
	draw.RoundedBoxEx (4, x - 4, y - 4, w - 8, h + 8, titleBackgroundColor, true, true, true, true)
	
	local x, y = self.CountdownIcon:GetPos ()
	x = 4
	y = self.FooterY
	w = self:GetWide () - 8
	h = self:GetTall () - 4 - y
	draw.RoundedBoxEx (4, x, y, w, h, footerBackgroundColor, true, true, true, true)
end

function PANEL:PerformLayout ()
	local w = 32
	local y = 8
	
	self.TitleLabel:SetPos (8, y)
	self:ResizeLabel (self.TitleLabel)
	y = y + self.TitleLabel:GetTall ()
	y = y + 8
	
	w = self.TitleLabel:GetWide () + 16
	
	for i = 1, #self.Items do
		self.Items [i].Control:SetPos (24, y)
		self:ResizeLabel (self.Items [i].Control)
		
		w = math.max (w, self.Items [i].Control:GetWide () + 24)
		y = y + self.Items [i].Control:GetTall ()
	end
	y = y + self.CancelItem:GetTall ()
	
	self.CancelItem:SetPos (24, y)
	self:ResizeLabel (self.CancelItem)
	w = math.max (w, self.CancelItem:GetWide () + 24)
	y = y + self.CancelItem:GetTall ()
	
	y = y + 4
	self:ResizeLabel (self.CountdownLabel, 256 - 8 - 4 - self.CountdownIcon:GetWide ())
	self:ResizeLabel (self.CreditsLabel, 256 - 8 - 4 - self.CountdownIcon:GetWide ())
	
	self.FooterY = y
	local footerHeight = math.max (self.CountdownIcon:GetTall (), self.CountdownLabel:GetTall () + 8, self.CreditsLabel:GetTall () + 8)
	self.CountdownIcon :SetPos (8, y + 0.5 * footerHeight - 0.5 * self.CountdownIcon:GetTall ())
	self.CountdownLabel:SetPos (8 + self.CountdownIcon:GetWide () + 4, y + 0.5 * footerHeight - 0.5 * self.CountdownLabel:GetTall ())
	self.CreditsLabel  :SetPos (8 + self.CountdownIcon:GetWide () + 4, y + 0.5 * footerHeight - 0.5 * self.CreditsLabel  :GetTall ())
	y = y + footerHeight
	
	w = math.max (w, self.CreditsLabel:GetPos () + self.CreditsLabel:GetWide () + 8)
	
	self:SetSize (w, y + 4)
	self:SetPos (ScrW () - self:GetWide (), (ScrH () - self:GetTall ()) * 0.5)
end

function PANEL:ResizeLabel (control, maxWidth)
	control:SetContentAlignment (5)
	control:SetWrap (true)
	
	control:SizeToContents ()
	local w, h = control:GetSize ()
	local lineHeight = control:GetLineHeight ()
	local area = w * h
	
	maxWidth = maxWidth or 256
	if w > maxWidth then
		w = maxWidth
		h = math.ceil ((area / maxWidth) / lineHeight) * lineHeight
	end
	
	control:SetSize (w, h)
end

function PANEL:SetVote (vote)
	if self.Vote == vote then return end
	
	self:UnhookVote (self.Vote)
	self.Vote = vote
	self:HookVote (self.Vote)
	self.LastBeepSecond = 0
	
	if self.Vote then
		local questionText = self.Vote and self.Vote:GetText () or ""
		questionText = questionText:gsub (":you:", LocalPlayer ():Name ())
		questionText = questionText:gsub (":YOU:", LocalPlayer ():Name ():upper ())
		self.TitleLabel:SetText (questionText)
		
		for i = 1, self.Vote:GetChoiceCount () do
			local choiceId, text = self.Vote:GetChoice (i)
			self:OnChoiceAdded (choiceId, text)
		end
		
		if self.Vote:IsInProgress () then
			surface.PlaySound ("buttons/button3.wav")
		end
	end
end

-- Internal, do not call
function PANEL:HookVote (vote)
	if not vote then return end
	
	vote:AddEventListener ("ChoiceAdded", tostring (self:GetTable ()),
		function (_, choiceId, text)
			self:OnChoiceAdded (choiceId, text)
		end
	)
	vote:AddEventListener ("ChoiceRemoved", tostring (self:GetTable ()),
		function (_, choiceId)
			self:OnChoiceRemoved (choiceId)
		end
	)
	vote:AddEventListener ("ChoiceTextChanged", tostring (self:GetTable ()),
		function (_, choiceId, text)
			for _, itemEntry in ipairs (self.Items) do
				if itemEntry.ChoiceId == choiceId then
					itemEntry.Text = text
					self:UpdateChoiceText (itemEntry)
					self:InvalidateLayout ()
					break
				end
			end
		end
	)
	vote:AddEventListener ("TextChanged", tostring (self:GetTable ()),
		function (_, text)
			self.TitleLabel:SetText (self.Vote:GetText ())
			self:InvalidateLayout ()
		end
	)
	vote:AddEventListener ("UserVoteChanged", tostring (self:GetTable ()),
		function (_, userId, _, choiceId)
			for _, itemEntry in ipairs (self.Items) do
				self:UpdateItemEntry (itemEntry)
			end
			self:UpdateCancelItemEntry ()
			
			local name = GLib.Net.PlayerMonitor:GetUserName (userId)
			local text = self.Vote:GetChoiceText (choiceId) or ""
			
			if choiceId then
				if SysTime () - (self.LastNotificationTimes [userId] or 0) > 1 then
					self.LastNotificationTimes [userId] = SysTime ()
					notification.AddLegacy (name .. " voted for \"" .. text .. "\"!", NOTIFY_HINT, 3)
					if userId ~= GLib.GetLocalId () then
						surface.PlaySound ("buttons/button9.wav")
					end
				end
				MsgN (name .. " voted for \"" .. text .. "\"!")
			end
		end
	)
	vote:AddEventListener ("VoteEnded", tostring (self:GetTable ()),
		function (_)
			local suppressPrint = false
			if epoe and type (epoe.Print) == "function" then
				epoe.Print (self.Vote:ToString ())
				suppressPrint = GetConVar ("epoe_toconsole") and GetConVar ("epoe_toconsole"):GetBool () or false
			end
			if not suppressPrint then
				print (self.Vote:ToString ())
			end
			self.CountdownIcon:SetImage ("icon16/lock.png")
			surface.PlaySound ("buttons/button3.wav")
		end
	)
	vote:AddEventListener ("VoteStarted", tostring (self:GetTable ()),
		function (_)
			surface.PlaySound ("buttons/button3.wav")
		end
	)
end

function PANEL:UnhookVote (vote)
	if not vote then return end
	
	vote:RemoveEventListener ("ChoiceAdded",       tostring (self:GetTable ()))
	vote:RemoveEventListener ("ChoiceRemoved",     tostring (self:GetTable ()))
	vote:RemoveEventListener ("TextChanged",       tostring (self:GetTable ()))
	vote:RemoveEventListener ("UserVoteChanged",   tostring (self:GetTable ()))
	vote:RemoveEventListener ("VoteEnded",         tostring (self:GetTable ()))
end

function PANEL:UpdateCancelItemEntry ()
	local localChoiceId = self.Vote:GetUserVote (GLib.GetLocalId ())
	self.CancelAlphaController:SetTargetAlpha (localChoiceId and 255 or 128)
end

function PANEL:UpdateChoiceText (itemEntry)
	local choiceText = itemEntry.Text or ""
	local gay = (string.find (string.lower (choiceText), "=rainbow=") or string.find (string.lower (choiceText), "=gaybow=")) and true or false
	
	choiceText = choiceText:gsub (":you:", LocalPlayer ():Name ())
	choiceText = choiceText:gsub (":YOU:", LocalPlayer ():Name ():upper ())
	
	itemEntry.Control:SetText (tostring (self.Vote:GetChoiceIndex (itemEntry.ChoiceId)) .. ". " .. choiceText)
	itemEntry.Gay = gay
end

function PANEL:UpdateItemEntry (itemEntry)
	local totalVotes = self.Vote:GetTotalVotes ()
	
	local localChoiceId = self.Vote:GetUserVote (GLib.GetLocalId ())
	itemEntry.AlphaController:SetTargetAlpha ((not localChoiceId or itemEntry.ChoiceId == localChoiceId) and 255 or 128)
	itemEntry.BarController:SetTargetValue (self.Vote:GetChoiceVoteCount (itemEntry.ChoiceId) * 32)
end

function PANEL:OnChoiceAdded (choiceId, text)
	local localChoiceId = self.Vote:GetUserVote (GLib.GetLocalId ())
	local itemEntry = {}
	self.Items [#self.Items + 1] = itemEntry
	itemEntry.ChoiceId = choiceId
	itemEntry.Text = text
	itemEntry.Control = vgui.Create ("GLabelX", self)
	itemEntry.Control:SetText ("")
	itemEntry.Control:SetFont ("DermaDefaultBold")
	itemEntry.AlphaController = Gooey.AlphaController ()
	itemEntry.AlphaController:SetAlpha (0)
	itemEntry.AlphaController:SetTargetAlpha ((not localChoiceId or itemEntry.ChoiceId == localChoiceId) and 255 or 128)
	itemEntry.AlphaController:SetTickController (self.TickProvider)
	itemEntry.AlphaController:AddControl (itemEntry.Control)
	itemEntry.BarController = Gooey.LerpController ()
	itemEntry.BarController:SetValue (0)
	itemEntry.BarController:SetTargetValue (self.Vote:GetChoiceVoteCount (itemEntry.ChoiceId) * 32)
	
	self:UpdateChoiceText (itemEntry)
	self:UpdateItemEntry (itemEntry)
	self:InvalidateLayout ()
end

function PANEL:OnChoiceRemoved (choiceId)
	for k, itemEntry in ipairs (self.Items) do
		if itemEntry.ChoiceId == choiceId then
			itemEntry.Control:Remove ()
			itemEntry.AlphaController:dtor ()
			itemEntry.BarController:dtor ()
			table.remove (self.Items, k)
			
			for i = k, #self.Items do
				self:UpdateChoiceText (self.Items [i])
			end
			
			self:InvalidateLayout ()
			break
		end
	end
	for _, itemEntry in ipairs (self.Items) do
		self:UpdateItemEntry (itemEntry)
	end
end

-- Returns true to suppress keybind from being processed
function PANEL:OnNumberPressed (number)
	if not self.Vote then return end
	if not self.Vote:IsInProgress () then return end
	
	if number == 0 then number = nil end
	
	if number and (number <= 0 or number > self.Vote:GetChoiceCount ()) then return end
	
	local existingChoice = self.Vote:GetUserVote (GLib.GetLocalId ())
	if not existingChoice or not number then
		local choiceId = number and self.Vote:GetChoiceId (number) or nil
		if choiceId ~= self.Vote:GetUserVote (GLib.GetLocalId ()) then
			local outBuffer = GVote.Net.OutBuffer ()
			outBuffer:UInt32 (self.Vote:GetId () or 0)
			outBuffer:UInt16 (choiceId and choiceId or 0xFFFF)
			GVote.Net.DispatchPacket (GLib.GetServerId (), "gvote", outBuffer)
			
			self.Vote:SetUserVote (GLib.GetLocalId (), choiceId)
			surface.PlaySound ("buttons/button9.wav")
		end
		return true
	end
end

-- Event handlers
function PANEL:OnRemoved ()
	GVote:RemoveEventListener ("Unloaded", tostring (self:GetTable ()))
	self.KeyboardMonitor:dtor ()
	
	self:SetVote (nil)
	self:SetVisible (false)
end

function PANEL:Think ()
	local remainingTime = self.Vote and self.Vote:GetRemainingTime () or 0
	self.CountdownLabel:SetText (string.format ("%02d:%02d", math.floor (remainingTime / 60), remainingTime % 60))
	if self.Vote and self.Vote:HasEnded () then
		self.CountdownAlphaController:SetTargetAlpha (0)
		self.CreditsAlphaController  :SetTargetAlpha (255)
	else
		self.CountdownAlphaController:SetTargetAlpha (255)
		self.CreditsAlphaController  :SetTargetAlpha (0)
	end
	
    if self.Vote and self.Vote:GetRemainingTime () < 5 then
		local currentSecond = math.floor (self.Vote:GetRemainingTime ())
		if currentSecond ~= self.LastBeepSecond then
			self.LastBeepSecond = currentSecond
			surface.PlaySound ("buttons/blip1.wav")
		end
		self.Vote:Tick ()
    end
	if self.Vote and CurTime () - self.Vote:GetEndTime () > 5 then
		self.AlphaController:SetTargetAlpha (0)
		self.AlphaController:AddEventListener ("FadeCompleted",
			function ()
				self:Remove ()
			end
		)
	end
	self.TickProvider:Tick ()
end

Gooey.Register ("GVoteMenu", PANEL, "GPanel")