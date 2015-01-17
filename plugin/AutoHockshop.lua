Include("PluginBase");
Include("Queues");
SetDescription("�Զ���������", false);

local tbFavouriteItemNextBuy = GetShareTable("Hockshop_FavouriteItemNextBuy");
local tbEquipPosToItem = 
{
	[Item.EQUIPPOS_HEAD]			= 225;		-- ͷ
	[Item.EQUIPPOS_BODY]			= 3325;		-- �·�
	[Item.EQUIPPOS_BELT]			= 225;		-- ����
	[Item.EQUIPPOS_WEAPON]			= 0;		-- ����
	[Item.EQUIPPOS_FOOT]			= 225;		-- Ь��
	[Item.EQUIPPOS_CUFF]			= 225;		-- ����
	[Item.EQUIPPOS_AMULET]			= 199;		-- �����
	[Item.EQUIPPOS_RING]			= 199;		-- ��ָ
	[Item.EQUIPPOS_NECKLACE]		= 199;		-- ����
	[Item.EQUIPPOS_PENDANT]			= 199;		-- ����
};

local emItemType_Stone = 36;

function Setup() 	
	dwSilverItemTemplateID = KItem.GetTemplateByKind("silver_item");	
	nSilverItemLastBuyTime = 0;
	
	tbEnhanceExecute = {};
	tbHockshopEnhanceItems = {};
	for _, szName in pairs(Item.tbEnhanceTransItemOfPos) do
		for nEnhTimes = 1, Item.MAX_EQUIP_ENHANCE do
			local szKind = szName .. nEnhTimes;
			local dwItemTemplateID = KItem.GetTemplateByKind(szKind);			
			if dwItemTemplateID > 0 then
				tbHockshopEnhanceItems[szKind] = dwItemTemplateID;	
			end		
		end		
	end
	return true;
end

function Activate(nNow)		
	FavouriteItem_QueryRequest();		
	
	while true do	
		-- �⼸���Զ������ǻ����
		if HockshopEnhance_Sell(nNow) then			
			break;
		end
	
		if HockshopEnhance_Activate(nNow) then			
			break;
		end
		
		break;
	end
end

function QueryRequest(tbQueues, fnQueryRespond)	
	local tbItemIDList = {}; 
	local tbAssistantHockshop = GetPlugin("AssistantHockshop");
	while #tbItemIDList < 9 do 
		local dwTemplateId = List.popleft(tbQueues);
		if not dwTemplateId then
			break;
		end
		
		if tbAssistantHockshop.HockshopHasItem(dwTemplateId) then
			table.insert(tbItemIDList, dwTemplateId);
		end
	end	
	
	if #tbItemIDList > 0 then
		RemoteServer.QueryHockshopItem(tbItemIDList, fnQueryRespond);		
	end		
end

function FavouriteItem_QueryRespond(tbItemList)
	for nKey, tbItem in ipairs(tbItemList) do
		if tbItem.Amount > 0 and tbItem.Price <= me.nBindCoin then			
			FavouriteItem_Buy(tbItem.ID, nKey);		
		end		
	end	
end

function FavouriteItem_Buy(dwTemplateId, nKey)
	local nNow = GetTime();
	if tbFavouriteItemNextBuy[dwTemplateId] and tbFavouriteItemNextBuy[dwTemplateId] > nNow then	
		return;
	end
	
	local nItemCountInBag = me.GetItemCountInBags(dwTemplateId, -1); 
	
	local tbBaseProp = KItem.GetItemBaseProp(dwTemplateId);	
	if Item:IsEquip(tbBaseProp.nItemType) == 1 and nItemCountInBag < 1 then
		Log("AutoHockshop", "FavouriteItemBuy", tbBaseProp.szName);		
		RemoteServer.HockshopBuy(dwTemplateId, 1, nKey, false);
		tbFavouriteItemNextBuy[dwTemplateId] = nNow + 10;		
	elseif string.find(tbBaseProp.szName, "��ʯ��Ƭ��") ~= nil then
		Log("AutoHockshop", "FavouriteItemBuy", tbBaseProp.szName);		
		RemoteServer.HockshopBuy(dwTemplateId, 1, nKey, false);
	elseif string.find(tbBaseProp.szName, "ˮ��") ~= nil then
		Log("AutoHockshop", "FavouriteItemBuy", tbBaseProp.szName);		
		RemoteServer.HockshopBuy(dwTemplateId, 1, nKey, false);		
	else
		Log("AutoHockshop", "FavouriteItemBuy", "δ��������", tbBaseProp.szName, tbBaseProp.nItemType);		
	end	
