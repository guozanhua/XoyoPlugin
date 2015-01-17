-- PluginMgr
local tbPluginManger = MiniClient.PluginManger or {}
MiniClient.PluginManger = tbPluginManger;

local szPluginDir = "plug_in/Plugin/";

function tbPluginManger:Setup()
	self:DetourSetup();
	
	UiNotify:RegistNotify(UiNotify.emUIEVENT_WND_OPENED, self.OnWndOpen, self);	
	UiNotify:RegistNotify(UiNotify.emCOREEVENT_SYNC_CURRENTMAP, self.OnEnterMap, self);	
	
	assert(not self.nActivateTimerID);
	self.nActivateTimerID = Ui.tbLogic.tbTimer:Register(Env.GAME_FPS, self.Activate, self);
	
	self:DetourAttach(Ui("saypanel"), "OnOpen", self.OnSayPanelOpen);
		
	self:LoadPatch();
	
	assert(not MiniClient.Plugin);
	MiniClient.Plugin = {}	
	self:LoadPlugin();	
	
	for _k, _v in pairs (MiniClient.Plugin) do
		if _v.bEnable then
			_v.EnablePlugin();
		end	
	end
end

function tbPluginManger:Clear()	
	if MiniClient.Plugin then
		for _k, _v in pairs (MiniClient.Plugin) do
			if _v.bEnable then
				_v:DisablePlugin();
			end	
		end	
		
		MiniClient.Plugin = nil;
	end
		
	self:DetourDetach(Ui("saypanel"), "OnOpen");
	
	if self.nActivateTimerID then
		Ui.tbLogic.tbTimer:Close(self.nActivateTimerID);
		self.nActivateTimerID = nil;
	end
	
	UiNotify:UnRegistNotify(UiNotify.emUIEVENT_WND_OPENED, self);
	UiNotify:UnRegistNotify(UiNotify.emCOREEVENT_SYNC_CURRENTMAP, self);
	
	self:DetourClear();
end

function tbPluginManger:Show()		
	local szText = "点击对话框即可<color=green>打开<color>或者<color=gray>关闭<color>";
	local tbOptList = {};
	
	for _k, _v in pairs (MiniClient.Plugin) do
		local tbItem = 
		{
			szText = _v.szName, 
			bChecked = _v.bEnable;
			szTip = _v.szDescription or "";
			fnCallback = function() 			
				if _v.bEnable then					
					_v.DisablePlugin();
				else
					_v.EnablePlugin();
				end				
				return true;
			end,
			nUiIndex = _v._nUiIndex,
		}
		
		if _v.szName then
			table.insert(tbOptList, tbItem);
		end		
	end
	
	local fnSort = function (tbItem1, tbItem2)
		return tbItem1.nUiIndex < tbItem2.nUiIndex;
	end
	table.sort(tbOptList, fnSort);
	
	local tbItem = 
	{
		szText = "离开秘境", 
		szTip = "秘境结束后可用";
		fnCallback = function() 
			me.CallServerScript("MissionAwardCmd", "Request_Leave");
			self:Msg("已发送离开秘境指令");
			return true;
		end
	}
	table.insert(tbOptList, tbItem);
			
	local tbItem = 
	{
		szText = "重新加载所有插件", 
		szTip = "";
		fnCallback = function() 
			self:Clear();
			self:Setup();
			self:Msg("重新加载插件成功");
			return true;
		end
	}
	table.insert(tbOptList, tbItem);
	UiManager:OpenWindow("xymanual", tbOptList);
end

function tbPluginManger:Activate()
	if self.nNextActivateFrame and self.nNextActivateFrame > GetFrame() then
		return;		
	end
	
	local nNow = GetTime();	
	for _k, _v in pairs (MiniClient.Plugin) do
		if _v.bEnable then
			Lib:CallBack({_v.Activate, nNow});
		end	
	end	
end

function tbPluginManger:OnWndOpen(szUiGroup)
	if szUiGroup == "skillprogress" then
		local uiSkillProgress = Ui("skillprogress");
		self.nNextActivateFrame = GetFrame() + uiSkillProgress.nInterval;
	end
	
	for _k, _v in pairs (MiniClient.Plugin) do
		if _v.bEnable then
			Lib:CallBack({_v.OnWndOpen, szUiGroup});			
		end	
	end
end

function tbPluginManger:OnEnterMap(nTemplateMapId)
	for _k, _v in pairs (MiniClient.Plugin) do
		if _v.bEnable then
			Lib:CallBack({_v.OnEnterMap, nTemplateMapId});			
		end	
	end
end

function tbPluginManger.OnSayPanelOpen(tbSelf, tbDlgInfo) 
	-- 注意 self 是拦截的函数API
	local nRetCode = tbPluginManger:DetourCallOld(Ui("saypanel"), "OnOpen", tbSelf, tbDlgInfo);
	if nRetCode == 0 then
		return 0;
	end
	
	for _k, _v in pairs (MiniClient.Plugin) do
		if _v.bEnable then
			local bSuccess, bProcess = Lib:CallBack({_v.OnShowDialog, tbDlgInfo});		
			if bSuccess and bProcess then
				return 0;
			end
		end	
	end	
end

