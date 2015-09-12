#include "gamespace.bi"
#include "printlog.bi"
#include "fbgfx.bi"
#include "debug.bi"
#include "objectlink.bi"

#define WIN_INCLUDEALL
#include "windows.bi"

#include "vbcompat.bi"
#include "fbpng.bi"

#define SLEEP_RESOLUTION 1

using fb

constructor GameSpace()
    dim as integer i
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
    link.electricarc_ptr = @arcEffects
      
   
    graphicFX.setLink(link)
    triggers.setLink(link)
    soundFX.setLink(link)
    soundFX.init()
    effects.setLink(link)
    spy.setLink(link)
    dynControl.setLink(link)
    lvlData.setLink(link)
	projectiles.setLink(link)
  

    movingFrmAvg = 0.016
    vibcount = 0
	lockAction = 0
	winStatus = 0
    lvlData.init(@graphicFX)
    
    lvlData.load(command(1))

    fadeoutTex = 0
    bailFrame = 0         
    graphicFX.setParent(@effects, @projectiles)
    
    spy.body.r = 18
    spy.body.m = 5

                       
    spy.body_i = world.addBody(@(spy.body))
    spy.body.friction = 2


    effects.setParent(@this, @lvlData)
    projectiles.setParent(@world, @lvlData, @this)
    spy.setParent(@world, @lvlData, @projectiles, @this)
    
    projectiles.setEffectsGenerator(@effects)
    
    arcEffects.init(SCRX, SCRY)
	
	currentMusic = 0
    music(0) = 0
    music(1) = 0
    curMusic = lvlData.getCurrentMusicFile()
    music(currentMusic) = FSOUND_Stream_Open(lvlData.getCurrentMusicFile(),_
											 FSOUND_LOOP_NORMAL, 0, 0) 
    FSOUND_Stream_Play currentMusic, music(currentMusic)
    FSOUND_SetVolumeAbsolute(currentMusic, 128)
    musicVol = 128
    musicVolDir = 0
   
    switchTracks = 0
    
    spy.centerToMap(lvlData.getDefaultPos())
    'spy.body.p = Vector2D(3000, 1000)
    
    lastSpawn = spy.body.p
    camera = spy.body.p
    lastMap = lvlData.getName()
    
    backgroundSnow.setSize(lvlData.getWidth() * 16, lvlData.getHeight() * 16)
    backgroundSnow.setFreq(3, 3)
    backgroundSnow.setDepth(6, 10)
    'backgroundSnow.setDepth(15, 18)
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
     
    for i = 0 to 255
        last_keypress(i) = 0
    next i
	
    scnbuff = imagecreate(640,480)
    stallTime_mili = 15
    movingFrmAvg = 0
    shake = 0 
    lastTurnstyleInput = 0
    lockCamera = 1
    
    
    timeBeginPeriod(SLEEP_RESOLUTION)
    
    #ifdef KICKSTARTER
        
        'spy.initPathing()
	
        dim as string fname, extract, levelName
        dim as integer filenum, tag
        dim as recordFrame_t frame
        dim as Item ptr sitem
        dim as recordFrame_t ptr frames
        dim as integer frames_N
        dim as integer soldierType, stamp
        fname = Dir("pathing\"+lcase(lvlData.getName())+"\*.path") 

        Do Until Len(fname) = 0 
            
            extract = right(fname, len(fname) - instrrev(fname, "_"))
            stamp = val(left(extract, instr(extract, ".") - 1))

            if stamp <> spy.timeStamp then
                
                filenum = freefile
                open "pathing\"+lcase(lvlData.getName())+"\"+fname for binary as filenum
                
                frames = 0
                frames_N = 0
                get #filenum,,soldierType
                get #filenum,,tag
                getStringFromFile(filenum, levelName)
                if levelName = lvlData.getName() then

                    'print fname

                    while not eof(filenum)
                        get #filenum, ,frame
                        
                        frames_N += 1
                        frames = reallocate(frames, sizeof(recordFrame_t) * frames_N)
                        frames[frames_N - 1] = frame
                        
                    wend
                    
                    
                    sitem = dynControl.constructItem(dynControl.itemStringToType("RECORDED SOLDIER"), ACTIVE_FRONT)
                    sitem->setParameter(soldierType, "soldierType")
                    sitem->setParameter(cast(integer, frames), "frames_ptr")
                    sitem->setParameter(frames_N, "frames_N")
                    sitem->setParameter(tag, "tag")
                    dynControl.initItem(sitem)
                    
                    
                end if
                    
                close #filenum
            end if
            fname = Dir()

        Loop
        'sleep            
    #endif
    manualInput_dire = 0
end constructor

sub GameSpace.reconnectCollision()
    world.setBlockData(lvlData.getCollisionLayerData(),_
                   lvlData.getWidth(), lvlData.getHeight(),_
                   16.0)
                   
end sub

destructor GameSpace
    imagedestroy scnbuff
    timeEndPeriod(SLEEP_RESOLUTION)
end destructor
        
sub GameSpace.setMusicVolume(v as integer)
    musicVol = v
	FSOUND_SetVolumeAbsolute currentMusic, v
end sub
        
function GameSpace.go() as integer
    dim as double startTime, processTime, oneSecondMaxLoad, secondTimer, oneSecondAvg, oneSecondAvgLast
    dim as double load
    dim as byte ptr trackerEx
    dim as integer  dataSize, frames
    stallTime_mili = 1
    step_process()
    secondTimer = timer
    oneSecondMaxLoad = 0
    frames = 0
    oneSecondAvg = 0
    oneSecondAvgLast =0
    do
		
        startTime = timer
		step_draw()
        
        locate 1,1
        load = (processTime / (1000 / FPS_TARGET)) * 100
        if load > oneSecondMaxLoad then oneSecondMaxLoad = load
        oneSecondAvg += load
        #ifdef SCALE_ELLIOTT
            locate 1,1
            print "                                            "
            print "                                            "
            print "                                            "
        #endif
        locate 1,1
        'print using "Frame Load %: ##.##"; load
        'print using "One Second Max Load %: ##.##"; oneSecondMaxLoad
        'print using "One Second Average Load %: ##.##"; oneSecondAvgLast
        
        'print spy.body.p

        
        step_input()
        step_process()
        processTime = 1000*(timer - startTime)
                
        while multikey(SC_P): wend
        
        sleep(SLEEP_RESOLUTION * stallTime_mili)
        frameTime = timer - startTime
        if keypress(SC_ESCAPE) then exit do
        
   
        movingFrmAvg = movingFrmAvg*0.8 + 0.2*(frameTime*1000)		
        if movingFrmAvg < (1000 / FPS_TARGET) then
			stallTime_mili += 1
		else
			stallTime_mili -= 1
			if stallTime_mili < 0 then stallTime_mili = 0
		end if
        if Timer - secondTimer >= 1 then
            oneSecondMaxLoad = 0
            oneSecondAvgLast = oneSecondAvg / frames
            oneSecondAvg = 0
            frames = 0
            secondTimer = timer
        end if
        frames += 1
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
    keypress(SC_Q) = multikey(SC_Q)
    keypress(SC_W) = multikey(SC_W)
    keypress(SC_A) = multikey(SC_A)
    keypress(SC_S) = multikey(SC_S)
    keypress(SC_SPACE) = multikey(SC_SPACE)
end sub

sub GameSpace.vibrateScreen(vibAmount as integer = 8)
    vibcount = vibAmount
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
    #define INIT_PROFILE(X) timeAdd(X) = 0
    #define START_PROFILE(X) startTime(X) = timer
    #define RECORD_PROFILE(X) timeAdd(X) += timer - startTime(X)

    dim as integer x, y, block
    dim as integer tl_x, tl_y
    dim as integer br_x, br_y
    dim as integer i
    
    dim as double tM, tS, totalT, startTotalT
    dim as double timeAdd(0 to 9), startTime(0 to 9)
    static as double timeProfiles(0 to 9)
    
    for i = 0 to 9
        INIT_PROFILE(i)
    next i
    
    START_PROFILE(0)
    
    window screen (0,0)-(SCRX-1,SCRY-1)
    if lvlData.getWidth() < 40 orElse lvlData.getHeight() < 30 then
        line scnbuff, (0,0)-(SCRX-1,SCRY-1), 0, BF
    end if
    
    window screen (camera.x() - SCRX * 0.5, camera.y() - SCRY * 0.5)-_
                  (camera.x() + SCRX * 0.5, camera.y() + SCRY * 0.5)
                  
	
    
    
    START_PROFILE(3)
    
    START_PROFILE(1)
    lvlData.drawLayers(scnbuff, BACKGROUND, camera.x(), camera.y(), Vector2D(0, 0))
    dynControl.drawDynamics(scnbuff, BACKGROUND)
    RECORD_PROFILE(1)
    
    
    START_PROFILE(2)
    if lvlData.usesSnow() then backgroundSnow.drawFlakes(scnbuff, camera)
    if lvlData.usesSnow() = 2 then foregroundSnow.drawFlakes(scnbuff, camera)
    RECORD_PROFILE(2)
    
    START_PROFILE(1)
    lvlData.drawLayers(scnbuff, ACTIVE, camera.x(), camera.y(), Vector2D(0, shake))
    RECORD_PROFILE(1)
    
    START_PROFILE(4)
    graphicFX.drawEffects(scnbuff, camera, ACTIVE)
    RECORD_PROFILE(4)
    
    START_PROFILE(6)
	dynControl.drawDynamics(scnbuff, ACTIVE)
    RECORD_PROFILE(6)
    
    START_PROFILE(1)
    lvlData.drawLayers(scnbuff, ACTIVE_FRONT, camera.x(), camera.y(), Vector2D(0, shake))
    dynControl.drawDynamics(scnbuff, ACTIVE_FRONT)
    RECORD_PROFILE(1)    
    
    START_PROFILE(5)
    spy.drawPlayer(scnbuff)
    RECORD_PROFILE(5)
     
    START_PROFILE(1)
	lvlData.drawLayers(scnbuff, ACTIVE_COVER, camera.x(), camera.y(), Vector2D(0, shake))'
    dynControl.drawDynamics(scnbuff, ACTIVE_COVER)
    RECORD_PROFILE(1)

    
    START_PROFILE(1)
    lvlData.drawLayers(scnbuff, FOREGROUND, camera.x(), camera.y(), Vector2D(0, shake))
    dynControl.drawDynamics(scnbuff, FOREGROUND)
    
    RECORD_PROFILE(1)


    
    START_PROFILE(2)
    if lvlData.usesSnow() = 1 then foregroundSnow.drawFlakes(scnbuff, camera)
    RECORD_PROFILE(2)


    START_PROFILE(6)
    lvlData.drawSmoke(scnbuff)
    arcEffects.drawArcs(scnbuff)

    effects.draw_effects(scnbuff)
    projectiles.draw_collection(scnbuff)
    
    dynControl.drawDynamics(scnbuff, OVERLAY)
    RECORD_PROFILE(6)

    
    START_PROFILE(5)
    spy.drawOverlay(scnbuff, Vector2D(0, shake))
    RECORD_PROFILE(5)
    
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
    
    'triggers.draw_(scnbuff)
    
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
    RECORD_PROFILE(3)

    #ifndef SCALE_ELLIOTT
        #ifndef SCALE_2X
            window screen (0,0)-(SCRX-1,SCRY-1)
                  
            put (0,0), scnbuff, PSET
        #else
            scale2sync scnbuff
        #endif
    #else
        window screen (0,0)-(799, 599)
        line (79, 59)-(720, 540), &h1f1f1f, B
        put (80,60), scnbuff, PSET
    #endif 
    RECORD_PROFILE(0)
    
    

    for i = 0 to 9
        timeProfiles(i) = timeProfiles(i) * 0.90 + 0.10 * timeAdd(i)
    next i
    /'
    window screen (0,0)-(SCRX*2-1,SCRY*2-1)
    draw string (0, 8),  "Time % to draw static layers: " + str(int((timeProfiles(1) / timeProfiles(3))*100)), 0
    draw string (0, 16), "Time % to draw snow: " + str(int((timeProfiles(2) / timeProfiles(3))*100)),0
    draw string (0, 24), "Time % to draw projectiles and one shots: " + str(int((timeProfiles(4) / timeProfiles(3))*100)),0
    draw string (0, 32), "Time % to draw player and overlay: " + str(int((timeProfiles(5) / timeProfiles(3))*100)), 0
    draw string (0, 40), "Time % to draw dynamic objects: " + str(int((timeProfiles(6) / timeProfiles(3))*100)),0
    draw string (0, 48), "Time % to draw to buffer out of screen refresh time " + str(int((timeProfiles(3) / timeProfiles(0))*100)),0
    '/
end sub
    
sub GameSpace.setShakeStyle(style as integer)
    slowdownShake = style
end sub

sub GameSpace.fadeMusicIn()
    musicVolDir = 1
end sub
sub GameSpace.fadeMusicOut()
    musicVolDir = -1
end sub
sub GameSpace.resetMusicFade()
    musicVolDir = 0
end sub

sub GameSpace.step_process()

    #define INIT_PROFILE(X) timeAdd(X) = 0
    #define START_PROFILE(X) startTime(X) = timer
    #define RECORD_PROFILE(X) timeAdd(X) += timer - startTime(X)
    
    dim as integer i, dire, jump, ups, fire, explodeAll, deactivateAll
    dim as integer numbers(0 to 9), turnstyle, turnstyleInput, activate, actualVol

    dim as double tM, tS, totalT, startTotalT, mmult
    dim as double timeAdd(0 to 9), startTime(0 to 9)
    static as double timeProfiles(0 to 9)
    
    for i = 0 to 9
        INIT_PROFILE(i)
    next i
    
    START_PROFILE(0)
    
    window
    
    if lockCamera = 1 then
   
        if isSwitching = 0 then
            camera = spy.body.p * 0.1 + camera * 0.9
        elseif isSwitching = -1 then
            camera = spy.body.p
        end if
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
    
    if vibcount > 0 then
        shake = (((vibcount/3) mod 2) * 2 - 1) * iif(slowdownShake, _min_(vibcount*0.25, 4), 4)
    else
        shake = 0
    end if
    
	tracker.step_record(keypress(SC_DELETE))
    START_PROFILE(1)
    if isSwitching = 0 then
		#ifdef DEBUG
			world.step_time(0.01667)
		#else
			for i = 1 to 3
				world.step_time(0.0055555)
			next i
		#endif
	end if
    RECORD_PROFILE(1)
    
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
    
    turnstyle = 0
    if keypress(SC_A) then
        turnstyle = -1
    elseif keypress(SC_S) then
        turnstyle = 1
    end if
    
    if lastTurnstyleInput = 0 andalso turnstyle <> 0 then
        turnstyleInput = turnstyle
    else
        turnstyleInput = 0       
    end if
        
    if lockAction = 0 then
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
    end if
    
    explodeAll = keypress(SC_W)
    deactivateAll = keypress(SC_Q)
    
    if vibcount > 0 then vibcount -= 1
    
    musicVol += musicVolDir*2
    if musicVol < 0 then
        musicVol = 0
    elseif musicVol > 255 then
        musicVol = 255
    end if
    
    actualVol = musicVol

    mmult = 1
    select case curMusic
    case "Mountain.ogg"
        mmult = 0.25
    case "Lab.ogg"
        mmult = 0.5
    end select
    FSOUND_SetVolumeAbsolute(currentMusic, actualVol*mmult)
    
    if keypress(SC_SPACE) andAlso (last_keypress(SC_SPACE) = 0) then 
        activate = 1
    else
        activate = 0
    end if
    
    lvlData.process(0.01667)
    dynControl.process(0.01667)
    
	if keypress(SC_M) then tracker.record()
	if keypress(SC_N) then tracker.pause()
	
	if isSwitching <> 1 andAlso lockAction <> 1 then
    	spy.processControls(dire, jump, ups, fire, keypress(SC_LSHIFT), numbers(), explodeAll, deactivateAll, turnstyleInput, activate, 0.01667)
    elseif lockAction = 1 then
    	spy.processControls(manualInput_dire, 0, 0, 0, 0, numbers(), 0, 0, 0, 0, 0.01667)
    end if
    spy.processItems(0.01667)
    if lvlData.usesSnow() then 
        backgroundSnow.stepFlakes(camera, 0.01667)
        foregroundSnow.stepFlakes(camera, 0.01667)
    end if
    projectiles.proc_collection(0.01667)
    graphicFX.processFrame(camera)
 
    effects.proc_effects(0.01667)
    arcEffects.stepArcs(0.01667)

        
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
				'FSOUND_SetVolumeAbsolute (1 - currentMusic), 0
				switchTracks = 1
                FSOUND_SetVolumeAbsolute(currentMusic, 0)'(switchFrame / 512) * 255 * mmult)

			end if
		end if
		switchFrame -= 64
		if switchTracks = 1 then
			FSOUND_SetVolumeAbsolute((1 - currentMusic), 0)
		end if
		if switchFrame = 0 then
			isSwitching = 0
			if switchTracks = 1 then
				switchTracks = 0
               
                FSOUND_Stream_Play (1 - currentMusic), music(1 - currentMusic)

                FSOUND_SetVolumeAbsolute((1 - currentMusic), 0)
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
    

    
    RECORD_PROFILE(0)
    for i = 0 to 9
        timeProfiles(i) = timeProfiles(i) * 0.90 + 0.10 * timeAdd(i)
    next i
    'print int((timeProfiles(1) / timeProfiles(0)) * 100)
    lastTurnstyleInput = turnstyle
    for i = 0 to 255
        last_keypress(i) = keypress(i)
    next i
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
    
    kill pathFile
	pathFileNum = freefile
	open pathfile for binary as #pathFileNum
	tracker.exportGraph(pathData, pathBytes)
	put #pathFileNum,,pathBytes
	put #pathFileNum,,pathData[0], pathBytes
	close #pathFileNum
	deallocate(pathData)
    
	lvlData.saveMapState()
	lvlData.load(ls.fileName)
    world.setBlockData(lvlData.getCollisionLayerData(),_
                       lvlData.getWidth(), lvlData.getHeight(),_
                       16.0)
                       
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
