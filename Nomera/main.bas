
#include "constants.bi"
#include "gamespace.bi"
#include "effects3d.bi"
#include "zimage.bi"
#include "utility.bi"
#include "fbpng.bi"
#include "vector2d.bi"
#include "pointlight.bi"

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
        dim as integer i, fps, f, h, frameCount, treeT, alphaT
        dim as single scale
        dim as double groundScroll, animate, treeX, treeY, treeZ
        dim as zimage logo, baseTexture, mist
        dim as zimage mountain(0 to 2), back
        dim as zimage trees, menulogo
        dim as PointLight logoLight
        dim as Vector2D treePos(0 to MAX_TREES-1)
        dim as integer treeType(0 to MAX_TREES-1)
        randomize timer

        mist.load("mist.png")
        baseTexture.load("base.png")
        mountain(0).load("menuback0.png")
        mountain(1).load("menuback1.png")
        mountain(2).load("menuback2.png")
        back.load("menubacksun.png")
        trees.load("menutrees.png")
        menulogo.load("menulogo.png")
        
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
        
        t = timer
        frameCount = 0
        do

            
            animate = sin(frameCount * 0.004)

            groundScroll = animate * 30
            
            
            for i = 0 to 4
                scrollPercent(i) = (scrollPercent(i) + scrollAdd(i) * (1+-animate*0.5)) 
                if scrollPercent(i) >= SCRX then scrollPercent(i) -= SCRX
            next i   
            
            line scnbuff, (0,0)-(SCRX-1,SCRY-1), 0, BF
            

            put scnbuff, (0,0), back.getData(), PSET
            for i = 0 to 2
                scale = 1+(1-animate)*0.03*(1+i*0.2)
                rotozoom_alpha2(cast(FB.IMAGE ptr, scnbuff), cast(FB.IMAGE ptr, mountain(2 - i).getData()), 320, 165, 0, scale, scale, ,255)
            next i
            
            drawMode7Ground(scnbuff, baseTexture.getData(),0,groundScroll,, 100)
            
            for i = 0 to MAX_TREES-1
                treeZ = treePos(i).y + animate*65
                treeX = SCRX*0.5 + treePos(i).x * (256 / treeZ)
                treeY = SCRY*0.5 + 200 * (256 / treeZ)
                put scnbuff, (treeX-20, treeY-31), trees.getData(), (treeType(i)*41,0)-(treeType(i)*41+40, 110), ALPHA
            next i
            
            
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
            
            
            logoLight.x = cos(frameCount * 0.005) * 200 + SCRX*0.5
            logoLight.y = sin(frameCount * 0.005) * 100 + 110
            
            window screen (0,0)-(640,480)
            ''''''''''''''''''''''' FIGURE OUT WHY COORDS NO GOOD '''''''''''''''''''''''
            menulogo.putTRANS_1xLight(scnbuff, SCRX*0.5 - 200, 10, 0,0,397,198, &hA0A0A0, logoLight)
            '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
            window screen
            
            
            'draw string scnbuff, (0,0), str(fps), 0
        
            groundScroll += 1
        
        
            sync()
            f += 1
            frameCount += 1
            if timer - t >= 1 then
                fps = f
                f = 0
                t = timer
            end if
        loop until inkey$ <> ""
        
        baseTexture.flush()
        mist.flush()
        mountain(0).flush()
        mountain(1).flush()
        mountain(2).flush()
        back.flush()
        trees.flush()
        menulogo.flush()
        png_destroy(logoLight.diffuse_fbimg)
        png_destroy(logoLight.specular_fbimg)

    #endif
#endif

Dim as GameSpace gameNomero


gameNomero.go


end
