----------------- Metrostroi Advanced -----------------
-- Авторы: Alexell и Agent Smith
-- Версия: 1.0
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_advanced
-------------------------------------------------------

if CLIENT then return end

-- CVars
local spawn_int = CreateConVar("metrostroi_advanced_spawninterval", 0, {FCVAR_ARCHIVE})
local train_rest = CreateConVar("metrostroi_advanced_trainsrestrict", 0, {FCVAR_ARCHIVE})
local spawn_mes = CreateConVar("metrostroi_advanced_spawnmessage", 1, {FCVAR_ARCHIVE})
local max_wags = CreateConVar("metrostroi_advanced_maxwagons", 4, {FCVAR_ARCHIVE})
local min_wags = CreateConVar("metrostroi_advanced_minwagons", 2, {FCVAR_ARCHIVE})
local route_nums = CreateConVar("metrostroi_advanced_routenums", 1, {FCVAR_ARCHIVE})
local auto_wags = CreateConVar("metrostroi_advanced_autowags", 0, {FCVAR_ARCHIVE})
local madv_lang = CreateConVar("metrostroi_advanced_lang", "ru", {FCVAR_ARCHIVE})
local afktime = CreateConVar("metrostroi_advanced_afktime", 0, {FCVAR_ARCHIVE})
local timezone = CreateConVar("metrostroi_advanced_timezone", 3, {FCVAR_ARCHIVE})
AFK_TIME = 0
AFK_WARN1 = 0
AFK_WARN2 = 0
AFK_WARN3 = 60

timer.Create("MetrostroiAdvancedInit",1,1,function()
	MetrostroiAdvanced.LoadLanguage(GetConVarString("metrostroi_advanced_lang"))
	MetrostroiAdvanced.LoadStationsIgnore()
	MetrostroiAdvanced.LoadMapWagonsLimit()
	SetGlobalInt("TrainLastSpawned",os.time())
end)

cvars.AddChangeCallback("metrostroi_advanced_lang", function(cvar, old, new)
    MetrostroiAdvanced.LoadLanguage(new)
end)

AFK_TIME = GetConVarNumber("metrostroi_advanced_afktime") * 60
cvars.AddChangeCallback("metrostroi_advanced_afktime", function(cvar, old, new)
    AFK_TIME = new * 60
	AFK_WARN1 = AFK_TIME * 0.6
	AFK_WARN2 = AFK_TIME * 0.4
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
			ply:ChatPrint(MetrostroiAdvanced.Lang["SpawnerRestrict1"])
			ply:ChatPrint(MetrostroiAdvanced.Lang["SpawnerRestrict2"])
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
		if (cur_wagons <= 8) then
			ply_wagons = 4
		else
			ply_wagons = 3
		end
	else
		ply_wagons = GetConVarNumber("metrostroi_advanced_maxwagons")
	end
	
	if (PlayerPermission(ply,"add_3wagons")) then
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
		ply:ChatPrint(MetrostroiAdvanced.Lang["FewWagons"].." "..tostring(GetConVarNumber("metrostroi_advanced_minwagons"))..".")
	end
	
	local map_wagons = MetrostroiAdvanced.MapWagons[game.GetMap()] or 0
	local wag_str = MetrostroiAdvanced.Lang["wagon1"]
	if map_wagons > 0 and not ply:IsAdmin() then
		if settings.WagNum > map_wagons then
			if map_wagons >= 2 and map_wagons <= 4 then wag_str = MetrostroiAdvanced.Lang["wagon2"] end
			if map_wagons == 0 or map_wagons >= 5 then wag_str = MetrostroiAdvanced.Lang["wagon3"] end
			ply:ChatPrint(MetrostroiAdvanced.Lang["MapWagonsLimit"])
			ply:ChatPrint(MetrostroiAdvanced.Lang["Wagonsrestrict2"].." "..map_wagons.." "..wag_str..".")
			return true
		end
	end
	
	if (settings.WagNum > ply_wagons) then
		wag_str = MetrostroiAdvanced.Lang["wagon1"]
		if ply_wagons >= 2 and ply_wagons <= 4 then wag_str = MetrostroiAdvanced.Lang["wagon2"] end
		if ply_wagons == 0 or ply_wagons >= 5 then wag_str = MetrostroiAdvanced.Lang["wagon3"] end
		if wag_awail == 0 then
			ply:ChatPrint(MetrostroiAdvanced.Lang["NoWagons1"])
			ply:ChatPrint(MetrostroiAdvanced.Lang["NoWagons2"])
		else
			ply:ChatPrint(MetrostroiAdvanced.Lang["Wagonsrestrict1"])
			ply:ChatPrint(MetrostroiAdvanced.Lang["Wagonsrestrict2"].." "..ply_wagons.." "..wag_str..".")
		end
		return true
	end

	--спавн в любом месте
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
				ply:ChatPrint(MetrostroiAdvanced.Lang["StationRestrict"])
				return true
			end
		end
		if (loc == MetrostroiAdvanced.Lang["UnknownPlace"]) then
			ply:ChatPrint(MetrostroiAdvanced.Lang["AnyPlaceRestrict"])
			return true
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
			ply:ChatPrint(MetrostroiAdvanced.Lang["PleaseWait"].." "..secs.." "..MetrostroiAdvanced.Lang["Seconds"].." "..MetrostroiAdvanced.Lang["WaitSpawn"])
			return true
		end
	end

	-- спавн разрешен
	if (GetConVarNumber("metrostroi_advanced_spawnmessage") == 1) then
		local wag_str = MetrostroiAdvanced.Lang["wagon1"]
		local wag_num = settings.WagNum
		if wag_num >= 2 and wag_num <= 4 then wag_str = MetrostroiAdvanced.Lang["wagon2"] end
		if wag_num >= 5 then wag_str = MetrostroiAdvanced.Lang["wagon3"] end
		if ulx then
			ulx.fancyLog(MetrostroiAdvanced.Lang["Player"].." #s "..MetrostroiAdvanced.Lang["Spawned"].." #s #s #s.\n"..MetrostroiAdvanced.Lang["Location"]..": #s.",ply:Nick(),tostring(wag_num),wag_str,MetrostroiAdvanced.GetTrainName(settings.Train),MetrostroiAdvanced.GetLocation(ply))
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
	if (GetConVarNumber("metrostroi_advanced_routenums") == 1) then
		local rnum = MetrostroiAdvanced.GetRouteNumber(ply)
		ply:SetNW2Int("MARouteNumber",rnum)
	end
	if AFK_TIME > 0 then
		ply.NextAFK = CurTime() + AFK_TIME
		ply.WarningAFK = 0
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
					ply:ChatPrint("[Metrostroi Advanced]: "..string.format(MetrostroiAdvanced.Lang["AfkWarning"],tostring(min_left),MetrostroiAdvanced.Lang["Afkmins"]))
					ply.WarningAFK = 1
				end
				if (ply.NextAFK <= CurTime() + AFK_WARN2) and (ply.WarningAFK == 1) then
				local min_left =  math.Round((ply.NextAFK - CurTime()) / 60)
					ply:ChatPrint("[Metrostroi Advanced]: "..string.format(MetrostroiAdvanced.Lang["AfkWarning"],tostring(min_left),MetrostroiAdvanced.Lang["Afkmins"]))
					ply.WarningAFK = 2
				end
				if (ply.NextAFK <= CurTime() + AFK_WARN3) and (ply.WarningAFK == 2) then
					local min_left = 1
					ply:ChatPrint("[Metrostroi Advanced]: "..string.format(MetrostroiAdvanced.Lang["AfkWarning"],tostring(min_left),MetrostroiAdvanced.Lang["Afkmin1"]))
					ply.WarningAFK = 3
				end
				if (CurTime() >= ply.NextAFK and ply.WarningAFK == 3) then
					ply.WarningAFK = nil
					ply.NextAFK = nil
					ply:Kick("[Metrostroi Advanced] - "..MetrostroiAdvanced.Lang["AfkKick"])
				end
			end
		end
	end
end)

