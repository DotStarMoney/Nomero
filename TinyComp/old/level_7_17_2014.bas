#include "level.bi"
#include "utility.bi"
#include "seqfile.bi"
#include "debug.bi"



dim as RegionData_t ptr Level.regionPortals = 0

constructor level
    coldata = 0
    lvlWidth = 0
    lvlHeight = 0
    tilesets_N = 0
    blocks_N = 0
    layerData = 0
    
    tilesets = 0
    blocks = 0
    portalZonesNum = 0

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

sub level.loadPortals(filename as string)
    dim as SeqFile.Reader struct    
    
    
    struct.push(SeqFile.READ_INTEGER)
    struct.push(SeqFile.SET_REPEAT, 1)
    struct.push(SeqFile.READ_STRING)
    struct.push(SeqFile.READ_INTEGER)
    struct.push(SeqFile.SET_REPEAT, 2)
    struct.push(SeqFile.READ_STRING)
    struct.push(SeqFile.READ_INTEGER)
    struct.push(SeqFile.READ_INTEGER)
    struct.push(SeqFile.READ_STRING)
    struct.push(SeqFile.READ_STRING)
    struct.push(SeqFile.END_REPEAT)
    struct.push(SeqFile.END_REPEAT)

    struct.readFile(filename, Level.regionPortals)
    
end sub


sub level.drawLayersBack(scnbuff as uinteger ptr,_
                         cam_x as integer, cam_y as integer,_
                         adjust as Vector2D)
    dim as integer tl_x, tl_y
    dim as integer br_x, br_y
    dim as double  x, y
    dim as integer i
    dim as integer ocx, ocy
    
    for i = 0 to blocks_N - 1
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
                      
        drawLayer(scnbuff, tl_x, tl_y, br_x, br_y, 0, 0, ocx, ocy, i)
        
    next i
    window screen (cam_x - SCRX * 0.5, cam_y - SCRY * 0.5)-_
                  (cam_x + SCRX * 0.5, cam_y + SCRY * 0.5)
end sub

sub level.drawLayersFront(scnbuff as uinteger ptr,_
                          cam_x as integer, cam_y as integer,_
                          adjust as Vector2D)
                          
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
    dim as double newcx, newcy
    dim as integer tilePosX, tilePosY
    
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
    
    
    for yscan = tl_y to br_y
        for xscan = tl_x to br_x
            block = blocks[lyr][yscan * lvlWidth + xscan]
            if block.tileset < 65535 then
                
                row_c = tilesets[block.tileset].row_count
                tilePosX = ((block.tileNum - 1) mod row_c) * 16
                tilePosY = ((block.tileNum - 1) \ row_c  ) * 16
                if block.usesAnim < 65535 then
                    delay = tilesets[block.tileset].tile_anim[block.usesAnim].delay
                    block.frameDelay += 1
                    if block.frameDelay > delay then
                        nextTile = tilesets[block.tileset].tile_anim[block.usesAnim].nextTile
                        nextTile += block.tileNum
                        block.tileNum = nextTile
                        block.usesAnim = tilesets[block.tileset].tile_anim[block.usesAnim].nextAnim
                        block.frameDelay = 0
                        blocks[lyr][yscan * lvlWidth + xscan] = block
                    else
                        blocks[lyr][yscan * lvlWidth + xscan].frameDelay = block.frameDelay
                    end if
                end if
                put scnbuff, (xscan*16 + x, yscan*16 + y), tilesets[block.tileset].set_image, (tilePosX, tilePosY)-(tilePosX + 15, tilePosY + 15), TRANS
            else
                'line scnbuff, (xscan*16 + x, yscan*16 + y)-(xscan*16 + x + 15, yscan*16 + y + 15), (lyr + 1) * &h092340, B
            end if
        next xscan
    next yscan
end sub
  
destructor level
    flush()
end destructor

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
    'prinTLOG "phlusch"
    'stall(1000)
    if lvlName <> "" then
        if coldata <> 0 then deallocate(coldata)
        for i = 0 to tilesets_N - 1
            imagedestroy tilesets[i].set_image
            if tilesets[i].tile_anim <> 0 then 
                deallocate(tilesets[i].tile_anim)
            end if
        next i
        deallocate(tilesets)
        for i = 0 to blocks_N - 1
            deallocate(blocks[i])
        next i
        deallocate(blocks)
        deallocate(layerData)
    end if
end sub

