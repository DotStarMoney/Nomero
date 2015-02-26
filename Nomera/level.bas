#include "level.bi"
#include "utility.bi"
#include "seqfile.bi"
#include "debug.bi"
#include "tinyblock.bi"
#include "dynamiccontroller.bi"
#include "projectilecollection.bi"
#include "player.bi"
#include "soundeffects.bi"
#include "fbpng.bi"

dim as integer ptr Level.falloutTex(0 to 2) = {0, 0, 0}
#ifdef DEBUG
	dim as integer ptr Level.collisionBlox = 0
#endif

#define NEW_SQUARE_MASK() new Level_SquareMaskList(lvlWidth*16, lvlHeight*16)
constructor Level_SquareMaskList(lvlWidth as double, lvlHeight as double)
    squares.init(lvlWidth, lvlHeight, sizeof(Level_SquareMask), 256, 256)
end constructor
destructor Level_SquareMaskList()
    'dim as any ptr ptr curSquare
    'BEGIN_HASH2D(curSquare, squares)
    '    delete(*cptr(Level_SquareMask ptr ptr, curSquare))
    'END_HASH2D()
end destructor

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
    destroyedBlockMemory.init(sizeof(destroyedBlocks_t))
    portalZonesNum = 0
    if falloutTex(0) = 0 then
		falloutTex(0) = png_load("falloutdisk96_1.png")
    end if
    if falloutTex(1) = 0 then
		falloutTex(1) = png_load("falloutdisk96_2.png")
    end if    
    if falloutTex(2) = 0 then
		falloutTex(2) = png_load("falloutdisk96_3.png")
    end if    
       
    foreground_layer.init(sizeof(integer))
    background_layer.init(sizeof(integer))
    active_layer.init(sizeof(integer))
    activeCover_layer.init(sizeof(integer))
    pendingPortalSwitch = 0
    reconnect = 0
    #ifdef DEBUG
		if collisionBlox = 0 then
			collisionBlox = png_load("CShapes.png")
		end if
	#endif
end constructor

constructor level(filename as string)    
    load filename
end constructor

sub level.setLink(link_ as objectlink)
	link = link_
end sub

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
    case ACTIVE_COVER
		curList = @activeCover_layer
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
                                                  falloutTex(cur->flavor),_
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
    
    #ifdef DEBUG
		dim as integer xs, ys
		dim as integer tilePosX, tilePosY
		if order = FOREGROUND then
			tl_x = ((cam_x - SCRX * 0.5) ) / 16 - 1
			tl_y = ((cam_y - SCRY * 0.5) ) / 16 - 1
			br_x = ((cam_x + SCRX * 0.5) ) / 16
			br_y = ((cam_y + SCRY * 0.5) ) / 16
			if tl_x > br_x then swap tl_x, br_x
			if tl_y > br_y then swap tl_y, br_y
			if tl_x <            0 then tl_x = 0
			if br_x > lvlWidth - 1 then br_x = lvlWidth - 1
			if tl_y <             0 then tl_y = 0
			if br_y > lvlHeight - 1 then br_y = lvlHeight - 1   
			for ys = tl_y to br_y
				for xs = tl_x to br_x
					i = coldata[ys * lvlWidth + xs]
					if i <> 0 then
						tilePosX = ((i - 1) mod 21) * 16
						tilePosY = ((i - 1) \ 21  ) * 16
						put scnbuff, (xs*16,ys*16), collisionBlox, (tilePosX, tilePosY)-(tilePosX+15, tilePosY+15), TRANS
					end if
				next xs
			next ys
		end if
	#endif
   
    if falloutBlend <> 0 then imagedestroy falloutBlend

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
    
    if layerData[lyr].parallax < 8 then
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
                
                put scnbuff, (xscan*16 + x, yscan*16 + y), tilesets[block.tileset].set_image, (tilePosX, tilePosY)-(tilePosX + 15, tilePosY + 15), TRANS

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
    
    'lol this is in here twice... y lol...
    
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
		/'
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
		'/
    end if
                 
end sub
  
destructor level
    flush()
    imagedestroy(falloutTex(0))
    imagedestroy(falloutTex(1))
    imagedestroy(falloutTex(2))
end destructor

function Level.usesSnow() as integer
    if snowfall = 1 then 
        return 1
    else
        return 0
    end if
end function
    
