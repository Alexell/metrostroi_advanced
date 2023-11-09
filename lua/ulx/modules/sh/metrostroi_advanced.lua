------------------------ Metrostroi Advanced -------------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- Version: 2.4
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_advanced
----------------------------------------------------------------------

local CATEGORY_NAME = "Metrostroi Advanced"

local function lang(str)
	return MetrostroiAdvanced.Lang[str]
end

-- телепортация в состав
local function GotoTrain (ply,tply,train,sit)
	if not IsValid(train) then return end
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
			timer.Simple(1, function()
				train.DriverSeat:Use(ply,ply,3,1)
				ulx.fancyLog("#s "..lang("Teleported")..lang("Teleported1"),ply:Nick())
				ply:Freeze(false)
			end)
		else
			train.InstructorsSeat:UseClientSideAnimation()
			timer.Simple(1, function()
				train.InstructorsSeat:Use(ply,ply,3,1)
				ulx.fancyLog("#s "..lang("Teleported")..lang("Teleported2").." #s.",ply:Nick(),tply:Nick())
				ply:Freeze(false)
			end)
		end
    else
		if ply == tply then
			ply:SetPos(pos-Vector(0,0,40))
			ulx.fancyLog("#s "..lang("Teleported")..lang("Teleported3"),ply:Nick())
		else
			ply:SetPos(pos-Vector(0,0,40))
			ulx.fancyLog("#s "..lang("Teleported")..lang("Teleported4").." #s.",ply:Nick(),tply:Nick())
		end
    end
end

----------------------------------------------------------
--			***	TRAIN START/STOP SCRIPT ***				--
--				  Made by Agent Smith					--
----------------------------------------------------------

