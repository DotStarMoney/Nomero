#include "level.bi"
#include "utility.bi"
#include "seqfile.bi"
#include "debug.bi"



dim as RegionData_t ptr Level.regionPortals = 0
dim as integer ptr Level.falloutTex = 0

function blendFallout(byval src as uinteger, byval dest As uinteger, _
                      byval param as any ptr) As uInteger
    dim as integer r, g, b
    if src = &hff000000 orElse dest = &hffff00ff then
        return &hffff00ff
    else
        r = (((src shr 16) and &hff) * (((dest shr 16) and &hff) + 1)) shr 8
        g = (((src shr  8) and &hff) * (((dest shr  8) and &hff) + 1)) shr 8
        b = (((src shr  0) and &hff) * (((dest shr  0) and &hff) + 1)) shr 8
        return &hff000000 or (r shl 16) or (g shl 8) or (b shl 0)
    end if
end function


constructor level
    coldata = 0
    lvlWidth = 0
    lvlHeight = 0
    tilesets_N = 0
    blocks_N = 0
    layerData = 0
    snowfall = 0
    tilesets = 0
    blocks = 0
    portalZonesNum = 0
    if falloutTex = 0 then
        falloutTex = imagecreate(128,128)
        bload "falloutdisk96.bmp", falloutTex
    end if
    foreground_layer.init(sizeof(integer))
    background_layer.init(sizeof(integer))
    active_layer.init(sizeof(integer))
end constructor

constructor level(filename as string)    
    load filename
end constructor

sub level.resetBlock(x as integer, y as integer, lyr as integer)
    if x < 0 then
        x = 0
    elseif x > lvlWidth - 1 then 
        x = lvlWidth - 1
    end if
    if y < 0 then
        y = 0
    elseif y > lvlHeight - 1 then 
        y = lvlHeight - 1
    end if
    blocks[lyr][y * lvlWidth + x].tileset = 65535
end sub

sub level.setCollision(x as integer, y as integer, v as integer)
    if x < 0 then
        x = 0
    elseif x > lvlWidth - 1 then 
        x = lvlWidth - 1
    end if
    if y < 0 then
        y = 0
    elseif y > lvlHeight - 1 then 
        y = lvlHeight - 1
    end if
    coldata[y * lvlWidth + x] = v
end sub

sub Level.init(e_p as EffectController ptr)
    graphicFX_ = e_p
end sub

sub level.loadPortals(filename as string)
    dim as SeqFile.Reader struct    
    
    
    struct.push(SeqFile.READ_INTEGER)
    struct.push(SeqFile.SET_REPEAT, 1)
    struct.push(SeqFile.READ_STRING)
    struct.push(SeqFile.READ_INTEGER)
    struct.push(SeqFile.SET_REPEAT, 2)
    struct.push(SeqFile.READ_STRING)
    struct.push(SeqFile.READ_STRING)
    struct.push(SeqFile.READ_STRING)
    struct.push(SeqFile.END_REPEAT)
    struct.push(SeqFile.END_REPEAT)

    struct.readFile(filename, Level.regionPortals)
    
end sub


