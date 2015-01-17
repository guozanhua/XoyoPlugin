Include("PluginBase");

-- SetDescription("自动派遣", false);
local nCheFuNpcID = 2228;

function Setup()	
	nSteps = 1;	
	Msg("自动派遣已开启");
	return true;
end

function OnShowDialog(tbDlgInfo)
	local tbSelectDlgText = {};	
	
	local szType = GetMapType(me.GetMapTemplateID());
	if szType == "city" then 
		table.insert(tbSelectDlgText, "回我的居住地");
	end
		
	if me.nLevel >= 100 then
		table.insert(tbSelectDlgText, "冷龙岭（95级）");
	elseif me.nLevel >= 80 then
		table.insert(tbSelectDlgText, "星陨密窟（80级）");
	elseif me.nLevel >= 60 then
		table.insert(tbSelectDlgText, "星陨铁堡（60级）");
	end

	for _k, _v in pairs(tbDlgInfo.OptList) do
		for _, szSelectDlgText in pairs(tbSelectDlgText) do
			if _v.Text == szSelectDlgText then
				SelectDlg(_k);
				return true;
			end
		end			
	end
end

function Activate()	
	while true do
		if nSteps > #tbSteps then
			nSteps = 1;
			break;
		end
					
		if tbSteps[nSteps]() then
			Log("Auto parter doing step" .. nSteps .. " success!");
			nSteps = nSteps + 1;
		else
			break
		end
	end
end

function IsAvailable() 
	local nSprotTimes = 0;
	local tbSprotTimes = GetSprotState();
	for _, v in pairs(tbSprotTimes) do
		nSprotTimes = nSprotTimes + v;
	end	
	if nSprotTimes == 0 then		
		return;
	end
	
	local bEnable, bHasAward = GetPartnerState();
	if not bEnable and not bHasAward then 
		return;
	end
	
	local nEnergy = Import("common_script/degreectrl.lua").GetDegree(me, "PartnerEnergy");	
	return nEnergy > 60;
end

function GetSprotState()
	local nMiJingSkillID = 1;
	local nQingYunFengSkillID = 2;
	local nYunBiaoSkillID = 3; 
	local nTongJiSkillID = 4;
	local nMenPaiShouWeiSkillID = 5;

	local tbSprotTimes = {};	
	local tbAllSprot = Ui.tbLogic.tbCalendar:GetAllSport();
	
	for i = 1, 5 do
		tbSprotTimes[i] = 0;
		
		local tbCalendar = tbAllSprot[Partner.tbSkillSetting[i].CalendarName];
		if tbCalendar and tbCalendar.fnCalcDegree then
			tbSprotTimes[i] = tbCalendar.fnCalcDegree(me);
		end		
	end
	
	
	tbSprotTimes[nYunBiaoSkillID] = 0;
	
	local nSecond = Lib:GetLocalDayTime();
	if nSecond < 21 * 3600 then -- 每晚9点后发现本日可以派遣的活动,则自动派遣(现在认证用户送活力360了，可以多派遣一些)
		tbSprotTimes[nMiJingSkillID] = 0;
		tbSprotTimes[nQingYunFengSkillID] = 0;
		tbSprotTimes[nMenPaiShouWeiSkillID] = 0;
	else
		if tbSprotTimes[nQingYunFengSkillID] < 8 then
			tbSprotTimes[nQingYunFengSkillID] = 0; -- 每天9点半后,发现青云峰次数大于等于8自动派遣青云峰
		end		
	end
	
	return tbSprotTimes;
end

-- 参数1 是否可派遣, 是否有奖励未领
function GetPartnerState()
	local bEnable = false;
	local bAward = false;
	
	for i = 1, Partner.MAX_PARTNER do	
		local tbData = Partner.tbPartner[i];
		if tbData then		
			if tbData.nWorkStartTime and tbData.nWorkStartTime > 0 and tbData.szWorkType then
				if tbData.nWorkEndTime <= GetTime() then
					bAward = true;
				end
			else
				bEnable = true; 	
			end
		end
	end		
	
	return bEnable, bAward;
end

function Step_GoHome()
	if IsMapHouse(me.nTemplateMapId) then
		return true;
	end
	
	local bAvailable = IsAvailable();
	if not bAvailable then 
		Msg("本次派遣完成，插件关闭");
		DisablePlugin();	
		return;
	end
	
	AutoFight:Stop();

	local szType = GetMapType(me.GetMapTemplateID());
	if szType == "fight" and me.GetItemCountInBags(1947, -1) > 0 then -- 回城石		
		RemoteServer.CheFuGoHome();	
		return;		
	end
		
	local nMapTemplateID, nX, nY = Task:GetTaskNpcCityMapPosByNpc(30, nCheFuNpcID); 
	assert(nMapTemplateID);		

	local bRetCode = RunToPoint(nMapTemplateID, nX, nY, 2);
	if not bRetCode then
		return;
	end
	
	bRetCode = DialogNpc(nCheFuNpcID);
	if not bRetCode then
		assert(false);
	end
end

function Step_DoPartner()
	if not IsMapHouse(me.nTemplateMapId) then
		return true;
	end	
		
	local bEnable, bHasAward = GetPartnerState();
	if not bEnable and not bHasAward then 
		return true;
	end	
		
	if bHasAward then
		for i = 1, Partner.MAX_PARTNER do		
			local tbData = Partner.tbPartner[i];		
			if tbData then					
				if tbData.nWorkStartTime and tbData.nWorkStartTime > 0 and tbData.szWorkType then
					if tbData.nWorkEndTime <= GetTime() then
						me.CallServerScript("PartnerCmd", "FetchAward", i);
					end
				end
			end
		end			
		return;
	end
	
	local tbSprotTimes = GetSprotState();	
	for i = 1, Partner.MAX_PARTNER do
		local tbData = Partner.tbPartner[i];		
		if tbData then
			if not (tbData.nWorkStartTime and tbData.nWorkStartTime > 0 and tbData.szWorkType) then
				for nSkillId, nTimes in pairs(tbSprotTimes) do
					if nTimes > 0 then
						local tbWork = Partner:GetSkillWork(tbData, nSkillId);
						me.CallServerScript("PartnerCmd", "SendToWork", i, nSkillId);
						return;
					end
				end
			end
		end
	end		
end

function Step_LeaveHome()
	if not IsMapHouse(me.nTemplateMapId) then
		return true;
	end	
	
	local tbNpc = KNpc.GetAroundNpcList(me, 96);
	for _, pNpc in pairs(tbNpc) do
		if pNpc.nTemplateId == 4237 then
			local _, nX, nY = pNpc.GetWorldPos();
			RunToPoint(me.nTemplateMapId, nX, nY);
		end
	end	
end

tbSteps = 
{
	Step_GoHome,
	Step_DoPartner,
	Step_LeaveHome,
}
