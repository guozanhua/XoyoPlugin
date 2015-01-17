-- tbPluginBase 所有插件基类
-- local tbPlugin = MiniClient.PluginManger:CreatePlugin("Assistant");
-- tbPlugin:SetDescription("逍遥助手", true, "出售灰色物品、领福利、使用绑定箱子");

function Setup() -- 初始化工作
	return true;
end

function Clear() -- 清理工作
end

function Activate(nNow) -- 每秒一次, Enable 时会调用, 当出现进度条时不会调用,防止互相打断
end

function OnWndOpen(szUiGroup) -- 打开窗口时调用, Enable 时会调用
end

function OnShowDialog(tbDlgInfo) -- 打开对话框时调用, Enable 时会调用
	-- return true; -- 则不显示此对话框
end

function OnEnterMap(nTemplateMapId) -- 主角进入时调用, Enable 时会调用
end

function IsAvailable() -- 插件是否可用，主要用于一些需要自动触发的任务
	-- return true;
end

function SetDescription(szNewName, bNewEnable, szNewDescription)
	szName = szNewName;
	bEnable = bNewEnable;
	szDescription = szNewDescription;
end

function EnablePlugin()
	local bSuceess, bRetCode = Lib:CallBack({Setup});
	bEnable = bSuceess and bRetCode;
	return bEnable;
end

function DisablePlugin()
	Lib:CallBack({Clear});
	bEnable = false;
end

function GetName()
	if bEnable then
		return string.format("关闭 %s", szName or "");
	else
		return string.format("打开 %s", szName or "");
	end
end

function GetPlugin(szPluginName) -- 破坏插件设计
	return MiniClient.Plugin[szPluginName];
end

function TryUseItem(dwItemTemplateID)
	local tbItems = me.FindItemInBags(dwItemTemplateID);
	if #tbItems > 0 then
		if me.nLevel >= tbItems[1].pItem.nUseLevel then
			me.UseItem(tbItems[1].pItem);
		end		
	end
end

function SelectDlg(nIndex) 
	Ui("saypanel"):OnListSel("LstSelectArray", nIndex);
end

function GetMapNpcByTemplateID(nMapTemplateID, nNpcTemplateID)
	local tbConfigNpcList = Ui.tbLogic.tbXoyoMap:GetSceneMapNpcList(nMapTemplateID)
	if tbConfigNpcList then
		for i, tbCreate in ipairs(tbConfigNpcList) do
			if tbCreate.NpcTemplateID == nNpcTemplateID then
				local tbNpc = {};
				tbNpc.szName = tbCreate.NpcName;
				tbNpc.szTitle = tbCreate.NpcUiShowTitle;
				tbNpc.nX = tbCreate.NpcInMpsPosX / 32;
				tbNpc.nY = tbCreate.NpcInMpsPosY / 32;
				tbNpc.nMapTemplateID = nMapTemplateID;
				tbNpc.nTemplateId = tbCreate.NpcTemplateID;
				
				tbNpc.szMapName = tbNpc.szName;		
				if tbCreate.ShowUiInfoFlag == 2 then
					tbNpc.szMapName = tbNpc.szTitle;
				end
				return tbNpc;
			end
		end
	end
end

function GetNearestCityMapNpc(nNpcTemplateID)
	if not Task.tbTrackMapTable or not Task.tbTrackMapTable[me.nTemplateMapId] then
		return GetMapNpcByTemplateID(30, nNpcTemplateID); -- 扬州
	end
	
	return GetMapNpcByTemplateID(Task.tbTrackMapTable[me.nTemplateMapId], nNpcTemplateID);
end

