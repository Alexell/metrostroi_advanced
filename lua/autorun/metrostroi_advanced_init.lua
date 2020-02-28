----------------- Metrostroi Advanced -----------------
-- Авторы: Alexell и Agent Smith
-- Версия: 1.0
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_advanced
-------------------------------------------------------

if not Metrostroi or not Metrostroi.Version or Metrostroi.Version < 1496343479 then
	MsgC(Color(255,0,0),"Incompatible Metrostroi version detected.\nMetrostroi Advanced can not be loaded.\n")
	return
end

-- Создаем MetrostroiAdvanced глобально
if not MetrostroiAdvanced then
	MetrostroiAdvanced = {}
	MetrostroiAdvanced.TrainList = {}
	MetrostroiAdvanced.StationsIgnore = {}
	MetrostroiAdvanced.MapWagons = {}
end

-- Перенос настроек в отдельную папку (временный код для автоматического перехода)
if file.Exists("metrostroi_advanced_trains.txt","DATA") then
	if not file.Exists("metrostroi_advanced","DATA") then
		file.CreateDir("metrostroi_advanced")
	end
	--local trains = file.Read("metrostroi_advanced_trains.txt","DATA")
	file.Write("metrostroi_advanced/trains.txt",file.Read("metrostroi_advanced_trains.txt","DATA"))
	file.Delete("metrostroi_advanced_trains.txt")
end
if file.Exists("metrostroi_advanced_stations_ignore.txt","DATA") then
	if not file.Exists("metrostroi_advanced","DATA") then
		file.CreateDir("metrostroi_advanced")
	end
	file.Write("metrostroi_advanced/stations_ignore.txt",file.Read("metrostroi_advanced_stations_ignore.txt","DATA"))
	file.Delete("metrostroi_advanced_stations_ignore.txt")
end

-- Загрузка локализации
function MetrostroiAdvanced.LoadLanguage(lang)
	if MetrostroiAdvanced.Lang then MetrostroiAdvanced.Lang = nil end
	if file.Exists("metrostroi_advanced/language/"..lang..".lua","LUA") then
		include("metrostroi_advanced/language/"..lang..".lua")
	else
		print("Metrostroi Advanced: localization file not found: lua/metrostroi_advanced/language/"..lang..".lua")
		print("Metrostroi Advanced: default language will be loaded (ru)")
		include("metrostroi_advanced/language/ru.lua")
	end

	file.Write("metrostroi_advanced/trains.txt","") -- очищаем файл с составами для перезаписи
	
	for _,class in pairs(Metrostroi.TrainClasses) do
		local ENT = scripted_ents.Get(class)
		if not ENT.Spawner or not ENT.SubwayTrain then continue end
		file.Append("metrostroi_advanced/trains.txt",class.."\n")
		MetrostroiAdvanced.TrainList[class] = MetrostroiAdvanced.Lang[class] or ENT.PrintName or class
	end
end

-- Список слов из точек телепорта для игнорирования запрета спавна на станциях
function MetrostroiAdvanced.LoadStationsIgnore()
	if not file.Exists("metrostroi_advanced/stations_ignore.txt","DATA") then
		file.Write("metrostroi_advanced/stations_ignore.txt","Депо,депо,Depot,depot,ПТО,пто,Оборот,оборот,Oborot,oborot,Тупик,тупик,Deadlock,deadlock")
	end
	MetrostroiAdvanced.StationsIgnore = string.Explode(",",file.Read("metrostroi_advanced/stations_ignore.txt","DATA"))
end