sub level.drawLayers(scnbuff as uinteger ptr, order as integer,_
                     cam_x as integer, cam_y as integer,_
                     adjust as Vector2D)
    dim as integer tl_x, tl_y
    dim as integer br_x, br_y
    dim as double  x, y
    dim as integer i, num, j
    dim as Vector2D a, b
    dim as integer ocx, ocy
    dim as integer ptr falloutBlend
    dim as Level_FalloutType ptr ptr flist
    dim as Level_FalloutType ptr cur
    dim as integer npx, npy, sx0, sy0, sx1, sy1
    dim as integer px, py
    dim as List ptr curList
    dim as integer ptr curLayer

    falloutBlend = 0
    num = 0
    
    select case order
    case BACKGROUND
        curList = @background_layer
    case ACTIVE
        curList = @active_layer
    case FOREGROUND
        curList = @foreground_layer
    end select
    
    curList->rollReset()
    do
        curLayer = curList->roll()
        if curLayer <> 0 then
            i = *curLayer
            x = 0
            y = 0
            if layerData[i].parallax < 255 then
                parallaxAdjust(x, y,_
                               cam_x, cam_y,_
                               lvlWidth * 16, lvlHeight * 16,_
                               layerData[i].depth)
                ocx = cam_x
                ocy = cam_y
            else
                x = 0 
                y = 0
                ocx = cam_x + adjust.x()
                ocy = cam_y + adjust.y()
            end if
            tl_x = ((ocx - x - SCRX * 0.5) ) / 16 - 1
            tl_y = ((ocy - y - SCRY * 0.5) ) / 16 - 1
            br_x = ((ocx - x + SCRX * 0.5) ) / 16
            br_y = ((ocy - y + SCRY * 0.5) ) / 16
              
            window screen (ocx - SCRX * 0.5, ocy - SCRY * 0.5)-_
                          (ocx + SCRX * 0.5, ocy + SCRY * 0.5)
                          
            
            if layerData[i].isFallout <> 65535 then
                if falloutBlend = 0 then
                    falloutBlend = imagecreate(640,480)
                end if
                drawLayer(falloutBlend, tl_x, tl_y, br_x, br_y, 0, 0, ocx, ocy, i)
                
                a = Vector2D(cam_x, cam_y) - Vector2D(SCRX, SCRY) * 0.5
                b = Vector2D(cam_x, cam_y) + Vector2D(SCRX, SCRY) * 0.5
    
                
                num = falloutZones.search(a,_
                                          b,_
                                          flist)
                
                if num > 0 then
                    for j = 0 to num - 1 
                        cur = flist[j]
                        
                        px = cur->a.x() - (cam_x - SCRX * 0.5) - adjust.x()
                        py = cur->a.y() - (cam_y - SCRY * 0.5) - adjust.y()
                        
                        if screenClip(px, py,_
                                      cur->b.x() - cur->a.x() - 1,_
                                      cur->b.y() - cur->a.y() - 1,_
                                      npx, npy,_
                                      sx0, sy0, sx1, sy1) = 1 then
                        
                        
                            if cur->cachedImage = 0 then
                                bitblt_FalloutMix(falloutBlend,_
                                                  npx, npy, _
                                                  falloutTex,_
                                                  sx0, sy0, sx1, sy1)
                            else
                                
                                bitblt_FalloutMix(falloutBlend,_
                                                  npx, npy, _
                                                  cur->cachedImage,_
                                                  sx0, sy0, sx1, sy1)
                                
                            end if
                                              
                        end if
                        
                    next j
              
                    deallocate(flist)
                end if
                
                put scnbuff, (ocx - SCRX*0.5,ocy - SCRY*0.5), falloutBlend, TRANS
                
            else
                drawLayer(scnbuff, tl_x, tl_y, br_x, br_y, 0, 0, ocx, ocy, i)
            end if
        else
            exit do
        end if
    loop
   
    if falloutBlend <> 0 then imagedestroy falloutBlend
    window screen (cam_x - SCRX * 0.5, cam_y - SCRY * 0.5)-_
                  (cam_x + SCRX * 0.5, cam_y + SCRY * 0.5)

end sub