sub level.load(filename as string)
    dim as integer f, i, q, j, s, x, y, xscan, yscan, skipCheck
    dim as TinyBlock block
    dim as ushort lyr
    dim as ushort blockNumber
    dim as string  strdata_n
    dim as ZString * 128 strdata
    redim as ushort setFirstIds(0)
    f = freefile
 
    'printlog "already bailing"
    'stall(500)
 
    'flush()
    
    coldata = 0
    lvlWidth = 0
    lvlHeight = 0
    tilesets_N = 0
    blocks_N = 0
    tilesets = 0
    blocks = 0
    layerData = 0
    portalZonesNum = 0
    
    open filename for binary as #f
    get #f,,strdata
    lvlName = strdata
 
 
 
    get #f,,lvlWidth
    get #f,,lvlHeight
    get #f,,tilesets_N
    tilesets = allocate(sizeof(Level_Tileset) * tilesets_N)
        if tilesets = 0 then
                'printlog "panic 0"
                 'stall(500)
        end if
   
    redim as ushort setFirstIds(tilesets_N - 1)
    
    for i = 0 to tilesets_N - 1
        get #f,,strdata
        tilesets[i].set_name = strdata
        
        get #f,,strdata
        get #f,,tilesets[i].set_width
        get #f,,tilesets[i].set_height
        
        tilesets[i].row_count = (tilesets[i].set_width / 16)  
        tilesets[i].count = (tilesets[i].set_width / 16) * (tilesets[i].set_height / 16)
        
        
        tilesets[i].set_image = imagecreate(tilesets[i].set_width, tilesets[i].set_height)
        if tilesets[i].set_image = 0 then
                'printlog "panic 1"
                 'stall(500)
            end if

        bload strdata, tilesets[i].set_image

        get #f,,setFirstIds(i)
        get #f,,tilesets[i].num_anims
    
        if tilesets[i].num_anims > 0 then
            tilesets[i].tile_anim = allocate(sizeof(Level_BlockAnimData) * tilesets[i].num_anims)
            if tilesets[i].tile_anim = 0 then
                'printlog "panic 2"
                 'stall(500)
            end if
        else
            tilesets[i].tile_anim = 0
        end if
        
        for j = 0 to tilesets[i].num_anims - 1
            with tilesets[i].tile_anim[j]
                get #f,,.tilenum 
                get #f,,.nextTile
                get #f,,.delay
                .tilenum += 1
                .nextAnim = 65535
            end with
        next j
        for j = 0 to tilesets[i].num_anims - 1
            for s = 0 to tilesets[i].num_anims - 1
                if j <> s then
                    if tilesets[i].tile_anim[j].nextTile + tilesets[i].tile_anim[j].tileNum = _
                       tilesets[i].tile_anim[s].tileNum then
                        tilesets[i].tile_anim[j].nextAnim = s
                        exit for
                    end if
                end if
            next s
        next j
    next i
    
    
    
    'get #f,,blocks_N
    'blocks_N -= 1
    'blocks = allocate(sizeof(Level_VisBlock ptr) * blocks_N)
    'if blocks = 0 then
        'printlog "panic 3"
                 'stall(500)
    'end if
    'printlog "attempting to allocate layerData, " & layerData
    'layerData = allocate(sizeof(Level_LayerData) * blocks_N)
    if layerData = 0 then
        'printlog "panic 4"
        'printlog str(sizeof(Level_LayerData)) & ", " & blocks_N
         '        stall(500)
    end if
    
    for i = 0 to blocks_N
        get #f,,strdata
        strdata_n = strdata
        'printlog strdata_n
        if strdata_n = "Collision" then
            coldata = allocate(lvlWidth * lvlHeight * sizeof(ushort))
            
            if coldata = 0 then 
             '   printlog "panic 5"
             '    stall(500)
            else
              '  printlog "colldata " & coldata
              '  stall(500)
            end if
            for j = 0 to lvlWidth * lvlHeight - 1
                get #f,,coldata[j]
            next j
            
        else
            dim as single sss
            dim as ushort uuu
            get #f,,lyr  
            get #f,,sss
            get #f,,uuu
            
            'blocks[lyr] = allocate(sizeof(Level_VisBlock) * lvlWidth * lvlHeight)
            'printlog str(blocks[lyr])
            'stall(500)
            'if  blocks[lyr] = 0 then 
               ' printlog "panic 6"
               '  stall(500)
            'end if
            
            for j = 0 to lvlWidth * lvlHeight - 1
                get #f,,blockNumber
                
                'blocks[lyr][j].tileset = 65535
               ' blocks[lyr][j].tilenum = 65535
                
                for q = 0 to tilesets_N - 1
                    /'
                    if blockNumber >= setFirstIds(q) andAlso _
                       blockNumber <  setFirstIds(q) + tilesets[q].count then
                        blocks[lyr][j].tileset = q
                        blocks[lyr][j].tilenum = blockNumber - setFirstIds(q) + 1
                        blocks[lyr][j].usesAnim = 65535
                        blocks[lyr][j].frameDelay = 0
                        for s = 0 to tilesets[q].num_anims - 1
                            if blocks[lyr][j].tilenum = tilesets[q].tile_anim[s].tilenum then
                                blocks[lyr][j].usesAnim = s 
                                
                                exit for
                            end if
                        next s
                        exit for
                    end if
                    '/
                next q
            next j
            
        end if
    next i
    
    
    
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

    findPortal = 0

    if p.x() <= 0 then
        searchStr = "LEFT"
    elseif p.x() >= (lvlWidth * 16 - 1) then
        searchStr = "RIGHT"
    elseif p.y() <= 0 then
        searchStr = "UP"
    elseif p.y() >= (lvlWidth * 16 - 1) then
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
                            dv = Vector2D(.portals[q].xPos, .portals[q].yPos) - _
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
