if CLIENT then return end

local cur_map = game.GetMap()

-- фикс деповских магистралей на Imagine Line
local function snake()
	local trubs = ents.FindByClass("gmod_track_pneumatic_snake")
	local pos
	for k,v in pairs(trubs) do
		pos = v:GetPos()
		v:SetPos(pos-Vector(0,0,30))
	end
end
if (cur_map:find("gm_metro_jar_imagine_line")) then
	timer.Create("SnakeFix", 1, 1, function() snake() end)
end

-- сохраняем изначальные положения удочек
MetrostroiAdvanced.Udc_Positions = {}
MetrostroiAdvanced.Box_Positions = {}
MetrostroiAdvanced.Box_Angles = {}
local function get_udc_pos()
	local boxes = {}
	if (cur_map:find("gm_mus_loopline")) then
		boxes = ents.FindByClass("func_tracktrain")
	else
		boxes = ents.FindByClass("func_physbox")
	end
	for k,v in pairs(boxes) do
		MetrostroiAdvanced.Box_Positions[k] = v:GetPos()
		MetrostroiAdvanced.Box_Angles[k] = v:GetAngles()
	end
	local udcs = ents.FindByClass("gmod_track_udochka")
	for k,v in pairs(udcs) do
		MetrostroiAdvanced.Udc_Positions[k] = v:GetPos()
	end
end
timer.Create("UdcGetPos", 3, 1, function() get_udc_pos() end)
