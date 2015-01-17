Include("PluginBase");
SetDescription("Õ—“¬÷˙ ÷", false);

function Activate(nNow)	
	TakeOffEquipment(Item.EQUIPPOS_HEAD);
	TakeOffEquipment(Item.EQUIPPOS_BODY);
	TakeOffEquipment(Item.EQUIPPOS_BELT);
	TakeOffEquipment(Item.EQUIPPOS_WEAPON);
	TakeOffEquipment(Item.EQUIPPOS_FOOT);
	TakeOffEquipment(Item.EQUIPPOS_CUFF);
	TakeOffEquipment(Item.EQUIPPOS_AMULET);
	TakeOffEquipment(Item.EQUIPPOS_RING);
	TakeOffEquipment(Item.EQUIPPOS_NECKLACE);	
	TakeOffEquipment(Item.EQUIPPOS_PENDANT);
end

function Clear()
	PutOnAllEquipment();
end

function TakeOffEquipment(nPos)
	local pItem = me.GetItem(Item.ROOM_EQUIP, nPos, 0);
	if not pItem then
		return;
	end

	for _, nRoom in ipairs(Item.BAG_ROOM) do
		local nTargetX, nTargetY = me.GetFreeCellInRoom(nRoom)
		if nTargetX and nTargetY then
			me.SwitchItem(Item.ROOM_EQUIP, nPos, 0, nRoom, nTargetX, nTargetY);
			return true;
		end
	end	
end

function PutOnAllEquipment()
	for i, nRoomId in ipairs(Item.BAG_ROOM) do
		local nWidth, nHeight = me.GetRoomSize(nRoomId)
		for nRoomY = 0, nHeight - 1 do
			for nRoomX = 0, nWidth - 1 do
				local pItem = me.GetItem(nRoomId, nRoomX, nRoomY)
				if pItem and pItem.IsEquip() == 1 and pItem.IsBind() == 1 then
					me.UseItem(nRoomId, nRoomX, nRoomY)
				end
			end
		end	
	end
end