sub Level.splodeBlockReact(xs as integer, ys as integer)
	dim as integer i
	dim as integer deleteBlock
	dim as Level_VisBlock block
	dim as Level_EffectData tempEffect
	    
	if xs <  0         then exit sub
	if xs >= lvlWidth  then exit sub
	if ys <  0         then exit sub
	if ys >= lvlHeight then exit sub
	
	'dull splode 23, 73
	'resplode 24, 74
	'chain splode 75 and 76
	select case getCollisionBlock(xs, ys).cModel
	case 23
		setCollision(xs, ys, 0)
	case 73
		setCollision(xs, ys, 0)
	case 24
		setCollision(xs, ys, 0)
		if noVisuals = 0 then
			graphicFX_->create("Temporary Explode", ONE_SHOT_EXPLODE,_
							   ELLIPSE, Vector2D(xs * 16 + 8, ys * 16 + 8),_
							   Vector2D(0,0), 0,_
							   ACTIVE)
		else
			addFallout(xs*16 + 8, ys*16 + 8)
		end if
	case 74
		setCollision(xs, ys, 0)
		if noVisuals = 0 then
			graphicFX_->create("Temporary Explode", ONE_SHOT_EXPLODE,_
					   ELLIPSE, Vector2D(xs * 16 + 8, ys * 16 + 8),_
					   Vector2D(0,0), 0,_
					   ACTIVE)
		else
			addFallout(xs*16 + 8, ys*16 + 8)
		end if
	case 75
		setCollision(xs, ys, 0)
		splodeBlockReact(xs - 1, ys)
		splodeBlockReact(xs, ys - 1)
		splodeBlockReact(xs + 1, ys)
		splodeBlockReact(xs, ys + 1)		
	case 76
		setCollision(xs, ys, 0)
		splodeBlockReact(xs - 1, ys)
		splodeBlockReact(xs, ys - 1)
		splodeBlockReact(xs + 1, ys)
		splodeBlockReact(xs, ys + 1)	
	case else
		exit sub
	end select
	'chance to smoke
	
	curDestBlocks[ys * lvlWidth + xs] = 1
	if noVisuals = 0 then
		if int(rnd * 2) = 0 then
			graphicFX_->create("Temporary Smoke", ONE_SHOT_SMOKE,_
							   ELLIPSE, Vector2D(xs * 16 + 8, ys * 16 + 8),_
							   Vector2D(0,0), 0,_
							   ACTIVE)
		end if
	end if
	for i = 0 to blocks_N
		if layerData[i].isDestructible = 1 then
			block = blocks[i][ys * lvlWidth + xs]
			if block.tileset < 65535 then
				deleteBlock = 1
				if block.usesAnim < 65535 then
					tempEffect = *cast(Level_EffectData ptr, tilesets[block.tileset].tileEffect.retrieve(block.tileNum))
					if tempEffect.effect = DESTRUCT then
						deleteBlock = 0
						modBlockDestruct(i, xs, ys)
					end if
				end if
				if deleteBlock = 1 then
					resetBlock(xs, ys, i)
				end if
			end if
		end if
	next i
end sub

sub Level.modBlockDestruct(lyr as integer, xs as integer, ys as integer)
    dim as Level_VisBlock block
    dim as Level_EffectData tempEffect
    
	block = blocks[lyr][ys * lvlWidth + xs]
                        
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
				block.frameDelay = tempEffect.offset + tempEffect.delay * rnd
			end if
			blocks[lyr][ys * lvlWidth + xs] = block
		end if
		
	end if
end sub

function Level.getCoverageLayerBlocks(x0 as integer, y0 as integer,_
									  x1 as integer, y1 as integer,_
									  byref data_ as Level_CoverageBlockInfo_t ptr) as integer
	dim as integer ptr layer_i
	dim as integer tl_x, tl_y
	dim as integer br_x, br_y
	dim as integer xscan, yscan
	dim as integer listSize, row_c
	dim as integer tilePosX, tilePosY
	dim as Level_VisBlock block
	
	listSize = 0
	data_ = 0

	tl_x = x0 shr 4
	tl_y = y0 shr 4
	br_x = x1 shr 4
	br_y = y1 shr 4		
	
	if tl_x < 0 then tl_x = 0
	if tl_y < 0 then tl_y = 0
	if br_x >= lvlWidth then br_x = lvlWidth - 1
	if br_y >= lvlHeight then br_y = lvlHeight - 1
	
	BEGIN_LIST(layer_i, activeCover_layer)
		
		for yscan = tl_y to br_y
			for xscan = tl_x to br_x
				block = blocks[*layer_i][yscan * lvlWidth + xscan]
				if block.tileset < 65535 then
                
					row_c = tilesets[block.tileset].row_count
					tilePosX = ((block.tileNum - 1) mod row_c) * 16
					tilePosY = ((block.tileNum - 1) \ row_c  ) * 16
					
					listSize += 1
					data_ = reallocate(data_, sizeof(Level_CoverageBlockInfo_t)*listSize)
					with data_[listSize - 1]
						.img = tilesets[block.tileset].set_image
						.l = *layer_i
						.x0 = tilePosX
						.y0 = tilePosY
						.x1 = .x0 + 15
						.y1 = .y0 + 15
						.rpx = xscan * 16
						.rpy = yscan * 16
					end with

				end if
			next xscan
		next yscan
		
	END_LIST()				
	return listSize
end function

sub Level.addFallout(x as integer, y as integer, flavor as integer = -1)
    dim as Level_FalloutType fallout
    dim as Level_FalloutType ptr ptr list
    dim as integer num, i
    dim as integer imgW, imgH
    dim as integer cacheW, cacheH
    dim as Vector2D old_a, old_b
    dim as integer tl_x, tl_y, br_x, br_y
    dim as integer xs, ys
    dim as double xp, yp
    dim as double d
    dim as Level_VisBlock block
    dim as Level_EffectData tempEffect
    
    fallout.a = Vector2D(x,y) - Vector2D(64, 64)
    fallout.b = Vector2D(x,y) + Vector2D(64, 64)
    if flavor = -1 then
		if int(rnd * 5000) = 0 then
			flavor = 2
		else
			flavor = int(rnd * 2)
		end if
		'flavor = 2
    end if
    
	fallout.flavor = flavor
    
    tl_x = fallout.a.x() / 16
    tl_y = fallout.a.y() / 16
    br_x = fallout.b.x() / 16
    br_y = fallout.b.y() / 16
    tl_x = max(0, min(tl_x, lvlWidth - 1))
    tl_y = max(0, min(tl_y, lvlHeight - 1))
    br_x = max(0, min(br_x, lvlWidth - 1))
    br_y = max(0, min(br_y, lvlHeight - 1))      

	link.dynamiccontroller_ptr->explosionAlert(Vector2D(x,y))
	link.player_ptr->explosionAlert(Vector2D(x,y))
	
	link.effectcontroller_ptr->explodeEffects(Vector2D(x,y))

	for ys = tl_y to br_y
		for xs = tl_x to br_x
			xp = xs * 16 - x
			yp = ys * 16 - y
			d = sqr(xp*xp + yp*yp)
			if d <= 48 then
				splodeBlockReact(xs, ys)
				if noVisuals = 0 andAlso fallout.flavor <> 2 then
					for i = 0 to blocks_N - 1
						if (layerData[i].isFallout = 1) andAlso d <= 12 then
							resetBlock(xs, ys, i)
						end if
					next i
				end if
			end if
		next xs
	next ys
   

    
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
                                   falloutTex(fallout.flavor),_
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
                                               falloutTex(.flavor),_
                                               0, 0,_
                                               127, 127)
                    
                end if
                
                falloutZones.remove(list[i])
            end with
        next i
        deallocate(list)
    end if
    
    falloutZones.insert(fallout.a, fallout.b, @fallout)
	reconnect = 1
