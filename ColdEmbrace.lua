-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
BINDING_HEADER_COLDEMBRACE = "ColdEmbrace";
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
--[ References ]--

local OriginalUIErrorsFrame_OnEvent;

--[ Settings ]--
ColdEmbraceVariables = {
	RollFrame = 1;
};

local ItemFrameCE = nil
local NeedFrameCE = nil
local GreedFrameCE = nil
local PassFrameCE = nil

local me = UnitName('player')

function ColdEmbrace_OnLoad()
	this:RegisterEvent("RESURRECT_REQUEST")
	this:RegisterEvent("CHAT_MSG_SYSTEM");
	this:RegisterEvent("CHAT_MSG_OFFICER");
	this:RegisterEvent("CHAT_MSG_WHISPER");
	this:RegisterEvent("CHAT_MSG_RAID_WARNING");
	this:RegisterEvent("START_LOOT_ROLL");

	SLASH_CEZ1 = "/ce";
	SLASH_CEZ2 = "/coldembrace";
	SlashCmdList["CEZ"] = ColdEmbrace_Help;

	SLASH_CEX1 = "/frames";
	SLASH_CEX2 = "/rollframes";
	SLASH_CEX3 = "/togglerollframes";
	SlashCmdList["CEX"] = CE_RollFramesToggle;
	
	SLASH_CEY1 = "/ceclear";
	SLASH_CEY2 = "/clearframes";
	SlashCmdList["CEY"] = CE_ClearFrames;

	SLASH_CEA1 = "/rms";
	SLASH_CEA2 = "/rollms";
	SlashCmdList["CEA"] = ColdEmbrace_MainSpecRoll;

	SLASH_CEB1 = "/ros";
	SLASH_CEB2 = "/rollos";
	SlashCmdList["CEB"] = ColdEmbrace_OffSpecRoll;

	SLASH_CEC1 = "/rc";
	SLASH_CEC2 = "/readycheck";
	SlashCmdList["CEC"] = ColdEmbrace_ReadyCheck;

	SLASH_CED1 = "/ml";
	SLASH_CED2 = "/master";
	SLASH_CED3 = "/masterloot";
	SlashCmdList["CED"] = ColdEmbrace_MasterLoot;

	SLASH_CEE1 = "/gl";
	SLASH_CEE2 = "/group";
	SLASH_CEE3 = "/grouploot";
	SlashCmdList["CEE"] = ColdEmbrace_GroupLoot;

	SLASH_CEF1 = "/inviteraid";
	SlashCmdList["CEF"] = ColdEmbrace_RaidInvites;

	SLASH_CEG1 = "/rl";
	SLASH_CEG2 = "/reload";
	SlashCmdList["CEG"] = ReloadUI;

	SLASH_CEH1 = "/reset";
	SLASH_CEH2 = "/resetinstance";
	SLASH_CEH3 = "/resetinstances";
	SlashCmdList["CEH"] = ResetInstances;

	SLASH_CEI1 = "/advertise";
	SlashCmdList["CEI"] = ColdEmbraceAdvertise;

	SLASH_CEJ1 = "/attackstart";
	SlashCmdList["CEJ"] = ColdEmbraceAttackStart;

	SLASH_CEK1 = "/attackstop";
	SlashCmdList["CEK"] = ColdEmbraceAttackStop;

	SLASH_CEL1 = "/celogout";
	SlashCmdList["CEL"] = CE_LogoutRaid;




	SLASH_CEV1 = "/cevc";
	SlashCmdList["CEV"] = CE_VersionCheck;