local function TrainStart(train)
	if not IsValid(train) then return end
	local class = train:GetClass()
	local cursig
	-- Проход по составам - самая большая группа - Номерной и древнее
	if class and (not class:find("718") and not class:find("720") and not class:find("722") and not class:find("760")) then
		if train.KVWrenchMode != 1  or train.KVWrenchMode == 1 then
			train:PlayOnce("revers_in", "cabin", 0.7)
			train.KVWrenchMode = 1
			train.KV:TriggerInput("Enabled", 1)
		end
		if train.KVWrenchMode == 1  then
			train.KV:TriggerInput("ReverserSet", 1)
		end 
		if train.Pneumatic.DriverValvePosition != 2 then
			train.Pneumatic:TriggerInput("BrakeSet", 2)
		end
		if train.ALS then train.ALS:TriggerInput("Set", 0) end
		if train.ARS then train.ARS:TriggerInput("Set", 0) end
		if train.EPK then train.EPK:TriggerInput("Set", 0) end
		if train.EPV then train.EPV:TriggerInput("Set", 0) end
		timer.Simple(0.5, function()
			if train.VMK then train.VMK:TriggerInput("Set", 1) end
			if train.V1 then train.V1:TriggerInput("Set", 1) end
			if train.KU1 then train.KU1:TriggerInput("Set", 1) end
			if train.VUS then train.VUS:TriggerInput("Set", 1) end	
		end)
		timer.Simple(1, function()
			if train.VUD1 then train.VUD1:TriggerInput("Set", 1) end
			if train.V2 then train.V2:TriggerInput("Set", 1) end
			if train.L_1 then train.L_1:TriggerInput("Set", 1) end
			if train.L_3 then train.L_3:TriggerInput("Set", 1) end
			if train.L_4 then train.L_4:TriggerInput("Set", 1) end	
			if train.R_UNch then train.R_UNch:TriggerInput("Set", 1) end
			if train.R_ZS then train.R_ZS:TriggerInput("Set", 1) end
			if train.R_G then train.R_G:TriggerInput("Set", 1) end
			if train.R_Radio then train.R_Radio:TriggerInput("Set", 1) end
			if train.PLights then train.PLights:TriggerInput("Set", 1) end
			if train.GLights then train.GLights:TriggerInput("Set", 1) end
			if train.VU14 then train.VU14:TriggerInput("Set", 1) end
			if train.KU16 then train.KU16:TriggerInput("Set", 1) end
			if train.KU2 then train.KU2:TriggerInput("Set", 1) end
		end)
		timer.Simple(2, function() -- таймер на AРC
			if train.ALS then train.ALS:TriggerInput("Set", 1) end
			if train.ARS then train.ARS:TriggerInput("Set", 1) end
			if train.EPK then train.EPK:TriggerInput("Set", 1) end
			if train.EPV then train.EPV:TriggerInput("Set", 1) end
		end)
		timer.Simple(3, function() -- таймер на разобщительный кран и на краны двойной тяги
			if train.DriverValveDisconnect then train.DriverValveDisconnect:TriggerInput("Set", 1) end
			if train.DriverValveBLDisconnect then train.DriverValveBLDisconnect:TriggerInput("Set", 1) end
			if train.DriverValveTLDisconnect then train.DriverValveTLDisconnect:TriggerInput("Set", 1) end
		end)
		timer.Simple(4, function() -- таймер на дешифратор
			local pos = Metrostroi.TrainPositions[train]
			if pos then pos = pos[1] end
			if pos then
				cursig = Metrostroi.GetARSJoint(pos.node1, pos.x, Metrostroi.TrainDirections[train])
			end
			if IsValid(cursig) and cursig.TwoToSix then
				if train.ALSFreq then train.ALSFreq:TriggerInput("Set", 1) end
			else
				if train.ALSFreq then train.ALSFreq:TriggerInput("Set", 0) end
			end
		end)
		timer.Simple(5, function() -- таймер на отмену КВТ
			if train.KB then train.KB:TriggerInput("Toggle", 1) end
			if train.KVT then train.KVT:TriggerInput("Toggle", 1) end
			timer.Simple(4, function()
				if train.KB then train.KB:TriggerInput("Toggle", 1) end
				if train.KVT then train.KVT:TriggerInput("Toggle", 1) end
			end)
		end)
	-- ТИСУ
	elseif class:find("718") then
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
		if train.SA15 then train.SA15:TriggerInput("Set", 0) end
		if train.SA13 then train.SA13:TriggerInput("Set", 0) end
		if train.SA16 then train.SA16:TriggerInput("Set", 1) end
		if train.SAP39 then train.SAP39:TriggerInput("Set", 1) end
		if train.EPK then train.EPK:TriggerInput("Set", 0) end
		timer.Simple(0.5, function() -- таймер на тумблера
			if train["SA2/1"] then train["SA2/1"]:TriggerInput("Set", 1) end
			if train["SA4/1"] then train["SA4/1"]:TriggerInput("Set", 1) end
			if train.SA5 then train.SA5:TriggerInput("Set", 1) end
		end)
		timer.Simple(1, function() -- таймер на AРC
			if train.SA15 then train.SA15:TriggerInput("Set", 1) end
			if train.SA13 then train.SA13:TriggerInput("Set", 1) end
			if train.EPK then train.EPK:TriggerInput("Set", 1) end
		end)
		timer.Simple(2, function() -- таймер на разобщительный кран (013)
			if train.DriverValveDisconnect then train.DriverValveDisconnect:TriggerInput("Set", 1) end
		end)
		timer.Simple(3, function() -- таймер на отмену КВТ
			if train.SB9 then train.SB9:TriggerInput("Toggle", 1) end
			timer.Simple(3, function()
				if train.SB9 then train.SB9:TriggerInput("Toggle", 1) end
			end)
		end)
		timer.Simple(4, function() -- таймер на дешифратор
			local pos = Metrostroi.TrainPositions[train]
			if pos then pos = pos[1] end
			if pos then
				cursig = Metrostroi.GetARSJoint(pos.node1, pos.x, Metrostroi.TrainDirections[train])
			end
			if IsValid(cursig) and cursig.TwoToSix then
				if train.SAP14 then train.SAP14:TriggerInput("Set", 1) end
			else
				if train.SAP14 then train.SAP14:TriggerInput("Set", 0) end
			end
		end)
	-- Яуза	
	elseif class:find("720") then
		if train.WrenchMode != 1 or train.WrenchMode == 1 then
			train:PlayOnce("kro_in", "cabin",1)
			train.WrenchMode = 1
			timer.Simple(0.5, function() -- таймер на переключение реверса
				train.RV:TriggerInput("KROSet", train.RV.KROPosition + 1)
			end)
		end	
		timer.Simple(1, function() -- таймер на тумблера сзади
			if train.Headlights1 then train.Headlights1:TriggerInput("Set", 1) end
			if train.Headlights2 then train.Headlights2:TriggerInput("Set", 1) end
			if train.CabLightStrength then train.CabLightStrength:TriggerInput("Set", 1) end
		end)
		timer.Simple(1, function() -- таймер на переход в штатный режим
			if train.BUKP.State != 5 then
				train.BUKP.State = 5
			end
		end)
		timer.Simple(2, function() -- таймер на кнопки спереди
			if train.DoorClose then train.DoorClose:TriggerInput("Set", 1) end
		end)
		timer.Simple(2.5, function() -- таймер на кнопки спереди
			if train.DoorSelectL then train.DoorSelectL:TriggerInput("Set", 1) end
			if train.DoorSelectR then train.DoorSelectR:TriggerInput("Set", 0) end
		end)
		timer.Create("AttentionPressed1", 3, 2, function() -- таймер на отмену (Яуза)
			if train.AttentionMessage then train.AttentionMessage:TriggerInput("Toggle", 1) end
			if train.AttentionBrake then train.AttentionBrake:TriggerInput("Toggle", 1) end
			timer.Simple(2, function()
				if train.AttentionMessage then train.AttentionMessage:TriggerInput("Toggle", 1) end
				if train.AttentionBrake then train.AttentionBrake:TriggerInput("Toggle", 1) end
			end)
		end)
		timer.Simple(4, function() -- таймер на дешифратор
			local pos = Metrostroi.TrainPositions[train]
			if pos then pos = pos[1] end
			if pos then
				cursig = Metrostroi.GetARSJoint(pos.node1, pos.x, Metrostroi.TrainDirections[train])
			end
			if IsValid(cursig) and cursig.TwoToSix then
				if train.ALSFreq then train.ALSFreq:TriggerInput("Set", 1) end
			else
				if train.ALSFreq then train.ALSFreq:TriggerInput("Set", 0) end
			end
		end)
	-- Юбилейный
	elseif class:find("722") then
		if train.ALS then train.ALS:TriggerInput("Set", 0) end
		if train.ARS then train.ARS:TriggerInput("Set", 0) end
		if train.MFDU.State != 1 then train.MFDU.State = 1 end
		timer.Simple(0.5, function() 
			train.BUKP.Active = 1
			train:SetPackedBool("MFDUActive", true)	
		end)
		timer.Simple(1, function() 
			if train.ALS then train.ALS:TriggerInput("Set", 1) end
			if train.ARS then train.ARS:TriggerInput("Set", 1) end
		end)
		timer.Simple(2, function() 
			if train.Vigilance then train.Vigilance:TriggerInput("Toggle", 1) end
			if train.PassVent then train.PassVent:TriggerInput("Set", 2) end
		end)	
		timer.Simple(3, function() 
			if train.Vigilance then train.Vigilance:TriggerInput("Toggle", 1) end
			if train.Headlights then train.Headlights:TriggerInput("Set", 2) end
			if train.DoorClose then train.DoorClose:TriggerInput("Set", 2) end
		end)
		timer.Simple(3.5, function() 
			train.KRO:TriggerInput("Set", 2) 
		end)
	-- Ока
	elseif class:find("760") then
		timer.Simple(0.5, function() -- таймер на переключение реверса
			train.RV:TriggerInput("KROSet", train.RV.KROPosition + 1)
		end)
		timer.Simple(1.5, function() -- таймер на переход в штатный режим
			if train.BUKP.State != 5 then
				train.BUKP.State = 5
			end
		end)
		timer.Simple(2, function() -- таймер на кнопки спереди
			if train.DoorSelectL then train.DoorSelectL:TriggerInput("Toggle", 1) end
			if train.DoorClose then train.DoorClose:TriggerInput("Toggle", 1) end
		end)
		timer.Simple(2.5, function() -- таймер на дешифратор
			local pos = Metrostroi.TrainPositions[train]
			if pos then pos = pos[1] end
			if pos then
				cursig = Metrostroi.GetARSJoint(pos.node1, pos.x, Metrostroi.TrainDirections[train])
			end
			if IsValid(cursig) and cursig.TwoToSix then
				if train.SA14k then train.SA14k:TriggerInput("Set", 0) end
				if train.SA14 then train.SA14:TriggerInput("Set", 1) end
			else
				if train.SA14k then train.SA14k:TriggerInput("Set", 1) end
				if train.SA14 then train.SA14:TriggerInput("Set", 0) end
			end
		end)
	end
