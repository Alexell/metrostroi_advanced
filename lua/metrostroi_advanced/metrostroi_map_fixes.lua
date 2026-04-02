if CLIENT then return end

local map = game.GetMap()

-- фикс деповских магистралей на Imagine Line
local function snake()
	for k,v in pairs(ents.FindByClass("gmod_track_pneumatic_snake")) do
		v:SetPos(v:GetPos()-Vector(0,0,30))
	end
end
if (map:find("gm_metro_jar_imagine_line")) then
	timer.Simple(1, function() snake() end)
end

-- сохраняем изначальные положения удочек
MetrostroiAdvanced.Udc_Positions = {}
MetrostroiAdvanced.Box_Positions = {}
MetrostroiAdvanced.Box_Angles = {}
local function get_udc_pos()
	local boxes = {}
	if map:find("loopline") and not map:find("_r") then
		boxes = ents.FindByClass("func_tracktrain")
	else
		boxes = ents.FindByClass("func_physbox")
	end
	for k,v in pairs(boxes) do
		MetrostroiAdvanced.Box_Positions[k] = v:GetPos()
		MetrostroiAdvanced.Box_Angles[k] = v:GetAngles()
	end
	boxes = nil
	for k,v in pairs(ents.FindByClass("gmod_track_udochka")) do
		MetrostroiAdvanced.Udc_Positions[k] = v:GetPos()
	end
end
timer.Simple(3, function() get_udc_pos() end)