end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function ColdEmbrace_Help()
	DEFAULT_CHAT_FRAME:AddMessage("Thank you for downloading the Cold Embrace guild addon.",1,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("List of usable commands:",0,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("/rl or /reload - Reload UI.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/reset or /resetinstance or /resetinstances - Reset Instances.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/ceclear or /clearframes - Clears all visible frames.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/frames or /rollframes or /togglerollframes - Toggles roll frames on and off.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/rms or /rollms - Main Spec roll.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/ros or /rollos - Off Spec roll.",1,1,1);
	--DEFAULT_CHAT_FRAME:AddMessage("/advertise - Will post basic guild add in world chat (type /join world).",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/attackstart and /attackstop - spammable start/stop attacking command (requires Attack from spellbook General tab to be ANYWHERE on the action bar):",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("Requires Raid Lead/Assist and/or a Guild Officer rank:",0,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("/inviteraid - Start raid invites.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/rc or /readycheck - Start a Ready Check.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/ml or /master or /masterloot - Change loot method to Master Loot.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/gl or /group or /grouploot - Change loot method to Group Loot.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("Please report any bugs or problems caused by this addon to your guild leader.",1,1,0);
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function ColdEmbrace_OnEvent()
	if event == "CHAT_MSG_SYSTEM" then
		if strfind(arg1, "No players are AFK", 1) then
			SendChatMessage("No players are AFK", "RAID"); end
		if strfind(arg1, "(.*) is not ready", 1) then
			SendChatMessage("...group member is not ready !", "RAID"); end
		if strfind(arg1, "The following players are AFK", 1) then
			SendChatMessage("...some group members are AFK !", "RAID"); end
		if strfind(arg1, "You are now", 1) and strfind(arg1, "(AFK)", 1) then
			inInstance, instanceType = IsInInstance()
			inRaidInstance  = (instanceType == 'raid');
			if inRaidInstance then
				SendChatMessage("I am AFK (..offline in 20 seconds..)", "RAID");
				Logout(); 
			end
		end
	elseif event == "RESURRECT_REQUEST" then
		UIErrorsFrame:AddMessage(arg1.." - Resurrection")
		TargetByName(arg1, true)
		if GetCorpseRecoveryDelay() == 0 and UnitIsPlayer("target") and UnitIsVisible("target") and not UnitAffectingCombat("target") then
			AcceptResurrect()
			StaticPopup_Hide("RESURRECT_NO_TIMER"); 
			StaticPopup_Hide("RESURRECT_NO_SICKNESS");
			StaticPopup_Hide("RESURRECT");
		end
		TargetLastTarget();
	elseif event == "CHAT_MSG_OFFICER" then
		if strfind(arg1, "Please do a Ready Check", 1) then
			isLeader = IsRaidLeader() 
			if isLeader then
				DoReadyCheck();
				--SendChatMessage("Starting ReadyCheck...", "OFFICER"); 
			end end
		if strfind(arg1, "Please change to Master Loot", 1) then
			playerName = UnitName("Player");
			isLeader = IsRaidLeader() 
			if isLeader then
				SetLootMethod("master", playerName);
				--SendChatMessage("is now the loot master", "OFFICER"); 
			end end
		if strfind(arg1, "Please change to Group Loot", 1) then
			isLeader = IsRaidLeader() 
			if isLeader then
				SetLootMethod("Group", "1");
				--SendChatMessage("GroupLoot activated", "OFFICER"); 
			end
		end
	elseif event == "CHAT_MSG_WHISPER" then
		if strfind(arg1, "CE_LogoutPlease", 1) then
			isLeader = IsRaidLeader() 
			inInstance, instanceType = IsInInstance()
			inRaidInstance  = (instanceType == 'raid');
			if inRaidInstance then
				if not isLeader then
					Logout(); 
				end
			else
				SendChatMessage("Logout prevented: Player is not in the raid instance.", "RAID");
			end
		end
	elseif event == "CHAT_MSG_RAID_WARNING" then
		if strfind(arg1, "CE_Roll:", 1) then
		itemLink = arg1

			Chronos.scheduleByName("Clear", 0.1, CE_ClearFrames);
			Chronos.scheduleByName("Draw", 0.2, CE_DrawFrames);
			Chronos.scheduleByName("Erase", 30, CE_ClearFrames);
			
		elseif strfind(arg1, "awarded", 1) then
			CE_ClearFrames()
		elseif strfind(arg1, "CE_VersionCheck:", 1) then
			if strfind(arg1, "CE_VersionCheck: 001", 1) then
			else
				SendChatMessage("Addon: OUT OF DATE", "RAID");
			end
		elseif strfind(arg1, "CE_EveryoneLogout", 1) then
			isLeader = IsRaidLeader() 
			inInstance, instanceType = IsInInstance()
			inRaidInstance  = (instanceType == 'raid');
			if inRaidInstance then
				if not isLeader then
					Logout(); 
				end
			else
				SendChatMessage("Logout prevented: Player is not in the raid instance.", "RAID");
			end
		end
	elseif event == "START_LOOT_ROLL" then
		CE_AutoRoll(arg1)

	end
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function CE_VersionCheck()
	SendChatMessage("CE_VersionCheck: 001", "RAID_WARNING");
end

function CE_LogoutRaid()
	SendChatMessage("CE_EveryoneLogout", "RAID_WARNING");
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function ColdEmbraceAdvertise()
	id, name = GetChannelName("World");
	SendChatMessage("Cold Embrace (EU) - Looking for more players to join our guild. We offer casual raid environment and a friendly guild atmosphere. Whisper for more info." ,"CHANNEL" ,nil ,id);
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function ColdEmbrace_MainSpecRoll()		
	guild = ("Cold Embrace");
	guildName, guildRankName, guildRankIndex = GetGuildInfo("Player");
	playerName = UnitName("Player");
	if guildName == guild then
		for i = 1,450 do
			name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i);
			playerName = UnitName("Player");
			if name == playerName then
				if officernote == ("") then RandomRoll(0,99);
				else
					RandomRoll(officernote*0.75,officernote*0.25+100);
				end
			end
		end
	else 
		RandomRoll(1,100);
	end
end

function ColdEmbrace_OffSpecRoll()
	RandomRoll(1,69);
end

function CE_AutoRoll(id)
	local  inInstance, instanceType = IsInInstance()
	notInInstance   = (instanceType == 'none');
	inPartyInstance = (instanceType == 'party');
	inRaidInstance  = (instanceType == 'raid');
	inArenaInstance = (instanceType == 'arena');
	inPvPInstance   = (instanceType == 'pvp');
	isLeader = IsRaidLeader();
	class = UnitClass("Player");
	


	RollReturn = function()
		local txt = ""
		if isLeader then
			txt = "NEED"
		elseif not isLeader then
			txt = "PASS"
		end
		return txt
	end
	if inRaidInstance then	
		local _, name, _, quality = GetLootRollItemInfo(id);

		if string.find(name ,"Hakkari Bijou") 
		or string.find(name ,"Coin") then

			RollOnLoot(id, 1);
			local _, _, _, hex = GetItemQualityColor(quality)
			DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto NEED "..hex..GetLootRollItemLink(id))
			return
		
		elseif string.find(name ,"Blood of the Mountain") 
			or string.find(name ,"Fiery Core") 
			or string.find(name ,"Lava Core") 

			or string.find(name ,"Heart of Fire") 
			or string.find(name ,"Elemental Earth") 
			or string.find(name ,"Elemental Air") 
			or string.find(name ,"Elemental Water")
		
			or string.find(name ,"Elementium Ore") 
			or string.find(name ,"Hourglass Sand") 
			 
			or string.find(name ,"Scarab") 
			or (string.find(name ,"Idol") and not string.find(name ,"Primal Hakkari")) 
			
			or string.find(name ,"Ironweb Spider Silk") 
			or string.find(name ,"Wartorn") 
			or string.find(name ,"Word of Thawing")
			then

				if isLeader then RollOnLoot(id, 1); end
				if not isLeader then RollOnLoot(id, 0); end
				local _, _, _, hex = GetItemQualityColor(quality)
				DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
				return

			-- Priest
		elseif string.find(name ,"Vambraces of Prophecy") 
			or string.find(name ,"Girdle of Prophecy") 
			then

				if not isLeader and not class == "Priest" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0); end
				local _, _, _, hex = GetItemQualityColor(quality)
				DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
				return

			-- Mage
		elseif string.find(name ,"Arcanist Bindings") 
			or string.find(name ,"Arcanist Belt")
			or string.find(name ,"Ringo's Blizzard Boots")
			then

				if not isLeader and not class == "Mage" and 
				(class == "Priest" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0); end
				local _, _, _, hex = GetItemQualityColor(quality)
				DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
				return	
			
			-- Warlock
		elseif string.find(name ,"Felheart Bracers") 
			or string.find(name ,"Felheart Belt") 
			then

				if not isLeader and not class == "Warlock" and 
				(class == "Mage" or class == "Priest" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0); end
				local _, _, _, hex = GetItemQualityColor(quality)
				DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
				return

			-- Rogue
		elseif string.find(name ,"Nightslayer Bracelets") 
			or string.find(name ,"Nightslayer Belt")
			then

				if not isLeader and not class == "Rogue" and 
				(class == "Mage" or class == "Warlock" or class == "Priest" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0); end
				local _, _, _, hex = GetItemQualityColor(quality)
				DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
				return

			-- Druid
		elseif string.find(name ,"Cenarion Bracers") 
			or string.find(name ,"Cenarion Belt")
			then

				if not isLeader and not class == "Druid" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Priest" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0); end
				local _, _, _, hex = GetItemQualityColor(quality)
				DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
				return

			-- Hunter
		elseif string.find(name ,"Giantstalker's Bracers") 
			or string.find(name ,"Giantstalker's  Belt")
			then

				if not isLeader and not class == "Hunter" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Priest" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0); end
				local _, _, _, hex = GetItemQualityColor(quality)
				DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
				return

			-- Shaman
		elseif string.find(name ,"Earthfury Bracers") 
			or string.find(name ,"Earthfury Belt")
			or string.find(name ,"Pauldrons of Elemental Fury") 
			or string.find(name ,"Leggings of Elemental Fury")
			then

				if not isLeader and not class == "Shaman" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Priest" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0); end
				local _, _, _, hex = GetItemQualityColor(quality)
				DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
				return

			-- Warrior
		elseif string.find(name ,"Bracers of Might") 
			or string.find(name ,"Belt of Might")
			then

				if not isLeader and not class == "Warrior" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Priest" or class == "Paladin") then 
					RollOnLoot(id, 0); end
				local _, _, _, hex = GetItemQualityColor(quality)
				DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
				return

			-- Paladin
		elseif string.find(name ,"Lawbringer Bracers") 
			or string.find(name ,"Lawbringer Belt")
			or string.find(name ,"Gloves of the Redeemed Prophecy")
			or string.find(name ,"Spaulders of the Grand Crusader")
			or string.find(name ,"Belt of the Grand Crusader")
			or string.find(name ,"Leggings of the Grand Crusader")
			then

				if not isLeader and not class == "Paladin" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Priest") then 
					RollOnLoot(id, 0); end
				local _, _, _, hex = GetItemQualityColor(quality)
				DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
				return

		end
	end	
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function ColdEmbrace_ReadyCheck()
	isLeader  = IsRaidLeader();
	isOfficer = IsRaidOfficer();
	if isLeader then
		DoReadyCheck();
	elseif isOfficer then 
		SendChatMessage("Please do a Ready Check", "OFFICER"); 
	else
		DEFAULT_CHAT_FRAME:AddMessage("You are not a Raid Leader/Assistant.");
	end
end

function ColdEmbrace_MasterLoot()
	isLeader  = IsRaidLeader();
	isOfficer = IsRaidOfficer(); 
	playerName = UnitName("Player");
	lootmethod = GetLootMethod();
	if lootmethod == ("master") then DEFAULT_CHAT_FRAME:AddMessage("Master Looter already set."); 
	elseif lootmethod == ("group") or lootmethod == ("freeforall") or lootmethod == ("roundrobin") or lootmethod == ("needbeforegreed") then
		if isLeader then SetLootMethod("master", playerName);
		elseif isOfficer then SendChatMessage("Please change to Master Loot", "OFFICER"); 
		else DEFAULT_CHAT_FRAME:AddMessage("You are not a Raid Leader/Assistant."); end
	end
end

function ColdEmbrace_GroupLoot()
	isLeader  = IsRaidLeader();
	isOfficer = IsRaidOfficer(); 
	lootmethod = GetLootMethod();
	if lootmethod == ("group") then DEFAULT_CHAT_FRAME:AddMessage("Group Loot already set.");
	elseif lootmethod == ("master") or lootmethod == ("freeforall") or lootmethod == ("roundrobin") or lootmethod == ("needbeforegreed") then
		if isLeader then SetLootMethod("group","1");
		elseif isOfficer then SendChatMessage("Please change to Group Loot", "OFFICER");
		else DEFAULT_CHAT_FRAME:AddMessage("You are not a Raid Leader/Assistant."); end
	end
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function ColdEmbrace_RaidInvites()	

	if GetNumRaidMembers()  < 5 then SendChatMessage("Starting RAID group!", "GUILD"); end
	if GetNumRaidMembers() >= 0 then SendChatMessage("Write + for raid invite", "GUILD"); end
	if GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 then ConvertToRaid(); end

	Chronos.scheduleByName("StartInvites", 1, ColdEmbrace_SearchInvite);
end

function ColdEmbrace_SearchInvite()
	guild = ("Cold Embrace");
	guildName, guildRankName, guildRankIndex = GetGuildInfo("Player");
	playerName = UnitName("Player");
	if guildRankIndex <= 3 then
		for i = 1,450 do
			name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i);
			if rankIndex <= 6 and online == 1 then
				InviteByName(name);
			end
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("Your rank is not high enough to do that.");
	end
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function ColdEmbraceAttackStart()
	if not UnitIsDeadOrGhost("Target") then 
		if not AttackFound then
			for i = 1,99 do 
				if IsAttackAction(i) then 
					AttackFound = i; 
				end; 
			end; 
		end; 
		if AttackFound then
			if not IsCurrentAction(AttackFound) then UseAction(AttackFound); 
			end
		end
	elseif UnitIsDeadOrGhost("Target") then ClearTarget(); end
