Include("PluginBase");
SetDescription("�Զ�����", true);

function Activate(nNow)	
	local pNpc = SearchShouLing();
	if not pNpc then
		return;
	end
	
	Msg("��������" .. pNpc.szName);
	local nDistance = me.GetNpc().GetDistance(pNpc.nIndex);
	if nDistance > 16 then
		local _, nNpcX, nNpcY = pNpc.GetWorldPos();
		RunToPoint(me.nTemplateMapId, nNpcX, nNpcY);
		return;
	end	
	
	AutoAi.SetTargetIndex(pNpc.nIndex);
end

function OnShowDialog(tbDlgInfo)	
	local tbSelectText = {
		["����������"] = true,
	};
	
	for nIndex, tbOpt in pairs(tbDlgInfo.OptList) do
		if tbSelectText[tbOpt.Text] then
			SelectDlg(nIndex);	
			return true;
		end
	end
end

function SearchShouLing()
	local tbNpc = KNpc.GetAroundNpcList(me, 96);
	for _, pNpc in pairs(tbNpc) do		
		local szClassName, szScriptParam = KNpc.GetNpcClassName(pNpc.nTemplateId);
		if szClassName == "shoulingdlg" then -- ʰȡ
			return pNpc;
		end		
	end
end
