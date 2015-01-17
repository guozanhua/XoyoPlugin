Include("PluginBase");
SetDescription("��ң����", true);

local tbFaction = 
{
	-- [Player.FACTION_NONE] = "������",
    [Player.FACTION_TIANWANG] = "<color=Yellow>����<color>",
    [Player.FACTION_SHAOLIN] = "<color=Yellow>����<color>",
    [Player.FACTION_XIAOYAO] = "<color=Green_01>��ң<color>",
    [Player.FACTION_HUASHAN] = "<color=Green_01>��ɽ<color>",
    [Player.FACTION_KUNLUN] = "<color=Orange_02>����<color>",
    [Player.FACTION_WUDANG] = "<color=Orange_02>�䵱<color>",
    [Player.FACTION_TAOHUADAO] = "<color=Blue_02>�һ���<color>",
    [Player.FACTION_EMEI] = "<color=Blue_02>��ü<color>",
    [Player.FACTION_GAIBANG] = "<color=Orange_01>ؤ��<color>",
    [Player.FACTION_TANGMEN] = "<color=Orange_01>����<color>",    
};

local tbAutoUseItem = 
{
	["lottery"] = true, 	
	["randomitem"] = true,
	["liaotian"] = true,
	-- ["shimenling"] = true, �̻�������Ҫ
	["gathercard"] = true,
	["yunbiaoaward"] = true,
	["lingqidan"] = true,
	["LevelReward"] = true,
	["zhuanjiitem"] = true,
	
};

local tbAutoUseItemKindBlacklist = 
{
	["menpaijingyandan"] = true, 	
	["mj_jingyandan"] = true, 	
}

local MissionAwardGrade = 		-- ���ӽ�������,Grade=1����6��
{
	[1]	= 3;
	[2]	= 3;
	[3]	= 3;
	[4]	= 3;
	[5]	= 2;
	[6]	= 1;
};

function Setup()	
	DetourAttach(Ui("team_member_list"), "OnButtonDBClick", TeamMmemberListOnButtonDBClick);		
	DetourAttach(Ui("selectnpc"), "OnButtonRClick", SelectNpcOnButtonRClick);		
	-- DetourAttach(Ui("cspanel"), "OnOpen", GMWebOnOpen);		

	return true;
end

function Clear()		
	-- DetourDetach(Ui("cspanel"), "OnOpen");
	DetourDetach(Ui("selectnpc"), "OnButtonRClick");
	DetourDetach(Ui("team_member_list"), "OnButtonDBClick");
end

function Activate(nNow)
	TraverseItem(SellGrayItem); -- ���ۻ�ɫ��Ʒ
	FollowNpcActivate(nNow);
	WalfareActivate(nNow); -- ��֤����
	DailyTargetActivate(nNow); -- ÿ��Ŀ��
	AutoAwardActivate(nNow);
	ChangeEnemyPlayerTitle(nNow);			
	KeepBagRetainCell(4); -- ��֤�������ĸ�����
	
	AutoAi.PickAroundItem();  -- ʰȡ����	
end

function OnWndOpen(szUiGroup)
	if szUiGroup == "online_award" then -- �����콱
		if not Ui("online_award").nAwardIndex then
			return;
		end
		RemoteServer.OnlineAward_GetAward();	
	elseif szUiGroup == "missionsumup" then
		Ui("missionsumup"):OnButtonClick("btnConfirm");
	end
end

function OnEnterMap(nTemplateMapId)
	if IsMapHouse(nTemplateMapId) then
		RemoteServer.AcquireRewardPills(); -- ��ȡԪ����
	end
end

function OnShowDialog(tbDlgInfo)
	if tbDlgInfo.Text == "������ʹ����<color=yellow>10��<color>����������ʹ��<color=yellow>�������ø߶��<color>��" then
		for _k, _v in pairs(tbDlgInfo.OptList) do
			if _v.Text == "ʹ�ø��������100��������" then
				SelectDlg(_k);
				return true;
			end		
		end	
	end		
end

function FollowNpcActivate(nNow)
	if not tbFellowNpc then
		return;
	end
	
	local pNpc = KNpc.GetById(tbFellowNpc.dwFollowNpcID);
	if not pNpc then
		EndFollowNpc();
		return;
	end
	
	if nNow > tbFellowNpc.nNextFellowTime then
		local _, nCurX, nCurY = pNpc.GetWorldPos();
		tbFellowNpc.nTemplateMapId = me.nTemplateMapId;
		tbFellowNpc.nX = nCurX;
		tbFellowNpc.nY = nCurY;
		
		tbFellowNpc.nNextFellowTime = nNow + 5;
	end
	
	if tbFellowNpc.bFight then
		FightingToPoint(tbFellowNpc.nTemplateMapId, tbFellowNpc.nX, tbFellowNpc.nY);
	else
		RunToPoint(tbFellowNpc.nTemplateMapId, tbFellowNpc.nX, tbFellowNpc.nY);
	end
