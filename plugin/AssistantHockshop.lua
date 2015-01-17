Include("PluginBase");
Include("Queues");
SetDescription("交易中心助手", true);

local tbUiHockShopFile = Import("ui/script/window/hockshop.lua");
local tbItemSellPriceCache = GetShareTable("Hockshop_ItemSellPriceCache");
local tbItemBuyPriceCache = GetShareTable("Hockshop_ItemBuyPriceCache");
local tbItemSellFailedCache = GetShareTable("Hockshop_ItemSellFailedCache");
local tbHockshopSetting = GetShareTable("Hockshop_Setting");
local tbHockshopSellItem = {
	-- 藏宝图
	"treasuremap_Q1_hide", "treasuremap_Q2_hide", "treasuremap_Q3_hide", "treasuremap_Q4_hide", 
	-- 生活技能材料
	"kuangding_1", "kuangding_2", "kuangding_3", "kuangding_4", -- "kuangding_5", "kuangding_6", "kuangding_7", "kuangding_8", 
	"mucai_1", "mucai_2", "mucai_3", "mucai_4", -- "mucai_5", "mucai_6", "mucai_7", "mucai_8", 
	"buliao_1", "buliao_2", "buliao_3", "buliao_4", -- "buliao_5", "buliao_6", "buliao_7", "buliao_8",
	"maopi_1", "maopi_2", "maopi_3", "maopi_4", -- "maopi_5", "maopi_6", "maopi_7", "maopi_8", 
	"baoshi_1", "baoshi_2", "baoshi_3", "baoshi_4", -- "baoshi_5", "baoshi_6", "baoshi_7", "baoshi_8", 
	"yushi_1", "yushi_2", "yushi_3", "yushi_4", -- "yushi_5", "yushi_6", "yushi_7", "yushi_8", 
	"yaocai_1", "yaocai_2", "yaocai_3", "yaocai_4", -- "yaocai_5", "yaocai_6", "yaocai_7", "yaocai_8", 
	-- 水晶
	--"EnhanceItem_Lv1", "EnhanceItem_Lv2", -- "EnhanceItem_Lv3","EnhanceItem_Lv4","EnhanceItem_Lv5","EnhanceItem_Lv2","EnhanceItem_Lv6","EnhanceItem_Lv7",	
	-- 混沌原石
	"money_item",
};

function Setup() 
	tbOrderHockshopSell = List.new();
	DetourAttach(RemoteServer, "HockshopSell", OrderHockshopSell);
	DetourAttach(tbUiHockShopFile, "SellItemRespond", OrderSellItemRespond);
	
	tbOrderQueryHockshopItem = List.new();
	DetourAttach(RemoteServer, "QueryHockshopItem", OrderQueryHockshopItem);
	DetourAttach(tbUiHockShopFile, "SyncHockshopItem", OrderSyncHockshopItem);
	
	tbOrderHockshopItemPrice = List.new();
	DetourAttach(RemoteZone, "GetHockshopItemPrice", OrderGetHockshopItemPrice);
	DetourAttach(tbUiHockShopFile, "UpdateSellItem", OrderUpdateSellItem);	
	
	DetourAttach(Item, "Tip_Suffix", ItemTipSuffix);
	DetourAttach(Ui("enhance"), "UpdateEnhance", EnhanceUI_UpdateEnhance);	
	DetourAttach(Ui("enhance"), "UpdateTransfer", EnhanceUI_UpdateTransfer);		
	
	local tbSetting = LoadTabFile("setting/hockshop.tab", "ddsd", "ItemID", {"ItemID", "DayPlayerMaxCount", "TimeEvent", "Price", });
	for _, v in pairs(tbSetting) do
		tbHockshopSetting[v.ItemID] = v;
	end
		
	return true;
end

function Clear() 	
	DetourDetach(Ui("enhance"), "UpdateTransfer");		
	DetourDetach(Ui("enhance"), "UpdateEnhance");		
	DetourDetach(Item, "Tip_Suffix")
	
	DetourDetach(tbUiHockShopFile, "UpdateSellItem");
	DetourDetach(RemoteZone, "GetHockshopItemPrice");
	
	DetourDetach(tbUiHockShopFile, "SyncHockshopItem");
	DetourDetach(RemoteServer, "QueryHockshopItem");
	
	DetourDetach(tbUiHockShopFile, "SellItemRespond");
	DetourDetach(RemoteServer, "HockshopSell");
end

