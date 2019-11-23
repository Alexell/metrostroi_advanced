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
				ulx.fancyLog("#s "..MetrostroiAdvanced.Lang["Teleported"]..MetrostroiAdvanced.Lang["Teleported1"],ply:Nick())
				ply:Freeze(false)
			end)
		else
			train.InstructorsSeat:UseClientSideAnimation()
			timer.Create("TeleportIntoInstructorsSeat", 1, 1, function()
				train.InstructorsSeat:Use(ply,ply,3,1)
				ulx.fancyLog("#s "..MetrostroiAdvanced.Lang["Teleported"]..MetrostroiAdvanced.Lang["Teleported2"].." #s.",ply:Nick(),tply:Nick())
				ply:Freeze(false)
			end)
		end
    else
		if ply == tply then
			ply:SetPos(pos-Vector(0,0,40))
			ulx.fancyLog("#s "..MetrostroiAdvanced.Lang["Teleported"]..MetrostroiAdvanced.Lang["Teleported3"],ply:Nick())
		else
			ply:SetPos(pos-Vector(0,0,40))
			ulx.fancyLog("#s "..MetrostroiAdvanced.Lang["Teleported"]..MetrostroiAdvanced.Lang["Teleported4"].." #s.",ply:Nick(),tply:Nick())
		end
    end
end

------------------------------------------------------
--		***	METROSTROI TRAIN START SCRIPT ***		--
--				Made by Agent Smith					--
--		https://steamcommunity.com/id/ag-sm1th/		--
------------------------------------------------------

local function Set(button,state,ply,train)
	if IsValid(train) then
		if train[button] then
			train[button]:TriggerInput("Set",state)
		end
	end
end