end

function HockshopEnhance_Activate(nNow)	
	local tbAssistantHockshop = GetPlugin("AssistantHockshop");		
	if dwSilverItemTemplateID == 0 or not tbAssistantHockshop.HockshopHasItem(dwSilverItemTemplateID) then
		Log("��������û���ϼ�����, �Զ�ǿ����Ч");
		return;			
	end
	
	nHockshopEnhanceNextQuery = nHockshopEnhanceNextQuery or 0;
	if nNow > nHockshopEnhanceNextQuery then
		RemoteServer.QueryHockshopItem({dwSilverItemTemplateID}, true);
	
		for szKind, dwItemTemplateID in pairs(tbHockshopEnhanceItems) do
			if tbAssistantHockshop.HockshopHasItem(dwItemTemplateID) then
				RemoteZone.GetHockshopItemPrice(dwItemTemplateID, 0, 1, true);		
			end			
		end
		
		nHockshopEnhanceNextQuery = nNow + 60 * 10;
		return;
	end

	nHockshopEnhanceNextCalc = nHockshopEnhanceNextCalc or 0;
	if nNow > nHockshopEnhanceNextCalc then	
		local _, tbBuyItem = tbAssistantHockshop.GetHockshopItemCache(dwSilverItemTemplateID);
		if not tbBuyItem then
			Log("û�а�������۸�");
			return;
		end

		local tbSilverItem = KItem.GetItemBaseProp(dwSilverItemTemplateID);
		
		local bAllSucess = true;
		for szKind, dwItemTemplateID in pairs(tbHockshopEnhanceItems) do			
			if not CalcHockshopEnhance(szKind, dwItemTemplateID, tbBuyItem.Price, tbSilverItem.nPrice) then
				bAllSucess = false;
				Log("����ǿ����ʽʧ�ܣ��Ժ�����", szKind);
				return;
			end
		end	
		
		nHockshopEnhanceNextCalc = nNow + 60;
	end

	
	EnhanceItem_Execute();
	
	local szSelectKind, tbSelectEnhance = SelectEnhanceItem();	
	return szSelectKind ~= nil;
end