sub level.drawLayer(scnbuff as uinteger ptr,_
                    tl_x as integer, tl_y as integer,_
                    br_x as integer, br_y as integer,_
                    x as integer, y as integer,_
                    cam_x as integer, cam_y as integer,_
                    lyr as integer)
                    
    
    dim as integer xscan, yscan
    dim as integer offset, delay
    dim as Level_VisBlock block
    dim as integer row_c, nextTile
    dim as integer retrieve
    dim as double newcx, newcy
    dim as integer tilePosX, tilePosY
    dim as double rand
    dim as Level_EffectData tempEffect
    
    if tl_x > br_x then swap tl_x, br_x
    if tl_y > br_y then swap tl_y, br_y
    if tl_x <            0 then tl_x = 0
    if br_x > lvlWidth - 1 then br_x = lvlWidth - 1
    if tl_y <             0 then tl_y = 0
    if br_y > lvlHeight - 1 then br_y = lvlHeight - 1    
    
    if layerData[lyr].parallax < 5 then
        x = (cam_x - (lvlWidth * 0.5 * 16)) * (1-layerData[lyr].depth)
        y = (cam_y - (lvlHeight * 0.5 * 16)) * (1-layerData[lyr].depth)
    end if
    
    rand = rnd
    
    for yscan = tl_y to br_y
        for xscan = tl_x to br_x
            block = blocks[lyr][yscan * lvlWidth + xscan]
            if block.tileset < 65535 then
                
                row_c = tilesets[block.tileset].row_count
                tilePosX = ((block.tileNum - 1) mod row_c) * 16
                tilePosY = ((block.tileNum - 1) \ row_c  ) * 16
                if block.usesAnim < 65535 then
                    tempEffect = *cast(Level_EffectData ptr, tilesets[block.tileset].tileEffect.retrieve(block.tileNum))
                    select case tempEffect.effect
                    case ANIMATE
                        block.frameDelay += 1
                        if block.frameDelay > tempEffect.delay then
                            block.frameDelay = 0
                            block.tileNum += tempEffect.nextTile
                            if tilesets[block.tileset].tileEffect.exists(block.tileNum) = 1 then
                                block.usesAnim = 1
                            else
                                block.usesAnim = 65535
                            end if
                            if tempEffect.effect = ANIMATE then
                                block.frameDelay = 0
                            elseif tempEffect.effect = FLICKER then
                                block.frameDelay = tempEffect.offset + tempEffect.delay * rand
                            end if
                            blocks[lyr][yscan * lvlWidth + xscan] = block
                        else
                            blocks[lyr][yscan * lvlWidth + xscan].frameDelay = block.frameDelay
                        end if
                    case FLICKER
                        block.frameDelay -= 1
                        if block.frameDelay < 0 then
                            block.tileNum += tempEffect.nextTile
                            if tilesets[block.tileset].tileEffect.exists(block.tileNum) = 1 then
                                tempEffect = *cast(Level_EffectData ptr, tilesets[block.tileset].tileEffect.retrieve(block.tileNum))
                                block.usesAnim = 1
                            else
                                block.usesAnim = 65535
                            end if
                            if tempEffect.effect = ANIMATE then
                                block.frameDelay = 0
                            elseif tempEffect.effect = FLICKER then
                                block.frameDelay = tempEffect.offset + tempEffect.delay * rand
                            end if
                            blocks[lyr][yscan * lvlWidth + xscan] = block
                        else
                            blocks[lyr][yscan * lvlWidth + xscan].frameDelay = block.frameDelay
                        end if
                    case DESTRUCT
                        ''
                    end select
                end if
                putDispatch(scnbuff, block, xscan*16 + x, yscan*16 + y,_
                            tilePosX, tilePosY, cam_x, cam_y)
            end if
        next xscan
    next yscan
 
end sub

sub Level.putDispatch(scnbuff as integer ptr,_
                      block as Level_VisBlock,_
                      x as integer, y as integer,_
                      tilePos_x as integer, tilePos_y as integer,_
                      cam_x as integer, cam_y as integer)
                      
    #define X_ 0
    #define Y_ 1
    
    dim as uinteger ptr src
    dim as integer ppos(0 to 1)
    dim as integer pdes(0 to 1)
    dim as integer pdir(0 to 1)
    dim as integer ptr ptile(0 to 1)
    dim as integer byCol, byRow, oldCol, i
    dim as integer xpos, ypos, w, col
    
    src = tilesets[block.tileset].set_image
    w = tilesets[block.tileset].set_width
    
    if block.rotatedType = 0 then
        put scnbuff, (x, y), src, (tilePos_x, tilePos_y)-(tilePos_x + 15, tilePos_y + 15), TRANS
    else
        x -= (cam_x - SCRX*0.5)
        y -= (cam_y - SCRY*0.5)
        ptile(X_) = @tilePos_x
        ptile(Y_) = @tilePos_y
        ppos(X_) = x
        ppos(Y_) = y
        pdes(X_) = x
        pdes(Y_) = y 
        select case block.rotatedType
        case 1
            byRow = X_
            byCol = Y_
            ppos(byRow) += 15
            ppos(byCol) += 15
            pdes(byRow) += -1
            pdes(byCol) += -1
            pdir(byRow) = -1
            pdir(byCol) = -1
        case 2
            byRow = Y_
            byCol = X_
            ppos(byRow) += 15
            ppos(byCol) += 0
            pdes(byRow) += -1
            pdes(byCol) += 16
            pdir(byRow) = -1
            pdir(byCol) = 1
        case 3
            byRow = X_
            byCol = Y_
            ppos(byRow) += 0
            ppos(byCol) += 15
            pdes(byRow) += 16
            pdes(byCol) += -1
            pdir(byRow) = 1
            pdir(byCol) = -1
        case 4
            byRow = Y_
            byCol = X_
            ppos(byRow) += 0
            ppos(byCol) += 15
            pdes(byRow) += 16
            pdes(byCol) += -1
            pdir(byRow) = 1
            pdir(byCol) = -1
        case 5
            byRow = X_
            byCol = Y_
            ppos(byRow) += 15
            ppos(byCol) += 0
            pdes(byRow) += -1
            pdes(byCol) += 16
            pdir(byRow) = -1
            pdir(byCol) = 1
        case 6
            byRow = Y_
            byCol = X_
            ppos(byRow) += 15
            ppos(byCol) += 15
            pdes(byRow) += -1
            pdes(byCol) += -1
            pdir(byRow) = -1
            pdir(byCol) = -1
        case 7
            byRow = X_
            byCol = Y_
            ppos(byRow) += 0
            ppos(byCol) += 0
            pdes(byRow) += 16
            pdes(byCol) += 16
            pdir(byRow) = 1
            pdir(byCol) = 1
        end select

        if ppos(X_) < 0 then 
            *(ptile(byCol)) += (-ppos(X_))
            ppos(X_) = 0
        elseif ppos(X_) >= SCRX then
            *(ptile(byCol)) += (ppos(X_) - SCRX) + 1
            ppos(X_) = SCRX - 1
        end if
            
        if pdes(X_) < 0 then 
            pdes(X_) = 0
        elseif pdes(X_) > SCRX then
            pdes(X_) = SCRX
        end if
        
        if ppos(Y_) < 0 then 
            *(ptile(byRow)) += (-ppos(Y_))
            ppos(Y_) = 0
        elseif ppos(Y_) >= SCRY then
            *(ptile(byRow)) += (ppos(Y_) - SCRY) + 1
            ppos(Y_) = SCRY - 1
        end if
            
        if pdes(Y_) < 0 then 
            pdes(Y_) = 0
        elseif pdes(Y_) > SCRY then
            pdes(Y_) = SCRY
        end if
        
        if sgn(pdes(X_) - ppos(X_)) <> pdir(X_) then 
            exit sub
        end if
        
        if sgn(pdes(Y_) - ppos(Y_)) <> pdir(Y_) then 
            exit sub
        end if
        
        ypos = tilePos_y
        oldCol = ppos(byCol)

        while ppos(byRow) <> pdes(byRow)
            ppos(byCol) = oldCol
            xpos = tilePos_x
            while ppos(byCol) <> pdes(byCol)
                
                col = src[8 + xpos + ypos*w]
                if col <> &hffff00ff then 
                    scnbuff[8 + ppos(X_) + ppos(Y_) * SCRX] = col
                end if
                ppos(byCol) += pdir(byCol)
                xpos += 1
            wend
            ppos(byRow) += pdir(byRow)
            ypos += 1
        wend
    
    end if
                 