hook.Add("MetrostroiCoupled","SetTrainParams",function(ent,ent2)
	if IsValid(ent) and IsValid(ent2) then
		-- устанавливаем номер маршрута на состав
		if (GetConVarNumber("metrostroi_advanced_routenums") == 1) then
			local ply = ent.Owner
			local rnum = ply:GetNW2Int("MARouteNumber")
			if MetrostroiAdvanced.TrainList[ent:GetClass()] then
				if table.HasValue({"gmod_subway_81-702","gmod_subway_81-703","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_ezh3ru1","gmod_subway_81-717_mvm","gmod_subway_81-718","gmod_subway_81-720"},ent:GetClass()) then rnum = rnum * 10 end
				if ent:GetClass() == "gmod_subway_81-722" or ent:GetClass() == "gmod_subway_81-722_3" or ent:GetClass() == "gmod_subway_81-7175p" then
					ent.RouteNumberSys.CurrentRouteNumber = rnum
				elseif ent:GetClass() == "gmod_subway_81-717_6" then
					ent.ASNP.RouteNumber = rnum
				elseif ent:GetClass() == "gmod_subway_81-502" or ent:GetClass() == "gmod_subway_81-540" or ent:GetClass() == "gmod_subway_81-717_lvz" then
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
				if table.HasValue({"gmod_subway_81-702","gmod_subway_81-703","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_ezh3ru1","gmod_subway_81-717_mvm","gmod_subway_81-718","gmod_subway_81-720"},ent2:GetClass()) then rnum = rnum * 10 end
				
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
				elseif ent2:GetClass() == "gmod_subway_81-722" or ent2:GetClass() == "gmod_subway_81-722_3" then
					ent2.RouteNumberSys.CurrentRouteNumber = rnum
				elseif ent2:GetClass() == "gmod_subway_81-717_6" then
					ent2.ASNP.RouteNumber = rnum
				elseif ent2:GetClass() == "gmod_subway_81-502" or ent2:GetClass() == "gmod_subway_81-540" or ent2:GetClass() == "gmod_subway_81-717_lvz" then
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
	end
end)

hook.Add("EntityRemoved","DeleteTrainParams",function (ent)
	if MetrostroiAdvanced.TrainList[ent:GetClass()] then
		local ply = ent.Owner
		if not IsValid(ply) then return end
		ply:SetNW2String("MATrainClass","")
	end
end)
