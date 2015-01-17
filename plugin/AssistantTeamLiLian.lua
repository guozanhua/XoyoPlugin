Include("AutoLiLian");
SetDescription("�����������", false);

function Setup()
	nSteps = 1;
	tbKillNpcPos = nil;
			
	local tbOption = Ui.tbLogic.tbSaveData:Load("TeamOption");
	tbOption.bAutoAgreeInvite = false;
	tbOption.bAutoAgreeApply = false;	
	Ui.tbLogic.tbSaveData:Save("TeamOption", tbOption);
	
	Msg("��������ѿ���");
		
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
	if not tbTaskInfo then -- ���Խ�����		
		if me.nTeamId > 0 then
			if me.IsTeamLeader() == 1 then
				-- table.insert(tbSelectDlgText, "��Ը�������һͬǰ��");
				table.insert(tbSelectDlgText, "<color=yellow>���\n(ɱ���������ֱ�ӵ���ĺɴ��͵�����ص�)<color>");
			else
				Msg("�ȴ��ӳ�������");
			end
		else
			-- table.insert(tbSelectDlgText, "��Ҫ���˽�ȡ"); 
			table.insert(tbSelectDlgText, "<color=yellow>����<color>");
		end			
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
