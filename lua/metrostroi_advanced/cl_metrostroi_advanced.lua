------------------------ Metrostroi Advanced -------------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- Version: 2.4
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_advanced
----------------------------------------------------------------------

if SERVER then return end

CreateClientConVar("ma_autoinformator","0",true,true,"Enable autoannouncer (def = 1 - enabled)")
CreateClientConVar("ma_routenums","1",true,true,"Auto-generate route number on train spawn (def = 1 - enabled)")
CreateClientConVar("ma_clientoptimize","1",true,false)
CreateClientConVar("ma_voltage","0",false,false,"Third rail voltage")
CreateClientConVar("ma_curlim","0",false,false,"Third rail current limit")
CreateClientConVar("ma_requirethirdrail","0",false,false,"Require third rail")
CreateClientConVar("ma_button_sourcename", "", false, false)
CreateClientConVar("ma_button_output", "", false, false)
CreateClientConVar("ma_auto_alsdecoder", "1", true, true,"Enable auto ALS decoder switching (def = 1 - enabled)")

-- Дублирующие серверные квары для админов
local AdminCVarList = {
	{"metrostroi_advanced_spawninterval","Global delay between spawns in seconds (def = 0 - disabled)"},
	{"metrostroi_advanced_trainsrestrict","Global train restrictions convar for ulx groups (def = 0 - disabled)"},
	{"metrostroi_advanced_spawnmessage","Global chat outputs for every spawned train (def = 1 - enabled)"},
	{"metrostroi_advanced_minwagons","Minimum wagon count for a player to spawn (def = 2)"},
	{"metrostroi_advanced_maxwagons","Maximum wagon count for a player to spawn (def = 4)"},
	{"metrostroi_advanced_autowags","Automatic permission to spawn 4 wagons instead of 3 wagons for the first 3 players to spawn a train, in case metrostroi_advanced_maxwagons convar is set to less than 4 (def = 0 - disabled)"},
	{"metrostroi_advanced_afktime","Time in minutes before a player is kicked for being AFK (def = 0 - disabled)"},
	{"metrostroi_advanced_timezone","Server time zone, def = 3 (Moscow local time)"},
	{"metrostroi_advanced_buttonmessage","Enable chat notifications for station control panel's buttons (def = 1 - enabled)"},
	{"metrostroi_advanced_noentryann","Enable automatic station announcements when there is no entry on an arriving train (def = 1 - enabled)"}
}
for _,cvr in pairs(AdminCVarList) do
	CreateClientConVar(cvr[1],"0",false,false,cvr[2])
end

-- Локализация
MetrostroiAdvanced.LoadLanguage(GetConVar("metrostroi_language"):GetString())
cvars.AddChangeCallback("metrostroi_language", function(cvar,old,new)
	if (old == new) then return end
    MetrostroiAdvanced.LoadLanguage(new)
end)
local function lang(str)
	return MetrostroiAdvanced.Lang[str]
end

-- Отправка команд на сервер
local function SendCommand(com,val)
	if not LocalPlayer():IsAdmin() then return end
	net.Start("MA.ServerCommands")
		net.WriteString(com)
		net.WriteString(val)
	net.SendToServer()
end

concommand.Add("ma_add_buttonoutput",function(ply,cmd,args)
	if not ply:IsAdmin() then return end
	local btn_name = GetConVar("ma_button_sourcename"):GetString()
	local btn_text = GetConVar("ma_button_output"):GetString()
	net.Start("MA.AddNewButtons")
		net.WriteString(btn_name)
		net.WriteString(btn_text)
	net.SendToServer()
end)