local function TrainStart(train)
	-- Проход по составам - самая большая группа - Номерной и древнее
	if train:GetClass() and (train:GetClass():sub(13,18) != "81-718" and train:GetClass():sub(13,18) != "81-720" and train:GetClass():sub(13,18) != "81-722") then
		if train.KVWrenchMode != 1  or train.KVWrenchMode == 1 then
			train:PlayOnce("revers_in","cabin", 0.7)
			train.KVWrenchMode = 1
			train.KV:TriggerInput("Enabled", 1)
		end
		if train.KVWrenchMode == 1  then
			train.KV:TriggerInput("ReverserSet", 1)
		end 
		if train.Pneumatic.DriverValvePosition != 2 then
			train.Pneumatic:TriggerInput("BrakeSet", 2)
		end
		Set("ALS", 0, ply, train)
		Set("ARS", 0, ply, train)	
		Set("EPK", 0, ply, train)
		Set("EPV", 0, ply, train)
		timer.Create("TogglesOnTimer", 0.5, 1, function()	
			Set("A53", 1, ply, train)
			Set("A49", 1, ply, train)
			Set("A63", 1, ply, train)
			Set("VB", 1, ply, train)
			--Set("BPSNon", 1, ply, train)
			Set("VMK", 1, ply, train)
			Set("V1", 1, ply, train)
			Set("KU1", 1, ply, train)	-- МК для Еж
			Set("VUS", 1, ply, train)	
		end)
		timer.Create("TogglesOnTimer2", 1, 1, function()	
			Set("VUD1", 1, ply, train)
			Set("V2", 1, ply, train)
			Set("L_1", 1, ply, train)
			Set("L_3", 1, ply, train)
			Set("L_4", 1, ply, train)
			Set("R_UNch", 1, ply, train)
			Set("R_ZS", 1, ply, train)
			Set("R_G", 1, ply, train)
			Set("R_Radio", 1, ply, train)
			Set("PLights", 1, ply, train) -- для Еж3
			Set("GLights", 1, ply, train) -- для Еж3
			Set("VU14", 1, ply, train)	-- для Еж3
			Set("KU16", 1, ply, train)	-- Фары для Еж
			Set("KU2", 1, ply, train)	-- двери для Еж
		end)
		if train.ALS_ARS then 	-- условие на наличие АРС
			timer.Create("ARSTimer", 1.5, 1, function() -- таймер на AРC
				Set("ALS", 1, ply, train)
				Set("ARS", 1, ply, train)
				Set("EPK", 1, ply, train)
				Set("EPV", 1, ply, train)			
			end)
			timer.Create("DriverValveTimer013", 2.5, 1, function() -- таймер на разобщительный кран (013)
				Set("DriverValveDisconnect", 1, ply, train)
			end)
			timer.Create("DriverValveTimer334", 2, 1, function() -- таймер на краны двойной тяги (334)
				Set("DriverValveBLDisconnect", 1, ply, train)
				Set("DriverValveTLDisconnect", 1, ply, train)
			end)
			timer.Create("KBPressed", 4, 2, function() -- таймер на отмену КВТ (Ема)
				Set("KB", 1, ply, train)
			end)
			timer.Create("KBReleased", 5, 2, function() -- таймер на отмену КВТ (Ема)
				Set("KB", 0, ply, train)
			end)
			timer.Create("KVTPressed", 4, 2, function() -- таймер на отмену КВТ
				Set("KVT", 1, ply, train)		
			end)	
			timer.Create("KVTReleased", 5, 2, function() -- таймер на отмену КВТ
				Set("KVT", 0, ply, train)		
			end)
		else
			timer.Create("DriverValveTimer013", 2, 1, function() -- таймер на разобщительный кран (013)
				Set("DriverValveDisconnect", 1, ply, train)
			end)
			timer.Create("DriverValveTimer334", 2, 1, function() -- таймер на краны двойной тяги (334)
				Set("DriverValveBLDisconnect", 1, ply, train)
				Set("DriverValveTLDisconnect", 1, ply, train)
			end)	
		end
	-- ТИСУ
	elseif train:GetClass():sub(13,18) == "81-718" then
		if train.WrenchMode != 1 or train.WrenchMode == 1 then
			train:PlayOnce("kr_in", "cabin",1)
			train.WrenchMode = 1
		end
		if train.WrenchMode == 1 then
			train.KR:TriggerInput("Set", train.KR.Position + 1)
		end
		if train.Pneumatic.DriverValvePosition != 2 then
			train.Pneumatic:TriggerInput("BrakeSet", 2)
		end
		Set("SA15", 0, ply, train)
		Set("SA13", 0, ply, train)
		Set("EPK", 0, ply, train)	
		Set("SA16", 1, ply, train)
		Set("SAP39", 1, ply, train)		
		timer.Create("TogglesOnTimer718", 0.5, 1, function() -- таймер на тумблера
			Set("SA2/1", 1, ply, train)
			Set("SA4/1", 1, ply, train)				
			Set("SA5", 1, ply, train)
		end)
		timer.Create("ARSTimer718", 1, 1, function() -- таймер на AРC
			Set("SA15", 1, ply, train)
			Set("SA13", 1, ply, train)
			Set("EPK", 1, ply, train)
		end)
		timer.Create("DriverValveTimer013", 1.5, 1, function() -- таймер на разобщительный кран (013)
			Set("DriverValveDisconnect", 1, ply, train)
		end)
		timer.Create("SB9Pressed", 2, 1, function() -- таймер на отмену КВТ
			Set("SB9", 1, ply, train)		
		end)	
		timer.Create("SB9Released", 3, 1, function() -- таймер на отмену КВТ
			Set("SB9", 0, ply, train)		
		end)
	-- Яуза	
	elseif train:GetClass():sub(13,18) == "81-720" then 	-- не проверено!
		if train.WrenchMode != 1 or train.WrenchMode == 1 then
			train:PlayOnce("kro_in", "cabin",1)
			train.WrenchMode = 1
			timer.Create("ReverserSet", 0.25, 1, function() -- таймер на переключение реверса
				train.RV:TriggerInput("KROSet", train.RV.KROPosition + 1)
			end)
		end	
		timer.Create("RearToggles", 0.5, 1, function() -- таймер на тумблера сзади
			Set("Headlights1", 1, ply, train) -- Фары для Яузы
			Set("Headlights2", 1, ply, train) -- Фары для Яузы
			Set("CabLightStrength", 1, ply, train) -- Фары для Яузы				
		end)
		timer.Create("VityazActivate", 1, 1, function() -- таймер на переход в штатный режим
			if train["BUKP"].State != 5 then
				train["BUKP"].State = 5
			end
		end)
		timer.Create("FrontToggles", 1.5, 1, function() -- таймер на кнопки спереди
			Set("DoorClose", 1, ply, train) 
			Set("DoorSelectL", 1, ply, train) 
			Set("DoorSelectR", 0, ply, train) 
		end)
		timer.Create("AttentionPressed1", 3, 2, function() -- таймер на отмену (Яуза)
			Set("AttentionMessage", 1, ply, train)
			Set("AttentionBrake", 1, ply, train)
		end)
		timer.Create("AttentionReleased1", 3.25, 2, function() -- таймер на отмену (Яуза)
			Set("AttentionMessage", 0, ply, train)
			Set("AttentionBrake", 0, ply, train)
		end)
	else
	-- Юбилейный (без комментариев)
		if train:GetClass():sub(13,18) == "81-722" then 	
			Set("ALS", 0, ply, train)
			Set("ARS", 0, ply, train)
			if train.MFDU.State != 1 then train.MFDU.State = 1 end
			timer.Create("CabActive", 0.5, 1, function() 
				train.BUKP.Active = 1
				train:SetPackedBool("MFDUActive", true)	
				Set("PassVent", 2, ply, train)					
			end)
			timer.Create("ARSTimer722", 1, 1, function() 
				Set("ALS", 1, ply, train)
				Set("ARS", 1, ply, train)			
			end)
			timer.Create("VigilancePressed", 1.5, 1, function() 
				Set("Vigilance", 1, ply, train)		
			end)	
			timer.Create("VigilanceReleased", 2, 1, function() 
				Set("Vigilance", 0, ply, train)		
				Set("Headlights", 2, ply, train)
				Set("DoorClose", 2, ply, train)
			end)
			timer.Create("KROForward", 2.5, 1, function() 
				train.KRO:TriggerInput("Set", 2) 
			end)
		end
	end