end

local function TrainStop(train)
	local class = train:GetClass()
	-- Проход по составам - самая большая группа - Номерной и древнее
	if class and (not class:find("718") and not class:find("720") and not class:find("722") and not class:find("760")) then
		if train.Pneumatic.DriverValvePosition != 5 then
			train.Pneumatic:TriggerInput("BrakeSet", 5)
		end
		timer.Simple(0.5, function ()
			if train.R_UNch then train.R_UNch:TriggerInput("Set", 0) end
			if train.R_ZS then train.R_ZS:TriggerInput("Set", 0) end
			if train.R_G then train.R_G:TriggerInput("Set", 0) end
			if train.R_Radio then train.R_Radio:TriggerInput("Set", 0) end
			if train.V1 then train.V1:TriggerInput("Set", 0) end
		end)
		timer.Simple(1, function ()
			if train.KU1 then train.KU1:TriggerInput("Set", 0) end
			if train.KU2 then train.KU2:TriggerInput("Set", 0) end
			if train.PLights then train.PLights:TriggerInput("Set", 0) end
			if train.VMK then train.VMK:TriggerInput("Set", 0) end
		end)		
		timer.Simple(1.5, function ()
			if train.DriverValveDisconnect then train.DriverValveDisconnect:TriggerInput("Set", 0) end
			if train.DriverValveBLDisconnect then train.DriverValveBLDisconnect:TriggerInput("Set", 0) end
			if train.DriverValveTLDisconnect then train.DriverValveTLDisconnect:TriggerInput("Set", 0) end
		end)		
		timer.Simple(2, function()
			if train.ALS then train.ALS:TriggerInput("Set", 0) end
			if train.ARS then train.ARS:TriggerInput("Set", 0) end
		end)
		timer.Simple(2.5, function()
			if train.KVWrenchMode == 1  then
				train.KV:TriggerInput("ControllerSet", 0)				
			end 
		end)
		timer.Simple(3, function()			
			if train.VUD1 then train.VUD1:TriggerInput("Set", 0) end
			if train.V2 then train.V2:TriggerInput("Set", 0) end
			train.Pneumatic:TriggerInput("BrakeSet", 2)	
		end)
		timer.Simple(4, function() -- таймер на откл реверса
			if train.KVWrenchMode != 0  then
				train.KV:TriggerInput("ReverserSet", 0)
				timer.Simple(0.5, function()
					train.KV:TriggerInput("Enabled", 0)
					train.KVWrenchMode = 0
				end)
			end
		end)					
	-- ТИСУ
	elseif class:find("718") then
		if train.Pneumatic.DriverValvePosition != 6 then
			train.Pneumatic:TriggerInput("BrakeSet", 5)
		end
		timer.Simple(3, function() -- таймер на полное служебное торможение ТИСУ
			if train.DriverValveDisconnect then train.DriverValveDisconnect:TriggerInput("Set", 0) end
		end)
		timer.Simple(4, function()
			if train.SA5 then train.SA5:TriggerInput("Set", 0) end
			if train.SA16 then train.SA16:TriggerInput("Set", 0) end
			if train.SAP39 then train.SAP39:TriggerInput("Set", 0) end
		end)						
		if train.WrenchMode != 0 then
			timer.Simple(5, function() -- таймер на откл реверса. ТИСУ
				train.KR:TriggerInput("Set", train.KR.Position - 1)
				if train.SA15 then train.SA15:TriggerInput("Set", 0) end
				if train.SA13 then train.SA13:TriggerInput("Set", 0) end
			end)			
			timer.Simple(6, function() -- таймер на откл реверса. ТИСУ
				train.WrenchMode = 0
				train.Pneumatic:TriggerInput("BrakeSet", 2)
			end)
		end		
	-- Яуза
	elseif class:find("720") then
		if train.WrenchMode != 0 then
			timer.Simple(1, function() -- таймер на откл реверса. Яуза
				train.RV:TriggerInput("KROSet", train.RV.KROPosition - 1) 
			end)
			timer.Simple(1.5, function() -- таймер на откл реверса. Яуза
				train.WrenchMode = 0
			end)
			timer.Simple(2, function() -- таймер на откл кнопок
				if train.DoorClose then train.DoorClose:TriggerInput("Set", 0) end
				if train.DoorSelectL then train.DoorSelectL:TriggerInput("Set", 0) end
				if train.DoorSelectR then train.DoorSelectR:TriggerInput("Set", 0) end
			end)
		end	
	-- Юбилейный (без комментариев)
	elseif class:find("722") then
			timer.Simple(0.5, function() 
				train.KRO:TriggerInput("Set", 1) 
			end)
			timer.Simple(1, function() 
				if train.ALS then train.ALS:TriggerInput("Set", 0) end
				if train.ARS then train.ARS:TriggerInput("Set", 0) end		
			end)
			timer.Simple(1.5, function() 
				train.BUKP.Active = 0
				train:SetPackedBool("MFDUActive", false)	
				if train.DoorClose then train.DoorClose:TriggerInput("Set", 1) end			
			end)
	-- Oka
	elseif class:find("760") then
		timer.Simple(1, function() -- таймер на переключение реверса
			train.RV:TriggerInput("KROSet", train.RV.KROPosition - 1)
		end)
		timer.Simple(1.5, function() -- таймер на кнопки спереди
			if train.DoorSelectL then train.DoorSelectL:TriggerInput("Set", 0) end
			if train.DoorSelectR then train.DoorSelectR:TriggerInput("Set", 0) end
			if train.DoorClose then train.DoorClose:TriggerInput("Set", 0) end
		end)
	end