function CalcHockshopEnhance(szKind, dwItemTemplateID, nSilverItemPrice, nSilverItemValue)
	local nLastProfit = 0;
	if tbEnhanceExecute[szKind] and tbEnhanceExecute[szKind].nProfit then
		nLastProfit = tbEnhanceExecute[szKind].nProfit;
	end
	
	tbEnhanceExecute[szKind] = nil;
	
	local tbAssistantHockshop = GetPlugin("AssistantHockshop");	
	if not tbAssistantHockshop.HockshopHasItem(dwItemTemplateID) then
		return true;
	end
	
	local tbSellItem, _ = tbAssistantHockshop.GetHockshopItemCache(dwItemTemplateID);
	if not tbSellItem then
		return;
	end
	
	local nItemEquipPos, nItemEnhTimes = ParseEnhanceItemKind(szKind);
	if not nItemEquipPos then
		return;
	end
			
	local nCostPrice = 0;
	local nCostMoney = 0;
	local tbItem = KItem.GetItemBaseProp(dwItemTemplateID); 
	local tbTotalEnhance = {};	
	local nEnhanceOfEquipPos = Item.tbEnhanceOfEquipPos[nItemEquipPos]; 
	
	for i = 1, nItemEnhTimes do
		local nSrcValue = Item.tbEnhance.m_tbEnhanceValue[i] * nEnhanceOfEquipPos;
		local tbEnhanceCount, nMoney, nPrice, nWasteValue = tbAssistantHockshop.CalcEnhance(nSrcValue, 16, true);
		if not tbEnhanceCount then
			return true;
		end
		
		nCostPrice = nCostPrice + nPrice;
		nCostMoney = nCostMoney + nMoney;	
		tbTotalEnhance[i] = tbEnhanceCount;
	end
	
	local nCostMoneyPrice = nCostMoney * nSilverItemPrice / nSilverItemValue;	
	local nProfit = tbSellItem.nPrice - nCostPrice - nCostMoneyPrice;
	
	if math.abs(nProfit - nLastProfit) > 0.01 then
		Log(tbItem.szName, "����:", nCostPrice, string.format("����:%d�ϰ��:%d", nCostMoney, nCostMoneyPrice), "�ۼ�:", tbSellItem.nPrice, "����:", nProfit, (nProfit > 5 and "��" or ""));
	end
			
	tbEnhanceExecute[szKind] = {
		dwItemTemplateID = dwItemTemplateID;
	    tbEnhance = tbTotalEnhance;
	    nCostPrice = nCostPrice;
	    nCostMoney = nCostMoney;
	    nCostMoneyPrice = nCostMoneyPrice;
		nProfit = nProfit;	
	};
	return true;
end

function EnhanceItem_Execute()
	local szSelectKind, tbSelectEnhance = SelectEnhanceItem();	
	if not szSelectKind then
		return;
	end
	
	if not CheckBindMoney(tbSelectEnhance.nCostMoney) then
		return;
	end
	
	local nSellItemsCount = me.GetItemCountInBags(tbSelectEnhance.dwItemTemplateID, 1);
	if nSellItemsCount > 0 then		
		RemoteServer.HockshopSell(tbSelectEnhance.dwItemTemplateID, 1, nSellItemsCount, false, true);
		return;
	end
		
	local nItemEquipPos, nItemEnhTimes = ParseEnhanceItemKind(szSelectKind);
	local dwEquipItemTemplateID = tbEquipPosToItem[nItemEquipPos];
	if dwEquipItemTemplateID == 0 then
		Log("û������ǿ������", szSelectKind);
		return;
	end
	
	local tbEquipItems = me.FindItemInBags(dwEquipItemTemplateID); 		
	local pEquipItem = tbEquipItems[1].pItem;	
	if pEquipItem.nEnhTimes >= #tbSelectEnhance.tbEnhance then		
		me.CallServerScript("ItemCmd", "EquipOperation", "tbUnEnhance", pEquipItem.dwId) -- ǿ������ 
		return;
	end
	
	if not CheckEnhanceItem(tbSelectEnhance.tbEnhance[pEquipItem.nEnhTimes + 1]) then
		return;
	end
		
	local tbEnhanceItems = {};
	for szItemKind, nCount in pairs(tbSelectEnhance.tbEnhance[pEquipItem.nEnhTimes + 1]) do
		local dwItemTemplateID = KItem.GetTemplateByKind(szItemKind);
		local tbEnhanceItemsInBag = me.FindItemInBags(dwItemTemplateID);		
		local nLeftCount = nCount;
		
		for _, tbItem in pairs(tbEnhanceItemsInBag) do
			if nLeftCount == 0 then
				break;
			end
			
			if tbItem.pItem.IsBind() == 1 then
				table.insert(tbEnhanceItems, tbItem.pItem.dwId);
				nLeftCount = nLeftCount - 1;
			end
		end
	end

	me.CallServerScript("ItemCmd", "EquipOperation", "tbEnhance", pEquipItem.dwId, tbEnhanceItems, 1, 10000);
end

function ParseEnhanceItemKind(szKind)
	for nEquipPos, szName in pairs(Item.tbEnhanceTransItemOfPos) do
		local _, _, szEnhTimes = string.find(szKind, szName .."(%d+)");
		if szEnhTimes then
			return nEquipPos, tonumber(szEnhTimes);
		end
	end	
