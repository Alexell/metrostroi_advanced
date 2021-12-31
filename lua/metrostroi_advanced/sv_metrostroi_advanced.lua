------------------------ Metrostroi Advanced -------------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- Version: 2.3
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_advanced
----------------------------------------------------------------------

if CLIENT then return end

-- CVars
local spawn_int = CreateConVar("metrostroi_advanced_spawninterval", 0, {FCVAR_ARCHIVE})
local train_rest = CreateConVar("metrostroi_advanced_trainsrestrict", 0, {FCVAR_ARCHIVE})
local spawn_mes = CreateConVar("metrostroi_advanced_spawnmessage", 1, {FCVAR_ARCHIVE})
local max_wags = CreateConVar("metrostroi_advanced_maxwagons", 4, {FCVAR_ARCHIVE})
local min_wags = CreateConVar("metrostroi_advanced_minwagons", 2, {FCVAR_ARCHIVE})
local auto_wags = CreateConVar("metrostroi_advanced_autowags", 0, {FCVAR_ARCHIVE})
local madv_lang = CreateConVar("metrostroi_advanced_lang", "ru", {FCVAR_ARCHIVE})
local afktime = CreateConVar("metrostroi_advanced_afktime", 0, {FCVAR_ARCHIVE})
local timezone = CreateConVar("metrostroi_advanced_timezone", 3, {FCVAR_ARCHIVE})
local buttonmessage = CreateConVar("metrostroi_advanced_buttonmessage", 1, {FCVAR_ARCHIVE})
local noentry_ann = CreateConVar("metrostroi_advanced_noentryann", 1, {FCVAR_ARCHIVE})

util.AddNetworkString("MA.ServerCommands")
util.AddNetworkString("MA.AddNewButtons")

AFK_TIME = 0
AFK_WARN1 = 0
AFK_WARN2 = 0
AFK_WARN3 = 60

timer.Create("MetrostroiAdvancedInit",1,1,function()
	if (not file.Exists("metrostroi_advanced","DATA")) then
		file.CreateDir("metrostroi_advanced")
	end
	MetrostroiAdvanced.LoadLanguage(GetConVarString("metrostroi_advanced_lang"))
	MetrostroiAdvanced.LoadStationsIgnore()
	MetrostroiAdvanced.LoadMapWagonsLimit()
	MetrostroiAdvanced.LoadMapButtons()
	SetGlobalInt("TrainLastSpawned",os.time())
	if not file.Exists("sound/metrostroi_advanced/no_entry_ann/"..madv_lang:GetString(),"GAME") then
		RunConsoleCommand("metrostroi_advanced_noentryann",0)
		print("Metrostroi Advanced: Sounds for '"..madv_lang:GetString().."' language not found!")
		print("Metrostroi Advanced: No Entry Announces DISABLED.")
	end
end)

concommand.Add("ma_save_buttonoutput", function( ply, cmd, args )
	if not ply:IsAdmin() then return end
	local fl = file.Read("metrostroi_advanced/map_buttons.txt","DATA")
	local tab = fl and util.JSONToTable(fl) or {}
	tab[game.GetMap()] = MetrostroiAdvanced.MapButtonNames
	file.Write("metrostroi_advanced/map_buttons.txt",util.TableToJSON(tab,true))
end)
	
cvars.AddChangeCallback("metrostroi_advanced_lang", function(cvar, old, new)
    MetrostroiAdvanced.LoadLanguage(new)
end)
local function lang(str)
	return MetrostroiAdvanced.Lang[str]
end

AFK_TIME = GetConVarNumber("metrostroi_advanced_afktime") * 60
cvars.AddChangeCallback("metrostroi_advanced_afktime", function(cvar, old, new)
    AFK_TIME = new * 60
	AFK_WARN1 = AFK_TIME * 0.6
	AFK_WARN2 = AFK_TIME * 0.4
end)

