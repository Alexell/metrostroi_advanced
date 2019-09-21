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

-- CVars
local spawn_int = CreateConVar("metrostroi_advanced_spawninterval", "0", {FCVAR_NEVER_AS_STRING})
local train_rest = CreateConVar("metrostroi_advanced_trainsrestrict", "0", {FCVAR_NEVER_AS_STRING})
local spawn_mes = CreateConVar("metrostroi_advanced_spawnmessage", "1", {FCVAR_NEVER_AS_STRING})
local max_wags = CreateConVar("metrostroi_advanced_maxwagons", "4", {FCVAR_NEVER_AS_STRING})
local min_wags = CreateConVar("metrostroi_advanced_minwagons", "2", {FCVAR_NEVER_AS_STRING})
local route_nums = CreateConVar("metrostroi_advanced_routenums", "1", {FCVAR_NEVER_AS_STRING})
local auto_wags = CreateConVar("metrostroi_advanced_autowags", "0", {FCVAR_NEVER_AS_STRING})

hook.Add("MetrostroiSpawnerRestrict","TrainSpawnerLimits",function(ply,settings)
	if IsValid(ply) then
		-- ограничение составов по правам ULX
		local train_restrict = GetConVarNumber("metrostroi_advanced_trainsrestrict")
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
		
		if (ULib.ucl.query(ply,"add_3wagons")) then
			ply_wagons = ply_wagons + 3
			if ply_wagons > GetConVarNumber("metrostroi_maxwagons") then ply_wagons = GetConVarNumber("metrostroi_maxwagons") end
		else
			if (ULib.ucl.query(ply,"add_2wagons")) then
				ply_wagons = ply_wagons + 2
			else
				if (ULib.ucl.query(ply,"add_1wagons")) then
					ply_wagons = ply_wagons + 1
				end
			end
		end
		if ply_wagons > wag_awail then ply_wagons = wag_awail end
		
		if settings.WagNum < GetConVarNumber("metrostroi_advanced_minwagons") then
			settings.WagNum = GetConVarNumber("metrostroi_advanced_minwagons")
			ply:ChatPrint("Запрещено спавнить короткие составы!\nКоличество вагонов увеличено до "..tostring(GetConVarNumber("metrostroi_advanced_minwagons"))..".")
		end
		
		if (settings.WagNum > ply_wagons) then
			local wag_str = "вагон"
			if ply_wagons >= 2 and ply_wagons <= 4 then wag_str = "вагона" end
			if ply_wagons == 0 or ply_wagons >= 5 then wag_str = "вагонов" end
			if wag_awail == 0 then
				ply:ChatPrint("Закончились доступные для спавна вагоны на сервере.")
				ply:ChatPrint("Пожалуйста подождите пока кто-нибудь отключится или удалит состав.")
			else
				ply:ChatPrint("Вы не можете спавнить столько вагонов!")
				ply:ChatPrint("Для спавна доступно: "..ply_wagons.." "..wag_str..".")
			end
			return true
		end
	
		--спавн в любом месте
		if (not ULib.ucl.query(ply,"metrostroi_anyplace_spawn")) then
			loc = GetTrainLoc(ply)
			if (loc == "перегон") then
				ply:ChatPrint("Вам запрещен спавн в этом месте!")
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
				ply:ChatPrint("Пожалуйста подождите "..secs.." секунд прежде, чем спавнить состав.")
				return true
			end
		end
	
		-- спавн разрешен
		if (GetConVarNumber("metrostroi_advanced_spawnmessage") == 1) then
			local wag_str = "вагон"
			local wag_num = settings.WagNum
			if wag_num >= 2 and wag_num <= 4 then wag_str = "вагона" end
			if wag_num >= 5 then wag_str = "вагонов" end
			ulx.fancyLog("Игрок #s заспавнил #s #s #s.\nМестоположение: #s.",ply:Nick(),tostring(wag_num),wag_str,MetrostroiAdvanced.GetTrainName(settings.Train),MetrostroiAdvanced.GetLocation(ply))
		end
		if (settings.Train == "gmod_subway_81-717_mvm_custom") then
			ply:SetNW2String("TrainC","gmod_subway_81-717_mvm")
		else
			ply:SetNW2String("TrainC",settings.Train)
		end
		SetGlobalInt("TrainLastSpawned",os.time())
		return
	end
end)

hook.Add("PlayerInitialSpawn","SetPlyParams",function(ply)
	-- выдаем игроку уникальный номер маршрута на время сессии
	if (GetConVarNumber("metrostroi_advanced_routenums") == 1) then
		local rnum = MetrostroiAdvanced.GetRouteNumber(ply)
		ply:SetNW2Int("RouteNum",rnum)
	end
end)

hook.Add("MetrostroiCoupled","SetTrainParams",function(ent,ent2)
	if IsValid(ent) and IsValid(ent2) then
		-- устанавливаем номер маршрута на состав
		if (GetConVarNumber("metrostroi_advanced_routenums") == 1) then
			local ply = ent.Owner
			local rnum = ply:GetNW2Int("RouteNum")
			for k, v in pairs(MetrostroiAdvanced.TrainList) do
				if ent:GetClass() == k then
					if table.HasValue({"gmod_subway_81-702","gmod_subway_81-703","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_ezh3ru1","gmod_subway_81-717_mvm","gmod_subway_81-717_mvm_custom","gmod_subway_81-718","gmod_subway_81-720"},ent:GetClass()) then rnum = rnum * 10 end
					if ent:GetClass() == "gmod_subway_81-722" then
						ent:SetNW2Int("RouteNumber",rnum)
					else
						ent:SetNW2String("RouteNumber",tostring(rnum))
					end
				end
				if ent2:GetClass() == k then
					if table.HasValue({"gmod_subway_81-702","gmod_subway_81-703","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_ezh3ru1","gmod_subway_81-717_mvm","gmod_subway_81-717_mvm_custom","gmod_subway_81-718","gmod_subway_81-720"},ent2:GetClass()) then rnum = rnum * 10 end
					if ent2:GetClass() == "gmod_subway_81-722" then
						ent2:SetNW2Int("RouteNumber",rnum)
					else
						ent2:SetNW2String("RouteNumber",tostring(rnum))
					end
				end
			end
		end
	end
end)

hook.Add("EntityRemoved","DeleteTrainParams",function (ent)
	for k, v in pairs(MetrostroiAdvanced.TrainList) do
		if ent:GetClass() == k then
			local ply = ent.Owner
			if not IsValid(ply) then return end
			ply:SetNW2String("TrainC","")
		end
	end
end)

hook.Add("MetrostroiLoaded","MetrostroiLoadEnd",function()
	SetGlobalInt("TrainLastSpawned",os.time())
end)