end

function ColdEmbraceAttackStop()
	if not UnitIsDeadOrGhost("Target") then 
		if not AttackFound then
			for i = 1,99 do 
				if IsAttackAction(i) then 
					AttackFound = i; 
				end; 
			end; 
		end; 
		if AttackFound then
			if IsCurrentAction(AttackFound) then UseAction(AttackFound); 
			end
		end
	elseif UnitIsDeadOrGhost("Target") then ClearTarget(); end
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function CE_DrawFrames()
	--if ColdEmbraceVariables.RollFrame > 0 then
		CE_ItemFrame();
		CE_NeedFrame(); ColdEmbraceMS:Show(); 
		CE_GreedFrame(); ColdEmbraceOS:Show();
		CE_PassFrame(); ColdEmbracePS:Show();
	--end
end

function CE_ClearFrames()
	--DEFAULT_CHAT_FRAME:AddMessage("Roll frames cleared",0,1,0);
	if ItemFrameCE and ItemFrameCE:IsVisible() then ItemFrameCE:Hide(); end
	if NeedFrameCE and NeedFrameCE:IsVisible() then NeedFrameCE:Hide(); ColdEmbraceMS:Hide(); end
	if GreedFrameCE and GreedFrameCE:IsVisible() then GreedFrameCE:Hide(); ColdEmbraceOS:Hide(); end
	if PassFrameCE and PassFrameCE:IsVisible() then PassFrameCE:Hide(); ColdEmbracePS:Hide(); end
