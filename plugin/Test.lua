Include("PluginBase");
Include("aeslua");
-- SetDescription("测试", true);

function Setup() -- 初始化工作
	local sz = aeslua.encrypt("password", "test 初始化工作");
	print(sz);
	local sz1 = aeslua.decrypt("password", sz);
	print(sz1);
--	return true;
end

--function Activate(nNow)	
--	KillSpecifiedNpc(144, 1897, 3311, 3148);
--end



