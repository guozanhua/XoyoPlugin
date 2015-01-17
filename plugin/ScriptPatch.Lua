-- 游戏脚本补丁
function Task:GetTaskNpcCityMapPosByNpc(nOrgMapID, nNpcID) -- 修复GetTaskNpcCityMapPosByNpc中的bug
	local tbXoyoMap = Ui.tbLogic.tbXoyoMap;
	local nMapID = nOrgMapID;
	local tbCityMapID = 
	{
		[30] = 1;
		[176] = 1;
		[178] = 1;
		[179] = 1;
		[180] = 1;
	};

	if tbCityMapID[nOrgMapID] then
		nMapID = self.tbTrackMapTable[me.nTemplateMapId] or nOrgMapID; -- 此处修复
	end
	
	local strPathLink = tbXoyoMap:GetAutoPathLink(nMapID, nNpcID);
	local nRealMapID, nX, nY = self:AnyleLink(strPathLink);
	
	if not nRealMapID or not nX or not nY then
		return;
	end
	
	return tonumber(nRealMapID), nX / 32, nY / 32;
end

function Task:AnyleLink(szString)
    if not szString then
        return;
    end
	
	-- 如果是 link=pos 那么就直接返回
	local nMapId, nX, nY = string.match(szString, "(%s*%d+%s*),(%s*%d+%s*),(%s*%d+%s*)>");
	if nMapId then
		return nMapId, nX, nY;
	end
	
	local tbLinePart = Lib:SplitStr(szString);
	if not tbLinePart[2] then -- 此处修复
		return;
	end
	
	local tbLinkPos = string.gmatch(tbLinePart[2], "%d+");  -- 得到坐标的内容
	local tbPos = {};
	local nIndex = 1;
	for s in tbLinkPos do
		tbPos[nIndex] = s;
		nIndex = nIndex + 1;
	end

	if not tbPos[1] or not tbPos[2] or not tbPos[3] then
		return;
	end
	
    nMapId = tonumber(tbPos[1]);
	nX = tonumber(tbPos[2]);
	nY = tonumber(tbPos[3]);
	
    return nMapId, nX, nY;
end


AutoFight.tbFightRange =
{
	[Player.FACTION_NONE]		= 20;		-- 无门派
	[Player.FACTION_TIANWANG]	= 20;		-- 天王
	[Player.FACTION_SHAOLIN]	= 20;		-- 少林
	[Player.FACTION_XIAOYAO]	= 20;		-- 逍遥
	[Player.FACTION_HUASHAN]	= 20;		-- 华山
	[Player.FACTION_KUNLUN]		= 20;		-- 昆仑
	[Player.FACTION_WUDANG]		= 37;		-- 武当
	[Player.FACTION_TAOHUADAO]	= 37;		-- 桃花岛
	[Player.FACTION_EMEI]		= 37;		-- 峨眉
	[Player.FACTION_GAIBANG]	= 25;		-- 丐帮
	[Player.FACTION_TANGMEN]	= 37;		-- 唐门
};

ForbitGameSpace(0);
_G.ForbitGameSpace = function()
end

function Item:IsEquip(nItemType) -- 判断该道具是否一件装备
	if nItemType > 0 and  nItemType < 31 then
		return 1;
	end
end

Wnd_SetSize("enhance", "TxtInfo", nil, 100);

local uiPluginPanel = Ui("xymanual");
uiPluginPanel.uiRowPanel = "RowPanel";
uiPluginPanel.uiBtnPluginLeft = "BtnPluginLeft";
uiPluginPanel.uiBtnPluginRight = "BtnPluginRight";
uiPluginPanel.uiBtnClose = "btnClose";

