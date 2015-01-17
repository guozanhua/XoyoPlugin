Include("PluginBase");
-- SetDescription("�Զ�����", false);
local nAcceptTaskNpcTemplateID = 3551; -- �ĺ�
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
			
	Msg("�Զ������ѿ���");
		
	return true;
end

function OnShowDialog(tbDlgInfo)	
	local tbSelectDlgText = {};	

	local tbTaskInfo, tbTaskSetting, bFinish = GetTask();
	if not tbTaskInfo then -- ���Խ�����	
		-- table.insert(tbSelectDlgText, "��Ҫ���˽�ȡ"); 	
		table.insert(tbSelectDlgText, "<color=yellow>����<color>");
	end
	
	if bFinish then
		table.insert(tbSelectDlgText, "���Ѿ����������");
	else
		table.insert(tbSelectDlgText, "<color=yellow>��׼������,���ҹ�ȥ��!<color>");
		table.insert(tbSelectDlgText, "�ǵġ����ҹ�ȥ");
		table.insert(tbSelectDlgText, "���������Ӹ����Ÿ���");
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
		
		Log("��������������");
		local tbAward = {};		
		for nID, tbKey in pairs(Task.tbYiJunAwardKey) do
			local nTypeID = me.GetUserValue(Task.YIJUN_GROUP, tbKey.nTypeKey);
			local nCount = me.GetUserValue(Task.YIJUN_GROUP, tbKey.nCountKey);
			nTypeID = KLib.SetBit(nTypeID, 32, 0);
							
			if nTypeID == Task.YIJUN_EXP_AWARD and nCount > 0 then			
				Log(nID, "����" .. nCount);
			elseif nTypeID == Task.YIJUN_BINDMONEY_AWARD and nCount > 0 then		
				Log(nID, "����" .. nCount);
			elseif nTypeID == Task.YIJUN_BINDCOIN_AWARD and nCount > 0 then		
				Log(nID, "���" .. nCount);
			elseif nTypeID == Task.YIJUN_SHIMEN_AWARD and nCount > 0 then		
				Log(nID, "ʦ��" .. nCount);
			elseif nTypeID == Task.YIJUN_ITEM_AWARD and nCount > 0 then				
			    local tbItem = KItem.GetItemBaseProp(nCount);		
				Log(nID, "����" .. tbItem.szName);		
			elseif nTypeID == Task.YIJUN_ZHUAN_JI and nCount > 0 then		
				Log(nID, "���ǵ�" .. nCount);
			else
				Msg("δ֪�����������죡" .. nTypeID);
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
			
			if nValue >= nSelectedValue then -- ͬ������ѡ�����
				nSelectedAward = nID;
				nSelectedValue = nValue;
			end
		end		
						
		if nSelectedAward then
			uiGutAward.nSelectedAward = nSelectedAward;			
			Log("ѡ����:" .. nSelectedAward);
		else
			Log("�Զ�ѡ��ʧ��");
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
		Msg("����������ɣ�����ر�");
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
		Msg("�Զ��������ܲ�֧���ռ�����");
	elseif tbTaskSetting.Type == Task.YIJUN_TYPE_TRAP then
		TryUseItem(tbTaskSetting.UseItemID);
	else
		Msg("�Զ��������ܲ�֧����");
	end	
	
	return true;
end

tbSteps = 
{
	Step_AcceptTask,
	Step_SearchTask,
	Step_DoingTask,
}

