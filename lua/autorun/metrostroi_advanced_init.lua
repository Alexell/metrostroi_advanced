------------------------ Metrostroi Advanced -------------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_advanced
----------------------------------------------------------------------

if not Metrostroi or not Metrostroi.Version or Metrostroi.Version < 1537278077 then
	MsgC(Color(0,80,255),"[Metrostroi Advanced] Incompatible Metrostroi version detected. Addon DISABLED.\n")
	return
end

-- Создаем MetrostroiAdvanced глобально
MetrostroiAdvanced = MetrostroiAdvanced or {}
if SERVER then
	MetrostroiAdvanced.TrainList = {}
	MetrostroiAdvanced.StationsIgnore = {}
	MetrostroiAdvanced.MapWagons = {}
	MetrostroiAdvanced.MapButtonNames = {}
	MetrostroiAdvanced.TwoToSixMap = false
end

-- Загрузка локализации
function MetrostroiAdvanced.LoadLanguage(lang)
	if MetrostroiAdvanced.Lang then MetrostroiAdvanced.Lang = nil end
	if file.Exists("metrostroi_advanced/language/"..lang..".lua","LUA") then
		include("metrostroi_advanced/language/"..lang..".lua")
	else
		MsgC(Color(0,80,255),"[Metrostroi Advanced] Language file not found (lua/metrostroi_advanced/language/"..lang..".lua)\n")
		MsgC(Color(0,80,255),"[Metrostroi Advanced] Default language will be loaded (en)\n")
		include("metrostroi_advanced/language/en.lua")
	end

	if SERVER then
		file.Write("metrostroi_advanced/trains.txt","") -- очищаем файл с составами для перезаписи
		for _,class in pairs(Metrostroi.TrainClasses) do
			local ENT = scripted_ents.Get(class)
			if not class:find("717_ars_minsk") and (not ENT.Spawner or not ENT.SubwayTrain) then continue end
			file.Append("metrostroi_advanced/trains.txt",class.."\n")
			MetrostroiAdvanced.TrainList[class] = MetrostroiAdvanced.Lang[class] or ENT.PrintName or class
		end
	end
end

function MetrostroiAdvanced.FixedRoute(class,route)
	local classes = {"gmod_subway_em508","gmod_subway_81-702","gmod_subway_81-703","gmod_subway_81-705_old","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_ezh3ru1","gmod_subway_81-717_mvm","gmod_subway_81-718","gmod_subway_81-720","gmod_subway_81-720_1","gmod_subway_81-720a","gmod_subway_81-717_freight","gmod_subway_81-717_5a", "gmod_subway_81-717_ars_minsk", "gmod_subway_am"}
	local rnum = tonumber(route)
	if table.HasValue(classes, class) then
		rnum = rnum / 10
		route = rnum
	end
	return route
end