function uiPluginPanel:OnOpen(tbBtnSetting)
	if not self.bCreatePluginPanel then
		local tbChildSet = Wnd_GetChildSet(self.UIGROUP, "Main");
		for _, tbChild in ipairs(tbChildSet.tbChild) do
			if tbChild.szWndName ~= self.uiBtnClose then
				Wnd_Hide(self.UIGROUP, tbChild.szWndName);	
			end
		end
			
		Wnd_SetSize(self.UIGROUP, "Main", 270, 400);				
		Wnd_SetPos(self.UIGROUP, self.uiBtnClose, 239, 10);	
				
		local uiRowPanel = self.uiRowPanel .. "1";
		local uiBtnPluginLeft = self.uiBtnPluginLeft .. "1";
		local uiBtnPluginRight = self.uiBtnPluginRight .. "1";
		
		CopyWnd("logout_retain", "LogoutItem", self.UIGROUP, "Main", uiRowPanel);
		Wnd_SetPos(self.UIGROUP, uiRowPanel, 6, 45);
		Wnd_SetSize(self.UIGROUP, uiRowPanel, 260, 30);	
			
		CopyWnd("gamesetting", "BtnHideGuide", self.UIGROUP, uiRowPanel, uiBtnPluginLeft);
		Wnd_SetPos(self.UIGROUP, uiBtnPluginLeft, 8, 0);
		Wnd_SetSize(self.UIGROUP, uiBtnPluginLeft, 130, 20);	
				
		CopyWnd("gamesetting", "BtnHideGuide", self.UIGROUP, uiRowPanel, uiBtnPluginRight);
		Wnd_SetPos(self.UIGROUP, uiBtnPluginRight, 146, 0);
		Wnd_SetSize(self.UIGROUP, uiBtnPluginRight, 130, 20);	
		
		self.tbPluginUi = Ui.tbLogic.CreateSuperList{Instance = self.UIGROUP, Parent = "Main", Panel = "RowPanel"};
		self.tbPluginUi.Resize(0);	
		
		self.bCreatePluginPanel = true;
	end
	
	if not tbBtnSetting then
		MiniClient.PluginManger:Show();
		return;
	end
	
	local nWidth, nHeight = Wnd_GetScreenSize();	
	Wnd_SetPos(self.UIGROUP, "Main", nWidth - 300, nHeight - 468);		
	
	local nLines = math.ceil(#tbBtnSetting / 2);
	self.tbPluginUi.Resize(nLines);	
	self.tbBtnCallback = 
	{ 
		[self.uiBtnClose] = function() 
			UiManager:CloseWindow(self.UIGROUP); 	
			return false;
		end
	};	
	
	local nBtnSettingIndex = 1;
	for i = 1, nLines do
		local uiBtnPluginLeft = self.uiBtnPluginLeft .. i;
		local uiBtnPluginRight = self.uiBtnPluginRight .. i;
		
		local tbBtnLeft = tbBtnSetting[nBtnSettingIndex];		
		if tbBtnLeft then
			Wnd_Show(self.UIGROUP, uiBtnPluginLeft);  
			Btn_SetTxt(self.UIGROUP, uiBtnPluginLeft, tbBtnLeft.szText);
			Wnd_SetTip(self.UIGROUP, uiBtnPluginLeft, tbBtnLeft.szTip);
			Btn_Check(self.UIGROUP, uiBtnPluginLeft, tbBtnLeft.bChecked and 1 or 0);
			self.tbBtnCallback[uiBtnPluginLeft] = tbBtnLeft.fnCallback;
		else
			Wnd_Hide(self.UIGROUP, uiBtnPluginLeft);  
		end
		nBtnSettingIndex = nBtnSettingIndex + 1;
		
		local tbBtnRight = tbBtnSetting[nBtnSettingIndex];		
		if tbBtnRight then
			Wnd_Show(self.UIGROUP, uiBtnPluginRight);  
			Btn_SetTxt(self.UIGROUP, uiBtnPluginRight, tbBtnRight.szText);
			Wnd_SetTip(self.UIGROUP, uiBtnPluginRight, tbBtnRight.szTip);
			Btn_Check(self.UIGROUP, uiBtnPluginRight, tbBtnRight.bChecked and 1 or 0);
			self.tbBtnCallback[uiBtnPluginRight] = tbBtnRight.fnCallback;
		else
			Wnd_Hide(self.UIGROUP, uiBtnPluginRight);  
		end
		nBtnSettingIndex = nBtnSettingIndex + 1;
	end
end

function uiPluginPanel:OnButtonClick(szWnd, nParam)
	if self.tbBtnCallback[szWnd] then
		local bReOpen = self.tbBtnCallback[szWnd](nParam);
		if bReOpen then
			self:OnOpen();
		end
	end
end