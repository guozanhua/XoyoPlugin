Include("PluginBase");
SetDescription("�Ի�����", false);
local tbLuckTreeAnswerQuestion = {["ȱˮ"] = "��ˮ", ["ȱӪ��"] = "ʩ��", ["����"] = "����",};
local tbPickNpcClass = {
	["open_server_activity_baoxiang"] = true, 
	["boxnpc"] = true, 
	["lingguo"] = true,
	["renshenguo"] = true,
	["menpaibaoxiang"] = true,
};

local tbMapTemplateID = 
{
	[217] = true, -- ���������
	[206] = true, -- ��������ս
	[207] = true,
	[208] = true,
	[209] = true,
	[210] = true,
	[211] = true,
	[212] = true,
	[213] = true,
	[214] = true,
	[215] = true,
};

function Setup() -- ��ʼ������
	nNextSearchDlgNpcTime = 0;

	XTongKin.ApplyKinData();
	return true;
end

function Activate(nNow)	
	local tbPickNpc = {};
	local tbNpc = KNpc.GetAroundNpcList(me, 32);
	for _, pNpc in pairs(tbNpc) do
		local szClassName, szScriptParam = KNpc.GetNpcClassName(pNpc.nTemplateId);
		if tbPickNpcClass[szClassName] then -- ʰȡ
			table.insert(tbPickNpc, pNpc);
		end
	end
	
	if #tbPickNpc > 0 then
		table.sort(tbPickNpc, NpcSortFun);
		
		local pNpc = tbPickNpc[1];		
		AutoAi.SetTargetIndex(pNpc.nIndex);
		Msg("�Զ��ɼ�  " .. pNpc.szName);
		return;
	end	
	
	if nNow > nNextSearchDlgNpcTime then		
		local szKinName = nil;
		local pKin = XTongKin.GetSelfKin();
		if pKin then
			szKinName = pKin.GetName();
		end
		local nTaskJiuCount = me.GetItemCountInBags(4104, 1); 
		local bTongJiLevel1, bTongJiLevel2, bTongJiLevel3 = GetTongJiCount();
				
		local tbNpc = KNpc.GetAroundNpcList(me, 48);
		for _, pNpc in pairs(tbNpc) do
			local szClassName, szScriptParam = KNpc.GetNpcClassName(pNpc.nTemplateId);
			if szClassName == "lucktree" then
				if szKinName and szKinName == pNpc.GetTitle() then
					AutoAi.SetTargetIndex(pNpc.nIndex);
					break;
				end
			elseif szClassName == "taskgouhuo" then
				if nTaskJiuCount > 0 then
					AutoAi.SetTargetIndex(pNpc.nIndex);
					break;
				end
			elseif szClassName == "policeman" then
				if bTongJiLevel1 or bTongJiLevel2 or bTongJiLevel3 then
					AutoAi.SetTargetIndex(pNpc.nIndex);
					break;
				end			
			end
		end			
	end
end

function NpcSortFun(pNpc1, pNpc2)
	local nDistance1 = me.GetNpc().GetDistance(pNpc1.nIndex);
	local nDistance2 = me.GetNpc().GetDistance(pNpc2.nIndex);
	
	return nDistance1 < nDistance2;
end

function OnShowLuckTreeDialog(tbDlgInfo)
	local nBegin, nEnd = string.find(tbDlgInfo.Text, "���������ڽ�������˹���,��ҿ����ɰ�");
	if nBegin and nEnd then
		for _k, _v in pairs(tbDlgInfo.OptList) do	
			if _v.Text == "�ɹ�ʵ" then
				SelectDlg(_k);
				return true;
			end		
		end			
	end
	
	local nBegin, nEnd = string.find(tbDlgInfo.Text, "���Ѿ�����������������ĵȴ������������졣�������������컹�У�");
	if nBegin and nEnd then
		return;
	end
	
	local nBegin, nEnd = string.find(tbDlgInfo.Text, "Ŀǰ����״����̫�ã������е㣺");
	if not nEnd then
		return;
	end
		
	local szQuestion = string.sub(tbDlgInfo.Text, nEnd + 1);
	if not szQuestion then
		return;
	end
	
	local szAnswer = tbLuckTreeAnswerQuestion[szQuestion];
	if not szAnswer then
		Msg("�Զ�������ֲ��֧������:" .. szQuestion);
		return;
	end	
	
	for _k, _v in pairs(tbDlgInfo.OptList) do	
		if _v.Text == szAnswer then
			SelectDlg(_k);
			return true;	
		end		
	end	
end

function GetTongJiCount()
	local nCount1 = me.GetItemCountInBags(3673, 1); 
	local nCount2 = me.GetItemCountInBags(3674, 1); 
	local nCount3 = me.GetItemCountInBags(0, 1); 
	
	return math.floor(nCount1 / 5) > 0, math.floor(nCount2 / 5) > 0, math.floor(nCount3 / 5) > 0;
end

function OnShowTongJiDialog(tbDlgInfo)		
	local tbText = {};
	tbText["ʹ�����ƶһ�����"] = true;
	
	local bTongJiLevel1, bTongJiLevel2, bTongJiLevel3 = GetTongJiCount();
	if bTongJiLevel1 then
		tbText["ʹ��5������ͨ�����ƶһ�һ�������������"] = true;
	elseif bTongJiLevel2 then
		tbText["ʹ��5���м�ͨ�����ƶһ�һ���м��������"] = true;
	elseif bTongJiLevel3 then
		tbText["ʹ��5���߼�ͨ�����ƶһ�һ���߼��������"] = true;	
	end
	
	for _k, _v in pairs(tbDlgInfo.OptList) do	
		if tbText[_v.Text] then
			SelectDlg(_k);
			return true, 0;
		end		
	end		
end

function OnShowTaskGouHuoDialog(tbDlgInfo)
	for _k, _v in pairs(tbDlgInfo.OptList) do
		if _v.Text == "�����ȸ�ʹ�죡" then
			SelectDlg(_k);
			return true;
		end		
	end		
end

function OnShowDialog(tbDlgInfo)	
	local bRetCode = false;
	
	if not bRetCode then
		bRetCode, nDelay = OnShowLuckTreeDialog(tbDlgInfo);
	end
	
	if not bRetCode then
		bRetCode, nDelay = OnShowTaskGouHuoDialog(tbDlgInfo);
	end
	
	if not bRetCode then
		bRetCode, nDelay = OnShowTongJiDialog(tbDlgInfo);
	end
	
	if bRetCode then
		nDelay = nDelay or 20;
		nNextSearchDlgNpcTime = GetTime() + nDelay;
		return true;
	end	
end

function IsAvailable() 
	return tbMapTemplateID[me.nTemplateMapId]; 
end