end sub
  
destructor level
    flush()
    imagedestroy(falloutTex)
end destructor

function Level.usesSnow() as integer
    if snowfall = 1 then 
        return 1
    else
        return 0
    end if
end function
    
    
sub Level.addFallout(x as integer, y as integer, flavor as integer)
    dim as Level_FalloutType fallout
    dim as Level_FalloutType ptr ptr list
    dim as integer num, i
    dim as integer imgW, imgH
    dim as integer cacheW, cacheH
    dim as Vector2D old_a, old_b
    dim as integer tl_x, tl_y, br_x, br_y
    dim as integer xs, ys
    dim as double xp, yp
    dim as double d, rand
    dim as Level_VisBlock block
    dim as Level_EffectData tempEffect
    
    fallout.a = Vector2D(x,y) - Vector2D(64, 64)
    fallout.b = Vector2D(x,y) + Vector2D(64, 64)
    
    
    tl_x = fallout.a.x() / 16
    tl_y = fallout.a.y() / 16
    br_x = fallout.b.x() / 16
    br_y = fallout.b.y() / 16
    tl_x = max(0, min(tl_x, lvlWidth - 1))
    tl_y = max(0, min(tl_y, lvlHeight - 1))
    br_x = max(0, min(br_x, lvlWidth - 1))
    br_y = max(0, min(br_y, lvlHeight - 1))    
    
    
    
    for i = 0 to blocks_N - 1
        rand = rnd
        if layerData[i].isFallout = 1 then
            for ys = tl_y to br_y
                for xs = tl_x to br_x
                    xp = xs * 16 - x
                    yp = ys * 16 - y
                    d = sqr(xp*xp + yp*yp)
                    if d <= 48 then
                        
                        block = blocks[i][ys * lvlWidth + xs]
                        
                        if block.usesAnim < 65535 andAlso block.tileset < 65535 then
                           
                            tempEffect = *cast(Level_EffectData ptr, tilesets[block.tileset].tileEffect.retrieve(block.tileNum))
                            
                            if tempEffect.effect = DESTRUCT then
                                block.tileNum += tempEffect.nextTile
                                if tilesets[block.tileset].tileEffect.exists(block.tileNum) = 1 then
                                    tempEffect = *cast(Level_EffectData ptr, tilesets[block.tileset].tileEffect.retrieve(block.tileNum))
                                    block.usesAnim = 1
                                else
                                    block.usesAnim = 65535
                                end if
                                if tempEffect.effect = ANIMATE then
                                    block.frameDelay = 0
                                elseif tempEffect.effect = FLICKER then
                                    block.frameDelay = tempEffect.offset + tempEffect.delay * rand
                                end if
                                blocks[i][ys * lvlWidth + xs] = block
                            end if
                            
                        end if
                        
                        if d <= 12 then
                            resetBlock(xs, ys, i)
                        end if
                    end if
                next xs
            next ys
        end if
    next i
    
    
    fallout.flavor = flavor
    fallout.cachedImage = 0
    
    num = falloutZones.search(fallout.a, fallout.b, list)
    
    if num > 0 then
        
        old_a = fallout.a
        old_b = fallout.b
        for i = 0 to num - 1
            fallout.a.setX(min(list[i]->a.x(), fallout.a.x()))
            fallout.a.setY(min(list[i]->a.y(), fallout.a.y()))
            fallout.b.setX(max(list[i]->b.x(), fallout.b.x()))
            fallout.b.setY(max(list[i]->b.y(), fallout.b.y()))
        next i
        
    
        imgW = int(fallout.b.x() - fallout.a.x()) + 1
        imgH = int(fallout.b.y() - fallout.a.y()) + 1
        
        
        fallout.cachedImage = imagecreate(imgW, imgH, &hffffffff)
        
        bitblt_FalloutToFalloutMix(fallout.cachedImage,_
                                   x - fallout.a.x() - 64, y - fallout.a.y() - 64,_
                                   falloutTex,_
                                   0, 0, 127, 127)
        
        for i = 0 to num - 1
            with *(list[i])
                
                if .cachedImage <> 0 then
                    
                    cacheW = .b.x() - .a.x()
                    cacheH = .b.y() - .a.y()
                    
                    
                    bitblt_FalloutToFalloutMix(fallout.cachedImage,_
                                               .a.x() - fallout.a.x(),_
                                               .a.y() - fallout.a.y(),_
                                               .cachedImage,_
                                               0, 0,_
                                               cacheW - 1, cacheH - 1)
                    
                    
                    imagedestroy .cachedImage
                else
                   
                    bitblt_FalloutToFalloutMix(fallout.cachedImage,_
                                               .a.x() - fallout.a.x(),_
                                               .a.y() - fallout.a.y(),_
                                               falloutTex,_
                                               0, 0,_
                                               127, 127)
                    
                end if
                
                falloutZones.remove(list[i])
            end with
        next i
        deallocate(list)
    end if
    
    falloutZones.insert(fallout.a, fallout.b, @fallout)
   
