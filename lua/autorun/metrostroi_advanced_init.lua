----------------- Metrostroi Advanced -----------------
-- Авторы: Alexell и Agent Smith
-- Версия: 1.0
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_advanced
-------------------------------------------------------

-- Создаем MetrostroiAdvanced глобально
if not MetrostroiAdvanced then
	MetrostroiAdvanced = {}
	MetrostroiAdvanced.TrainList = {}
	
	MetrostroiAdvanced.TrainList["gmod_subway_81-502"] 				= "81-502 (Ема-502)"
	MetrostroiAdvanced.TrainList["gmod_subway_81-702"] 				= "81-702 (Д)"
	MetrostroiAdvanced.TrainList["gmod_subway_81-703"] 				= "81-703 (E)"
	MetrostroiAdvanced.TrainList["gmod_subway_ezh"] 				= "81-707 (Еж)"
	MetrostroiAdvanced.TrainList["gmod_subway_ezh3"] 				= "81-710 (Еж3)"
	MetrostroiAdvanced.TrainList["gmod_subway_ezh3ru1"] 			= "81-710 (Еж3 РУ1)"
	MetrostroiAdvanced.TrainList["gmod_subway_81-717_mvm"]			= "81-717 (Номерной МСК)"
	MetrostroiAdvanced.TrainList["gmod_subway_81-717_mvm_custom"]	= "81-717 (Номерной МСК)"
	MetrostroiAdvanced.TrainList["gmod_subway_81-717_lvz"] 			= "81-717 (Номерной СПБ)"
	MetrostroiAdvanced.TrainList["gmod_subway_81-717_6"] 			= "81-717.6"
	MetrostroiAdvanced.TrainList["gmod_subway_81-718"] 				= "81-718 (ТИСУ)"
	MetrostroiAdvanced.TrainList["gmod_subway_81-720"] 				= "81-720 (Яуза)"
	MetrostroiAdvanced.TrainList["gmod_subway_81-722"] 				= "81-722 (Юбилейный)"
  --MetrostroiAdvanced.TrainList["gmod_subway_81-760"] 				= "81-760 (Ока)"
end

if SERVER then
	include("sv_metrostroi_advanced.lua")
	include("metrostroi_map_fixes.lua")
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

-- Название состава по классу
function MetrostroiAdvanced.GetTrainName(class)
	local train_name = ""
	for k, v in pairs (MetrostroiAdvanced.TrainList) do
		if (class == k) then
			train_name = v
			break
		end
	end
	return train_name
end

-- Получение местоположения
function MetrostroiAdvanced.GetLocation(ent)
	local ent_station = ""
	local map_pos
	local station_pos
	local station_posx
	local station_posy
	local station_posz
	local train_pos
	local train_posx
	local train_posy
	local train_posz
	local get_pos1
	local get_pos2
	local radius = 4000 -- Радиус по умолчанию для станций на всех картах
	local cur_map = game.GetMap()
	local Sz
	local S
	
	train_pos = tostring(ent:GetPos())
	get_pos1 = string.find(train_pos, " ")
	train_posx = string.sub(train_pos,1,get_pos1)
	train_posx = tonumber(train_posx)	
	
	get_pos2 = string.find(train_pos, " ", get_pos1 + 1)
	train_posy = string.sub(train_pos,get_pos1,get_pos2)
	train_posy = tonumber(train_posy)
	
	train_posz = string.sub(train_pos,get_pos2 + 1)
	train_posz = tonumber(train_posz)

	for k, v in pairs(Metrostroi.StationConfigurations) do
		map_pos = v.positions and v.positions[1]
		if map_pos and map_pos[1] then
			station_pos = tostring(map_pos[1])
			get_pos1 = string.find(station_pos, " ")
			station_posx = string.sub(station_pos,1,get_pos1)
			station_posx = tonumber(station_posx)
			
			get_pos2 = string.find(station_pos, " ", get_pos1 + 1)
			station_posy = string.sub(station_pos,get_pos1,get_pos2)
			station_posy = tonumber(station_posy)
			
			station_posz = string.sub(station_pos,get_pos2 + 1)
			station_posz = tonumber(station_posz)
			
			if (cur_map:find("gm_metro_jar_imagine_line"))  then
				if (v.names[1] == "ДДЭ" or v.names[1] == "Диспетчерская") then continue end
			end

			if ((station_posz > 0 and train_posz > 0) or (station_posz < 0 and train_posz < 0)) then -- оба Z больше нуля или меньше нуля
				Sz = math.max(math.abs(station_posz),math.abs(train_posz)) - math.min(math.abs(station_posz),math.abs(train_posz))
			end
			if ((station_posz < 0 and train_posz > 0) or (station_posz > 0 and train_posz < 0)) then -- один Z больше нуля или меньше нуля
				Sz = math.abs(train_posz) + math.abs(station_posz)
			end
			S = math.sqrt(math.pow((station_posx - train_posx), 2) + math.pow((station_posy - train_posy), 2))
		
			-- Поиск ближайшей точки в StationConfigurations с уменьшением радиуса:
			if (S < radius and Sz < 200)
			then 
				ent_station = (v.names[1])
				radius = S
			end
		end
	end
	if (ent_station=="") then ent_station = "перегон" end
	return ent_station
end

-- Получение уникального рандомного номера маршрута
function MetrostroiAdvanced.GetRouteNumber(ply)
	local rnum = math.random(99)
	local routes = {}
	for k,v in pairs(MetrostroiAdvanced.TrainList) do
		local trs = ents.FindByClass(v)
		for k2,v2 in pairs(trs) do
			if (routes[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] == nil and v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)" != ply:Nick()) then
				if (v2:GetNW2String("RouteNumber") != "") then
					local rnum2 = tonumber(v2:GetNW2String("RouteNumber"))
					if table.HasValue({"gmod_subway_81-702","gmod_subway_81-703","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_ezh3ru1","gmod_subway_81-717_mvm","gmod_subway_81-717_mvm_custom","gmod_subway_81-718","gmod_subway_81-720"},v2:GetClass()) then rnum2 = rnum2 / 10 end
					routes[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] = rnum2
				end
			end
		end
	end
	if routes != nil then
		local r2 = {}
		for k,v in pairs(routes) do
			r2[#r2+1] = v
		end
		
		for k,v in pairs(r2) do
			if (rnum == v or rnum == 22 or rnum == 11) then
				rnum = math.random(99)
				k = 1
			end	
		end
	end
	
	if ply:SteamID() == "STEAM_0:1:125018747" then rnum = 22 end -- Alexell
	if ply:SteamID() == "STEAM_0:1:15049625" then rnum = 11 end -- Agent Smith
	
	return rnum
end