end

function CE_RollFramesToggle()
	--if ColdEmbraceVariables.RollFrame < 1 then 
	--	ColdEmbraceVariables.RollFrame = 1
	--	DEFAULT_CHAT_FRAME:AddMessage("Roll frames enabled",0,1,0);
	--else
	--	ColdEmbraceVariables.RollFrame = 0
	--	DEFAULT_CHAT_FRAME:AddMessage("Roll frames disabled",0,1,0);
	--end
	--return
end

function CE_ItemFrame()
	if not ItemFrameCE then
		ItemFrameCE = CreateFrame("Button", "ItemFrameCE", UIParent)
		ItemFrameCE:ClearAllPoints()
		ItemFrameCE:SetWidth(450)
		ItemFrameCE:SetHeight(32)
		ItemFrameCE:SetPoint("CENTER", 195, 85)
		ItemFrameCE.text = ItemFrameCE:CreateFontString("Status", "LOW", "GameFontNormal")
		ItemFrameCE.text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		ItemFrameCE.text:ClearAllPoints()
		ItemFrameCE.text:SetAllPoints(ItemFrameCE)
		ItemFrameCE.text:SetPoint("CENTER", 0, 0)
		ItemFrameCE.text:SetFontObject(GameFontWhite)
		ItemFrameCE:SetMovable(true)
		ItemFrameCE:EnableMouse(true)
		ItemFrameCE:SetScript("OnUpdate", function()
			this.text:SetText(itemLink)
			--ItemFrameCE:Show()
		end)
		ItemFrameCE:SetScript("OnMouseDown", function()
			if arg1 == 'LeftButton' then
				this:StartMoving()
				--print("OnMouseDown")
			end
		end)
		ItemFrameCE:SetScript("OnMouseUp", function()
			this:StopMovingOrSizing()
			this:SetUserPlaced(true)
			--print("OnMouseUp", button)
		end)
	end
	ItemFrameCE:Show();