if SERVER then
	local function lang(str)
		return MetrostroiAdvanced.Lang[str]
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
			file.Write("metrostroi_advanced/map_wagons.txt","gm_jar_pll_remastered_v12 4\ngm_mustox_neocrimson_line_a 4\ngm_metro_crossline_n3 6\ngm_metro_crossline_r199h 6\ngm_mus_loopline_e 5\ngm_metro_ruralline_v29 4\ngm_metro_jar_imagine_line_v4 6\ngm_mus_neoorange_e 3\ngm_metro_surfacemetro_w 4\ngm_metro_virus 6\ngm_metro_mosldl_v1 8\ngm_metro_nsk_line_2_v7 4\ngm_metro_nekrasovskaya_line_v6 5\ngm_metro_kalinin_v3 5\ngm_smr_1987 4\ngm_metro_lightrail_v2a 4\ngm_metro_minsk_1984 5\ngm_metro_chapaevskaya_line_redux 5\ngm_metro_krl_v1 6\ngm_metro_kaluzhskaya_line6 6")
		end
		local mapwagons = string.Explode("\n",file.Read("metrostroi_advanced/map_wagons.txt","DATA"))
		for _,str in pairs(mapwagons) do
			local tbl = string.Explode(" ",str)
			if tbl[1] ~= "" and tonumber(tbl[2]) then
				MetrostroiAdvanced.MapWagons[tbl[1]] = tonumber(tbl[2]) or nil
			end
		end
	end
	
	-- Определяем тип сигнализации на карте
	function MetrostroiAdvanced.GetSignallingType()
		local type26 = 0
		local type15 = 0
		for k, v in pairs(Metrostroi.Stations) do 
			for a, b in pairs(v) do 
				local signal = Metrostroi.GetARSJoint(b.node_start, b.x_start, true)
				if IsValid(signal) then
					if signal.TwoToSix == true then
						type26 = type26 + 1
					else
						type15 = type15 + 1
					end
				end
			end
		end
		if type26 > 0 and type15 == 0 then MetrostroiAdvanced.TwoToSixMap = true end
	end

	-- отцентровка точек для поиска станций 
	function MetrostroiAdvanced.CenteringStationPositions()
		if not Metrostroi.StationConfigurations then return end
		local centre
		for k1, v1 in pairs(ents.FindByClass("gmod_track_platform")) do
			if not Metrostroi.StationConfigurations[v1.StationIndex] then continue end
			for k2, v2 in pairs(ents.FindByClass("gmod_track_platform")) do
				if v1.StationIndex == v2.StationIndex and v1.PlatformIndex == 1 and v2.PlatformIndex == 2 then
					local pos1 = LerpVector(0.5, v1.PlatformStart, v2.PlatformStart)
					local pos2 = LerpVector(0.5, v1.PlatformEnd, v2.PlatformEnd)
					if isvector(pos1) and isvector(pos2) then 
						centre = LerpVector(0.5, pos1, pos2) 
					end
					if isvector(centre) and istable(Metrostroi.StationConfigurations[v1.StationIndex].positions) then
						table.insert(Metrostroi.StationConfigurations[v1.StationIndex].positions, 2, {centre, Angle(0, 0, 0)})
					end
				end
			end
		end
	end

	-- путь по названию сигнала
	local function PathBySignalName(signal)
		if not signal.Name then return nil end
		if tonumber(signal.Name) then return signal.Name end
		local namesub = string.sub(signal.Name,-1)
		local namesub2 = string.sub(signal.Name,-2,-2)
		if tonumber(namesub) then
			return namesub
		elseif tonumber(namesub2) then 
			return namesub2 
		else
			return nil 
		end
	end

	-- исправляем пути на платформах
	function MetrostroiAdvanced.DefinePlatformPaths()
		print("MA: Processing true platform paths definition ...")
		for k, v in pairs(Metrostroi.Stations) do 
			for a, b in pairs(v) do 
				-- b.x_start -- координаты начала платформы
				-- b.x_end -- координаты конца платформы
				-- b.length -- длина платформы
				-- b.node_start -- node начала платформы
				-- b.node_end -- node конца платформы
				-- b.ent -- энтити платформы
				if b.ent.PlatformIndex > 2 then continue end
				local center_point = Metrostroi.GetPositionOnTrack(LerpVector(0.5, b.ent.PlatformStart, b.ent.PlatformEnd))
				local signal = Metrostroi.GetARSJoint(b.node_start, b.x_start, true)
				local path = tonumber(signal.RouteNumber) and signal.RouteNumber or PathBySignalName(signal)
				if not IsValid(signal) or not path then
					signal = Metrostroi.GetARSJoint(b.node_end, b.x_end, true)
					path = tonumber(signal.RouteNumber) and signal.RouteNumber or PathBySignalName(signal)
				end
				if IsValid(signal) and path then 
					path = path % 2 == 0 and 2 or 1
					if path != b.ent.PlatformIndex then
						b.ent.PlatformIndex = path
						b.ent:SetNWInt("PlatformIndex", path)
						b.ent.TrackPos = center_point[1].x
						b.ent.TrackID = center_point[1].path.id
						b.ent.PlatformLen = b.ent.PlatformStart:DistToSqr(b.ent.PlatformEnd)
						b.ent.PlatformLenX = math.abs(b.x_start - b.x_end)
					end
				end
			end 
		end
		Metrostroi.UpdateStations()
	end

	-- Кнопки на картах
	function MetrostroiAdvanced.LoadMapButtons()
		local source_data = [[
{
	"gm_metro_kalinin_v3":
   {
		"mr_ao_b": "[Марксистская] АО ВКЛ",
		"mr_b_nb": "[Марксистская] Табло ПОСАДКИ НЕТ",
		"mr_b_sw1-": "[Марксистская] Стрелка 1-",
		"mr_b_sw1+": "[Марксистская] Стрелка 1+",				
		"mr_b_sw2-": "[Марксистская] Стрелка 2-",
		"mr_b_sw2+": "[Марксистская] Стрелка 2+",
		"se_ao_b": "[Шоссе Энт-ов] АО ВКЛ/ВЫКЛ",
		"se_b_sw1+": "[Шоссе Энт-ов] Стрелка 1+",
		"se_b_sw1-": "[Шоссе Энт-ов] Стрелка 1-",
		"se_b_sw2+": "[Шоссе Энт-ов] Стрелка 2+",
		"se_b_sw2-": "[Шоссе Энт-ов] Стрелка 2-",
		"se_b_nb": "[Шоссе Энт-ов] Табло ПОСАДКИ НЕТ",
		"se_b_sw3-": "[Шоссе Энт-ов] Стрелка 3-",
		"se_b_sw3+": "[Шоссе Энт-ов] Стрелка 3+",
		"kgu_b_on": "[Шоссе Энт-ов] КГУ ВКЛ",
		"kgu_b_off": "[Шоссе Энт-ов] КГУ ВЫКЛ",
		"kgu_b_reset": "[Шоссе Энт-ов] КГУ ВОССТ.",
		"nv_b_nb": "[Новогиреево] Табло ПОСАДКИ НЕТ",
		"nv_b_sw1+": "[Новогиреево] Стрелка 1+",
		"nv_b_sw1-": "[Новогиреево] Стрелка 1-",
		"nv_b_sw2+": "[Новогиреево] Стрелка 2+",
		"nv_b_sw2-": "[Новогиреево] Стрелка 2-",
		"nv_b_sw3+": "[Новогиреево] Стрелка 3+",
		"nv_b_sw3-": "[Новогиреево] Стрелка 3-",
		"nv_b_sw5+": "[Новогиреево] Стрелка 5+",
		"nv_b_sw5-": "[Новогиреево] Стрелка 5-",
		"nv_b_sw4+": "[Новогиреево] Стрелка 4+",
		"nv_b_sw4-": "[Новогиреево] Стрелка 4-",
		"nv_b_sw6+": "[Новогиреево] Стрелка 6+",
		"nv_b_sw6-": "[Новогиреево] Стрелка 6-",
		"nv_b_ad4_on": "[Новогиреево] АО 4 путь ВКЛ",
		"nv_b_ad4_off": "[Новогиреево] АО 4 путь ВЫКЛ",
		"nv_b_ad3_on": "[Новогиреево] АО 3 путь ВКЛ",
		"nv_b_ad3_off": "[Новогиреево] АО 3 путь ВЫКЛ",
		"tr_b_sw3+": "[Третьяковская] Стрелка 3+",
		"tr_b_sw3-": "[Третьяковская] Стрелка 3-",
		"tr_b_sw1+": "[Третьяковская] Стрелка 1+",
		"tr_b_sw1-": "[Третьяковская] Стрелка 1-",
		"tr_b_sw2+": "[Третьяковская] Стрелка 2+",
		"tr_b_sw2-": "[Третьяковская] Стрелка 2-",
		"tr_b_ad3_on": "[Третьяковская] АО ВКЛ",
		"tr_b_ad3_off": "[Третьяковская] АО ВЫКЛ",
		"nk_b_nb": "[Новокосино] Табло ПОСАДКИ НЕТ",
		"nk_b_ad3_on": "[Новокосино] АО 3 путь ВКЛ",
		"nk_b_ad3_off": "[Новокосино] АО 3 путь ВЫКЛ",
		"nk_b_ad4_on": "[Новокосино] АО 4 путь ВКЛ",
		"nk_b_ad4_off": "[Новокосино] АО 4 путь ВЫКЛ",
		"nk_b_sw6+": "[Новокосино] Стрелка 6+",
		"nk_b_sw6-": "[Новокосино] Стрелка 6-",
		"nk_b_sw4+": "[Новокосино] Стрелка 4+",
		"nk_b_sw4-": "[Новокосино] Стрелка 4-",
		"nk_b_sw2+": "[Новокосино] Стрелка 2+",
		"nk_b_sw2-": "[Новокосино] Стрелка 2-",
		"nk_b_sw1+": "[Новокосино] Стрелка 1+",
		"nk_b_sw1-": "[Новокосино] Стрелка 1-",
		"nk_b_sw3+": "[Новокосино] Стрелка 3+",
		"nk_b_sw3-": "[Новокосино] Стрелка 3-",
		"nk_b_sw5+": "[Новокосино] Стрелка 5+",
		"nk_b_sw5-": "[Новокосино] Стрелка 5-"
   }
}]]

		if not file.Exists("metrostroi_advanced/map_buttons.txt","DATA") then
			file.Write("metrostroi_advanced/map_buttons.txt",source_data)
		end
		
		local fl = file.Read("metrostroi_advanced/map_buttons.txt","DATA")
		local tab = fl and util.JSONToTable(fl) or {}
		MetrostroiAdvanced.MapButtonNames = tab[game.GetMap()] or {}
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
	function MetrostroiAdvanced.GetLocation(pos)
		local ent_station = lang("UnknownPlace")
		local map_pos
		local radius = 4000 -- Радиус по умолчанию для станций на всех картах
		local cur_map = game.GetMap()
		local Sz
		local S
		local train_pos = pos
		
		radius = radius*radius

		if Metrostroi.StationConfigurations then
			for k, v in pairs(Metrostroi.StationConfigurations) do
				if isnumber(k) and v.positions[2] then 
					map_pos = v.positions and v.positions[2] 
				else 
					map_pos = v.positions and v.positions[1] 
				end
				if cur_map:find("gm_metro_jar_imagine_line") then
					if v.names[1] == "ДДЭ" or v.names[1] == "Диспетчерская" then continue end
				end
				if map_pos then
					S = train_pos:DistToSqr(map_pos[1])
					if (train_pos.z > 0 and map_pos[1].z < 0) or (train_pos.z < 0 and map_pos[1].z > 0) then
						Sz = math.abs(train_pos.z) + math.abs(map_pos[1].z)
					end
					if (train_pos.z > 0 and map_pos[1].z > 0) or (train_pos.z < 0 and map_pos[1].z < 0) then
						Sz = math.abs(train_pos.z - map_pos[1].z)
					end
					if S < radius and Sz < 200 then 
						ent_station = v.names[1]
						radius = S
					end
				end
			end
		else
			ent_station = "N/A"
		end
		return ent_station
	end

	-- Получение уникального рандомного номера маршрута
	function MetrostroiAdvanced.GetRouteNumber(ply)
		local rnum = math.random(1,99)
		local routes = {}
		for train in pairs(Metrostroi.SpawnedTrains) do
			if not IsValid(train) then continue end
			if not MetrostroiAdvanced.TrainList[train:GetClass()] then continue end
			local cl = train:GetClass()
			local owner = train.Owner
			if not IsValid(owner) then continue end
			if owner == ply then continue end
			local rnum2 = 0
			if cl:find("722") or cl:find("7175p") then
				if train.RouteNumberSys then
					rnum2 = tonumber(train.RouteNumberSys.RouteNumber)
				end
			elseif cl:find("717_6") or cl:find("740_4") then
				if train.ASNP then
					rnum2 = train.ASNP.RouteNumber
				end
			else
				if train.RouteNumber then
					rnum2 = tonumber(train.RouteNumber.RouteNumber)
				end
			end
			if rnum2 == 0 then continue end
			rnum2 = MetrostroiAdvanced.FixedRoute(cl,rnum2)
			routes[owner:Nick()] = rnum2
		end
		if #routes > 0 then
			local r2 = {}
			for k,v in pairs(routes) do
				r2[#r2+1] = v
			end
			
			for k,v in pairs(r2) do
				if rnum == v then
					rnum = math.random(1,99)
					k = 1
				end	
			end
		end
		return rnum
	end

	function MetrostroiAdvanced.IsHeadWagon(ent)
		if (not IsValid(ent)) then return false end
		if (not MetrostroiAdvanced.TrainList[ent:GetClass()]) then return false end -- только головные
		local class = ent:GetClass()
		if class:find("760") then
			if ent.RV.KROPosition ~= 0 then
				return true
			end
		elseif class:find("722") then
			if ent.Electric.CabActive ~= 0 then
				return true
			end
		elseif class:find("720") then
			if ent.WrenchMode ~= 0 then
				if ent.RV.KROPosition ~= 0 then
					return true
				end
			end
		elseif class:find("718") then
			if ent.WrenchMode ~= 0 then
				if ent.KR.Position ~= 0 then
					return true
				end
			end
		else
			if ent.KVWrenchMode ~= 0 then
				if ent.KV.ReverserSet ~= 0 then
					return true
				end
			end
		end
		return false
	end
	
	-- Получение установленной конечной из информатора/табло/трафарета поезда
	function MetrostroiAdvanced.GetLastStationID(train)
		if game.GetMap():find("gm_metro_crossline") then return -1 end -- там нет трафаретов + с конфигами ЦИС и списком станций все через жопу
		if game.GetMap():find("gm_metro_nsk_line") then return -1 end -- там нет трафаретов, информаторов и конфига ЦИС
		if game.GetMap():find("gm_smr_1987") then return -1 end -- трафареты есть, но пустые
		
		if not IsValid(train) then return -1 end
		local station = -1
		
		if train:GetClass() == "gmod_subway_am" or train:GetClass() == "gmod_subway_ap" then return -1 end
		
		-- 81-540.2K
		if train:GetClass():find("540_2k",1,true) and train.ASNP then
			if (train:GetNW2String("Inf:Tablo1") == "обкатка" or train:GetNW2String("Inf:Tablo1") == "перегонка") then return 1111 end
			-- у меня на табло станци не отображаются, будем брать с информатора
			if train.ASNP.State < 2 then return 1111 end
			local tbl = Metrostroi.ASNPSetup[train:GetNW2Int("Announcer",1)] and Metrostroi.ASNPSetup[train:GetNW2Int("Announcer",1)][train.ASNP.Line]
			if tbl and tbl.Loop then tbl = nil return -1 end -- информатор не стандартный, как его настраивать не понятно
			station = tbl and tbl[train.ASNP.Path and train.ASNP.FirstStation or train.ASNP.LastStation][1] or -1
			tbl = nil
		end
		
		-- 81-* трафареты
		if (station == -1 and train.LastStation and train.LastStation.ID and train.LastStation.TableName) then
			station = table.KeyFromValue(Metrostroi.Skins[train.LastStation.TableName],(tonumber(train.LastStation.ID) == 0 and 1 or train.LastStation.ID)) or -1 -- по ID 0 в Metrostroi.Skins ничего не находит
			if station == "" and game.GetMap():find("gm_mus_loop") then return -1 end -- для таблички "Кольцевой" на MSS
		end
		
		-- 81-720.1, 81-717.5A и 81-740.4 (только ASNP)
		if (station == -1 and (train:GetClass():find("720_1") or train:GetClass():find("717_5a") or train:GetClass():find("740_4")) and train.ASNP) then
			if train.ASNP.State < 7 then return 1111 end
			local tbl = Metrostroi.ASNPSetup[train:GetNW2Int("Announcer",1)] and Metrostroi.ASNPSetup[train:GetNW2Int("Announcer",1)][train.ASNP.Line]
			if tbl and (tbl.Loop and train.ASNP.LastStation == 0) then tbl = nil return -1 end -- когда выбран "Кольцевой", срабатывать не будет
			station = tbl and tbl[train.ASNP.Path and train.ASNP.FirstStation or train.ASNP.LastStation][1] or -1
			tbl = nil
		end
		
		-- 81-722
		if (station == -1 and train:GetClass():find("722") and train.SarmatUPO) then
			if train.SarmatUPO.Line < 1 then return 1111 end -- сервисная надпись табло
			local tbl = Metrostroi.SarmatUPOSetup[train:GetNW2Int("Announcer",1)] and Metrostroi.SarmatUPOSetup[train:GetNW2Int("Announcer",1)][train.SarmatUPO.Line]
			if tbl and (tbl.Loop and train.SarmatUPO.LastStationName == "Кольцевой") then tbl = nil return -1 end
			station = tbl and tbl[train.SarmatUPO.Path and train.SarmatUPO.StartStation or train.SarmatUPO.EndStation][1] or -1
			tbl = nil
		end
		
		-- 81-* LVZ (на остальных нельзя выбирать конечную и нет трафаретов)
		
		-- 81-760
		if (station == -1 and train:GetClass():find("760") and train.BMCIS) then
			if train.BMCIS.Line < 1 then return 1111 end -- сервисная надпись табло
			if train.BMCIS.State1 < 7 then return 1111 end
			local tbl = Metrostroi.CISConfig[train.CISConfig] and Metrostroi.CISConfig[train.CISConfig][train.BMCIS.Line]
			if tbl and (tbl.Loop and train.BMCIS.LastStationEntered == 0) then return -1 end
			station = tbl and (train.BMCIS.LastStationEntered == 0 and (train.BMCIS.Path and tbl[train.BMCIS.FirstStation][1] or tbl[train.BMCIS.LastStation][1]) or tbl[train.BMCIS.laststbl[train.BMCIS.LastStationEntered]][1]) or -1
			tbl = nil
		end
		return tonumber(station,10) or 1111 -- любой трафарет со строковым индексом будет считаться сервисным
	end
	
	-- Проверяем, является ли полученный id станции реальной конечной (т.е. первой или последней станцией на линии)
	function MetrostroiAdvanced.IsRealLastStation(id)
		if not Metrostroi.StationConfigurations then return true end
		if game.GetMap():find("pll_remastered_v") then return table.HasValue({150,156,157,159},id) end -- костыль, т.к. id станций обеих линий в одной сотне
		if game.GetMap():find("mus_neoorange") then return table.HasValue({401,411,451,462},id) end -- костыль, т.к. у трафаретов id отличаются от id в платформах
		local s_id = math.floor(id/100)
		local station_ids = {}
		for k,v in pairs(Metrostroi.StationConfigurations) do
			if not isnumber(k) then continue end
			if (math.floor(k/100) == s_id) then table.insert(station_ids,k) end -- собираем ids с той же линии, если их две
		end
		table.SortDesc(station_ids)
		if (id == station_ids[1] or id == station_ids[#station_ids]) then return true else return false end
	end
	
	-- Обработка команд сигнализации с выводами в чат
	function MetrostroiAdvanced.SignalSayHook(ply,comm,Name,fromULX)
		if ulx and not fromULX then return end
		if not IsValid(ply) then return end
		if comm == "!sactiv" then
			local route_found = false
			local route_opened = false
			local names = ""
			for _, ent in pairs(ents.FindByClass("gmod_track_signal")) do
				if ent.Routes then
					for RouteID, RouteInfo in pairs(ent.Routes) do
						if (RouteInfo.RouteName and RouteInfo.RouteName:upper() == Name:upper() or Name == "*") and RouteInfo.Emer then
							route_found = true
							if ent.LastOpenedRoute and k != ent.LastOpenedRoute then ent:CloseRoute(ent.LastOpenedRoute) end
							if not RouteInfo.IsOpened then
								RouteInfo.IsOpened = true
								route_opened = true
							end
							if names == "" then names = ent.Name
							else names = names ..", "..ent.Name 
							end
						end
					end
				end    
			end
			if route_found and route_opened then
				timer.Simple(0.2, function()
					if GetConVar("metrostroi_advanced_signalsmessage"):GetInt() == 1 then
						ulx.fancyLog("#s "..lang("OpenedEmerRoute").." #s.", ply:Nick(), names)
					end
				end)	 	
			elseif route_found and not route_opened then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("EmerRoute").." "..names.." "..lang("AlreadyEnabled")..".")
				end)	 
			end		
			if not route_found then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("EmerRoute").." "..names.." "..lang("NotFound")..".")
				end)
			end
		elseif comm == "!sdeactiv" then
			local route_found = false
			local route_closed = false
			local names = ""
			for _, ent in pairs(ents.FindByClass("gmod_track_signal")) do
				if ent.Routes then
					for RouteID, RouteInfo in pairs(ent.Routes) do
						if (RouteInfo.RouteName and RouteInfo.RouteName:upper() == Name:upper() or Name == "*") and RouteInfo.Emer then
							route_found = true
							if ent.LastOpenedRoute and k != ent.LastOpenedRoute then ent:CloseRoute(ent.LastOpenedRoute) end
							if RouteInfo.IsOpened then
								RouteInfo.IsOpened = false
								route_closed = true
							end
							if names == "" then names = ent.Name
							else names = names ..", "..ent.Name 
							end
						end
					end
				end    
			end
			if route_found and route_closed then
				timer.Simple(0.2, function()
					if GetConVar("metrostroi_advanced_signalsmessage"):GetInt() == 1 then
						ulx.fancyLog("#s "..lang("ClosedEmerRoute").." #s.", ply:Nick(), names)
					end
				end)	 	
			elseif route_found and not route_closed then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("EmerRoute").." "..names.." "..lang("AlreadyDisabled")..".")
				end) 
			end		
			if not route_found then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("EmerRoute").." "..names.." "..lang("NotFound")..".")
				end)
			end
		elseif comm == "!sclose" then
			local signal_found = false
			local signal_closed = false
			local route_found = false
			local route_closed = false
			for _, ent in pairs(ents.FindByClass("gmod_track_signal")) do
				if ent.Name == Name:upper() then
					signal_found = true
					if #ent.Routes == 1 and ent.Routes[1].Manual then
						ent:CloseRoute(1)
						signal_closed = true
					else
						if not ent.Close then
							ent.Close = true
							signal_closed = true
						end
						
						if ent.InvationSignal then
							ent.InvationSignal = false
							signal_closed = true
						end
						
						if (ent.LastOpenedRoute and ent.LastOpenedRoute == 1) or ent.Routes[1].Repeater then
							ent:CloseRoute(1)
							signal_closed = true
						else
							ent:OpenRoute(1)
						end
					end
				elseif #ent.Routes >= 1 then
					for RouteID, RouteInfo in pairs(ent.Routes) do
						if RouteInfo.RouteName and RouteInfo.RouteName:upper() == Name:upper() then
							route_found = true
							if ent.LastOpenedRoute and ent.LastOpenedRoute == RouteID then
								ent:CloseRoute(RouteID)
								ent.LastOpenedRoute = 0
								route_closed = true	
							end
						end
					end
				end		
			end
			if signal_found and signal_closed then
				timer.Simple(0.2, function()
					if GetConVar("metrostroi_advanced_signalsmessage"):GetInt() == 1 then
						ulx.fancyLog("#s "..lang("ClosedSignal").." #s.", ply:Nick(), Name:upper())
					end
				end)	 	
			elseif signal_found and not signal_closed then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("Signal").." "..Name:upper().." "..lang("AlreadyClosed")..".")
				end)	 
			end
			if route_found and route_closed then
				timer.Simple(0.2, function()
					if GetConVar("metrostroi_advanced_signalsmessage"):GetInt() == 1 then
						ulx.fancyLog("#s "..lang("ClosedRoute").." #s.", ply:Nick(), Name:upper())
					end
				end)	 	
			elseif route_found and not route_closed then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("Route").." "..Name:upper().." "..lang("AlreadyClosed")..".")
				end)	 
			end		
			if not route_found and not signal_found then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("SignalOrRoute").." "..Name:upper().." "..lang("NotFound")..".")
				end)	 	
			end
		elseif comm == "!sopen" then
			local signal_found = false
			local signal_opened = false
			local route_found = false
			local route_opened = false
			for _, ent in pairs(ents.FindByClass("gmod_track_signal")) do
				if ent.Name == Name:upper() then
					signal_found = true
					if #ent.Routes == 1 and ent.Routes[1].Manual then
						ent:OpenRoute(1)
						signal_opened = true
					elseif ent.Close then
						ent.Close = false
						signal_opened = true
					end
				elseif #ent.Routes >= 1 then
					for RouteID, RouteInfo in pairs(ent.Routes) do
						if RouteInfo.RouteName and RouteInfo.RouteName:upper() == Name:upper() then
							route_found = true
							if ent.Route != RouteID or not RouteInfo.IsOpened then
								ent:OpenRoute(RouteID) 
								route_opened = true
							end
						end
					end
				end
			end	
			if signal_found and signal_opened then
				timer.Simple(0.2, function()
					if GetConVar("metrostroi_advanced_signalsmessage"):GetInt() == 1 then
						ulx.fancyLog("#s "..lang("OpenedSignal").." #s.", ply:Nick(), Name:upper())
					end
				end)	 	
			elseif signal_found and not signal_opened then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("Signal").." "..Name:upper().." "..lang("AlreadyOpened")..".")
				end)	 
			end
			if route_found and route_opened then
				timer.Simple(0.2, function()
					if GetConVar("metrostroi_advanced_signalsmessage"):GetInt() == 1 then
						ulx.fancyLog("#s "..lang("OpenedRoute").." #s.", ply:Nick(), Name:upper())
					end
				end)	 	
			elseif route_found and not route_opened then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("Route").." "..Name:upper().." "..lang("AlreadyOpened")..".")
				end)	 
			end	
			if not route_found and not signal_found then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("SignalOrRoute").." "..Name:upper().." "..lang("NotFound")..".")
				end)	 	
			end
		elseif comm == "!sopps" then
			local signal_found = false
			local signal_opened = false
			for _, ent in pairs(ents.FindByClass("gmod_track_signal")) do
				if ent.Name == Name:upper() then
					signal_found = true
					if not ent.InvationSignal and ent.GoodInvationSignal != 0 then
						ent.InvationSignal = true
						signal_opened = true
					end
				end
			end	
			if signal_found and signal_opened then
				timer.Simple(0.2, function()
					if GetConVar("metrostroi_advanced_signalsmessage"):GetInt() == 1 then
						ulx.fancyLog("#s "..lang("OpenedIS").." #s.", ply:Nick(), Name:upper())
					end
				end)
			elseif not signal_found then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("Signal").." "..Name:upper().." "..lang("NotFound")..".")
				end)
			end
		elseif comm == "!sclps" then
			local signal_found = false
			local signal_closed = false
			for _, ent in pairs(ents.FindByClass("gmod_track_signal")) do
				if ent.Name == Name:upper() then
					signal_found = true
					if ent.InvationSignal and ent.GoodInvationSignal != 0 then
						ent.InvationSignal = false
						signal_closed = true
					end
				end
			end	
			if signal_found and signal_closed then
				timer.Simple(0.2, function()
					if GetConVar("metrostroi_advanced_signalsmessage"):GetInt() == 1 then
						ulx.fancyLog("#s "..lang("ClosedIS").." #s.", ply:Nick(), Name:upper())
					end
				end)
			elseif not signal_found then
				timer.Simple(0.2, function() 
					ply:ChatPrint(lang("Signal").." "..Name:upper().." "..lang("NotFound")..".")
				end)
			end
		elseif Metrostroi.Version > 1537278077 then
			if comm == "!senao" then
				local signal_found = false
				local ao_changed = false
				for _, ent in pairs(ents.FindByClass("gmod_track_signal")) do
					if ent.Name == Name:upper() then
						signal_found = true
						if ent.AODisabled then ent.AODisabled = false ao_changed = true end
					end
				end
				if signal_found and ao_changed then
					timer.Simple(0.2, function()
						if GetConVar("metrostroi_advanced_signalsmessage"):GetInt() == 1 then
							ulx.fancyLog("#s "..lang("EnabledAS").." #s.", ply:Nick(), Name:upper())
						end
					end)
				elseif not signal_found then
					timer.Simple(0.2, function() 
						ply:ChatPrint(lang("Signal").." "..Name:upper().." "..lang("NotFound")..".")
					end)
				end
			elseif comm == "!sdisao" then
				local signal_found = false
				local ao_changed = false
				for _, ent in pairs(ents.FindByClass("gmod_track_signal")) do
					if ent.Name == Name:upper() then
						signal_found = true
						if ent.ARSSpeedLimit == 2 then ent.AODisabled = true ao_changed = true end
					end
				end
				if signal_found and ao_changed then
					timer.Simple(0.2, function()
						if GetConVar("metrostroi_advanced_signalsmessage"):GetInt() == 1 then
							ulx.fancyLog("#s "..lang("DisabledAS").." #s.", ply:Nick(), Name:upper())
						end
					end)
				elseif not signal_found then
					timer.Simple(0.2, function() 
						ply:ChatPrint(lang("Signal").." "..Name:upper().." "..lang("NotFound")..".")
					end)
				end
			end
		end
	end
end --SERVER

-- Подключение файлов
if SERVER then
	-- отправка локалей на клиент
	for k, fl in pairs(file.Find("metrostroi_advanced/language/*.lua","LUA")) do
		AddCSLuaFile("metrostroi_advanced/language/"..fl)
	end
	
	include("metrostroi_advanced/sv_metrostroi_advanced.lua")
	include("metrostroi_advanced/metrostroi_map_fixes.lua")
	AddCSLuaFile("metrostroi_advanced/cl_metrostroi_advanced.lua")
	resource.AddWorkshop("1838480881")
end

if CLIENT then
	include("metrostroi_advanced/cl_metrostroi_advanced.lua")
end