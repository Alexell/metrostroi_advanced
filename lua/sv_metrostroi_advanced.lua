----------------- Metrostroi Advanced -----------------
-- Авторы: Alexell и Agent Smith
-- Версия: 1.0
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_advanced
-------------------------------------------------------

if CLIENT then return end

--CVars
local spawn_int = CreateConVar("metrostroi_spawn_interval", "0", {FCVAR_NEVER_AS_STRING})

hook.Add("MetrostroiSpawnerRestrict","TrainSpawnerLimits",function(ply,settings)
	if IsValid(ply) then
		--задержка спавна
		local spawnint = GetConVarNumber("metrostroi_spawn_interval")
		if spawnint > 0 then
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
		SetGlobalInt("TrainLastSpawned",os.time())
		return
	end
end)

hook.Add("MetrostroiLoaded","MetrostroiLoadEnd",function()
	SetGlobalInt("TrainLastSpawned",os.time())
end)