end sub

function Level.checkDestroyedBlocks(x as integer, y as integer) as integer
	if curDestBlocks[y * lvlWidth + x] <> 0 then
		return 1
	else
		return 0
	end if
end function

function level.mustReconnect() as integer
	return reconnect
end function

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
    dim as PortalType_t ptr portalItem
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
            delete(layerData[i].visibilitySquares)
            delete(layerData[i].maskSquares)
            delete(layerData[i].aggregateBlockingRegions)
        next i
        if blocks <> 0 then deallocate(blocks)
        if layerData <> 0 then deallocate(layerData)
        background_layer.flush()
        active_layer.flush()
        activeCover_layer.flush()
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
		portals.rollReset()
        do
            portalItem = portals.roll()
            if portalItem > 0 then
                deallocate(portalItem->portal_name)
                deallocate(portalItem->to_map)
                deallocate(portalItem->to_portal)
            else
                exit do
            end if
        loop
        portals.flush()
        falloutZones.flush()
        graphicFX_->flush()
        link.projectilecollection_ptr->flush()
        link.dynamiccontroller_ptr->flush()
    end if
    #ifdef DEBUG
        prinTLOG "Fin-e"
        stall(100)
    #endif
end sub

function Level.getCurrentMusicFile() as string
	return loadedMusic
end function

function Level.getDefaultPos() as Vector2D
	return Vector2D(default_x * 16, default_y * 16)
end function


sub Level.computeSquareMasks(lyr as integer, x0 as integer, y0 as integer,_
                                             x1 as integer, y1 as integer)

    #macro SET_NT_VALUE(BLOCK_INDEX)
    
        NTvalue = 0
        if compStep = NT_MASK then
            tset = blocks[lyr][BLOCK_INDEX].tileset
            if tset <> 65535 then
                if tilesets[tset].NoTransparencyIDs.exists(blocks[lyr][BLOCK_INDEX].tileNum - 1) then
                    NTvalue = 1
                end if
            end if    
        elseif compStep = DRAW_MASK then
            if blocks[lyr][BLOCK_INDEX].tileset <> 65535 then
                NTvalue = 1
            end if
        end if
    
    #endmacro
    #define NT_MASK 0
    #define DRAW_MASK 1
                                             
    dim as Level_SquareMask newSquare
    dim as integer xscan, yscan, windowSize, tset
    dim as integer i, j, findLowLimit
    dim as integer offX, offY, largestArea
    dim as integer best_x0, best_y0, best_x1, best_y1, area
    dim as integer last_x0, last_y0, last_x1, last_y1, row
    dim as integer leftLo, leftHi, rightLo, rightHi
    dim as integer invalidLeft, invalidRight, leftExArea, rightExArea
    dim as integer NTvalue
    dim as integer ptr searchMask
    dim as integer compStep
    
    subtractSquareMasks((*layerData[lyr].maskSquares), x0*16, y0*16, (x1 + 1)*16, (y1 + 1)*16)
    subtractSquareMasks((*layerData[lyr].visibilitySquares), x0*16, y0*16, (x1 + 1)*16, (y1 + 1)*16)
  
    windowSize = (x1 - x0 + 1)
    for compStep = NT_MASK to DRAW_MASK
        searchMask = callocate(windowSize * (y1 - y0 + 1), sizeof(integer))
        offY = 0
        yscan = y0
        while yscan <= y1
            offX = 0
            xscan = x0
            while xscan <= x1
            
                SET_NT_VALUE(yscan * lvlWidth + xscan)
                
                if NTvalue = 1 andAlso (searchMask[offX + offY * windowSize] = 0) then
                    
                    last_x0 = offX
                    last_x1 = offX
                    last_y0 = offY
                    last_y1 = last_y0
                    
                    while(last_y1 < (y1 - y0))
                        SET_NT_VALUE((y0 + last_y1 + 1)*lvlWidth + (x0 + last_x0))
                        if (NTvalue = 0) orElse (searchMask[(last_y1 + 1)*windowSize + last_x0] = 1) then exit while
                        last_y1 += 1
                    wend
                    
                    largestArea = 0 
                    invalidLeft = 0
                    invalidRight = 0
                    do
                        area = (last_x1 - last_x0 + 1) * (last_y1 - last_y0 + 1)

                        if area > largestArea then
                            largestArea = area
                            best_x0 = last_x0
                            best_y0 = last_y0
                            best_x1 = last_x1
                            best_y1 = last_y1
                        end if
                        if last_y0 > last_y1 then exit do
              
                        if invalidLeft = 0 then
                            leftLo = last_y0
                            leftHi = last_y1
                            if last_x0 > 0 then
                                findLowLimit = 1
                                for row = last_y0 to last_y1
                                    SET_NT_VALUE((y0 + row)*lvlWidth + (x0 + last_x0 - 1))
                                    if (NTvalue = 0) orElse (searchMask[row*windowSize + last_x0 - 1] = 1) then 
                                        if findLowLimit = 1 then
                                            leftLo += 1
                                        else
                                            leftHi = row - 1
                                            exit for
                                        end if
                                    else
                                        findLowLimit = 0
                                    end if
                                next row      
                            else
                                invalidLeft = 1
                            end if
                            if leftLo > leftHi then invalidLeft = 1
                        end if
                        
                        if invalidRight = 0 then
                            rightLo = last_y0
                            rightHi = last_y1
                            if last_x1 < (x1 - x0) then
                                findLowLimit = 1
                                for row = last_y0 to last_y1
                                    SET_NT_VALUE((y0 + row)*lvlWidth + (x0 + last_x1 + 1))
                                    if (NTvalue = 0) orElse (searchMask[row*windowSize + last_x1 + 1] = 1) then 
                                        if findLowLimit = 1 then
                                            rightLo += 1
                                        else
                                            rightHi = row - 1
                                            exit for
                                        end if
                                    else
                                        findLowLimit = 0
                                    end if
                                next row      
                            else
                                invalidRight = 1
                            end if
                            if rightLo > rightHi then invalidRight = 1
                        end if
                        
                        if (invalidLeft = 1) andAlso (invalidRight = 1) then exit do
                        
                        leftExArea = (leftHi - leftLo + 1) * (last_x1 - last_x0 + 2)
                        rightExArea = (rightHi - rightLo + 1) * (last_x1 - last_x0 + 2)
                        
                        if ((leftExArea > rightExArea) orElse (invalidRight = 1)) andAlso (invalidLeft = 0) then
                            last_y0 = leftLo
                            last_y1 = leftHi
                            last_x0 -= 1
                        else
                            last_y0 = rightLo
                            last_y1 = rightHi
                            last_x1 += 1                    
                        end if
                    loop
                    
                    for i = best_y0 to best_y1
                        for j = best_x0 to best_x1
                            searchMask[i*windowSize + j] = 1
                        next j
                    next i
                   
                    newSquare.tl = Vector2D(best_x0, best_y0) * 16
                    newSquare.br = Vector2D(best_x1 + 1, best_y1 + 1) * 16
                    
                    if compStep = NT_MASK then
                        (*layerData[lyr].maskSquares).squares.insert(newSquare.tl, newSquare.br, @newSquare)
                    elseif compStep = DRAW_MASK then
                        (*layerData[lyr].visibilitySquares).squares.insert(newSquare.tl, newSquare.br, @newSquare)
                    end if
                    
                    if last_y0 = yscan then 
                        offX += 1
                        xscan += 1
                    end if
                else
                    offX += 1
                    xscan += 1
                end if
            wend
            offY += 1
            yscan += 1
        wend
        deallocate(searchMask)
    next compStep
    
