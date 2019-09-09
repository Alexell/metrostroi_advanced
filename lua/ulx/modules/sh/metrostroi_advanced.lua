----------------- Metrostroi Advanced -----------------
-- Авторы: Alexell и Agent Smith
-- Версия: 1.0
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_advanced
-------------------------------------------------------

local CATEGORY_NAME = "Metrostroi Advanced"

local train_list = {}
train_list["gmod_subway_81-502"] 			= "81-502 (Ема-502)"
train_list["gmod_subway_81-702"] 			= "81-702 (Д)"
train_list["gmod_subway_81-703"] 			= "81-703 (E)"
train_list["gmod_subway_ezh"] 				= "81-707 (Еж)"
train_list["gmod_subway_ezh3"] 				= "81-710 (Еж3)"
train_list["gmod_subway_ezh3ru1"] 			= "81-710 (Еж3 РУ1)"
train_list["gmod_subway_81-717_mvm"] 		= "81-717 (Номерной МСК)"
train_list["gmod_subway_81-717_mvm_custom"] = "81-717 (Номерной МСК)"
train_list["gmod_subway_81-717_lvz"] 		= "81-717 (Номерной СПБ)"
train_list["gmod_subway_81-717_6"] 			= "81-717.6"
train_list["gmod_subway_81-718"] 			= "81-718 (ТИСУ)"
train_list["gmod_subway_81-720"] 			= "81-720 (Яуза)"
train_list["gmod_subway_81-722"] 			= "81-722 (Юбилейный)"
--train_list["gmod_subway_81-760"] 			= "81-760 (Ока)"

-- Получение местоположения состава
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

-- Вывод станций в чат
local stswaittime = 10
local stslasttime = -stswaittime
function ulx.sts( calling_ply )
	if stslasttime + stswaittime > CurTime() then
		ULib.tsayError( calling_ply, "Пожалуйста подождите " .. math.Round(stslasttime + stswaittime - CurTime()) .. " секунд перед использованием этой команды снова!", true )
		return
	end
	stslasttime = CurTime()
	for k,v in pairs(Metrostroi.StationConfigurations) do
		ULib.tsayColor(nil,false,Color(219, 116, 32),k.." - "..v.names[1])
	end
end
local sts = ulx.command(CATEGORY_NAME, "ulx stations", ulx.sts, "!stations" )
sts:defaultAccess( ULib.ACCESS_ALL )
sts:help( "Список станций на карте." )

