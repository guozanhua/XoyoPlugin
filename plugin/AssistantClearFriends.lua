Include("PluginBase");
SetDescription("清理好友助手", false);

function Setup() -- 不返回成功
	local bAutoAddIntimacy = false;
	local nLeftClearCount = 5;
	local nClearIntimacy = 0;
	
	local nCount, nMaxCount = XFriendship.GetFrinedshipCount(Player.EMFRIENDSHIP_TYPE_FRIEND);
	if nCount == nMaxCount then
		bAutoAddIntimacy = true;
	end
	
	local nDeleteTime = GetTime() - 3 * 24 * 3600; -- 三天没有上线
	local tbFriends = XFriendship.GetFriends(1, 0) or {};	
	while true do
		for _, tbFriend in pairs(tbFriends) do
			local bInCustomGroupFlag = false;
			for i = 1, 8 do
				if XFriendship.InCustomGroup(i - 1, tbFriend.dwPlayerID) == 1 then
					bInCustomGroupFlag = true;
					break;
				end
			end
			
			if not bInCustomGroupFlag then
				if tbFriend.nLastSaveTime < nDeleteTime then
					RemoteZoneSafe.DelFriendship(Player.EMFRIENDSHIP_TYPE_FRIEND, tbFriend.dwPlayerID);	
					me.Msg(string.format("自动清理[%s]最后上线时间%s", tbFriend.szName, os.date("%Y-%m-%d", tbFriend.nLastSaveTime)));
					nLeftClearCount = nLeftClearCount - 1;				
				elseif tbFriend.nIntimacy == nClearIntimacy then
					RemoteZoneSafe.DelFriendship(Player.EMFRIENDSHIP_TYPE_FRIEND, tbFriend.dwPlayerID);	
					me.Msg(string.format("自动清理[%s]亲密度:%d", tbFriend.szName, tbFriend.nIntimacy));
					nLeftClearCount = nLeftClearCount - 1;
				end			
			end
			
			if nLeftClearCount == 0 then			
				break;
			end
		end
		
		if (not bAutoAddIntimacy) or nLeftClearCount == 0 then			
			break;
		end
		
		nClearIntimacy = nClearIntimacy + 1;
	end
	
	Msg("清理好友成功");
end

function IsAvailable() 
	local szType = GetMapType(me.nTemplateMapId);	
	return szType == "fuben";
end