end

function CE_NeedFrame()
	if not NeedFrameCE then
		NeedFrameCE = CreateFrame("Button",nil,UIParent)
		--NeedFrameCE:SetFrameStrata("BACKGROUND")
		NeedFrameCE:SetWidth(32)
		NeedFrameCE:SetHeight(32)
		NeedFrameCE:SetMovable(true)
		
		NeedFrameCE:SetScript("OnClick", function()
			ColdEmbrace_OnClickMS();
			ColdEmbraceMS:Hide();
			ColdEmbraceOS:Hide();
			ColdEmbracePS:Hide();
		end)

		local t = NeedFrameCE:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\Addons\\ColdEmbrace\\ms_icon.tga")
		t:SetAllPoints(NeedFrameCE)
		NeedFrameCE.texture = t

		NeedFrameCE:SetPoint("CENTER", ItemFrameCE,-50,-30)
	end
	NeedFrameCE:Show()
end

function CE_GreedFrame()
	if not GreedFrameCE then
		GreedFrameCE = CreateFrame("Button",nil,UIParent)
		--GreedFrameCE:SetFrameStrata("BACKGROUND")
		GreedFrameCE:SetWidth(32)  
		GreedFrameCE:SetHeight(32) 
		GreedFrameCE:SetMovable(true)

		GreedFrameCE:SetScript("OnClick", function()
			ColdEmbrace_OnClickOS();
			ColdEmbraceMS:Hide();
			ColdEmbraceOS:Hide();
			ColdEmbracePS:Hide();
		end)

		local t = GreedFrameCE:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\Addons\\ColdEmbrace\\os_icon.tga")
		t:SetAllPoints(GreedFrameCE)
		GreedFrameCE.texture = t

		GreedFrameCE:SetPoint("CENTER", ItemFrameCE,0,-30)
	end
	GreedFrameCE:Show()
