------------------------ Metrostroi Advanced -------------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- Version: 2.1
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_advanced
----------------------------------------------------------------------

if SERVER then return end

CreateClientConVar("ma_autoinformator","1",true,true)
CreateClientConVar("ma_routenums","1",true,true)
CreateClientConVar("ma_clientoptimize","1",true,false)
CreateClientConVar("ma_voltage","0",false,false)
CreateClientConVar("ma_curlim","0",false,false)
CreateClientConVar("ma_requirethirdrail","0",false,false)

-- Дублирующие серверные квары для админов
CreateClientConVar("metrostroi_advanced_spawninterval","0",false,false)
CreateClientConVar("metrostroi_advanced_trainsrestrict","0",false,false)
CreateClientConVar("metrostroi_advanced_spawnmessage","0",false,false)
CreateClientConVar("metrostroi_advanced_minwagons","0",false,false)
CreateClientConVar("metrostroi_advanced_maxwagons","0",false,false)
CreateClientConVar("metrostroi_advanced_autowags","0",false,false)
CreateClientConVar("metrostroi_advanced_afktime","0",false,false)
CreateClientConVar("metrostroi_advanced_timezone","0",false,false)

-- Локализация
MetrostroiAdvanced.LoadLanguage(GetConVarString("metrostroi_language"))
cvars.AddChangeCallback("metrostroi_language", function(cvar,old,new)
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

hook.Add("InitPostEntity","MA_PlayerInit",function()
	if not LocalPlayer():IsAdmin() then return end
	timer.Simple(1,function()
		cvars.AddChangeCallback("metrostroi_advanced_spawninterval",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
		cvars.AddChangeCallback("metrostroi_advanced_trainsrestrict",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
		cvars.AddChangeCallback("metrostroi_advanced_spawnmessage",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
		cvars.AddChangeCallback("metrostroi_advanced_minwagons",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
		cvars.AddChangeCallback("metrostroi_advanced_maxwagons",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
		cvars.AddChangeCallback("metrostroi_advanced_autowags",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
		cvars.AddChangeCallback("metrostroi_advanced_afktime",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
		cvars.AddChangeCallback("metrostroi_advanced_timezone",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
		--
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
	panel:Help("") -- отступ
	panel:Help("") -- отступ
	panel:ControlHelp(lang("APServerOptions").." Metrostroi:")
	panel:CheckBox(lang("APReqThirdRail"),"ma_requirethirdrail")
	panel:NumSlider(lang("APThirdRailVol"),"ma_voltage",0,999,0)
	panel:Help(lang("APCurLim").." (A):")
	panel:TextEntry("","ma_curlim")
	panel:Help("") -- отступ
	panel:Help("") -- отступ
	panel:ControlHelp(lang("APTools"))
	panel:Button(lang("APSignSave"),"metrostroi_save",true)
	panel:Button(lang("APSignReload"),"metrostroi_load",true)
	panel:Button(lang("APTrackEditor"),"metrostroi_trackeditor",true)
	panel:Button(lang("APToggleNodes"),"metrostroi_trackeditor_togglenodes",true)
end

hook.Add("PopulateToolMenu", "MetrostroiAdvancedACP", function()
	spawnmenu.AddToolMenuOption("Utilities", "Metrostroi Advanced", "MetrostroiAdvancedCP", lang("ACPClient"), "", "", ClientPanel)
	spawnmenu.AddToolMenuOption("Utilities", "Metrostroi Advanced", "MetrostroiAdvancedAP", lang("ACPAdmin"), "", "", AdminPanel)
end)
