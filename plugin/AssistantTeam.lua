Include("PluginBase");
SetDescription("��������", true);

local tbAssistantTeam = {};
tbAssistantTeam.tbTeammate =
{
     ["����"] = true,
	 ["��֥���"] = true,
	 ["�Ҹ���"] = true,
	 ["��֦��"] = true,
	 ["���һ���в���"] = true,
	 ["������׷��"] = true,
	 ["���޹"] = true,
	 ["��ĺɫ��"] = true,
	 ["������"] = true,
}

function Setup()
	UiNotify:RegistNotify(UiNotify.emCOREEVENT_TEAM_APPLY, tbAssistantTeam.OnTeamApply, tbAssistantTeam);
	return true;
end

function Clear()		
	UiNotify:UnRegistNotify(UiNotify.emCOREEVENT_TEAM_APPLY, tbAssistantTeam);
end

function tbAssistantTeam:OnTeamApply(szName, nLevel, szFaction)	
	if self.tbTeammate[szName] then
		me.TeamReplyApply(szName, 1);
		Msg("�Զ�ͬ��[" .. szName .. "]���");
	end
end
