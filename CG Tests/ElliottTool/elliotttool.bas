#include "fbpng.bi"
#include "fbgfx.bi"
#include "utility.bi"
#include "zimage.bi"
#include "vbcompat.bi"

using fb

#define SCRX 1024
#define SCRY 768
#define BACK_COLOR &h101010
#define BORDER_COLOR &h7f7f7f
#define DARK_COLOR &h070707
#define WINDOW_W 921
#define WINDOW_H 738

#define MOVING_WINDOW &h00000001
#define MOVING_R &h00000002
#define MOVING_G &h00000004
#define MOVING_B &h00000008
#define MOVING_AR &h00000010
#define MOVING_AG &h00000020
#define MOVING_AB &h00000040
#define MOVING_SPRITE &h00000080
 
function loadWhatever(filename as string, byref img as integer ptr, byref w as integer, byref h as integer) as integer
    dim as integer f
    if fileexists(filename+".bmp") then
        f = freefile
        open filename+".bmp" for binary access read as #f
        get #f, 19, w
        get #f, 23, h
        close #f
        img = imagecreate(w, h)
        if bload(filename+".bmp", img) then return 1
    elseif fileexists(filename+".png") then
        img = png_load(filename+".png")
        if img = 0 then return 1
        imageinfo img, w, h
    else
        return 1
    end if
    return 0
end function

dim as integer lrgV, upheight, leftheight, rightHeight, downHeight, omb
dim as integer xdif, ydif, offX, offY, xshift, yshift, omouseX, omouseY
dim as double scale
dim as Vector2D lp
dim as integer shouldExit, x, y, isMoving, sposX, sposY, oneClick
dim as double dx, dy, rc, rs, r
dim as integer mouseX, mouseY, mouseB, col, imgW, imgH, mb
dim as integer rSlider, gSlider, bSlider, success, curHeight, curBound
dim as integer arSlider, agSlider, abSlider
dim as integer ptr workArea, backImage, dataX, dataY, renderScale
dim as integer ptr diffuse_map, height_map, specular_map, boundary_map, surface_map
dim as PointLight light, lightCopy
dim as zimage diffBase, specBase, composite
dim as string filename
dim as EVENT e


screenres SCRX, SCRY, 32,2 ,GFX_NO_FRAME
screenset 1,0
success = 0

if command(1) = "" then success += 1


filename = command(1)
filename = left(filename, instr(filename, ".") - 1)

success += loadWhatever(filename, diffuse_map, imgW, imgH)
success += loadWhatever(filename+"_height", height_map, imgW, imgH)
success += loadWhatever(filename+"_specular", specular_map, imgW, imgH)
success += loadWhatever(filename+"_boundary", boundary_map, imgW, imgH)


sleep 10
flip

