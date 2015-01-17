Include("PluginBase");
SetDescription("自动任务", false);

local tbMenpaiList =
{
    "天王",
    "少林",
    "逍遥",
    "华山",	
    "昆仑",
    "武当",
    "桃花岛",
    "峨嵋",
    "丐帮",
    "唐门",
};

function Setup()	
	nSteps = 1;
	
	_tbTaskSetting = Lib:LoadTabFile("setting/task/task.tab", {ID = true, });
	_tbTaskQuestionsSetting = Lib:LoadTabFile("setting/task/task_question.tab");
	
	return true;
end

function Activate()		
	while true do			
		if nSteps > #tbSteps then
			nSteps = 1;
		end

		local nClickTimes = 0;
		while UiManager:WindowVisible("gutmodel") == 1 do
			Ui("gutmodel"):OnButtonClick();

			local uiGutDialog = Ui("gutdialog");
			uiGutDialog.nEnd = 0;
			uiGutDialog:EndGut();

			nClickTimes = nClickTimes + 1;
			if nClickTimes > 10 then
				break;
			end
		end
	
		if tbSteps[nSteps](self) then
			Log("Auto task doing step" .. nSteps .. " success!");
			nSteps = nSteps + 1;
		else
			break
		end
	end
end

function OnWndOpen(szUiGroup)
	if szUiGroup == "gutaward" then
		local uiGutAward = Ui("gutaward");
		
		if uiGutAward.bTaskAccept == 0 then
			uiGutAward:OnAcceptOptAward(1); -- 随便选个奖励
		end
		
		uiGutAward:OnButtonClick("zBtnAccept");			
	end
end

function OnShowDialog(tbDlgInfo)
	local tbTaskInfo = GetTask();
	if not tbTaskInfo then
		return;
	end
	
	for nIndex, tbOpt in ipairs(tbDlgInfo.OptList) do	
		if tbOpt.Type == "Task" and tbOpt.ID == Task.nJoinFactionTaskID then	
			if tbOpt.Text == tbMenpaiList[me.nNewbieFaction] then
				SelectDlg(nIndex);
				return true;
			end					
		elseif tbOpt.Type == "Task" and tbOpt.ID == 2731 and tbOpt.State ==  "EnterTaskMap" then --落叶谷
			SelectDlg(nIndex);
			return true;
		elseif tbOpt.Type == "Task" and nDoTaskActionState == 1 and tbOpt.ID == tbTaskInfo.nID and tbOpt.State ~=  "UnFinish" then
			SelectDlg(nIndex);
			nDoTaskActionState = 2;
			return true;
		elseif tbOpt.Type == "Task" and tbOpt.ID == tbTaskInfo.nID then
			SelectDlg(nIndex);
			nDoTaskActionState = 2;
			return true;
		elseif tbOpt.Type == "Script" and tbTaskInfo.nID == Task.nJoinFactionTaskID and (tbOpt.Text == "我想拜入门派" or tbOpt.Text == "我要加入" ) then
			SelectDlg(nIndex);
			return true;	
		end
	end
		
	-- 随便接任务
	for nIndex, tbOpt in ipairs(tbDlgInfo.OptList) do
		if tbOpt.Type == "Task" then	
			SelectDlg(nIndex);
			return true;
		end
	end
end

function AcceptTask()
	local tbTaskInfo = GetTask();
	if tbTaskInfo then
		return true;
	end

	
--	local tbTaskID = XTaskClient.GetCanAcceptTaskByGenre(Task.TASK_GENRE_MAIN);
--	tbMainTask = XTaskClient.GetTaskInfoByID(tbTaskID[1] or 0);	
	
	Log("任务断了");
end

function RunToTask()
	local tbTaskInfo = GetTask();
	local nMapTemplateID, nX, nY = GetTaskPos(tbTaskInfo);
	
	return RunToPoint(nMapTemplateID, nX, nY, dwNpcTemplateID);
end

-- 能处理则返回false 不能处理则返回true
function DoTask()
	local tbTaskInfo = GetTask();
	local fnProcessTask = tbProcessTask[tbTaskInfo.nStepType];
	
	if not fnProcessTask then
		Log("不支持的任务类型", tbTaskInfo.nStepType);
		return true;
	end
	
	local bSuceess, bRetCode = Lib:CallBack({fnProcessTask, tbTaskInfo});
	if not bSuceess then
		Lib:ShowTB(tbTaskInfo);
	end
	return bSuceess and bRetCode;
end

function GetNextStep(tbTaskInfo)
	if not tbTaskInfo.tbStepDesc then
		return 1;
	end 

	for nStep, tbDesc in ipairs(tbTaskInfo.tbStepDesc) do
		if tbDesc and tbDesc.strDesc and tbDesc.bDone ~= 1 then
			return nStep;
		end
	end
end

-- 这个要调整为
--	如果有完成的任务，优先交任务（选最近的）
--  如果有本地图可以接的任务，优先接任务
function GetTask()
	local tbAreadyAcceptTask = XTaskClient.GetPlayerTaskID();
	if tbAreadyAcceptTask and tbAreadyAcceptTask[1] == Task.nJoinFactionTaskID then
		local pAreadyAcceptTask = XTaskClient.GetTaskInfoByID(Task.nJoinFactionTaskID)
		return pAreadyAcceptTask;
	end

	local tbMainTask, tbBranchTask, tbAnotherTask = Ui.tbLogic.tbLogoutRetain:GetFirstPlayerTask();
	return tbMainTask or tbBranchTask or tbAnotherTask;
