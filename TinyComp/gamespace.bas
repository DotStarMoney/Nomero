#include "gamespace.bi"
#include "printlog.bi"
#include "fbgfx.bi"
#include "debug.bi"

using fb

constructor GameSpace()
    randomize timer
    movingFrmAvg = 0.016
    vibcount = 0

    lvlData.init(@graphicFX)
    lvlData.load(command(1))
    world.setBlockData(lvlData.getCollisionLayerData(),_
                       lvlData.getWidth(), lvlData.getHeight(),_
                       16.0)
                  
    graphicFX.setParent(@effects, @projectiles)
    
    spy.body.r = 18
    spy.body.m = 5
    spy.body.p = Vector2D(665,397)

    camera = spy.body.p
                       
    spy.body_i = world.addBody(@(spy.body))
    spy.body.friction = 2
    spy.loadAnimations("mrspy.txt")

    effects.setParent(@this)
    projectiles.setParent(@world, @lvlData, @this)
    spy.setParent(@world, @lvlData, @projectiles, @this)
    
    projectiles.setEffectsGenerator(@effects)

    'FSOUND_Init(44100, 3, 0)
    'music = FSOUND_Stream_Open("PurovskyDistrict.ogg", FSOUND_LOOP_NORMAL, 0, 0 ) 
    'FSOUND_Stream_Play 1, music
    
    backgroundSnow.setSize(lvlData.getWidth() * 16, lvlData.getHeight() * 16)
    backgroundSnow.setFreq(3, 3)
    backgroundSnow.setDepth(8, 10)
    backgroundSnow.setDrift(-10)
    backgroundSnow.setSpeed(20)
    
    foregroundSnow.setSize(lvlData.getWidth() * 16, lvlData.getHeight() * 16)
    foregroundSnow.setFreq(1, 15)
    foregroundSnow.setDepth(0.5, 4)
    foregroundSnow.setDrift(-10)
    foregroundSnow.setSpeed(30)
    
    scnbuff = imagecreate(640,480)

end constructor

sub GameSpace.reconnectCollision()
    world.setBlockData(lvlData.getCollisionLayerData(),_
                   lvlData.getWidth(), lvlData.getHeight(),_
                   16.0)
end sub

destructor GameSpace
    imagedestroy scnbuff
end destructor
        
function GameSpace.go() as integer
    dim as single startTime, totalTime
    dim as integer stallTime
    do
        startTime = timer
        cls
        step_draw()
        step_input()
        step_process()
        
        if keypress(SC_ESCAPE) then exit do
        print using "Engine at ##.##% load"; movingFrmAvg * (FPS_TARGET / 10)
        flip
        totalTime = (timer - startTime) * 1000
        movingFrmAvg = movingFrmAvg * 0.92 + totalTime * 0.08
        stallTime = (1000.0 / FPS_TARGET) - movingFrmAvg
        if stallTime > 0 then sleep(stallTime)
    loop 
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
end sub

sub GameSpace.vibrateScreen()
    vibcount = 3
end sub

sub GameSpace.pow(x as double, y as double, r as double)
    dim as double xscan, yscan
    dim as double xd, yd
    x /= 16
    y /= 16
    for yscan = -r to r
        for xscan = -r to r
            if xscan*xscan + yscan*yscan <= r*r then
                xd = xscan + x
                yd = yscan + y
                lvlData.resetBlock xd, yd, 1
                lvlData.resetBlock xd, yd, 2
                lvlData.resetBlock xd, yd, 3
                lvlData.setCollision xd, yd, 0
            end if
        next xscan
    next yscan
    world.setBlockData(lvlData.getCollisionLayerData(),_
                       lvlData.getWidth(), lvlData.getHeight(),_
                       16.0)
end sub

sub GameSpace.step_draw()
    dim as integer x, y, block
    dim as integer tl_x, tl_y
    dim as integer br_x, br_y
    dim as integer shake
    
    camera = spy.body.p * 0.1 + camera * 0.9
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
        
    cls
  
    window screen (camera.x() - SCRX * 0.5, camera.y() - SCRY * 0.5)-_
                  (camera.x() + SCRX * 0.5, camera.y() + SCRY * 0.5)
                  
    line scnbuff, (camera.x() - SCRX * 0.5, camera.y() - SCRY * 0.5)-_
                  (camera.x() + SCRX * 0.5, camera.y() + SCRY * 0.5), 0, BF
    

    
    
      
    
    if vibcount > 0 then
        shake = ((vibcount mod 2) * 2 - 1) * 4
    else
        shake = 0
    end if
      
 
    lvlData.drawLayers(scnbuff, BACKGROUND, camera.x(), camera.y(), Vector2D(0, 0))
    if lvlData.usesSnow() = 1 then backgroundSnow.drawFlakes(scnbuff, camera)
    lvlData.drawLayers(scnbuff, ACTIVE, camera.x(), camera.y(), Vector2D(0, shake))
    graphicFX.drawEffects(scnbuff, camera, ACTIVE)
    spy.drawPlayer(scnbuff)
    projectiles.draw_collection(scnbuff)
    effects.draw_effects(scnbuff)

    lvlData.drawLayers(scnbuff, FOREGROUND, camera.x(), camera.y(), Vector2D(0, shake))

    if lvlData.usesSnow() = 1 then foregroundSnow.drawFlakes(scnbuff, camera)
    
    scale2sync scnbuff
end sub
    


sub GameSpace.step_process()
    dim as integer i, dire, jump, ups, fire
    
    
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
    
    vibcount -= 1
    
 
    spy.processControls(dire, jump, ups, fire, keypress(SC_LSHIFT), 0.033)
    if lvlData.usesSnow() = 1 then 
        backgroundSnow.stepFlakes(camera, 0.033)
        foregroundSnow.stepFlakes(camera, 0.033)
    end if
    projectiles.proc_collection(0.033)
    graphicFX.processFrame(camera)
 
    effects.proc_effects(0.033)
    
    print spy.body.p
    
    #ifdef DEBUG
    	world.step_time(0.033)
    #else
		for i = 1 to 3
			world.step_time(0.011)
		next i
	#endif
   
end sub
sub GameSpace.centerCamera(c as Vector2D)  
	camera = c
end sub
sub GameSpace.switchRegions(ls as LevelSwitch_t)
	projectiles.flush()
	lvlData.load(ls.fileName)
    world.setBlockData(lvlData.getCollisionLayerData(),_
                       lvlData.getWidth(), lvlData.getHeight(),_
                       16.0)
end sub        
        