net.Receive("MA.ServerCommands",function(ln,ply)
	if (not ply:IsAdmin()) then return end
	local com = net.ReadString()
	local val = net.ReadString()
	if (com == "ma_voltage") then com = "metrostroi_voltage" end
	if (com == "ma_curlim") then com = "metrostroi_current_limit" end
	if (com == "ma_requirethirdrail") then com = "metrostroi_train_requirethirdrail" end
	RunConsoleCommand(com,val)
end)

net.Receive("MA.AddNewButtons",function(ln,ply)
	if not IsValid(ply) then return end
	local sourcename = net.ReadString()
	local outputname = net.ReadString()
	MetrostroiAdvanced.MapButtonNames[sourcename] = outputname
end)

local function PlayerPermission(ply,permission)
	if ULib then
		return ULib.ucl.query(ply,permission)
	else
		return ply:IsSuperAdmin()
	end
end

hook.Add("MetrostroiSpawnerRestrict","TrainSpawnerLimits",function(ply,settings)
	if not IsValid(ply) then return end
	-- ограничение составов по правам ULX
	local train_restrict = GetConVarNumber("metrostroi_advanced_trainsrestrict")
	local train = settings.Train
	
	if (train_restrict == 1) then
		if (not PlayerPermission(ply,train)) then
			ply:ChatPrint(lang("SpawnerRestrict1"))
			ply:ChatPrint(lang("SpawnerRestrict2"))
			for k, v in pairs (MetrostroiAdvanced.TrainList) do
				if string.find(k,"custom") then continue end
				if (PlayerPermission(ply,k)) then
					ply:ChatPrint(v)
				end
			end
			return true
		end
	end
	
	-- система рассчета вагонов для спавна
	local max_wagons = GetConVarNumber("metrostroi_maxtrains") * GetConVarNumber("metrostroi_advanced_maxwagons")
	local cur_wagons = GetGlobalInt("metrostroi_train_count")
	local ply_wagons
	local wag_awail = max_wagons-cur_wagons
	if GetConVarNumber("metrostroi_advanced_autowags") == 1 then
		if (cur_wagons < 8) then
			ply_wagons = 4
		else
			ply_wagons = 3
		end
	else
		ply_wagons = GetConVarNumber("metrostroi_advanced_maxwagons")
	end

	if (PlayerPermission(ply,"add_4wagons")) then
		ply_wagons = ply_wagons + 4
		if ply_wagons > GetConVarNumber("metrostroi_maxwagons") then ply_wagons = GetConVarNumber("metrostroi_maxwagons") end
	elseif (PlayerPermission(ply,"add_3wagons")) then
		ply_wagons = ply_wagons + 3
		if ply_wagons > GetConVarNumber("metrostroi_maxwagons") then ply_wagons = GetConVarNumber("metrostroi_maxwagons") end
	else
		if (PlayerPermission(ply,"add_2wagons")) then
			ply_wagons = ply_wagons + 2
		else
			if (PlayerPermission(ply,"add_1wagons")) then
				ply_wagons = ply_wagons + 1
			end
		end
	end
	if ply_wagons > wag_awail then ply_wagons = wag_awail end
	
	if settings.WagNum < GetConVarNumber("metrostroi_advanced_minwagons") then
		settings.WagNum = GetConVarNumber("metrostroi_advanced_minwagons")
		ply:ChatPrint(lang("FewWagons").." "..tostring(GetConVarNumber("metrostroi_advanced_minwagons"))..".")
	end
	
	local map_wagons = MetrostroiAdvanced.MapWagons[game.GetMap()] or 0
	local wag_str = lang("wagon1")
	if map_wagons > 0 and not ply:IsAdmin() then
		if settings.WagNum > map_wagons then
			if map_wagons >= 2 and map_wagons <= 4 then wag_str = lang("wagon2") end
			if map_wagons == 0 or map_wagons >= 5 then wag_str = lang("wagon3") end
			ply:ChatPrint(lang("MapWagonsLimit"))
			ply:ChatPrint(lang("Wagonsrestrict2").." "..map_wagons.." "..wag_str..".")
			return true
		end
	end
	
	if (settings.WagNum > ply_wagons) then
		wag_str = lang("wagon1")
		if ply_wagons >= 2 and ply_wagons <= 4 then wag_str = lang("wagon2") end
		if ply_wagons == 0 or ply_wagons >= 5 then wag_str = lang("wagon3") end
		if wag_awail == 0 then
			ply:ChatPrint(lang("NoWagons1"))
			ply:ChatPrint(lang("NoWagons2"))
		else
			ply:ChatPrint(lang("Wagonsrestrict1"))
			ply:ChatPrint(lang("Wagonsrestrict2").." "..ply_wagons.." "..wag_str..".")
		end
		return true
	end

	--спавн в любом месте / спавн на станции
	if Metrostroi.StationConfigurations then
		if (not PlayerPermission(ply,"metrostroi_anyplace_spawn")) then
			local tr = util.TraceLine(util.GetPlayerTrace(ply))
			local loc = ""
			if tr.Hit then
				loc = MetrostroiAdvanced.GetLocation(ply,tr.HitPos)
			end
			if (not PlayerPermission(ply,"metrostroi_station_spawn")) then
				local founded = false
				for k,v in pairs(MetrostroiAdvanced.StationsIgnore) do
					if loc:find(v) then founded = true break end
				end
				if not founded then
					ply:ChatPrint(lang("StationRestrict"))
					return true
				end
			end
			if (loc == lang("UnknownPlace")) then
				ply:ChatPrint(lang("AnyPlaceRestrict"))
				return true
			end
		end
	end
	
	-- задержка спавна
	local spawnint = GetConVarNumber("metrostroi_advanced_spawninterval")
	if (spawnint > 0) then
		local lastspawn = GetGlobalInt("TrainLastSpawned",0)
		local curtime = os.time()
		local curint = curtime - lastspawn
		if (curint < spawnint) then
			local secs = spawnint - curint
			ply:ChatPrint(lang("PleaseWait").." "..secs.." "..lang("Seconds").." "..lang("WaitSpawn"))
			return true
		end
	end

	-- спавн разрешен
	if (GetConVarNumber("metrostroi_advanced_spawnmessage") == 1) then
		local wag_str = lang("wagon1")
		local wag_num = settings.WagNum
		if wag_num >= 2 and wag_num <= 4 then wag_str = lang("wagon2") end
		if wag_num >= 5 then wag_str = lang("wagon3") end
		if ulx then
			ulx.fancyLog(lang("Player").." #s "..lang("Spawned").." #s #s #s.\n"..lang("Location")..": #s.",ply:Nick(),tostring(wag_num),wag_str,MetrostroiAdvanced.GetTrainName(settings.Train),MetrostroiAdvanced.GetLocation(ply))
		end
	end
	if (settings.Train == "gmod_subway_81-717_mvm_custom") then
		ply:SetNW2String("MATrainClass","gmod_subway_81-717_mvm")
	elseif(settings.Train == "gmod_subway_81-717_lvz_custom") then
		ply:SetNW2String("MATrainClass","gmod_subway_81-717_lvz")
	else
		ply:SetNW2String("MATrainClass",settings.Train)
	end
	SetGlobalInt("TrainLastSpawned",os.time())
	return
end)
	