end

local function TrainStop(train)
	-- Проход по составам - самая большая группа - Номерной и древнее
	if train:GetClass() and (train:GetClass():sub(13,18) != "81-718" and train:GetClass():sub(13,18) != "81-720" and train:GetClass():sub(13,18) != "81-722") then
		if train.Pneumatic.DriverValvePosition != 5 then
			train.Pneumatic:TriggerInput("BrakeSet", 5)
		end
		timer.Create("TogglesOffTimer", 0.5, 1, function ()
			Set("R_UNch", 0, ply, train)
			Set("R_ZS", 0, ply, train)
			Set("R_G", 0, ply, train)
			Set("V1", 0, ply, train)
		end)
		timer.Create("TogglesOffTimer", 1, 1, function ()
			Set("KU1", 0, ply, train)	-- МК для Еж
			Set("KU2", 0, ply, train)
			Set("PLights", 0, ply, train) -- свет в кабине для Еж3
			Set("VMK", 0, ply, train)
		end)		
		timer.Create("ValvesOffTimer", 1.5, 1, function ()
			Set("DriverValveDisconnect", 0, ply, train)
			Set("DriverValveBLDisconnect", 0, ply, train)
			Set("DriverValveTLDisconnect", 0, ply, train)
		end)		
		timer.Create("FullServiceBreakTimer", 2, 1, function() -- таймер на полное служебное торможение	
			Set("ALS", 0, ply, train)
			Set("ARS", 0, ply, train)	
			timer.Create("MiscTimer", 1, 1, function()			
				Set("VUD1", 0, ply, train)	
				Set("V2", 0, ply, train)			
				train.Pneumatic:TriggerInput("BrakeSet", 2)	
				end)
		end)
		if train.KVWrenchMode == 1  then
			train.KV:TriggerInput("ControllerSet", 0)				
		end 
		if train.KVWrenchMode != 0  then	
			timer.Create("KVOff", 2.5, 1, function() -- таймер на откл реверса
				train.KV:TriggerInput("ReverserSet", 0)
				timer.Create("KVOut", 0.5, 1, function()
					train.KV:TriggerInput("Enabled", 0)
					train.KVWrenchMode = 0
				end)
			end)					
		end	
	-- ТИСУ
	elseif train:GetClass() and train:GetClass():sub(13,18) == "81-718" then
		if train.Pneumatic.DriverValvePosition != 6 then
			train.Pneumatic:TriggerInput("BrakeSet", 5)
		end
		timer.Create("FullServiceBreakTimer718", 3, 1, function() -- таймер на полное служебное торможение ТИСУ
			Set("DriverValveDisconnect", 0, ply, train)
		end)
		timer.Create("TogglesOffTimer718", 4, 1, function()
			Set("SAP39", 0, ply, train)
			Set("SA5", 0, ply, train)
			Set("SA16", 0, ply, train)
		end)						
		if train.WrenchMode != 0 then
			timer.Create("KROff", 5, 1, function() -- таймер на откл реверса. ТИСУ
				train.KR:TriggerInput("Set", train.KR.Position - 1)
				Set("SA15", 0, ply, train)
				Set("SA13", 0, ply, train)
				timer.Create("KROff1", 1, 1, function() -- таймер на откл реверса. ТИСУ
					train.WrenchMode = 0
					train.Pneumatic:TriggerInput("BrakeSet", 2)
				end)
			end)			
		end		
	-- Яуза
	elseif train:GetClass() and train:GetClass():sub(13,18) == "81-720" then
		if train.WrenchMode != 0 then
			train.RV:TriggerInput("KROSet", train.RV.KROPosition - 1)
			timer.Create("RVOff", 0.5, 1, function() -- таймер на откл реверса. Яуза
				Set("DoorClose", 0, ply, train) 
				Set("DoorSelectL", 0, ply, train) 
				Set("DoorSelectR", 0, ply, train) 
			end)			
			timer.Create("RVOut", 1, 1, function() -- таймер на откл реверса. Яуза
				train.WrenchMode = 0
			end)
			timer.Create("TogglesOffTimer720", 1.5, 1, function() -- таймер на откл кнопок
				Set("DoorClose", 0, ply, train) 
				Set("DoorSelectL", 0, ply, train) 
				Set("DoorSelectR", 0, ply, train) 
			end)
		end	
	else 
	-- Юбилейный (без комментариев)
		if train:GetClass():sub(13,18) == "81-722" then 	
			timer.Create("KRONeutral", 0.5, 1, function() 
				train.KRO:TriggerInput("Set", 1) 
			end)
			timer.Create("ARSOffTimer722", 1, 1, function() 
				Set("ALS", 0, ply, train)
				Set("ARS", 0, ply, train)			
			end)
			timer.Create("CabDeactive", 1.5, 1, function() 
				train.BUKP.Active = 0
				train:SetPackedBool("MFDUActive", false)	
				Set("DoorClose", 1, ply, train)				
			end)
		end
	end
