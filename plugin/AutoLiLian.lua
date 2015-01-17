Include("PluginBase");
-- SetDescription("自动历练", false);
local nAcceptTaskNpcTemplateID = 3551; -- 心荷
local tbAwardLevel = 
{
	[Task.YIJUN_EXP_AWARD] = 
	{
		[5] = 1, [10] = 2, [15] = 3.1, [20] = 3.8, [25] = 4, [30] = 5, 
	},
	[Task.YIJUN_BINDMONEY_AWARD] = 
	{
		-- 0.40		-- 0.429	-- 0.12     -- 0.03		-- 0.01		 -- 0.003	  -- 0.001	   -- 0.0001     -- 0.00001
		[1000] = 1, [2000] = 2, [3000] = 3, [5000] = 4, [10000] = 5, [20000] = 6, [50000] = 7, [100000] = 8, [500000] = 9, 
	},
	[Task.YIJUN_BINDCOIN_AWARD] = 
	{
		[10] = 1, [20] = 2, [30] = 3, [50] = 4, [100] = 5, [200] = 6, [500] = 7, [1000] = 8, [50000] = 9,
	},
	[Task.YIJUN_SHIMEN_AWARD] = 
	{
		[10] = 1.1, [20] = 2.1, [30] = 3.1, [50] = 4.1, [100] = 5.1, [200] = 6.1, [500] = 7.1, [1000] = 8.1, [50000] = 9.1,
	},	
	[Task.YIJUN_ITEM_AWARD] = 
	{
		[1106] = 0, [2908] = 0, [2912] = 0, [1947] = 0.5, [1948] = 2, [317] = 3, [318] = 5, [319] = 7, [320] = 8.2,
	},		
	[Task.YIJUN_ZHUAN_JI] = 
	{
		[50] = 0.9, [100] = 2.1, [150] = 3, [300] = 4, [500] = 5, [800] = 6, [1000] = 7, [2000] = 8, [5000] = 9,
	},		
}

function Setup()
	nSteps = 1;
			
	Msg("自动历练已开启");
		
	return true;
end

function OnShowDialog(tbDlgInfo)	
	local tbSelectDlgText = {};	

	local tbTaskInfo, tbTaskSetting, bFinish = GetTask();
	if not tbTaskInfo then -- 尝试接任务	
		-- table.insert(tbSelectDlgText, "我要单人接取"); 	
		table.insert(tbSelectDlgText, "<color=yellow>单人<color>");
	end
	
	if bFinish then
		table.insert(tbSelectDlgText, "我已经完成了任务");
	else
		table.insert(tbSelectDlgText, "<color=yellow>我准备好了,送我过去吧!<color>");
		table.insert(tbSelectDlgText, "是的。送我过去");
		table.insert(tbSelectDlgText, "有人让我捎个口信给你");
	end

	for _k, _v in pairs(tbDlgInfo.OptList) do
		for _, szSelectDlgText in pairs(tbSelectDlgText) do
			if _v.Text == szSelectDlgText then
				SelectDlg(_k);
				return true;
			end
		end			
	end
end

function OnWndOpen(szUiGroup)
	if szUiGroup == "gutaward" then
		local uiGutAward = Ui("gutaward");
		local tbTaskInfo, tbTaskSetting, bFinish = GetTask();

		if uiGutAward.nTaskId ~= tbTaskInfo.nID or not bFinish then
			return;
		end
		
		Log("本次历练奖励：");
		local tbAward = {};		
		for nID, tbKey in pairs(Task.tbYiJunAwardKey) do
			local nTypeID = me.GetUserValue(Task.YIJUN_GROUP, tbKey.nTypeKey);
			local nCount = me.GetUserValue(Task.YIJUN_GROUP, tbKey.nCountKey);
			nTypeID = KLib.SetBit(nTypeID, 32, 0);
							
			if nTypeID == Task.YIJUN_EXP_AWARD and nCount > 0 then			
				Log(nID, "经验" .. nCount);
			elseif nTypeID == Task.YIJUN_BINDMONEY_AWARD and nCount > 0 then		
				Log(nID, "绑银" .. nCount);
			elseif nTypeID == Task.YIJUN_BINDCOIN_AWARD and nCount > 0 then		
				Log(nID, "绑金" .. nCount);
			elseif nTypeID == Task.YIJUN_SHIMEN_AWARD and nCount > 0 then		
				Log(nID, "师门" .. nCount);
			elseif nTypeID == Task.YIJUN_ITEM_AWARD and nCount > 0 then				
			    local tbItem = KItem.GetItemBaseProp(nCount);		
				Log(nID, "道具" .. tbItem.szName);		
			elseif nTypeID == Task.YIJUN_ZHUAN_JI and nCount > 0 then		
				Log(nID, "传记点" .. nCount);
			else
				Msg("未知奖励，不能领！" .. nTypeID);
				return;
			end	
			
			tbAward[nID] = tbAwardLevel[nTypeID][nCount];		
		end
				
		local nSelectedAward = nil;
		local nSelectedValue = nil;

		for nID, nValue in pairs(tbAward) do
			if not nSelectedAward then
				nSelectedAward = nID;
				nSelectedValue = nValue;
			end
			
			if nValue >= nSelectedValue then -- 同级优先选后面的
				nSelectedAward = nID;
				nSelectedValue = nValue;
			end
		end		
						
		if nSelectedAward then
			uiGutAward.nSelectedAward = nSelectedAward;			
			Log("选择了:" .. nSelectedAward);
		else
			Log("自动选择失败");
		end
						
		uiGutAward:OnButtonClick("zBtnAccept");	
	end
		
	if szUiGroup == "playerdeath" then
		me.CallServerScript("ApplyRevive", 0);
		nSteps = 1;
	end
