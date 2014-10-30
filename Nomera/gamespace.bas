#include "gamespace.bi"
#include "printlog.bi"
#include "fbgfx.bi"
#include "debug.bi"
#include "objectlink.bi"
#include "windows.bi"
#include "vbcompat.bi"
#include "fbpng.bi"

using fb

constructor GameSpace()
	dim as ObjectLink link
    randomize timer
    
    link.gamespace_ptr = @this
    link.level_ptr = @lvlData
    link.tinyspace_ptr = @world
    link.player_ptr = @spy
    link.projectilecollection_ptr = @projectiles
    link.oneshoteffects_ptr = @effects
    link.dynamiccontroller_ptr = @dynControl
    link.effectcontroller_ptr = @graphicFX
    link.soundeffects_ptr = @soundFX
    link.pathtracker_ptr = @tracker
    
    graphicFX.setLink(link)
    triggers.setLink(link)
    soundFX.setLink(link)
    soundFX.init()
    effects.setLink(link)
    spy.setLink(link)
    
    movingFrmAvg = 0.016
    vibcount = 0
	lockAction = 0
	winStatus = 0
    lvlData.init(@graphicFX)
    lvlData.setLink(link)
    lvlData.load(command(1))
    world.setBlockData(lvlData.getCollisionLayerData(),_
                       lvlData.getWidth(), lvlData.getHeight(),_
                       16.0)
    fadeoutTex = 0
    bailFrame = 0         
    dynControl.setLink(link)
    graphicFX.setParent(@effects, @projectiles)
    
    spy.body.r = 18
    spy.body.m = 5

                       
    spy.body_i = world.addBody(@(spy.body))
    spy.body.friction = 2
    spy.loadAnimations("mrspy.txt")
	projectiles.setLink(link)
    effects.setParent(@this, @lvlData)
    projectiles.setParent(@world, @lvlData, @this)
    spy.setParent(@world, @lvlData, @projectiles, @this)
    
    projectiles.setEffectsGenerator(@effects)
    
    hud_image = imagecreate(154, 65)
	bload "hud.bmp", hud_image

	currentMusic = 0
    music(0) = 0
    music(1) = 0
    curMusic = lvlData.getCurrentMusicFile()
    music(currentMusic) = FSOUND_Stream_Open(lvlData.getCurrentMusicFile(),_
											 FSOUND_LOOP_NORMAL, 0, 0) 
    'FSOUND_Stream_Play currentMusic, music(currentMusic)
    FSOUND_SetVolumeAbsolute(currentMusic, 255)
        
    switchTracks = 0
    
    spy.centerToMap(lvlData.getDefaultPos())
    lastSpawn = spy.body.p
    camera = spy.body.p
    lastMap = lvlData.getName()
    
    backgroundSnow.setSize(lvlData.getWidth() * 16, lvlData.getHeight() * 16)
    backgroundSnow.setFreq(3, 3)
    backgroundSnow.setDepth(15, 18)
    backgroundSnow.setDrift(-333)
    backgroundSnow.setSpeed(900)
    
    foregroundSnow.setSize(lvlData.getWidth() * 16, lvlData.getHeight() * 16)
    foregroundSnow.setFreq(1, 15)
    foregroundSnow.setDepth(0.5, 4)
    foregroundSnow.setDrift(-333)
    foregroundSnow.setSpeed(700)
    
    tracker.init(link)
    pathfile = lvlData.getName() & "_pathing.dat"
    if fileexists(pathfile) then
        pathFileNum = freefile
		open pathfile for binary as #pathFileNum
		get #pathFileNum,,pathBytes
		pathData = new byte[pathBytes]
		get #pathFileNum,,pathData[0],pathBytes
		tracker.importGraph(pathData, pathBytes)
		delete(pathData)
		close #pathFileNum
    end if
    
    tracker.pause()

    scnbuff = imagecreate(640,480)
    stallTime_mili = 15
    movingFrmAvg = 0
end constructor

sub GameSpace.reconnectCollision()
    world.setBlockData(lvlData.getCollisionLayerData(),_
                   lvlData.getWidth(), lvlData.getHeight(),_
                   16.0)
end sub

destructor GameSpace
    imagedestroy scnbuff
end destructor
        
sub GameSpace.setMusicVolume(v as integer)
	FSOUND_SetVolumeAbsolute currentMusic, v
end sub
        