end

------------------------------------------------------
--			***	TRAIN START SCRIPT END	***			--
------------------------------------------------------

-- Смена кабины
local function ChangeCab (ply,train1,train2)
    local tim = 3
	local tim2 = tim + 1.5
	local tim3 = tim2 + 1.5
	if ply:GetNW2String("MATrainClass","") == "gmod_subway_81-720" then tim = 1  tim2 = tim + 1 tim3 = tim2 + 1 end
	if ply:GetNW2String("MATrainClass","") == "gmod_subway_81-722" then tim = 1  tim2 = tim + 1 tim3 = tim2 + 1 end
	TrainStop(train1)	
	timer.Create("Cab1OutDriverSeat", tim, 1, function()
		ply:ExitVehicle()
		ply:SetMoveType(8)
	end)
	timer.Create("Cab2IntoDriverSeat", tim2, 1, function()
		train2.DriverSeat:UseClientSideAnimation() -- пусть ебучую анимацию отрабатывает клиент	
		train2.DriverSeat:Use(ply,ply,3,1)
	end)
	timer.Create("Cab2TrainStart", tim3, 1, function()
		TrainStart(train2)
	end)	
end

-- Вывод станций в чат
local stswaittime = 10
local stslasttime = -stswaittime
function ulx.sts( calling_ply )
    if stslasttime + stswaittime > CurTime() then
        ULib.tsayError( calling_ply, MetrostroiAdvanced.Lang["PleaseWait"].." "..math.Round(stslasttime + stswaittime - CurTime()).." "..MetrostroiAdvanced.Lang["Seconds"].." "..MetrostroiAdvanced.Lang["CommandDelay"], true )
        return
    end
    stslasttime = CurTime()
	local name_num = 1
    local lang = GetConVarString("metrostroi_advanced_lang")
	if lang ~= "ru" then name_num = 2 end
	local stationtable = {}
    for k,v in pairs(Metrostroi.StationConfigurations) do
        if isnumber(k) then
			if v.names[name_num] then
				table.insert( stationtable,{tonumber(k),tostring(v.names[name_num])})
			else
				table.insert( stationtable,{tonumber(k),tostring(v.names[1])})
			end
        end
    end
    table.sort(stationtable, function(a, b) if a[1] ~= nil and b[1] ~= nil then return a[1] < b[1] end end)
    for k,v in pairs(Metrostroi.StationConfigurations) do
        if isstring(k) then 
			if v.names[name_num] then
				table.insert( stationtable,{k,tostring(v.names[name_num])})
			else
				table.insert( stationtable,{k,tostring(v.names[1])})
			end
        end
    end
    for k,v in pairs(stationtable) do
        ULib.tsayColor(nil,false,Color(219, 116, 32),v[1].." - "..v[2])
    end
