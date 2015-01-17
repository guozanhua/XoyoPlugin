Include("PluginBase");
SetDescription("地图助手", true);

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
			tbPoint.szText = "首领";
			table.insert(tbMapPoint, tbPoint); 				
		end		
		tbMapPointSetting[nMapId] = tbMapPoint;
	end
	KIo.CloseTabFile(tbPosFile);
	
	DrawMapPoint(me.nTemplateMapId);
	return true;
end

function Clear()
	for _, tbPoint in pairs(tbDrawnMapPoint) do -- 大地图删除
		local nMapId, nPointId, nTxtId = unpack(tbPoint);
		Ui("xoyo_map"):DelMapAnimation(nMapId, nPointId); --删除指定地图的点
		Ui("xoyo_map"):DelMapText(nMapId, nTxtId); --删除指定地图的文本
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
		local nPointId = tbXoyoMap:AddMapAnimation(nMapId, tbPoint.nX, tbPoint.nY, "image/ui/tubiao/qita/point.spr", 1, "首领")
		local nTxtId = tbXoyoMap:AddMapText(nMapId, tbPoint.nX + 5, tbPoint.nY - 3, tbPoint.szText, 12, "orange");
		table.insert(tbDrawnMapPoint, {nMapId, nPointId, nTxtId}); 
	end	
	tbMapDrawFlag[nMapId] = true;	
end
