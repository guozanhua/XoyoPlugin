Include("PluginBase");
Include("aeslua");
-- SetDescription("����", true);

function Setup() -- ��ʼ������
	local sz = aeslua.encrypt("password", "test ��ʼ������");
	print(sz);
	local sz1 = aeslua.decrypt("password", sz);
	print(sz1);
--	return true;
end

--function Activate(nNow)	
--	KillSpecifiedNpc(144, 1897, 3311, 3148);
--end