end

----------------------------------------------------------
--			***	TRAIN START/STOP SCRIPT END	***			--
----------------------------------------------------------

-- Смена кабины
local function ChangeCab (ply,train1,train2)
    local tim = 3
	local tim2 = tim + 1.5
	local tim3 = tim2 + 1.5
	if ply:GetNW2String("MATrainClass",""):find("720") or ply:GetNW2String("MATrainClass",""):find("722") then
		tim = 1  tim2 = tim + 1 tim3 = tim2 + 1
	end
	TrainStop(train1)	
	timer.Simple(tim, function()
		ply:ExitVehicle()
		ply:SetMoveType(8)
	end)
	timer.Simple(tim2, function()
		train2.DriverSeat:UseClientSideAnimation() -- пусть ебучую анимацию отрабатывает клиент	
		train2.DriverSeat:Use(ply,ply,3,1)
	end)
	timer.Simple(tim3, function()
		TrainStart(train2)
	end)	
end

-- Вывод станций в чат
function ulx.sts( calling_ply )
	if Metrostroi.Version > 1537278077 then
        net.Start("metrostroi_stations_gui")
        net.Send(calling_ply)
	else
		local name_num = 1
		local lng = GetConVar("metrostroi_advanced_lang"):GetString()
		if lng ~= "ru" then name_num = 2 end
		--Проверка на наличие таблицы
		if not Metrostroi.StationConfigurations then ULib.tsayError(calling_ply, lang("MapNotCongigured"), true) return end	
		local stationstable = {}
		for k,v in pairs(Metrostroi.StationConfigurations) do
			if v.names[name_num] then
				table.insert(stationstable,{id = tostring(k), name = tostring(v.names[name_num])})
			else
				table.insert(stationstable,{id = tostring(k), name = tostring(v.names[1])})
			end
		end 
		table.SortByMember(stationstable, "id",true)
		timer.Simple(0.1, function() 
			for k,v in pairs(stationstable) do
				calling_ply:ChatPrint(v.id.." - "..v.name)
			end
		end)
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
        if not Metrostroi.StationConfigurations then ULib.tsayError( calling_ply, lang("MapNotCongigured"), true ) return end

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
            ULib.tsayError( calling_ply, Format(lang("StationNotFound").." %s",station), true )
            return
        elseif #st > 1 then
            ULib.tsayError( calling_ply,  Format(lang("ManyStations").." %s:",station), true )
            for k,v in pairs(st) do
                local tbl = Metrostroi.StationConfigurations[v]
                if tbl.names and tbl.names[1] then
                    ULib.tsayError( calling_ply, Format("\t%s=%s",v,tbl.names[1]), true )
                else
                    ULib.tsayError( calling_ply, Format("\t%s",k), true )
                end
            end
            ULib.tsayError( calling_ply, lang("StationIncorrect"), true )
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
                calling_ply:SetAngles(ptbl[2] or Angle(0,0,0))
                calling_ply:SetEyeAngles(ptbl[2] or Angle(0,0,0))
                ulx.fancyLogAdmin( calling_ply, "#A "..lang("Teleported")..lang("Teleported5").." #s", st.names and st.names[1] or key)
            else
                ULib.tsayError( calling_ply, lang("StationConfigError")..key, true )
                ulx.fancyLogAdmin( calling_ply, lang("StationConfigError").."#s", key)
            end

        else
            if ptbl and ptbl[1] then
                print(Format("DEBUG1:Teleported to %s(%s) pos:%s ang:%s",st.names and st.names[1] or key,key,ptbl[1],ptbl[2]))
            else
                ulx.fancyLogAdmin( calling_ply, lang("StationConfigError").."#s", station:gsub("^%l", string.upper))
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
        ULib.tsayError( calling_ply, lang("PleaseWait").." "..math.Round(wagonslasttime + wagonswaittime - CurTime()).." "..lang("Seconds")..lang("CommandDelay"), true )
        return
    end
    wagonslasttime = CurTime()
    ulx.fancyLog(lang("ServerWagons").." #s", Metrostroi.TrainCount())
	local Wags = {}
	local Trains = {}
	local Routes = {}
	local Locs = {}
	local wag_num = 0
	local wag_str = lang("wagon1")
	
	for train in pairs(Metrostroi.SpawnedTrains) do
		if not IsValid(train) then continue end
		if not MetrostroiAdvanced.TrainList[train:GetClass()] then continue end
		local cl = train:GetClass()
		local ply = train.Owner
		if not IsValid(ply) then continue end
		if Trains[ply:Nick()] then continue end
		Trains[ply:Nick()] = MetrostroiAdvanced.TrainList[cl]
		Wags[ply:Nick()] = #train.WagonList
		local rnum = 0
		if cl:find("722") or cl:find("7175p") then
			rnum = tonumber(train.RouteNumberSys.RouteNumber)
		elseif cl:find("717_6") or cl:find("740_4") then
			rnum = train.ASNP.RouteNumber
		else
			if train.RouteNumber then
				rnum = tonumber(train.RouteNumber.RouteNumber)
			end
		end
		if table.HasValue({"gmod_subway_em508","gmod_subway_81-702","gmod_subway_81-703","gmod_subway_81-705_old","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_ezh3ru1","gmod_subway_81-717_mvm","gmod_subway_81-718","gmod_subway_81-720","gmod_subway_81-720_1","gmod_subway_81-720a","gmod_subway_81-717_freight","gmod_subway_81-717_5a", "gmod_subway_81-717_ars_minsk"},cl) then
			rnum = rnum / 10
		end
		Routes[ply:Nick()] = tostring(rnum)
		Locs[ply:Nick()] = MetrostroiAdvanced.GetLocation(train:GetPos())
	end
	
	for k,v in pairs(Trains) do
		wag_num = tonumber(Wags[k])
		if wag_num >= 2 and wag_num <= 4 then wag_str = lang("wagon2") end
		if wag_num >= 5 then wag_str = lang("wagon3") end
		ulx.fancyLog("#s:\n\t#s "..wag_str.." #s \n\t"..lang("Route")..": #s\n\t"..lang("Location")..": #s",k,wag_num,Trains[k],Routes[k],Locs[k])
	end
	local wag_awail = (GetConVar("metrostroi_maxtrains"):GetInt()*GetConVar("metrostroi_advanced_maxwagons"):GetInt())-GetGlobalInt("metrostroi_train_count")
    ulx.fancyLog(lang("WagonsAwail").." #s",wag_awail)