function ParseTaskPos(tbTaskInfo, nStep)	
	if not tbTaskInfo.tbStepDesc then
    	return;	
    end
    
	local tbStepDesc = tbTaskInfo.tbStepDesc[nStep];
    local szDesc = tbStepDesc.strDesc;
	
	if tbTaskInfo.nActionNpcTemplateID and tbTaskInfo.nActionNpcTemplateID > 0 then
		local s1,s2,s3,s4 = string.match(szDesc, "(%s*%d+%s*),(%s*%d+%s*),(%s*%d+%s*)>(.*)");
		if s4 and nDoTaskActionState and nDoTaskActionState >= 1 then
			local nHadNum =  string.find(s4, ">")
			if nHadNum then
				local szNowDesc = string.sub(s4, 1, nHadNum)
				local nOrgMapID, nX, nY = string.match(szNowDesc, "(%s*%d+%s*),(%s*%d+%s*),(%s*%d+%s*)>");
				nOrgMapID, nX, nY = tonumber(nOrgMapID), math.floor(tonumber(nX) / 32), math.floor(tonumber(nY) / 32)
				return nOrgMapID, nX, nY;
			else
				if string.find(szDesc, "&sp") then
					local nOrgMapID, nX, nY = Task:GetTaskNpcCityMapPosByNpc(tbStepDesc.dwDlgNpcMapID, tbStepDesc.dwDlgNpcID)
					nX, nY = math.floor(nX), math.floor(nY);
					return nOrgMapID, nX, nY;
		        elseif string.find(szDesc, "&ep") then   
		        	local nOrgMapID, nX, nY = Task:GetTaskNpcCityMapPosByNpc(tbTaskInfo.dwEndNpcMapID, tbTaskInfo.dwEndNpc);
		        	nX, nY = math.floor(nX), math.floor(nY);   
					return nOrgMapID, nX, nY;
				end
			end
		end
		
		if s1 then
			local nOrgMapID, nX, nY = tonumber(s1), math.floor(tonumber(s2) / 32), math.floor(tonumber(s3) / 32);
			return nOrgMapID, nX, nY;
		end
	end
	
	if string.find(szDesc, "&sp") then
		local nOrgMapID, nX, nY = Task:GetTaskNpcCityMapPosByNpc(tbStepDesc.dwDlgNpcMapID, tbStepDesc.dwDlgNpcID);
		nX, nY = math.floor(nX), math.floor(nY);
		return nOrgMapID, nX, nY;	
	end
		
    if string.find(szDesc, "&ep") then   
    	local nOrgMapID, nX, nY = Task:GetTaskNpcCityMapPosByNpc(tbTaskInfo.dwEndNpcMapID, tbTaskInfo.dwEndNpc); 
    	nX, nY = math.floor(nX), math.floor(nY);
		return nOrgMapID, nX, nY;	
    end
	
	local nOrgMapID, nX, nY = Task:AnyleLink(szDesc);
	if nOrgMapID then
		nOrgMapID, nX, nY = tonumber(nOrgMapID), math.floor(nX / 32), math.floor(nY / 32);
		return nOrgMapID, nX, nY;  
	end 
end

function RunToPoint(nMapTemplateID, nX, nY, nArriveDistance)
	_tbRunToPoint = _tbRunToPoint or { nStopMoveTime = 0, };
	
	if not nArriveDistance or nArriveDistance < 1 then
		nArriveDistance = 1;
	end
	
	if me.GetNpc().nDoing == _NpcDoingDef.do_run then -- 防止停下
		_tbRunToPoint.nStopMoveTime = 0;
	else
		_tbRunToPoint.nStopMoveTime = _tbRunToPoint.nStopMoveTime + 1;
		
		if _tbRunToPoint.nStopMoveTime > 10 then
			_tbRunToPoint = { nStopMoveTime = 0, };		
			Log("RunToPoint", "恢复移动", nMapTemplateID, nX, nY);
		end
	end
	
	local _, nCurX, nCurY = me.GetWorldPos();
	if me.nTemplateMapId == nMapTemplateID then
		local nDistance = (nCurX - nX) * (nCurX - nX) + (nCurY - nY) * (nCurY - nY);
		if nDistance <= nArriveDistance * nArriveDistance then
			_tbRunToPoint = { nStopMoveTime = 0, };		
			return true;
		end

		if nDistance <= 25 and not _tbRunToPoint.bStartAutoMove then
			AutoAi.AiAutoMoveTo(nX * 32, nY * 32);
			_tbRunToPoint.bStartAutoMove = true;
			return;
		end
	end
				
	if _tbRunToPoint.nMapTemplateID == nMapTemplateID and _tbRunToPoint.nX == nX and _tbRunToPoint.nY == nY then
		return;
	end
	
	Ui.tbLogic.tbAutoPath:StartAutoPath({nMapId = nMapTemplateID , nX = nX, nY = nY}, 1);
	_tbRunToPoint.nMapTemplateID = nMapTemplateID;
	_tbRunToPoint.nX = nX;
	_tbRunToPoint.nY = nY;
	
	return;
end

function FightingToPoint(nMapTemplateID, nX, nY)	
	-- 因为无法获取到自动寻路的数据,不知道视野范围内的怪是不是要绕很大一圈或者根本不可达
	-- 还是大一点吧，不能自动的副本就算了
	local tbEnemy, nCount = KNpc.GetAroundNpcList(me, 96, 8); 
	if nCount == 0 then
		return RunToPoint(nMapTemplateID, nX, nY, 2);		
	end
	
	-- 无法实现辅助队长的功能,接口无法获取队长的目标
	
	local tbNearEnemy, nNearCount = KNpc.GetAroundNpcList(me, AutoFight.nFightRange, 8);
	if nNearCount == 0 then
		Msg("寻路到最近的怪");
		-- table.sort(tbPickNpc, NpcSortFun); 不能搞这个,会乱跑
		
		local _, nNpcX, nNpcY = tbEnemy[1].GetWorldPos();		
		return RunToPoint(nMapTemplateID, nNpcX, nNpcY, 2);
	end
	
	_tbRunToPoint = nil;
	AutoFight:Start();