-- Список карт и кол-во разрешенных вагонов на состав
function MetrostroiAdvanced.LoadMapWagonsLimit()
	if not file.Exists("metrostroi_advanced/map_wagons.txt","DATA") then
		file.Write("metrostroi_advanced/map_wagons.txt","gm_jar_pll_remastered_v9 4\ngm_mustox_neocrimson_line_a 4\ngm_metro_crossline_n3 6\ngm_metro_crossline_r199h 6\ngm_mus_loopline_e 5\ngm_metro_ruralline_v29 4\ngm_metro_jar_imagine_line_v4 6\ngm_mus_neoorange_d 3\ngm_metro_surfacemetro_w 4\ngm_metro_virus_v2 6\ngm_metro_mosldl_v1 8")
	end
	local mapwagons = string.Explode("\n",file.Read("metrostroi_advanced/map_wagons.txt","DATA"))
	for _,str in pairs(mapwagons) do
		local tbl = string.Explode(" ",str)
		if tbl[1] ~= "" and tonumber(tbl[2]) then
			MetrostroiAdvanced.MapWagons[tbl[1]] = tonumber(tbl[2]) or nil
		end
	end
end

-- Название состава по классу
function MetrostroiAdvanced.GetTrainName(class)
	if MetrostroiAdvanced.TrainList[class] and MetrostroiAdvanced.TrainList[class] ~= "" then
		return MetrostroiAdvanced.TrainList[class]
	else
		return class
	end
end

-- Получение местоположения
function MetrostroiAdvanced.GetLocation(ent,pos)
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
	
	if pos then
		train_pos = tostring(pos)
	else
		train_pos = tostring(ent:GetPos())
	end
	
	get_pos1 = string.find(train_pos, " ")
	train_posx = string.sub(train_pos,1,get_pos1)
	train_posx = tonumber(train_posx)	
	
	get_pos2 = string.find(train_pos, " ", get_pos1 + 1)
	train_posy = string.sub(train_pos,get_pos1,get_pos2)
	train_posy = tonumber(train_posy)
	
	train_posz = string.sub(train_pos,get_pos2 + 1)
	train_posz = tonumber(train_posz)

	if Metrostroi.StationConfigurations then
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
	else
		ent_station = "N/A"
	end
	if (ent_station=="") then ent_station = MetrostroiAdvanced.Lang["UnknownPlace"] end
	return ent_station
end

-- Получение уникального рандомного номера маршрута
function MetrostroiAdvanced.GetRouteNumber(ply)
	local rnum = math.random(23,99)
	local routes = {}
	for k,v in pairs(MetrostroiAdvanced.TrainList) do
		if string.find(k,"custom") then continue end
		for _,train in pairs(ents.FindByClass(k)) do
			local owner = train.Owner
			if not IsValid(owner) then continue end
			if owner != ply then
				local rnum2 = 0
				if k == "gmod_subway_81-722" or k == "gmod_subway_81-722_3" or k == "gmod_subway_81-7175p" then
					rnum2 = tonumber(train.RouteNumberSys.RouteNumber)
				elseif k == "gmod_subway_81-717_6" then
					rnum2 = train.ASNP.RouteNumber
				else
					if train.RouteNumber then
						rnum2 = tonumber(train.RouteNumber.RouteNumber)
					end
				end
				if table.HasValue({"gmod_subway_81-702","gmod_subway_81-703","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_81-717_mvm","gmod_subway_81-718","gmod_subway_81-720"},k) then rnum2 = rnum2 / 10 end
				routes[owner:Nick()] = rnum2
			end
		end
	end
	if routes != nil then
		local r2 = {}
		for k,v in pairs(routes) do
			r2[#r2+1] = v
		end
		
		for k,v in pairs(r2) do
			if rnum == v then
				rnum = math.random(23,99)
				k = 1
			end	
		end
	end
	
	if ply:SteamID() == "STEAM_0:1:125018747" then rnum = 22 end -- Alexell
	if ply:SteamID() == "STEAM_0:1:15049625" then rnum = 11 end -- Agent Smith
	
	return rnum
end

if SERVER then
	include("metrostroi_advanced/sv_metrostroi_advanced.lua")
	include("metrostroi_advanced/metrostroi_map_fixes.lua")
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