if success = 0 then
    
    dataX = allocate(sizeof(integer)*imgW*imgH)
    dataY = allocate(sizeof(integer)*imgW*imgH)
    
    lrgV = 0
    for y = 0 to imgH-1
        for x = 0 to imgW-1
            curBound = point(x, y, boundary_map)
            curHeight = point(x, y, height_map) and &hff
            if y = 0 then
                upHeight = curHeight
            else
                if (curBound = point(x, y-1, boundary_map)) andAlso _
                   (point(x, y-1, diffuse_map) <> &hffff00ff) then
                    upHeight = point(x, y-1, height_map) and &hff
                else
                    upHeight = curHeight
                end if
            end if
            if y = imgH-1 then
                downHeight = curHeight
            else
                if (curBound = point(x, y+1, boundary_map)) andAlso _
                   (point(x, y+1, diffuse_map) <> &hffff00ff) then
                    downHeight = point(x, y+1, height_map) and &hff
                else
                    downHeight = curHeight
                end if
            end if
            if x = 0 then
                leftHeight = curHeight
            else
                if (curBound = point(x-1, y, boundary_map)) andAlso _
                   (point(x-1, y, diffuse_map) <> &hffff00ff) then
                    leftHeight = point(x-1, y, height_map) and &hff
                else
                    leftHeight = curHeight
                end if
            end if
            if x = imgW-1 then
                rightHeight = curHeight
            else
                if (curBound = point(x+1, y, boundary_map)) andAlso _
                   (point(x+1, y, diffuse_map) <> &hffff00ff) then
                    rightHeight = point(x+1, y, height_map) and &hff
                else
                    rightHeight = curHeight
                end if
            end if        
            
            xdif = rightHeight - leftHeight
            ydif = downHeight - upHeight
            
            dataX[y*imgW+x] = -xdif
            dataY[y*imgW+x] = -ydif
            if abs(xdif) > lrgV then lrgV = abs(xdif)
            if abs(ydif) > lrgV then lrgV = abs(ydif)
     
        next x
    next y
    
    scale = (128.0 / cdbl(lrgV))
    surface_map = imagecreate(imgW, imgH)
    for y = 0 to imgH-1
        for x = 0 to imgW-1
            xdif = dataX[y*imgW+x] * scale
            ydif = dataY[y*imgW+x] * scale
            if point(x, y, diffuse_map) <> &hffff00ff then
                pset surface_map, (x, y), (rgb(point(x, y, specular_map), ydif + 128, xdif + 128) and &hFFffffff)
            else
                pset surface_map, (x, y), &hffff00ff             
            end if
        next x
    next y
    
    deallocate(dataX)
    deallocate(dataY)
    
    png_save(filename+"_surface.png",surface_map)
    
    imagedestroy(height_map)
    imagedestroy(specular_map)
    imagedestroy(boundary_map)
    
    renderScale = imagecreate(imgW, imgH)

    composite.create(imgW, imgH, diffuse_map, surface_map)
    
    rSlider = 255
    gSlider = 255
    bSlider = 255
    arSlider = 64
    agSlider = 64
    abSlider = 64
    
    backImage = png_load("back.png")
    
    lightCopy.diffuse_fbimg = imagecreate(512, 512)
    lightCopy.specular_fbimg = imagecreate(512, 512)
    light.diffuse_fbimg = imagecreate(512, 512)
    light.specular_fbimg = imagecreate(512, 512)
    workArea = imagecreate(WINDOW_W, WINDOW_H)
    
    for y = 0 to 511
        for x = 0 to 511
            dx = x - 256
            dy = y - 256
            r = 255 - sqr(dx*dx + dy*dy)
            if r < 0 then 
                rc = 0
                rs = 0
            else
                rc = ((r / 255.0)^2)
                rs = (((r / 255.0)^20) * 6)
                if rs > 1 then rs = 1
            end if
            pset light.diffuse_fbimg, (x, y), rgb(255 * rc, 255 * rc, 255 * rc)
            pset light.specular_fbimg, (x, y), rgb(255 * rs, 255 * rs, 255 * rs)
        next x
    next y
    
    diffBase.create(512, 512, light.diffuse_fbimg)
    specBase.create(512, 512, light.specular_fbimg)
    
    do
        omb = mb
        oneClick = 0
        omouseX = mouseX
        omouseY = mouseY
        getmouse mouseX, mouseY,,mb
        
        If (ScreenEvent(@e)) Then
            Select Case e.type
            Case EVENT_MOUSE_BUTTON_PRESS
                mouseB = -1
            Case EVENT_MOUSE_BUTTON_RELEASE
                mouseB = 0
                isMoving = 0
            Case EVENT_MOUSE_MOVE
                If mouseB Then
                    ScreenControl GET_WINDOW_POS, x, y
                    if isMoving = 0 then
                        if (mouseX >= 0) andALso (mouseX <= (SCRX-1)) andAlso (mouseY >= 0) andALso (mouseY <= 24) then
                            isMoving = MOVING_WINDOW
                        end if
                    end if
                    if isMoving and MOVING_WINDOW then ScreenControl SET_WINDOW_POS, x + e.dx, y + e.dy
                End If
            End Select
        End If
    
        if (omb = 0) andALso (mb > 0) then oneClick = -1
        if mb = 0 then isMoving = 0
    
        shouldExit = 0
        if multikey(1) then shouldExit = 1
        line (0,0)-(SCRX-1,SCRY-1),BACK_COLOR,BF
        line (0,0)-(SCRX-1,SCRY-1),BORDER_COLOR,B
        line (0,24)-(SCRX-1,24), BORDER_COLOR
        draw string (5,9), "ELLIOTT'S HEIGHTMAP TOOL", BORDER_COLOR
        
        if isMoving orElse (mouseX < SCRX-23) orElse (mouseX > SCRX-3) orElse (mouseY < 2) orElse (mouseY > 22) then
            line (SCRX-23, 2)-(SCRX-3, 22), BORDER_COLOR, BF
            draw string (SCRX-16,9), "X", BACK_COLOR
        else
            line (SCRX-23, 2)-(SCRX-3, 22), DARK_COLOR, BF
            draw string (SCRX-16,9), "X", BORDER_COLOR     
            line (SCRX-23, 2)-(SCRX-3, 22), BORDER_COLOR, B
            if mouseB then shouldExit = 1
        end if
    
        if oneClick then
            sposX = SCRX - 75
            sposY = 295 - rSlider 
            if sqr((sposX - mouseX)^2 + (sposY - mouseY)^2) <= 8 then
                isMoving = MOVING_R
            end if
            sposX = SCRX - 50
            sposY = 295 - gSlider 
            if sqr((sposX - mouseX)^2 + (sposY - mouseY)^2) <= 8 then
                isMoving = MOVING_G
            end if
            sposX = SCRX - 25
            sposY = 295 - bSlider 
            if sqr((sposX - mouseX)^2 + (sposY - mouseY)^2) <= 8 then
                isMoving = MOVING_B
            end if
            sposX = SCRX - 75
            sposY = 675 - arSlider 
            if sqr((sposX - mouseX)^2 + (sposY - mouseY)^2) <= 8 then
                isMoving = MOVING_AR
            end if
            sposX = SCRX - 50
            sposY = 675 - agSlider 
            if sqr((sposX - mouseX)^2 + (sposY - mouseY)^2) <= 8 then
                isMoving = MOVING_AG
            end if
            sposX = SCRX - 25
            sposY = 675 - abSlider 
            if sqr((sposX - mouseX)^2 + (sposY - mouseY)^2) <= 8 then
                isMoving = MOVING_AB
            end if            
        end if
        if isMoving and MOVING_R then
            rSlider = 295 - mouseY
            if rSlider < 0 then rSlider = 0
            if rSlider > 255 then rSlider = 255
        end if
        if isMoving and MOVING_G then
            gSlider = 295 - mouseY
            if gSlider < 0 then gSlider = 0
            if gSlider > 255 then gSlider = 255
        end if
        if isMoving and MOVING_B then
            bSlider = 295 - mouseY
            if bSlider < 0 then bSlider = 0
            if bSlider > 255 then bSlider = 255
        end if
        if isMoving and MOVING_AR then
            arSlider = 675 - mouseY
            if arSlider < 0 then arSlider = 0
            if arSlider > 255 then arSlider = 255
        end if
        if isMoving and MOVING_AG then
            agSlider = 675 - mouseY
            if agSlider < 0 then agSlider = 0
            if agSlider > 255 then agSlider = 255
        end if
        if isMoving and MOVING_AB then
            abSlider = 675 - mouseY
            if abSlider < 0 then abSlider = 0
            if abSlider > 255 then abSlider = 255
        end if
        
        line (2, 26)-(2 + WINDOW_W+1, 26 + WINDOW_H+1), BORDER_COLOR, B
        line (SCRX - 75, 40)-(SCRX - 75, 295), BORDER_COLOR
        line (SCRX - 50, 40)-(SCRX - 50, 295), BORDER_COLOR
        line (SCRX - 25, 40)-(SCRX - 25, 295), BORDER_COLOR
        
        circle (SCRX - 75, 295 - rSlider), 8, BACK_COLOR,,,,F
        circle (SCRX - 75, 295 - rSlider), 8, BORDER_COLOR
        draw string (SCRX-78,292 - rSlider), "R", BORDER_COLOR 
        
        circle (SCRX - 50, 295 - gSlider), 8, BACK_COLOR,,,,F
        circle (SCRX - 50, 295 - gSlider), 8, BORDER_COLOR
        draw string (SCRX-53,292 - gSlider), "G", BORDER_COLOR 
        
        circle (SCRX - 25, 295 - bSlider), 8, BACK_COLOR,,,,F
        circle (SCRX - 25, 295 - bSlider), 8, BORDER_COLOR
        draw string (SCRX-28,292 - bSlider), "B", BORDER_COLOR 
        
        draw string (SCRX-78,312), "R = " + str(rSlider), BORDER_COLOR 
        draw string (SCRX-78,321), "G = " + str(gSlider), BORDER_COLOR 
        draw string (SCRX-78,330), "B = " + str(bSlider), BORDER_COLOR 
        
        line (SCRX-97, 350)-(SCRX - 4, 366), rgb(rSlider, gSlider, bSlider), BF
        line (SCRX-97, 350)-(SCRX - 4, 366), BORDER_COLOR, B
        
        
        
        line (SCRX - 75, 420)-(SCRX - 75, 675), BORDER_COLOR
        line (SCRX - 50, 420)-(SCRX - 50, 675), BORDER_COLOR
        line (SCRX - 25, 420)-(SCRX - 25, 675), BORDER_COLOR
        
        circle (SCRX - 75, 675 - arSlider), 8, BACK_COLOR,,,,F
        circle (SCRX - 75, 675 - arSlider), 8, BORDER_COLOR
        draw string (SCRX-78,672 - arSlider), "R", BORDER_COLOR 
        
        circle (SCRX - 50, 675 - agSlider), 8, BACK_COLOR,,,,F
        circle (SCRX - 50, 675 - agSlider), 8, BORDER_COLOR
        draw string (SCRX-53,672 - agSlider), "G", BORDER_COLOR 
        
        circle (SCRX - 25, 675 - abSlider), 8, BACK_COLOR,,,,F
        circle (SCRX - 25, 675 - abSlider), 8, BORDER_COLOR
        draw string (SCRX-28,672 - abSlider), "B", BORDER_COLOR 
        
        draw string (SCRX-78,692), "R = " + str(arSlider), BORDER_COLOR 
        draw string (SCRX-78,701), "G = " + str(agSlider), BORDER_COLOR 
        draw string (SCRX-78,710), "B = " + str(abSlider), BORDER_COLOR 
        
        line (SCRX-97, 730)-(SCRX - 4, 746), rgb(arSlider, agSlider, abSlider), BF
        line (SCRX-97, 730)-(SCRX - 4, 746), BORDER_COLOR, B        
        
        
        col = (bslider and &hff) or ((gslider and &hff) shl 8) or ((rslider and &hff) shl 16)
        diffBase.putTRANS_0xLight(lightCopy.diffuse_fbimg, 0, 0, 0, 0, 511, 511, col)
        specBase.putTRANS_0xLight(lightCopy.specular_fbimg, 0, 0, 0, 0, 511, 511, col)
        lightCopy.w = 512
        lightCopy.h = 512

        for y = 0 to int(WINDOW_H / 48.0)+1.0
            for x = 0 to int(WINDOW_W / 48.0)+1.0
                put workArea, (x*48, y*48), backImage, PSET
            next x
        next y
        
        if (mouseX >= 2) andAlso (mouseX <= (2+WINDOW_W+1)) andAlso _
           (mouseY >= 26) andAlso (mouseY <= (26+WINDOW_H+1)) then
            lp.setX(mouseX - 2)
            lp.setY(mouseY - 26)  
            if isMoving = 0 andAlso oneClick then
                isMoving = MOVING_SPRITE
            end if
        end if
        if isMoving = MOVING_SPRITE then
            xshift += (mouseX - omouseX)
            yshift += (mouseY - omouseY)     
        end if
        lightCopy.x = (lp.x - (2 + WINDOW_W*0.5) - xshift)*0.5 + 32
        lightCopy.y = (lp.y - (26 + WINDOW_H*0.5) - yshift)*0.5 + 32
    
        composite.putTRANS_1xLight(renderScale, 0,0, 0,0, imgW-1, imgH-1, rgb(arslider, agslider, abslider), lightCopy)


        for y = 0 to imgH-1
            for x = 0 to imgW-1
                col = point(x, y, renderScale)
                offX = WINDOW_W*0.5 - imgW + x*2 + xshift
                offY = WINDOW_H*0.5 - imgH + y*2 + yshift
                if col <> &hffff00ff then
                    pset workArea, (offX  , offY  ), col
                    pset workArea, (offX+1, offY  ), col
                    pset workArea, (offX  , offY+1), col
                    pset workArea, (offX+1, offY+1), col
                end if
            next x
        next y
        
        put (3, 27), workArea, PSET
    
        sleep 16
        flip
    loop until shouldExit 
end if