end sub

sub level.load(filename as string)
    dim as integer f, i, q, j, s, x, y, xscan, yscan, skipCheck
    dim as TinyBlock block
    dim as ushort lyr
    dim as uinteger blockNumber, layerInt
    dim as integer row_c, tilePosX, tilePosY, transPxls
    dim as string  strdata_n
    dim as ZString * 128 strdata
    dim as Level_VisBlock ptr lvb
    redim as ushort setFirstIds(0)
    dim as Level_EffectData tempEffect
    dim as ushort numAnims, numObjs
    dim as ushort objType, objField(7)
    dim as Object_t tempObj
    dim as PortalType_t tempPortal
    dim as single tempSingleField
    dim as destroyedBlocks_t tempDblocks
    dim as Hashtable ptr NoTransLookup
    
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
    get #f,,default_x
    get #f,,default_y
    get #f,,strdata
    
    loadedMusic = strdata
    
    get #f,,tilesets_N
    if tilesets_N > 0 then
		tilesets = new Level_Tileset[tilesets_N]
	end if
    graphicFX_->init(lvlWidth * 16, lvlHeight * 16)
   

    portals.init(lvlWidth * 16, lvlHeight * 16, sizeof(PortalType_t))
    
    
    
    #ifdef DEBUG
        if tilesets = 0 then
            printlog "panic 0"
            stall(100)
        end if
    #endif
	if tilesets_N > 0 then
		redim as ushort setFirstIds(tilesets_N - 1)
    end if
    
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
        
        tilesets[i].NoTransparencyIDs.init(sizeof(integer))
        
        
        tilesets[i].row_count = (tilesets[i].set_width / 16)  
        tilesets[i].count = (tilesets[i].set_width / 16) * (tilesets[i].set_height / 16)
      
		#ifdef DEBUG
			printlog strdata
			stall(100)
		#endif
		
		if right(strdata, 3) = "bmp" then
			tilesets[i].set_image =  imagecreate(tilesets[i].set_width, tilesets[i].set_height)
			bload strdata, tilesets[i].set_image
		else
			tilesets[i].set_image = png_load(strdata)
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

        for j = 0 to tilesets[i].count - 1    
            row_c = tilesets[i].row_count
            tilePosX = (j mod row_c) * 16
            tilePosY = (j \ row_c) * 16
            transPxls = countTrans(tilesets[i].set_image, tilePosX, tilePosY, tilePosX+15, tilePosY+15)            
            if transPxls = 256 then tilesets[i].NoTransparencyIDs.insert(j, @j)
        next j
        
    next i
    

                            
    
    get #f,,blocks_N
    blocks_N -= 1
    if blocks_N > 0 then
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
	end if
    
    
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
            get #f,,layerData[lyr].illuminated
            get #f,,layerData[lyr].ambientLevel
            get #f,,layerData[lyr].coverage
            
            select case layerData[lyr].inRangeSet
            case BACKGROUND
                background_layer.push_back(@layerInt)
            case ACTIVE
                active_layer.push_back(@layerInt)
            case FOREGROUND
                foreground_layer.push_back(@layerInt)
            case ACTIVE_COVER
				activeCover_layer.push_back(@layerInt)
            end select
            
            layerData[lyr].visibilitySquares = NEW_SQUARE_MASK()
            layerData[lyr].maskSquares       = NEW_SQUARE_MASK()
            
            layerData[lyr].frameDrawRegions.init(sizeof(Level_SquareMask))
            layerData[lyr].aggregateBlockingRegions = new Level_SquareMaskList(SCRX, SCRY)

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
            
            computeSquareMasks(i, 0, 0, lvlWidth-1, lvlHeight-1)
            
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
        select case tempObj.object_type
        case EFFECT
            get #f,,objField(0)
            get #f,,objField(1)
            graphicFX_->create(tempObj.object_name, objField(0),_
                               tempObj.object_shape, tempObj.p,_
                               tempObj.size, objField(1),_
                               tempObj.inRangeSet)
        case PORTAL
            get #f,,strdata
            tempPortal.to_map = allocate(len(strdata) + 1)
            *(tempPortal.to_map) = strdata
            get #f,,strdata
            tempPortal.to_portal = allocate(len(strdata) + 1)
            *(tempPortal.to_portal) = strdata
            get #f,,objField(0)
            tempPortal.direction = objField(0)
            tempPortal.a = tempObj.p
            tempPortal.b = tempObj.p + tempObj.size
            tempPortal.portal_name = allocate(len(tempObj.object_name) + 1)
            *(tempPortal.portal_name) = tempObj.object_name
            portals.insert(tempPortal.a, tempPortal.b, @tempPortal)
        case SPAWN
			get #f,,strdata
			get #f,,objField(0)
			get #f,,objField(1)
			get #f,,tempSingleField
			link.dynamiccontroller_ptr->addSpawnZone(strdata,_
													 objField(0),_
													 tempObj.p,_
													 tempObj.size,_
													 objField(1),_
													 tempSingleField)
        end select
    next i

    #ifdef DEBUG
        printlog str(blocks_N) & ", " & tilesets_N
        stall(100)
        printlog "Resolving portals..."
        stall(100)
    #endif
    close #f
    
    if destroyedBlockMemory.exists(lvlName) = 1 then
		curDestBlocks = cast(destroyedBlocks_t ptr, destroyedBlockMemory.retrieve(lvlName))->data_
	else
		curDestBlocks = allocate(sizeof(byte) * lvlWidth * lvlHeight)
		for i = 0 to lvlWidth * lvlHeight - 1
			curDestBlocks[i] = 0
		next i
		tempDblocks.data_ = curDestBlocks
		tempDblocks.width_ = lvlWidth
		tempDblocks.height_ = lvlHeight
		destroyedBlockMemory.insert(lvlName, @tempDblocks)
	end if
	noVisuals = 1
	for i = 0 to lvlWidth * lvlHeight - 1
		if curDestBlocks[i] <> 0 then
			splodeBlockReact(i mod lvlWidth, i / lvlWidth)
		end if
	next i

	noVisuals = 0
    falloutZones.init(lvlWidth*16, lvlHeight*16, sizeof(Level_FalloutType))
    pendingPortalSwitch = 0
    justLoaded = 1
	#ifdef DEBUG
        printlog "Loading complete!"
        stall(100)
    #endif
