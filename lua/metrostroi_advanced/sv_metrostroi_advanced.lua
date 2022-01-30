------------------------ Metrostroi Advanced -------------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- Version: 2.4
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_advanced
----------------------------------------------------------------------

if CLIENT then return end

-- CVars
local spawn_int = CreateConVar("metrostroi_advanced_spawninterval", 0, FCVAR_ARCHIVE, "Global delay between spawns in seconds (def = 0 - disabled)")
local train_rest = CreateConVar("metrostroi_advanced_trainsrestrict", 0, FCVAR_ARCHIVE, "Global train restrictions convar for ulx groups (def = 0 - disabled)")
local spawn_mes = CreateConVar("metrostroi_advanced_spawnmessage", 1, FCVAR_ARCHIVE, "Global chat outputs for every spawned train (def = 1 - enabled)")
local max_wags = CreateConVar("metrostroi_advanced_maxwagons", 4, FCVAR_ARCHIVE, "Maximum wagon count for a player to spawn (def = 4)")
local min_wags = CreateConVar("metrostroi_advanced_minwagons", 2, FCVAR_ARCHIVE, "Minimum wagon count for a player to spawn (def = 2)")
local auto_wags = CreateConVar("metrostroi_advanced_autowags", 0, FCVAR_ARCHIVE, "Automatic permission to spawn 4 wagons instead of 3 wagons for the first 3 players to spawn a train, in case metrostroi_advanced_maxwagons convar is set to less than 4 (def = 0 - disabled)")
local madv_lang = CreateConVar("metrostroi_advanced_lang", "ru", FCVAR_ARCHIVE, "Addon localization, available languages: 'ru' or 'en' (def = 'ru')")
local afktime = CreateConVar("metrostroi_advanced_afktime", 0, FCVAR_ARCHIVE, "Time in minutes before a player is kicked for being AFK (def = 0 - disabled)")
local timezone = CreateConVar("metrostroi_advanced_timezone", 3, FCVAR_ARCHIVE, "Server time zone, def = 3 (Moscow local time)")
local buttonmessage = CreateConVar("metrostroi_advanced_buttonmessage", 1, FCVAR_ARCHIVE, "Enable chat notifications for station control panel's buttons (def = 1 - enabled)")
local noentry_ann = CreateConVar("metrostroi_advanced_noentryann", 1, FCVAR_ARCHIVE, "Enable automatic station announcements when there is no entry on an arriving train (def = 1 - enabled)")
local twotosix_rest = CreateConVar("metrostroi_advanced_26restrict", 0, FCVAR_ARCHIVE, "Train restrictions for maps with 2/6 signalling (def = 0 - disabled)")

util.AddNetworkString("MA.ServerCommands")
util.AddNetworkString("MA.AddNewButtons")

local AFK_TIME = 0
local AFK_WARN1 = 0
local AFK_WARN2 = 0
local AFK_WARN3 = 60

timer.Create("MetrostroiAdvanced.Init",3,1,function()
	if (not file.Exists("metrostroi_advanced","DATA")) then
		file.CreateDir("metrostroi_advanced")
	end
	MetrostroiAdvanced.LoadLanguage(madv_lang:GetString())
	MetrostroiAdvanced.LoadStationsIgnore()
	MetrostroiAdvanced.LoadMapWagonsLimit()
	MetrostroiAdvanced.LoadMapButtons()
	MetrostroiAdvanced.GetSignallingType()
	MetrostroiAdvanced.LastSpawned = os.time()
	if not file.Exists("sound/metrostroi_advanced/no_entry_ann/"..madv_lang:GetString(),"GAME") then
		RunConsoleCommand("metrostroi_advanced_noentryann",0)
		MsgC(Color(0,80,255),"[Metrostroi Advanced] Sounds for '"..madv_lang:GetString().."' language not found!\n")
		MsgC(Color(0,80,255),"[Metrostroi Advanced] No Entry Announces DISABLED.\n")
	end
	if Metrostroi.Version > 1537278077 then
		if ulx then
			hook.Remove("PlayerSay","metrostroi-signal-say")
			MSignalSayHook = MetrostroiAdvanced.SignalSayHook
		end
	end
	timer.Remove("MetrostroiAdvanced.Init")
end)

