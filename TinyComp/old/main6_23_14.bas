#include "vector2d.bi"
#include "tinyspace.bi"
#include "level.bi"
#include "fmod.bi"
#include "utility.bi"

#ifndef DEBUG
    #define SCRX 640
    #define SCRY 480
#else
    #define SCRX 1366
    #define SCRY 768
    #include "printlog.bi"
    kill "debug.txt"
#endif

#define SFX_NUM 10

screenres SCRX,SCRY,32,2
screenset 1,0 

dim as TinySpace world
dim as TinyBody  bod
dim as Level     lev
dim as Vector2D  cameraPos
dim as integer ptr gfx = imagecreate(336, 16)
dim as integer ptr back = imagecreate(940, 659)
dim as integer ptr plyr = imagecreate(288, 256)

dim as integer curFrame, frmDelay, frmCntdown, doJump
dim as integer animState, facing, framesNotGrounded
dim as integer shouldToggle, sleepState

dim as integer jumpFrame

dim as integer x, y, block, jumpTimer = 0, speed, mx, my
dim as integer oldJumpState, isJumping
dim as double curForce, curJump, frictionForce

dim as uinteger ptr music
dim shared as uinteger ptr sample(SFX_NUM-1)

FSOUND_Init(44100, SFX_NUM, 0)
music = FSOUND_Stream_Open("TestTheme.ogg", FSOUND_LOOP_NORMAL, 0, 0 ) 
sample(0) = FSOUND_SAMPLE_Load(FSOUND_FREE,"Step.wav",1,0,0)
sample(1) = FSOUND_SAMPLE_Load(FSOUND_FREE,"Jump.wav",1,0,0)
sample(2) = FSOUND_SAMPLE_Load(FSOUND_FREE,"Land.wav",1,0,0)
#ifndef DEBUG
    FSOUND_Stream_Play 1, music
#endif

sleepState = 0
shouldToggle = 0

bload "Corners.bmp", gfx
bload "back.bmp", back
bload "mrspy.bmp", plyr

lev.load(command(1))
world.setBlockData(lev.getCollisionLayerData(),_
                   lev.getWidth(), lev.getHeight,_
                   16.0)
bod = TinyBody(Vector2D(22.832, 733.3732), 18, 5.0)
bod.friction = 0.5
bod.elasticity = 0
cameraPos = bod.p
world.addBody(@bod)

curFrame = 0
frmDelay = 1
animState = 0
facing = 1
doJump = 0

do
    cls
    
    
    
    
    
    bod.f = Vector2D(curForce,curJump)

        
    cameraPos = bod.p * 0.1 + cameraPos * 0.9
    if cameraPos.x() < SCRX*0.5 then 
        cameraPos.setX(SCRX*0.5)
    elseif cameraPos.x() >= lev.getWidth()*16 - SCRX*0.5 then
        cameraPos.setX(lev.getWidth()*16 - SCRX*0.5)
    end if
    if cameraPos.y() < SCRY*0.5 then 
        cameraPos.setY(SCRY*0.5)
    elseif cameraPos.y() >= lev.getHeight()*16 - SCRY*0.5 then
        cameraPos.setY(lev.getHeight()*16 - SCRY*0.5)
    end if  
    
    window screen (cameraPos.x() - SCRX * 0.5, cameraPos.y() - SCRY * 0.5)-_
                  (cameraPos.x() + SCRX * 0.5, cameraPos.y() + SCRY * 0.5)

    #ifndef DEBUG
        put (cameraPos.x() * 0.95 - 400 , cameraPos.y() * 0.95 - 300), back, PSET
    
        if isJumping = 0 then
            put (bod.p.x() - 16 + (facing * 2 - 1) * 4, bod.p.y() - 46), plyr, (curFrame * 32, facing*64)-(curFrame * 32 + 31, facing*64 + 63), TRANS
        else
            put (bod.p.x() - 16 + (facing * 2 - 1) * 4, bod.p.y() - 46 + min(jumpFrame, 4) * 6), plyr, (jumpFrame * 32, 128+facing*64)-(jumpFrame * 32 + 31, 128+facing*64 + 63), TRANS
        end if
    #else
        circle (bod.p.x(), bod.p.y()), bod.r, &hf01010,,,bod.r_rat,F
    #endif

    for y = 0 to lev.getHeight() - 1
        for x = 0 to lev.getWidth() - 1
            block = lev.getBlock(x, y, 0)
            if block > 0 then
                put (x*16, y*16), gfx, ((block-1)*16,0)-((block*16)-1,15), TRANS
            end if
        next x
    next y
    #ifdef DEBUG
        print iif(sleepState = 1, "FRAME ADVANCE", "PROCEED AT 30FPS")
    #endif
    world.step_time 0.033
    #ifndef DEBUG
        print "press ESC to quit, X to jump, arrows keys to move"
        print bod.p
    #endif
    flip
    #ifndef DEBUG
        sleep 30
    #else
        if sleepState = 1 then
            sleep
        else
            sleep 30
        end if
    #endif
    doJump = 0
loop until multikey(1)

imagedestroy gfx
imagedestroy back
imagedestroy plyr

end
