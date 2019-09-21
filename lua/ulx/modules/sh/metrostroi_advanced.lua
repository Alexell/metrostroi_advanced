----------------- Metrostroi Advanced -----------------
-- Авторы: Alexell и Agent Smith
-- Версия: 1.0
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_advanced
-------------------------------------------------------

local CATEGORY_NAME = "Metrostroi Advanced"

-- телепортация в состав
local function GotoTrain (ply,tply,train,sit)
    if IsValid(ply:GetVehicle()) then
        ply:ExitVehicle()
    end
    local pos = train:GetPos()
    ply:SetMoveType(8)
    if sit == true then
        ply:Freeze(true)
        ply:SetPos(pos-Vector(0,0,40))
		if ply == tply then
			train.DriverSeat:UseClientSideAnimation() -- пусть ебучую анимацию отрабатывает клиент
			timer.Create("TeleportIntoDriverSeat", 1, 1, function()
				train.DriverSeat:Use(ply,ply,3,1)
				ulx.fancyLog("#s телепортировался в свой состав.",ply:Nick())
				ply:Freeze(false)
			end)
		else
			train.InstructorsSeat:UseClientSideAnimation()
			timer.Create("TeleportIntoInstructorsSeat", 1, 1, function()
				train.InstructorsSeat:Use(ply,ply,3,1)
				ulx.fancyLog("#s телепортировался в состав игрока #s.",ply:Nick(),tply:Nick())
				ply:Freeze(false)
			end)
		end
    else
		if ply == tply then
			ply:SetPos(pos-Vector(0,0,40))
			ulx.fancyLog("#s телепортировался к своему составу.",ply:Nick())
		else
			ply:SetPos(pos-Vector(0,0,40))
			ulx.fancyLog("#s телепортировался к составу игрока #s.",ply:Nick(),tply:Nick())
		end
    end
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
    local stationtable = {}
    for k,v in pairs(Metrostroi.StationConfigurations) do
        if isnumber(k) then 
        table.insert( stationtable,{tonumber(k),tostring(v.names[1])})
        end
    end
    table.sort(stationtable, function(a, b) if a[1] ~= nil and b[1] ~= nil then return a[1] < b[1] end end)
    for k3,v3 in pairs(Metrostroi.StationConfigurations) do
        if isstring(k3) then 
        table.insert( stationtable,{k3,tostring(v3.names[1])})
        end
    end
    for k2,v2 in pairs(stationtable) do
        ULib.tsayColor(nil,false,Color(219, 116, 32),v2[1].." - "..v2[2])
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
				if (Trains[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] == nil) then Trains[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] = MetrostroiAdvanced.TrainList[v2:GetClass()] end
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
					Locs[v2:CPPIGetOwner() or v2:GetNetworkedEntity("Owner", "N/A") or "(disconnected)"] = MetrostroiAdvanced.GetLocation(v2)
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
	local wag_awail = (GetConVarNumber("metrostroi_maxtrains")*GetConVarNumber("metrostroi_advanced_maxwagons"))-GetGlobalInt("metrostroi_train_count")
    ulx.fancyLog("Доступно вагонов для спавна: #s",wag_awail)
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

-- телепорт в состав игрока
function ulx.traintp( calling_ply, target_ply )
	local class = target_ply:GetNW2String("TrainC","")
	if class !="" then
		local teleported = false
		local ents = ents.FindByClass(class)
		for k,v in pairs(ents) do
			if v.Owner:Nick() == target_ply:Nick() then
				if (class:sub(13,18) != "81-718" and class:sub(13,18) != "81-720" and class:sub(13,18) != "81-722") then
					if v.KVWrenchMode != 0 then if v.KV.ReverserSet != 0 then GotoTrain(calling_ply,target_ply,v,true) teleported = true end end
				elseif class:sub(13,18) == "81-718" then
					if v.WrenchMode != 0 then if v.KR.Position != 0 then GotoTrain(calling_ply,target_ply,v,true) teleported = true end end
				elseif class:sub(13,18) == "81-720" then
					if v.WrenchMode != 0 then if v.RV.KROPosition != 0 then GotoTrain(calling_ply,target_ply,v,true) teleported = true end end
				else
					if class:sub(13,18) == "81-722" then
						if v.Electric.CabActive != 0 then GotoTrain(calling_ply,target_ply,v,true)  teleported = true end
					end
				end
			end
		end
		if not teleported then
			for k,v in pairs(ents) do
				if v.Owner:Nick() == target_ply:Nick() then
					GotoTrain(calling_ply,target_ply,v,false)
					break
				end
			end
		end
	end
