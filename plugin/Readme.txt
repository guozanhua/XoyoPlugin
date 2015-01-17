命名规范：
AssistantXxxx	为Xxxx性质的助手
AutoXxxx		为Xxxx性质的自动

为什么是插件而非脱机：
其实我尝试过搞机器人，搞了一周左右，发现是个严重的坑，开发量巨大，难以调试。。。

调试技巧：
每天搜索一下日志中的 “stack traceback:”，看是否是插件报错

Todo List：
（Auto）披风换入微镜绑金(交易中心的被封的厉害)
（Auto）强化碎片赚钱(交易中心的被封的厉害)
（Auto）自动做任务拆分成两个，基础任务模块和特例任务，自动任务整理，并可支持500打怪等
（Assistant）自动寻路支持武林高手, 解决双龙洞地下泉跟战卡住的问题(暂时没好的思路，有个差的)
（Assistant）交易中心，拍卖行操盘(没思路, 交易中心的被封的厉害)
（Assistant）自动答题？！
（Auto）自动任务整理，并可支持500打怪等
（Assistant）交易中心自动监控白水晶、蓝水晶
（Auto）自动奇遇秘境
（Auto）自动藏宝图
（Assistant）滚动条可以增加检查  是否对话的已经消失（暂时没思路）

local tbFaction = LoadTabFile(
	"setting/faction/faction.tab", 
	"dsds", 
	"FactionId", 
	{"FactionId", "Name", "Series", "Icon"}
);


版本介绍：
	插件测试版	2012.07.27 
		尝试实现自动任务。
	
	插件1.0		2012.09.26
		调整框架结构。将消息注册等功能统一管理，插件不需要太多关注注册等细节
	
	插件1.5		2012.10.25
		注册插件接口被封，调整插件注册机制。
	
	插件2.0		2012.10.30
		调整插件结构。将原有的类结构改为文件结构，使插件功能更为单一。
	
	插件2.1		2012.11.05
		新增hook api的接口，使hook函数简单，安全。调整插件注册机制，使脚本更易调试。
		新版本代号：counter-attack 屌丝的逆袭。
	
插件介绍：
Assistant：自动领取福利,出售灰色物品,保证背包最少空闲格子数, 点队伍头像开启跟随战斗(默认开启)
ScheduledTask：计划任务，负责插件间的交互
AssistantDieback：简单版本的计划任务,防止小号作无谓的活动
AssistantAnswer：花灯或重大历程的题目问答
AssistantBattle：战场助手，调整血量，攻击血量最少的敌人。适用于：武当、峨眉(计划任务进入战场、领土战时自动激活)
AssistantClearFriends：自动清理好友。(计划任务进入副本时自动激活)
AssistantDialog：自动对话(家族种植，拾取箱子，灵果采集)(拾取箱子功能有问题)(计划任务进入灵果地图时自动激活)
AssistantMiJing：自动秘境(计划任务进入副本时自动激活)
AutoLiLian：自动历练(计划任务每天自动激活)
AutoYunBiao：自动运镖(计划任务每天自动激活)
AssistantTeamLiLian：组队历练助手。
AutoParter：自动派遣(计划任务每天自动激活)
AssistantHockshop：交易中心助手(默认开启)
AutoHockshop：自动购买收藏的装备，自动计算强化赚钱
AssistantExchangeStone：混沌原石助手，计算出购买哪种道具兑换混沌原石利润最高
AssistantChat：过滤无用的聊天消息，密聊控制(默认开启)
AssistantMap：地图扩展首领点等
AutoShangHui：半自动商会任务
AutoShouLing：自动和周围的首领对话