hook.Add("PlayerInitialSpawn","SetPlyParams",function(ply)
	-- выдаем игроку уникальный номер маршрута на время сессии
	if (ply:GetInfoNum("ma_routenums",1) == 1) then
		local rnum = MetrostroiAdvanced.GetRouteNumber(ply)
		ply:SetNW2Int("MARouteNumber",rnum)
	end
	if AFK_TIME > 0 then
		ply.NextAFK = CurTime() + AFK_TIME
		ply.WarningAFK = 0
	end
	
	-- выставляем кварам клиента серверное значение при спавне
	if (ply:IsAdmin()) then
		ply:ConCommand("metrostroi_advanced_spawninterval "..GetConVarNumber("metrostroi_advanced_spawninterval"))
		ply:ConCommand("metrostroi_advanced_trainsrestrict "..GetConVarNumber("metrostroi_advanced_trainsrestrict"))
		ply:ConCommand("metrostroi_advanced_spawnmessage "..GetConVarNumber("metrostroi_advanced_spawnmessage"))
		ply:ConCommand("metrostroi_advanced_minwagons "..GetConVarNumber("metrostroi_advanced_minwagons"))
		ply:ConCommand("metrostroi_advanced_maxwagons "..GetConVarNumber("metrostroi_advanced_maxwagons"))
		ply:ConCommand("metrostroi_advanced_autowags "..GetConVarNumber("metrostroi_advanced_autowags"))
		ply:ConCommand("metrostroi_advanced_afktime "..GetConVarNumber("metrostroi_advanced_afktime"))
		ply:ConCommand("metrostroi_advanced_timezone "..GetConVarNumber("metrostroi_advanced_timezone"))
		ply:ConCommand("metrostroi_advanced_buttonmessage "..GetConVarNumber("metrostroi_advanced_buttonmessage"))
		--
		ply:ConCommand("ma_voltage "..GetConVarNumber("metrostroi_voltage"))
		ply:ConCommand("ma_curlim "..GetConVarNumber("metrostroi_current_limit"))
		ply:ConCommand("ma_requirethirdrail "..GetConVarNumber("metrostroi_train_requirethirdrail"))
	end
end)

