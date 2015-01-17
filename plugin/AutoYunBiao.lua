Include("PluginBase");
-- SetDescription("自动运镖", false);
local nAcceptTaskNpcTemplateID = 3680; 
local szSubTaskFileName = "setting/yunbiao/yunbiaotask.tab";
local szEndTaskFileName = "setting/yunbiao/yunbiaofinishtask.tab";
local szYunBiaoNpcFileName = "setting/npc/npc_yunbiao.tab";
local tbBiaoCheNpc = {};
local tbJieBiaoNpc = {};
local tbSubTaskId2Map = {};
local tbEndTaskId = {};
local tbDegreeCtrl = Import("common_script/degreectrl.lua");

function Setup()
	nSteps = 1;
	LoadYunBiaoTaskTab();
	Msg("自动运镖开始了");	
	
	return true;
end

function LoadYunBiaoTaskTab()
	local tbTaskFile = Lib:LoadTabFile(szSubTaskFileName) or {};
	local tbEndTaskFile = Lib:LoadTabFile(szEndTaskFileName) or {};
	local tbYunBiaoNpcFile = Lib:LoadTabFile(szYunBiaoNpcFileName) or {};
	
	if tbTaskFile then 
		for _, tbRowData in pairs(tbTaskFile) do 
			if tonumber(tbRowData["nTaskId"]) and tbRowData["nMapId"] then 
				tbSubTaskId2Map[tonumber(tbRowData["nTaskId"])] = tbRowData["nMapId"];
			end
		end 
	end
	
	if tbEndTaskFile then 
		for _, tbRowData in pairs(tbEndTaskFile) do 
			if tonumber(tbRowData["nTaskId"]) then 
				tbEndTaskId[tonumber(tbRowData["nTaskId"])] = true;
			end
		end 
	end 
	
	if tbYunBiaoNpcFile then 
		for _, tbRowData in pairs(tbYunBiaoNpcFile) do 
			if tonumber(tbRowData ["Id"]) and tbRowData["Title"] and tbRowData["Title"] == "劫镖" then 
				tbJieBiaoNpc[tonumber(tbRowData ["Id"])] = true;
			end 
			
			if tonumber(tbRowData ["Id"]) and string.find(tbRowData["Name"], "镖车") then 
				tbBiaoCheNpc[tonumber(tbRowData ["Id"])] = true;
			end
		end 
	end 
	
end 

function OnShowDialog(tbDlgInfo)	
	local tbSelectText = {
		["好的，交给我吧"] = true,
		["开始运镖"] = true,
		["前往下一个驿站"] = true,
		["前往终点"] = true,
		["运镖(白色)"] = true,
		["运镖(绿色)"] = true,
		["运镖(蓝色)"] = true,
		["运镖(紫色)"] = true,
	};
	
	local tbTaskInfo = GetTaskInfo();
		
	for nIndex, tbOpt in pairs(tbDlgInfo.OptList) do
		if tbSelectText[tbOpt.Text] then
			SelectDlg(nIndex);	
			return true;
		end
		
		if tbSelectText[tbOpt.ShowText] or (tbTaskInfo and tbOpt.Type == "Task" and tbOpt.ID == tbTaskInfo.nID)then	
			SelectDlg(nIndex);	
			return true;
		end		
	end
end

function OnWndOpen(szUiGroup)
	if szUiGroup == "gutaward" then
		local uiGutAward = Ui("gutaward");																
		uiGutAward:OnButtonClick("zBtnAccept");	
	end
end

function Activate()	
	while true do
		if nSteps > #tbSteps then
			nSteps = 1;
			break;
		end
					
		if tbSteps[nSteps]() then
			Log("Auto task doing step" .. nSteps .. " success!");
			nSteps = nSteps + 1;
		else
			break
		end
	end
end

function IsAvailable() 
	if me.nLevel < 30 then
		return;
	end

	if tbDegreeCtrl.GetDegree(me, "YunBiao") > 0 then 
		return true
	end
	
	local tbTaskInfo = GetTaskInfo();
	if tbTaskInfo then
		return true;
	end		
end

-- return tbTaskInfo, tbTaskSetting, bFinish;
function GetTaskInfo()
	local tbTaskInfo = XTaskClient.GetPlayerTaskID();
	
	for _, nTaskId in pairs(tbTaskInfo) do
		local pTaskInfo = XTaskClient.GetTaskInfoByID(nTaskId);
		local szTaskKind = pTaskInfo.strChapterDesc;
		if szTaskKind == "运镖任务" then 
			return pTaskInfo;
		end 
	end
