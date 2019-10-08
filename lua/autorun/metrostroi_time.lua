-- переопределяем функцию и поправляем время
Metrostroi.GetSyncTime = function(notsync)
    if notsync then
        return os.time() - Metrostroi.GetTimedT(notsync)
    else
        return os.time() - Metrostroi.GetTimedT(notsync) + 10800
    end
end