hook.Add("PlayerButtonDown","PlayerActions",function(ply,key)
	if AFK_TIME > 0 then
		ply.NextAFK = CurTime() + AFK_TIME
		ply.WarningAFK = 0
	end
end)

hook.Add("Think","ControlAFKPlayers", function()
	if AFK_TIME > 0 then
		for _, ply in pairs(player.GetAll()) do
			if (ply:IsConnected() and ply:IsFullyAuthenticated() and not ply:IsAdmin()) then
				if (not ply.NextAFK) then
					ply.NextAFK = CurTime() + AFK_TIME
				end
				if (ply.NextAFK <= CurTime() + AFK_WARN1) and (ply.WarningAFK == 0) then
					local min_left =  math.Round((ply.NextAFK - CurTime()) / 60)
					ply:ChatPrint("[Metrostroi Advanced]: "..string.format(lang("AfkWarning"),tostring(min_left),lang("Afkmins")))
					ply.WarningAFK = 1
				end
				if (ply.NextAFK <= CurTime() + AFK_WARN2) and (ply.WarningAFK == 1) then
				local min_left =  math.Round((ply.NextAFK - CurTime()) / 60)
					ply:ChatPrint("[Metrostroi Advanced]: "..string.format(lang("AfkWarning"),tostring(min_left),lang("Afkmins")))
					ply.WarningAFK = 2
				end
				if (ply.NextAFK <= CurTime() + AFK_WARN3) and (ply.WarningAFK == 2) then
					local min_left = 1
					ply:ChatPrint("[Metrostroi Advanced]: "..string.format(lang("AfkWarning"),tostring(min_left),lang("Afkmin1")))
					ply.WarningAFK = 3
				end
				if (CurTime() >= ply.NextAFK and ply.WarningAFK == 3) then
					ply.WarningAFK = nil
					ply.NextAFK = nil
					ply:Kick("[Metrostroi Advanced] - "..lang("AfkKick"))
				end
			end
		end
	end
end)