end
local wagons = ulx.command(CATEGORY_NAME, "ulx trains", ulx.wagons, "!trains" )
wagons:defaultAccess( ULib.ACCESS_ALL )
wagons:help( "Info about all trains on server." )

-- чат-команда для высадки пассажиров
function ulx.expass(calling_ply)
	calling_ply:ConCommand("metrostroi_expel_passengers")
end
local exps = ulx.command(CATEGORY_NAME, "ulx expass", ulx.expass, "!expass")
exps:defaultAccess(ULib.ACCESS_ALL)
exps:help("Expel all passengers.")

--metrostroi_binds_menu
-- чат-команда для меню клавиш
function ulx.binds(calling_ply)
	calling_ply:ConCommand("metrostroi_binds_menu")
end
local kbinds = ulx.command(CATEGORY_NAME, "ulx binds", ulx.binds, "!binds")
kbinds:defaultAccess(ULib.ACCESS_ALL)
kbinds:help("Show key bindings for train.")

-- телепорт в состав игрока
function ulx.traintp( calling_ply, target_ply )
	local class = target_ply:GetNW2String("MATrainClass","")
	if class == "" then return end
	local teleported = false
	local ents = ents.FindByClass(class)
	for k,v in pairs(ents) do
		if v.Owner:Nick() == target_ply:Nick() then
			if class:find("760") then
				if v.RV.KROPosition ~= 0 then
					GotoTrain(calling_ply,target_ply,v,true)
					teleported = true
				end
			elseif class:find("722") then
				if v.Electric.CabActive ~= 0 then
					GotoTrain(calling_ply,target_ply,v,true) 
					teleported = true
				end
			elseif class:find("720") then
				if v.WrenchMode ~= 0 then
					if v.RV.KROPosition ~= 0 then
						GotoTrain(calling_ply,target_ply,v,true)
						teleported = true
					end
				end
			elseif class:find("718") then
				if v.WrenchMode ~= 0 then
					if v.KR.Position ~= 0 then
						GotoTrain(calling_ply,target_ply,v,true)
						teleported = true
					end
				end
			else
				if v.KVWrenchMode ~= 0 then
					if v.KV.ReverserSet ~= 0 then
						GotoTrain(calling_ply,target_ply,v,true)
						teleported = true
					end
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
local ttp = ulx.command( CATEGORY_NAME, "ulx traintp", ulx.traintp, "!traintp" )
ttp:addParam{ type=ULib.cmds.PlayerArg, target="*", default="^", ULib.cmds.optional }
ttp:defaultAccess( ULib.ACCESS_ALL )
ttp:help( "Teleport to a player's train." )