end
local sts = ulx.command(CATEGORY_NAME, "ulx stations", ulx.sts, "!stations" )
sts:defaultAccess( ULib.ACCESS_ALL )
sts:help( "List of stations on current map." )

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
        if not Metrostroi.StationConfigurations then ULib.tsayError( calling_ply, MetrostroiAdvanced.Lang["MapNotCongigured"], true ) return end

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
            ULib.tsayError( calling_ply, Format(MetrostroiAdvanced.Lang["StationNotFound"].." %s",station), true )
            return
        elseif #st > 1 then
            ULib.tsayError( calling_ply,  Format(MetrostroiAdvanced.Lang["ManyStations"].." %s:",station), true )
            for k,v in pairs(st) do
                local tbl = Metrostroi.StationConfigurations[v]
                if tbl.names and tbl.names[1] then
                    ULib.tsayError( calling_ply, Format("\t%s=%s",v,tbl.names[1]), true )
                else
                    ULib.tsayError( calling_ply, Format("\t%s",k), true )
                end
            end
            ULib.tsayError( calling_ply, MetrostroiAdvanced.Lang["StationIncorrect"], true )
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
                ulx.fancyLogAdmin( calling_ply, "#A "..MetrostroiAdvanced.Lang["Teleported"]..MetrostroiAdvanced.Lang["Teleported5"].." #s", st.names and st.names[1] or key)
            else
                ULib.tsayError( calling_ply, MetrostroiAdvanced.Lang["StationConfigError"]..key, true )
                ulx.fancyLogAdmin( calling_ply, MetrostroiAdvanced.Lang["StationConfigError"].."#s", key)
            end

        else
            if ptbl and ptbl[1] then
                print(Format("DEBUG1:Teleported to %s(%s) pos:%s ang:%s",st.names and st.names[1] or key,key,ptbl[1],ptbl[2]))
            else
                ulx.fancyLogAdmin( calling_ply, MetrostroiAdvanced.Lang["StationConfigError"].."#s", station:gsub("^%l", string.upper))
            end
        end