hook.Add("MetrostroiCoupled","SetTrainParams",function(ent,ent2)
	if IsValid(ent) and IsValid(ent2) then
		-- устанавливаем номер маршрута на состав
		local ply = ent.Owner
		if (ply:GetInfoNum("ma_routenums",1) == 0) then return end
		local rnum = ply:GetNW2Int("MARouteNumber")
		if MetrostroiAdvanced.TrainList[ent:GetClass()] then
			if table.HasValue({"gmod_subway_81-702","gmod_subway_81-703","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_ezh3ru1","gmod_subway_81-717_mvm","gmod_subway_81-718","gmod_subway_81-720","gmod_subway_81-720_1","gmod_subway_81-720a","gmod_subway_81-717_freight"},ent:GetClass()) then rnum = rnum * 10 end

			if ent:GetClass() == "gmod_subway_81-540_2" then
				local rtype = ent:GetNW2Int("Route",1)
				if rtype == 1 then
					ent.RouteNumbera.RouteNumbera = tostring(rnum).."0"
					ent:SetNW2String("RouteNumbera",tostring(rnum).."0")
				end
				if rtype == 2 then
					ent.RouteNumbera.RouteNumbera = "0"..tostring(rnum)
					ent:SetNW2String("RouteNumbera","0"..tostring(rnum))
				end
				if rtype == 3 then
					if ent.RouteNumberSys then
						ent.RouteNumberSys.CurrentRouteNumber = rnum
					end
				end
			elseif ent:GetClass() == "gmod_subway_81-540_2k" then
				ent.RouteNumber.RouteNumber = rnum
				ent.RouteNumber.CurrentRouteNumber = rnum
			elseif ent:GetClass() == "gmod_subway_81-722" or ent:GetClass() == "gmod_subway_81-722_3" or ent:GetClass() == "gmod_subway_81-722_new" or ent:GetClass() == "gmod_subway_81-7175p" then
				ent.RouteNumberSys.CurrentRouteNumber = rnum
			elseif ent:GetClass() == "gmod_subway_81-717_6" then
				ent.ASNP.RouteNumber = rnum
			elseif ent:GetClass() == "gmod_subway_81-502" or ent:GetClass() == "gmod_subway_81-540" or ent:GetClass() == "gmod_subway_81-540_1" or ent:GetClass() == "gmod_subway_81-540_8" or ent:GetClass() == "gmod_subway_81-717_lvz" then
				ent.RouteNumber.RouteNumber = "0"..tostring(rnum)
				ent:SetNW2String("RouteNumber","0"..tostring(rnum))
			elseif ent:GetClass() == "gmod_subway_81-760" or ent:GetClass() == "gmod_subway_81-760a" then
				ent.BMCIS.RouteNumber = rnum
				ent:SetNW2Int("RouteNumber:RouteNumber",rnum)
				ent.RouteNumber.RouteNumber = rnum
			else
				if ent.RouteNumber then
					ent.RouteNumber.RouteNumber = tostring(rnum)
					ent:SetNW2String("RouteNumber",tostring(rnum))
				end
			end
		end
		if MetrostroiAdvanced.TrainList[ent2:GetClass()] then
			if table.HasValue({"gmod_subway_81-702","gmod_subway_81-703","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_ezh3ru1","gmod_subway_81-717_mvm","gmod_subway_81-718","gmod_subway_81-720","gmod_subway_81-720_1","gmod_subway_81-720a","gmod_subway_81-717_freight"},ent2:GetClass()) then rnum = rnum * 10 end
			
			if ent2:GetClass() == "gmod_subway_81-540_2" then
				local rtype = ent2:GetNW2Int("Route",1)
				if rtype == 1 then
					ent2.RouteNumbera.RouteNumbera = tostring(rnum).."0"
					ent2:SetNW2String("RouteNumbera",tostring(rnum).."0")
				end
				if rtype == 2 then
					ent2.RouteNumbera.RouteNumbera = "0"..tostring(rnum)
					ent2:SetNW2String("RouteNumbera","0"..tostring(rnum))
				end
				if rtype == 3 then
					if ent2.RouteNumberSys then
						ent2.RouteNumberSys.CurrentRouteNumber = rnum
					end
				end
			elseif ent2:GetClass() == "gmod_subway_81-540_2k" then
				ent2.RouteNumber.RouteNumber = rnum
				ent2.RouteNumber.CurrentRouteNumber = rnum
			elseif ent2:GetClass() == "gmod_subway_81-722" or ent2:GetClass() == "gmod_subway_81-722_3" or ent2:GetClass() == "gmod_subway_81-722_new" or ent2:GetClass() == "gmod_subway_81-7175p" then
				ent2.RouteNumberSys.CurrentRouteNumber = rnum
			elseif ent2:GetClass() == "gmod_subway_81-717_6" then
				ent2.ASNP.RouteNumber = rnum
			elseif ent2:GetClass() == "gmod_subway_81-502" or ent2:GetClass() == "gmod_subway_81-540" or ent2:GetClass() == "gmod_subway_81-540_1" or ent2:GetClass() == "gmod_subway_81-540_8" or ent2:GetClass() == "gmod_subway_81-717_lvz" then
				ent2.RouteNumber.RouteNumber = "0"..tostring(rnum)
				ent2:SetNW2String("RouteNumber","0"..tostring(rnum))
			elseif ent2:GetClass() == "gmod_subway_81-760" or ent2:GetClass() == "gmod_subway_81-760a" then
				ent2.BMCIS.RouteNumber = rnum
				ent2:SetNW2Int("RouteNumber:RouteNumber",rnum)
				ent2.RouteNumber.RouteNumber = rnum
			else
				if ent2.RouteNumber then
					ent2.RouteNumber.RouteNumber = tostring(rnum)
					ent2:SetNW2String("RouteNumber",tostring(rnum))
				end
			end
		end
	end
end)


