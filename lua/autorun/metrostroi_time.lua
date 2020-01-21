if SERVER then
	if not Metrostroi or not Metrostroi.GetSyncTime then return end
	timer.Create("MetrostroiAdvancedTimezone",1,1,function()
		SetGlobalInt("MetrostroiTimezone",GetConVar("metrostroi_advanced_timezone"):GetInt())
		Metrostroi.GetSyncTime = function(notsync)
			return os.time() - Metrostroi.GetTimedT(notsync) + GetGlobalInt("MetrostroiTimezone",3) * 3600
		end
		timer.Remove("MetrostroiAdvancedTimezone")
	end)
	cvars.AddChangeCallback("metrostroi_advanced_timezone",function(name,old,new)
		SetGlobalInt("MetrostroiTimezone",tonumber(new))
	end)
else
	if not Metrostroi or not Metrostroi.GetSyncTime then return end
	timer.Create("MetrostroiAdvancedTimezone",2,1,function()
		Metrostroi.GetSyncTime = function(notsync)
			return os.time() - Metrostroi.GetTimedT(notsync) + GetGlobalInt("MetrostroiTimezone",3) * 3600
		end
		timer.Remove("MetrostroiAdvancedTimezone")
	end)
end
