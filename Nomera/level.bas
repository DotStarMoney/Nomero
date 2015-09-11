#include "level.bi"
#include "utility.bi"
#include "seqfile.bi"
#include "debug.bi"
#include "tinyblock.bi"
#include "dynamiccontroller.bi"
#include "projectilecollection.bi"
#include "player.bi"
#include "soundeffects.bi"
#include "item.bi"
#include "fbpng.bi"
#include "effects3d.bi"
#include "gamespace.bi"
#include "packedbinary.bi"
#include "vbcompat.bi"

dim as integer ptr Level.falloutTex(0 to 2) = {0, 0, 0}
#ifdef DEBUG
	dim as integer ptr Level.collisionBlox = 0
#endif

constructor level
    coldata = 0
    lvlWidth = 0
    lvlHeight = 0
    tilesets_N = 0
    blocks_N = 0
    layerData = 0
    snowfall = 0
    tilesets = 0
    windyMistLayers_n = 0
    curDestBlocks = 0
    shouldLightObjects = 0
    blocks = 0
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
    lightList = new LightPair ptr[LIGHT_MAX]
    foreground_layer.init(sizeof(integer))
    background_layer.init(sizeof(integer))
    active_layer.init(sizeof(integer))
    activeCover_layer.init(sizeof(integer))
    activeFront_layer.init(sizeof(integer))
    groups.init(sizeof(Level_layerGroup))
    smokeTexture = imagecreate(SCRX, SCRY, 0)
    auroraTranslate = 0
    pendingPortalSwitch = 0
    reconnect = 0
    auroraTexture.load("aurora.png")
    mistTexture.load("mist2.png")
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
sub level.fadeMistIn()
    fadeDir = -1
end sub

sub level.fadeMistOut()
    fadeDir = 1
end sub
sub level.resetMistFade()
    fadeDir = 0
    fadeOut = 0
end sub


function level.getLevelCenterX() as integer
    return lvlCenterX
end function

function level.getLevelCenterY() as integer
    return lvlCenterY