end

function SelectEnhanceItem()
	local tbAssistantHockshop = GetPlugin("AssistantHockshop");		
	local szSelectKind;
	local tbSelectEnhance;
	for szKind, tbEnhance in pairs(tbEnhanceExecute) do
		if tbEnhance.nProfit >= 5 and SupportEnhance(szKind) and tbAssistantHockshop.CanSellItem(tbEnhance.dwItemTemplateID) then
			szSelectKind = szSelectKind or szKind;
			tbSelectEnhance = tbSelectEnhance or tbEnhance;
			
			if tbSelectEnhance.nProfit < tbEnhance.nProfit then
				szSelectKind = szKind;		
				tbSelectEnhance = tbEnhance;		
			end
		end
	end	
	
	return szSelectKind, tbSelectEnhance;
end

function CheckBindMoney(nCostMoney) 
	if me.GetBindMoney() == 0 then
		Msg("���ͬ���У����Ժ󡣡���");
		return;
	end
	
	if me.GetBindMoney() > nCostMoney then
		return true;
	end
	
	local nSilverItemCount = me.GetItemCountInBags(dwSilverItemTemplateID, -1);
	local nNow = GetTime();
	if nSilverItemCount < 20 and nNow - nSilverItemLastBuyTime > 5 then		
		RemoteServer.HockshopBuy(dwSilverItemTemplateID, 1, 1, false);
		nSilverItemLastBuyTime = nNow;
	else
		Msg("���ٶȴ��������Լ���������");
	end	
end

function CheckEnhanceItem(tbEnhance) -- ��鲢����ˮ��
	local tbAssistant = GetPlugin("Assistant");		
	local tbNeedBuyItem = {};
	local nTotalCount = 0;
	
	for szItemKind, nCount in pairs(tbEnhance) do
		local dwItemTemplateID = KItem.GetTemplateByKind(szItemKind);
		local nItemCount = me.GetItemCountInBags(dwItemTemplateID, 1);
		if nItemCount < nCount then
			table.insert(tbNeedBuyItem, {dwItemTemplateID = dwItemTemplateID, nCount = nCount - nItemCount, });
			nTotalCount = nTotalCount + nCount - nItemCount;
		end
	end 
	
	if not tbAssistant.KeepBagRetainCell(nTotalCount + 2) then -- ��ֹͻȻʰȡ�˵���ʲô��
		Msg("��������" .. nTotalCount);
		return;
	end
	
	for _, tbItem in pairs(tbNeedBuyItem) do
		RemoteServer.HockshopBuy(tbItem.dwItemTemplateID, tbItem.nCount, 1, false);
	end
		
	if nTotalCount > 0 then
		return;
	end
	
	return true;
end

function SupportEnhance(szKind)
	local nItemEquipPos, nItemEnhTimes = ParseEnhanceItemKind(szKind);
	
	local dwItemTemplateID = tbEquipPosToItem[nItemEquipPos];
	if dwItemTemplateID == 0 then
		Log("�в�֧�ֵĺϳ�����", szKind);		
		return;
	end	
		
	local tbEquipItems = me.FindItemInBags(dwItemTemplateID); 	
	if #tbEquipItems == 0 then
		Log("û��ǿ������", dwEquipItemTemplateID);		
		return;	
	end
	
	if nItemEnhTimes > tbEquipItems[1].pItem.nMaxEnhance then
		Log(szKind, "���õĵ����޷�ǿ����", nItemEnhTimes);		
		Msg(szKind .. "���õĵ����޷�ǿ����" .. nItemEnhTimes);
		return;		
	end
	
	return true;
end

