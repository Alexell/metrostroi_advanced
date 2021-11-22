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
	panel:ControlHelp("") -- отступ
	panel:ControlHelp("Разное:")
	panel:CheckBox("Автоматически выдавать номер маршрута","ma_routenums")
	panel:CheckBox("Использовать автоинформатор","ma_autoinformator")
end

hook.Add("PopulateToolMenu", "MetrostroiAdvancedACP", function()
	spawnmenu.AddToolMenuOption("Utilities", "Metrostroi Advanced", "MetrostroiAdvancedCP", "Клиент", "", "", ClientPanel)
end)