end

function CE_PassFrame()
	if not PassFrameCE then
		PassFrameCE = CreateFrame("Button",nil,UIParent)
		--PassFrameCE:SetFrameStrata("BACKGROUND")
		PassFrameCE:SetWidth(32) 
		PassFrameCE:SetHeight(32) 
		PassFrameCE:SetMovable(true)

		PassFrameCE:SetScript("OnClick", function()
			ColdEmbrace_OnClickPS();
			ColdEmbraceMS:Hide();
			ColdEmbraceOS:Hide();
			ColdEmbracePS:Hide();
		end)

		local t = PassFrameCE:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\Addons\\ColdEmbrace\\ps_icon.tga")
		t:SetAllPoints(PassFrameCE)
		PassFrameCE.texture = t

		PassFrameCE:SetPoint("CENTER", ItemFrameCE, 50, -30)
	end
	PassFrameCE:Show()
end

function ColdEmbrace_OnClickMS()
	ColdEmbrace_MainSpecRoll()	
	if ItemFrameCE:IsVisible() then ItemFrameCE:Hide(); end
	if NeedFrameCE:IsVisible() then NeedFrameCE:Hide(); end
	if GreedFrameCE:IsVisible() then GreedFrameCE:Hide(); end
	if PassFrameCE:IsVisible() then PassFrameCE:Hide(); end
end

function ColdEmbrace_OnClickOS()
	ColdEmbrace_OffSpecRoll()	
	if ItemFrameCE:IsVisible() then ItemFrameCE:Hide(); end
	if NeedFrameCE:IsVisible() then NeedFrameCE:Hide(); end
	if GreedFrameCE:IsVisible() then GreedFrameCE:Hide(); end
	if PassFrameCE:IsVisible() then PassFrameCE:Hide(); end
end

function ColdEmbrace_OnClickPS()
	if ItemFrameCE:IsVisible() then ItemFrameCE:Hide(); end
	if NeedFrameCE:IsVisible() then NeedFrameCE:Hide(); end
	if GreedFrameCE:IsVisible() then GreedFrameCE:Hide(); end
	if PassFrameCE:IsVisible() then PassFrameCE:Hide(); end
end