end

function WalfareActivate(nNow)
	nNextCheckWelfareListTime = nNextCheckWelfareListTime or 0;
	
	if not bCheckWelfareList then 
		if nNow > nNextCheckWelfareListTime then
			RemoteServer.GetWelfareList();
			bCheckWelfareList = true;
		end
	else
		local tbWelfareList = Ui("welfare_board").tbWelfareList or {};
		for _k, _v in ipairs(tbWelfareList) do
			if _v.State and _v.State.Button == "��ȡ" then	
				if _v.Key ~= "huoli4" and _v.Key ~= "huoli8" and _v.Key ~= "shihoupingjia" then
					RemoteServer.TakeWelfare(_v.Key);	
				end				
			end
		end
		nNextCheckWelfareListTime = nNow + 180;
		bCheckWelfareList = false;	
	end
	
	if Wnd_Visible("missionaward") == 1 then
		local uiMissionAward = Ui("missionaward");		
		if (uiMissionAward.nState == 4) then
			UiManager:CloseWindow("missionaward");
		elseif (uiMissionAward.nState == 3) then
			me.CallServerScript("MissionAwardCmd", "Request_AddGainItem", uiMissionAward.nRecordIdx);
		elseif (uiMissionAward.nState == 1) then
			if uiMissionAward.nTimes > MissionAwardGrade[uiMissionAward.nGrade] then
				uiMissionAward:SwitchState(2);
				me.CallServerScript("MissionAwardCmd", "Request_GainAward", uiMissionAward.nRecordIdx, 1);
				me.CallServerScript("MissionAwardCmd", "Request_OpenAward", uiMissionAward.nRecordIdx);
			end
		end
	end	
end

function DailyTargetActivate(nNow)
	nNextCheckDailyTargetRewardTime = nNextCheckDailyTargetRewardTime or 0;
	
	if not bCheckDailyTargetReward then 
		if nNow > nNextCheckDailyTargetRewardTime then
			RemoteServer.GetTodayTargetList();
			bCheckDailyTargetReward = true;
		end
	elseif Ui("calendar").tbRewardFlag then
		for nRewardLevel, bFlag in pairs(Ui("calendar").tbRewardFlag) do
			if not bFlag then
				RemoteServer.TakeDailyTargetReward(nRewardLevel);
			end
		end
		nNextCheckDailyTargetRewardTime = nNow + 180;
		bCheckDailyTargetReward = false;	
	end	
end
		
function AutoAwardActivate(nNow)
	nNextAutoAwardTime = nNextAutoAwardTime or 0;
	
	if nNow > nNextAutoAwardTime then		
		if Welfare.tbPlayerPray:HasPrayAward(me) == 1 then -- ��
			RemoteServer.PlayerPray_GetAward();
		elseif Ui("playerpray"):RemainGiftPrayTimes() then 
			RemoteServer.PlayerPray_DoPray();
		end
		
		TraverseItem(AutoUseItem);
				
		local tbFuDaiItem = Item:GetClass("fudai"); -- ����				
		if tbFuDaiItem.RemainFuDaiUseCount and tbFuDaiItem:RemainFuDaiUseCount(me) then
			tbFuDaiItem:ClientTryUseNormal(); 			
		end
				
		local nCount, nMaxCount = XFriendship.GetFrinedshipCount(Player.EMFRIENDSHIP_TYPE_FRIEND);
		if nCount < nMaxCount then
			local tbMemberList = me.GetTeamMemberList() or {}; -- �Զ��Ӷ����ԱΪ����
			for _, tbMember in pairs(tbMemberList) do
				if XFriendship.CheckFriendship(Player.EMFRIENDSHIP_TYPE_FRIEND, tbMember.dwPlayerID) ~= 1 then
					RemoteZone.AddFriendship(Player.EMFRIENDSHIP_TYPE_FRIEND, tbMember.szName);
				end
			end
		end

		nNextAutoAwardTime = nNow + 4;
	end
end