end

function DialogNpc(nNpcTemplateID)
	local tbNpc = KNpc.GetAroundNpcList(me, 16);
	for _, pNpc in pairs(tbNpc) do
		if pNpc.nTemplateId == nNpcTemplateID then
			AutoAi.SetTargetIndex(pNpc.nIndex);
			return true;
		end
	end	
end

function Msg(szMsg)
	return MiniClient.PluginManger:Msg(szMsg);
end

local function IsSelfOrTeamMember(dwPlayerID)
	local tbTeamMember = me.GetTeamMemberList();
	if not tbTeamMember then
		return me.GetNpc().dwPlayerID == dwPlayerID;
	end
	
	for i, tbMember in ipairs(tbTeamMember) do
		if tbMember.dwPlayerID == dwPlayerID then
			return true;
		end
	end
end 

local function SearchKillNpcPos(nNpcTemplateId)	
	local _, nCurX, nCurY = me.GetWorldPos();
	local nAreaX = 16;
	local nAreaY = 16;
	local fnSortNpcFun = function (pNpc1, pNpc2)
		local nDistance1 = me.GetNpc().GetDistance(pNpc1.nIndex);
		local nDistance2 = me.GetNpc().GetDistance(pNpc2.nIndex);
		return nDistance1 < nDistance2;
	end
	
	local tbAreaNpcCount = {};	
	local tbNpc = KNpc.GetAroundNpcList(me, 96); 	
	table.sort(tbNpc, fnSortNpcFun);
	
	for _, pNpc in pairs(tbNpc) do
		if not IsSelfOrTeamMember(pNpc.dwPlayerID) then
			local _, nX, nY = pNpc.GetWorldPos();
			local nSubX = math.floor((nX - nCurX) / nAreaX);
			local nSubY = math.floor((nY - nCurY) / nAreaY);
			
			tbAreaNpcCount[nSubX] = tbAreaNpcCount[nSubX] or {};
			tbAreaNpcCount[nSubX][nSubY] = tbAreaNpcCount[nSubX][nSubY] or {nPlayerCount = 0, nNpcCount = 0;};
			
			local tbArea = tbAreaNpcCount[nSubX][nSubY];			
			if pNpc.dwPlayerID > 0 then
				tbArea.nPlayerCount = tbArea.nPlayerCount + 1;
			elseif pNpc.nTemplateId == nNpcTemplateId then
				tbArea.nNpcCount = tbArea.nNpcCount + 1;
				tbArea.pFirstNpc = tbArea.pFirstNpc or pNpc;
			end
		end
	end
		
	-- 寻找没人的怪最多的点
	local nMaxCount, nMaxX, nMaxY, pFirstNpc = 0, 0, 0, nil;	
	for nX, tbAreaRow in pairs(tbAreaNpcCount) do
		for nY, tbArea in pairs(tbAreaRow) do
			local nCount = tbArea.nNpcCount;			
			if nCount > nMaxCount and tbArea.nPlayerCount == 0 then
				nMaxCount = nCount;
				nMaxX = nX;
				nMaxY = nY;
				pFirstNpc = tbArea.pFirstNpc;
			end
		end
	end
	
	if pFirstNpc then
		local _, nX, nY = pFirstNpc.GetWorldPos();
		return me.nTemplateMapId, nX, nY;
	end
	
	-- 寻找怪比例最多的点
	for nX, tbAreaRow in pairs(tbAreaNpcCount) do
		for nY, tbArea in pairs(tbAreaRow) do
			local nCount = tbArea.nNpcCount / (1 + tbArea.nPlayerCount);			
			if nCount > nMaxCount then
				nMaxCount = nCount;
				nMaxX = nX;
				nMaxY = nY;
				pFirstNpc = tbArea.pFirstNpc;
			end
		end
	end
	
	if pFirstNpc then
		local _, nX, nY = pFirstNpc.GetWorldPos();
		return me.nTemplateMapId, nX, nY;
	end
end

function IsMapHouse(nTemplateMapId)
	if nTemplateMapId == 77 then -- 民宅
		return true;
	end
	
	if not tbCityHouse then
		tbCityHouse = LoadTabFile("setting/house/city_house.tab", "d", "MapID", {"MapID"});
	end
	
	assert(tbCityHouse);
	if tbCityHouse[nTemplateMapId] then
		return true;
	end
	
	return false;
end