end

function FindTaskMap(tbTaskInfo)	
	for nTaskId, nMapId in pairs(tbSubTaskId2Map) do
		if nTaskId and nMapId and nTaskId == tbTaskInfo.nID then 
			return tonumber(nMapId);
		end 
	end 
end 

function GetTaskNpcInfo(tbTaskInfo)
	local tbNpc = KNpc.GetAroundNpcList(me, 16);
	for _, pNpc in pairs(tbNpc) do
		if pNpc.nTemplateId == tbTaskInfo.nActionNpcTemplateID or pNpc.nTemplateId == tbTaskInfo.dwEndNpc then	
			return pNpc;
		end
	end	
end 

function Step_AcceptTask()
	if not IsAvailable() then 
		Msg("自动运镖结束了,插件已经关闭");
		DisablePlugin();	
		return;
	end
	
	local tbTaskInfo = GetTaskInfo();
	if tbTaskInfo then
		return true;
	end
				
	local nMapTemplateID, nX, nY = Task:GetTaskNpcCityMapPosByNpc(30, nAcceptTaskNpcTemplateID); 
	assert(nMapTemplateID);		
	
	local bRetCode = RunToPoint(nMapTemplateID, nX, nY, 2);
	if not bRetCode then
		return;
	end
	
	bRetCode = DialogNpc(nAcceptTaskNpcTemplateID);
	if not bRetCode then
		assert(false);
	end
end

function Step_SearchTask()
	local tbTaskInfo = GetTaskInfo();
	if not tbTaskInfo then
		return true;
	end
	
	local tbNpc = KNpc.GetAroundNpcList(me, 96);	
	for _, pNpc in pairs(tbNpc) do
		if tbBiaoCheNpc[pNpc.nTemplateId] and string.find(pNpc.GetTitle(), me.szName) then
			return true;
		end		
	end			
						
	local nMapTemplateID, nX, nY = ParseTaskPos(tbTaskInfo, 1);
	if nMapTemplateID then		
		if not RunToPoint(nMapTemplateID, nX, nY, 2) then
			return;
		end	
	end
	
	local nTaskNpcMapId = FindTaskMap(tbTaskInfo);	
	if nTaskNpcMapId then 
		local tbNpc = GetMapNpcByTemplateID(nTaskNpcMapId, tbTaskInfo.nActionNpcTemplateID);		
		if tbNpc and RunToPoint(tbNpc.nMapTemplateID, tbNpc.nX, tbNpc.nY, 5) then 
			local pNpc = GetTaskNpcInfo(tbTaskInfo);
			if pNpc then 
				AutoAi.SetTargetIndex(pNpc.nIndex);
			end 
		end 
	end 

	if tbEndTaskId[tbTaskInfo.nID] then 
		local pNpc = GetTaskNpcInfo(tbTaskInfo);
		if pNpc then 
			AutoAi.SetTargetIndex(pNpc.nIndex);
		end 
	end	
end

function Step_DoingTask()
	local tbNpc = KNpc.GetAroundNpcList(me, 96);	
	for _, pNpc in pairs(tbNpc) do
		if tbBiaoCheNpc[pNpc.nTemplateId] and string.find(pNpc.GetTitle(), me.szName) then
			local nDistance1 = me.GetNpc().GetDistance(pNpc.nIndex);
			if nDistance1 > 16 * 16 then
				local _, nNpcX, nNpcY = pNpc.GetWorldPos();
				RunToPoint(me.nTemplateMapId, nNpcX, nNpcY);		
			else
				local tbEnemyNpc = KNpc.GetAroundNpcList(me, AutoFight.nFightRange, 8);	 -- 参数3是个8是个可攻击的怪
				for _, pEnemyNpc in pairs(tbEnemyNpc) do
					if tbJieBiaoNpc[pEnemyNpc.nTemplateId] then
						AutoAi.SetTargetIndex(pEnemyNpc.nIndex);
						AutoFight:Start();
					end 
				end
			end
			return;	
		end
	end		
	return true;	
end

tbSteps = 
{
	Step_AcceptTask,
	Step_SearchTask,
	Step_DoingTask,
}