-- телепорт к светофору по названию
function ulx.signaltp(calling_ply,signal)
	for _,sig in pairs(ents.FindByClass("gmod_track_signal")) do
		if sig.Name and sig.Name:upper() == signal:upper() then
			if calling_ply:InVehicle() then calling_ply:ExitVehicle() end
			calling_ply:SetPos(sig:GetPos())
			calling_ply:SetEyeAngles(sig:GetAngles()+Angle(0,-90,0))	
			calling_ply:SetLocalVelocity( Vector( 0, 0, 0 ) ) -- Stop!				
			return
		end
	end
	ULib.tsayError( calling_ply, lang("Signal").." "..signal.." "..lang("NotFound"), true ) 			
end
local signaltp = ulx.command( CATEGORY_NAME, "ulx signaltp", ulx.signaltp, "!signaltp" )
signaltp:addParam{ type=ULib.cmds.StringArg, hint="Signal", ULib.cmds.takeRestOfLine }
signaltp:defaultAccess( ULib.ACCESS_ADMIN )
signaltp:help( "Teleport to a signal" )

-- телепорт к любому предмету по его ID (для отладки СЦБ)
function ulx.entitytp(calling_ply, ID)
	for _,ent in pairs(ents.GetAll()) do
		if ent:EntIndex() == tonumber(ID) then
			if calling_ply:InVehicle() then calling_ply:ExitVehicle() end
			calling_ply:SetPos(ent:GetPos())
			calling_ply:SetEyeAngles(ent:GetAngles()+Angle(0,-90,0))	
			calling_ply:SetLocalVelocity( Vector( 0, 0, 0 ) ) -- Stop!				
			return
		end
	end
	ULib.tsayError( calling_ply, ID.." "..lang("NotFound"), true ) 			
end
local entitytp = ulx.command( CATEGORY_NAME, "ulx entitytp", ulx.entitytp, "!entitytp" )
entitytp:addParam{ type=ULib.cmds.StringArg, hint="ID", ULib.cmds.takeRestOfLine }
entitytp:defaultAccess( ULib.ACCESS_ADMIN )
entitytp:help("Teleport to any entity by its ID (eg. signalling debug)")

-- установить собственный бортовой номер вагона (с проверкой на дубликаты!)
function ulx.setwagnumber(ply, WagNumber)
	if not IsValid(ply) then return end
	local train = ply:GetEyeTrace().Entity
	if ((not IsValid(train)) or (not train.WagonNumber)) then
		ULib.tsayError(ply, lang("SetWagNum1"))
		return
	end
	if (train.Owner ~= ply) then
		ULib.tsayError(ply, lang("SetWagNum2"))
		return
	end
	local double = false
	for k, v in pairs(Metrostroi.SpawnedTrains) do
		if k.WagonNumber == WagNumber then
			double = true
		end
	end 
	if not double then
		train.WagonNumber = WagNumber
		train:SetNW2Int("WagonNumber",train.WagonNumber)
	else
		ULib.tsayError(ply, lang("SetWagNum3"))
	end
end
local setwagnumber = ulx.command( CATEGORY_NAME, "ulx setwagnumber", ulx.setwagnumber, "!swn")
setwagnumber:addParam{type=ULib.cmds.StringArg, hint="Wagon Number", ULib.cmds.takeRestOfLine }
setwagnumber:defaultAccess(ULib.ACCESS_ADMIN)
setwagnumber:help("Set wagon number (aim at any wagon)")

-- восстановление исходного положения удочек
function ulx.udochka( calling_ply )
	local boxes = {}
	if (game.GetMap():find("gm_mus_loopline")) then
		boxes = ents.FindByClass("func_tracktrain")
	else
		boxes = ents.FindByClass("func_physbox")
	end
	for k,v in pairs(boxes) do
		v:SetAngles(MetrostroiAdvanced.Box_Angles[k])
		v:SetPos(MetrostroiAdvanced.Box_Positions[k])
	end
	boxes = nil
	for k,v in pairs(ents.FindByClass("gmod_track_udochka")) do
		v:SetPos(MetrostroiAdvanced.Udc_Positions[k])
	end
	ulx.fancyLog("#s "..lang("UDCMessage"),calling_ply:Nick())