if Metrostroi.Version == 1537278077 then
	timer.Simple(0.5, function()
		local ENT = scripted_ents.GetStored("gmod_track_signal").t
		function ENT:Initialize()
			self:SetModel("models/metrostroi/signals/mus/ars_box.mdl")
			self.Sprites = {}
			self.Sig = ""
			self.FreeBS = 1
			self.OldBSState = 1
			self.OutputARS = 1
			self.EnableDelay = {}
			self.PostInitalized = true

			self.Controllers = nil
		end
	end)
end

concommand.Add("ma_save_buttonoutput", function( ply, cmd, args )
	if not ply:IsAdmin() then return end
	local fl = file.Read("metrostroi_advanced/map_buttons.txt","DATA")
	local tab = fl and util.JSONToTable(fl) or {}
	tab[game.GetMap()] = MetrostroiAdvanced.MapButtonNames
	file.Write("metrostroi_advanced/map_buttons.txt",util.TableToJSON(tab,true))
end)

local function lang(str)
	return MetrostroiAdvanced.Lang[str]
end
AFK_TIME = afktime:GetInt() * 60

timer.Simple(1.5,function()
	cvars.AddChangeCallback("metrostroi_advanced_lang", function(cvar, old, new)
		if (old == new) then return end
		MetrostroiAdvanced.LoadLanguage(new)
	end)
	cvars.AddChangeCallback("metrostroi_advanced_afktime", function(cvar, old, new)
		if (old == new) then return end
		AFK_TIME = new * 60
		AFK_WARN1 = AFK_TIME * 0.6
		AFK_WARN2 = AFK_TIME * 0.4
	end)
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

hook.Add("MetrostroiSpawnerRestrict","MA.TrainSpawnerLimits",function(ply,settings)
	if not IsValid(ply) then return end
	-- ограничение составов по правам ULX
	local train = settings.Train
	
	if (train_rest:GetInt() == 1) then
		if (not PlayerPermission(ply,train)) then
			ply:ChatPrint(lang("SpawnerRestrict1"))
			ply:ChatPrint(lang("SpawnerRestrict2"))
			for k,v in pairs (MetrostroiAdvanced.TrainList) do
				if string.find(k,"custom") then continue end
				if (PlayerPermission(ply,k)) then
					ply:ChatPrint(v)
				end
			end
			return true
		end
	end
	
	-- ограничение составов на картах с сигналкой 2/6
	if (twotosix_rest:GetInt() == 1 and MetrostroiAdvanced.TwoToSixMap) then
		if ((tonumber(train:sub(16,18)) and tonumber(train:sub(16,18)) < 717) or train:find("ezh3")
		or train:find("lvz") or train:find("freight") or train:find("7175p") or train:find("722")) then
			ply:ChatPrint(lang("Restrict26"))
			return true
		end
	end
	
	-- система рассчета вагонов для спавна
	local max_wagons = GetConVar("metrostroi_maxtrains"):GetInt() * max_wags:GetInt()
	local cur_wagons = GetGlobalInt("metrostroi_train_count")
	local ply_wagons
	local wag_awail = max_wagons-cur_wagons
	if auto_wags:GetInt() == 1 then
		if (cur_wagons < 8) then
			ply_wagons = 4
		else
			ply_wagons = 3
		end
	else
		ply_wagons = max_wags:GetInt()
	end

	if (PlayerPermission(ply,"add_4wagons")) then
		ply_wagons = ply_wagons + 4
		if ply_wagons > GetConVar("metrostroi_maxwagons"):GetInt() then ply_wagons = GetConVar("metrostroi_maxwagons"):GetInt() end
	elseif (PlayerPermission(ply,"add_3wagons")) then
		ply_wagons = ply_wagons + 3
		if ply_wagons > GetConVar("metrostroi_maxwagons"):GetInt() then ply_wagons = GetConVar("metrostroi_maxwagons"):GetInt() end
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
	
	if settings.WagNum < min_wags:GetInt() then
		settings.WagNum = min_wags:GetInt()
		ply:ChatPrint(lang("FewWagons").." "..min_wags:GetString()..".")
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
	local spawnint = spawn_int:GetInt()
	if (spawnint > 0) then
		local lastspawn = MetrostroiAdvanced.LastSpawned or 0
		local curtime = os.time()
		local curint = curtime - lastspawn
		if (curint < spawnint) then
			local secs = spawnint - curint
			ply:ChatPrint(lang("PleaseWait").." "..secs.." "..lang("Seconds").." "..lang("WaitSpawn"))
			return true
		end
	end

	-- спавн разрешен
	if (spawn_mes:GetInt() == 1) then
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
	elseif(settings.Train == "gmod_subway_81-717_5a_custom") then
		ply:SetNW2String("MATrainClass","gmod_subway_81-717_5a")
	else
		ply:SetNW2String("MATrainClass",settings.Train)
	end
	MetrostroiAdvanced.LastSpawned = os.time()
	return
end)
	
hook.Add("PlayerInitialSpawn","MA.SetPlyParams",function(ply)
	-- выдаем игроку номер маршрута
	local rnum = MetrostroiAdvanced.GetRouteNumber(ply)
	if Metrostroi.Version > 1537278077 then
		if (ply:GetInfoNum("metrostroi_route_number",61) == 61) then
			ply:ConCommand("metrostroi_route_number "..rnum)
		end
	else
		if (ply:GetInfoNum("ma_routenums",1) == 1) then
			ply:SetNW2Int("MARouteNumber",rnum)
		end
	end
	if AFK_TIME > 0 then
		ply.NextAFK = CurTime() + AFK_TIME
		ply.WarningAFK = 0
	end
	
	-- выставляем кварам клиента серверное значение при спавне
	if (ply:IsAdmin()) then
		ply:ConCommand("metrostroi_advanced_spawninterval "..spawn_int:GetInt())
		ply:ConCommand("metrostroi_advanced_trainsrestrict "..train_rest:GetInt())
		ply:ConCommand("metrostroi_advanced_spawnmessage "..spawn_mes:GetInt())
		ply:ConCommand("metrostroi_advanced_minwagons "..min_wags:GetInt())
		ply:ConCommand("metrostroi_advanced_maxwagons "..max_wags:GetInt())
		ply:ConCommand("metrostroi_advanced_autowags "..auto_wags:GetInt())
		ply:ConCommand("metrostroi_advanced_afktime "..afktime:GetInt())
		ply:ConCommand("metrostroi_advanced_timezone "..timezone:GetInt())
		ply:ConCommand("metrostroi_advanced_buttonmessage "..buttonmessage:GetInt())
		ply:ConCommand("metrostroi_advanced_noentryann "..noentry_ann:GetInt())
		--
		ply:ConCommand("ma_voltage "..GetConVar("metrostroi_voltage"):GetInt())
		ply:ConCommand("ma_curlim "..GetConVar("metrostroi_current_limit"):GetInt())
		ply:ConCommand("ma_requirethirdrail "..GetConVar("metrostroi_train_requirethirdrail"):GetInt())
	end
end)

hook.Add("PlayerButtonDown","MA.PlayerActions",function(ply,key)
	if AFK_TIME > 0 then
		ply.NextAFK = CurTime() + AFK_TIME
		ply.WarningAFK = 0
	end
end)

hook.Add("Think","MA.ControlAFKPlayers", function()
	if AFK_TIME == 0 then return end
	for _, ply in pairs(player.GetAll()) do
		if (not ply:IsConnected() and not ply:IsFullyAuthenticated() or ply:IsAdmin()) then return end
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
			ply:Kick("[Metrostroi Advanced]: "..lang("AfkKick"))
		end
	end
end)

hook.Add("MetrostroiCoupled","MA.SetTrainParams",function(train,train2)
	if not IsValid(train) then return end
	if not MetrostroiAdvanced.TrainList[train:GetClass()] then return end
	local ply = train.Owner
	if not IsValid(ply) then return end
	
	-- переключаем дешифратор АЛС
	if (ply:GetInfoNum("ma_auto_alsdecoder",1) == 1 and MetrostroiAdvanced.TwoToSixMap) then
		for _,sw in pairs({"ALSFreq","SAP14","SA14k","SA14"}) do
			if train[sw] then train[sw]:TriggerInput("Toggle",1) end
		end
	end
	
	-- устанавливаем номер маршрута на состав
	local rnum = 0
	if Metrostroi.Version > 1537278077 then
		rnum = ply:GetInfoNum("metrostroi_route_number",61)
	else
		rnum = ply:GetNW2Int("MARouteNumber")
		if (ply:GetInfoNum("ma_routenums",1) == 0) then return end
	end

	if train:GetClass() == "gmod_subway_81-540_2" then
		local rtype = train:GetNW2Int("Route",1)
		if rtype == 1 then
			if rnum < 10 then
				rnum = "0"..tostring(rnum).."0"
			else
				rnum = tostring(rnum).."00"
			end
			train.RouteNumbera.RouteNumbera = rnum
			train:SetNW2String("RouteNumbera",rnum)
		end
		if rtype == 2 then
			if rnum < 10 then
				rnum = "00"..tostring(rnum)
			else
				rnum = "0"..tostring(rnum)
			end
			train.RouteNumbera.RouteNumbera = rnum
			train:SetNW2String("RouteNumbera",rnum)
		end
		if rtype == 3 then
			if train.RouteNumberSys then
				train.RouteNumberSys.CurrentRouteNumber = rnum
			end
		end
	elseif train:GetClass() == "gmod_subway_81-540_2k" then
		train.RouteNumber.RouteNumber = rnum
		train.RouteNumber.CurrentRouteNumber = rnum
	elseif train:GetClass() == "gmod_subway_81-722" or train:GetClass() == "gmod_subway_81-722_3" or train:GetClass() == "gmod_subway_81-722_new" or train:GetClass() == "gmod_subway_81-7175p" then
		train.RouteNumberSys.CurrentRouteNumber = rnum
	elseif train:GetClass() == "gmod_subway_81-717_6" then
		train.ASNP.RouteNumber = rnum
	elseif train:GetClass() == "gmod_subway_81-502" or train:GetClass() == "gmod_subway_81-540" or train:GetClass() == "gmod_subway_81-540_1" or train:GetClass() == "gmod_subway_81-540_8" or train:GetClass() == "gmod_subway_81-717_lvz" then
		if rnum < 10 then
			rnum = "00"..tostring(rnum)
		else
			rnum = "0"..tostring(rnum)
		end
		train.RouteNumber.RouteNumber = rnum
		train:SetNW2String("RouteNumber",rnum)
	elseif train:GetClass() == "gmod_subway_81-760" or train:GetClass() == "gmod_subway_81-760a" then
		train.BMCIS.RouteNumber = rnum
		train:SetNW2Int("RouteNumber:RouteNumber",rnum)
		train.RouteNumber.RouteNumber = rnum
	else
		if train.RouteNumber then
			if rnum < 10 then
				rnum = "0"..tostring(rnum).."0"
			else
				rnum = tostring(rnum).."0"
			end
			train.RouteNumber.RouteNumber = rnum
			train:SetNW2String("RouteNumber",rnum)
		end
	end
end)

hook.Add("EntityRemoved","MA.DeleteTrainParams",function (ent)
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
				if ctrain.Speed < 1 and not v.LastCurrentTrain then v.LastCurrentTrain = ctrain end
				if ctrain.Speed > 10 and (not v.LastCurrentTrain or ctrain ~= v.LastCurrentTrain) then
					if not v.LastCurrentTrain then v.LastCurrentTrain = ctrain end
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
							if not MetrostroiAdvanced.IsRealLastStation(v.StationIndex) or (MetrostroiAdvanced.IsRealLastStation(v.StationIndex)
							and IsValid(rtrain) and rtrain:ReadCell(49162) == 0) then -- на реальной конечной только при выезде из тупика
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
		if(buttonmessage:GetInt() == 0) then return end
		if not IsValid(ent) or ent:GetClass() ~= "func_button" then return end
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
					if ulx then
						ulx.fancyLog("#s "..lang("PressedButton").." #s",Nick,ButtonName)
					end
				end	
			end
		elseif input == "Press" then
			Nick = "Someone"
			if ulx then
				ulx.fancyLog("#s "..lang("PressedButton").." #s",Nick,ButtonName)
			end
		end
	end)
end)