function Activate(nNow)
	local nSecond = Lib:GetLocalDayTime(nNow);
	
	if nSecond < 2 * 60 or nSecond > (23 * 3600 + 59 * 60) then 
		HockshopAutoSell();
	end	
	
	if nSecond < 2 or nSecond > (23 * 3600 + 59 * 60 + 58) then 
		ClearShareTable("Hockshop_ItemSellPriceCache");
		tbItemSellPriceCache = GetShareTable("Hockshop_ItemSellPriceCache");
		
		ClearShareTable("Hockshop_ItemBuyPriceCache");
		tbItemBuyPriceCache = GetShareTable("Hockshop_ItemBuyPriceCache");
		
		ClearShareTable("Hockshop_ItemSellFailedCache");
		tbItemSellFailedCache = GetShareTable("Hockshop_ItemSellFailedCache");
	end	
end

function OnShowDialog(tbDlgInfo)		
	if not string.find(tbDlgInfo.Text, "<color=green>您可以选择获得以下这些道具中的一个：<color>\n") then
		return;
	end
	
	local tbItemTemplateId = {};
	for dwTemplateId in string.gmatch(tbDlgInfo.Text, "%d+") do
		local tbSellItem, tbBuyItem = GetHockshopItemCache(dwTemplateId);	
		if not tbSellItem then
			RemoteZone.GetHockshopItemPrice(dwTemplateId, 0, 1, true);
			table.insert(tbItemTemplateId, dwTemplateId);
		end
	end	
	RemoteServer.QueryHockshopItem(tbItemTemplateId, true);	
end

function HockshopAutoSell()
	local tbItemCount = {};
	for _, dwItemTemplateID in pairs(tbHockshopSellItem) do
		if type(dwItemTemplateID) == "string" then
			dwItemTemplateID = KItem.GetTemplateByKind(dwItemTemplateID);
		end
		tbItemCount[dwItemTemplateID] = 0;
	end
	
	local fnCountInBag = function(pItem, eItemType)				
		if eItemType ~= Item.BAG_ROOM or pItem.IsBind() ~= 1 then
			return;
		end
		
		local nCount = tbItemCount[pItem.dwTemplateId];
		if nCount then
			tbItemCount[pItem.dwTemplateId] = nCount + pItem.nCount;			
		end		
	end
	
	TraverseItem(fnCountInBag);
	
	for dwItemTemplateID, nCount in pairs(tbItemCount) do
		if nCount > 0 then
			RemoteServer.HockshopSell(dwItemTemplateID, 1, nCount, false, true);
		end
	end
end

function OrderHockshopSell(dwItemID, nBind, nCount, bOnlySellCoin, fnCallback)
	if not me.CanOpenHockshop() then
		return;
	end		

	DetourCallOld(RemoteServer, "HockshopSell", dwItemID, nBind, nCount, bOnlySellCoin);
	
	local tbSellItem = 
	{
		dwItemID = dwItemID,
		nBind = nBind,
		nCount = nCount,
		fnCallback = fnCallback,
	}
	List.pushright(tbOrderHockshopSell, tbSellItem);
end

function AddSellFailedCache(dwItemID)
	tbItemSellFailedCache[dwItemID] = true;		
end

function CanSellItem(dwItemID)
	return not tbItemSellFailedCache[dwItemID];
end

function OrderSellItemRespond(dwItemID, nBind, nSellCount, nOrgCount, nSellMoney, bSellBind, szSellCode)
	if szSellCode == "TODAY_SELL_FULL" then -- 当日玩家限额已满,会导致队列顺序错乱
		AddSellFailedCache(dwItemID);
		if UiManager:WindowVisible("hockshop") == 1 then
			DetourCallOld(tbUiHockShopFile, "SellItemRespond", dwItemID, nBind, nSellCount, nOrgCount, nSellMoney, bSellBind, szSellCode);
		end
		return;
	elseif szSellCode == "SELL_FULL" then
		AddSellFailedCache(dwItemID);
	end
		
	while true do
		local tbSellItem = List.popleft(tbOrderHockshopSell);
		if not tbSellItem then
			break;
		end
				
		if tbSellItem.dwItemID == dwItemID and tbSellItem.nBind == nBind and tbSellItem.nCount >= nOrgCount then
			if not tbSellItem.fnCallback then
				break;
			end
			
			if nSellMoney > 0 then
				local tbBaseProp = KItem.GetItemBaseProp(dwItemID);	
				Log("AssistantHockshop", string.format("出售%s(%d个)获得绑金%d(总绑金%d)", 
					tbBaseProp.szName, nSellCount, nSellMoney, me.nBindCoin));
			end
						
			if type(tbSellItem.fnCallback) == "function" then
				tbSellItem.fnCallback(dwItemID, nBind, nSellCount, nOrgCount, nSellMoney, bSellBind, szSellCode);
			end
			return;
		end
	end

	DetourCallOld(tbUiHockShopFile, "SellItemRespond", dwItemID, nBind, nSellCount, nOrgCount, nSellMoney, bSellBind, szSellCode);
