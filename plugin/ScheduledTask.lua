Include("PluginBase");
SetDescription("�ƻ�����", false);

function Setup()	
	tbLastGuaJiPos = nil;
	nNextActivateTime = 0;
	tbBossMap = LoadTabFile("setting/boss/boss.tab", "d", "nMapId",{"nMapId",});
		
	return true;
end

function Activate(nNow)		
	if nNow < nNextActivateTime then
		return;
	end
	
	local szType = GetMapType(me.nTemplateMapId);	
	if szType == "fuben" or 
	   szType == "factionbattle" or 
	   szType == "battle" or 
	   szType == "domain" or 
	   tbBossMap[me.nTemplateMapId] 
	then
		nNextActivateTime = nNow + 10;
		return;
	end
	
	for _, szPluginName in pairs(tbAutoTasks) do
		local tbTask = GetPlugin(szPluginName); 
		if tbTask and tbTask.bEnable then
			return;
		end
	end
	
	for _, szPluginName in pairs(tbAutoTasks) do
		local tbTask = GetPlugin(szPluginName); 		
		if tbTask then
			local bSuceess, bRetCode = Lib:CallBack({tbTask.IsAvailable});
			if bSuceess and bRetCode then
				if tbTask.EnablePlugin() then
					SaveGuaJiPos();
					Log("�ƻ�����", "����", szPluginName);
					return;
				end
			end
		end
	end
	
	if tbLastGuaJiPos then
		local bRetCode = RunToPoint(tbLastGuaJiPos.nMapId, tbLastGuaJiPos.nX, tbLastGuaJiPos.nY, 4);
		if bRetCode then
			Log("�ƻ�����", "���ص�ǰ��", tbLastGuaJiPos.nMapId, tbLastGuaJiPos.nX, tbLastGuaJiPos.nY);
			tbLastGuaJiPos = nil;			
			AutoFight:Start();
			return;
		end		
	end	
end

function OnWndOpen(szUiGroup)
	if szUiGroup == "playerdeath" then
		SaveGuaJiPos();
		me.CallServerScript("ApplyRevive", 0);
		
		nNextActivateTime = GetTime() + 10; -- �ȴ������ӳ�
		
		if nSteps == 1 then
			nSteps = #tbSteps;
		end
 	end
end

function OnEnterMap(nTemplateMapId) 
	for _, szPluginName in pairs(tbAssistant) do
		local tbTask = GetPlugin(szPluginName); 
		if tbTask and tbTask.bEnable then
			tbTask.DisablePlugin();			
		end	
	end
	
	for _, szPluginName in pairs(tbAssistant) do
		local tbTask = GetPlugin(szPluginName); 
		if tbTask then
			local bSuceess, bRetCode = Lib:CallBack({tbTask.IsAvailable});
			if bSuceess and bRetCode then
				if tbTask.EnablePlugin() then
					Msg("�Զ�����" .. tbTask.szName);
				end
			end
		end
	end
		
	if tbLastGuaJiPos then
		local szType = GetMapType(tbLastGuaJiPos.nMapId);	
		if szType == "fuben" or 
		   szType == "factionbattle" or 
		   szType == "battle" or 
		   szType == "domain" or 
		   tbBossMap[tbLastGuaJiPos.nMapId] 
		then
			tbLastGuaJiPos = nil;
		end
	end
end

function SaveGuaJiPos()
	if not tbLastGuaJiPos then
		local _, nCurX, nCurY = me.GetWorldPos();
		tbLastGuaJiPos = { nMapId = me.nTemplateMapId , nX = nCurX, nY = nCurY};
		Log("�ƻ�����", "���浱ǰ��", tbLastGuaJiPos.nMapId, tbLastGuaJiPos.nX, tbLastGuaJiPos.nY);
	end
end

tbAutoTasks = 
{
	"AutoParter",
	"AutoYunBiao",	
	"AutoLiLian",	
};

tbAssistant = 
{
	"AssistantBattle",
	"AssistantMiJing",	
	"AssistantClearFriends",			
};