end sub

sub Level.overrideCurrentMusicFile(filename as string)
	loadedMusic = filename
end sub


sub level.computeDrawRegions(cam_x as integer, cam_y as integer, adjust as Vector2D)
    #define MAX_SLICES 64

    dim as integer layerList
    dim as integer squares_N
    dim as integer i, j, q, u, t
    dim as double x, y
    dim as double ocx, ocy
    dim as Vector2D tl, br
    dim as Vector2D center
    dim as Level_SquareMask ptr ptr squares
    dim as Level_SquareMask ptr curSquare
    dim as Level_SquareMask squareInst
    dim as Level_SquareMaskList ptr aggregateMask
    dim as Level_SquareMask ptr ptr coverSquares
    dim as integer coverSquares_N, numNew
    dim as Level_SquareMask ptr curCoverSquare
    dim as integer ptr curLayer
    dim as List ptr curList
    dim as Level_SquareMask drawSlices(0 to MAX_SLICES - 1)
    dim as integer drawSlices_N, oldDrawSlices_N
   
    
    aggregateMask = new Level_SquareMaskList(SCRX, SCRY)
    
    for layerList = 0 to 3
        select case layerList
        case 0
            curList = @foreground_layer
        case 1
            curList = @activeCover_layer
        case 2
            curList = @active_layer
        case 3
            curList = @background_layer
        end select
        BEGIN_LIST_REVERSE(curLayer, (*curList))
            x = 0
            y = 0
            i = *curLayer
            if layerData[i].parallax < 255 then
                parallaxAdjust(x, y,_
                               cam_x, cam_y,_
                               lvlWidth * 16, lvlHeight * 16,_
                               layerData[i].depth)
                ocx = cam_x
                ocy = cam_y
            else
                ocx = cam_x + adjust.x()
                ocy = cam_y + adjust.y()
            end if
            center = Vector2D(ocx - x, ocy - y)
            layerData[i].frameCenter = center
            tl = center - Vector2D(SCRX, SCRY)*0.5
            br = center + Vector2D(SCRX, SCRY)*0.5
            
            layerData[i].frameDrawRegions.flush()
            squares_N = layerData[i].visibilitySquares->squares.search(tl, br, squares)
            for j = 0 to squares_N - 1
                
                squareInst = *(squares[j])
                
                if squareInst.tl.x < tl.x then squareInst.tl.setX(tl.x)
                if squareInst.tl.y < tl.y then squareInst.tl.setY(tl.y) 
                if squareInst.br.x > br.x then squareInst.br.setX(br.x)
                if squareInst.br.y > br.y then squareInst.br.setY(br.y)
                squareInst.tl = squareInst.tl - tl
                squareInst.br = squareInst.br - tl
                  
                drawSlices_N = 1
                drawSlices(0) = squareInst
              
                coverSquares_N = aggregateMask->squares.search(drawSlices(0).tl, drawSlices(0).br, coverSquares)
                for q = 0 to coverSquares_N - 1      
                    curCoverSquare = coverSquares[q]
                    
                    u = 0
                    oldDrawSlices_N = drawSlices_N
                    while u < oldDrawSlices_N
                     
                        numNew = subtractSquareMasksList(drawSlices(u), *curCoverSquare, drawSlices(), drawSlices_N)
                        if numNew > -2 then
                            if numNew = 0 then
                                oldDrawSlices_N -= 1
                                drawSlices_N -= 1
                                drawSlices(u) = drawSlices(drawSlices_N)
                            else
                                drawSlices_N += numNew - 1
                                drawSlices(u) = drawSlices(drawSlices_N)
                                u += 1
                            end if
                        else
                            u += 1
                        end if
                                 
                    wend  
               
                next q
                deallocate(coverSquares)
                
                for q = 0 to drawSlices_N - 1
                    layerData[i].frameDrawRegions.push_back(@(drawSlices(q)))
                next q
            next j
            deallocate(squares)
            
            coverSquares_N = layerData[i].maskSquares->squares.search(tl, br, coverSquares)
            for j = 0 to coverSquares_N - 1
                squareInst = *(coverSquares[j])
                if squareInst.tl.x < tl.x then squareInst.tl.setX(tl.x)
                if squareInst.tl.y < tl.y then squareInst.tl.setY(tl.y) 
                if squareInst.br.x > br.x then squareInst.br.setX(br.x)
                if squareInst.br.y > br.y then squareInst.br.setY(br.y)
                squareInst.tl = squareInst.tl - tl
                squareInst.br = squareInst.br - tl
                subtractSquareMasks(*aggregateMask, squareInst.tl.x, squareInst.tl.y, squareInst.br.x, squareInst.br.y)                
                aggregateMask->squares.insert(squareInst.tl, squareInst.br, @squareInst)
            next j
            deallocate(coverSquares)
            
        END_LIST()
    next layerList
    delete(aggregateMask)