function GameSpace.go() as integer
    dim as double startTime, totalTime
    dim as byte ptr trackerEx
    dim as integer  dataSize
    do
		
        startTime = timer
		step_draw()
        step_input()
        step_process()
        frameTime = timer - startTime
        if keypress(SC_ESCAPE) then exit do
        'print spy.body.p
        locate 1,1
        movingFrmAvg = movingFrmAvg * 0.25 + 0.75 * (frameTime / (1 / FPS_TARGET) * 100)
		'print using "Engine at ##.##% load"; movingFrmAvg
		
		stall( stallTime_mili)
		totalTime = (timer - startTime)
        if totalTime < (1 / FPS_TARGET) then
			stallTime_mili += 1
		else
			stallTime_mili -= 1
			if stallTime_mili < 0 then stallTime_mili = 0
		end if
		
		if keypress(SC_P) then
			sleep
			stall(100)
			sleep
		end if
    loop 
    
	kill pathFile
	pathFileNum = freefile
	open pathfile for binary as #pathFileNum
	tracker.exportGraph(pathData, pathBytes)
	put #pathFileNum,,pathBytes
	put #pathFileNum,,pathData[0], pathBytes
	close #pathFileNum
	deallocate(pathData)
    return 0
end function
            
sub GameSpace.step_input()
    keypress(SC_ESCAPE) = multikey(SC_ESCAPE)
    keypress(SC_LEFT) = multikey(SC_LEFT)
    keypress(SC_RIGHT) = multikey(SC_RIGHT)
    keypress(SC_UP) = multikey(SC_UP)
    keypress(SC_X) = multikey(SC_X)
    keypress(SC_DOWN) = multikey(SC_DOWN)
    keypress(SC_Z) = multikey(SC_Z)
    keypress(SC_LSHIFT) = multikey(SC_LSHIFT) or multikey(SC_RSHIFT)
    keypress(SC_M) = multikey(SC_M)
    keypress(SC_N) = multikey(SC_N)
    keypress(SC_DELETE) = multikey(SC_DELETE)
    keypress(SC_P) = multikey(SC_P)
    keypress(SC_0) = multikey(SC_0)
    keypress(SC_1) = multikey(SC_1)
    keypress(SC_2) = multikey(SC_2)
    keypress(SC_3) = multikey(SC_3)
    keypress(SC_4) = multikey(SC_4)
    keypress(SC_5) = multikey(SC_5)
    keypress(SC_6) = multikey(SC_6)
    keypress(SC_7) = multikey(SC_7)
    keypress(SC_8) = multikey(SC_8)
    keypress(SC_9) = multikey(SC_9)
end sub

sub GameSpace.vibrateScreen()
    vibcount = 4
end sub

sub GameSpace.hardSwitchMusic(filename as string)
	music(1 - currentMusic) = FSOUND_Stream_Open(filename,_
												 FSOUND_LOOP_NORMAL, 0, 0) 
	FSOUND_Stream_Play (1 - currentMusic), music(1 - currentMusic)
	FSOUND_SetVolumeAbsolute (1 - currentMusic), 0
	FSOUND_Stream_Stop  music(currentMusic)
	FSOUND_Stream_Close music(currentMusic)
	FSOUND_SetVolumeAbsolute (1 - currentMusic), 255
	currentMusic = 1 - currentMusic
end sub

