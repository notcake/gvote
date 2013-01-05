if SERVER then
	timer.Simple (1,
		function ()
			if not aowl then return end
			aowl.AddCommand ("vote",
				function (ply, _, question, ...)
					if not question then
						ply:ChatPrint ("You need to provide a question and at least 2 choices.")
						return
					end
					
					local choices = {...}
					if #choices < 2 then
						ply:ChatPrint ("You need to provide at least 2 choices.")
						return
					end
					
					GVote.Vote (question, ...)
				end,
				"developers"
			)
		end
	)
end