end sub

function level.getCollisionBlock(x as integer, y as integer) as TinyBlock
    Dim as TinyBlock b
    dim as integer rz
    rz = 0
    if x < 0 then 
        rz = 1
    elseif x >= lvlWidth then
        rz = 1
    end if
    if y < 0 then 
        rz = 1
    elseif y >= lvlHeight then
        rz = 1
    end if
    if rz = 0 then
        b.cModel = coldata[y * lvlWidth + x]
    else
        b.cModel = 0
    end if
    return b
end function

sub level.flush()
    dim as integer i
    dim as Level_FalloutType ptr falloutItem
    #ifdef DEBUG
        prinTLOG "phlusch"
        stall(100)
    #endif
    if lvlName <> "" then
        if coldata <> 0 then deallocate(coldata)
        for i = 0 to tilesets_N - 1
            deallocate(tilesets[i].set_name)
            if tilesets[i].set_image <> 0 then imagedestroy(tilesets[i].set_image)
        next i
        if tilesets <> 0 then delete(tilesets)
        for i = 0 to blocks_N - 1
            if blocks[i] <> 0 then deallocate(blocks[i])
        next i
        if blocks <> 0 then deallocate(blocks)
        if layerData <> 0 then deallocate(layerData)
        background_layer.flush()
        active_layer.flush()
        foreground_layer.flush()
        falloutZones.rollReset()
        do
            falloutItem = falloutZones.roll()
            if falloutItem > 0 then
                if falloutItem->cachedImage <> 0 then 
                    imagedestroy(falloutItem->cachedImage)
                end if
            else
                exit do
            end if
        loop
        falloutZones.flush()
    end if
    #ifdef DEBUG
        prinTLOG "Fin-e"
        stall(100)
    #endif
end sub

