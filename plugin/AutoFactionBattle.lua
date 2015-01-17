Include("CmdPlugin");
SetDescription("自动门派竞技", false, "");

local tbFactionMap = 
{
    [Player.FACTION_TIANWANG] = {},
    [Player.FACTION_SHAOLIN] = {},
    [Player.FACTION_XIAOYAO] = {},
    [Player.FACTION_HUASHAN] = {},
    [Player.FACTION_KUNLUN] = {},
    [Player.FACTION_WUDANG] = {26, 1886, 3245},
    [Player.FACTION_TAOHUADAO] = {},
    [Player.FACTION_EMEI] = {},
    [Player.FACTION_GAIBANG] = {},
    [Player.FACTION_TANGMEN] = {},
};

function FactionMapX()
end

tbStep = {
	{RunToPoint, unpack(tbFactionMap[me.GetNpc().nFaction])},	
};