end
local tps = ulx.command(CATEGORY_NAME, "ulx station", ulx.tps, "!station" )
tps:addParam{ type=ULib.cmds.StringArg, hint="Station or ID", ULib.cmds.takeRestOfLine }
tps:defaultAccess( ULib.ACCESS_ALL )
tps:help( "Teleport to a station." )

-- Замена !trains
local wagonswaittime = 10
local wagonslasttime = -wagonswaittime
function ulx.wagons( calling_ply )
    if wagonslasttime + wagonswaittime > CurTime() then
        ULib.tsayError( calling_ply, MetrostroiAdvanced.Lang["PleaseWait"].." "..math.Round(wagonslasttime + wagonswaittime - CurTime()).." "..MetrostroiAdvanced.Lang["Seconds"]..MetrostroiAdvanced.Lang["CommandDelay"], true )
        return
    end

    wagonslasttime = CurTime()

    ulx.fancyLog(MetrostroiAdvanced.Lang["ServerWagons"].." #s", Metrostroi.TrainCount())
	local Wags = {}
	local Trains = {}
	local Routes = {}
	local Locs = {}
	local wag_num = 0
	local wag_str = MetrostroiAdvanced.Lang["wagon1"]

	for k,v in pairs(MetrostroiAdvanced.TrainList) do
		if string.find(k,"custom") then continue end
		for _,train in pairs(ents.FindByClass(k)) do
			local ply = train.Owner
			if not IsValid(ply) then continue end
			if (not Trains[ply:Nick()]) then
				Trains[ply:Nick()] = MetrostroiAdvanced.TrainList[k]
				Wags[ply:Nick()] = #train.WagonList
				local rnum = 0
				if k == "gmod_subway_81-540_2" then
					if train.RouteNumberSys then
						rnum = tonumber(train.RouteNumberSys.RouteNumber)
					end
				elseif k == "gmod_subway_81-722" then
					rnum = tonumber(train.RouteNumberSys.RouteNumber)
				elseif k == "gmod_subway_81-717_6" then
					rnum = train.ASNP.RouteNumber
				else
					if train.RouteNumber then
						rnum = tonumber(train.RouteNumber.RouteNumber)
					end
				end
				if table.HasValue({"gmod_subway_81-702","gmod_subway_81-703","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_81-717_mvm","gmod_subway_81-718","gmod_subway_81-720"},k) then
					rnum = rnum / 10
				end
				Routes[ply:Nick()] = tostring(rnum)
				Locs[ply:Nick()] = MetrostroiAdvanced.GetLocation(train)
			end
		end
	end
	
	for k,v in pairs(Trains) do
		wag_num = tonumber(Wags[k])
		if wag_num >= 2 and wag_num <= 4 then wag_str = MetrostroiAdvanced.Lang["wagon2"] end
		if wag_num >= 5 then wag_str = MetrostroiAdvanced.Lang["wagon3"] end
		ulx.fancyLog("#s: #s #s #s. "..MetrostroiAdvanced.Lang["Route"]..": #s\n"..MetrostroiAdvanced.Lang["Location"]..": #s",k,wag_num,wag_str,Trains[k],Routes[k],Locs[k])
	end
	local wag_awail = (GetConVarNumber("metrostroi_maxtrains")*GetConVarNumber("metrostroi_advanced_maxwagons"))-GetGlobalInt("metrostroi_train_count")
    ulx.fancyLog(MetrostroiAdvanced.Lang["WagonsAwail"].." #s",wag_awail)
end
local wagons = ulx.command(CATEGORY_NAME, "ulx trains", ulx.wagons, "!trains" )
wagons:defaultAccess( ULib.ACCESS_ALL )
wagons:help( "Info about all trains on server." )

-- чат-команда для высадки пассажиров
function ulx.expass( calling_ply )
	calling_ply:ConCommand("metrostroi_expel_passengers")
end
local exps = ulx.command(CATEGORY_NAME, "ulx expass", ulx.expass, "!expass" )
exps:defaultAccess( ULib.ACCESS_ALL )
exps:help( "Expel all passengers." )

