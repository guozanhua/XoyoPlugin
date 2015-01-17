Include("PluginBase");
SetDescription("��ͼ����", true);

function Setup()	
	tbDrawnMapPoint = {};
	tbMapDrawFlag = {};
	tbMapPointSetting = {};
	
	local tbPosFile = KIo.OpenTabFile("setting/littleboss.tab");
	for k = 2, tbPosFile.GetHeight() do
		local nMapId = tbPosFile.GetInt(k, "nMapId");
		if nMapId == 0 then
			break;
		end
		
		local tbMapPoint = {}		
		for i = 1, 50 do 
			local nX = tbPosFile.GetInt(k, "nX"..i);
			local nY = tbPosFile.GetInt(k, "nY"..i);				
			if nX == 0 or nY == 0 then
				break;
			end
			
			local tbPoint = {};
			tbPoint.nX, tbPoint.nY = Ui.tbLogic.tbXoyoMap:WorldPosToImgPos(nMapId, (nX - 100 ) / 32 , (nY - 120) / 32);
			tbPoint.szText = "����";
			table.insert(tbMapPoint, tbPoint); 				
		end		
		tbMapPointSetting[nMapId] = tbMapPoint;
	end
	KIo.CloseTabFile(tbPosFile);
	
	DrawMapPoint(me.nTemplateMapId);
	return true;
end

function Clear()
	for _, tbPoint in pairs(tbDrawnMapPoint) do -- ���ͼɾ��
		local nMapId, nPointId, nTxtId = unpack(tbPoint);
		Ui("xoyo_map"):DelMapAnimation(nMapId, nPointId); --ɾ��ָ����ͼ�ĵ�
		Ui("xoyo_map"):DelMapText(nMapId, nTxtId); --ɾ��ָ����ͼ���ı�
	end 
end

function OnEnterMap()
	DrawMapPoint(me.nTemplateMapId);
end

function DrawMapPoint(nMapId)		
	if tbMapDrawFlag[nMapId] then
		return;
	end
	
	local tbMapPoints = tbMapPointSetting[nMapId];
	if not tbMapPoints then
		return;
	end
	
	local tbXoyoMap = Ui("xoyo_map");
	for _, tbPoint in pairs(tbMapPoints) do
		local nPointId = tbXoyoMap:AddMapAnimation(nMapId, tbPoint.nX, tbPoint.nY, "image/ui/tubiao/qita/point.spr", 1, "����")
		local nTxtId = tbXoyoMap:AddMapText(nMapId, tbPoint.nX + 5, tbPoint.nY - 3, tbPoint.szText, 12, "orange");
		table.insert(tbDrawnMapPoint, {nMapId, nPointId, nTxtId}); 
	end	
	tbMapDrawFlag[nMapId] = true;	
end