end

function DoingProtect(tbTaskInfo)
	local tbNpc = KNpc.GetAroundNpcList(me, 96);	
	for _, pNpc in pairs(tbNpc) do
		if string.find(pNpc.GetTitle(), me.szName) then
			local nDistance = me.GetNpc().GetDistance(pNpc.nIndex);			
			if nDistance > 16 * 16 then
				local _, nNpcX, nNpcY = pNpc.GetWorldPos();
				RunToPoint(me.nTemplateMapId, nNpcX, nNpcY);		
			end
			return;
		end
	end	
	
	return true;
end

function DoingToAreaTask(tbTaskInfo)
	local nMapTemplateID, nX, nY = GetTaskPos(tbTaskInfo);
	return not RunToPoint(nMapTemplateID, nX, nY, 1);
end

function DoingDialogTask(tbTaskInfo)
	local dwDialogTaskNPC = GetTaskNPC(tbTaskInfo);
	
	if not DialogNpc(dwDialogTaskNPC) then
		Log("没有找到NPC", dwDialogTaskNPC);
		return true;
	end
	return; 
end

function DoingKillNpcTask(tbTaskInfo)
	local nNowTaskStep = GetNextStep(tbTaskInfo);
	local dwNpcTemplateID = tbTaskInfo.tbKillNpc[nNowTaskStep].dwNpcTemplateID;
	local nMapTemplateID, nX, nY = GetTaskPos(tbTaskInfo);
	
	KillSpecifiedNpc(nMapTemplateID, nX, nY, dwNpcTemplateID)
end

function GetTaskPos(tbTaskInfo)
	local bTaskAccepted = XTaskClient.IsPlayerAcceptedTask(tbTaskInfo.nID);
	if bTaskAccepted == 1 then
		return Task:GetTaskActivePos(tbTaskInfo.nID);
	else
		return Task:GetTaskAcceptNpcPos(tbTaskInfo.nID);
	end
end

function GetTaskSetting(nTaskID)
	for _, tbSetting in pairs(_tbTaskSetting) do
		if tbSetting.ID == nTaskID then
			return tbSetting;
		end
	end
end

function DoingCollectItemTask(tbTaskInfo)
	local nNowTaskStep = GetNextStep(tbTaskInfo);
	local dwTaskItem = tbTaskInfo.tbCollectItem[nNowTaskStep].nID;
	
	assert(dwTaskItem);
		
	local tbNpc = KNpc.GetAroundNpcList(me, 32);
	for _, pNpc in pairs(tbNpc) do
		if pNpc.nTemplateId == tbTaskInfo.nActionNpcTemplateID then -- 任务领取
			AutoAi.SetTargetIndex(pNpc.nIndex);
			return;
		end
		
		local szClassName, szScriptParam = KNpc.GetNpcClassName(pNpc.nTemplateId);
		if szClassName == "taskdoodad" and szScriptParam ~= "" then -- 拾取
			local tbParam = Lib:SplitStr(tostring(szScriptParam));
			local nItemTemplateID = tonumber(tbParam[1]);
			if nItemTemplateID == dwTaskItem then
				AutoAi.SetTargetIndex(pNpc.nIndex);
				return;
			end
		end		
	end
	
	local tbTaskSetting = GetTaskSetting(tbTaskInfo.nID);
	local nDropNpcTemplateID = tbTaskSetting["DropNpcTemplateID" .. nNowTaskStep];

	if nDropNpcTemplateID and nDropNpcTemplateID ~= 0 then
		local nMapTemplateID, nX, nY = GetTaskPos(tbTaskInfo);	
		KillSpecifiedNpc(nMapTemplateID, nX, nY, nDropNpcTemplateID);
		return;
	end
	
	return true;
end

function DoingUseItemTask()
	local tbTaskSetting = GetTaskSetting(tbTaskInfo.nID); 
	local tbItems = me.FindItemInBags(tbTaskSetting.nUseItemID)
	if tbItems then
		me.UseItem(tbItems[1].nRoom, tbItems[1].nX,tbItemstbPos[1].nY);
		return;
	end
	
	return true;
end

function GetTaskNPC(tbTaskInfo)
	if tbTaskInfo.dwEndNpc > 0 then
		return tbTaskInfo.dwEndNpc;
	end
	
	local tbStepDesc = tbTaskInfo.tbStepDesc;
	if tbStepDesc then		
		local nNowTaskStep = GetNextStep(tbTaskInfo);
		local dwDlgNpcID = tbStepDesc[nNowTaskStep].dwDlgNpcID;
		if dwDlgNpcID and dwDlgNpcID > 0 then
			return dwDlgNpcID;
		end
	end
	
	if tbTaskInfo.dwAcceptNpc > 0 then
		return tbTaskInfo.dwAcceptNpc;
	end
end

tbSteps = 
{
	AcceptTask,
	RunToTask,
	DoTask,
}

tbProcessTask = 
{
	[Task.STEP_TYPE_DIALOG] = DoingDialogTask,
	[Task.STEP_TYPE_KILLNPC] = DoingKillNpcTask,
	[Task.STEP_TYPE_COLLECTITEM] = DoingCollectItemTask,
	[Task.STEP_TYPE_USEITEM] = DoingUseItemTask,
	[Task.STEP_TYPE_PROTECT] = DoingProtect,
	[Task.STEP_TYPE_TOAREA] = DoingToAreaTask,
	[Task.STEP_TYPE_QUESTION] = DoingDialogTask,
};