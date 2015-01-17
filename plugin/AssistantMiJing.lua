Include("PluginBase");
SetDescription("秘境助手", false);

local tbMapPoint = 
{
--	[27] = -- 星陨铁堡
--	{
--		{nX = 1703, nY = 3136, },
--		{nX = 1773, nY = 3188, nShortcutNpc = 3334, },
--		{nX = 1727, nY = 3304, nShortcutNpc = 3334, },
--		{nX = 1702, nY = 3269, nShortcutNpc = 3335, },
--		{nX = 1630, nY = 3201, nShortcutNpc = 3335, },
--		{nX = 1572, nY = 3262 },
--		{nX = 1678, nY = 3433, nShortcutNpc = 3336, },
--	},
	[76] = -- 落叶谷
	{
		{nX = 1820, nY = 3333, },
		{nX = 1617, nY = 3358, nShortcutNpc = 3332, },
		{nX = 1674, nY = 3554, nShortcutNpc = 3333, },
		{nX = 1704, nY = 3689, nShortcutNpc = 3333, },
		{nX = 1719, nY = 3572, nShortcutNpc = 3333, },	
	},
	[31] = -- 家族试炼
	{
		{nX = 1918, nY = 2777, },
		{nX = 1995, nY = 2681, bOnlyRunToFlag = true, },
	},
	[104] = -- 离忧岛废墟
	{
		{nX = 1610, nY = 3002, },
		{nX = 1591, nY = 3087, },
		{nX = 1630, nY = 3129, },
		{nX = 1711, nY = 3191, },
	},
};

function Setup()
	local tbMapPoints = tbMapPoint[me.nTemplateMapId];
	if tbMapPoints then
		return true;
	end
		
	if Ui("team_member_list").dwFollowMemberID then
		return;
	end
		
	local tbTeamMember = me.GetTeamMemberList() or {};
	for _, tbMember in ipairs(tbTeamMember) do -- 优先跟随峨眉
		if tbMember.dwPlayerID ~= dwPlayerID and tbMember.nFaction == Player.FACTION_EMEI then
			Ui("team_member_list"):StartFollow(tbMember.dwPlayerID)
			return;
		end
	end
	for _, tbMember in ipairs(tbTeamMember) do -- 随便跟随一个
		if tbMember.dwPlayerID ~= dwPlayerID then
			Ui("team_member_list"):StartFollow(tbMember.dwPlayerID)
			return;
		end
	end		
end

function Activate(nNow)	
	if AutoMoveActivate(nNow) then
		return;
	end		
end

function Shortcuts(nShortcutNpc)
	local tbNpc = KNpc.GetAroundNpcList(me, 96);

	for _, pNpc in pairs(tbNpc) do
		if pNpc.nTemplateId == nShortcutNpc then
			local _, nX, nY = pNpc.GetWorldPos();
			RunToPoint(me.nTemplateMapId, nX, nY);	
			return true;			
		end
	end
end

function NpcSortFun(pNpc1, pNpc2)
	local nDistance1 = me.GetNpc().GetDistance(pNpc1.nIndex);
	local nDistance2 = me.GetNpc().GetDistance(pNpc2.nIndex);
	
	return nDistance1 < nDistance2;
end

function AutoMoveActivate(nNow)		
	if not nPointIndex or nTemplateMapId ~= me.nTemplateMapId then
		nTemplateMapId = me.nTemplateMapId;
		nPointIndex = 1;
	end
	
	local tbMapPoints = tbMapPoint[nTemplateMapId];
	if not tbMapPoints then
		nTemplateMapId = nil;
		nPointIndex = nil;
		return;
	end	
	
	if me.GetNpc().nDoing == _NpcDoingDef.do_jump then -- 轻功说明人在操作
		return;
	end
		
	while true do
		local tbMapPoint = tbMapPoints[nPointIndex];
		
		if not tbMapPoint then
			Msg("秘境完成, 插件自动关闭");
			DisablePlugin();	
			break;
		end		
				
		if tbMapPoint.nShortcutNpc and Shortcuts(tbMapPoint.nShortcutNpc) then
			Msg("快捷寻路中");
			break;
		end		
		
		if tbMapPoint.bOnlyRunToFlag then
			local bRetCode = RunToPoint(nTemplateMapId, tbMapPoint.nX, tbMapPoint.nY);
			if not bRetCode then
				break;
			end			
		else
			local bRetCode = FightingToPoint(nTemplateMapId, tbMapPoint.nX, tbMapPoint.nY);
			if not bRetCode then
				break;
			end			
		end
		
		nPointIndex = nPointIndex + 1;
		break;
	end
	
	return true;
end

function IsAvailable() 
	local szType = GetMapType(me.nTemplateMapId);	
	return szType == "fuben";
end