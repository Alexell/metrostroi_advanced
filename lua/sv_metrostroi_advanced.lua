----------------- Metrostroi Advanced -----------------
-- Авторы: Alexell и Agent Smith
-- Версия: 1.0
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_advanced
-------------------------------------------------------

if CLIENT then return end
local CATEGORY_NAME = "Metrostroi Advanced"

--CVars
local spawn_int = CreateConVar("metrostroi_spawn_interval", "0", {FCVAR_NEVER_AS_STRING})
local train_rest = CreateConVar("metrostroi_trains_restrict", "0", {FCVAR_NEVER_AS_STRING})
local spawn_mes = CreateConVar("metrostroi_spawn_message", "1", {FCVAR_NEVER_AS_STRING})

local train_list = {}
train_list["gmod_subway_81-502"] 			= "81-502 (Ема-502)"
train_list["gmod_subway_81-702"] 			= "81-702 (Д)"
train_list["gmod_subway_81-703"] 			= "81-703 (E)"
train_list["gmod_subway_ezh"] 				= "81-707 (Еж)"
train_list["gmod_subway_ezh3"] 				= "81-710 (Еж3)"
train_list["gmod_subway_81-717_mvm"] 		= "81-717 (Номерной МСК)"
train_list["gmod_subway_81-717_mvm_custom"] = "81-717 (Номерной МСК)"
train_list["gmod_subway_81-717_lvz"] 		= "81-717 (Номерной СПБ)"
train_list["gmod_subway_81-718"] 			= "81-718 (ТИСУ)"
train_list["gmod_subway_81-720"] 			= "81-720 (Яуза)"
train_list["gmod_subway_81-722"] 			= "81-722 (Юбилейный)"
--train_list["gmod_subway_81-760"] 			= "81-760 (Ока)"
	
-- Получение названия состава
local function GetTrainName(class)
	local train_name = ""
	for k, v in pairs (train_list) do
		if (class == k) then
			train_name = v
			break
		end
	end
	return train_name
end

-- Получение местоположения
local function GetTrainLoc(ent)
	local train_station = ""
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
				train_station = (v.names[1])
				radius = S
			end
		end
	end
	if (train_station=="") then train_station = "перегон" end
	return train_station
end

hook.Add("MetrostroiSpawnerRestrict","TrainSpawnerLimits",function(ply,settings)
	if IsValid(ply) then
		--задержка спавна
		local spawnint = GetConVarNumber("metrostroi_spawn_interval")
		if (spawnint > 0) then
			local lastspawn = GetGlobalInt("TrainLastSpawned",0)
			local curtime = os.time()
			local curint = curtime - lastspawn
			if (curint < spawnint) then
				local secs = spawnint - curint
				ply:ChatPrint("Пожалуйста подождите "..secs.." секунд прежде, чем спавнить состав.")
				return true
			end
		end
		
		--ограничение составов по правам ULX
		local train_restrict = GetConVarNumber("metrostroi_trains_restrict")
		local train = settings.Train
		
		if (train_restrict == 1) then
			if (not ULib.ucl.query(ply,train)) then
				ply:ChatPrint("[Сервер] Вам запрещен данный тип состава!")
				ply:ChatPrint("Разрешено спавнить только следующие составы:")
				for k, v in pairs (train_list) do
					if (ULib.ucl.query(ply,k)) then
						ply:ChatPrint(v)
					end
				end
				return true
			end
		end
		
		-- спавн разрешен
		local spawnmes = GetConVarNumber("metrostroi_spawn_message")
		if (spawnmes == 1) then
			local wag_str = "вагон"
			local wag_num = settings.WagNum
			if wag_num >= 2 and wag_num <= 4 then wag_str = "вагона" end
			if wag_num >= 5 then wag_str = "вагонов" end
			ulx.fancyLog("Игрок #s заспавнил #s #s #s.\nМестоположение: #s.",ply:Nick(),tostring(wag_num),wag_str,GetTrainName(settings.Train),GetTrainLoc(ply))
		end
		SetGlobalInt("TrainLastSpawned",os.time())
		return
	end
end)

hook.Add("MetrostroiLoaded","MetrostroiLoadEnd",function()
	SetGlobalInt("TrainLastSpawned",os.time())
end)