hook.Add("InitPostEntity","MA_PlayerInit",function()
	if not LocalPlayer():IsAdmin() then return end
	timer.Simple(1,function()
		for _,cvr in pairs(AdminCVarList) do
			cvars.AddChangeCallback(cvr[1],function(cvar,old,new)
				if (old == new) then return end
				SendCommand(cvar,new)
			end)
		end
		cvars.AddChangeCallback("ma_voltage",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
		cvars.AddChangeCallback("ma_curlim",function(cvar,old,new)
			if not tonumber(new) then return end
			if (tonumber(old) == tonumber(new)) then return end
			SendCommand(cvar,tonumber(new))
		end)
		cvars.AddChangeCallback("ma_requirethirdrail",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
	end)
	hook.Remove("InitPostEntity","MA_PlayerInit")
end)

-- Оптимизация клиента
local function ClientOptimize(opt)
	if (tonumber(opt) == 2) then
		RunConsoleCommand("gmod_mcore_test",1)
		RunConsoleCommand("mat_queue_mode",2)
		RunConsoleCommand("mat_specular",0)
		RunConsoleCommand("cl_threaded_bone_setup",1)
		RunConsoleCommand("cl_threaded_client_leaf_system",1)
		RunConsoleCommand("r_threaded_client_shadow_manager",1)
		RunConsoleCommand("r_threaded_particles",1)
		RunConsoleCommand("r_threaded_renderables",1)
		RunConsoleCommand("r_queued_ropes",1)
		RunConsoleCommand("datacachesize",512)
		RunConsoleCommand("mem_max_heapsize",2048)
	elseif (tonumber(opt) == 1) then
		RunConsoleCommand("gmod_mcore_test",0)
		RunConsoleCommand("mat_queue_mode",-1)
		RunConsoleCommand("mat_specular",1)
		RunConsoleCommand("cl_threaded_bone_setup",0)
		RunConsoleCommand("cl_threaded_client_leaf_system",0)
		RunConsoleCommand("r_threaded_client_shadow_manager",0)
		RunConsoleCommand("r_threaded_particles",1)
		RunConsoleCommand("r_threaded_renderables",0)
		RunConsoleCommand("r_queued_ropes",1)
		RunConsoleCommand("datacachesize",64)
		RunConsoleCommand("mem_max_heapsize",256)
	end
end
ClientOptimize(GetConVar("ma_clientoptimize"):GetInt())

-- Панели в меню [Q]
local function ClientPanel(panel)
    panel:ClearControls()
    panel:SetPadding(0)
    panel:SetSpacing(0)
    panel:Dock(FILL)
	panel:ControlHelp(lang("CPGameStart"))
	local cbox,lb = panel:ComboBox(lang("CPOptimization"),"ma_clientoptimize")
	cbox:AddChoice(lang("CPOptimization2"),2)
	cbox:AddChoice(lang("CPOptimization1"),1)
	cbox:AddChoice(lang("CPOptimization0"),0)
	panel:Help("") -- отступ
	panel:Help("") -- отступ
	panel:ControlHelp(lang("CPOptions"))
	panel:CheckBox(lang("CPRouteNum"),"ma_routenums")
	panel:Help("      "..lang("CPNeedReconnect"))
	panel:CheckBox(lang("CPUseAutoinform"),"ma_autoinformator")
	panel:CheckBox(lang("CPUseAutoALSDecoder"),"ma_auto_alsdecoder")
end

local function AdminPanel(panel)
    if not LocalPlayer():IsAdmin() then return end
	panel:ClearControls()
    panel:SetPadding(0)
    panel:SetSpacing(0)
    panel:Dock(FILL)
	panel:ControlHelp(lang("APServerOptions").." Metrostroi Advanced:")
	panel:Help(lang("APSpawnInterval"))
	panel:NumSlider("","metrostroi_advanced_spawninterval",0,60,0)
	panel:CheckBox(lang("APTrainRestrict"),"metrostroi_advanced_trainsrestrict")
	panel:CheckBox(lang("APSpawnMessage"),"metrostroi_advanced_spawnmessage")
	panel:Help(lang("APWagMin"))
	panel:NumSlider("","metrostroi_advanced_minwagons",1,8,0)
	panel:Help(lang("APWagMax"))
	panel:NumSlider("","metrostroi_advanced_maxwagons",1,8,0)
	panel:CheckBox(lang("APAutoWags"),"metrostroi_advanced_autowags")
	panel:Help(lang("APAFKTime"))
	panel:NumSlider("","metrostroi_advanced_afktime",0,120,0)
	panel:NumSlider(lang("APServerTimezone"),"metrostroi_advanced_timezone",-12,12,0)
	panel:CheckBox(lang("APNoEntryAnn"),"metrostroi_advanced_noentryann")
	panel:Help("") -- отступ
	panel:Help("") -- отступ
	panel:ControlHelp(lang("APServerOptions").." Metrostroi:")
	panel:CheckBox(lang("APReqThirdRail"),"ma_requirethirdrail")
	panel:NumSlider(lang("APThirdRailVol"),"ma_voltage",0,999,0)
	panel:Help(lang("APCurLim").." (A):")
	panel:TextEntry("","ma_curlim")
	panel:Help("") -- отступ
	panel:ControlHelp(lang("APTools"))
	panel:Help(lang("ACPBtnHeader"))
	panel:CheckBox(lang("ACPBtnCheckBox"),"metrostroi_advanced_buttonmessage")
	panel:Help(lang("ACPBtnCheckBox"))
	panel:TextEntry(lang("ACPBtnSource"),"ma_button_sourcename")
	panel:TextEntry(lang("ACPBtnVisible"),"ma_button_output")
	panel:Button(lang("ACPBtnAdd"),"ma_add_buttonoutput",true)
	panel:Button(lang("ACPBtnSave"),"ma_save_buttonoutput",true)
	panel:Help("") -- отступ
	panel:Help(lang("ACPSigTools"))
	panel:Button(lang("APSignSave"),"metrostroi_save",true)
	panel:Button(lang("APSignReload"),"metrostroi_load",true)
	panel:Button(lang("APTrackEditor"),"metrostroi_trackeditor",true)
	panel:Button(lang("APToggleNodes"),"metrostroi_trackeditor_togglenodes",true)
end

hook.Add("PopulateToolMenu", "MetrostroiAdvancedACP", function()
	spawnmenu.AddToolMenuOption("Utilities", "Metrostroi Advanced", "MetrostroiAdvancedCP", lang("ACPClient"), "", "", ClientPanel)
	spawnmenu.AddToolMenuOption("Utilities", "Metrostroi Advanced", "MetrostroiAdvancedAP", lang("ACPAdmin"), "", "", AdminPanel)
end)
