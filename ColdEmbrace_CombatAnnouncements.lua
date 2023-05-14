--ORIGINAL CODE COPIED FROM:
--VF_WarriorAddon
--Written by Dilatazu @ EmeraldDream @ www.EmeraldDream.com / www.wow-one.com

function ColdEmbrace_CA_OnLoad()
	--this:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF");
	this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE");
	this:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS");
	this:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE");
	this:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS");
	this:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS");
	this:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE");
end

g_DebugMode = false;

function VF_WA_DebugPrint(theText)
	if(g_DebugMode == true) then
		DEFAULT_CHAT_FRAME:AddMessage(theText, 1, 1, 0);
	end
end

g_CurrTime = 0;

function VF_GetBuffCount(unitID, buffIcon)
	for u = 1, 16 do
		local buffIconPath, buffCount = UnitBuff(unitID, u);
		if(buffIconPath) then
			if(strfind(buffIconPath, buffIcon) ~= nil) then
				return buffCount;
			end
		end
	end
	return 0;
end

function ColdEmbrace_CheckForBuff(unit,name,app)
    local i=1;
    local state,apps;
    while true do
        state,apps = UnitBuff(unit,i);
        if not state then return false end
        if string.find(state,name) and ((app == apps) or (app == nil)) then return apps end
        i=i+1;
    end
end

function ColdEmbrace_CheckForDebuff(unit,name,app)
    local i=1;
    local state,apps;
    while true do
        state,apps = UnitDebuff(unit,i);
        if not state then return false end
        if string.find(state,name) and ((app == apps) or (app == nil)) then return apps end
        i=i+1;
    end
end

function ColdEmbrace_CA_OnEvent()
	target = UnitName("Target");
	if(event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS") then
		local _, _, gainWhat = string.find(arg1, "You gain (.*).");
		if(gainWhat ~= nil) then
			if(gainWhat == "Berserk") then
				if GetNumRaidMembers() > 0 then SendChatMessage("Berserk activated.", "RAID"); end
			elseif(gainWhat == "Shield Wall") then
				if GetNumRaidMembers() > 0 then SendChatMessage("Shield Wall activated.", "RAID"); end
			else
				VF_WA_DebugPrint("I gained "..gainWhat);
			end
		else
			VF_WA_DebugPrint("UNPARSED1: "..arg1);
		end
	elseif(event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE") then
		--[[local _, _, creature, spellEffect = string.find(arg1, "(.*) is afflicted by (.*).");
		if(creature ~= nil and spellEffect ~= nil) then
			if(spellEffect == "Taunt") then
				g_TauntCastTime = -1;
			elseif(spellEffect == "Challenging Shout") then
				g_ChallengingShoutCastTime = -1;
			elseif(spellEffect == "Mocking Blow") then
				VF_WA_DebugPrint("This message should never be shown!");
			else
				VF_WA_DebugPrint(spellEffect.." on "..creature.." was successful!");
			end
		else
			VF_WA_DebugPrint("UNPARSED2: "..arg1);
		end--]]
	elseif(event == "CHAT_MSG_SPELL_SELF_DAMAGE") then
		hasFFF = ColdEmbrace_CheckForDebuff('target',"Spell_Nature_FaerieFire");
		hasSA = ColdEmbrace_CheckForDebuff('target',"Ability_Warrior_Sunder", 5);
		local actionStatus = "Hit";
		local _, _, spellEffect, creature, dmg = string.find(arg1, "Your (.*) hits (.*) for (.*).");
		
		if(spellEffect == nil or creature == nil or dmg == nil) then
			_, _, spellEffect, creature, dmg = string.find(arg1, "Your (.*) crits (.*) for (.*).");
			actionStatus = "Crit";
		end
		
		if(spellEffect == nil or creature == nil or dmg == nil) then
			_, _, spellEffect, creature = string.find(arg1, "Your (.*) was resisted by (.*).");
			dmg = 0;
			actionStatus = "Resist";
		end

		if(spellEffect == nil or creature == nil or dmg == nil) then
			_, _, spellEffect, creature = string.find(arg1, "You perform (.*) on (.*).");
			dmg = 0;
			actionStatus = "Perform";
		end
		
		if(spellEffect == nil or creature == nil or dmg == nil) then
			_, _, spellEffect, creature = string.find(arg1, "Your (.*) missed (.*).");
			dmg = 0;
			actionStatus = "Miss";
		end
		
		if(spellEffect == nil or creature == nil or dmg == nil) then
			_, _, spellEffect, creature = string.find(arg1, "Your (.*) was dodged by (.*).");
			dmg = 0;
			actionStatus = "Dodge";
		end

		if(spellEffect == nil or creature == nil or dmg == nil) then
			_, _, spellEffect, creature = string.find(arg1, "Your (.*) is parried by (.*).");
			dmg = 0;
			actionStatus = "Parry";
		end
		
		if(spellEffect == nil or creature == nil or dmg == nil) then
			actionStatus = "Unknown";
		end

		if(actionStatus == "Resist" and (spellEffect == "Taunt" or spellEffect == "Growl" or spellEffect == "Hand of Reckoning")) then
			SendChatMessage("Resisted Taunt: " .. target, "SAY");
		elseif(actionStatus == "Perform" and (spellEffect == "Taunt" or spellEffect == "Growl" or spellEffect == "Hand of Reckoning")) then
			if UnitClassification("target") == "worldboss" then
				SendChatMessage("Taunted: " .. target, "SAY");
			end
		elseif((actionStatus == "Resist" or actionStatus == "Miss" or actionStatus == "Dodge" or actionStatus == "Parry") and spellEffect == "Mocking Blow") then
			SendChatMessage("Resisted Taunt: " .. target, "SAY");
		elseif(actionStatus == "Resist" and (spellEffect == "Faerie Fire (Feral)" or spellEffect == "Faerie Fire")) then
			if UnitClassification("target") == "worldboss" then
				if not hasFFF then SendChatMessage("Faerie Fire: Resisted", "SAY"); end
			end
		elseif((actionStatus == "Resist" or actionStatus == "Miss" or actionStatus == "Dodge" or actionStatus == "Parry") and spellEffect == "Sunder Armor") then
			if UnitClassification("target") == "worldboss" then
				if not hasSA then SendChatMessage("Sunder Armor: Failed", "SAY"); end
			end
		elseif(actionStatus == "Resist" and (spellEffect == "Challenging Roar" or spellEffect == "Challenging Shout")) then
			SendChatMessage("Taunt Resisted!", "SAY");
		elseif(actionStatus == "Unknown") then
			VF_WA_DebugPrint("UNPARSED3: "..arg1);
		end
	elseif(event == "VF_INSTANT_SUCCESSFULL_SPELLCAST") then
		VF_WA_DebugPrint("Instant Cast Spell: "..arg1);
	else
		if(arg1 == nil) then
			VF_WA_DebugPrint("UNPARSED4: "..event);
		else
			VF_WA_DebugPrint("UNPARSED4: "..event..arg1);
		end
	end
	--AURAADDEDOTHERHARMFUL == %s is afflicted by %s.
end

function ColdEmbrace_CA_OnUpdate()
	g_CurrTime = GetTime();
end
