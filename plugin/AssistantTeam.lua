Include("PluginBase");
SetDescription("队伍助手", true);

local tbAssistantTeam = {};
tbAssistantTeam.tbTeammate =
{
     ["劍心"] = true,
	 ["黑芝麻糊"] = true,
	 ["桃根仙"] = true,
	 ["桃枝仙"] = true,
	 ["多给一分行不行"] = true,
	 ["往昔成追忆"] = true,
	 ["神谷薰"] = true,
	 ["灬暮色灬"] = true,
	 ["苏悠悠"] = true,
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
		Msg("自动同意[" .. szName .. "]入队");
	end
end
