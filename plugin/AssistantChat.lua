Include("PluginBase");
Include("Cryptography");
SetDescription("��������", true);

local szChatKey = "return";
local tbChatFilter = 
{
	"���˵�ͷ", 
	"�鸣����",
	"�齱�л����",
}

function Setup() 
	DetourAttach(Ui.tbLogic.tbChatMgr, "OnPrivateMessage", OnPrivateMessage);		
	DetourAttach(Ui.tbLogic.tbChatMgr, "OnChannelSystemMessage", OnChannelSystemMessage);
	DetourAttach(Ui.tbLogic.tbChatMgr, "OnChannelMessage", OnChannelMessage);
	
	DetourAttach(Ui("friendship_detail"), "OnButtonClick", OnFriendshipDetailButtonClick);	
	return true;
end

function Clear() 
	DetourDetach(Ui("friendship_detail"), "OnButtonClick");	
	DetourDetach(Ui.tbLogic.tbChatMgr, "OnChannelMessage");
	DetourDetach(Ui.tbLogic.tbChatMgr, "OnChannelSystemMessage");
	DetourDetach(Ui.tbLogic.tbChatMgr, "OnPrivateMessage");
end

function OnPrivateMessage(tbSelf, szSender, tbLink, szMsg)	
	local bSucced, szCmd = Lib:CallBack({Decryption, szMsg});
	if not bSucced or not szCmd then
		DetourCallOld(Ui.tbLogic.tbChatMgr, "OnPrivateMessage", tbSelf, szSender, tbLink, szMsg);
		return;	
	end
	
	local nStart = string.find(szCmd, szChatKey);
	if not nStart and nStart ~= 1 then
		DetourCallOld(Ui.tbLogic.tbChatMgr, "OnPrivateMessage", tbSelf, szSender, tbLink, szMsg);
		return;
	end
				
	fnCmd, szMsg = loadstring(szCmd);
	if not fnCmd then
		Log("AssistantChat", "load string error!", szMsg, szCmd);
		return;	
	end

	local tbEnv = getfenv(1);
	setfenv(fnCmd, tbEnv);
	
	local bSucced, tbCmd = Lib:CallBack({fnCmd});
	if not bSucced then
		Log("AssistantChat", "do string error!", szMsg, szCmd);
		return;
	end
		
	bSucced = Lib:CallBack(tbCmd);
	if not bSucced then
		Log("AssistantChat", "do cmd error!", szMsg, szCmd);
		return;	
	end
	
	Log("AssistantChat", szSender, "Send", szCmd);
end

function OnChannelSystemMessage(tbSelf, varChannelType, szHead, szMsg) 
	for _, szFilter in pairs(tbChatFilter) do
		if string.find(szMsg, szFilter) then
			return;
		end
	end

	DetourCallOld(Ui.tbLogic.tbChatMgr, "OnChannelSystemMessage", tbSelf, varChannelType, szHead, szMsg);
end

function OnChannelMessage(tbSelf, nChannelType, nDynamicId, nChatTitleId, szName, tbLink, szMsg) 	
	for _, szFilter in pairs(tbChatFilter) do
		if string.find(szMsg, szFilter) then
			return;
		end
	end

	DetourCallOld(Ui.tbLogic.tbChatMgr, "OnChannelMessage", tbSelf, nChannelType, nDynamicId, nChatTitleId, szName, tbLink, szMsg);
end

function OnFriendshipDetailButtonClick(tbSelf, ...)	 
	local szReceiver = Txt_GetTxt(tbSelf.UIGROUP, "PlayerName");
	local _, nEnd = string.find(szReceiver, "<color>");
	if nEnd then
		szReceiver = string.sub(szReceiver, nEnd + 1);
	end
	
	local _, nCurX, nCurY = me.GetWorldPos();
	
	local tbMenu =
	{
		{
			szText = "����",
			tbCallback = {SendCmdMsg, szReceiver, "RunToPoint", me.nTemplateMapId, nCurX, nCurY, },
		},	
		{
			szText = "���",
			tbCallback = {SendCmdMsg, szReceiver, "AutoFight.Start", "AutoFight"},
		},
		{
			szText = "�����",
			tbCallback = {SendCmdMsg, szReceiver, "AutoFight.Stop", "AutoFight"},
		},	
		{
			szText = "�ӳ�����",
			tbCallback = {SendCmdMsg, szReceiver, "me.TeamAppoint", "[[" .. me.szName .. "]]"},
		},			
	};
	
	Ui.tbLogic.tbRightMenu:OpenMenu(szReceiver, 0, tbMenu);
end

function SendCmdMsg(szReceiver, ...)
	local szCmd = string.format("%s {%s}", szChatKey, table.concat({...}, ","));
	
	for i = 1, 10 do
		local szMsg = Encryption(szCmd);
		if #szMsg > (1024 * 8 - 34) then
			Msg(string.format("��%s����%s�ַ���̫����", szReceiver, szCmd));		
			return;
		end
		
		if VerifyChatMsg(szMsg) == 1 then
			SendPrivateMessage(szReceiver, szMsg, 0, {});	
			Msg(string.format("��%s����%s", szReceiver, szCmd));		
			return true;
		end
		Log("AssistantChat", "VerifyChatMsg", szMsg);
	end
	
	Msg(string.format("��%s����%sʧ�ܣ����ֱ�����", szReceiver, szCmd));	
end