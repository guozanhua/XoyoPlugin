Include("PluginBase");
SetDescription("���Զ��̻�����", false);
local nAcceptTaskNpcTemplateID = 2430; -- �̻�����

function Setup()
	nSteps = 1;
			
	Msg("���Զ��̻������ѿ���");
		
	return true;
end

function OnShowDialog(tbDlgInfo)	
	local tbSelectDlgText = {};	

	local tbTaskInfo, tbTaskSetting, bFinish = GetTask();
	if not tbTaskInfo then -- ���Խ�����		
		table.insert(tbSelectDlgText, "�����ȡ�̻�����");
	end
	
	if bFinish then
		table.insert(tbSelectDlgText, "���Ѿ����������");
	end
	
	table.insert(tbSelectDlgText, "[�̻�����] ���и����Ÿ���");

	for _k, _v in pairs(tbDlgInfo.OptList) do
		for _, szSelectDlgText in pairs(tbSelectDlgText) do
			if _v.Text == szSelectDlgText then
				SelectDlg(_k);
				return true;
			end
		end			
	end
end

function Activate()	
	while true do
		if nSteps > #tbSteps then
			nSteps = 1;
			break;
		end
					
		if tbSteps[nSteps]() then
			Log("Auto ShangHui doing step" .. nSteps .. " success!");
			nSteps = nSteps + 1;
		else
			break
		end
	end
end

function IsAvailable() 
	if me.nLevel < Task.COMMERCE_TASK_ACCPET_LEVEL then
		return;
	end
	 
	local nLastCount = me.GetUserValue(Task.COMMERCE_TASK_USR_KEY, Task.COMMERCE_TASK_LAST_ACCEPT_COUNT);
    if nLastCount <= 0 then
        local nWeekTime = Lib:GetLocalWeek();
        local nLastAccpetTime = me.GetUserValue(Task.COMMERCE_TASK_USR_KEY, Task.COMMERCE_TASK_LAST_ACCEPT_WEEK);
        
        if nWeekTime == nLastAccpetTime then
			return;
        end
    end
	
	return true;
end

-- return tbTaskInfo, tbTaskSetting, bFinish;
function GetTask()
	local tbTaskInfo = Task:GetCommerceTaskInfo();
	if not tbTaskInfo then
		return;
	end
	
	local nCommerceTaskID = me.GetUserValue(Task.COMMERCE_TASK_USR_KEY, Task.COMMERCE_TASK_ACCEPT_ID);
	local tbTaskSetting = Task.tbCommerceTaskTable[nCommerceTaskID];
	
	return tbTaskInfo, tbTaskSetting, tbTaskInfo.tbStepDesc[1].bDone == 1;
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
	
	local nMapTemplateID, nX, nY = ParseTaskPos(tbTaskInfo, 1);	
	if not nMapTemplateID then
		Msg("���������޷����������Զ��̻᲻֧��...");
		return;
	end	
	
	return RunToPoint(nMapTemplateID, nX, nY, 2);	
end

function Step_DoingTask()
	local tbTaskInfo, tbTaskSetting, bFinish = GetTask();
	if not tbTaskInfo then
		tbKillNpcPos = nil;
		return true;
	end
	
	if bFinish then 		
		DialogNpc(tbTaskInfo.dwEndNpc);
		tbKillNpcPos = nil;
		return true;
	end
				
	if tbTaskSetting.Type == Task.COMMERCE_TASK_TYPE_SEND_MSG then
		DialogNpc(tbTaskSetting.OperatorNpcTemplateID);
	elseif tbTaskSetting.Type == Task.COMMERCE_TASK_TYPE_COLLECTION then
		Msg("�ռ����ߣ����Զ��̻᲻֧��...");
		return;
	else
		Msg("���Զ��̻᲻֧�ֵ�����:" .. tbTaskSetting.Type);
		return;		
	end	
	
	tbKillNpcPos = nil;
	return true;
end

tbSteps = 
{
	Step_AcceptTask,
	Step_SearchTask,
	Step_DoingTask,
}

