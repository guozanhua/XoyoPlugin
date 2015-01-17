Include("AutoLiLian");
SetDescription("组队历练助手", false);

function Setup()
	nSteps = 1;
	tbKillNpcPos = nil;
			
	local tbOption = Ui.tbLogic.tbSaveData:Load("TeamOption");
	tbOption.bAutoAgreeInvite = false;
	tbOption.bAutoAgreeApply = false;	
	Ui.tbLogic.tbSaveData:Save("TeamOption", tbOption);
	
	Msg("组队历练已开启");
		
	return true;
end

function Clear()
	local tbOption = Ui.tbLogic.tbSaveData:Load("TeamOption");
	tbOption.bAutoAgreeInvite = true;
	tbOption.bAutoAgreeApply = true;	
	Ui.tbLogic.tbSaveData:Save("TeamOption", tbOption);
end

function OnShowDialog(tbDlgInfo)	
	local tbSelectDlgText = {};	

	local tbTaskInfo, tbTaskSetting, bFinish = GetTask();
	if not tbTaskInfo then -- 尝试接任务		
		if me.nTeamId > 0 then
			if me.IsTeamLeader() == 1 then
				-- table.insert(tbSelectDlgText, "我愿意与队友一同前往");
				table.insert(tbSelectDlgText, "<color=yellow>组队\n(杀怪任务可以直接点击心荷传送到任务地点)<color>");
			else
				Msg("等待队长接任务");
			end
		else
			-- table.insert(tbSelectDlgText, "我要单人接取"); 
			table.insert(tbSelectDlgText, "<color=yellow>单人<color>");
		end			
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