function KeepBagRetainCell(nRetainCellCount)
	local nLeftCount = nRetainCellCount - me.CountFreeBagCell();
	if nLeftCount < 0 then
		return true;
	end
	
	-- ����˴�����nLeftCount��������ѱ����ڵ�ȫ���ˣ����ƺ��ӳٸ��й�ϵ
	local fnClearBag = function (pItem, eItemType)
		if eItemType ~= Item.BAG_ROOM or pItem.nUseLevel > me.nLevel then
			return;
		end
		
		if pItem.szClass == "fudai" then
			me.UseItem(pItem);	
			return true;
		end
	end
	
	TraverseItem(fnClearBag);
end

function ChangeEnemyPlayerTitle(nNow)
	local tbEnemyNpc  = KNpc.GetAroundNpcList(me, 60, 8);
	for _, pNpc in pairs(tbEnemyNpc) do
		if pNpc.dwPlayerID > 0 and pNpc.dwPlayerID ~= me.GetNpc().dwPlayerID then
			local szFaction = tbFaction[pNpc.nFaction];
			if szFaction and szFaction ~= pNpc.GetTitle() then
				pNpc.SetTitle(szFaction);
			end
		end
	end
end

function TeamMmemberListOnButtonDBClick(tbSelf, szWnd, ...)	
	local szPreWnd, i = Ui.tbLogic.SplitSuperListName(szWnd);
	local tbSelectMember = Ui("team_member_list").tbMemberList[i];
	if tbSelectMember then
		tbSelf:StartFollow(tbSelectMember.dwPlayerID);
	end	
end 

function SelectNpcOnButtonRClick(tbSelf, szWnd, ...) 
	if szWnd == "ImgPortrait" then
		local pNpc	= KNpc.GetById(tbSelf.dwNpcId); -- ע�� tbSelf �����صĺ���API
		if not pNpc then
			return;
		end
		if pNpc.dwPlayerID ~= 0 then
			DetourCallOld(Ui("selectnpc"), "OnButtonRClick", tbSelf, szWnd, ...);
			return;
		end
		
		local tbMenu =
		{
			{
				szText = "����",
				tbCallback = {StartFollowNpc, pNpc.dwId, },
			},
			{
				szText = "����ս��",
				tbCallback = {StartFollowNpc, pNpc.dwId, true},
			},
			{
				szText = "ȡ������",
				tbCallback = {EndFollowNpc, },
			},
		};
			
		Ui.tbLogic.tbRightMenu:OpenMenu(pNpc.szName, pNpc.dwPlayerID, tbMenu);
	end	
end

function SellGrayItem(pItem, eItemType) 
	if eItemType == Item.BAG_ROOM then
		if pItem.nQuality == 99 then
			me.Msg("�Զ����ۻ�ɫ��Ʒ:" .. pItem.szName);
			RemoteServer.NpcShopSell(pItem.dwId, pItem.nCount, 1);		
			return;
		end
	end
	
	if eItemType == Item.ROOM_MEDICIN then
		local szType = GetMapType(me.nTemplateMapId);	
		if szType ~= "city" and szType ~= "faction" then
			if pItem.szForbidType == "battle_medicine" and szType ~= "battle" then  
				me.Msg("�Զ�����ս��ҩƷ:" .. pItem.szName);
				RemoteServer.NpcShopSell(pItem.dwId, pItem.nCount, 1);		
				return;			
			end
			
			if pItem.szForbidType == "domain_medicine" and szType ~= "domain" then
				me.Msg("�Զ�����ս��ҩƷ:" .. pItem.szName);
				RemoteServer.NpcShopSell(pItem.dwId, pItem.nCount, 1);		
				return;			
			end			
		end
	end	
end

function AutoUseItem(pItem, eItemType)
	if eItemType ~= Item.BAG_ROOM or pItem.nUseLevel > me.nLevel then
		return;
	end
	
	if tbAutoUseItemKindBlacklist[pItem.szKind] then
		return;
	end
					
	if tbAutoUseItem[pItem.szClass] then
		me.UseItem(pItem);
	elseif pItem.szClass == "sycee" then
		local nHasCount = me.GetItemCountInBags(pItem.dwTemplateId, 1);
		if nHasCount == 1 then
			me.UseItem(pItem);
		end
	elseif pItem.szClass == "novive" then
		local _, nUseLevel, _ = Item:GetClass("novive"):GetAward(me, pItem);
		if nUseLevel <= me.nLevel then
			me.UseItem(pItem);
		end		
	end		
end

function StartFollowNpc(dwFollowNpcID, bFight)
	EndFollowNpc();
	tbFellowNpc = { nNextFellowTime = 0 };
	tbFellowNpc.dwFollowNpcID = dwFollowNpcID;
	tbFellowNpc.bFight = bFight;
end

function EndFollowNpc()
	tbFellowNpc = nil;
end