function KillSpecifiedNpc(nMapTemplateID, nX, nY, nNpcTemplateId)
	if not _tbKillSpecifiedNpc or _tbKillSpecifiedNpc.nNpcTemplateId ~= nNpcTemplateId then
		tbKillSpecifiedNpc = nil;
		
		local nSearchMapTemplateID, nSearchX, nSearchY = SearchKillNpcPos(nNpcTemplateId);
		if nSearchMapTemplateID and nSearchX and nSearchY then
			_tbKillSpecifiedNpc = 
			{
				nNpcTemplateId = nNpcTemplateId,
				nMapTemplateID = nSearchMapTemplateID, 
				nX = nSearchX, 
				nY = nSearchY,
				bDisable = false,
			};
		end		
	end
	
	if not _tbKillSpecifiedNpc then
		Msg("走回起始坐标点");
		RunToPoint(nMapTemplateID, nX, nY);
		return;
	end

	if not _tbKillSpecifiedNpc.bDisable then
		if not RunToPoint(_tbKillSpecifiedNpc.nMapTemplateID, _tbKillSpecifiedNpc.nX, _tbKillSpecifiedNpc.nY) then
			Msg("走向怪物最多的点");
			return;			
		end		
		_tbKillSpecifiedNpc.bDisable = true;
	end
		
	local tbNpc = KNpc.GetAroundNpcList(me, AutoFight.nFightRange);
	for _, pNpc in pairs(tbNpc) do
		if pNpc.nTemplateId == nNpcTemplateId then
			AutoFight:Start();	
			return;
		end
	end	
	
	_tbKillSpecifiedNpc = nil;
end

function DetourAttach(tbTable, szName, fnFunction)		
	return MiniClient.PluginManger:DetourAttach(tbTable, szName, fnFunction);
end

function DetourDetach(tbTable, szName)	
	return MiniClient.PluginManger:DetourDetach(tbTable, szName);
end

function DetourCallOld(tbTable, szName, ...)
	return MiniClient.PluginManger:DetourCallOld(tbTable, szName, ...);
end

function GetShareTable(szTableName) -- 破坏插件设计
	local tbPluginMgr = MiniClient.PluginManger;
	tbPluginMgr.tbShare = tbPluginMgr.tbShare or {};
	tbPluginMgr.tbShare[szTableName] = tbPluginMgr.tbShare[szTableName] or {};
	return tbPluginMgr.tbShare[szTableName];
end

function ClearShareTable(szTableName)
	local tbPluginMgr = MiniClient.PluginManger;
	tbPluginMgr.tbShare = tbPluginMgr.tbShare or {};
	tbPluginMgr.tbShare[szTableName] = {};
end

-- function ProcessItem(pItem, Item.BAG_ROOM or Item.ROOM_MEDICIN or Item.ROOM_EQUIP) 
-- 		return bStopTraverse; -- true:stop, false or nil:continue;
-- end
function TraverseItem(fnProcessItem)
	for _, nRoomId in ipairs(Item.BAG_ROOM) do
		local nWidth, nHeight = me.GetRoomSize(nRoomId)
		for nY = 0, nHeight - 1 do
			for nX = 0, nWidth - 1 do
				local pItem = me.GetItem(nRoomId, nX, nY)
				if pItem then	
					if fnProcessItem(pItem, Item.BAG_ROOM) then
						return;
					end
				end
			end
		end	
	end
		
	for nPos = 0, Item.ROOM_MEDICINE_WIDTH do
		local pItem = me.GetItem(Item.ROOM_MEDICIN, nPos, 0);
		if pItem then
			if fnProcessItem(pItem, Item.ROOM_MEDICIN) then
				return;
			end
		end
	end			
	
	for nPos = Item.EQUIPPOS_HEAD, Item.EQUIPPOS_NUM do
		local pItem = me.GetItem(Item.ROOM_EQUIP, nPos, 0);
		if pItem then
			if fnProcessItem(pItem, Item.ROOM_EQUIP) then
				return;
			end
		end	
	end
end

function CreatEnumTable(tbEnumString, nStartIndex) 	
    local tbEnum = {};    
	nStartIndex	= nStartIndex or 0; 	
    for i, v in ipairs(tbEnumString) do 
        tbEnum[v] = nStartIndex + i - 1; 
    end 
    return tbEnum 
end 

_NpcDoingDef = CreatEnumTable(
{
	"do_none",		    
	"do_stand",		    
	"do_run",			    
    "do_sit",			    
    "do_skill",           
	"do_jump",		    
	"do_magic",		    
	"do_attack",		    
	"do_blurattack",	    
	"do_runattack",
	"do_manyattack",
	"do_jumpattack",
	"do_movepos",		    
	"do_runattackmany",   
    "do_death",		    
    "do_revive",
    "do_knockback",	    
    "do_drag",		    
    "do_rand_move",
    "do_auto_move",

	"do_num",
});