end
local udc = ulx.command( CATEGORY_NAME, "ulx udochka", ulx.udochka, "!udc" )
udc:defaultAccess( ULib.ACCESS_ADMIN )
udc:help( "Reset the positions of power connectors." )

-- посадить игрока в кресло машиниста
function ulx.enter( calling_ply, target_ply )
	if not IsValid(target_ply) then return end
	local train = calling_ply:GetEyeTrace().Entity
	if not IsValid(train) then ULib.tsayError( calling_ply, lang("WagonIncorrect") ) return end
	if not train.DriverSeat then ULib.tsayError( calling_ply, lang("WagonIncorrect") ) return end
	if IsValid(target_ply:GetVehicle()) then
		target_ply:ExitVehicle()
	end
	local pos = train:GetPos()
	target_ply:SetMoveType(8)
	target_ply:Freeze(true)
	target_ply:SetPos(pos-Vector(0,0,40))
	timer.Simple(0.2, function()
		train.DriverSeat:UseClientSideAnimation()
		train.DriverSeat:Use(target_ply,target_ply,3,1)
		target_ply:Freeze(false)
		if train.DriverSeat == target_ply:GetVehicle() then
			ulx.fancyLogAdmin( calling_ply, "#A "..lang("EnterPlayer").." #T "..lang("IntoTrain"), target_ply )
		else
			ULib.tsayError( calling_ply, lang("EnterFail") )
		end
	end)
end
local enter = ulx.command( CATEGORY_NAME, "ulx enter", ulx.enter, "!enter")
enter:addParam{ type = ULib.cmds.PlayerArg }
enter:defaultAccess( ULib.ACCESS_ADMIN )
enter:help( "Place a player into the driver's seat (aim at any wagon)" )

-- высадить игрока с любого места в составе
function ulx.expel( calling_ply, target_ply )
	if not IsValid(target_ply) then return end
	if not IsValid(target_ply:GetVehicle()) then
		ULib.tsayError( calling_ply, target_ply:Nick() .. " "..lang("NotInVehicle") )
		return
	else
		target_ply:ExitVehicle()
	end
	ulx.fancyLogAdmin( calling_ply, "#A "..lang("ExpelPlayer").." #T "..lang("OutTrain"), target_ply )
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
	local train = seat:GetNW2Entity("TrainEntity")
	if not IsValid(train) then return end
	local seatlink = ""
	
	local seats = {"DriverSeat","InstructorsSeat","ExtraSeat"}
	for _,st in pairs(seats) do
		for i=0,4 do
			if i == 0 then i = "" end
			if IsValid(train[st..i]) and train[st..i] == seat then
				seatlink = st..i
				break
			end
		end
	end
	
	if seatlink ~= "" then
		for t,wag in pairs(train.WagonList) do
			if (wag:GetClass() == train:GetClass() and wag ~= train) then
				calling_ply:ExitVehicle()
				calling_ply:SetMoveType(8)
				wag[seatlink]:UseClientSideAnimation()
				timer.Simple(1, function()
					wag[seatlink]:Use(calling_ply,calling_ply,3,1)
				end)
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
	if seattype ~= "driver" then return end
	local train1 = seat:GetNW2Entity("TrainEntity")
	if not IsValid(train1) then return end
	local train2
	for t,wag in pairs(train1.WagonList) do
		if (wag:GetClass() == train1:GetClass() and wag ~= train1) then
			train2 = wag
		end
	end
	ChangeCab(calling_ply,train1,train2)
end
local sch = ulx.command( CATEGORY_NAME, "ulx sch", ulx.smartch, "!sch" )
sch:defaultAccess( ULib.ACCESS_ALL )
sch:help( "Smart cabin change" )

function ulx.trainstart( calling_ply )
	if not IsValid(calling_ply) then return end
    local train = calling_ply:GetTrain()
	if not IsValid(train) then return end
	TrainStart(train)
	ulx.fancyLog("#s "..lang("UseTrainStart"),calling_ply:Nick())
end
local trainstart = ulx.command( CATEGORY_NAME, "ulx trainstart", ulx.trainstart, "!trainstart" )
trainstart:defaultAccess( ULib.ACCESS_ALL )
trainstart:help( "Cabin autostart" )

function ulx.trainstop( calling_ply )
	if not IsValid(calling_ply) then return end
    local train = calling_ply:GetTrain()
	if not IsValid(train) then return end
	TrainStop(train)
end
local trainstop = ulx.command( CATEGORY_NAME, "ulx trainstop", ulx.trainstop, "!trainstop" )
trainstop:defaultAccess( ULib.ACCESS_ALL )
trainstop:help( "Cabin stop." )

-- Обработка команд сигнализации
function ulx.sopen( calling_ply, arg )
    MetrostroiAdvanced.SignalSayHook(calling_ply,"!sopen", arg, true)
end
local sopen = ulx.command( CATEGORY_NAME, "ulx sopen", ulx.sopen, "!sopen" )
sopen:addParam{ type=ULib.cmds.StringArg, hint="Signal or route name", ULib.cmds.takeRestOfLine }
sopen:defaultAccess( ULib.ACCESS_ALL )
sopen:help( "Open signal or route" )