sub level.load(filename as string)
    dim as integer f, i, q, j, s, x, y, xscan, yscan, skipCheck
    dim as TinyBlock block
    dim as ushort lyr
    dim as uinteger blockNumber, layerInt
    dim as string  strdata_n
    dim as ZString * 128 strdata
    dim as integer ptr imgData
    dim as Level_VisBlock ptr lvb
    redim as ushort setFirstIds(0)
    dim as Level_EffectData tempEffect
    dim as ushort numAnims, numObjs
    dim as ushort objType, objField(7)
    dim as Object_t tempObj
    
    f = freefile
 
    #ifdef DEBUG
        printlog "already bailing"
        stall(100)
    #endif
 
    flush()
    
    
    coldata = 0
    lvlWidth = 0
    lvlHeight = 0
    tilesets_N = 0
    blocks_N = 0
    tilesets = 0
    blocks = 0
    snowfall = 0 
    layerData = 0
    portalZonesNum = 0
    
    
    open filename for binary as #f
    get #f,,strdata
    lvlName = strdata

    get #f,,lvlWidth
    get #f,,lvlHeight
    get #f,,snowfall
    get #f,,tilesets_N
    tilesets = new Level_Tileset[tilesets_N]
    graphicFX_->init(lvlWidth * 16, lvlHeight * 16)
    #ifdef DEBUG
        if tilesets = 0 then
            printlog "panic 0"
            stall(100)
        end if
    #endif
   
    redim as ushort setFirstIds(tilesets_N - 1)
    
    #ifdef DEBUG
        dim as ushort pp
        dim as single ss
        dim as ushort temp1
        printlog lvlWidth & ", " & lvlHeight & ", " & tilesets_N & ", " & lvlName
        stall(100)
        
    #endif
      
    for i = 0 to tilesets_N - 1
        get #f,,strdata
        tilesets[i].set_name = allocate(len(strdata) + 1)
        *(tilesets[i].set_name) = strdata

        get #f,,strdata
        get #f,,tilesets[i].set_width
        get #f,,tilesets[i].set_height
        
        tilesets[i].row_count = (tilesets[i].set_width / 16)  
        tilesets[i].count = (tilesets[i].set_width / 16) * (tilesets[i].set_height / 16)
        
        imgData = 0
        imgData = imagecreate(tilesets[i].set_width, tilesets[i].set_height)
        
        if imgData = 0 then
            #ifdef DEBUG
                printlog "panic 1" & ", " & tilesets[i].set_width & ", " & tilesets[i].set_height
                stall(100)
            #endif
            tilesets[i].set_image = 0
        else
            #ifdef DEBUG
                printlog strdata
                stall(500)
            #endif
            tilesets[i].set_image = imgData
            bload strdata, tilesets[i].set_image
        end if
        
        
        get #f,,setFirstIds(i)
        get #f,,numAnims
        
        tilesets[i].tileEffect.init(sizeof(Level_EffectData))
        
        for j = 0 to numAnims - 1
            with tempEffect
                get #f,,.tilenum
                get #f,,.effect
                get #f,,.nextTile
                get #f,,.delay
                get #f,,.offset
                .tilenum += 1 'because tiles are 1 based not 0 based
            end with
            tilesets[i].tileEffect.insert(tempEffect.tilenum, @tempEffect)
        next j

    next i
    
    get #f,,blocks_N
    
    blocks_N -= 1
    blocks = allocate(sizeof(Level_VisBlock ptr) * blocks_N)
    #ifdef DEBUG
        printlog "Layers: " & str(blocks_N)
        stall(100)
        if blocks = 0 then
            printlog "panic 3"
            stall(100)
        end if
    #endif
    layerData = allocate(sizeof(Level_LayerData) * blocks_N)
    #ifdef DEBUG
        if layerData = 0 then
            printlog "panic 4"
            stall(100)
        end if
        printlog "Loading blocks..."
        stall(100)
    #endif
    for i = 0 to blocks_N - 1
        blocks[i] = 0
    next i
    
    
    for i = 0 to blocks_N
        get #f,,strdata
        strdata_n = strdata
        if ucase(left(strdata_n, 9)) = "COLLISION" then
            
            coldata = allocate(lvlWidth * lvlHeight * sizeof(ushort))
            #ifdef DEBUG
                if coldata = 0 then 
                    printlog "panic 5"
                     stall(100)
                end if
            #endif
            for j = 0 to lvlWidth * lvlHeight - 1
                get #f,,blockNumber
                coldata[j] = blockNumber
            next j
            
        else
            get #f,,lyr 
            layerInt = lyr
            get #f,,layerData[lyr].depth
            get #f,,layerData[lyr].parallax
            get #f,,layerData[lyr].inRangeSet
            get #f,,layerData[lyr].isDestructible
            get #f,,layerData[lyr].isFallout
            
            select case layerData[lyr].inRangeSet
            case BACKGROUND
                background_layer.push_back(@layerInt)
            case ACTIVE
                active_layer.push_back(@layerInt)
            case FOREGROUND
                foreground_layer.push_back(@layerInt)
            end select
            
            lvb = 0
            lvb = allocate(sizeof(Level_VisBlock) * lvlWidth * lvlHeight)
            
            blocks[lyr] = lvb
        
            #ifdef DEBUG
                if lvb = 0 then 
                    printlog "panic 6"
                     stall(100)
                end if
                printlog "Loading block layer, " & str(i)
            #endif
            
            for j = 0 to lvlWidth * lvlHeight - 1
                get #f,,blockNumber
         
                
                blocks[lyr][j].tileset = 65535
                blocks[lyr][j].tilenum = 65535
                blocks[lyr][j].rotatedType = blockNumber shr 29
                
                blockNumber = blockNumber and FLIPPED_MASK
                
                for q = 0 to tilesets_N - 1
                    
                    if blockNumber >= setFirstIds(q) andAlso _
                       blockNumber <  setFirstIds(q) + tilesets[q].count then
                        blocks[lyr][j].tileset = q
                        blocks[lyr][j].tilenum = blockNumber - setFirstIds(q) + 1
                        blocks[lyr][j].usesAnim = 65535
                        blocks[lyr][j].frameDelay = 0
                        if tilesets[q].tileEffect.exists(blocks[lyr][j].tilenum) = 1 then
                            blocks[lyr][j].usesAnim = 1
                        end if
                        exit for
                    end if
                    
                next q
                
            next j
            
        end if
    next i
    
    get #f,,numObjs
    for i = 0 to numObjs - 1 
        get #f,,tempObj.object_name
        get #f,,tempObj.object_type
        get #f,,tempObj.object_shape
        get #f,,tempObj.inRangeSet
        get #f,,tempObj.p
        get #f,,tempObj.size
        select case objType
        case EFFECT
            get #f,,objField(0)
            get #f,,objField(1)
            graphicFX_->create(tempObj.object_name, objField(0),_
                               tempObj.object_shape, tempObj.p,_
                               tempObj.size, objField(1),_
                               tempObj.inRangeSet)
        case PORTAL
            get #f,,strdata
            get #f,,strdata
            get #f,,objField(0)
        end select
    next i
    
    
    
    
    
    #ifdef DEBUG
        printlog str(blocks_N) & ", " & tilesets_N
        stall(100)
        printlog "Resolving portals..."
        stall(100)
    #endif
    close #f
    
    /'
    portalZonesNum = 0
    
    for y = 0 to lvlHeight - 1
        for x = 0 to lvlWidth - 1
            skipCheck = 0
            for i = 0 to portalZonesNum - 1
                if x < portalZones(i).a.x() orElse _
                   x > portalZones(i).b.x() orElse _
                   y < portalZones(i).a.y() orElse _
                   y > portalZones(i).b.y() then
                    skipCheck = 1
                    exit for
                end if
            next i
            if skipCheck = 0 andAlso getCollisionBlock(x, y).cModel = 24 then
                xscan = x
                yscan = y
                while getCollisionBlock(xscan + 1, yscan).cModel = 24
                    xscan += 1
                wend
                while getCollisionBlock(xscan, yscan + 1).cModel = 24
                    yscan += 1
                wend
                    
                with portalZones(portalZonesNum)
                    .a = Vector2D(x, y) * 16
                    .b = Vector2D(xscan + 1, yscan + 1) * 16 - Vector2D(1, 1)
                    .area = (.b.x() - .a.x()) * (.b.y() - .a.y())
                end with
                portalZonesNum += 1
           end if 
        next x
    next y
    '/
    
    
    falloutZones.init(lvlWidth*16, lvlHeight*16, sizeof(Level_FalloutType))
    