-- телепорт в состав игрока
function ulx.traintp( calling_ply, target_ply )
	local class = target_ply:GetNW2String("MATrainClass","")
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
ttp:help( "Teleport to a player's train." )

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
	ULib.tsayError( calling_ply, MetrostroiAdvanced.Lang["Signal"].." "..signal.." "..MetrostroiAdvanced.Lang["NotFound"], true ) 			
end
local signaltp = ulx.command( CATEGORY_NAME, "ulx signaltp", ulx.signaltp, "!signaltp" )
signaltp:addParam{ type=ULib.cmds.StringArg, hint="Signal", ULib.cmds.takeRestOfLine }
signaltp:defaultAccess( ULib.ACCESS_ADMIN )
signaltp:help( "Teleport to a signal" )

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
	ulx.fancyLog("#s "..MetrostroiAdvanced.Lang["UDCMessage"],calling_ply:Nick())
end
local udc = ulx.command( CATEGORY_NAME, "ulx udochka", ulx.udochka, "!udc" )
udc:defaultAccess( ULib.ACCESS_ADMIN )
udc:help( "Reset the positions of power connectors." )

-- посадить игрока в кресло машиниста
function ulx.enter( calling_ply, target_ply )
	if IsValid(target_ply) then
		local train = calling_ply:GetEyeTrace().Entity
		if not train.DriverSeat then
			ULib.tsayError( calling_ply, MetrostroiAdvanced.Lang["WagonIncorrect"] )
			return
		end
		if IsValid(target_ply:GetVehicle()) then
			target_ply:ExitVehicle()
		end
		local pos = train:GetPos()
		target_ply:SetMoveType(8)
		target_ply:Freeze(true)
		target_ply:SetPos(pos-Vector(0,0,40))
		timer.Create("TimerPlyEnterDriverSeat", 0.2, 1, function()
			train.DriverSeat:UseClientSideAnimation()
			train.DriverSeat:Use(target_ply,target_ply,3,1)
			target_ply:Freeze(false)
			if train.DriverSeat == target_ply:GetVehicle() then
				ulx.fancyLogAdmin( calling_ply, "#A "..MetrostroiAdvanced.Lang["EnterPlayer"].." #T "..MetrostroiAdvanced.Lang["IntoTrain"], target_ply )
			else
				ULib.tsayError( calling_ply, MetrostroiAdvanced.Lang["EnterFail"] )
			end
		end)

	end
end
local enter = ulx.command( CATEGORY_NAME, "ulx enter", ulx.enter, "!enter")
enter:addParam{ type = ULib.cmds.PlayerArg }
enter:defaultAccess( ULib.ACCESS_ADMIN )
enter:help( "Place a player into the driver's seat (aim at any wagon)" )

-- высадить игрока с любого места в составе
function ulx.expel( calling_ply, target_ply )
	if IsValid(target_ply) then
		if not IsValid(target_ply:GetVehicle()) then
			ULib.tsayError( calling_ply, target_ply:Nick() .. " "..MetrostroiAdvanced.Lang["NotInVehicle"] )
			return
		else
			target_ply:ExitVehicle()
		end
		ulx.fancyLogAdmin( calling_ply, "#A "..MetrostroiAdvanced.Lang["ExpelPlayer"].." #T "..MetrostroiAdvanced.Lang["OutTrain"], target_ply )
	end
end
local expl = ulx.command( CATEGORY_NAME, "ulx expel", ulx.expel, "!expel")
expl:addParam{ type = ULib.cmds.PlayerArg }
expl:defaultAccess( ULib.ACCESS_ADMIN )
expl:help( "Expel a player from any seat in train" )