end function


        
sub level.drawLayers(scnbuff as uinteger ptr, order as integer,_
                     cam_x as integer, cam_y as integer,_
                     adjust as Vector2D)
    dim as integer tl_x, tl_y
    dim as integer br_x, br_y
    dim as double  x, y
    dim as integer i, num, j, wlayer
    dim as Vector2D a, b, drawP, shift
    dim as integer ocx, ocy, fade
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
    case ACTIVE_FRONT
    	curList = @activeFront_layer
    end select

    
    curList->rollReset()
    do
        curLayer = curList->roll()
        if curLayer <> 0 then
            i = *curLayer
            x = 0
            y = 0
            
            if layerData[i].isHidden = LEVEL_OFF then
                
                if layerData[i].parallax < 255 then
                    parallaxAdjust(x, y,_
                                   cam_x, cam_y,_
                                   lvlCenterX, lvlCenterY,_ 'lvlWidth * 16 * 0.5, lvlHeight * 16 * 0.5,_
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
                
                if layerData[i].windyMistLayer <> -1 andAlso fadeOut < 255 then
                    wlayer = layerData[i].windyMistLayer
                    shift = (link.gamespace_ptr->camera - Vector2D(lvlWidth, lvlHeight)*8)*(1 - layerData[i].depth)
                    fade = 255 * layerData[i].depth^(0.02) - fadeOut
                    if fade < 0 then fade = 0
                    if fade > 250 then fade = 250
                    for j = 0 to windyMistLayers[wlayer].objects_n - 1
                        drawP = windyMistLayers[wlayer].objects[j].p + shift
                        mistTexture.putGLOW(scnbuff, drawP.x, drawP.y, 0, 0, mistTexture.getWidth() - 1, mistTexture.getHeight() - 1, &h007f7fff or (fade shl 24))
                    next j
                end if
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
    dim as Level_VisBlock ptr modBlock
    dim as integer row_c, nextTile
    dim as integer retrieve
    dim as double newcx, newcy
    dim as integer tilePosX, tilePosY
    dim as double ax, ay
    dim as Level_EffectData tempEffect
   
    
    if tl_x > br_x then swap tl_x, br_x
    if tl_y > br_y then swap tl_y, br_y
    if tl_x <            0 then tl_x = 0
    if br_x > lvlWidth - 1 then br_x = lvlWidth - 1
    if tl_y <             0 then tl_y = 0
    if br_y > lvlHeight - 1 then br_y = lvlHeight - 1    
    
    if layerData[lyr].parallax < 8 then
        ax = 0
        ay = 0
        parallaxAdjust(ax, ay, cam_x, cam_y, lvlCenterX, lvlCenterY, layerData[lyr].depth)
        x = ax
        y = ay
    end if
    
    if layerData[lyr].illuminated <> 65535 then
    
        for yscan = tl_y to br_y
            for xscan = tl_x to br_x
                modBlock = @(blocks[lyr][yscan * lvlWidth + xscan])
                if modBlock->tileset < 65535 then
                    
                    row_c = tilesets[modBlock->tileset].row_count
                    tilePosX = ((modBlock->tileNum - 1) mod row_c) * 16
                    tilePosY = ((modBlock->tileNum - 1) \ row_c  ) * 16
                    
                    select case modBlock->numLights
                    case 0
                        tilesets[modBlock->tileset].set_image.putTRANS_0xLight(scnbuff, xscan*16 + x, yscan*16 + y,_
                                                                           tilePosX, tilePosY, tilePosX + 15, tilePosY + 15,_
                                                                           layerData[lyr].ambientLevel)    
                    case 1
                        tilesets[modBlock->tileset].set_image.putTRANS_1xLight(scnbuff, xscan*16 + x, yscan*16 + y,_
                                                                           tilePosX, tilePosY, tilePosX + 15, tilePosY + 15,_
                                                                           layerData[lyr].ambientLevel, *(modBlock->light(0)))   
                    case 2
                        tilesets[modBlock->tileset].set_image.putTRANS_2xLight(scnbuff, xscan*16 + x, yscan*16 + y,_
                                                                           tilePosX, tilePosY, tilePosX + 15, tilePosY + 15,_
                                                                           layerData[lyr].ambientLevel, *(modBlock->light(0)),_
                                                                                                        *(modBlock->light(1)))
                    case 3
                        tilesets[modBlock->tileset].set_image.putTRANS_3xLight(scnbuff, xscan*16 + x, yscan*16 + y,_
                                                                               tilePosX, tilePosY, tilePosX + 15, tilePosY + 15, _
                                                                               layerData[lyr].ambientLevel, *(modBlock->light(0)), _
                                                                                                            *(modBlock->light(1)), _
                                                                                                            *(modBlock->light(2)))
                    end select
                    modBlock->numLights = 0
                    modBlock->light(0) = 0
                    modBlock->light(1) = 0
                    modBlock->light(2) = 0
                    
                end if
            next xscan
        next yscan
      
    else
        if layerData[lyr].glow = &hffffffff then
            for yscan = tl_y to br_y
                for xscan = tl_x to br_x
                    modBlock = @(blocks[lyr][yscan * lvlWidth + xscan])
                    if modBlock->tileset < 65535 then
                        
                        row_c = tilesets[modBlock->tileset].row_count
                        tilePosX = ((modBlock->tileNum - 1) mod row_c) * 16
                        tilePosY = ((modBlock->tileNum - 1) \ row_c  ) * 16
                      
                        tilesets[modBlock->tileset].set_image.putTRANS(scnbuff, xscan*16 + x, yscan*16 + y, tilePosX, tilePosY, tilePosX + 15, tilePosY + 15)
                    end if
                next xscan
            next yscan
        else
            for yscan = tl_y to br_y
                for xscan = tl_x to br_x
                    modBlock = @(blocks[lyr][yscan * lvlWidth + xscan])
                    if modBlock->tileset < 65535 then
                        
                        row_c = tilesets[modBlock->tileset].row_count
                        tilePosX = ((modBlock->tileNum - 1) mod row_c) * 16
                        tilePosY = ((modBlock->tileNum - 1) \ row_c  ) * 16
                      
                        tilesets[modBlock->tileset].set_image.putGLOW(scnbuff, xscan*16 + x, yscan*16 + y, tilePosX, tilePosY, tilePosX + 15, tilePosY + 15, layerData[lyr].glow)
                    end if
                next xscan
            next yscan        
        end if
    end if
    if layerData[lyr].depth = 0 andAlso (drawAurora <> 65535) then 
        drawMode7Ceiling(scnbuff, auroraTexture.getData(), auroraTranslate, auroraTranslate, -70)   
    end if
end sub

destructor level
    flush()
    imagedestroy(falloutTex(0))
    imagedestroy(falloutTex(1))
    imagedestroy(falloutTex(2))
end destructor

function Level.usesSnow() as integer
    if snowfall <> LEVEL_OFF then 
        return snowfall
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
						.img = tilesets[block.tileset].set_image.getData()
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
    tl_x = _max_(0, _min_(tl_x, lvlWidth - 1))
    tl_y = _max_(0, _min_(tl_y, lvlHeight - 1))
    br_x = _max_(0, _min_(br_x, lvlWidth - 1))
    br_y = _max_(0, _min_(br_y, lvlHeight - 1))      

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
            fallout.a.setX(_min_(list[i]->a.x(), fallout.a.x()))
            fallout.a.setY(_min_(list[i]->a.y(), fallout.a.y()))
            fallout.b.setX(_max_(list[i]->b.x(), fallout.b.x()))
            fallout.b.setY(_max_(list[i]->b.y(), fallout.b.y()))
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
    dim as Level_layerGroup ptr curGroup
    #ifdef DEBUG
        prinTLOG "phlusch"
        stall(100)
    #endif
    highestLayerIndex = -1
    if lvlName <> "" then
        shouldLightObjects = 0
        #ifdef DEBUG
            prinTLOG "tilesets..."
            stall(100)
        #endif
        if coldata <> 0 then deallocate(coldata)
        for i = 0 to tilesets_N - 1
            deallocate(tilesets[i].set_name)
            tilesets[i].set_image.flush()
        next i
        if tilesets <> 0 then delete(tilesets)
        #ifdef DEBUG
            prinTLOG "layers..."
            stall(100)
        #endif
        for i = 0 to blocks_N - 1
            if blocks[i] <> 0 then deallocate(blocks[i])
        next i
        #ifdef DEBUG
            prinTLOG "windymist..."
            stall(100)
        #endif
        if windyMistLayers <> 0 then
            for i = 0 to windyMistLayers_n - 1
                if windyMistLayers[i].objects <> 0 then deallocate(windyMistLayers[i].objects)
            next i
            deallocate(windyMistLayers)
        end if
        if blocks <> 0 then deallocate(blocks)
        if layerData <> 0 then deallocate(layerData)
        #ifdef DEBUG
            prinTLOG "layer lists..."
            stall(100)
        #endif
        background_layer.flush()
        active_layer.flush()
        activeFront_layer.flush()
        activeCover_layer.flush()
        foreground_layer.flush()
        #ifdef DEBUG
            prinTLOG "layer groups..."
            stall(100)
        #endif
        BEGIN_HASH(curGroup, groups)
            delete(curGroup->layers)
        END_HASH()
        groups.flush()
        #ifdef DEBUG
            prinTLOG "fallout zones..."
            stall(100)
        #endif
        falloutZones.rollReset()
        lightList_N = 0
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
        #ifdef DEBUG
            prinTLOG "portals..."
            stall(100)
        #endif
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
        #ifdef DEBUG
            prinTLOG "legacy effects..."
            stall(100)
        #endif
        graphicFX_->flush()
        #ifdef DEBUG
            prinTLOG "projectiles..."
            stall(100)
        #endif
        link.projectilecollection_ptr->flush()
        #ifdef DEBUG
            prinTLOG "objects..."
            stall(100)
        #endif
        link.dynamiccontroller_ptr->flush()
        windyMistLayers_n = 0
        windyMistLayers = 0
        if curDestBlocks <> 0 then deallocate(curDestBlocks)
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

function level.getLightList(byref lightList_p as LightPair ptr ptr) as integer
    lightList_p = lightList
    return lightList_N
end function

function level.shouldLight() as integer
    return shouldLightObjects
end function

function level.getObjectAmbientLevel() as integer
    return objectAmbientLevel
end function

function level.getHiddenObjectAmbientLevel() as integer
    return hiddenObjectAmbientLevel
end function

sub level.processMist()
    dim as integer i, q
    for i = 0 to windyMistLayers_n - 1
        for q = 0 to windyMistLayers[i].objects_n - 1
            windyMistLayers[i].objects[q].p += Vector2D(-windyMistLayers[i].objects[q].zd, 0)*35
            if windyMistLayers[i].objects[q].p.x < windyMistLayers[i].tl.x then
                windyMistLayers[i].objects[q].p = Vector2D(windyMistLayers[i].br.x, _
                                                           (windyMistLayers[i].br.y - windyMistLayers[i].tl.y)*rnd + windyMistLayers[i].tl.y)  
                windyMistLayers[i].objects[q].zd = windyMistLayers[i].zdepth * (0.9 + rnd*0.2)
            end if
        next q
    next i

end sub

sub level.processLights()
    dim as integer i
    dim as windowCircleIntersectData_t wdata
    dim as Vector2D screen_tl, screen_br
    dim as Vector2D lightP
    dim as double lightR
    dim as integer tex_tl_x, tex_tl_y, tex_br_x, tex_br_y
    dim as integer tl_x, tl_y, br_x, br_y
    dim as integer xscan, yscan
    dim as Level_VisBlock ptr modBlock
    dim as integer row_c, tilePosX, tilePosY
    dim as List ptr curList
    dim as integer ptr curLayer
    dim as integer order, cornerX, cornerY
    dim as integer x0, y0, x1, y1
    dim as integer dposx, dposy
    dim as ObjectSlotSet occluders
        
    lightList_N = link.dynamiccontroller_ptr->populateLightList(lightList)    
    
    screen_tl = link.gamespace_ptr->camera - Vector2D(SCRX, SCRY)*0.5 - Vector2D(128, 128)
    screen_br = link.gamespace_ptr->camera + Vector2D(SCRX, SCRY)*0.5 + Vector2D(128, 128)
    
    for i = 0 to lightList_N - 1
        lightP = Vector2D(lightList[i]->texture.x, lightList[i]->texture.y)
        lightR = lightList[i]->texture.w*0.5 
        if windowCircleIntersect(screen_tl, screen_br, lightP, lightR, wdata) then
            if lightList[i]->occlusion_fbimg <> 0 then
            
                imageSet(lightList[i]->occlusion_fbimg, &hffff00ff, _
                         lightList[i]->last_tl_x, lightList[i]->last_tl_y, _
                         lightList[i]->last_br_x, lightList[i]->last_br_y)
                imageSet(lightList[i]->shaded.diffuse_fbimg, &hff000000, _
                         lightList[i]->last_tl_x, lightList[i]->last_tl_y, _
                         lightList[i]->last_br_x, lightList[i]->last_br_y)
                imageSet(lightList[i]->shaded.specular_fbimg, &hff000000, _
                         lightList[i]->last_tl_x, lightList[i]->last_tl_y, _
                         lightList[i]->last_br_x, lightList[i]->last_br_y)
              
                cornerX = lightList[i]->texture.x - lightList[i]->texture.w*0.5
                cornerY = lightList[i]->texture.y - lightList[i]->texture.h*0.5
                
                tex_tl_x = wdata.tl_x - cornerX
                tex_tl_y = wdata.tl_y - cornerY
                tex_br_x = wdata.br_x - cornerX
                tex_br_y = wdata.br_y - cornerY
                
                if tex_tl_x < 0 then tex_tl_x = 0
                if tex_tl_y < 0 then tex_tl_y = 0
                if tex_br_x >= lightList[i]->texture.w then tex_br_x = lightList[i]->texture.w - 1
                if tex_br_y >= lightList[i]->texture.h then tex_br_y = lightList[i]->texture.h - 1
                
                tl_x = wdata.tl_x shr 4
                tl_y = wdata.tl_y shr 4
                br_x = wdata.br_x shr 4
                br_y = wdata.br_y shr 4		
                
                if tl_x < 0 then tl_x = 0
                if tl_y < 0 then tl_y = 0
                if br_x >= lvlWidth then br_x = lvlWidth - 1
                if br_y >= lvlHeight then br_y = lvlHeight - 1
                
                for order = 0 to 4
                
                    select case order
                    case BACKGROUND
                        curList = @background_layer
                    case ACTIVE
                        curList = @active_layer
                    case FOREGROUND
                        curList = @foreground_layer
                    case ACTIVE_COVER
                        curList = @activeCover_layer
                    case ACTIVE_FRONT
                        curList = @activeFront_layer                    
                    end select
                
                    BEGIN_LIST(curLayer, (*curList))
                        if layerData[*curLayer].occluding < 65535 then
                            for yscan = tl_y to br_y
                                for xscan = tl_x to br_x
                                    modBlock = @(blocks[*curLayer][yscan * lvlWidth + xscan])
                                    if modBlock->tileset < 65535 then
                                        row_c = tilesets[modBlock->tileset].row_count
                                        tilePosX = ((modBlock->tileNum - 1) mod row_c) * 16
                                        tilePosY = ((modBlock->tileNum - 1) \ row_c  ) * 16
                                     
                                        AnyClip(xscan*16 - cornerX, yscan*16 - cornerY, 16, 16,_
                                                tex_tl_x, tex_tl_y, tex_br_x, tex_br_y,_
                                                dposx, dposy,_
                                                x0, y0, x1, y1)
                                                
                                        x0 += tilePosX
                                        y0 += tilePosY
                                        x1 += tilePosX
                                        y1 += tilePosY
 
                                        put lightList[i]->occlusion_fbimg, (dposx, dposy), tilesets[modBlock->tileset].set_image.getData(), (x0, y0)-(x1, y1), TRANS

                                    end if
                                next xscan
                            next yscan
                        end if
                        
                        if (layerData[*curLayer].illuminated < 65535) then
                            if layerData[*curLayer].receiver < 65535 then
                                
                                for yscan = tl_y to br_y
                                    for xscan = tl_x to br_x
                                        modBlock = @(blocks[*curLayer][yscan * lvlWidth + xscan])
                                        if modBlock->tileset < 65535 then
                                            if (modBlock->light(0) <> @(lightList[i]->shaded)) andAlso _
                                               (modBlock->light(1) <> @(lightList[i]->shaded)) andAlso _
                                               (modBlock->light(2) <> @(lightList[i]->shaded)) andAlso modBlock->numLights < 3 then
                                            
                                                modBlock->light(modBlock->numLights) = @(lightList[i]->shaded)
                                                modBlock->numLights += 1
                                            end if
                                        end if
                                    next xscan
                                next yscan          
                            else
                                for yscan = tl_y to br_y
                                    for xscan = tl_x to br_x
                                        modBlock = @(blocks[*curLayer][yscan * lvlWidth + xscan])
                                        if modBlock->tileset < 65535 then
                                            if (modBlock->light(0) <> @(lightList[i]->texture)) andAlso _
                                               (modBlock->light(1) <> @(lightList[i]->texture)) andAlso _
                                               (modBlock->light(2) <> @(lightList[i]->texture)) andAlso modBlock->numLights < 3 then
                                            
                                                modBlock->light(modBlock->numLights) = @(lightList[i]->texture)
                                                modBlock->numLights += 1
                                            end if
                                        end if
                                    next xscan
                                next yscan  
                                                              
                            end if
                        end if
                        
                    END_LIST()	
                next order
                
                link.player_ptr->drawPlayerInto(lightList[i]->occlusion_fbimg, cornerX, cornerY)
                link.dynamiccontroller_ptr->querySlots(occluders, "lightoccluder")
                occluders.throw("dest = " + str(lightList[i]->occlusion_fbimg) + ", x = " + str(cornerX) + ", y = " + str(cornerY))

                
                line lightList[i]->occlusion_fbimg, (lightList[i]->texture.w*0.5 - 4, lightList[i]->texture.h*0.5 - 4)-_
                                                    (lightList[i]->texture.w*0.5 + 4, lightList[i]->texture.h*0.5 + 4),_
                                                    &hffff00ff, BF
                                                                                                                                                    
                pointCastTexture(lightList[i]->shaded.diffuse_fbimg, lightList[i]->shaded.specular_fbimg,_
                                 lightList[i]->texture.diffuse_fbimg, lightList[i]->texture.specular_fbimg,_
                                 lightList[i]->occlusion_fbimg, _
                                 tex_tl_x, tex_tl_y,_
                                 tex_br_x, tex_br_y,_
                                 wdata.dx0, wdata.dy0, _
                                 wdata.dx1, wdata.dy1, _
                                 lightList[i]->texture.w*0.5, lightList[i]->texture.h*0.5,_
                                 lightList[i]->texture.w*0.5, &hffff00ff)
                
            
                lightList[i]->last_tl_x = tex_tl_x
                lightList[i]->last_tl_y = tex_tl_y
                lightList[i]->last_br_x = tex_br_x
                lightList[i]->last_br_y = tex_br_y
            else
                tl_x = wdata.tl_x shr 4
                tl_y = wdata.tl_y shr 4
                br_x = wdata.br_x shr 4
                br_y = wdata.br_y shr 4		
                
                if tl_x < 0 then tl_x = 0
                if tl_y < 0 then tl_y = 0
                if br_x >= lvlWidth then br_x = lvlWidth - 1
                if br_y >= lvlHeight then br_y = lvlHeight - 1
                
                for order = 0 to 4
                    select case order
                    case BACKGROUND
                        curList = @background_layer
                    case ACTIVE
                        curList = @active_layer
                    case FOREGROUND
                        curList = @foreground_layer
                    case ACTIVE_COVER
                        curList = @activeCover_layer
                    case ACTIVE_FRONT
                        curList = @activeFront_layer
                    end select
                
                    BEGIN_LIST(curLayer, (*curList))
                        for yscan = tl_y to br_y
                            for xscan = tl_x to br_x
                                modBlock = @(blocks[*curLayer][yscan * lvlWidth + xscan])
                                if modBlock->tileset < 65535 then
                                    if (modBlock->light(0) <> @(lightList[i]->texture)) andAlso _
                                       (modBlock->light(1) <> @(lightList[i]->texture)) andAlso _
                                       (modBlock->light(2) <> @(lightList[i]->texture)) andAlso modBlock->numLights < 3 then
                                    
                                        modBlock->light(modBlock->numLights) = @(lightList[i]->texture)
                                        modBlock->numLights += 1
                                    end if
                                end if
                            next xscan
                        next yscan
                    END_LIST()	
                next order                   
            end if
        end if        
    next i
             
end sub

function level.getSmokeTexture() as integer ptr
    return smokeTexture
end function

sub level.process(t as double)
    imageSet(smokeTexture, &hFF000000, 0, 0, SCRX-1, SCRY-1)
    processLights()
    if windyMist <> 65535 then processMist()
    if drawAurora then auroraTranslate += 0.007
    fadeOut += fadeDir*0.2
    if fadeOut > 255 then 
        fadeOut = 255
    elseif fadeOut < 0 then 
        fadeOut = 0
    end if
end sub

sub level.drawSmoke(scnbuff as integer ptr)
       
    bitblt_prealpha(scnbuff, 0, 0, smokeTexture, 0, 0, SCRX-1, SCRY-1)
        
end sub

function level.getAmbientLevel(lyr as integer) as integer
    return layerData[lyr].ambientLevel
end function
sub level.setAmbientLevel(lyr as integer, col as integer)
    layerData[lyr].ambientLevel = col
end sub

sub level.setObjectAmbientLevel(col as integer)
    objectAmbientLevel = col
end sub
sub level.setHiddenObjectAmbientLevel(col as integer)    
    hiddenObjectAmbientLevel = col
end sub

sub level.drawBackgroundEffects(scnbuff as integer ptr) 
    if drawAurora <> 65535 then
        drawMode7Ceiling(scnbuff, auroraTexture.getData(), auroraTranslate, auroraTranslate, -20)   
    end if
end sub

function level.getGroup(group_tag as string, byref layer_nums as integer ptr) as integer
    dim as integer members
    dim as integer memberList
    dim as integer i
    dim as integer ptr curInt
    dim as Level_layerGroup ptr lgroup
    group_tag = ucase(group_tag)
    if groups.exists(group_tag) then
        lgroup = groups.retrieve(group_tag)
        members = lgroup->layers->getSize()
        layer_nums = new integer[members]
        i = 0
        BEGIN_LIST(curInt, (*(lgroup->layers)))
            layer_nums[i] = *curInt
            i += 1
        END_LIST()
        return members
    else
        layer_nums = 0
        return 0
    end if
end function

function level.getLayerN() as integer
    return blocks_N
end function

sub level.load(filename as string)
    dim as integer f, i, q, j, s, x, y, xscan, yscan, skipCheck
    dim as TinyBlock block
    dim as ushort lyr
    dim as integer drawless
    dim as uinteger blockNumber, layerInt
    dim as integer row_c, tilePosX, tilePosY, transPxls, checkAllLayers
    dim as string  strdata_n
    dim as string  tempString, groupName
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
    dim as string itemName, itemID, parameterTag, parameterValue
    dim as ushort numParams, numSignals, numTargets
    dim as string signalName, signalParameter, slotID, slotName, saveFileName
    dim as Item ptr itemPtr
    dim as zstring ptr groupStringPtr
    dim as ushort isHidden
    dim as Level_layerGroup ptr curGroup
    dim as integer itemLoadIndex
    dim as PackedBinary serialData
    
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
    get #f,,objField(2)
    get #f,,windyMist
    get #f,,objField(0)
    get #f,,objectAmbientLevel
    get #f,,hiddenObjectAmbientLevel
    get #f,,default_x
    get #f,,default_y
    get #f,,lvlCenterX
    get #f,,lvlCenterY
    get #f,,strdata
    
    link.dynamiccontroller_ptr->setRegionSize(lvlWidth*16, lvlHeight*16)
    
    drawAurora = objField(2)
    
    shouldLightObjects = objField(0)
    if shouldLightObjects = 65535 then shouldLightObjects = 0
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
        
        tilesets[i].row_count = (tilesets[i].set_width / 16)  
        tilesets[i].count = (tilesets[i].set_width / 16) * (tilesets[i].set_height / 16)
      
		#ifdef DEBUG
			printlog strdata
			stall(100)
		#endif
		
        tilesets[i].set_image.load(strdata)

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
            getStringFromFile(f, groupName)
            groupName = ucase(groupName)
            if groupName <> "" then
                groupStringPtr = allocate(len(groupName) + 1)
                *groupStringPtr = groupName
            else
                 groupStringPtr = 0
            end if
            get #f,,isHidden
            get #f,,lyr 
            layerInt = lyr
            layerData[lyr].groupName = groupStringPtr
            layerData[lyr].isHidden = isHidden
            
            if layerData[lyr].groupName <> 0 then
                if groups.exists(*(layerData[lyr].groupName)) then
                    curGroup = groups.retrieve(*(layerData[lyr].groupName))
                else
                    curGroup = new Level_layerGroup
                    curGroup->layers = new List
                    curGroup->layers->init(sizeof(integer))
                    groups.insert(*(layerData[lyr].groupName), curGroup)
                end if
                s = lyr
                curGroup->layers->push_back(@s)
            end if
            get #f,,layerData[lyr].depth
            get #f,,layerData[lyr].parallax
            get #f,,layerData[lyr].inRangeSet
            get #f,,layerData[lyr].isDestructible
            get #f,,layerData[lyr].isFallout
            get #f,,layerData[lyr].illuminated
            get #f,,layerData[lyr].ambientLevel
            get #f,,layerData[lyr].coverage
            get #f,,layerData[lyr].receiver
            get #f,,layerData[lyr].occluding
            layerData[lyr].glow = &hffffffff

            layerData[lyr].windyMistLayer = -1
            if windyMist <> 65535 then
                if layerData[lyr].depth < 1.0 andAlso layerData[lyr].isHidden = LEVEL_OFF then 
                    windyMistLayers_n += 1
                    windyMistLayers = reallocate(windyMistLayers, sizeof(MistLayer_t) * windyMistLayers_n)
                    windyMistLayers[windyMistLayers_n - 1].layerNum = layerInt
                    windyMistLayers[windyMistLayers_n - 1].objects_n = 0
                    windyMistLayers[windyMistLayers_n - 1].objects = 0
                    layerData[lyr].windyMistLayer = windyMistLayers_n - 1
                end if
            end if
            
            select case layerData[lyr].inRangeSet
            case BACKGROUND
                background_layer.push_back(@layerInt)
                if highestLayerIndex <> -1 then
                    if layerData[highestLayerIndex].inRangeSet = BACKGROUND then
                        highestLayerIndex = layerInt
                    end if
                end if
            case ACTIVE
                active_layer.push_back(@layerInt)
                if highestLayerIndex <> -1 then
                    if layerData[highestLayerIndex].inRangeSet = BACKGROUND orElse _
                       layerData[highestLayerIndex].inRangeSet = ACTIVE then
                        highestLayerIndex = layerInt
                    end if
                end if
            case FOREGROUND
                foreground_layer.push_back(@layerInt)
                if highestLayerIndex <> -1 then
                    if layerData[highestLayerIndex].inRangeSet = BACKGROUND orElse _
                       layerData[highestLayerIndex].inRangeSet = ACTIVE orElse _
                       layerData[highestLayerIndex].inRangeSet = ACTIVE_FRONT orElse _
                       layerData[highestLayerIndex].inRangeSet = ACTIVE_COVER orElse _
                       layerData[highestLayerIndex].inRangeSet = FOREGROUND then 
                        highestLayerIndex = layerInt
                    end if
                end if
            case ACTIVE_COVER
				activeCover_layer.push_back(@layerInt)
                if highestLayerIndex <> -1 then
                    if layerData[highestLayerIndex].inRangeSet = BACKGROUND orElse _
                       layerData[highestLayerIndex].inRangeSet = ACTIVE orElse _
                       layerData[highestLayerIndex].inRangeSet = ACTIVE_FRONT orElse _
                       layerData[highestLayerIndex].inRangeSet = ACTIVE_COVER then
                        highestLayerIndex = layerInt
                    end if
                end if
            case ACTIVE_FRONT
 				activeFront_layer.push_back(@layerInt)           
                if highestLayerIndex <> -1 then
                    if layerData[highestLayerIndex].inRangeSet = BACKGROUND orElse _
                       layerData[highestLayerIndex].inRangeSet = ACTIVE orElse _
                       layerData[highestLayerIndex].inRangeSet = ACTIVE_FRONT then
                        highestLayerIndex = layerInt
                    end if
                end if
            end select
            
            if highestLayerIndex = -1 then highestLayerIndex = layerInt
            
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
                blockNumber = blockNumber and FLIPPED_MASK

                blocks[lyr][j].tileset = 65535
                blocks[lyr][j].tilenum = 65535
                blocks[lyr][j].numLights = 0
                'blocks[lyr][j].rotatedType = blockNumber shr 29                
                
                for q = 0 to tilesets_N - 1
                    
                    if blockNumber >= setFirstIds(q) andAlso _
                       blockNumber <  setFirstIds(q) + tilesets[q].count then
                        blocks[lyr][j].tileset = q
                        blocks[lyr][j].tilenum = blockNumber - setFirstIds(q) + 1
                        blocks[lyr][j].usesAnim = 65535
                        blocks[lyr][j].frameDelay = 0
                      
                        if tilesets[q].tileEffect.exists(blocks[lyr][j].tilenum) = 1 then
                            blocks[lyr][j].usesAnim = 1
                        else
                          
                            row_c = tilesets[q].row_count
                            tilePosX = ((blocks[lyr][j].tilenum - 1) mod row_c) * 16
                            tilePosY = ((blocks[lyr][j].tilenum - 1) \ row_c  ) * 16

                        end if
                        
                        exit for
                    end if
                    
                next q
                
            next j
            
        end if
    next i
    
    if windyMist <> 65535 then
        checkAllLayers = 1
        for i = 0 to windyMistLayers_n - 1
            if windyMistLayers[i].layerNum = highestLayerIndex then 
                checkAllLayers = 0
                exit for
            end if
        next i
        if checkAllLayers then
            windyMistLayers_n += 1
            windyMistLayers = reallocate(windyMistLayers, sizeof(MistLayer_t) * windyMistLayers_n)
            windyMistLayers[windyMistLayers_n - 1].layerNum = highestLayerIndex
            windyMistLayers[windyMistLayers_n - 1].objects_n = 0       
            windyMistLayers[windyMistLayers_n - 1].objects = 0
            layerData[highestLayerIndex].windyMistLayer = windyMistLayers_n - 1
        end if
    end if
    
    #ifdef DEBUG
        printlog "Loading objects..."
    #endif
    
    link.tinyspace_ptr->setBlockData(getCollisionLayerData(),_
                                     getWidth(), getHeight(),_
                                     16.0)
    
    loadMapState()
    
    itemLoadIndex = 0 
    get #f,,numObjs
    for i = 0 to numObjs - 1 
        get #f,,tempObj.object_name
        get #f,,tempObj.object_type
        get #f,,tempObj.object_shape
        get #f,,tempObj.inRangeSet
        get #f,,tempObj.p
        get #f,,tempObj.size
        get #f,,tempObj.depth
        get #f,,tempObj.drawless    
        select case tempObj.object_type
        case EFFECT
            get #f,,objField(0)
            get #f,,objField(1)
            get #f,,objField(2) 'minValue
            get #f,,objField(3) 'maxValue
            get #f,,objField(4) 'mode
            get #f,,objField(5) 'fast

            if objField(0) >= LIGHT_EFFECT_VALUE then 
                itemPtr = link.dynamiccontroller_ptr->constructItem(link.dynamiccontroller_ptr->itemStringToType("accent light"), tempObj.inRangeSet)     
                
                if itemPtr then
                    itemPtr->setParameter(cint(objField(0) - LIGHT_EFFECT_VALUE), "flavor")                 
                    itemPtr->setParameter(cdbl(objField(2) / 65535.0), "minValue")
                    itemPtr->setParameter(cdbl(objField(3) / 65535.0), "maxValue")
                    itemPtr->setParameter(cint(objField(4)), "mode")
                    itemPtr->setParameter(cint(objField(5)), "fast")
                    link.dynamiccontroller_ptr->initItem(itemPtr, tempObj.p + tempObj.size*0.5)     
                end if
                
            else
                graphicFX_->create(tempObj.object_name, objField(0),_
                                   tempObj.object_shape, tempObj.p,_
                                   tempObj.size, objField(1),_
                                   tempObj.inRangeSet)
            end if

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
            if link.dynamiccontroller_ptr->isActiveILI(itemLoadIndex) then 
            
                ''''''''''''''''''''''''''''''''
                getStringFromFile(f, itemName)
                getStringFromFile(f, itemID)                
                get #f,,numParams
                for j = 0 to numParams - 1
                    getStringFromFile(f, parameterTag)
                    getStringFromFile(f, parameterValue)
                next j                
                get #f,,numSignals
                for j = 0 to numSignals - 1
                    getStringFromFile(f, signalName)
                    getStringFromFile(f, signalParameter)
                    get #f,,numTargets
                    for q = 0 to numTargets - 1
                        getStringFromFile(f, slotID)
                        getStringFromFile(f, slotName)          
                    next q
                next j
                get #f,,objField(1)
                get #f,,objField(1)
                get #f,,tempSingleField
                '''''''''''''''''''''''''''''''
                        
            else
                getStringFromFile(f, itemName)
                getStringFromFile(f, itemID)
                
                if tempObj.drawless = LEVEL_ON then
                    drawless = 1
                elseif tempObj.drawless = LEVEL_OFF then
                    drawless = 0
                end if
            
                itemPtr = link.dynamiccontroller_ptr->constructItem(link.dynamiccontroller_ptr->itemStringToType(itemName), tempObj.inRangeSet, itemID, drawless, itemLoadIndex)     
                if itemPtr then itemID = itemPtr->getID()
                get #f,,numParams
                for j = 0 to numParams - 1
                    getStringFromFile(f, parameterTag)
                    getStringFromFile(f, parameterValue)
                    if itemPtr then link.dynamiccontroller_ptr->setParameterFromString(parameterValue, itemID, parameterTag)     
                next j
                get #f,,numSignals
                for j = 0 to numSignals - 1
                    getStringFromFile(f, signalName)
                    getStringFromFile(f, signalParameter)
                    get #f,,numTargets
                    for q = 0 to numTargets - 1
                        getStringFromFile(f, slotID)
                        getStringFromFile(f, slotName)          
                        if link.dynamiccontroller_ptr->hasItem(slotID) then
                            if itemPtr then link.dynamiccontroller_ptr->connect(itemID, signalName, slotID, slotName, signalParameter)
                        else
                            if link.dynamiccontroller_ptr->getILIEntry(slotID) = -1 then
                                if itemPtr then link.dynamiccontroller_ptr->connect(itemID, signalName, slotID, slotName, signalParameter)  
                            end if
                        end if
                    next q
                next j
                if itemPtr then link.dynamiccontroller_ptr->initItem(itemPtr, tempObj.p, tempObj.size, tempObj.depth)     

                get #f,,objField(1)
                get #f,,objField(1)
                get #f,,tempSingleField
            end if
        end select
        itemLoadIndex += 1
    next i
   
    
    #ifdef DEBUG
        printlog str(blocks_N) & ", " & tilesets_N
        stall(100)
        printlog "Resolving portals..."
        stall(100)
    #endif
    close #f
    
    curDestBlocks = allocate(sizeof(byte) * lvlWidth * lvlHeight)    
    
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
    
    if windyMist <> 65535 then prepareWindyMistLayers()
    
	#ifdef DEBUG
        printlog "Loading complete!"
        stall(100)
    #endif
end sub

sub level.saveMapState() 
    dim as PackedBinary serialData
    dim as string saveFileName
    dim as integer curFile
    
    saveFileName = SAVE_PATH + ucase(lvlName) + "_STATE.dat"
    if fileexists(saveFileName) then kill saveFileName
    
    curFile = freefile
    open saveFileName for binary as curFile
    
    link.dynamiccontroller_ptr->serialize_out(serialData)
    put #curFile,,cint(serialData.getSize())
    put #curFile,,*cast(byte ptr, serialData.getData()),serialData.getSize()  
    put #curFile,,*curDestBlocks, lvlWidth*lvlHeight
    
    close curFile
end sub
sub level.loadMapState() 
    dim as PackedBinary serialData
    dim as string saveFileName
    dim as integer curFile, dataSize
    
    saveFileName = SAVE_PATH + ucase(lvlName) + "_STATE.dat"
    if fileexists(saveFileName) then 
        curFile = freefile
        open saveFileName for binary as curFile
        
        get #curFile,,dataSize
        serialData.request(dataSize) 
        get #curFile,,*cast(byte ptr, serialData.getData()),dataSize
        link.dynamiccontroller_ptr->serialize_in(serialData)
        
        curDestBlocks = allocate(lvlWidth*lvlHeight*sizeof(byte))
        get #curFile,,*curDestBlocks, lvlWidth*lvlHeight
        
        close curFile
    else
        curDestBlocks = callocate(lvlWidth*lvlHeight, sizeof(byte))
    end if
end sub

sub Level.setHide(lyr as integer)
    layerData[lyr].isHidden = LEVEL_ON
end sub
sub Level.setUnhide(lyr as integer)
    layerData[lyr].isHidden = LEVEL_OFF
end sub
sub Level.setGlow(lyr as integer, glow as integer)
    layerData[lyr].glow = glow
end sub
sub Level.prepareWindyMistLayers()
    dim as integer i, q
    dim as Vector2D lvlCenter, screenDim, newPos
    lvlCenter = Vector2D(lvlWidth, lvlHeight) * 8
    screenDim = Vector2D(SCRX, SCRY)
    for i = 0 to windyMistLayers_n - 1
        windyMistLayers[i].zdepth = layerData[windyMistLayers[i].layerNum].depth
        windyMistLayers[i].objects_n = MIST_OBJECTS_PER_LAYER
        windyMistLayers[i].objects = allocate(windyMistLayers[i].objects_n * sizeof(MistObject_t))
        windyMistLayers[i].tl = (lvlCenter - screenDim*0.5) * (1 - layerData[windyMistLayers[i].layerNum].depth) - Vector2D(mistTexture.getWidth(), mistTexture.getHeight())
        windyMistLayers[i].br = (lvlCenter + screenDim*0.5) + (lvlCenter*2 - (lvlCenter + screenDim*0.5)) * layerData[windyMistLayers[i].layerNum].depth
        for q = 0 to windyMistLayers[i].objects_n - 1
            newPos = windyMistLayers[i].br - windyMistLayers[i].tl
            newPos = Vector2D(newPos.x * rnd, newPos.y * rnd) + windyMistLayers[i].tl
            windyMistLayers[i].objects[q].p = newPos
            windyMistLayers[i].objects[q].zd = windyMistLayers[i].zdepth * (0.9 + rnd*0.2)
        next q
    next i
end sub

sub Level.overrideCurrentMusicFile(filename as string)
	loadedMusic = filename
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
		a.setX(_max_(tempPortal->a.x(), p.x()))
		a.setY(_max_(tempPortal->a.y(), p.y()))
		b.setX(_min_(tempPortal->b.x(), p.x() + w))
		b.setY(_min_(tempPortal->b.y(), p.y() + h))
		area1 = (b.x() - a.x()) * (b.y() - a.y())
		area2 = w * h
		if area1 / area2 >= coverage then
			l.fileName = *(tempPortal->to_map)' + ".map"
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