end sub


sub Level.repositionFromPortal(l as levelSwitch_t, _
                              byref p as Vector2D)
    /'
    dim as integer i, q                          
    
    for i = 0 to regionPortals->numRegions - 1
        if *(regionPortals->regionPortals[i].regionName) = left(l.fileName, len(l.fileName)-4) then
            with regionPortals->regionPortals[i]
                for q = 0 to .numPortals - 1
                    if *(.portals[q].portalName) = l.portalName then
                        select case l.portalName
                        case "RIGHT"
                            p = Vector2D(lvlWidth * 16 - 2, p.y())
                        case "LEFT"
                            p = Vector2D(1, p.y())
                        case "DOWN"
                            p = Vector2D(p.x(), 1)
                        case "UP"
                            p = Vector2D(p.x(), lvlHeight * 16 - 2)
                        case else
                            p = Vector2D(.portals[q].repX, .portals[q].repY)
                        end select
                        exit sub
                    end if
                next q
            end with
            exit sub
        end if  
    next i
    '/
end sub




function Level.getName() as string
    return lvlName
end function

function Level.processPortalCoverage(p as Vector2D,_
                                     w as double, h as double,_
                                     byref l as levelSwitch_t,_
                                     coverage as double = 0.5) as integer
    dim as integer i, q
    dim as integer curReg
    dim as integer curPortal
    dim as integer findPortal, index
    dim as string searchStr
    dim as double totalCoverage, dist, dvmag
    dim as Vector2D tl, br, dv
    /'
    findPortal = 0

    if p.x() <= 0 then
        searchStr = "LEFT"
    elseif p.x() + w >= (lvlWidth * 16 - 1) then
        searchStr = "RIGHT"
    elseif p.y() <= 0 then
        searchStr = "UP"
    elseif p.y() + h >= (lvlWidth * 16 - 1) then
        searchStr = "DOWN"
    else
        for i = 0 to portalZonesNum - 1
            
            if (p.x() > portalZones(i).b.x()) orElse _
               ((p.x() + w - 1) < portalZones(i).a.x()) orElse _
               (p.y()     > portalZones(i).b.y()) orElse _
               ((p.y() + h - 1) < portalZones(i).a.y()) then
            else
                tl.setX(max(portalZones(i).a.x(), p.x()))
                tl.setY(max(portalZones(i).a.y(), p.y()))
                br.setX(min(portalZones(i).b.x(), (p.x() + w - 1)))
                br.setY(min(portalZones(i).b.y(), (p.y() + h - 1)))
                                
                totalCoverage = ((br.x() - tl.x()) * (br.y() - tl.y())) / (w * h)
                if totalCoverage > coverage then
                    findPortal = i + 1
                end if
            end if
        next i
    end if
    l.fileName = ""
    l.portalName = ""
    l.p = Vector2D(0,0)
    if searchStr <> "" orElse findPortal > 0 then
        for i = 0 to regionPortals->numRegions - 1
            if *(regionPortals->regionPortals[i].regionName) = lvlName then
                index = 0
                dist = 1000
                with regionPortals->regionPortals[i]
                    for q = 0 to .numPortals - 1
                        if searchStr <> "" then
                            if *(.portals[q].portalName) = searchStr then
                                l.p = Vector2D(.portals[q].xPos, .portals[q].yPos)
                                l.fileName = *(.portals[q].linkMapName) + ".map"
                                l.portalName = *(.portals[q].linkPortalName)
                                return 0
                            end if
                        else
                            dv = Vector2D(.portals[q].xPos, .portals[q].yPos) * 16 - _
                                 (portalZones(findPortal - 1).a + portalZones(findPortal - 1).b) * 0.5
                            dvmag = dv.magnitude()
                            if dvmag < dist then
                                dist = dvmag
                                index = q
                            end if
                        end if
                    next q
                    if searchStr = "" andAlso findPortal = 0 then return 0
                    l.p = Vector2D(.portals[index].xPos, .portals[index].yPos)
                    l.fileName = *(.portals[index].linkMapName) + ".map"
                    l.portalName = *(.portals[index].linkPortalName)
                    return 1
                end with
                exit for
            end if
        next i
    end if
    '/
end function

function level.getWidth() as integer
    return lvlWidth
end function

function level.getHeight() as integer
    return lvlHeight
end function



function level.getCollisionLayerData() as TinyBlock ptr
    Dim as TinyBlock ptr blockd
    dim as integer u, v, off
    blockd = allocate(lvlWidth * lvlHeight * sizeof(TinyBlock))
    for v = 0 to lvlHeight-1
        for u = 0 to lvlWidth-1
            off = v*lvlWidth + u
            '''''''''''''''''''''''''''''''''''''''''''''
            if colData[off] = 22 orElse colData[off] = 24 then
                blockd[off].cModel = 0
            else
                blockd[off].cModel = coldata[off]
            end if
            '''''''''''''''''''''''''''''''''''''''''''''
        next u
    next v
    return blockd
end function