end

function OrderQueryHockshopItem(tbItemIDList, fnCallback)
	if not me.CanOpenHockshop() then
		return;
	end		
	DetourCallOld(RemoteServer, "QueryHockshopItem", tbItemIDList);
	
	local tbQueryItem = 
	{
		tbItemIDList = tbItemIDList,
		fnCallback = fnCallback,
	}
	List.pushright(tbOrderQueryHockshopItem, tbQueryItem);
end

function OrderSyncHockshopItem(tbItemList)
	ItemBuyPriceCache(tbItemList);
	
	while true do
		local tbQueryItem = List.popleft(tbOrderQueryHockshopItem);
		if not tbQueryItem then
			break;
		end

		if #tbQueryItem.tbItemIDList == #tbItemList then
			local bDifferentFlag = false;
			for i = 1, #tbItemList do
				if tbQueryItem.tbItemIDList[i] ~= tbItemList[i].ID then
					bDifferentFlag = true;
					break;
				end
			end
			
			if not bDifferentFlag then
				if not tbQueryItem.fnCallback then
					break;
				end
				
				if type(tbQueryItem.fnCallback) == "function" then
					tbQueryItem.fnCallback(tbItemList);
				end
				return;
			end
		end
	end

	DetourCallOld(tbUiHockShopFile, "SyncHockshopItem", tbItemList);
end
	
function OrderGetHockshopItemPrice(dwItemID, nBind, nCount, fnCallback)
	if not me.CanOpenHockshop() then
		return;
	end
	
	DetourCallOld(RemoteZone, "GetHockshopItemPrice", dwItemID, nBind, nCount);
	
	local tbItem = 
	{
		dwItemID = dwItemID,
		nBind = nBind,
		nCount = nCount,
		fnCallback = fnCallback,
	}
	List.pushright(tbOrderHockshopItemPrice, tbItem);
end

function OrderUpdateSellItem(dwItemID, nBind, nCount, nPrice, nAddPrice, bPrepay)
	ItemSellPriceCache(dwItemID, nBind, nCount, nPrice, nAddPrice, bPrepay);
	
	while true do
		local tbItem = List.popleft(tbOrderHockshopItemPrice);
		if not tbItem then
			break;
		end
		
		if tbItem.dwItemID == dwItemID and tbItem.nBind == nBind and tbItem.nCount == nCount then			
			if not tbItem.fnCallback then
				break;
			end
			
			if type(tbItem.fnCallback) == "function" then
				tbItem.fnCallback(dwItemID, nBind, nCount, nPrice, nAddPrice, bPrepay);
			end			
			return;
		end
	end

	DetourCallOld(tbUiHockShopFile, "UpdateSellItem", dwItemID, nBind, nCount, nPrice, nAddPrice, bPrepay);
end

-- 通用缓存
function ItemBuyPriceCache(tbItemList)
	-- {ID = v, Price = nPrice, Amount = hockitem.nCount, IsPrepay = bIsPrepay}

	for _, tbItem in ipairs(tbItemList) do
		tbItemBuyPriceCache[tbItem.ID] = tbItem;
	end
end

function HockshopHasItem(dwItemTemplateId)
	local tbItemInfo = tbHockshopSetting[dwItemTemplateId];
	if not tbItemInfo then
		return;
	end
	
	return GetTime() > CalcTimeFrameOpenTime(tbItemInfo.TimeEvent);
end

function GetHockshopItemCache(dwItemTemplateId)
	local tbSellItem = tbItemSellPriceCache[dwItemTemplateId];
	local tbBuyItem = tbItemBuyPriceCache[dwItemTemplateId];
	
	return tbSellItem, tbBuyItem;
end

