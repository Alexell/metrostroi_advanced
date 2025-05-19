------------------------ Metrostroi Advanced -------------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_advanced
----------------------------------------------------------------------

if SERVER then return end

CreateClientConVar("ma_autoinformator","0",true,true,"Enable autoannouncer (def = 1 - enabled)")
if Metrostroi.Version == 1537278077 then
	CreateClientConVar("ma_routenums","1",true,true,"Auto-generate route number on train spawn (def = 1 - enabled)")
end
CreateClientConVar("ma_clientoptimize","1",true,false)
CreateClientConVar("ma_voltage","0",false,false,"Third rail voltage")
CreateClientConVar("ma_curlim","0",false,false,"Third rail current limit")
CreateClientConVar("ma_requirethirdrail","0",false,false,"Require third rail")
CreateClientConVar("ma_button_sourcename", "", false, false)
CreateClientConVar("ma_button_output", "", false, false)
CreateClientConVar("ma_auto_alsdecoder", "1", true, true,"Enable auto ALS decoder switching (def = 1 - enabled)")
CreateClientConVar("ma_cl_crosshair","1",true,false, "Crosshair in the train")
CreateClientConVar("ma_cl_crosshair_hide","1",true,false, "Auto-hide cursor in train on mouse inactivity")
if Metrostroi.Version > 1537278077 then
	CreateClientConVar("ma_statiosview","1",true,true,"How to get the results of the !stations command (def = 1 - modal window)")
end

-- Дублирующие серверные квары для админов
local AdminCVarList = {
	{"metrostroi_advanced_spawninterval","Global delay between spawns in seconds (def = 0 - disabled)"},
	{"metrostroi_advanced_trainsrestrict","Global train restrictions convar for ulx groups (def = 0 - disabled)"},
	{"metrostroi_advanced_spawnmessage","Global chat outputs for every spawned train (def = 1 - enabled)"},
	{"metrostroi_advanced_minwagons","Minimum wagon count for a player to spawn (def = 2)"},
	{"metrostroi_advanced_maxwagons","Maximum wagon count for a player to spawn (def = 4)"},
	{"metrostroi_advanced_autowags","Automatic permission to spawn 4 wagons instead of 3 wagons for the first 3 players to spawn a train, in case metrostroi_advanced_maxwagons convar is set to less than 4 (def = 0 - disabled)"},
	{"metrostroi_advanced_afktime","Time in minutes before a player is kicked for being AFK (def = 0 - disabled)"},
	{"metrostroi_advanced_timezone","Server time zone, def = 3 (Moscow local time)"},
	{"metrostroi_advanced_buttonmessage","Enable chat notifications for station control panel's buttons (def = 1 - enabled)"},
	{"metrostroi_advanced_noentryann","Enable automatic station announcements when there is no entry on an arriving train (def = 1 - enabled)"}
}
for _,cvr in pairs(AdminCVarList) do
	CreateClientConVar(cvr[1],"0",false,false,cvr[2])
end

-- Локализация
MetrostroiAdvanced.LoadLanguage(GetConVar("metrostroi_language"):GetString())
cvars.AddChangeCallback("metrostroi_language", function(cvar,old,new)
	if (old == new) then return end
    MetrostroiAdvanced.LoadLanguage(new)
end)
local function lang(str)
	return MetrostroiAdvanced.Lang[str]
end

-- Отправка команд на сервер
local function SendCommand(com,val)
	if not LocalPlayer():IsAdmin() then return end
	net.Start("MA.ServerCommands")
		net.WriteString(com)
		net.WriteString(val)
	net.SendToServer()
end

concommand.Add("ma_add_buttonoutput",function(ply,cmd,args)
	if not ply:IsAdmin() then return end
	local btn_name = GetConVar("ma_button_sourcename"):GetString()
	local btn_text = GetConVar("ma_button_output"):GetString()
	net.Start("MA.AddNewButtons")
		net.WriteString(btn_name)
		net.WriteString(btn_text)
	net.SendToServer()
end)

