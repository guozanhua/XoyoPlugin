Include("PluginBase");
Include("Queues");
SetDescription("����ԭʯ����", false);

local dwMoneyItemTemplateID = KItem.GetTemplateByKind("money_item"); -- ����ԭʯ
local tbHockshopSetting = GetShareTable("Hockshop_Setting");

function Setup() 	
	local tbAssistantHockshop = GetPlugin("AssistantHockshop");	
	if not tbAssistantHockshop.HockshopHasItem(dwMoneyItemTemplateID) then
		return;
	end
	
	tbExhangeStoneQueues = List.new();
	nExhangeStoneNilTime = 0;
	tbExchangeStone = {};
	
	RemoteZone.GetHockshopItemPrice(dwMoneyItemTemplateID, 0, 1, true);
	
	for dwTemplateId, _ in pairs(Player.tbExhangeStoneItem) do
		List.pushright(tbExhangeStoneQueues, dwTemplateId);			
	end	
	
	return true;
end

function Activate(nNow)	 		
	if not tbExhangeStoneQueues then
		nExhangeStoneNilTime = nExhangeStoneNilTime + 1;
		if nExhangeStoneNilTime > 5 then
			CalcExchangeStone();
			DisablePlugin();
		end
		return;
	end
	
	local tbAutoHockshop = GetPlugin("AutoHockshop");	
	for i = 1, 5 do		
		tbAutoHockshop.QueryRequest(tbExhangeStoneQueues, ExchangeStone_QueryRespond);
		
		if List.empty(tbExhangeStoneQueues) then
			tbExhangeStoneQueues = nil;
			break;
		end		
	end			
end

function CalcExchangeStone()
	local tbAssistantHockshop = GetPlugin("AssistantHockshop");	
	local tbSellItem, _ = tbAssistantHockshop.GetHockshopItemCache(dwMoneyItemTemplateID);
	if not tbSellItem then
		Msg("û�л���ԭʯ���ۼ۸�����");
		return;
	end
	
	local nSellPrice = tbSellItem.nPrice;	
	local tbItemList = {};
	
	for dwTemplateId, _ in pairs(Player.tbExhangeStoneItem) do	
		local _, tbItem = tbAssistantHockshop.GetHockshopItemCache(dwTemplateId);
		if tbItem and tbItem.Amount > 0 then
			local tbInfo = Player.tbExhangeStoneItem[tbItem.ID];	
			local tbBaseProp = KItem.GetItemBaseProp(tbItem.ID);	
			local nExchangeStoneCount = math.floor(tbBaseProp.nValue * tbInfo.ChangeRate / 100 / 10000);
			local nStoneBuyPrice = math.floor(tbItem.Price / nExchangeStoneCount);
			
			if nExchangeStoneCount > 0 and nSellPrice - nStoneBuyPrice > 5 then
				table.insert(tbItemList, {
					dwTemplateID = tbItem.ID, 
					nPrice = tbItem.Price;
					nAmount = tbItem.Amount, 
					nStoneBuyPrice = nStoneBuyPrice, 						
					nExchangeStoneCount = nExchangeStoneCount, 						
				});
			end
		end		
	end	
	
	table.sort(tbItemList, ExchangeStone_Sort);
	
	local tbLog = {};
	local nMaxBuyCount = tbHockshopSetting[dwMoneyItemTemplateID].DayPlayerMaxCount;	
	table.insert(tbLog, string.format("����ԭʯÿ���޹�<color=yellow>%d<color>��", nMaxBuyCount));
	
	for _, tbItem in pairs(tbItemList) do
		local tbBaseProp = KItem.GetItemBaseProp(tbItem.dwTemplateID);			
		table.insert(tbLog, string.format("<color=yellow>%s<color>�ɶһ�<color=yellow>%d<color>��������:<color=yellow>%d<color>���/��", tbBaseProp.szName, tbItem.nExchangeStoneCount, nSellPrice - tbItem.nStoneBuyPrice));	
	end
	UiManager:OpenWindow("stalllog", tbLog);	
end

function ExchangeStone_Sort(tbItem1, tbItem2)
	return tbItem1.nStoneBuyPrice < tbItem2.nStoneBuyPrice;
end