function ItemTipSuffix(tbSelf, nState, szSuffix, szBindType)
	local szTip = DetourCallOld(Item, "Tip_Suffix", tbSelf, nState, szSuffix, szBindType);	
		
	local tbSellItem, tbBuyItem = GetHockshopItemCache(it.dwTemplateId);	
	if Ui("hockshop"):CanSellHockshop(it) then
		RemoteZone.GetHockshopItemPrice(it.dwTemplateId, 0, 1, true);
		if not tbBuyItem then
			RemoteServer.QueryHockshopItem({it.dwTemplateId}, true);
		end
	end
	
	if not tbSellItem then
		return szTip;
	end
	
	local szCoin = "绑金";
	if it.IsBind() ~= 1 and tbSellItem.bPrepay then
		szCoin = "金币";
	end
	
	szTip = string.format("%s\n<color=green_01><color=orange_01>交易中心<color> %s", szTip, os.date("%H:%M:%S", tbSellItem.nUpdateTime));
	szTip = string.format("%s\n└出售:<color=yellow>%d%s<color>", szTip, tbSellItem.nPrice, szCoin);
	if tbSellItem.nAddPrice > 0 then
		szTip = string.format("%s <color=yellow>(+%d)<color>", szTip, tbSellItem.nAddPrice);
	end
	
	if tbSellItem.bPrepay then
		szTip = string.format("%s <color=pink>预购中<color>", szTip);
	end
	
	if tbBuyItem then
		szTip = string.format("%s\n└购买:<color=yellow>%d绑金<color> 库存:<color=yellow>%d<color>", szTip, tbBuyItem.Price, tbBuyItem.Amount);
	end
		
	szTip = string.format("%s<color>", szTip);
	return szTip;
end

function ItemSellPriceCache(dwItemID, nBind, nCount, nPrice, nAddPrice, bPrepay)
	tbItemSellPriceCache[dwItemID] = 
	{	
		nCount = nCount, 
		nBind = nBind, 
		nPrice = nPrice, 
		nAddPrice = nAddPrice, 
		bPrepay = bPrepay, 
		nUpdateTime = GetTime(),
	};
end

function EnhanceUI_UpdateEnhance(tbSelf)
	local bRet, szMsg = DetourCallOld(Ui("enhance"), "UpdateEnhance", tbSelf);	
	local tbItems = tbSelf:GetItemInfo()
	if not tbItems or not tbItems[1] then
		return bRet, szMsg;
	end
	
	local tbItem = tbItems[1][1];
	if not tbItem then
		return bRet, szMsg;
	end
	
	local nSrcValue = Item.tbEnhance.m_tbEnhanceValue[tbItem.nEnhTimes + 1] * Item.tbEnhanceOfEquipPos[tbItem.nEquipPos]; 
	local tbEnhanceCount, nMoney, nTotolPrice, nWasteValue = CalcEnhance(nSrcValue, 16, true);
	if not tbEnhanceCount then
		tbEnhanceCount, nMoney, nTotolPrice, nWasteValue = CalcEnhance(nSrcValue, 16);
	end
	
	if not tbEnhanceCount then
		return bRet, szMsg;
	end 
	
	szMsg = szMsg .. "\n";
	for szItemKind, nCount in pairs(tbEnhanceCount) do
		local dwItemTemplateID = KItem.GetTemplateByKind(szItemKind);
		local tbItem = KItem.GetItemBaseProp(dwItemTemplateID);
		if nCount > 0 then
			szMsg = string.format("%s<color=yellow>%s:%d个;<color> ", szMsg, tbItem.szName, nCount);
		end
	end
	
	if nTotolPrice ~= 0 then
		szMsg = string.format("%s\n水晶折合绑金:%d", szMsg, nTotolPrice);
	end	
	
	if nWasteValue ~= 0 then
		szMsg = string.format("%s 浪费价值量:%d", szMsg, nWasteValue);
	end

	return bRet, szMsg;
end

function EnhanceUI_UpdateTransfer(tbSelf)
	local bRet, szMsg = DetourCallOld(Ui("enhance"), "UpdateTransfer", tbSelf);	
	local tbItems = tbSelf:GetItemInfo()	
	if not tbItems or #tbItems[1] < 2 then
		return bRet, szMsg;
	end
	
	local pSourceEquip = tbItems[1][1];
	local pTagetEquip = tbItems[1][2];	
	local nEnhTimes = Item.tbTransfer:GetSourceEnhanceTimes(pSourceEquip, pTagetEquip);
	local nSourceValue = Item:GetEnhanceValue(pTagetEquip.nEquipPos, nEnhTimes);	
	local nTargetValue = nSourceValue - pTagetEquip.GetEnhanceValue();
	local nMoney = nTargetValue * 0.04;
	local nNeedValue = nTargetValue - nSourceValue * 0.9; 
	
	local tbEnhanceCount, nMoney, nTotolPrice, nWasteValue = CalcEnhance(nNeedValue, 12, true);
	if not tbEnhanceCount then
		tbEnhanceCount, nMoney, nTotolPrice, nWasteValue = CalcEnhance(nNeedValue, 12);
	end
	
	if not tbEnhanceCount then
		return bRet, szMsg;
	end 
	
	szMsg = szMsg .. "\n";
	for szItemKind, nCount in pairs(tbEnhanceCount) do
		local dwItemTemplateID = KItem.GetTemplateByKind(szItemKind);
		local tbItem = KItem.GetItemBaseProp(dwItemTemplateID);
		if nCount > 0 then
			szMsg = string.format("%s<color=yellow>%s:%d个;<color> ", szMsg, tbItem.szName, nCount);
		end
	end
	
	if nTotolPrice ~= 0 then
		szMsg = string.format("%s\n水晶折合绑金:%d", szMsg, nTotolPrice);
	end	
	
	if nWasteValue ~= 0 then
		szMsg = string.format("%s 浪费价值量:%d", szMsg, nWasteValue);
	end

	return bRet, szMsg;
