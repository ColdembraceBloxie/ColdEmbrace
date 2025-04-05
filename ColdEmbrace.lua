-------------------------------------------------------------------------------------------------------------
BINDING_HEADER_COLDEMBRACE = "ColdEmbrace";
-------------------------------------------------------------------------------------------------------------
-- Official Guild Addon of 'Cold Embrace' at Turtle WoW (https://turtle-wow.org)
-- created by Sebben/Anachrony (https://github.com/Sebben7Sebben), modified by Melbaa/Psykhe (https://github.com/melbaa) and Bloxie (https://github.com/ColdembraceBloxie)

--[ References ]--

local OriginalUIErrorsFrame_OnEvent;

local addon_version = "1.04.02"
local addon_prefix_version = 'CEVersion'
local addon_prefix_version_force_announce = 'CEVAnnounce'
local addon_version_cache = {}

--[ Settings ]--
ColdEmbraceVariables = {
	RollFrame = 1,

	-- Skin:
	--  0 = disable backdrop visuals
	--  1 = autodetect-pfUI theme
	--  2 = enforce blizzard theme
	Skin = 1,
};

local ItemFrameCE = nil
local NeedFrameCE = nil
local OffspecFrameCE = nil
local GreedFrameCE = nil
local PassFrameCE = nil

local me = UnitName('player')

local backdrops = {}
local function CreateBackdrop(frame)
	if not backdrops[frame] then backdrops[frame] = true end

	if ColdEmbraceVariables.Skin == 0 then
		frame:SetBackdrop(nil)
		return
	elseif ColdEmbraceVariables.Skin == 1 and pfUI and pfUI.uf and pfUI.api then
		pfUI.api.CreateBackdrop(frame, nil, true, .75)
		return
	end

	frame:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	frame:SetBackdropColor(.2,.2,.2,.8)
	frame:SetBackdropBorderColor(.4,.4,.4,1)
end

local buttons = {}
local function CreateButton(frame)
	if not buttons[frame] then buttons[frame] = true end

	if ColdEmbraceVariables.Skin == 0 then
		-- legacy style (all translucent)
		frame:SetHighlightTexture(nil)
		frame:SetBackdrop(nil)
	elseif ColdEmbraceVariables.Skin == 1 and pfUI and pfUI.uf and pfUI.api then
		-- pfUI style (using pfUI API)
		pfUI.api.SkinButton(frame)
		frame.locked = false
	else
		-- default style
		CreateBackdrop(frame)
		frame:SetHighlightTexture("Interface\\Buttons\\CheckButtonHilight")
		frame:GetHighlightTexture():SetAlpha(0.5)
		frame.locked = true
	end
end

local function UpdateSkin()
	-- reset current item
	ItemFrameCE.item.itemLink = nil

	-- update all current backdrop
	for backdrop in pairs(backdrops) do
		CreateBackdrop(backdrop)
	end

	for button in pairs(buttons) do
		CreateButton(button)
	end
end

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

	SLASH_CERFS1 = "/rfs";
	SLASH_CERFS2 = "/rollfs";
	SlashCmdList["CERFS"] = ColdEmbrace_GreedRoll;

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

	SLASH_CEAR1 = "/autores";
	SlashCmdList["CEAR"] = ColdEmbrace_AutomaticResurrection;

	SLASH_CEATKSTART1 = "/attackstart";
	SlashCmdList["CEATKSTART"] = ColdEmbraceAttackStart;

	SLASH_CEATKSTOP1 = "/attackstop";
	SlashCmdList["CEATKSTOP"] = ColdEmbraceAttackStop;

	SLASH_CEVC1 = "/cevc";
	SlashCmdList["CEVC"] = ColdEmbrace_VersionCheck;
	SLASH_CEVRA1 = "/cevra";
	SlashCmdList["CEVRA"] = ColdEmbrace_VersionRaidAnnounce;
	SLASH_CEVA1 = "/ceva";
	SlashCmdList["CEVA"] = ColdEmbrace_VersionForceAnnounce;

end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function CE_FindSpell (spellName, caseinsensitive)
	spellName = string.lower(spellName);
	local maxSpells = 500;
	local id = 0;
	local searchName;
	local subName;
	while (id <= maxSpells) do
		id = id + 1;
		searchName, subName = GetSpellName(id,BOOKTYPE_SPELL);
		if (searchName) then
			if (string.lower(searchName) == string.lower(spellName)) then
				local nextName, nextSubName = GetSpellName(id+1, BOOKTYPE_SPELL);
				if (string.lower(nextName) ~= string.lower(searchName)) then
					break;
				end
			end
		end
	end
	if (id == maxSpells) then
		id = nil;
	end
	return id;
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

function ColdEmbrace_Help(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

	if strlower(cmd) == "test" then
		itemLink = "CE_Roll: |cffff8000|Hitem:19019:0:0:0:0:0:0:0:0|h[Thunderfury, Blessed Blade of the Windseeker]|h|r"
		ItemFrameCE.item.itemLink = nil
		CE_DrawFrames()
		return
	elseif strlower(cmd) == "skin" then
		if args == "0" then
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00CE Skin:|r Now set to |cffffcc000|r (Disable backdrop visuals)")
			ColdEmbraceVariables.Skin = 0
			UpdateSkin()
		elseif args == "1" then
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00CE Skin:|r Now set to |cffffcc001|r (Autodetect pfUI theme)")
			ColdEmbraceVariables.Skin = 1
			UpdateSkin()
		elseif args == "2" then
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00CE Skin:|r Now set to |cffffcc002|r (Enforce blizzard theme)")
			ColdEmbraceVariables.Skin = 2
			UpdateSkin()
		else
			local c = ColdEmbraceVariables.Skin
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00CE Skin:|r Please choose a skin (e.g: /ce skin 2)")
			DEFAULT_CHAT_FRAME:AddMessage(" 0: Disable backdrop visuals"..(c == 0 and "|cffffcc00*|r" or ""))
			DEFAULT_CHAT_FRAME:AddMessage(" 1: Autodetect pfUI theme"..(c == 1 and "|cffffcc00*|r" or ""))
			DEFAULT_CHAT_FRAME:AddMessage(" 2: Enforce blizzard theme"..(c == 2 and "|cffffcc00*|r" or ""))
		end

		return
	end

	DEFAULT_CHAT_FRAME:AddMessage("Thank you for downloading the Cold Embrace guild addon.",1,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("Version: "..addon_version,1,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("List of usable commands:",0,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("/rl or /reload - Reload UI.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/autores - Resurrect dead raid members.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/reset or /resetinstance or /resetinstances - Reset Instances.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/rms or /rollms - Main Spec roll.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/ros or /rollos - Off Spec roll.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/rfs or /rollfs - Free Spec roll. (you won't pay the items price even if you win)",1,1,1);
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
			ItemFrameCE.item.itemLink = nil

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
		UpdateSkin()
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

--[[
/cast Shackle Undead
/run ColdEmbrace_ShackleAnnounce("Diamond")
1) if a mob is not marked, it will mark it
2) announce the shackle target
]]

local shackle_names = {"Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull"}

function ColdEmbrace_ShackleAnnounce(which_mark)
    local shackle_idx = GetRaidTargetIndex("target")
    if not shackle_idx and which_mark then
        for ti, shackle_name in ipairs(shackle_names) do
            if which_mark == shackle_name then
                shackle_idx = ti
                break
            end
        end
        if not shackle_idx then
            DEFAULT_CHAT_FRAME:AddMessage([[unknown mark name, should be one of "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull"]])
        else
            SetRaidTarget("target", shackle_idx);
        end

    end

    shackle_idx = shackle_idx or GetRaidTargetIndex("target");
    local msg = 'shackle'
    if shackle_idx then
        msg = msg .. ' -- ' .. shackle_names[shackle_idx]
    end
    msg = msg .. ' -- ' .. UnitName("target")
    SendChatMessage(msg,"SAY",nil);
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

local _,playerClass = UnitClass("player");

if playerClass == "PRIEST" then
    resSpell = "Resurrection";
elseif playerClass == "SHAMAN" then
    resSpell = "Ancestral Spirit";
elseif playerClass == "PALADIN" then
    resSpell = "Redemption";
end

local classcolors = { DRUID="FF7D0A", HUNTER="ABD473", MAGE="69CCF0", PALADIN="F58CBA", PRIEST="FFFFFF", ROGUE="FFF569", SHAMAN="F58CBA", WARLOCK="9482C9", WARRIOR="C79C6E" }

function ColdEmbrace_AutomaticResurrection()
	if playerClass == "PRIEST" or playerClass == "SHAMAN" or playerClass == "PALADIN" then

		if HealComm == nil then
			HealComm = AceLibrary("HealComm-1.0")
		end

		local classOrder = {"PRIEST", "SHAMAN", "PALADIN", "DRUID", "WARLOCK", "MAGE", "HUNTER", "WARRIOR", "ROGUE"};
		CastSpell(CE_FindSpell(resSpell), BOOKTYPE_SPELL);

		for c=1,table.getn(classOrder) do
			for i = 1,40 do
			Target = 0;
				if GetNumRaidMembers() > 0 then
					Target = 'raid'..i
				elseif GetNumRaidMembers() == 0 then
					if GetNumPartyMembers() > 0 then
						Target = 'party'..i
					elseif GetNumPartyMembers() == 0 then
						Target = 'Player'
					end
				end

				local _, raidClass = UnitClass(Target);
				if UnitIsDead(Target)
				and CheckInteractDistance(Target,4)
				and not UnitIsGhost(Target)
				and not HealComm:UnitisResurrecting(UnitName(Target))
				and raidClass == classOrder[c]
				then
					SpellTargetUnit(Target);
					--CastSpell(CE_FindSpell(resSpell), BOOKTYPE_SPELL);
				end
			end
		end
	elseif playerClass == "DRUID" or playerClass == "WARLOCK" or playerClass == "MAGE" or playerClass == "HUNTER" or playerClass == "WARRIOR" or playerClass == "ROGUE" then
		DEFAULT_CHAT_FRAME:AddMessage("nice try... dumbass",1,1,0);
	end
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

local strength = {
	[0] = { 0, 100 }, -- ms
	[1] = { 0,  70 }, -- os
	[2] = { 1,  69 }, -- greed
	[3] = { 1,  50 }, -- xmog
}

local function GetRollStrength()
	local guild = "Cold Embrace"
	local guildName, guildRankName, guildRankIndex = GetGuildInfo("Player")
	local playerName = UnitName("Player");

	-- update roll strength
	if guildName == guild then
		for i = 1,750 do
			local name, _, _, _, _, _, _, officernote = GetGuildRosterInfo(i)
			if name == playerName then
				if officernote ~= "" then
					local points = tonumber(officernote)
					if not points then return strength end

					strength[0] = { tonumber(points), tonumber(points*0.7+100) } -- ms
					strength[1] = { math.max(points-100, 0), math.min(points*0.7+70,120) } -- os
				end
			end
		end
	end

	return strength
end

function ColdEmbrace_MainSpecRoll()
	local min, max = unpack(GetRollStrength()[0])
	RandomRoll(min, max)
end

function ColdEmbrace_OffSpecRoll()
	local min, max = unpack(GetRollStrength()[1])
	RandomRoll(min, max)

	if min > max then
		DEFAULT_CHAT_FRAME:AddMessage("Your points exceed limit, please contact an officer")
	end
end

function ColdEmbrace_GreedRoll()
	local min, max = unpack(GetRollStrength()[2])
	RandomRoll(min, max)
end

function ColdEmbrace_XMogRoll()
	local min, max = unpack(GetRollStrength()[3])
	RandomRoll(min, max)
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

	zoneES = "Emerald Sanctum";


	RollReturn = function()
		local txt = ""
		if isLeader then
			txt = "NEED"
		elseif not isLeader then
			txt = "PASS"
		end
		return txt
	end
	if inPartyInstance then
		local _, name, _, quality = GetLootRollItemInfo(id);

		if string.find(name ,"Dreamscale") and strfind(GetRealZoneText(), zoneES)
		or string.find(name ,"Small Dream Shard") and strfind(GetRealZoneText(), zoneES)
		or string.find(name ,"Bright Dream Shard") and strfind(GetRealZoneText(), zoneES)
		or string.find(name ,"Fading Dream Fragment") and strfind(GetRealZoneText(), zoneES)
		then

			if isLeader then RollOnLoot(id, 1); end
			if not isLeader then RollOnLoot(id, 0); end
			local _, _, _, hex = GetItemQualityColor(quality)
			DEFAULT_CHAT_FRAME:AddMessage("ColdEmbrace: Auto "..hex..RollReturn().." "..GetLootRollItemLink(id))
			return
		end
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
			or (string.find(name ,"Idol") and (not string.find(name ,"Primal Hakkari") or string.find(name ,"of the Moonfang")))

			or string.find(name ,"Ironweb Spider Silk")
			or string.find(name ,"Wartorn")
			or string.find(name ,"Word of Thawing")

			or string.find(name ,"Dreamscale")
			or string.find(name ,"Small Dream Shard")
			or string.find(name ,"Bright Dream Shard")
			or string.find(name ,"Fading Dream Fragment")
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
			or string.find(name ,"Giantstalker's Belt")
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
			or string.find(name ,"Girdle of Elemental Fury")
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
			-- Mana Potions
		elseif string.find(name ,"Mana Potion")
		then

			if not isLeader and
			(class == "Rogue" or class == "Warrior") then
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
do -- Create Main Window
	ItemFrameCE = CreateFrame("Button", "ItemFrameCE", UIParent)
	CreateBackdrop(ItemFrameCE)

	ItemFrameCE:ClearAllPoints()
	ItemFrameCE:SetWidth(272)
	ItemFrameCE:SetHeight(96)
	ItemFrameCE:SetPoint("CENTER", 240, 85)
	ItemFrameCE:SetClampedToScreen(true)

	ItemFrameCE:SetMovable(true)
	ItemFrameCE:EnableMouse(true)
	ItemFrameCE:Hide()

	ItemFrameCE:SetScript("OnMouseDown", function()
		if arg1 ~= 'LeftButton' then return end
		this:StartMoving()
	end)

	ItemFrameCE:SetScript("OnMouseUp", function()
		this:StopMovingOrSizing()
		this:SetUserPlaced(true)
	end)

	ItemFrameCE.item = CreateFrame("Frame", nil, ItemFrameCE)
	CreateBackdrop(ItemFrameCE.item)

	ItemFrameCE.item:SetPoint("TOPLEFT", ItemFrameCE, "TOPLEFT", 4, -4)
	ItemFrameCE.item:SetPoint("TOPRIGHT", ItemFrameCE, "TOPRIGHT", -4, -4)
	ItemFrameCE.item:SetHeight(36)
	ItemFrameCE.item:EnableMouse(true)
	ItemFrameCE.item:SetScript("OnUpdate", function()
		-- only set current item once
		if not itemLink or itemLink == this.itemLink then return end

		local name = itemLink
		local r, g, b, rarity = 1, 1, 1, 1
		local _, _, itemId = string.find(itemLink, "item:(%d+):%d+:%d+:%d+")
		if itemId then name, _, rarity = GetItemInfo(itemId) end
		if rarity then r, g, b = GetItemQualityColor(rarity) end

		-- update text and borders
		this.text:SetText(name)
		this.text:SetTextColor(r,g,b,1)
		this:SetBackdropBorderColor(r,g,b,1)

		-- save for next run
		this.itemLink = itemLink
	end)

	ItemFrameCE.item:SetScript("OnEnter", function()
		if not this.itemLink then return end

		local _, _, itemId = string.find(itemLink, "item:(%d+):%d+:%d+:%d+")
		if not itemId then return end

		GameTooltip:SetOwner(ItemFrameCE.item, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink('item:' .. itemId .. ":0:0:0")
		GameTooltip:Show()
	end)

	ItemFrameCE.item:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	ItemFrameCE.item.text = ItemFrameCE.item:CreateFontString("Status", "LOW", "GameFontNormal")
	ItemFrameCE.item.text:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
	ItemFrameCE.item.text:SetAllPoints()
end

do -- Create MainSpec Button
	NeedFrameCE = CreateFrame("Button", nil, ItemFrameCE)
	NeedFrameCE:SetWidth(36)
	NeedFrameCE:SetHeight(36)

	NeedFrameCE:SetScript("OnEnter", function()
		local min, max = unpack(GetRollStrength()[0])
		min, max = math.floor(min), math.floor(max)

		GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", -36, -4)
		GameTooltip:SetText("MS Roll", nil, nil, nil, nil, 1)
		GameTooltip:AddLine("Mainspec rolls are for Gearpieces which are an |cffffffffupgrade|r to the |cffffffffprimary raid specialization|r of your |cffffffffprimary character|r, Resistence Gear and Recepies for your primary Character.", .7, .7, .7, true)
		GameTooltip:AddDoubleLine("Your Rollstrength:", min .. " - " .. max)
		GameTooltip:Show()
	end)

	NeedFrameCE:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	NeedFrameCE:SetScript("OnClick", function()
		ColdEmbrace_MainSpecRoll()
		this:GetParent():Hide()
	end)

	CreateButton(NeedFrameCE)

	NeedFrameCE.texture = NeedFrameCE:CreateTexture(nil,"NORMAL")
	NeedFrameCE.texture:SetTexture("Interface\\Addons\\ColdEmbrace\\ms_icon.tga")
	NeedFrameCE.texture:SetPoint("CENTER", 0, 0)
	NeedFrameCE.texture:SetWidth(24)
	NeedFrameCE.texture:SetHeight(24)

	NeedFrameCE:SetPoint("CENTER", ItemFrameCE, "CENTER", -96,-20)
end

do -- Create OffSpec Button
	OffspecFrameCE = CreateFrame("Button", nil, ItemFrameCE)
	OffspecFrameCE:SetWidth(36)
	OffspecFrameCE:SetHeight(36)

	OffspecFrameCE:SetScript("OnEnter", function()
		local min, max = unpack(GetRollStrength()[1])
		min, max = math.floor(min), math.floor(max)

		GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", -36, -4)
		GameTooltip:SetText("OS Roll", nil, nil, nil, nil, 1)
		GameTooltip:AddLine("Offspec is limited to the specialisations you chose in the |cffffffffchoose-your-specs|r discord channel, PvP Gear for those Specs & Mainspec, Niche Sidegrades for your Mainspec as well as Resistence Gear and Recepies for your Alts", .7, .7, .7, true)
		GameTooltip:AddDoubleLine("Your Rollstrength:", min .. " - " .. max)
		GameTooltip:Show()
	end)

	OffspecFrameCE:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	OffspecFrameCE:SetScript("OnClick", function()
		ColdEmbrace_OffSpecRoll()
		this:GetParent():Hide()
	end)

	CreateButton(OffspecFrameCE)

	OffspecFrameCE.texture = OffspecFrameCE:CreateTexture(nil, "NORMAL")
	OffspecFrameCE.texture:SetTexture("Interface\\Addons\\ColdEmbrace\\os_icon.tga")
	OffspecFrameCE.texture:SetPoint("CENTER", 0, 0)
	OffspecFrameCE.texture:SetWidth(24)
	OffspecFrameCE.texture:SetHeight(24)

	OffspecFrameCE:SetPoint("CENTER", ItemFrameCE, -48, -20)
end

do -- Create OffSpec Button
	GreedFrameCE = CreateFrame("Button", nil, ItemFrameCE)
	GreedFrameCE:SetWidth(36)
	GreedFrameCE:SetHeight(36)

	GreedFrameCE:SetScript("OnEnter", function()
		local min, max = unpack(GetRollStrength()[2])
		min, max = math.floor(min), math.floor(max)

		GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", -36, -4)
		GameTooltip:SetText("OS (Free) Roll", nil, nil, nil, nil, 1)
		GameTooltip:AddLine("'Freeroll' is for loot on characters & specialisations you |cffffffffdidn't specify in the choose-your-specs|r discord channel, and items you would like to scoop up before it gets disenchanted. |cffffffffThis is NOT meant as a greed roll for vendoring!|r", .7, .7, .7, true)
		GameTooltip:AddDoubleLine("Your Rollstrength:", min .. " - " .. max)
		GameTooltip:Show()
	end)

	GreedFrameCE:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	GreedFrameCE:SetScript("OnClick", function()
		ColdEmbrace_GreedRoll()
		this:GetParent():Hide()
	end)

	CreateButton(GreedFrameCE)

	GreedFrameCE.texture = GreedFrameCE:CreateTexture(nil, "NORMAL")
	GreedFrameCE.texture:SetTexture("Interface\\Addons\\ColdEmbrace\\osfree_icon.tga")
	GreedFrameCE.texture:SetPoint("CENTER", 0, 0)
	GreedFrameCE.texture:SetWidth(24)
	GreedFrameCE.texture:SetHeight(24)

	GreedFrameCE:SetPoint("CENTER", ItemFrameCE, 0, -20)
end

do -- Create XMog Button
	XmogFrameCE = CreateFrame("Button", nil, ItemFrameCE)
	XmogFrameCE:SetWidth(36)
	XmogFrameCE:SetHeight(36)

	XmogFrameCE:SetScript("OnEnter", function()
		local min, max = unpack(GetRollStrength()[3])
		min, max = math.floor(min), math.floor(max)

		GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", -36, -4)
		GameTooltip:SetText("XMog Roll", nil, nil, nil, nil, 1)
		GameTooltip:AddLine("Roll for Transmogification, you will be expected to |cffffffffhand over the Item|r to the Person the Lootmaster specifies |cffffffffafter equipping it|r.", .7, .7, .7, true)
		GameTooltip:AddDoubleLine("Your Rollstrength:", min .. " - " .. max)
		GameTooltip:Show()
	end)

	XmogFrameCE:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	XmogFrameCE:SetScript("OnClick", function()
		ColdEmbrace_XMogRoll()
		this:GetParent():Hide()
	end)

	CreateButton(XmogFrameCE)

	XmogFrameCE.texture = XmogFrameCE:CreateTexture(nil, "NORMAL")
	XmogFrameCE.texture:SetTexture("Interface\\Addons\\ColdEmbrace\\xmg_icon.tga")
	XmogFrameCE.texture:SetPoint("CENTER", 0, 0)
	XmogFrameCE.texture:SetWidth(24)
	XmogFrameCE.texture:SetHeight(24)

	XmogFrameCE:SetPoint("CENTER", ItemFrameCE, 48, -20)
end

do -- Create Pass Button
	PassFrameCE = CreateFrame("Button", nil, ItemFrameCE)
	PassFrameCE:SetWidth(36)
	PassFrameCE:SetHeight(36)

	PassFrameCE:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", -36, -4)
		GameTooltip:SetText("Pass Roll", nil, nil, nil, nil, 1)
		GameTooltip:AddLine("Close the Lootwindow", .7, .7, .7, true)
		GameTooltip:Show()
	end)

	PassFrameCE:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	PassFrameCE:SetScript("OnClick", function()
		this:GetParent():Hide()
	end)

	CreateButton(PassFrameCE)

	PassFrameCE.texture = PassFrameCE:CreateTexture(nil, "NORMAL")
	PassFrameCE.texture:SetTexture("Interface\\Addons\\ColdEmbrace\\ps_icon.tga")
	PassFrameCE.texture:SetPoint("CENTER", 0, 0)
	PassFrameCE.texture:SetWidth(24)
	PassFrameCE.texture:SetHeight(24)

	PassFrameCE:SetPoint("CENTER", ItemFrameCE, 96, -20)
end

function CE_DrawFrames()
	ItemFrameCE:Show()
end

function CE_ClearFrames()
	ItemFrameCE:Hide()
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
			extra_info = 'UNKNOWN'
		elseif version ~= addon_version then
			extra_info = 'OUTDATED'
		end
		if extra_info then
			DEFAULT_CHAT_FRAME:AddMessage(who .. ' ' .. version .. ' ' .. extra_info)
			num_issues = num_issues + 1
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage("addon versions summary: " .. num_issues .. ' issues')
end

function ColdEmbrace_VersionRaidAnnounce()
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

	--DEFAULT_CHAT_FRAME:AddMessage("addon versions:")
	SendChatMessage("Raid members with incorrect addon version; ", "RAID_WARNING");
	local num_issues = 0

	table.sort(raid_members)

	for i, who in ipairs(raid_members) do
		local version = tostring(addon_version_cache[who])

		local extra_info = nil
		if version == 'nil' then
			extra_info = 'DISABLED OR NOT INSTALLED'
		elseif version ~= addon_version then
			extra_info = 'OUTDATED'
		end
		if extra_info then
			--DEFAULT_CHAT_FRAME:AddMessage(who .. ' ' .. version .. ' ' .. extra_info)
			SendChatMessage(who .. ' ' .. version .. ' ' .. extra_info, "RAID");
			num_issues = num_issues + 1
		end
	end
	--DEFAULT_CHAT_FRAME:AddMessage("addon versions summary: " .. num_issues .. ' issues')
	SendChatMessage("addon versions summary: " .. num_issues .. ' issues', "RAID");
end
