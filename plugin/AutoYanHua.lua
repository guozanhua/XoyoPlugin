
-- tbPlugin:SetDescription("", false);

function tbPlugin:Setup()	
--	assert(not self.fnOnChannelSystemMessage);
	
--	self.fnOnChannelSystemMessage = Ui.tbLogic.tbChatMgr.OnChannelSystemMessage;
--	Ui.tbLogic.tbChatMgr.OnChannelSystemMessage = self.OnChannelSystemMessage;
	
	return true;
end

function tbPlugin:Clear()
--	if self.fnSelectNpcOnButtonRClick then
--		Ui("selectnpc").OnButtonRClick = self.fnSelectNpcOnButtonRClick;
--		self.fnSelectNpcOnButtonRClick = nil;
--	end
end

function tbPlugin:OnChatMessage(szSender, szHead, szMsg)
	if szSender == "System" then
		local szNpcName, nMapID, nX, nY = string.match(szMsg, "^�����(%S*)�����̻�����ҿ��Ե�{pos=(%d+),(%d+),(%d+)}����ȡ�̻�");
		if szNpcName then
			print(szNpcName, nMapID, nX, nY);
		end		
	end
end