end

function CalcEnhance(nSrcValue, nSpace, bCheckExist)	
	local nMoney = nSrcValue * 0.06;
	local tbQueryHockshopItem = {};
	local tbValue = {};
	local tbPrice = {};	
	
	for i = 1, 20 do
		local szItemKind = "EnhanceItem_Lv" ..  i;
		local dwItemTemplateID = KItem.GetTemplateByKind(szItemKind);
		if dwItemTemplateID == 0 or not HockshopHasItem(dwItemTemplateID) then
			break;			
		end
		
		table.insert(tbQueryHockshopItem, dwItemTemplateID);
		
		local _, tbBuyItem = GetHockshopItemCache(dwItemTemplateID);		
		if tbBuyItem then	
			if not bCheckExist or tbBuyItem.Amount > 0 or me.GetItemCountInBags(dwItemTemplateID, 1) > 0 then	
				local tbItem = KItem.GetItemBaseProp(dwItemTemplateID);
				
				tbValue[i] = tbItem.nValue;		
				tbPrice[i] = tbBuyItem.Price;
			end
		end 		
	end	
	
	RemoteServer.QueryHockshopItem(tbQueryHockshopItem, true);
	
	local nItemCount = #tbValue;
	if nItemCount == 0 then
		Msg("水晶价格为空或者不连续，水晶购买价格同步中或者缺货");
		return nil, nMoney;
	end
	
	for i = 1, nItemCount do
		if not tbPrice[i] or not tbValue[i] then
			Msg("水晶价格不连续，价格同步中或者缺货");
			return nil, nMoney;
		end
	end
					
	local nNeedValue = nSrcValue;
	local tbRetDis = {};
	local tbRetPath = {};	

	local nTotolPrice = CalcValue(nSrcValue, nSpace, tbValue, tbPrice, tbRetDis, tbRetPath);	
	if nTotolPrice == math.huge then		
		return nil, nMoney;
	end
	
	local tbResult = {};
	local nTotalValue = 0;
	while nNeedValue > 0 do
		local nIndex = tbRetPath[nNeedValue][nSpace];
		nNeedValue = nNeedValue - tbValue[nIndex];
		nSpace = nSpace - 1;
		nTotalValue = nTotalValue + tbValue[nIndex];
		local szItemKind = "EnhanceItem_Lv" ..  nIndex;
		tbResult[szItemKind] = (tbResult[szItemKind] or 0) + 1;
	end	
	
	return tbResult, nMoney, nTotolPrice, nTotalValue - nSrcValue;
end

function CalcValue(nNeedValue, nSpace, tbValue, tbPrice, tbRetDis, tbRetPath)
	assert(#tbValue == #tbPrice);
	
	if nSpace < 0 then
		return math.huge;
	end
	
	if nNeedValue <= 0 then
		return 0;
	end	
			
	tbRetDis[nNeedValue] = tbRetDis[nNeedValue] or {};
	
	local nCurPrice = tbRetDis[nNeedValue][nSpace];		
	if nCurPrice then
		return nCurPrice;
	end
	
	nCurPrice = math.huge;
	tbRetDis[nNeedValue][nSpace] = nCurPrice;
	
	for i = 1, #tbPrice do
		local nRetPrice = CalcValue(nNeedValue - tbValue[i], nSpace - 1, tbValue, tbPrice, tbRetDis, tbRetPath);
		if nCurPrice > nRetPrice + tbPrice[i] then
			nCurPrice = nRetPrice + tbPrice[i];
			tbRetDis[nNeedValue][nSpace] = nCurPrice;
			
			tbRetPath[nNeedValue] = tbRetPath[nNeedValue] or {};
			tbRetPath[nNeedValue][nSpace] = i;
		end
	end

	return nCurPrice;
end