hook.Add("EntityRemoved","DeleteTrainParams",function (ent)
	if MetrostroiAdvanced.TrainList[ent:GetClass()] then
		local ply = ent.Owner
		if not IsValid(ply) then return end
		ply:SetNW2String("MATrainClass","")
	end
end)

-- Список объявлений
local snd_dir = "metrostroi_advanced/no_entry_ann/"..madv_lang:GetString()
local ann_sounds = {}
ann_sounds[1] = {snd_dir.."/p1/1.mp3",snd_dir.."/p1/2.mp3",snd_dir.."/p1/3.mp3",snd_dir.."/p1/4.mp3",snd_dir.."/p1/5.mp3"}
ann_sounds[2] = {snd_dir.."/p2/1.mp3",snd_dir.."/p2/2.mp3",snd_dir.."/p2/3.mp3",snd_dir.."/p2/4.mp3",snd_dir.."/p2/5.mp3"}
ann_sounds[3] = {snd_dir.."/p3/1.mp3"}
ann_sounds[4] = {snd_dir.."/p4/1.mp3"}

-- Инжект в код платформ
timer.Simple(1,function()
	for k,v in pairs(ents.FindByClass("gmod_track_platform")) do
		local OriginalThink = v.Think
		local Think = function()
			OriginalThink(v)
			if (not v.AITimer) then v.AITimer = CurTime() end
			if ((CurTime() - v.AITimer) < 1 ) then return end -- задержка выполнения
			v.AITimer = CurTime()
			if (not IsValid(v.CurrentTrain)) then return end
			local ctrain = v.CurrentTrain
			if (not MetrostroiAdvanced.IsHeadWagon(ctrain)) then return end
			
			-- Объявление на станции, если на прибывающий поезд посадки нет
			if noentry_ann:GetInt() == 1 then
				if ctrain.Speed > 15 and (not v.LastCurrentTrain or ctrain ~= v.LastCurrentTrain) then
					v.LastCurrentTrain = ctrain
					local last_st = MetrostroiAdvanced.GetLastStationID(ctrain)
					if last_st > -1 then
						local play_snd
						if v.PlatformIndex > 2 then
							play_snd = ann_sounds[v.PlatformIndex][1]
						else
							play_snd = ann_sounds[v.PlatformIndex][math.random(5)]
						end

						if last_st < 1000 then
							if (tonumber(v.StationIndex) == last_st and not MetrostroiAdvanced.IsRealLastStation(v.StationIndex)) then
								--v:PlayAnnounce(2,play_snd) не хочет работать :(
								sound.Play(play_snd,LerpVector(0.33,v.PlatformStart,v.PlatformEnd),120,100,0.5)
								sound.Play(play_snd,LerpVector(0.33,v.PlatformEnd,v.PlatformStart),120,100,0.5)
								for _,wag in pairs(ctrain.WagonList) do wag.AnnouncementToLeaveWagon = true end -- высадка пассажиров
							end
						else
							local rtrain
							for t,wag in pairs(ctrain.WagonList) do
								if (wag:GetClass() == ctrain:GetClass() and wag ~= ctrain) then
									rtrain = wag
								end
							end
							if not MetrostroiAdvanced.IsRealLastStation(v.StationIndex) or (MetrostroiAdvanced.IsRealLastStation(v.StationIndex) and IsValid(rtrain) and rtrain:ReadCell(49162) == 0) then -- на реальной конечной только при выезде из тупика
								--v:PlayAnnounce(2,play_snd) не хочет работать :(
								sound.Play(play_snd,LerpVector(0.33,v.PlatformStart,v.PlatformEnd),120,100,0.5)
								sound.Play(play_snd,LerpVector(0.33,v.PlatformEnd,v.PlatformStart),120,100,0.5)
								for _,wag in pairs(ctrain.WagonList) do wag.AnnouncementToLeaveWagon = true end -- высадка пассажиров
							end
						end
					end
				elseif not v.CurrentTrain then
					v.LastCurrentTrain = nil
				end
			end
			
			-- Автоматическое проигрывание записи информатора по прибытию на станцию
			local ply = ctrain.Owner
			if (not IsValid(ply)) then return end
			if (ply:GetInfoNum("ma_autoinformator",1) == 0) then return end
			pmidpos = Metrostroi.GetPositionOnTrack(LerpVector(0.5,v.PlatformStart,v.PlatformEnd))
			pmidpos_id = pmidpos[1].node1.id
			trainpos = Metrostroi.GetPositionOnTrack(ctrain:GetPos())
			trainpos_id = trainpos[1].node1.id
			if ((trainpos_id > (pmidpos_id - 1)) and (trainpos_id < (pmidpos_id + 1))) then
				if (ctrain.BMCIS) then
					if ctrain:GetNW2Bool("BMCISArrived",true) then return end
					if (#ctrain.Announcer.Schedule ~= 0) then return end
					ctrain.BMCIS:Trigger("R_Program1",1)
				elseif (ctrain.ASNP) then
					if ctrain:GetNW2Bool("ASNP:Arrived",true) then return end
					if ctrain:GetNW2Bool("ASNP:Playing") then return end
					ctrain.ASNP:Trigger("R_Program1",1)
				end
			end
		end
		v.Think = Think
	end
end)

-- Вывод в чат нажатия кнопок на карте
timer.Simple(5,function()	-- отсекаем лишний высер в лог на старте карт
	hook.Add("AcceptInput", "MA.ButtonUsedOutputs", function(ent, input, activator, caller, value)
		if(GetConVar("metrostroi_advanced_buttonmessage"):GetInt() == 0) then return end
		if IsValid(ent) and ent:GetClass() == "func_button" then
			local Nick
			local ButtonName
			if MetrostroiAdvanced.MapButtonNames[ent:GetName()] == nil then
				ButtonName = ent:GetName()
			else 
				ButtonName = MetrostroiAdvanced.MapButtonNames[ent:GetName()]
			end
			if input == "Use" then
				if IsValid(activator) and activator:GetClass() == "player" then				
					if IsValid(caller) and caller:GetClass() == "player" then 
						Nick = caller:Nick()
						ulx.fancyLog("#s "..lang("PressedButton").." #s",Nick,ButtonName)
					end	
				end
			elseif input == "Press" then
				Nick = "Someone"
				ulx.fancyLog("#s "..lang("PressedButton").." #s",Nick,ButtonName)
			end
		end
	end)
end)