-- простая смена кабины
function ulx.ch( calling_ply )
	if not IsValid(calling_ply) then return end
	local seat = calling_ply:GetVehicle()
	if not IsValid(seat) then return end
	local seattype = seat:GetNW2String("SeatType")
	local train = seat:GetNW2Entity("TrainEntity")
	if not IsValid(train) then return end
	local seatpos = train:WorldToLocal(seat:GetPos())
	for t,wag in pairs(train.WagonList) do
		if (wag:GetClass() == train:GetClass() and wag ~= train) then
			calling_ply:ExitVehicle()
			calling_ply:SetMoveType(8)
			if seattype == "driver" then
				wag.DriverSeat:UseClientSideAnimation()
				timer.Create("TeleportIntoCab2DriverSeat", 1, 1, function()
					wag.DriverSeat:Use(calling_ply,calling_ply,3,1)
				end)
				break
			else
				local seats = ents.FindInSphere(wag:LocalToWorld(seatpos),2)
				for w,s in pairs(seats) do
					if s:GetNW2String("SeatType") == "instructor" then
						s:UseClientSideAnimation()
						timer.Create("TeleportIntoCab2InstructorSeat", 1, 1, function()
							s:Use(calling_ply,calling_ply,3,1)
						end)
						break
					end
				end
			end
		end
	end
end
local ch = ulx.command( CATEGORY_NAME, "ulx ch", ulx.ch, "!ch" )
ch:defaultAccess( ULib.ACCESS_ALL )
ch:help( "Simple cabin change" )

function ulx.smartch( calling_ply )
	local seat = calling_ply:GetVehicle()
	if not IsValid(seat) then return end
	local seattype = seat:GetNW2String("SeatType")
	if seattype == "driver" then
		local train1 = seat:GetNW2Entity("TrainEntity")
		local train2
		if not IsValid(train1) then return end
		for t,wag in pairs(train1.WagonList) do
			if (wag:GetClass() == train1:GetClass() and wag ~= train1) then
				train2 = wag
			end
		end
		ChangeCab(calling_ply,train1,train2)
	end
end
local sch = ulx.command( CATEGORY_NAME, "ulx sch", ulx.smartch, "!sch" )
sch:defaultAccess( ULib.ACCESS_ALL )
sch:help( "Smart cabin change" )

function ulx.trainstart( calling_ply )
	if not IsValid(calling_ply) then return end
    local train = calling_ply:GetTrain()
	if train != nil then
		TrainStart(train)
		ulx.fancyLog("#s "..MetrostroiAdvanced.Lang["UseTrainStart"],calling_ply:Nick())
	end
end
local trainstart = ulx.command( CATEGORY_NAME, "ulx trainstart", ulx.trainstart, "!trainstart" )
trainstart:defaultAccess( ULib.ACCESS_ALL )
trainstart:help( "Cabin autostart" )

function ulx.trainstop( calling_ply )
	if not IsValid(calling_ply) then return end
    local train = calling_ply:GetTrain()
	if train != nil then TrainStop(train) end
end
local trainstop = ulx.command( CATEGORY_NAME, "ulx trainstop", ulx.trainstop, "!trainstop" )
trainstop:defaultAccess( ULib.ACCESS_ALL )
trainstop:help( "Cabin stop." )

if SERVER then
	-- Регистрация прав ULX
	
	-- Составы загружаем из файла, потому что Metrostroi.TrainClasses появляется позже, чем можно добавить права ULX
	if file.Exists("metrostroi_advanced_trains.txt","DATA") then
		local trains = string.Explode("\n", file.Read("metrostroi_advanced_trains.txt","DATA"))
		for k, v in pairs (trains) do
			if v ~= "" then ULib.ucl.registerAccess(v, ULib.ACCESS_ALL, "Spawn train "..v, CATEGORY_NAME) end
		end
	end
	ULib.ucl.registerAccess("add_1wagons", ULib.ACCESS_ADMIN, "Spawn +1 wagon more", CATEGORY_NAME)
	ULib.ucl.registerAccess("add_2wagons", ULib.ACCESS_ADMIN, "Spawn +2 wagons more", CATEGORY_NAME)
	ULib.ucl.registerAccess("add_3wagons", ULib.ACCESS_ADMIN, "Spawn +3 wagons more", CATEGORY_NAME)
	ULib.ucl.registerAccess("metrostroi_anyplace_spawn", ULib.ACCESS_ALL, "Spawn anywhere", CATEGORY_NAME)
end