sub GameSpace.step_draw()
    dim as integer x, y, block
    dim as integer tl_x, tl_y
    dim as integer br_x, br_y
    dim as integer shake
    if isSwitching = 0 then
		camera = spy.body.p * 0.1 + camera * 0.9
	elseif isSwitching = -1 then
		camera = spy.body.p
	end if
    if lvlData.getWidth() * 16 > SCRX then
        if camera.x() < SCRX*0.5 then 
            camera.setX(SCRX*0.5)
        elseif camera.x() >= lvlData.getWidth()*16 - SCRX*0.5 then
            camera.setX(lvlData.getWidth()*16 - SCRX*0.5)
        end if
    else
        camera.setX(lvlData.getWidth() * 8)
    end if
    
    if lvlData.getHeight() * 16 > SCRY then
        if camera.y() < SCRY*0.5 then 
            camera.setY(SCRY*0.5)
        elseif camera.y() >= lvlData.getHeight()*16 - SCRY*0.5 then
            camera.setY(lvlData.getHeight()*16 - SCRY*0.5)
        end if  
    else
        camera.setY(lvlData.getHeight() * 8)
    end if
        
    camera.setX(int(camera.x()))
    camera.setY(int(camera.y()))

  
    window screen (camera.x() - SCRX * 0.5, camera.y() - SCRY * 0.5)-_
                  (camera.x() + SCRX * 0.5, camera.y() + SCRY * 0.5)
                  
    line scnbuff, (camera.x() - SCRX * 0.5, camera.y() - SCRY * 0.5)-_
                  (camera.x() + SCRX * 0.5, camera.y() + SCRY * 0.5), 0, BF
    
    if vibcount > 0 then
        shake = ((vibcount mod 2) * 2 - 1) * 5
    else
        shake = 0
    end if
	
    lvlData.drawLayers(scnbuff, BACKGROUND, camera.x(), camera.y(), Vector2D(0, 0))
    if lvlData.usesSnow() = 1 then backgroundSnow.drawFlakes(scnbuff, camera)
    lvlData.drawLayers(scnbuff, ACTIVE, camera.x(), camera.y(), Vector2D(0, shake))
    graphicFX.drawEffects(scnbuff, camera, ACTIVE)
    spy.drawPlayer(scnbuff)
	dynControl.drawDynamics(scnbuff, ACTIVE)

	lvlData.drawLayers(scnbuff, ACTIVE_COVER, camera.x(), camera.y(), Vector2D(0, shake))
	dynControl.drawDynamics(scnbuff, ACTIVE_COVER)
    lvlData.drawLayers(scnbuff, FOREGROUND, camera.x(), camera.y(), Vector2D(0, shake))
    effects.draw_effects(scnbuff)
    projectiles.draw_collection(scnbuff)

    if lvlData.usesSnow() = 1 then foregroundSnow.drawFlakes(scnbuff, camera)
    spy.drawItems(scnbuff, Vector2D(0, shake))

    
    dynControl.drawDynamics(scnbuff, FOREGROUND)
    
	
    window screen (0,0)-(SCRX-1,SCRY-1)
    
    /'
    if spy.health > 75 then
		put scnbuff, (8,11), hud_image, (0,18)-(151,25), TRANS
    elseif spy.health > 50 then
		put scnbuff, (8,11), hud_image, (0,26)-(151,33), TRANS
    elseif spy.health > 25 then
		put scnbuff, (8,11), hud_image, (0,34)-(151,41), TRANS
    elseif spy.health > 0 then
    	put scnbuff, (8,11), hud_image, (0,42)-(151,49), TRANS
    end if

	if spy.charge > 0 then
		if spy.charge = 100 then
			if spy.chargeFlicker < 4 then
				line scnbuff, (17, 19)-(117, 22), &hff0000, BF
			else
				line scnbuff, (17, 19)-(117, 22), &hffff00, BF
			end if
		else
			put scnbuff, (17, 19), hud_image, (9, 15)-(spy.charge + 9, 17), TRANS
		end if
	end if
	if spy.beingHarmed() > 0 then
		put scnbuff, (8,8), hud_image, (0,50)-(151,64), TRANS
	else
		put scnbuff, (8,8), hud_image, (0,0)-(151,14), TRANS
	end if
	
	drawStringShadow(scnbuff, 144, 11, str(spy.bombs), rgb(200,200,200))
	'/
    
    if isSwitching <> 0 then
		line scnbuff, (0, SCRY - 1)-(SCRX - 1, SCRY - switchFrame - 1), 0, BF
    end if
    
    triggers.draw_(scnbuff)
    
    if shouldBail > 0 then
		if fadeoutTex = 0 then 
			fadeoutTex = imagecreate(SCRX, SCRY)
			if shouldBail = 1 then
				line fadeoutTex,(0,0)-(639, 479),&hffffff, BF
			else
				line fadeoutTex,(0,0)-(639, 479),&h606060, BF
			end if
		end if
		put scnbuff, (0,0), fadeoutTex, ALPHA, min(255, bailFrame+1)
		bailFrame += 3	
	end if
	   
    window screen (camera.x() - SCRX * 0.5, camera.y() - SCRY * 0.5)-_
                  (camera.x() + SCRX * 0.5, camera.y() + SCRY * 0.5)
    tracker.record_draw(scnbuff)

    scale2sync scnbuff
    
end sub
    


