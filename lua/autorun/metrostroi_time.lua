-- переопределяем функцию и поправляем время
Metrostroi.GetSyncTime = function(notsynk)
    if notsync then
        return os.time() - Metrostroi.GetTimedT(notsync)
    else
        return os.time() + 10800
    end
end