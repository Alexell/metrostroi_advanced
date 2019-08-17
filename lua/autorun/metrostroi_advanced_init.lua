----------------- Metrostroi Advanced -----------------
-- Авторы: Alexell и Agent Smith
-- Версия: 1.0
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_advanced
-------------------------------------------------------

if SERVER then
	include("sv_metrostroi_advanced.lua")
end

if CLIENT then
	-- Оптимизация клиентов
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