end
local ttp = ulx.command( CATEGORY_NAME, "ulx traintp", ulx.traintp, "!traintp" )
ttp:addParam{ type=ULib.cmds.PlayerArg, target="*", default="^", ULib.cmds.optional }
ttp:defaultAccess( ULib.ACCESS_ALL )
ttp:help( "Телепортироваться в состав игрока." )

-- телепорт к светофору по названию
function ulx.signaltp(calling_ply,signal)
	for _,sig in pairs(ents.FindByClass("gmod_track_signal")) do
		if sig.Name == signal or sig.Name == string.upper(signal) or string.upper(sig.Name) == signal then
			if calling_ply:InVehicle() then calling_ply:ExitVehicle() end
			calling_ply:SetPos(sig:GetPos())
			calling_ply:SetEyeAngles(sig:GetAngles()+Angle(0,-90,0))	
			calling_ply:SetLocalVelocity( Vector( 0, 0, 0 ) ) -- Stop!				
			return
		end
	end
	ULib.tsayError( calling_ply, "Светофор "..signal.." не найден", true ) 			
end
local signaltp = ulx.command( CATEGORY_NAME, "ulx signaltp", ulx.signaltp, "!signaltp" )
signaltp:addParam{ type=ULib.cmds.StringArg, hint="Светофор", ULib.cmds.takeRestOfLine }
signaltp:defaultAccess( ULib.ACCESS_ADMIN )
signaltp:help( "Телепортирует к сигналу")

-- восстановление исходного положения удочек
function ulx.udochka( calling_ply )
	local cur_map = game.GetMap()
	local boxes = {}
	if (cur_map:find("gm_mus_loopline")) then
		boxes = ents.FindByClass("func_tracktrain")
	else
		boxes = ents.FindByClass("func_physbox")
	end
	for k,v in pairs(boxes) do
		v:SetAngles(MetrostroiAdvanced.Box_Angles[k])
		v:SetPos(MetrostroiAdvanced.Box_Positions[k])
	end
	local udcs = ents.FindByClass("gmod_track_udochka")
	for k,v in pairs(udcs) do
		v:SetPos(MetrostroiAdvanced.Udc_Positions[k])
	end
	ulx.fancyLog("#s восстановил удочки в исходное положение.",calling_ply:Nick())
end
local udc = ulx.command( CATEGORY_NAME, "ulx udochka", ulx.udochka, "!udc" )
udc:defaultAccess( ULib.ACCESS_ADMIN )
udc:help( "Восстановить положения удочек." )

if SERVER then
	-- Регистрация прав ULX
	for k, v in pairs (MetrostroiAdvanced.TrainList) do
		ULib.ucl.registerAccess(k, ULib.ACCESS_ALL, "Спавн состава "..v, CATEGORY_NAME)
	end
	ULib.ucl.registerAccess("add_1wagons", ULib.ACCESS_ADMIN, "Спавн на 1 вагон больше", CATEGORY_NAME)
	ULib.ucl.registerAccess("add_2wagons", ULib.ACCESS_ADMIN, "Спавн на 2 вагона больше", CATEGORY_NAME)
	ULib.ucl.registerAccess("add_3wagons", ULib.ACCESS_ADMIN, "Спавн на 3 вагона больше", CATEGORY_NAME)
	ULib.ucl.registerAccess("metrostroi_anyplace_spawn", ULib.ACCESS_ALL, "Спавн в любом месте", CATEGORY_NAME)
end