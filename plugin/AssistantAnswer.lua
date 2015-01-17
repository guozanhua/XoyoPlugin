Include("PluginBase");
SetDescription("答题助手", false);

function Setup()
	local szFile = "plug_in/Plugin/question.tab";
    local pTabFile = KIo.OpenTabFile(szFile, 1);
    if not pTabFile then
		Log(string.format("Load %s file failed!!", szFile));
		return false;
	end
	
	tbQuestionTable = {}

	local nLine = pTabFile.GetHeight();
	for nRow = 2, nLine do
		local szQuestion = pTabFile.GetStr(nRow, "Question");
		if szQuestion ~= "" then
			local szAnswerKey = "Opt" .. pTabFile.GetStr(nRow, "Answer"); 
			local szAnswer = pTabFile.GetStr(nRow, szAnswerKey); 
			tbQuestionTable[szQuestion] = tbQuestionTable[szQuestion] or {}
			table.insert(tbQuestionTable[szQuestion], szAnswer);
		end
	end
	
	KIo.CloseTabFile(pTabFile);
	return true;
end

function OnShowDialog(tbDlgInfo)	
	local nBegin, nEnd = string.find(tbDlgInfo.Text, "%. ");
	if not nEnd then
		return;
	end
	
	local szQuestion = string.sub(tbDlgInfo.Text, nEnd + 1);
	if not szQuestion then
		return;
	end
	
	local tbAnswer = tbQuestionTable[szQuestion]
	if not tbAnswer then
		return;
	end
	
	if nDelaySelectID then
		Ui.tbLogic.tbTimer:Close(nDelaySelectID);
		nDelaySelectID = nil;
	end
	
	for _k, _v in pairs(tbDlgInfo.OptList) do
		for _, szAnswer in pairs(tbAnswer) do
			if szAnswer == _v.Text then
				SelectDlg(_k);
				return true;			
			end
		end
	end
	
	if not nDelaySelectID then
		Log("问题" .. tbDlgInfo.Text);
		for _k, _v in pairs(tbDlgInfo.OptList) do
			if _v.Text then
				Log(string.format("选项%d %s", _k, _v.Text));
			end
		end
		for _k, _v in pairs(tbAnswer) do
			Log(string.format("答案%d %s", _k, _v));
		end
	end
end

function OnSelect(nSelect)
	me.Select(nSelect);
	UiManager:CloseWindow("saypanel");
	
	nDelaySelectID = nil;
	return 0;
end