hook.Add("InitPostEntity","MA_PlayerInit",function()
	if not LocalPlayer():IsAdmin() then return end
	timer.Simple(1,function()
		for _,cvr in pairs(AdminCVarList) do
			cvars.AddChangeCallback(cvr[1],function(cvar,old,new)
				if (old == new) then return end
				SendCommand(cvar,new)
			end)
		end
		cvars.AddChangeCallback("ma_voltage",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
		cvars.AddChangeCallback("ma_curlim",function(cvar,old,new)
			if not tonumber(new) then return end
			if (tonumber(old) == tonumber(new)) then return end
			SendCommand(cvar,tonumber(new))
		end)
		cvars.AddChangeCallback("ma_requirethirdrail",function(cvar,old,new)
			if (old == new) then return end
			SendCommand(cvar,new)
		end)
	end)
	hook.Remove("InitPostEntity","MA_PlayerInit")
end)

-- Оптимизация клиента
local function ClientOptimize(opt)
	if (tonumber(opt) == 2) then
		RunConsoleCommand("gmod_mcore_test",1)
		RunConsoleCommand("mat_queue_mode",2)
		RunConsoleCommand("mat_specular",0)
		RunConsoleCommand("cl_threaded_bone_setup",1)
		RunConsoleCommand("cl_threaded_client_leaf_system",1)
		RunConsoleCommand("r_threaded_client_shadow_manager",1)
		RunConsoleCommand("r_threaded_particles",1)
		RunConsoleCommand("r_threaded_renderables",1)
		RunConsoleCommand("r_queued_ropes",1)
		RunConsoleCommand("cl_smooth",0)
		RunConsoleCommand("r_eyemove",0)	
	elseif (tonumber(opt) == 1) then
		RunConsoleCommand("gmod_mcore_test",0)
		RunConsoleCommand("mat_queue_mode",-1)
		RunConsoleCommand("mat_specular",1)
		RunConsoleCommand("cl_threaded_bone_setup",0)
		RunConsoleCommand("cl_threaded_client_leaf_system",0)
		RunConsoleCommand("r_threaded_client_shadow_manager",0)
		RunConsoleCommand("r_threaded_particles",1)
		RunConsoleCommand("r_threaded_renderables",0)
		RunConsoleCommand("r_queued_ropes",1)
		RunConsoleCommand("cl_smooth",1)
		RunConsoleCommand("r_eyemove",1)
	end
end
ClientOptimize(GetConVar("ma_clientoptimize"):GetInt())

-- Панели в меню [Q]
local function ClientPanel(panel)
    panel:ClearControls()
    panel:SetPadding(0)
    panel:SetSpacing(0)
    panel:Dock(FILL)
	panel:ControlHelp(lang("CPGameStart"))
	local cbox,lb = panel:ComboBox(lang("CPOptimization"),"ma_clientoptimize")
	cbox:AddChoice(lang("CPOptimization2"),2)
	cbox:AddChoice(lang("CPOptimization1"),1)
	cbox:AddChoice(lang("CPOptimization0"),0)
	panel:Help("") -- отступ
	panel:Help("") -- отступ
	panel:ControlHelp(lang("CPOptions"))
	if Metrostroi.Version == 1537278077 then
		panel:CheckBox(lang("CPRouteNum").."\n"..lang("CPNeedReconnect"),"ma_routenums")
	end
	panel:CheckBox(lang("CPUseAutoinform"),"ma_autoinformator")
	panel:CheckBox(lang("CPUseAutoALSDecoder"),"ma_auto_alsdecoder")
	local cbox2,lb2 = panel:ComboBox(lang("CPTrainCrosshair"),"ma_cl_crosshair")
	cbox2:AddChoice(lang("CPDefault"),3)
	cbox2:AddChoice(lang("CPOpaque"),2)
	cbox2:AddChoice(lang("CPSemiTransp"),1)
	cbox2:AddChoice(lang("CPDisabled"),0)
	panel:CheckBox(lang("TrainCrosshairHide"),"ma_cl_crosshair_hide")
	if Metrostroi.Version > 1537278077 then
		local cbox3,lb3 = panel:ComboBox(lang("CPStationsView"),"ma_statiosview")
		cbox3:AddChoice(lang("CPStationsViewDef"),1)
		cbox3:AddChoice(lang("CPStationsViewOld"),2)
	end
end

local function AdminPanel(panel)
    if not LocalPlayer():IsAdmin() then return end
	panel:ClearControls()
    panel:SetPadding(0)
    panel:SetSpacing(0)
    panel:Dock(FILL)
	panel:ControlHelp(lang("APServerOptions").." Metrostroi Advanced:")
	panel:Help(lang("APSpawnInterval"))
	panel:NumSlider("","metrostroi_advanced_spawninterval",0,60,0)
	panel:CheckBox(lang("APTrainRestrict"),"metrostroi_advanced_trainsrestrict")
	panel:CheckBox(lang("APSpawnMessage"),"metrostroi_advanced_spawnmessage")
	panel:Help(lang("APWagMin"))
	panel:NumSlider("","metrostroi_advanced_minwagons",1,8,0)
	panel:Help(lang("APWagMax"))
	panel:NumSlider("","metrostroi_advanced_maxwagons",1,8,0)
	panel:CheckBox(lang("APAutoWags"),"metrostroi_advanced_autowags")
	panel:Help(lang("APAFKTime"))
	panel:NumSlider("","metrostroi_advanced_afktime",0,120,0)
	panel:NumSlider(lang("APServerTimezone"),"metrostroi_advanced_timezone",-12,12,0)
	panel:CheckBox(lang("APNoEntryAnn"),"metrostroi_advanced_noentryann")
	panel:Help("") -- отступ
	panel:Help("") -- отступ
	panel:ControlHelp(lang("APServerOptions").." Metrostroi:")
	panel:CheckBox(lang("APReqThirdRail"),"ma_requirethirdrail")
	panel:NumSlider(lang("APThirdRailVol"),"ma_voltage",0,999,0)
	panel:Help(lang("APCurLim").." (A):")
	panel:TextEntry("","ma_curlim")
	panel:Help("") -- отступ
	panel:ControlHelp(lang("APTools"))
	panel:Help(lang("ACPBtnHeader"))
	panel:CheckBox(lang("ACPBtnCheckBox"),"metrostroi_advanced_buttonmessage")
	panel:Help(lang("ACPBtnCheckBox"))
	panel:TextEntry(lang("ACPBtnSource"),"ma_button_sourcename")
	panel:TextEntry(lang("ACPBtnVisible"),"ma_button_output")
	panel:Button(lang("ACPBtnAdd"),"ma_add_buttonoutput",true)
	panel:Button(lang("ACPBtnSave"),"ma_save_buttonoutput",true)
	panel:Help("") -- отступ
	panel:Help(lang("ACPSigTools"))
	panel:Button(lang("APSignSave"),"metrostroi_save",true)
	panel:Button(lang("APSignReload"),"metrostroi_load",true)
	panel:Button(lang("APTrackEditor"),"metrostroi_trackeditor",true)
	panel:Button(lang("APToggleNodes"),"metrostroi_trackeditor_togglenodes",true)
end

hook.Add("PopulateToolMenu", "MetrostroiAdvancedACP", function()
	spawnmenu.AddToolMenuOption("Utilities", "Metrostroi Advanced", "MetrostroiAdvancedCP", lang("ACPClient"), "", "", ClientPanel)
	spawnmenu.AddToolMenuOption("Utilities", "Metrostroi Advanced", "MetrostroiAdvancedAP", lang("ACPAdmin"), "", "", AdminPanel)
end)

local color_default = Color(255, 255, 255, 255)
local color_default_t = Color(255, 255, 255, 100)
local color_hover = Color(255, 0, 0, 255)
local color_hover_t = Color(255, 0, 0, 100)

local drawCrosshair
local canDrawCrosshair
local toolTipText
local toolTipColor
local lastAimButtonChange
local lastAimButton
local C_DrawDebug = GetConVar("metrostroi_drawdebug")

-- функции из gmod_subway_base\cl_init.lua (нужны для работы переопределяемых хуков)
local function isValidTrainDriver(ply)
    local train
    local seat = ply:GetVehicle()
    if IsValid(seat) then train = seat:GetNW2Entity("TrainEntity") end
    if IsValid(train) then return train end
    local weapon = IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass()
    if weapon == "train_kv_wrench"  or weapon == "train_kv_wrench_gold" then
        train = util.TraceLine({
            start = LocalPlayer():GetPos(),
            endpos = LocalPlayer():GetPos() - LocalPlayer():GetAngles():Up() * 100,
            filter = function( ent ) if ent.ButtonMap ~= nil then return true end end
        }).Entity
        if not IsValid(train) then
            train = util.TraceLine({
                start = LocalPlayer():EyePos(),
                endpos = LocalPlayer():EyePos() + LocalPlayer():EyeAngles():Forward() * 300,
                filter = function( ent ) if ent.ButtonMap ~= nil then return true end end
            }).Entity
        end
    end
    return train, true
end

local function LinePlaneIntersect(PlanePos,PlaneNormal,LinePos,LineDir)
    local dot = LineDir:Dot(PlaneNormal)
    local fac = LinePos-PlanePos
    local dis = -PlaneNormal:Dot(fac) / dot
    return LineDir * dis + LinePos
end

local function WorldToScreen(vWorldPos, vPos, vScale, aRot)
    vWorldPos = vWorldPos - vPos
    vWorldPos:Rotate(Angle(0, -aRot.y, 0))
    vWorldPos:Rotate(Angle(-aRot.p, 0, 0))
    vWorldPos:Rotate(Angle(0, 0, -aRot.r))

    return vWorldPos.x / vScale, (-vWorldPos.y) / vScale
end

local function findAimButton(ply,train)
    local panel,panelDist = nil,1e9
    for kp,pan in pairs(train.ButtonMap) do
        if not train:ShouldDrawPanel(kp) then continue end
        --If player is looking at this panel
        if pan.aimedAt and (pan.buttons or pan.sensor or pan.mouse) and pan.aimedAt < panelDist then
            panel = pan
            panelDist = pan.aimedAt
        end
    end
    if not panel then return false end
    if panel.aimX and panel.aimY and (panel.sensor or panel.mouse) and math.InRangeXY(panel.aimX,panel.aimY,0,0,panel.width,panel.height) then return false,panel.aimX,panel.aimY,panel.system end
    if not panel.buttons then return false end

    local buttonTarget
    for _,button in pairs(panel.buttons) do
        if (train.Hidden[button.PropName] or train.Hidden.button[button.PropName]) and (not train.ClientProps[button.PropName] or not train.ClientProps[button.PropName].config or not train.ClientProps[button.PropName].config.staylabel) then continue end
        if (train.Hidden[button.ID] or train.Hidden.button[button.ID])  and (not train.ClientProps[button.ID] or not train.ClientProps[button.ID].config or not train.ClientProps[button.ID].config.staylabel) then  continue end
        if button.w and button.h then
            if  panel.aimX >= button.x and panel.aimX <= (button.x + button.w) and
                    panel.aimY >= button.y and panel.aimY <= (button.y + button.h) then
                buttonTarget = button
                --table.insert(foundbuttons,{button,panel.aimedAt})
            end
        else
            --If the aim location is withing button radis
            local dist = math.Distance(button.x,button.y,panel.aimX,panel.aimY)
            if dist < (button.radius or 10) then
                buttonTarget = button
                --table.insert(foundbuttons,{button,panel.aimedAt})
            end
        end
    end

    if not buttonTarget then return false end

    return buttonTarget
end
------------------------------------------

-- функции хуков из gmod_subway_base\cl_init.lua (измененные)
local lastCursorX = 0
local lastCursorY = 0
local lastCursorTime = 0
local function metrostroi_cabin_panel()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    toolTipText = nil
    drawCrosshair = false
    canDrawCrosshair = false
	
	-- отключение указателя игроком
	if GetConVar("ma_cl_crosshair"):GetInt() == 0 then return end
	
	-- отключение указателя при отсутствии движения курсора
	if GetConVar("ma_cl_crosshair_hide"):GetInt() == 1 then
		local cursorX, cursorY = input.GetCursorPos()
		if (cursorX ~= lastCursorX or cursorY ~= lastCursorY) then
			lastCursorX = cursorX
			lastCursorY = cursorY
			lastCursorTime = CurTime()
		else
			if (CurTime() - lastCursorTime) > 3 then return end
		end
	end
	
    local train, outside = isValidTrainDriver(ply)
    if not IsValid(train) then return end
    if gui.IsConsoleVisible() or gui.IsGameUIVisible() or IsValid(vgui.GetHoveredPanel()) and not vgui.IsHoveringWorld() and  vgui.GetHoveredPanel():GetParent() ~= vgui.GetWorldPanel() then return end
    if train.ButtonMap ~= nil then
        canDrawCrosshair = true
        local plyaimvec
        if outside then
            plyaimvec = ply:GetAimVector()
        else
            local x,y = input.GetCursorPos()
            plyaimvec = gui.ScreenToVector(x,y)
        end

        -- Loop trough every panel
        for k2,panel in pairs(train.ButtonMap) do
            if not train:ShouldDrawPanel(kp2) then continue end
            local pang = train:LocalToWorldAngles(panel.ang)

            if plyaimvec:Dot(pang:Up()) < 0 then
                local campos = not outside and train.CamPos or ply:EyePos()
                local ppos = train:LocalToWorld(panel.pos)
                local isectPos = LinePlaneIntersect(ppos,pang:Up(),campos,plyaimvec)
                local localx,localy = WorldToScreen(isectPos,ppos,panel.scale,pang)

                panel.aimX = localx
                panel.aimY = localy
                if plyaimvec:Dot(isectPos - campos)/(isectPos-campos):Length() > 0 and localx > 0 and localx < panel.width and localy > 0 and localy < panel.height then
                    panel.aimedAt = isectPos:Distance(campos)
                    drawCrosshair = panel.aimedAt
                else
                    panel.aimedAt = false
                end
                panel.outside = outside
            else
                panel.aimedAt = false
            end
        end

        -- Tooltips
        local ttdelay = GetConVarNumber("metrostroi_tooltip_delay")
        if GetConVarNumber("metrostroi_disablehovertext") == 0 and ttdelay and ttdelay >= 0 then
            local button = findAimButton(ply,train)
            if button and
                ((train.Hidden[button.ID] or train.Hidden[button.PropName]) and (not train.ClientProps[button.ID].config or not train.ClientProps[button.ID].config.staylabel) or
                (train.Hidden.button[button.ID] or train.Hidden.button[button.PropName]) and (not train.ClientProps[button.PropName].config or not train.ClientProps[button.PropName].config.staylabel)) then
                return
            end
            if button ~= lastAimButton then
                lastAimButtonChange = CurTime()
                lastAimButton = button
            end

            if button then
                if ttdelay == 0 or CurTime() - lastAimButtonChange > ttdelay then
                    if C_DrawDebug:GetInt() > 0 then
                        toolTipText,_,toolTipColor = button.ID,Color(255,0,255)
                    elseif button.plombed then
                        toolTipText,_,toolTipColor = button.plombed(train)
                    else
                        toolTipText,_,toolTipColor = button.tooltip
                    end
                    if Metrostroi.Version > 1537278077 then
                        if GetConVar("metrostroi_disablehovertextpos"):GetInt() == 0 and button.tooltipState and button.tooltip then
                            toolTipText = toolTipText..button.tooltipState(train)
                        end
                    end
                end
            end
        end
    end
end

local function metrostroi_draw_crosshair_tooltip()
    if not canDrawCrosshair then return end
    if IsValid(LocalPlayer()) then
		local cvarCrosshair = GetConVar("ma_cl_crosshair"):GetInt()
        local scrX,scrY = surface.ScreenWidth(),surface.ScreenHeight()

		if cvarCrosshair == 3 then
			-- стандартный курсор
			surface.DrawCircle(scrX/2,scrY/2,4.1,drawCrosshair and Color(255,0,0) or Color(255,255,150))
		else
			-- новый курсор
			draw.RoundedBox(3, ScrW() / 2 - 3, ScrH() / 2 - 3, 6, 6, drawCrosshair and (cvarCrosshair == 1 and color_hover_t or color_hover) or (cvarCrosshair == 1 and color_default_t or color_default))
		end

        if toolTipText ~= nil then
            surface.SetFont("MetrostroiLabels")
            local w,h = surface.GetTextSize("SomeText")
            local height = h*1.1
            local texts = string.Explode("\n",toolTipText)
            surface.SetDrawColor(0,0,0,125)
            for i,v in ipairs(texts) do
                local y = scrY/2+height*(i)
                if #v==0 then continue end
                local w2,h2 = surface.GetTextSize(v)
                surface.DrawRect(scrX/2-w2/2-5, scrY/2-h2/2+height*(i), w2+10, h2)
                draw.SimpleText(v,"MetrostroiLabels",scrX/2,y, toolTipColor or Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            end
        end
    end
end
------------------------------------------------

-- замена хуков
timer.Simple(1, function()
	hook.Remove("Think", "metrostroi-cabin-panel")
	hook.Add("Think", "metrostroi-cabin-panel", metrostroi_cabin_panel)
	hook.Remove("HUDPaint", "metrostroi-draw-crosshair-tooltip")
	hook.Add("HUDPaint", "metrostroi-draw-crosshair-tooltip", metrostroi_draw_crosshair_tooltip)
end)