sub GameSpace.step_process()
    dim as integer i, dire, jump, ups, fire
    dim as integer numbers(0 to 9)
    
    
    if keypress(SC_RIGHT) then
        dire = 1
    elseif keypress(SC_LEFT) then
        dire = -1
    else
        dire = 0
    end if
    if keypress(SC_Z) then 
        jump = 1
    else
        jump = 0
    end if
    if keypress(SC_UP) then 
        ups = -1
    elseif keypress(SC_DOWN) then
        ups = 1
    else
        ups = 0
    end if
    if keypress(SC_X) then
        fire = 1 
    else
        fire = 0
    end if
    
    numbers(0) = keypress(SC_1)
    numbers(1) = keypress(SC_2)
    numbers(2) = keypress(SC_3)
    numbers(3) = keypress(SC_4)
    numbers(4) = keypress(SC_5)
    numbers(5) = keypress(SC_6)
    numbers(6) = keypress(SC_7)
    numbers(7) = keypress(SC_8)
    numbers(8) = keypress(SC_9)
    numbers(9) = keypress(SC_0)
    
    vibcount -= 1
    
    dynControl.process(0.01667)
    
	if keypress(SC_M) then tracker.record()
	if keypress(SC_N) then tracker.pause()
	
	if isSwitching <> 1 andAlso lockAction <> 1 then
    	spy.processControls(dire, jump, ups, fire, keypress(SC_LSHIFT), numbers(), 0.01667)
    elseif lockAction = 1 then
    	spy.processControls(0, 0, 0, 0, 0, numbers(), 0.01667)
    end if
    spy.processItems(0.01667)
    if lvlData.usesSnow() = 1 then 
        backgroundSnow.stepFlakes(camera, 0.01667)
        foregroundSnow.stepFlakes(camera, 0.01667)
    end if
    projectiles.proc_collection(0.01667)
    graphicFX.processFrame(camera)
 
    effects.proc_effects(0.01667)
        
    if lvlData.mustReconnect() = 1 then reconnectCollision()
    triggers.process(0.01667)
        
    if isSwitching = 1 then
		switchFrame += 64
		if switchFrame > 512 then
			performSwitch(pendingSwitch)
		end if
	elseif isSwitching = -1 then
		if switchFrame = 512 then
			if lvlData.getCurrentMusicFile() <> curMusic then
				music(1 - currentMusic) = FSOUND_Stream_Open(lvlData.getCurrentMusicFile(),_
															 FSOUND_LOOP_NORMAL, 0, 0) 
				FSOUND_Stream_Play (1 - currentMusic), music(1 - currentMusic)
				FSOUND_SetVolumeAbsolute (1 - currentMusic), 0
				switchTracks = 1
			end if
		end if
		switchFrame -= 64
		if switchTracks = 1 then
			FSOUND_SetVolumeAbsolute(currentMusic, (switchFrame / 512) * 255)
			FSOUND_SetVolumeAbsolute((1 - currentMusic), (1 - (switchFrame / 512)) * 255)
		end if
		if switchFrame = 0 then
			isSwitching = 0
			if switchTracks = 1 then
				switchTracks = 0
				FSOUND_Stream_Stop  music(currentMusic)
				FSOUND_Stream_Close music(currentMusic)
				currentMusic = 1 - currentMusic
				curMusic = lvlData.getCurrentMusicFile()
			end if
		end if
    end if

	if bailFrame > 255 then
		doGameEnd()
	end if
  
	tracker.step_record(keypress(SC_DELETE))
  
    if isSwitching = 0 then
		#ifdef DEBUG
			world.step_time(0.01667)
		#else
			for i = 1 to 3
				world.step_time(0.00555)
			next i
		#endif
	end if

end sub
sub GameSpace.doGameEnd()
	#macro sync()
		screenlock	
			scale2sync scnbuff
		screenunlock
		flip
	#endmacro
	window screen (0,0)-(SCRX-1,SCRY-1)
	if winstatus = 0 then
		line scnbuff,(0,0)-(SCRX-1,SCRY-1),&h606060,BF
		sync()
		stall(1000)
		drawstringshadow scnbuff, SCRX * 0.5 - 80, SCRY*0.5 - 8, "THANK YOU FOR PLAYING", &hffffff
		sync()
	else
		line scnbuff,(0,0)-(SCRX-1,SCRY-1),&hffffff,BF
		sync()
		stall(1000)
		drawstringshadow scnbuff, SCRX * 0.5 - 60, SCRY*0.5 - 8, "CONGRATULATIONS", &h808080
		sync()
	end if
	do
		if multikey(1) then end
	loop

end sub
sub GameSpace.centerCamera(c as Vector2D)  
	camera = c
end sub
sub GameSpace.switchRegions(ls as LevelSwitch_t)
	isSwitching = 1
	switchFrame = 0
	pendingSwitch = ls
end sub     
sub GameSpace.performSwitch(ls as LevelSwitch_t)
	isSwitching = -1
	
	lvlData.load(ls.fileName)
    world.setBlockData(lvlData.getCollisionLayerData(),_
                       lvlData.getWidth(), lvlData.getHeight(),_
                       16.0)
end sub 

function GameSpace.getLastFileName() as string
	return lastMap + ".map"
end function
function GameSpace.getLastPosition() as Vector2D    
	return lastSpawn
end function    
function GameSpace.getCurrentFileName() as string
	return lvlData.getName() + ".map"
end function
