-------------------------------------------------------------------------------------------------------------
BINDING_HEADER_COLDEMBRACE = "ColdEmbrace";
-------------------------------------------------------------------------------------------------------------
-- Official Guild Addon of 'Cold Embrace' at Turtle WoW (https://turtle-wow.org)
-- created by Sebben/Anachrony (https://github.com/Sebben7Sebben) and modified by Melbaa/Psykhe (https://github.com/melbaa)

--[ References ]--

local OriginalUIErrorsFrame_OnEvent;

local addon_version = "1.03.01"
local addon_prefix_version = 'CEVersion'
local addon_prefix_version_force_announce = 'CEVAnnounce'
local addon_version_cache = {}

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
	this:RegisterEvent("CHAT_MSG_ADDON");
	this:RegisterEvent("PLAYER_ENTERING_WORLD");

	SLASH_COLDEMBRACE1 = "/ce";
	SLASH_COLDEMBRACE2 = "/coldembrace";
	SlashCmdList["COLDEMBRACE"] = ColdEmbrace_Help;

	SLASH_CERMS1 = "/rms";
	SLASH_CERMS2 = "/rollms";
	SlashCmdList["CERMS"] = ColdEmbrace_MainSpecRoll;

	SLASH_CEROS1 = "/ros";
	SLASH_CEROS2 = "/rollos";
	SlashCmdList["CEROS"] = ColdEmbrace_OffSpecRoll;

	SLASH_CERXMG1 = "/rxmg";
	SLASH_CERXMG2 = "/rollxmg";
	SlashCmdList["CERXMG"] = ColdEmbrace_XMogRoll;

	SLASH_CERLD1 = "/rl";
	SLASH_CERLD2 = "/reload";
	SlashCmdList["CERLD"] = ReloadUI;

	SLASH_CERI1 = "/reset";
	SLASH_CERI2 = "/resetinstance";
	SLASH_CERI3 = "/resetinstances";
	SlashCmdList["CERI"] = ResetInstances;

	SLASH_CEATKSTART1 = "/attackstart";
	SlashCmdList["CEATKSTART"] = ColdEmbraceAttackStart;

	SLASH_CEATKSTOP1 = "/attackstop";
	SlashCmdList["CEATKSTOP"] = ColdEmbraceAttackStop;

	SLASH_CEVC1 = "/cevc";
	SlashCmdList["CEVC"] = ColdEmbrace_VersionCheck;
	SLASH_CEVA1 = "/ceva";
	SlashCmdList["CEVA"] = ColdEmbrace_VersionForceAnnounce;

end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function ColdEmbrace_Help()
	DEFAULT_CHAT_FRAME:AddMessage("Thank you for downloading the Cold Embrace guild addon.",1,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("Version: "..addon_version,1,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("List of usable commands:",0,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("/rl or /reload - Reload UI.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/reset or /resetinstance or /resetinstances - Reset Instances.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/rms or /rollms - Main Spec roll.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/ros or /rollos - Off Spec roll.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/rxmg or /rollxmg - Transmog roll.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/attackstart and /attackstop - spammable start/stop attacking command (requires Attack from spellbook General tab to be ANYWHERE on the action bar):",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("Please report any bugs or problems caused by this addon to your guild leader.",1,1,0);
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function ColdEmbrace_OnEvent()
	if event == "CHAT_MSG_SYSTEM" then
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
			Chronos.scheduleByName("Erase", 22, CE_ClearFrames);
			
		elseif strfind(arg1, "awarded", 1) then
			CE_ClearFrames()
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

	elseif event == "PLAYER_ENTERING_WORLD" then
		ColdEmbrace_AnnounceMyVersion()
	elseif event == "CHAT_MSG_ADDON" then
		if arg1 == addon_prefix_version then
			ColdEmbrace_OnVersionAnnounce(arg2, arg3, arg4)
		elseif arg1 == addon_prefix_version_force_announce then
			ColdEmbrace_AnnounceMyVersion()
		end
	end
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
				if officernote == ("") then RandomRoll(0,100);
				else
					RandomRoll(officernote*0.7,officernote*0.5+100);
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

function ColdEmbrace_XMogRoll()
	RandomRoll(1,50);
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
			or string.find(name ,"Elemental Fire")
		
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

				if not isLeader and --not class == "Priest" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0);
					local _, _, _, hex = GetItemQualityColor(quality)
					DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
					return
				end

			-- Mage
		elseif string.find(name ,"Arcanist Bindings") 
			or string.find(name ,"Arcanist Belt")
			or string.find(name ,"Ringo's Blizzard Boots")
			then

				if not isLeader and --not class == "Mage" and 
				(class == "Priest" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0);
					local _, _, _, hex = GetItemQualityColor(quality)
					DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
					return
				end
			
			-- Warlock
		elseif string.find(name ,"Felheart Bracers") 
			or string.find(name ,"Felheart Belt") 
			then

				if not isLeader and --not class == "Warlock" and 
				(class == "Mage" or class == "Priest" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0);
					local _, _, _, hex = GetItemQualityColor(quality)
					DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
					return
				end

			-- Rogue
		elseif string.find(name ,"Nightslayer Bracelets") 
			or string.find(name ,"Nightslayer Belt")
			then

				if not isLeader and --not class == "Rogue" and 
				(class == "Mage" or class == "Warlock" or class == "Priest" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0);
					local _, _, _, hex = GetItemQualityColor(quality)
					DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
					return
				end

			-- Druid
		elseif string.find(name ,"Cenarion Bracers") 
			or string.find(name ,"Cenarion Belt")
			then

				if not isLeader and --not class == "Druid" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Priest" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0);
					local _, _, _, hex = GetItemQualityColor(quality)
					DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
					return
				end

			-- Hunter
		elseif string.find(name ,"Giantstalker's Bracers") 
			or string.find(name ,"Giantstalker's  Belt")
			then

				if not isLeader and --not class == "Hunter" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Priest" or class == "Shaman" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0);
					local _, _, _, hex = GetItemQualityColor(quality)
					DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
					return
				end

			-- Shaman
		elseif string.find(name ,"Earthfury Bracers") 
			or string.find(name ,"Earthfury Belt")
			or string.find(name ,"Pauldrons of Elemental Fury") 
			or string.find(name ,"Leggings of Elemental Fury")
			then

				if not isLeader and --not class == "Shaman" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Priest" or class == "Warrior" or class == "Paladin") then 
					RollOnLoot(id, 0);
					local _, _, _, hex = GetItemQualityColor(quality)
					DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
					return
				end

			-- Warrior
		elseif string.find(name ,"Bracers of Might") 
			or string.find(name ,"Belt of Might")
			then

				if not isLeader and --not class == "Warrior" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Priest" or class == "Paladin") then 
					RollOnLoot(id, 0);
					local _, _, _, hex = GetItemQualityColor(quality)
					DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
					return
				end

			-- Paladin
		elseif string.find(name ,"Lawbringer Bracers") 
			or string.find(name ,"Lawbringer Belt")
			or string.find(name ,"Gloves of the Redeemed Prophecy")
			or string.find(name ,"Spaulders of the Grand Crusader")
			or string.find(name ,"Belt of the Grand Crusader")
			or string.find(name ,"Leggings of the Grand Crusader")
			then

				if not isLeader and --not class == "Paladin" and 
				(class == "Mage" or class == "Warlock" or class == "Rogue" or class == "Druid" or class == "Hunter" or class == "Shaman" or class == "Warrior" or class == "Priest") then 
					RollOnLoot(id, 0);
					local _, _, _, hex = GetItemQualityColor(quality)
					DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
					return
				end

		end
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
		CE_XmogFrame(); ColdEmbraceXmg:Show();
		CE_PassFrame(); ColdEmbracePS:Show();
	--end
end

function CE_ClearFrames()
	--DEFAULT_CHAT_FRAME:AddMessage("Roll frames cleared",0,1,0);
	if ItemFrameCE and ItemFrameCE:IsVisible() then ItemFrameCE:Hide(); end
	if NeedFrameCE and NeedFrameCE:IsVisible() then NeedFrameCE:Hide(); ColdEmbraceMS:Hide(); end
	if GreedFrameCE and GreedFrameCE:IsVisible() then GreedFrameCE:Hide(); ColdEmbraceOS:Hide(); end
	if XmogFrameCE and XmogFrameCE:IsVisible() then XmogFrameCE:Hide(); ColdEmbraceXmg:Hide(); end
	if PassFrameCE and PassFrameCE:IsVisible() then PassFrameCE:Hide(); ColdEmbracePS:Hide(); end
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
			end
		end)
		ItemFrameCE:SetScript("OnMouseUp", function()
			this:StopMovingOrSizing()
			this:SetUserPlaced(true)
		end)
		ItemFrameCE:SetScript("OnEnter", function()
			GameTooltip:SetOwner(ItemFrameCE, "ANCHOR_CURSOR")
			if not itemLink then return end
			local _, _, itemId = string.find(itemLink, "item:(%d+):%d+:%d+:%d+")
			if not itemId then return end
			GameTooltip:SetHyperlink('item:' .. itemId .. ":0:0:0")
			GameTooltip:Show()
		end)
		ItemFrameCE:SetScript("OnLeave", function()
			GameTooltip:Hide()
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
			ColdEmbraceXmg:Hide();
			ColdEmbracePS:Hide();
		end)

		local t = NeedFrameCE:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\Addons\\ColdEmbrace\\ms_icon.tga")
		t:SetAllPoints(NeedFrameCE)
		NeedFrameCE.texture = t

		NeedFrameCE:SetPoint("CENTER", ItemFrameCE,-75,-30)
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
			ColdEmbraceXmg:Hide();
			ColdEmbracePS:Hide();
		end)

		local t = GreedFrameCE:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\Addons\\ColdEmbrace\\os_icon.tga")
		t:SetAllPoints(GreedFrameCE)
		GreedFrameCE.texture = t

		GreedFrameCE:SetPoint("CENTER", ItemFrameCE,-25,-30)
	end
	GreedFrameCE:Show()
end

function CE_XmogFrame()
	if not XmogFrameCE then
		XmogFrameCE = CreateFrame("Button",nil,UIParent)
		--XmogFrameCE:SetFrameStrata("BACKGROUND")
		XmogFrameCE:SetWidth(32) 
		XmogFrameCE:SetHeight(32) 
		XmogFrameCE:SetMovable(true)

		XmogFrameCE:SetScript("OnClick", function()
			ColdEmbrace_OnClickXmg()
			ColdEmbraceMS:Hide();
			ColdEmbraceOS:Hide();
			ColdEmbraceXmg:Hide();
			ColdEmbracePS:Hide();
		end)

		local t = XmogFrameCE:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\Addons\\ColdEmbrace\\xmg_icon.tga")
		t:SetAllPoints(XmogFrameCE)
		XmogFrameCE.texture = t

		XmogFrameCE:SetPoint("CENTER", ItemFrameCE, 25, -30)
	end
	XmogFrameCE:Show()
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
			ColdEmbraceXmg:Hide();
			ColdEmbracePS:Hide();
		end)

		local t = PassFrameCE:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\Addons\\ColdEmbrace\\ps_icon.tga")
		t:SetAllPoints(PassFrameCE)
		PassFrameCE.texture = t

		PassFrameCE:SetPoint("CENTER", ItemFrameCE, 75, -30)
	end
	PassFrameCE:Show()
end

function ColdEmbrace_OnClickMS()
	ColdEmbrace_MainSpecRoll()	
	if ItemFrameCE:IsVisible() then ItemFrameCE:Hide(); end
	if NeedFrameCE:IsVisible() then NeedFrameCE:Hide(); end
	if GreedFrameCE:IsVisible() then GreedFrameCE:Hide(); end
	if XmogFrameCE:IsVisible() then XmogFrameCE:Hide(); end
	if PassFrameCE:IsVisible() then PassFrameCE:Hide(); end
end

function ColdEmbrace_OnClickOS()
	ColdEmbrace_OffSpecRoll()	
	if ItemFrameCE:IsVisible() then ItemFrameCE:Hide(); end
	if NeedFrameCE:IsVisible() then NeedFrameCE:Hide(); end
	if GreedFrameCE:IsVisible() then GreedFrameCE:Hide(); end
	if XmogFrameCE:IsVisible() then XmogFrameCE:Hide(); end
	if PassFrameCE:IsVisible() then PassFrameCE:Hide(); end
end

function ColdEmbrace_OnClickXmg()
	ColdEmbrace_XMogRoll()
	if ItemFrameCE:IsVisible() then ItemFrameCE:Hide(); end
	if NeedFrameCE:IsVisible() then NeedFrameCE:Hide(); end
	if GreedFrameCE:IsVisible() then GreedFrameCE:Hide(); end
	if XmogFrameCE:IsVisible() then XmogFrameCE:Hide(); end
	if PassFrameCE:IsVisible() then PassFrameCE:Hide(); end
end

function ColdEmbrace_OnClickPS()
	if ItemFrameCE:IsVisible() then ItemFrameCE:Hide(); end
	if NeedFrameCE:IsVisible() then NeedFrameCE:Hide(); end
	if GreedFrameCE:IsVisible() then GreedFrameCE:Hide(); end
	if XmogFrameCE:IsVisible() then XmogFrameCE:Hide(); end
	if PassFrameCE:IsVisible() then PassFrameCE:Hide(); end
end


function ColdEmbrace_AnnounceMyVersion()
    --SendAddonMessage(addon_prefix_version, addon_version, "PARTY")
    --SendAddonMessage(addon_prefix_version, addon_version, "GUILD")
    SendAddonMessage(addon_prefix_version, addon_version, "RAID")
    --SendAddonMessage(addon_prefix_version, addon_version, "BATTLEGROUND")
end

function ColdEmbrace_VersionForceAnnounce()
    --SendAddonMessage(addon_prefix_version_force_announce, addon_version, "PARTY")
    --SendAddonMessage(addon_prefix_version_force_announce, addon_version, "GUILD")
    SendAddonMessage(addon_prefix_version_force_announce, addon_version, "RAID")
    --SendAddonMessage(addon_prefix_version_force_announce, addon_version, "BATTLEGROUND")
	DEFAULT_CHAT_FRAME:AddMessage("requested a version announce by all members")
end

function ColdEmbrace_OnVersionAnnounce(version, where, who)
	addon_version_cache[who] = version
end

function ColdEmbrace_VersionCheck()
	-- TODO colorful output

	local raid_members = {}

	for i = 1, GetNumRaidMembers() do
		local unit = 'raid' .. i
		local who = UnitName(unit)
		table.insert(raid_members, who)
	end

	if table.getn(raid_members) == 0 then
		DEFAULT_CHAT_FRAME:AddMessage("no players found. are you in a raid?")
		return
	end

	DEFAULT_CHAT_FRAME:AddMessage("addon versions:")
	local num_issues = 0

	table.sort(raid_members)

	for i, who in ipairs(raid_members) do
		local version = tostring(addon_version_cache[who])

		local extra_info = nil
		if version == 'nil' then
			extra_info = 'unknown'
		elseif version ~= addon_version then
			extra_info = 'outdated/different'
		end
		if extra_info then
			DEFAULT_CHAT_FRAME:AddMessage(who .. ' ' .. version .. ' ' .. extra_info)
			num_issues = num_issues + 1
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage("addon versions summary: " .. num_issues .. ' issues')
end
