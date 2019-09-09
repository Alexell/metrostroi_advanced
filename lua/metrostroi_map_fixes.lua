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
