Include("PluginBase");
SetDescription("战场助手", false);

local tbFactionSafeDistance = 
{
	[Player.FACTION_NONE] = 300,
    [Player.FACTION_TIANWANG] = 300,
    [Player.FACTION_SHAOLIN] = 300,
    [Player.FACTION_XIAOYAO] = 300,
    [Player.FACTION_HUASHAN] = 300,
    [Player.FACTION_KUNLUN] = 300,
    [Player.FACTION_WUDANG] = 600,
    [Player.FACTION_TAOHUADAO] = 600,
    [Player.FACTION_EMEI] = 600,
    [Player.FACTION_GAIBANG] = 300,
    [Player.FACTION_TANGMEN] = 600,
};

function Setup()
	DetourAttach(UiManager, "OnLButtonDown", OnLButtonDown);
	
	nNextActivateFrame = 0;
	
	me.SetClientValue_Int(AutoFight.SAVE_GROUP, AutoFight.KEY_MODE, 1);
	me.SetClientValue_Int(AutoFight.SAVE_GROUP, AutoFight.KEY_AUTO_MED, 1); -- 开启自动吃药
	me.SetClientValue_Int(AutoFight.SAVE_GROUP, AutoFight.KEY_LIFE_PERCENT, 75);  -- 自动吃药生命值百分比
	me.SetClientValue_Int(AutoFight.SAVE_GROUP, AutoFight.KEY_MED_SPAN, 500);  -- 自动吃药间隔

	me.SaveClientData();	
	AutoFight:LoadSetting();
	
	return true;
end

function Clear()
	DetourDetach(UiManager, "OnLButtonDown");
	
	me.SetClientValue_Int(AutoFight.SAVE_GROUP, AutoFight.KEY_MODE, 0);
	me.SetClientValue_Int(AutoFight.SAVE_GROUP, AutoFight.KEY_AUTO_MED, 1); -- 开启自动吃药
	me.SetClientValue_Int(AutoFight.SAVE_GROUP, AutoFight.KEY_LIFE_PERCENT, 50);  -- 自动吃药生命值百分比
	me.SetClientValue_Int(AutoFight.SAVE_GROUP, AutoFight.KEY_MED_SPAN, 1000);  -- 自动吃药间隔
	me.SaveClientData();	
	AutoFight:LoadSetting();
end

function Activate(nNow)
	if me.nFightState == 0 then -- 非战斗状态没必要执行
		return;
	end
	
	if BattleActivate(nNow) then
		return;
	end
	
	UiSelectNpc(0);
	AutoAi.SetTargetIndex(0);
	AutoFight:Stop();
end

-- 技巧
-- 武当 站在障碍死角除放机能
function BattleActivate(nNow)
	local pPlayerNpc = me.GetNpc();
	
	if pPlayerNpc.nDoing == _NpcDoingDef.do_jump then 		
		return;
	end
	
	if pPlayerNpc.nDoing ~= _NpcDoingDef.do_stand and nNextActivateFrame > nNow then	
		return;
	end
	
	local tbShaoLinEnemyNpc  = KNpc.GetAroundNpcList(me, 14, 8); -- 220 / 32 * 2 
	for _, pNpc in pairs(tbShaoLinEnemyNpc) do	
		if pNpc.nFaction == Player.FACTION_SHAOLIN then
			Msg("小心！周围有少林");
			break;
		end
	end
			
	local tbEnemyNpc  = KNpc.GetAroundNpcList(me, 38, 8);
	table.sort(tbEnemyNpc, NpcSortFun);	
		
	for _, pNpc in pairs(tbEnemyNpc) do	
		if pNpc.dwPlayerID > 0 then
			local nDistance = pPlayerNpc.GetDistance(pNpc.nIndex);
			if nDistance < tbFactionSafeDistance[pPlayerNpc.nFaction] then
				AutoAi.SetActiveSkill(me.GetLeftSkill());
				AutoAi.SetTargetIndex(pNpc.nIndex);
				AutoFight:Start();
				UiSelectNpc(pNpc.nIndex);
				return true;
			end
		end
	end
	
	Msg("周围没有敌人，快去前线杀敌！");
end

function IsAvailable() 
	local szType = GetMapType(me.nTemplateMapId);	
	return szType == "battle" or szType == "factionbattle" or szType == "domain";
end

function NpcSortFun(pNpc1, pNpc2)
	local nCurLife1 = pNpc1.nCurLife;
	local nCurLife2 = pNpc2.nCurLife;
	
	if nCurLife1 == nCurLife2 then
		local nDistance1 = me.GetNpc().GetDistance(pNpc1.nIndex);
		local nDistance2 = me.GetNpc().GetDistance(pNpc2.nIndex);
		
		return nDistance1 < nDistance2;	
	end
	
	return nCurLife1 < nCurLife2;
end

function OnLButtonDown(self, tbUiManager) -- 注意此处self为UiManager
	nNextActivateFrame = GetTime() + 2; 
	AutoFight:Stop();
	DetourCallOld(UiManager, "OnLButtonDown", self, tbUiManager);
end