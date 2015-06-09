
#include "constants.bi"
#include "gamespace.bi"
#include "effects3d.bi"
#include "zimage.bi"
#include "utility.bi"
#include "fbpng.bi"
#include "vector2d.bi"
#include "pointlight.bi"
#include "fbgfx.bi"

using fb

#define MAX_TREES 50

#ifdef SCALE_2X
	screenres SCRX*2,SCRY*2,32
#else
	screenres SCRX, SCRY, 32
#endif

#macro sync()
    #ifdef SCALE_2X
        screenlock	
            scale2sync scnbuff
        screenunlock
    #else
        put (0,0), scnbuff, PSET
    #endif
#endmacro
randomize timer
FSOUND_Init(44100, 16, 0)

#ifdef INTRO
	#ifndef DEBUG 
		dim as uinteger ptr scnbuff
        dim as double scrollPercent(0 to 4)
        dim as double scrollAdd(0 to 4), t
        dim as integer i, fps, f, h, frameCount, treeT, alphaT, selectedOption, quitMenu
        dim as integer menuMusic_channel, alphaVal, letterW, letterH, dire, lastDire, pressSelect
        dim as single scale
        dim as double groundScroll, animate, treeX, treeY, treeZ, titlePosition
        dim as zimage logo, baseTexture, mist
        dim as zimage mountain(0 to 2), back
        dim as zimage trees, menulogo
        dim as zimage lensflare
        dim as zimage letters
        dim as zimage sunflare
        dim as PointLight logoLight
        dim as Vector2D treePos(0 to MAX_TREES-1)
        dim as integer treeType(0 to MAX_TREES-1)
        dim as integer textOffsetX(0 to 2), textRedX(0 to 2)
        dim as integer ptr menuMusic, menuSound(0 to 2)
        randomize timer

        mist.load("mist.png")
        baseTexture.load("base.png")
        mountain(0).load("menuback0.png")
        mountain(1).load("menuback1.png")
        mountain(2).load("menuback2.png")
        back.load("menubacksun.png")
        trees.load("menutrees.png")
        menulogo.load("menulogo.png")
        lensflare.load("lensflare.png")
        sunflare.load("sunflare.png")
        letters.load("menuletters.png")
        
        menuSound(0) = FSOUND_SAMPLE_Load(FSOUND_FREE,"menuSwitch.wav",0,0,0)
        menuSound(1) = FSOUND_SAMPLE_Load(FSOUND_FREE,"menuSelect.wav",0,0,0)
        menuSound(2) = FSOUND_SAMPLE_Load(FSOUND_FREE,"menuBack.wav",0,0,0)
        
        
        logoLight.diffuse_fbimg = png_load("Lights\Golden_diffuse.png")
        logoLight.specular_fbimg = png_load("Lights\Golden_specular.png")
        logoLight.w = 512
        logoLight.h = 512

        
        
		scnbuff = imagecreate(SCRX, SCRY)

        line scnbuff, (0,0)-(SCRX-1,SCRY-1), 0, BF
        
        for i = 0 to 4
            scrollAdd(i) = ((i + 1) + ((rnd * 2) - 1) * 0.3)^2.5 * 0.008
            scrollPercent(i) = rnd * SCRX
        next i
        groundScroll = 0
        selectedOption = 0
        
        menuMusic = FSOUND_Stream_Open("menu.ogg", FSOUND_LOOP_NORMAL, 0, 0) 
        FSOUND_Stream_Play menuMusic_channel, menuMusic
        FSOUND_SetVolumeAbsolute(menuMusic_channel, 128)
        
        titlePosition = -100
        
        randomize 4
        for i = 0 to MAX_TREES-1
            treePos(i).ys = 176 + (rnd^2 * 3000)
            treePos(i).xs = ((rnd * 2) - 1) * treePos(i).ys * (350 / 256)
            treeZ = treePos(i).ys
            if treeZ > 1000 then
                treeT = 2
            elseif treeZ > 500 then
                treeT = 1
            else
                treeT = 0
            end if
            treeType(i) = treeT
        next i
        
        i = 0
        while i < MAX_TREES
            if treePos(max(i-1, 0)).y >= treePos(i).y then
                i += 1
            else
                swap treePos(i - 1), treePos(i)
                swap treeType(i - 1), treeType(i)
                i -= 1
            end if
        wend
        
        for i = 0 to 2
            textRedX(i) = 0
        next i
        
        t = timer
        lastDire = 0
        frameCount = 0
        do

            
            animate = sin((frameCount * 0.003) + 3)

            groundScroll = animate * 30
            
            
            for i = 0 to 4
                scrollPercent(i) = (scrollPercent(i) + scrollAdd(i) * (1+-animate*0.5)) 
                if scrollPercent(i) >= SCRX then scrollPercent(i) -= SCRX
            next i   
            
            dire = 0
            if multikey(SC_UP) then dire -= 1
            if multikey(SC_DOWN) then dire += 1
            pressSelect = 0 
            if multikey(SC_Z) then 
                pressSelect = 1
            end if
            
            if lastDire = 0 andAlso dire <> 0 then
            	FSOUND_SetLoopMode(FSOUND_PlaySound(FSOUND_FREE, menuSound(0)), FSOUND_LOOP_OFF)
                selectedOption += dire
                if selectedOption > 2 then 
                    selectedOption -= 3
                elseif selectedOption < 0 then
                    selectedOption += 3
                end if
            end if
            
            if pressSelect then 
                if selectedOption <> 1 then quitMenu = 1
            end if
            
            line scnbuff, (0,0)-(SCRX-1,SCRY-1), 0, BF
            

            put scnbuff, (0,0), back.getData(), PSET
            for i = 0 to 2
                scale = 1+(1-animate)*0.008*(1+i*0.3)
                rotozoom_alpha2(cast(FB.IMAGE ptr, scnbuff), cast(FB.IMAGE ptr, mountain(2 - i).getData()), 320, 165, 0, scale, scale, ,255)
            next i
            
            drawMode7Ground(scnbuff, baseTexture.getData(),0,groundScroll,, 100)
            
            window screen (0,0)-(640,480)
            for i = 0 to MAX_TREES-1
                treeZ = treePos(i).y + animate*65
                treeX = SCRX*0.5 + treePos(i).x * (256 / treeZ)
                treeY = SCRY*0.5 + 200 * (256 / treeZ)
                trees.putGLOW(scnbuff, treeX-20, treeY-31,treeType(i)*41,0,treeType(i)*41+40, 110, &hffffffff)
            next i
            window screen
           
            
            for i = 0 to 4
                h = 250+i^2*(10 - (1+animate)*2)
                scale = (0.4 + i*0.1)
                alphaT = 255 - i*50
                if scrollPercent(i) <> 0 then
                    rotozoom_alpha2(cast(FB.IMAGE ptr, scnbuff), cast(FB.IMAGE ptr, mist.getData()), scrollPercent(i) - SCRX*0.5 + 1, h, 0, 1, scale, ,alphaT)
                    rotozoom_alpha2(cast(FB.IMAGE ptr, scnbuff), cast(FB.IMAGE ptr, mist.getData()), 321+scrollPercent(i), h, 0, 1, scale, ,alphaT)
                else
                    rotozoom_alpha2(cast(FB.IMAGE ptr, scnbuff), cast(FB.IMAGE ptr, mist.getData()), 321+scrollPercent(i), h, 0, 1, scale, ,alphaT) 
                end if
            next i
            
            
            logoLight.x = cos(frameCount * 0.003 + 3) * 200 + SCRX*0.5
            logoLight.y = sin(frameCount * 0.003 + 3) * 100 + 110
            
            window screen (0,0)-(640,480)
            
            menulogo.putTRANS_1xLight(scnbuff, SCRX*0.5 - 200, 10+titlePosition, 0,0,397,198, &h404040, logoLight)
            alphaVal = int((((1 + -animate)*0.5)^(0.4) * 250) * rnd^(0.1)) shl 24
            sunflare.putGLOW(scnbuff, SCRX*0.5 - 69,-11+titlePosition,0,0,134,108, &hffffff or alphaVal)
            alphaVal = int(((1 + -animate) * 90) * rnd^(0.1)) shl 24
            for i = 0 to 4
                lensflare.putGLOW(scnbuff, 270+i*35, i*35-10+titlePosition,i*127,0,i*127+126, 126, &hffffff or alphaVal)
            next i
            
            for i = 0 to 2
                select case i
                case 0
                    letterW = 119
                case 1
                    letterW = 154
                case 2
                    letterW = 84
                end select
                letters.putGLOW(scnbuff, (SCRX-letterW)*0.5+titlePosition*3+textOffsetX(i), 260+i*60, 0, i*2*39, letterW-1, i*2*39+38, &hffA0A0A0)
                letters.putGLOW(scnbuff, (SCRX-letterW)*0.5+titlePosition*3+textOffsetX(i), 260+i*60, 0, (i + 0.5)*2*39, letterW-1, (i + 0.5)*2*39+38, &h00ffffff or (textRedX(i) shl 24))

                if selectedOption = i then
                    textOffsetX(i) += ((30 - textOffsetX(i))^0.2)*0.3
                    textRedX(i) += 5
                    if textRedX(i) > 255 then textRedX(i) = 255
                    if textOffsetX(i) > 30 then textOffsetX(i) = 30
                else
                    textOffsetX(i) -= 1
                    if textOffsetX(i) < 0 then textOffsetX(i) = 0
                    textRedX(i) -= 4
                    if textRedX(i) < 0 then textRedX(i) = 0
                end if
            next i
            
            window screen
            
            line scnbuff, (0,0)-(SCRX-1,SCRY-1),0, B
            'draw string scnbuff, (0,0), str(fps), 0            
            draw string scnbuff, (550, 471), "Build V1.0b", 0
        
            groundScroll += 1
            
            titlePosition *= 0.90
        
            sync()
            f += 1
            frameCount += 1
            if timer - t >= 1 then
                fps = f
                f = 0
                t = timer
            end if
            lastDire = dire
        loop until quitMenu
        
        baseTexture.flush()
        mist.flush()
        mountain(0).flush()
        mountain(1).flush()
        mountain(2).flush()
        back.flush()
        trees.flush()
        menulogo.flush()
        lensflare.flush()
        sunflare.flush()
        letters.flush()
        png_destroy(logoLight.diffuse_fbimg)
        png_destroy(logoLight.specular_fbimg)
        FSOUND_Stream_Stop  menuMusic
        FSOUND_Stream_Close menuMusic
        'for i = 0 to 2
        '    FSOUND_Sample_Upload menuSound(i)
        'next i
    #endif
#endif




if selectedOption = 0 then

    Dim as GameSpace gameNomera


    gameNomera.go
    
end if


end