end

function Activate()	
	while true do
		if nSteps > #tbSteps then
			nSteps = 1;
			break;
		end
					
		if tbSteps[nSteps]() then
			Log("Auto lilian doing step" .. nSteps .. " success!");
			nSteps = nSteps + 1;
		else
			break
		end
	end
end

function IsAvailable() 
	if me.nLevel < 20 then        
        return;
    end
	
	local nCurrRing = me.GetUserValue(Task.YIJUN_GROUP, Task.YIJUN_CURR_RING);
	if nCurrRing <= Task.YIJUN_MAX_RING then
		return true;
	end
	
	local nLocalDay = Lib:GetLocalDay();
	if nLocalDay == me.GetUserValue(Task.YIJUN_GROUP, Task.YIJUN_RESTORE_DAY) then
		return;
	end
	
	local nSecond = Lib:GetLocalDayTime();
	if nSecond > 6 * 3600 then 
		return true;
	end
end

-- return tbTaskInfo, tbTaskSetting, bFinish;
function GetTask()
	local tbTaskInfo = Task:GetYiJunTaskInfo();
	if not tbTaskInfo then
		return;
	end
	
	local nTaskID = me.GetUserValue(Task.YIJUN_GROUP, Task.YIJUN_TASK_ID);
	assert(nTaskID > 0);
	
	local tbTaskSetting = Task.tbYiJunTaskTable[nTaskID];
	assert(tbTaskSetting);
	
	local bFinish = tbTaskInfo.tbStepDesc[1].bDone > 0;
	return tbTaskInfo, tbTaskSetting, bFinish;
end

function Step_AcceptTask()
	local tbTaskInfo, tbTaskSetting, bFinish = GetTask();
	if tbTaskInfo then
		return true;
	end
	
	local bAvailable = IsAvailable();
	if not bAvailable then 
		Msg("历练任务完成，插件关闭");
		DisablePlugin();	
		return;
	end
				
	local nMapTemplateID, nX, nY = Task:GetTaskNpcCityMapPosByNpc(30, nAcceptTaskNpcTemplateID); 
	assert(nMapTemplateID);		
	
	local bRetCode = RunToPoint(nMapTemplateID, nX, nY, 2);
	if not bRetCode then
		return;
	end
	
	bRetCode = DialogNpc(nAcceptTaskNpcTemplateID);
	if not bRetCode then
		return;
	end
end

function Step_SearchTask()
	local tbTaskInfo, tbTaskSetting, bFinish = GetTask();
	if not tbTaskInfo then
		return true;
	end
	
	if tbTaskSetting.Type == Task.YIJUN_TYPE_KILLNPC then
		if DialogNpc(nAcceptTaskNpcTemplateID) then
			return;
		end
	end
	
	local nMapTemplateID, nX, nY = ParseTaskPos(tbTaskInfo, 1);
	assert(nMapTemplateID);		
	return RunToPoint(nMapTemplateID, nX, nY, 2);	
end

function Step_DoingTask()
	local tbTaskInfo, tbTaskSetting, bFinish = GetTask();
	if not tbTaskInfo then
		return true;
	end
	
	if bFinish then 		
		DialogNpc(tbTaskInfo.dwEndNpc);
		return true;
	end
				
	if tbTaskSetting.Type == Task.YIJUN_TYPE_DIALOG then
		DialogNpc(tbTaskSetting.DialogNpcID);
	elseif tbTaskSetting.Type == Task.YIJUN_TYPE_KILLNPC then
		local nMapTemplateID, nX, nY = ParseTaskPos(tbTaskInfo, 1);
		KillSpecifiedNpc(nMapTemplateID, nX, nY, tbTaskSetting.KillNpcID);
		return;		
	elseif tbTaskSetting.Type == Task.YIJUN_TYPE_COLLECT then
		Msg("自动历练功能不支持收集道具");
	elseif tbTaskSetting.Type == Task.YIJUN_TYPE_TRAP then
		TryUseItem(tbTaskSetting.UseItemID);
	else
		Msg("自动历练功能不支持了");
	end	
	
	return true;
end

tbSteps = 
{
	Step_AcceptTask,
	Step_SearchTask,
	Step_DoingTask,
}