end sub

function Level.subtractSquareMasksList(squareA as Level_SquareMask,_
                                       squareB as Level_SquareMask,_
                                       outSquares() as Level_SquareMask, offset as integer) as integer
    dim as double x0, y0, x1, y1
    dim as Level_SquareMask newSquare
    dim as integer cutStyle
    'B cuts A
    x0 = squareB.tl.x
    y0 = squareB.tl.y
    x1 = squareB.br.x
    y1 = squareB.br.y
    
    if (squareA.tl.x >= x0) andAlso (squareA.br.x <= x1) andAlso _
       (squareA.tl.y >= y0) andAlso (squareA.br.y <= y1) then
        return 0
    elseif (squareA.br.x > x0) andAlso (squareA.br.y > y0) andALso _
           (squareA.tl.x < x1) andAlso (squareA.tl.y < y1) then
        cutStyle = 0
        with squareA
            if .tl.x < x0 then
                if .tl.y < y0 then
                    if .br.y <= y1 then
                        if .br.x <= x1 then
                            cutStyle = 1
                        else 
                            cutStyle = 2
                        end if
                    else
                         if .br.x <= x1 then
                            cutStyle = 3
                        else 
                            cutStyle = 15
                        end if
                    end if
                else
                    if .br.y <= y1 then
                        if .br.x <= x1 then
                            cutStyle = 4
                        else
                            cutStyle = 5
                        end if
                    else
                        if .br.x <= x1 then
                            cutStyle = 6
                        else
                            cutStyle = 7
                        end if  
                    end if
                end if
            else
                if .tl.y < y0 then
                    if .br.y <= y1 then
                        if .br.x <= x1 then
                            cutStyle = 10
                        else
                            cutStyle = 8
                        end if
                    else
                        if .br.x <= x1 then
                            cutStyle = 9
                        else
                            cutStyle = 11
                        end if
                    end if
                else
                    if .br.y <= y1 then
                        cutStyle = 12
                    else
                        if .br.x <= x1 then
                            cutStyle = 13
                        else
                            cutStyle = 14
                        end if
                    end if
                end if
            end if
        end with
        'print cutStyle
        select case cutStyle
        case 1
            newSquare = squareA
            newSquare.br.setX(x0)
            outSquares(offset + 0) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x0)
            newSquare.br.setY(y0)
            outSquares(offset + 1) = newSquare
            return 2
        case 2
            newSquare = squareA
            newSquare.br.setX(x0)
            outSquares(offset + 0) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x0)
            newSquare.br.setY(y0)
            outSquares(offset + 1) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x1)
            newSquare.tl.setY(y0)
            outSquares(offset + 2) = newSquare
            return 3
        case 3
            newSquare = squareA
            newSquare.br.setY(y0)
            outSquares(offset + 0) = newSquare
            newSquare = squareA
            newSquare.tl.setY(y0)
            newSquare.br.setX(x0)
            outSquares(offset + 1) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x0)
            newSquare.tl.setY(y1)
            outSquares(offset + 2) = newSquare
            return 3
        case 4
            newSquare = squareA
            newSquare.br.setX(x0)
            outSquares(offset + 0) = newSquare
            return 1
        case 5
            newSquare = squareA
            newSquare.br.setX(x0)
            outSquares(offset + 0) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x1)
            outSquares(offset + 1) = newSquare
            return 2
        case 6
            newSquare = squareA
            newSquare.br.setX(x0)
            outSquares(offset + 0) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x0)
            newSquare.tl.setY(y1)
            outSquares(offset + 1) = newSquare
            return 2
        case 7
            newSquare = squareA
            newSquare.br.setX(x0)
            outSquares(offset + 0) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x0)
            newSquare.tl.setY(y1)
            outSquares(offset + 1) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x1)
            newSquare.br.setY(y1)
            outSquares(offset + 2) = newSquare
            return 3
        case 8
            newSquare = squareA
            newSquare.br.setY(y0)
            outSquares(offset + 0) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x1)
            newSquare.tl.setY(y0)
            outSquares(offset + 1) = newSquare
            return 2
        case 9
            newSquare = squareA
            newSquare.br.setY(y0)
            outSquares(offset + 0) = newSquare
            newSquare = squareA
            newSquare.tl.setY(y1)
            outSquares(offset + 1) = newSquare
            return 2
        case 10
            newSquare = squareA
            newSquare.br.setY(y0)
            outSquares(offset + 0) = newSquare
            return 1
        case 11
            newSquare = squareA
            newSquare.br.setY(y0)
            outSquares(offset + 0) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x1)
            newSquare.tl.setY(y0)
            outSquares(offset + 1) = newSquare
            newSquare = squareA
            newSquare.tl.setY(y1)
            newSquare.br.setX(x1)
            outSquares(offset + 2) = newSquare
            return 3
        case 12
            newSquare = squareA
            newSquare.tl.setX(x1)
            outSquares(offset + 0) = newSquare
            return 1
        case 13
            newSquare = squareA
            newSquare.tl.setY(y1)
            outSquares(offset + 0) = newSquare
            return 1
        case 14
            newSquare = squareA
            newSquare.tl.setX(x1)
            outSquares(offset + 0) = newSquare
            newSquare = squareA
            newSquare.tl.setY(y1)
            newSquare.br.setX(x1)
            outSquares(offset + 1) = newSquare
            return 2
        case 15
            newSquare = squareA
            newSquare.br.setY(y0)
            newSquare.br.setX(x1)
            outSquares(offset + 0) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x1)
            newSquare.br.setY(y1)
            outSquares(offset + 1) = newSquare
            newSquare = squareA
            newSquare.tl.setX(x0)
            newSquare.tl.setY(y1)
            outSquares(offset + 2) = newSquare
            newSquare = squareA
            newSquare.tl.setY(y0)
            newSquare.br.setX(x0)
            outSquares(offset + 3) = newSquare
            return 4
        case else
            return -2
        end select   
    end if         
    return -2