function tbPluginManger:CreatePlugin(szPlugin, szParentPlugin) 
	local tbPlugin = MiniClient.Plugin[szPlugin];
	if tbPlugin then
		return tbPlugin;
	end
	
	local tbParentPlugin = MiniClient.Plugin[szParentPlugin];
	if not tbParentPlugin then
		tbParentPlugin = tbPluginBase;
	end
	
	tbPlugin = Lib:NewClass(tbParentPlugin);		
	MiniClient.Plugin[szPlugin] = tbPlugin;
	
	return tbPlugin;
end

function tbPluginManger:LoadPatch()	
	local szLuaFile = szPluginDir .. "ScriptPatch.Lua";
	local szText = KIo.ReadTxtFile(szLuaFile, 1);
	
	assert(szText);
	
	local fnFile, szMsg = loadstring(szText);
	if not fnFile then
		Log("Load ScriptPatch failed", szMsg);
	end
	
	assert(fnFile);
	fnFile();	
end

function tbPluginManger:LoadPlugin()	
	local pTabFile = KIo.OpenTabFile(szPluginDir .. "list.txt", 1);
	assert(pTabFile);
	
	for nRow = 1, pTabFile.GetHeight() do
		local szPlugin = pTabFile.GetStr(nRow, 1);
		
		if szPlugin and szPlugin ~= "" then
			local szLuaFile = szPluginDir .. szPlugin .. ".lua";
			local fnFile, szMsg = nil, nil;
			
			if loadfile then
				fnFile, szMsg = loadfile(szLuaFile);	
			else
				local szText = KIo.ReadTxtFile(szLuaFile, 1);	
				assert(szText, szPlugin);
				szText = string.format("-- %s\n%s", szPlugin, szText);	
				
				fnFile, szMsg = loadstring(szText);
			end		
			
			assert(fnFile, szMsg);	
			
			local tbPlugin = {};

			setmetatable(tbPlugin, { __index = _G, });	
			tbPlugin.Include = tbPluginManger.Include;		

			setfenv(fnFile, tbPlugin);	
			fnFile();
			
			tbPlugin._nUiIndex = nRow;
			MiniClient.Plugin[szPlugin] = tbPlugin;	
		end
	end	
	
	KIo.CloseTabFile(pTabFile);	
end

function tbPluginManger.Include(szPlugin)
	local szLuaFile = szPluginDir .. szPlugin .. ".lua";
	local fnFile, szMsg = nil, nil;
	
	if loadfile then
		fnFile, szMsg = loadfile(szLuaFile);			
	else
		local szText = KIo.ReadTxtFile(szLuaFile, 1);				
		szText = string.format("-- %s\n%s", szPlugin, szText);	
		
		fnFile, szMsg = loadstring(szText);
	end		
	
	assert(fnFile, szMsg);	
	
	local tbEnv = getfenv(2);
	setfenv(fnFile, tbEnv);	
	
	fnFile();
end

function tbPluginManger:DetourSetup()		
	assert(self.tbDetourFunctions == nil);	
	self.tbDetourFunctions = {};
end

function tbPluginManger:DetourClear()	
	for fnFunction, tbDetour in pairs (self.tbDetourFunctions) do
		local fnFunctionCheck = tbDetour.tbTable[tbDetour.szName];
		assert(fnFunctionCheck == fnFunction);
		
		tbDetour.tbTable[tbDetour.szName] = tbDetour.fnOldFunction;
		Log(tbDetour.szName, "由DetourClear释放");
	end
	self.tbDetourFunctions = nil;
end

function tbPluginManger:DetourAttach(tbTable, szName, fnFunction)		
	local fnOldFunction = tbTable[szName];
	if fnOldFunction then
		assert(type(fnOldFunction) == "function");
		assert(self.tbDetourFunctions[fnOldFunction] == nil); -- 这儿可以不判断这个的,只是不想此功能滥用
	end
		
	assert(self.tbDetourFunctions[fnFunction] == nil);
	
	self.tbDetourFunctions[fnFunction] = {
		tbTable = tbTable, 
		szName = szName, 
		fnOldFunction = fnOldFunction, 
		fnFunction = fnFunction, 
	};	
	tbTable[szName] = fnFunction;
end

function tbPluginManger:DetourDetach(tbTable, szName)	
	local fnFunction = tbTable[szName];
	local tbDetour = self.tbDetourFunctions[fnFunction];
	
	assert(tbDetour, szName);
	assert(tbTable == tbDetour.tbTable);
	assert(szName == tbDetour.szName);
	
	tbDetour.tbTable[tbDetour.szName] = tbDetour.fnOldFunction;
	self.tbDetourFunctions[fnFunction] = nil;
end

function tbPluginManger:DetourCallOld(tbTable, szName, ...)
	local fnFunction = tbTable[szName];
	local tbDetour = self.tbDetourFunctions[fnFunction];
	
	assert(tbDetour, szName);
	assert(tbTable == tbDetour.tbTable);
	assert(szName == tbDetour.szName);
	
	return tbDetour.fnOldFunction(...);
end

function tbPluginManger:Msg(szMsg)
	Ui("tasktips"):Begin(szMsg);
end

if not MiniClient.Plugin then		
	tbPluginManger:Setup();		
end
tbPluginManger:Show();