function FavouriteItem_QueryRequest()	
	if not tbFavouriteQueues then		
		local tbFavouriteItem = Ui.tbLogic.tbSaveData:Load("HockshopFavourite");
		tbFavouriteQueues = List.new();		
		
		for _, dwTemplateId in pairs(tbFavouriteItem) do			
			List.pushright(tbFavouriteQueues, dwTemplateId);			
		end
	end
	
	QueryRequest(tbFavouriteQueues, FavouriteItem_QueryRespond);
	
	if List.empty(tbFavouriteQueues) then
		tbFavouriteQueues = nil;
	end
end

function HockshopEnhance_Sell(nNow)	
	local tbAssistantHockshop = GetPlugin("AssistantHockshop");		
	if dwSilverItemTemplateID == 0 or not tbAssistantHockshop.HockshopHasItem(dwSilverItemTemplateID) then
		Log("��������û���ϼ�����, �Զ�ˮ����������Ч");
		return;			
	end
	
	nHockshopEnhanceSellNextQuery = nHockshopEnhanceSellNextQuery or 0;
	if nNow > nHockshopEnhanceSellNextQuery then
		RemoteZone.GetHockshopItemPrice(dwSilverItemTemplateID, 0, 1, true);	
		
		local tbQueryHockshopItem = {};
		for i = 1, 20 do
			local szItemKind = "EnhanceItem_Lv" ..  i;
			local dwItemTemplateID = KItem.GetTemplateByKind(szItemKind);
			if dwItemTemplateID == 0 or not tbAssistantHockshop.HockshopHasItem(dwItemTemplateID) then
				break;			
			end
			
			if #tbQueryHockshopItem > 0 then
				table.insert(tbQueryHockshopItem, dwItemTemplateID);	
			end
		end		
		RemoteServer.QueryHockshopItem(tbQueryHockshopItem, true);
		
		nHockshopEnhanceSellNextQuery = nNow + 60 * 10;
		return;
	end
	
	local tbSellSilverItem, _ = tbAssistantHockshop.GetHockshopItemCache(dwSilverItemTemplateID);
	if not tbSellSilverItem then
		Log("�����ĳ��ۼ۸�δͬ�����");
		return;
	end
	
	local tbSilverItem = KItem.GetItemBaseProp(dwSilverItemTemplateID);
	local nCanSellItemTypeCount = 0;
	local tbQueryHockshopItem = {};
	
	for i = 1, 20 do
		local szItemKind = "EnhanceItem_Lv" ..  i;
		local dwItemTemplateID = KItem.GetTemplateByKind(szItemKind);
		if dwItemTemplateID == 0 then
			break;			
		end
		
		local tbItem = KItem.GetItemBaseProp(dwItemTemplateID);
		local _, tbBuyItem = tbAssistantHockshop.GetHockshopItemCache(dwItemTemplateID);
		if tbBuyItem and tbItem.bSellable == 1 then			
				-- �ɱ���	 = �����������۸�      / ˮ���ĳ��ۼ۸�      * ˮ���ĵ���
			local nCostPrice = tbSilverItem.nPrice / (tbItem.nPrice / 2) * tbBuyItem.Price;
			
			if tbSellSilverItem.nPrice - nCostPrice > 5 then				
				local fnSell = function (pItem, eItemType) 
					if pItem.dwTemplateId == dwItemTemplateID then
						RemoteServer.NpcShopSell(pItem.dwId, pItem.nCount, 1);		
					end
				end
				TraverseItem(fnSell);
				
				local nBagCount = me.CountFreeBagCell() - 2; -- Ԥ���������ӵı���				
				local nCanBuyCount = math.floor(me.nBindCoin / tbBuyItem.Price)
				local nBuyCount = math.min(nBagCount, nCanBuyCount);				
				nBuyCount = math.min(nBuyCount, tbBuyItem.Amount);	
				
				table.insert(tbQueryHockshopItem, dwItemTemplateID);
				
				if nBuyCount > 0 then
					RemoteServer.HockshopBuy(dwItemTemplateID, nBuyCount, 1, false);					
					break;
				end										
			end 
		end
	end	
	
	if #tbQueryHockshopItem > 0 then
		RemoteServer.QueryHockshopItem(tbQueryHockshopItem, true); -- ������ѯ
	end	
end