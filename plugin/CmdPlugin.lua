Include("PluginBase");

tbStep = {};

function Setup()	
	nStep = 1;					
	return true;
end

function Activate(nNow)
	Lib:ShowTB(tbStep);
	local tbCmd = tbStep[nStep];
	if not tbCmd then
		Msg(szName .. "完成，插件关闭");
		DisablePlugin();	
		return;		
	end
	
	local bSucessed, bResult = Lib:CallBack(tbCmd);		
	if not bSucessed then
		Log(szName, "Step", nStep, "Error");
		DisablePlugin();	
		return;	
	end
	
	if bResult then
		nStep = nStep + 1;
	end
end