function ulx.sclose( calling_ply, arg )
    MetrostroiAdvanced.SignalSayHook(calling_ply,"!sclose", arg, true)
end
local sclose = ulx.command( CATEGORY_NAME, "ulx sclose", ulx.sclose, "!sclose" )
sclose:addParam{ type=ULib.cmds.StringArg, hint="Signal or route name", ULib.cmds.takeRestOfLine }
sclose:defaultAccess( ULib.ACCESS_ALL )
sclose:help( "Close signal or route" )

function ulx.sactiv( calling_ply, arg )
    MetrostroiAdvanced.SignalSayHook(calling_ply,"!sactiv", arg, true)
end
local sactiv = ulx.command( CATEGORY_NAME, "ulx sactiv", ulx.sactiv, "!sactiv" )
sactiv:addParam{ type=ULib.cmds.StringArg, hint="Signal or route name", ULib.cmds.takeRestOfLine }
sactiv:defaultAccess( ULib.ACCESS_ALL )
sactiv:help( "Enable auxulary signals" )

function ulx.sdeactiv( calling_ply, arg )
    MetrostroiAdvanced.SignalSayHook(calling_ply,"!sdeactiv", arg, true)
end
local sdeactiv = ulx.command( CATEGORY_NAME, "ulx sdeactiv", ulx.sdeactiv, "!sdeactiv" )
sdeactiv:addParam{ type=ULib.cmds.StringArg, hint="Signal or route name", ULib.cmds.takeRestOfLine }
sdeactiv:defaultAccess( ULib.ACCESS_ALL )
sdeactiv:help( "Disable auxulary signals" )

function ulx.sopps( calling_ply, arg )
    MetrostroiAdvanced.SignalSayHook(calling_ply,"!sopps", arg, true)
end
local sopps = ulx.command( CATEGORY_NAME, "ulx sopps", ulx.sopps, "!sopps" )
sopps:addParam{ type=ULib.cmds.StringArg, hint="Signal or route name", ULib.cmds.takeRestOfLine }
sopps:defaultAccess( ULib.ACCESS_ALL )
sopps:help( "Open invitation signal" )

function ulx.sclps( calling_ply, arg )
    MetrostroiAdvanced.SignalSayHook(calling_ply,"!sclps", arg, true)
end
local sclps = ulx.command( CATEGORY_NAME, "ulx sclps", ulx.sclps, "!sclps" )
sclps:addParam{ type=ULib.cmds.StringArg, hint="Signal or route name", ULib.cmds.takeRestOfLine }
sclps:defaultAccess( ULib.ACCESS_ALL )
sclps:help( "Close invitation signal" )

if Metrostroi.Version > 1537278077 then
	function ulx.senao( calling_ply, arg )
		MetrostroiAdvanced.SignalSayHook(calling_ply,"!senao", arg, true)
	end
	local senao = ulx.command( CATEGORY_NAME, "ulx senao", ulx.senao, "!senao" )
	senao:addParam{ type=ULib.cmds.StringArg, hint="Signal", ULib.cmds.takeRestOfLine }
	senao:defaultAccess( ULib.ACCESS_ALL )
	senao:help( "Enable absolute stop signal" )

	function ulx.sdisao( calling_ply, arg )
		MetrostroiAdvanced.SignalSayHook(calling_ply,"!sdisao", arg, true)
	end
	local sdisao = ulx.command( CATEGORY_NAME, "ulx sdisao", ulx.sdisao, "!sdisao" )
	sdisao:addParam{ type=ULib.cmds.StringArg, hint="Signal", ULib.cmds.takeRestOfLine }
	sdisao:defaultAccess( ULib.ACCESS_ALL )
	sdisao:help( "Disable absolute stop signal" )
end

if SERVER then
	-- Регистрация прав ULX
	
	-- Составы загружаем из файла, потому что Metrostroi.TrainClasses появляется позже, чем можно добавить права ULX
	if file.Exists("metrostroi_advanced/trains.txt","DATA") then
		local trains = string.Explode("\n", file.Read("metrostroi_advanced/trains.txt","DATA"))
		for k, v in pairs (trains) do
			if v ~= "" then ULib.ucl.registerAccess(v, ULib.ACCESS_ALL, "Spawn train "..v, CATEGORY_NAME) end
		end
	end
	ULib.ucl.registerAccess("add_1wagons", ULib.ACCESS_ADMIN, "Spawn +1 wagon more", CATEGORY_NAME)
	ULib.ucl.registerAccess("add_2wagons", ULib.ACCESS_ADMIN, "Spawn +2 wagons more", CATEGORY_NAME)
	ULib.ucl.registerAccess("add_3wagons", ULib.ACCESS_ADMIN, "Spawn +3 wagons more", CATEGORY_NAME)
	ULib.ucl.registerAccess("add_4wagons", ULib.ACCESS_ADMIN, "Spawn +4 wagons more", CATEGORY_NAME)
	ULib.ucl.registerAccess("metrostroi_station_spawn", ULib.ACCESS_ALL, "Spawn in stations", CATEGORY_NAME)
	ULib.ucl.registerAccess("metrostroi_anyplace_spawn", ULib.ACCESS_ALL, "Spawn anywhere", CATEGORY_NAME)
end