if SERVER then
	Metrostroi.GetCam = function()
		if not IsValid(Metrostroi.RTCamera) then
			Metrostroi.RTCamera = ents.Create( "point_camera" )
			Metrostroi.RTCamera:SetKeyValue( "GlobalOverride", 1 )
			Metrostroi.RTCamera:SetKeyValue( "fogEnable", 1 )
			Metrostroi.RTCamera:SetKeyValue( "fogStart", 1 )
			Metrostroi.RTCamera:SetKeyValue( "fogEnd", 4096  )
			Metrostroi.RTCamera:SetKeyValue( "fogColor", "255 0 255 127"     )
			Metrostroi.RTCamera:SetPos(Vector(0,0,-2^16))
			Metrostroi.RTCamera:SetNoDraw(true)
			Metrostroi.RTCamera:Activate()
			Metrostroi.RTCamera:Spawn()
			Metrostroi.RTCamera:Fire( "SetOff", "", 0.0 )
		end
		return Metrostroi.RTCamera
	end

else
	local CamRT = surface.GetTextureID( "pp/rt" )
	hook.Remove("Think","metrostroi_camera_move")
	hook.Add("Think","metrostroi_camera_move",function()
		if IsValid(Metrostroi.RTCamera) then
			Metrostroi.RTCamera:SetPos(Vector(0,0,-2^16))
			Metrostroi.RTCamera:SetAngles(Angle(90,0,0))
		end
		if Metrostroi.RenderCam and Metrostroi.RenderedCam ~= RealTime() then
			local camera = Metrostroi.RenderCam
			Metrostroi.RenderCam = nil
			if IsValid(camera[1]) then
				local distance = camera[1]:LocalToWorld(camera[2]):Distance(LocalPlayer():GetPos())
				if distance > 256 then return end
				local x,y = camera[9],camera[10]
				local scale = camera[11] or 1
				local xmin,ymin = camera[12] or 0,camera[13] or 0
				render.PushRenderTarget(camera[5],0,0,x, y)
				render.Clear(0, 0, 0, 0)
				cam.Start2D()
					surface.SetTexture( CamRT )
					surface.SetDrawColor( 255, 255, 255, 255 )
					surface.DrawTexturedRectRotated((x/2-xmin)*scale,(y/2-ymin)*scale,x*scale,y*scale,0)
				cam.End2D()
				render.PopRenderTarget()
			else
			end
		end
		if #Metrostroi.CamQueue > 0 and not Metrostroi.RenderCam then
			local cam = table.remove(Metrostroi.CamQueue,1)
			Metrostroi.CamQueue[cam[3]] = nil
			local name,time,post,pos,ang = cam[3],cam[4],cam[6],cam[7],cam[8]
			if IsValid(post) then
				debugoverlay.Sphere(post:LocalToWorld(pos),1,time,Color( 150, 105, 200 ),true)
				debugoverlay.Text(post:LocalToWorld(pos),name,time,Color( 150, 105, 200 ),true)
				debugoverlay.Line(post:LocalToWorld(pos),post:LocalToWorld(pos)+post:LocalToWorldAngles(ang):Forward()*25,time,Color( 150, 105, 200 ),true)
				Metrostroi.RenderCam = cam
				Metrostroi.SetCamPosAng(post:LocalToWorld(cam[7]),post:LocalToWorldAngles(cam[8]))
				Metrostroi.CamTimers[cam[3]] = RealTime()
			end
		end
	end)
	
end