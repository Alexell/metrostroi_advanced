----------------- Metrostroi Advanced -----------------
-- Авторы: Alexell и Agent Smith
-- Версия: 2.0
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexellpro
-- Repo: https://github.com/Alexell/metrostroi_advanced
-------------------------------------------------------

if SERVER then return end

CreateClientConVar("ma_autoinformator","1",true,true)
CreateClientConVar("ma_routenums","1",true,true)
CreateClientConVar("ma_clientoptimize","1",true,true)

-- Дублирующие серверные квары для админов
CreateClientConVar("metrostroi_advanced_spawninterval","0",false,false)
CreateClientConVar("metrostroi_advanced_trainsrestrict","0",false,false)
CreateClientConVar("metrostroi_advanced_spawnmessage","0",false,false)
CreateClientConVar("metrostroi_advanced_minwagons","0",false,false)
CreateClientConVar("metrostroi_advanced_maxwagons","0",false,false)
CreateClientConVar("metrostroi_advanced_autowags","0",false,false)
CreateClientConVar("metrostroi_advanced_afktime","0",false,false)
CreateClientConVar("metrostroi_advanced_timezone","0",false,false)

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
	end)
end)

-- Оптимизация клиента
local optimize = GetConVar("ma_clientoptimize"):GetInt()
if (optimize) then
	RunConsoleCommand( "gmod_mcore_test", 1 )
	RunConsoleCommand( "mat_queue_mode", 2 )
	RunConsoleCommand( "mat_specular", 0 )
	RunConsoleCommand( "cl_threaded_bone_setup", 1 )
	RunConsoleCommand( "cl_threaded_client_leaf_system", 1 )
	RunConsoleCommand( "r_threaded_client_shadow_manager", 1 )
	RunConsoleCommand( "r_threaded_particles", 1 )
	RunConsoleCommand( "r_threaded_renderables", 1 )
	RunConsoleCommand( "r_queued_ropes", 1 )
	RunConsoleCommand( "datacachesize", 512 )
	RunConsoleCommand( "mem_max_heapsize", 2048 )
end

-- Панели в меню [Q]
local function ClientPanel(panel)
    panel:ClearControls()
    panel:SetPadding(0)
    panel:SetSpacing(0)
    panel:Dock(FILL)
	panel:ControlHelp("Оптимизация:")
	panel:CheckBox("Использовать рекоменд. оптимизацию клиента","ma_clientoptimize")
	panel:Help("") -- отступ
	panel:Help("") -- отступ
	panel:ControlHelp("Разное:")
	panel:CheckBox("Автоматически выдавать номер маршрута","ma_routenums")
	panel:Help("      (необходимо переподключиться к серверу)")
	panel:CheckBox("Использовать автоинформатор","ma_autoinformator")
end

-- + вывести команду metrostroi_electric??? Посмотреть другие, посмотреть что еше интересного

local function AdminPanel(panel)
    if not LocalPlayer():IsAdmin() then return end
	panel:ClearControls()
    panel:SetPadding(0)
    panel:SetSpacing(0)
    panel:Dock(FILL)
	panel:ControlHelp("Серверные настройки Metrostroi Advanced:")
	panel:Help("Интервал между спавном поездов:")
	panel:NumSlider("","metrostroi_advanced_spawninterval",0,60,0)
	panel:CheckBox("Ограничение на спавн составов по рангу","metrostroi_advanced_trainsrestrict")
	panel:CheckBox("Писать в чат о спавне поезда","metrostroi_advanced_spawnmessage")
	panel:Help("Мин. вагонов для спавна:")
	panel:NumSlider("","metrostroi_advanced_minwagons",1,8,0)
	panel:Help("Макс. вагонов для спавна:")
	panel:NumSlider("","metrostroi_advanced_maxwagons",1,8,0)
	panel:CheckBox("Автом. кол-во вагонов для спавна","metrostroi_advanced_autowags")
	panel:Help("Кол-во минут AFK до кика игрока с сервера:")
	panel:NumSlider("","metrostroi_advanced_afktime",0,120,0)
	panel:NumSlider("Часовой пояс сервера","metrostroi_advanced_timezone",-12,12,0)
	panel:Help("") -- отступ
	panel:Help("") -- отступ
	panel:ControlHelp("Серверные настройки Metrostroi:")
	panel:NumSlider("Напряжение на КР","metrostroi_voltage",0,999,0)
	panel:Help("") -- отступ
	panel:Help("") -- отступ
	panel:ControlHelp("Инструменты:")
	panel:Button("Сохранить сигнализацию","metrostroi_save",true)
	panel:Button("Рестарт сигнализации","metrostroi_load",true)
	panel:Button("Редактор треков","metrostroi_trackeditor",true)
	panel:Button("Показать/скрыть треки","metrostroi_trackeditor_togglenodes",true)
end

hook.Add("PopulateToolMenu", "MetrostroiAdvancedACP", function()
	spawnmenu.AddToolMenuOption("Utilities", "Metrostroi Advanced", "MetrostroiAdvancedCP", "Клиент", "", "", ClientPanel)
	spawnmenu.AddToolMenuOption("Utilities", "Metrostroi Advanced", "MetrostroiAdvancedAP", "Админ", "", "", AdminPanel)
end)
