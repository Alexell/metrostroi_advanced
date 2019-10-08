-- переопределяем функцию и поправляем время
Metrostroi.GetSyncTime = function(notsync)
	return os.time() - Metrostroi.GetTimedT(notsync) + 10800
end