-- Замена !station
function ulx.tps( calling_ply,station )
        station = string.PatternSafe(station:lower())

        --Обработка сообщений вида станция:номер для станций, которые имеют несколько позиций
        local add = 0
        if station:find("[^:]+:%d+$") then
            local st,en = station:find(":%d+$")
            add = tonumber(station:sub(st+1,en))
            station = station:sub(1,st-1)
        end

        --Проверка на наличие таблицы
        if not Metrostroi.StationConfigurations then ULib.tsayError( calling_ply, "Карта не сконфигурирована!", true ) return end

        --Создание массива найденых станций по индкесу станции или куска имени
        local st = {}
        for k,v in pairs(Metrostroi.StationConfigurations) do
            if not v.positions then continue end
            if v.names then
                for _,stat in pairs(v.names) do
                    if stat:lower():find(station) then
                        table.insert(st,k)
                        break
                    end
                end
            end
            if tostring(k):find(station) then
                table.insert(st,k)
            end
        end

        if #st == 0 then
            ULib.tsayError( calling_ply, Format("Станция не найдена: %s",station), true )
            return
        elseif #st > 1 then
            ULib.tsayError( calling_ply,  Format("Найдено больше одной станции по запросу %s:",station), true )
            for k,v in pairs(st) do
                local tbl = Metrostroi.StationConfigurations[v]
                if tbl.names and tbl.names[1] then
                    ULib.tsayError( calling_ply, Format("\t%s=%s",v,tbl.names[1]), true )
                else
                    ULib.tsayError( calling_ply, Format("\t%s",k), true )
                end
            end
            ULib.tsayError( calling_ply, "Введите более точное название или ID станции!", true )
            return
        end
        local key = st[1]
        st = Metrostroi.StationConfigurations[key]
        local ptbl
        if add > 0 then
            local pos = st.positions
            ptbl = pos[math.min(#pos,add+1)]
        else
            ptbl = st.positions and st.positions[1]
        end
        if IsValid(calling_ply) then
            if ptbl and ptbl[1] then
                if calling_ply:InVehicle() then calling_ply:ExitVehicle() end
                calling_ply.ulx_prevpos = calling_ply:GetPos()--ulx return
                calling_ply.ulx_prevang = calling_ply:EyeAngles()
                calling_ply:SetPos(ptbl[1])
                calling_ply:SetAngles(ptbl[2])
                calling_ply:SetEyeAngles(ptbl[2])
                ulx.fancyLogAdmin( calling_ply, "#A телепортировался на станцию #s", st.names and st.names[1] or key)
            else
                ULib.tsayError( calling_ply, "Ошибка конфигурации для станции "..key, true )
                ulx.fancyLogAdmin( calling_ply, "Ошибка конфигурации для станции #s", key)
            end

        else
            if ptbl and ptbl[1] then
                print(Format("DEBUG1:Teleported to %s(%s) pos:%s ang:%s",st.names and st.names[1] or key,key,ptbl[1],ptbl[2]))
            else
                ulx.fancyLogAdmin( calling_ply, "Ошибка конфигурации для станции #s", station:gsub("^%l", string.upper))
            end
        end
end
local tps = ulx.command(CATEGORY_NAME, "ulx station", ulx.tps, "!station" )
tps:addParam{ type=ULib.cmds.StringArg, hint="Станция или ее номер", ULib.cmds.takeRestOfLine }
tps:defaultAccess( ULib.ACCESS_ALL )
tps:help( "Телепорт по станциям." )

-- Замена !trains
local wagonswaittime = 10
local wagonslasttime = -wagonswaittime
function ulx.wagons( calling_ply )
    if wagonslasttime + wagonswaittime > CurTime() then
        ULib.tsayError( calling_ply, "Пожалуйста подождите " .. math.Round(wagonslasttime + wagonswaittime - CurTime()) .. " секунд перед использованием этой команды снова!", true )
        return
    end

    wagonslasttime = CurTime()

    ulx.fancyLog("Вагонов на сервере: #s", Metrostroi.TrainCount())
    if CPPI then
        local Wags = {}
		local Trains = {}
		local Routes = {}
		local Locs = {}
		local ply_name = ""
		local tr_name = ""
		local r_num = ""
		local wag_num = 0
		local wag_str = "вагон"
		local inf
		local f_st = ""
		local c_st = ""
		local l_st = ""
		local tr_loc = ""

        for k,v in pairs(Metrostroi.TrainClasses) do
			if v == "gmod_subway_base" then continue end
            local ents = ents.FindByClass(v)
            for k2,v2 in pairs(ents) do
				-- подсчет кол-ва вагонов
                Wags[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] = (Wags[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] or 0) + 1
				-- запись типов составов
				if (Trains[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] == nil) then Trains[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] = train_list[v2:GetClass()] end
				-- запись номеров маршрутов
				if (Routes[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] == nil) then
					if (v2:GetNW2String("RouteNumber") != "") then
						local rnum = tonumber(v2:GetNW2String("RouteNumber"))
						if table.HasValue({"gmod_subway_81-702","gmod_subway_81-703","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_81-717_mvm","gmod_subway_81-717_mvm_custom","gmod_subway_81-718","gmod_subway_81-720"},v2:GetClass()) then rnum = rnum / 10 end
						Routes[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] = tostring(rnum)
					else
						Routes[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] = "0"
					end
				end
				-- запись местоположения
				if (Locs[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] == nil) then
					Locs[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] = GetTrainLoc(v2)
				end

            end
        end

        for k,v in pairs(Wags) do
			if (type(k) == "Player" and IsValid(k)) then
				ply_name = k:GetName()
				wag_num = tonumber(v)
				if wag_num >= 2 and wag_num <= 4 then wag_str = "вагона" end
				if wag_num >= 5 then wag_str = "вагонов" end
				-- составы
				for k2,v2 in pairs(Trains) do
					if (type(k2) == "Player" and IsValid(k2) and k2:GetName() == k:GetName()) then tr_name = v2 end
				end
				-- номера маршрутов
				for k3,v3 in pairs(Routes) do
					if (type(k3) == "Player" and IsValid(k3) and k3:GetName() == k:GetName()) then r_num = v3 end
				end
				-- мастоположения
				for k4,v4 in pairs(Locs) do
					if (type(k4) == "Player" and IsValid(k4) and k4:GetName() == k:GetName()) then tr_loc = v4 end
				end
			end
			ulx.fancyLog("#s: #s #s #s. Маршрут: #s\nМестоположение: #s",ply_name,wag_num,wag_str,tr_name,r_num,tr_loc)
        end
    end
end
local wagons = ulx.command(CATEGORY_NAME, "ulx trains", ulx.wagons, "!trains" )
wagons:defaultAccess( ULib.ACCESS_ALL )
wagons:help( "Информация о составах на сервере." )

-- чат-команда для высадки пассажиров
function ulx.expass( calling_ply )
	calling_ply:ConCommand("metrostroi_expel_passengers")
end
local exps = ulx.command(CATEGORY_NAME, "ulx expass", ulx.expass, "!expass" )
exps:defaultAccess( ULib.ACCESS_ALL )
exps:help( "Высадить всех пассажиров." )

if SERVER then
	-- Регистрация прав ULX
	for k, v in pairs (train_list) do
		ULib.ucl.registerAccess(k, ULib.ACCESS_ALL, "Спавн состава "..v, CATEGORY_NAME)
	end
	ULib.ucl.registerAccess("add_1wagons", ULib.ACCESS_ADMIN, "Спавн на 1 вагон больше", CATEGORY_NAME)
	ULib.ucl.registerAccess("add_2wagons", ULib.ACCESS_ADMIN, "Спавн на 2 вагона больше", CATEGORY_NAME)
	ULib.ucl.registerAccess("add_3wagons", ULib.ACCESS_ADMIN, "Спавн на 3 вагона больше", CATEGORY_NAME)
	ULib.ucl.registerAccess("metrostroi_anyplace_spawn", ULib.ACCESS_ADMIN, "Спавн в любом месте", CATEGORY_NAME)
end