end function

sub Level.subtractSquareMasks(byref squaresList as Level_SquareMaskList,_
                              x0 as double, y0 as double,_
                              x1 as double, y1 as double)
    
    dim as integer neighbors_N, i, cutStyle
    dim as Level_SquareMask ptr ptr foundSquares
    dim as Level_SquareMask ptr curSquare    
    dim as Level_SquareMask newSquare
    
    neighbors_N = squaresList.squares.search(Vector2D(x0, y0), Vector2D(x1, y1), foundSquares)
    for i = 0 to neighbors_N - 1
        curSquare = foundSquares[i]
        
        if (curSquare->tl.x >= x0) andAlso (curSquare->br.x <= x1) andAlso _
           (curSquare->tl.y >= y0) andAlso (curSquare->br.y <= y1) then
            squaresList.squares.remove(curSquare)
        elseif (curSquare->br.x > x0) andAlso (curSquare->br.y > y0) andALso _
               (curSquare->tl.x < x1) andAlso (curSquare->tl.y < y1) then
            cutStyle = 0
            '' may not be correct...
            with *curSquare
                if .tl.x < x0 then
                    if .tl.y < y0 then
                        if .br.y <= y1 then
                            if .br.x <= x1 then
                                cutStyle = 1
                            else 
                                cutStyle = 2
                            end if
                        else
                             if .br.x <= x1 then
                                cutStyle = 3
                            else 
                                cutStyle = 15
                            end if
                        end if
                    else
                        if .br.y <= y1 then
                            if .br.x <= x1 then
                                cutStyle = 4
                            else
                                cutStyle = 5
                            end if
                        else
                            if .br.x <= x1 then
                                cutStyle = 6
                            else
                                cutStyle = 7
                            end if  
                        end if
                    end if
                else
                    if .tl.y < y0 then
                        if .br.y <= y1 then
                            if .br.x <= x1 then
                                cutStyle = 10
                            else
                                cutStyle = 8
                            end if
                        else
                            if .br.x <= x1 then
                                cutStyle = 9
                            else
                                cutStyle = 11
                            end if
                        end if
                    else
                        if .br.y <= y1 then
                            cutStyle = 12
                        else
                            if .br.x <= x1 then
                                cutStyle = 13
                            else
                                cutStyle = 14
                            end if
                        end if
                    end if
                end if
            end with
            select case cutStyle
            case 1
                newSquare = *curSquare
                newSquare.br.setX(x0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x0)
                newSquare.br.setY(y0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 2
                newSquare = *curSquare
                newSquare.br.setX(x0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x0)
                newSquare.br.setY(y0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x1)
                newSquare.tl.setY(y0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 3
                newSquare = *curSquare
                newSquare.br.setY(y0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setY(y0)
                newSquare.br.setX(x0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x0)
                newSquare.tl.setY(y1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 4
                newSquare = *curSquare
                newSquare.br.setX(x0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 5
                newSquare = *curSquare
                newSquare.br.setX(x0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 6
                newSquare = *curSquare
                newSquare.br.setX(x0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x0)
                newSquare.tl.setY(y1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 7
                newSquare = *curSquare
                newSquare.br.setX(x0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x0)
                newSquare.tl.setY(y1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x1)
                newSquare.br.setY(y1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 8
                newSquare = *curSquare
                newSquare.br.setY(y0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x1)
                newSquare.tl.setY(y0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 9
                newSquare = *curSquare
                newSquare.br.setY(y0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setY(y1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 10
                newSquare = *curSquare
                newSquare.br.setY(y0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 11
                newSquare = *curSquare
                newSquare.br.setY(y0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x1)
                newSquare.tl.setY(y0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setY(y1)
                newSquare.br.setX(x1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 12
                newSquare = *curSquare
                newSquare.tl.setX(x1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 13
                newSquare = *curSquare
                newSquare.tl.setY(y1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 14
                newSquare = *curSquare
                newSquare.tl.setX(x1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setY(y1)
                newSquare.br.setX(x1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case 15
                newSquare = *curSquare
                newSquare.br.setY(y0)
                newSquare.br.setX(x1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x1)
                newSquare.br.setY(y1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setX(x0)
                newSquare.tl.setY(y1)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
                newSquare = *curSquare
                newSquare.tl.setY(y0)
                newSquare.br.setX(x0)
                squaresList.squares.insert(newSquare.tl, newSquare.br, @newSquare)
            case else
                exit for
            end select
            squaresList.squares.remove(curSquare)
        end if
    next i
    deallocate(foundSquares)
end sub 
                                                  
                                                       
sub Level.repositionFromPortal(l as levelSwitch_t, _
                               byref p as TinyBody)
	dim as PortalType_t ptr portal_p
	dim as string test1, test2
	portals.rollReset()
	test1 = trimwhite(ucase(l.portalName))
	if test1 = "DEFAULT" then 
		p.p = Vector2D(default_x, default_y) * 16
		p.v = Vector2D(0,0)
		exit sub
	end if
	do
		portal_p = portals.roll()
		if portal_p <> 0 then
			test2 = trimwhite(ucase(*(portal_p->portal_name)))
			if test1 = test2 then
				select case portal_p->direction
				case D_UP
					p.p = Vector2D(p.p.x(), portal_p->b.y() + p.r)
					if p.p.x() < portal_p->a.x() orElse p.p.x() > portal_p->b.x() then
						p.p.setX((portal_p->a.x() + portal_p->b.x()) * 0.5)
					end if
					if p.v.y() < 0 then p.v.setY(0)
				case D_DOWN
					p.p = Vector2D(p.p.x(), portal_p->a.y() - p.r)
					if p.p.x() < portal_p->a.x() orElse p.p.x() > portal_p->b.x() then
						p.p.setX((portal_p->a.x() + portal_p->b.x()) * 0.5)
					end if
					if p.v.y() > 0 then p.v.setY(0)
				case D_LEFT
					p.p = Vector2D(portal_p->b.x() + p.r, p.p.y())
					if p.p.y() < portal_p->a.y() orElse p.p.y() > portal_p->b.y() then
						p.p.setY((portal_p->a.y() + portal_p->b.y()) * 0.5)
					end if
					if p.v.x() < 0 then p.v.setX(0)
				case D_RIGHT
					p.p = Vector2D(portal_p->a.x() - p.r, p.p.y())
					if p.p.y() < portal_p->a.y() orElse p.p.y() > portal_p->b.y() then
						p.p.setY((portal_p->a.y() + portal_p->b.y()) * 0.5)
					end if
					if p.v.x() > 0 then p.v.setX(0)
				case D_IN
					p.p = Vector2D((portal_p->a.x() + portal_p->b.x()) * 0.5,_
								   portal_p->b.y() - p.r)
					p.v = Vector2D(0,0)
				end select
				exit do
			end if
		else
			exit do
		end if
	loop
end sub

sub Level.addPortal(pt as PortalType_t)
	portals.insert(pt.a, pt.b, @pt)
end sub


function Level.getName() as string
    return lvlName
end function

function Level.processPortalCoverage(p as Vector2D,_
                                     w as double, h as double,_
                                     byref l as levelSwitch_t,_
                                     coverage as double = 0.5) as integer
	dim as any ptr ptr p_list
	dim as PortalType_t ptr tempPortal
	dim as integer numFound
	dim as double area1, area2
	dim as Vector2D a, b
	
	numFound = portals.search(p, p + Vector2D(w,h), p_list)
	
	if numFound > 0 then
		tempPortal = p_list[0]
		a.setX(max(tempPortal->a.x(), p.x()))
		a.setY(max(tempPortal->a.y(), p.y()))
		b.setX(min(tempPortal->b.x(), p.x() + w))
		b.setY(min(tempPortal->b.y(), p.y() + h))
		area1 = (b.x() - a.x()) * (b.y() - a.y())
		area2 = w * h
		if area1 / area2 >= coverage then
			l.fileName = *(tempPortal->to_map) + ".map"
			l.portalName = *(tempPortal->to_portal)
			l.shouldSwitch = 1
			l.facing = tempPortal->direction
			return 1
		end if
		l.shouldSwitch = 0
		return 0
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
            
            if     ((colData[off] >= 1 ) andAlso (colData[off] <= 21)) then
				blockd[off].cModel = colData[off]
			elseif ((colData[off] >= 23) andAlso (colData[off] <= 56)) then
				blockd[off].cModel = colData[off] - 1
			elseif ((colData[off] >= 58) andAlso (colData[off] <= 72)) then
				blockd[off].cModel = colData[off] - 2
			elseif ((colData[off] >= 76) andAlso (colData[off] <= 76)) then
				blockd[off].cModel = colData[off] - 5
			else
                blockd[off].cModel = EMPTY
            end if
           
        next u
    next v
    reconnect = 0
    return blockd
end function
