#include "fbgdtriggerdispatch.bi"
#include "gamespace.bi"
#include "level.bi"
#include "player.bi"
#include "leveltypes.bi"

constructor FBGDTriggerDispatch
	dim as integer i
	phase = 0
	for i = 0 to ubound(dPoints)
		dPoints(i) = 0
	next i
	completed = 0
	setOnceOxy = 0
end constructor

sub FBGDTriggerDispatch.setLink(link_ as objectLink)
	link = link_
end sub

sub FBGDTriggerDispatch.draw_(scnbuff as integer ptr)
	if phase = 4 andAlso link.gamespace_ptr->shouldBail <> 1 then
		
		drawStringShadow(scnbuff, SCRX * 0.5 - 50, SCRY * 0.5 - 8,_
						 "OXYGEN", &hffffff)
		drawStringShadow(scnbuff, SCRX * 0.5 + 10, SCRY * 0.5 - 8,_
						 str(int(oxygen / 10)), &hffffff)
	end if
end sub

sub FBGDTriggerDispatch.process(t as double)
	dim as LevelSwitch_t ls
	dim as PortalType_t pt
	dim as integer i, vol
	
	if link.player_ptr->health <= 0 then
		link.player_ptr->health = 100
		if link.gamespace_ptr->getLastFileName() <> link.gamespace_ptr->getCurrentFileName() then
			ls.fileName = link.gamespace_ptr->getLastFileName()
			link.gamespace_ptr->switchRegions(ls)
		end if
		link.player_ptr->centerToMap(link.gamespace_ptr->getLastPosition())
		link.player_ptr->harmedFlashing = 48
		link.soundeffects_ptr->playSound(SND_DEATH)
		if phase = 0 then
			link.player_ptr->bombs = 10
			link.player_ptr->facing = 1
		elseif phase = 1 then
			link.player_ptr->bombs = 10
			link.player_ptr->facing = 1		
		elseif phase = 2 then
			link.player_ptr->bombs = 10
			link.player_ptr->facing = 0		
		elseif phase = 3 then
			link.player_ptr->bombs = 10
			link.player_ptr->facing = 1		
		elseif phase = 1 then
			link.player_ptr->facing = 0			
		end if
	
	end if
	if phase = 0 then
		'210x17
		if link.level_ptr->getName() = "Mountain Level" then 
		    link.gamespace_ptr->lastSpawn = link.level_ptr->getDefaultPos()
			link.gamespace_ptr->lastMap = link.level_ptr->getName()
			phase = 1
			for i = 0 to ubound(dPoints)
				dPoints(i) = 0
			next i
			completed = 0
			link.player_ptr->bombs = 10
		end if
		
		if link.level_ptr->getName() = "PurovskyDistrict Scene 2 Outside" then
			if link.level_ptr->checkDestroyedBlocks(210, 17) then dPoints(0) = 1
		elseif link.level_ptr->getName() = "PurovskyDistrict Scene 3 Inside" then
			if link.level_ptr->checkDestroyedBlocks(10, 15) then dPoints(1) = 1
			if link.level_ptr->checkDestroyedBlocks(21, 16) then dPoints(2) = 1
		end if
		
		if dPoints(0) = 1 andAlso dPoints(1) = 1 andAlso dPoints(2) = 1 then
			if link.level_ptr->getName() = "PurovskyDistrict Scene 3 Inside" then
				if link.level_ptr->justLoaded = 1 orElse completed = 0 then
					if link.level_ptr->justLoaded = 1 then
						link.level_ptr->overrideCurrentMusicFile("RadioStatic 2.ogg")
					else
						link.gamespace_ptr->hardSwitchMusic("RadioStatic 2.ogg")
					end if
					link.level_ptr->justLoaded = 0
					
					link.effectcontroller_ptr->create("speaker left", ACTIVE_SPEAKER, _
													  RECTANGLE,_
													  Vector2D(32,160), Vector2D(0,0),_
													  0, ACTIVE)
					link.effectcontroller_ptr->create("speaker right", ACTIVE_SPEAKER, _
													  RECTANGLE,_
													  Vector2D(496,160), Vector2D(0,0),_
													  1, ACTIVE)
					link.effectcontroller_ptr->create("open door", OPEN_DOOR, _
													  RECTANGLE,_
													  Vector2D(464,224), Vector2D(0,0),_
													  1, ACTIVE)								  
					pt.to_map = allocate(len("Mountain Level") + 1)
					*(pt.to_map) = "Mountain Level"
					pt.to_portal = allocate(len("default") + 1)
					*(pt.to_portal) = "default"
					pt.direction = D_IN
					pt.a = Vector2D(464,224)
					pt.b = Vector2D(464,224) + Vector2D(32,64)
					pt.portal_name = 0
					link.level_ptr->addPortal(pt)
				end if
			end if
			completed = 1
		end if
		link.level_ptr->justLoaded = 0
		
	elseif phase = 1 then
	
		if link.level_ptr->getName() = "Mine Scene 1" then 
		    link.gamespace_ptr->lastSpawn = link.level_ptr->getDefaultPos()
			link.gamespace_ptr->lastMap = link.level_ptr->getName()
			phase = 2
			for i = 0 to ubound(dPoints)
				dPoints(i) = 0
			next i
			completed = 0
			link.player_ptr->bombs = 10
		end if
		
		if link.level_ptr->getName() = "Mountain Level Scene 2" then
			if link.level_ptr->checkDestroyedBlocks(115, 14) then dPoints(0) = 1
		elseif link.level_ptr->getName() = "Number Station 2" then
			if link.level_ptr->checkDestroyedBlocks(31, 6) then dPoints(1) = 1
			if link.level_ptr->checkDestroyedBlocks(24, 7) then dPoints(2) = 1
			if link.level_ptr->checkDestroyedBlocks(20, 15) then dPoints(3) = 1
			if link.level_ptr->checkDestroyedBlocks(20, 34) then dPoints(4) = 1
		end if
		
		if dPoints(0) = 1 andAlso dPoints(1) = 1 andAlso dPoints(2) = 1  andAlso _
		   dPoints(3) = 1 andAlso dPoints(4) = 1 then
			if link.level_ptr->getName() = "Number Station 2" then
				if link.level_ptr->justLoaded = 1 orElse completed = 0 then
					if link.level_ptr->justLoaded = 1 then
						link.level_ptr->overrideCurrentMusicFile("RadioStatic 2.ogg")
					else
						link.gamespace_ptr->hardSwitchMusic("RadioStatic 2.ogg")
					end if
					link.level_ptr->justLoaded = 0
					
					link.effectcontroller_ptr->create("speaker left", ACTIVE_SPEAKER, _
													  RECTANGLE,_
													  Vector2D(32,32), Vector2D(0,0),_
													  0, ACTIVE)
					link.effectcontroller_ptr->create("speaker right", ACTIVE_SPEAKER, _
													  RECTANGLE,_
													  Vector2D(416,32), Vector2D(0,0),_
													  1, ACTIVE)
					link.effectcontroller_ptr->create("speaker left", ACTIVE_SPEAKER, _
													  RECTANGLE,_
													  Vector2D(32,640), Vector2D(0,0),_
													  0, ACTIVE)								  
					link.effectcontroller_ptr->create("open door", OPEN_DOOR, _
													  RECTANGLE,_
													  Vector2D(48,704), Vector2D(0,0),_
													  1, ACTIVE)								  
					pt.to_map = allocate(len("Mine Scene 1") + 1)
					*(pt.to_map) = "Mine Scene 1"
					pt.to_portal = allocate(len("default") + 1)
					*(pt.to_portal) = "default"
					pt.direction = D_IN
					pt.a = Vector2D(48,704)
					pt.b = Vector2D(48,704) + Vector2D(32,64)
					pt.portal_name = 0
					link.level_ptr->addPortal(pt)
				end if
			end if
			completed = 1
		end if
		link.level_ptr->justLoaded = 0
	elseif phase = 2 then
		
		if link.level_ptr->getName() = "Woodpecker Level" then 
		    link.gamespace_ptr->lastSpawn = link.level_ptr->getDefaultPos()
			link.gamespace_ptr->lastMap = link.level_ptr->getName()
			phase = 3
			for i = 0 to ubound(dPoints)
				dPoints(i) = 0
			next i
			completed = 0
			link.player_ptr->bombs = 10
		end if
		
		
		if link.level_ptr->getName() = "Mine Scene 1" then
			if link.level_ptr->checkDestroyedBlocks(8, 22) then dPoints(0) = 1
		elseif link.level_ptr->getName() = "Number Station (Cave)" then
			if link.level_ptr->checkDestroyedBlocks(6, 7) then dPoints(1) = 1
			if link.level_ptr->checkDestroyedBlocks(16, 8) then dPoints(2) = 1
			if link.level_ptr->checkDestroyedBlocks(22, 17) then dPoints(3) = 1
		end if
		
		if dPoints(0) = 1 andAlso dPoints(1) = 1 andAlso dPoints(2) = 1  andAlso _
		   dPoints(3) = 1 then
			if link.level_ptr->getName() = "Number Station (Cave)" then
				if link.level_ptr->justLoaded = 1 orElse completed = 0 then
					if link.level_ptr->justLoaded = 1 then
						link.level_ptr->overrideCurrentMusicFile("RadioStatic 2.ogg")
					else
						link.gamespace_ptr->hardSwitchMusic("RadioStatic 2.ogg")
					end if
					
					link.effectcontroller_ptr->create("speaker left", ACTIVE_SPEAKER, _
													  RECTANGLE,_
													  Vector2D(896,32), Vector2D(0,0),_
													  0, ACTIVE)								  
				
				end if
			elseif link.level_ptr->getName() = "Mine Scene 1" then
				if link.level_ptr->justLoaded = 1 orElse completed = 0 then
					if link.level_ptr->justLoaded = 1 then
						link.level_ptr->overrideCurrentMusicFile("RadioStatic 2.ogg")
					else
						link.gamespace_ptr->hardSwitchMusic("RadioStatic 2.ogg")
					end if
					link.effectcontroller_ptr->create("speaker left", ACTIVE_SPEAKER, _
													  RECTANGLE,_
													  Vector2D(176,912), Vector2D(0,0),_
													  0, ACTIVE)
					link.effectcontroller_ptr->create("speaker right", ACTIVE_SPEAKER, _
													  RECTANGLE,_
													  Vector2D(800,800), Vector2D(0,0),_
													  1, ACTIVE)
					link.effectcontroller_ptr->create("open door", OPEN_DOOR, _
													  RECTANGLE,_
													  Vector2D(880,960), Vector2D(0,0),_
													  1, ACTIVE)			
					
					pt.to_map = allocate(len("Woodpecker Level") + 1)
					*(pt.to_map) = "Woodpecker Level"
					pt.to_portal = allocate(len("default") + 1)
					*(pt.to_portal) = "default"
					pt.direction = D_IN
					pt.a = Vector2D(880,960)
					pt.b = Vector2D(880,960) + Vector2D(32,64)
					pt.portal_name = 0
					link.level_ptr->addPortal(pt)
					
				end if
			end if
			completed = 1
		end if
		link.level_ptr->justLoaded = 0
	elseif phase = 3 then
		
		if link.level_ptr->getName() = "Space Level" then 
			link.gamespace_ptr->setMusicVolume(0)
		    link.gamespace_ptr->lastSpawn = link.level_ptr->getDefaultPos()
			link.gamespace_ptr->lastMap = link.level_ptr->getName()
			phase = 4
			for i = 0 to ubound(dPoints)
				dPoints(i) = 0
			next i
			completed = 0
			oxygen = 1000
			link.player_ptr->bombs = 10
		end if
		
		
		if link.level_ptr->getName() = "Woodpecker Level" then
			if link.level_ptr->checkDestroyedBlocks(145, 19) then dPoints(0) = 1
		elseif link.level_ptr->getName() = "Woodpecker Number Station" then
			if link.level_ptr->checkDestroyedBlocks(35, 14) then dPoints(1) = 1
			if link.level_ptr->checkDestroyedBlocks(23, 14) then dPoints(2) = 1
			if link.level_ptr->checkDestroyedBlocks(13, 11) then dPoints(3) = 1
		end if
		
		if dPoints(0) = 1 andAlso dPoints(1) = 1 andAlso dPoints(2) = 1  then
			if link.level_ptr->getName() = "Woodpecker Number Station" then
				if link.level_ptr->justLoaded = 1 orElse completed = 0 then
					if link.level_ptr->justLoaded = 1 then
						link.level_ptr->overrideCurrentMusicFile("RadioStatic 2.ogg")
					else
						link.gamespace_ptr->hardSwitchMusic("RadioStatic 2.ogg")
					end if
					link.level_ptr->justLoaded = 0
					
					link.effectcontroller_ptr->create("speaker left", ACTIVE_SPEAKER, _
													  RECTANGLE,_
													  Vector2D(32,32), Vector2D(0,0),_
													  0, ACTIVE)
					link.effectcontroller_ptr->create("speaker right", ACTIVE_SPEAKER, _
													  RECTANGLE,_
													  Vector2D(736,32), Vector2D(0,0),_
													  1, ACTIVE)
										
													  							  
					if dPoints(3) = 0 then
						link.effectcontroller_ptr->removeEffect("teleporter shield")
						link.effectcontroller_ptr->create("teleport shimmer", SHIMMER,_
														  RECTANGLE,_
														  Vector2D(9, 11) * 16,_
														  Vector2D(3, 3) * 16,_
														  0.01, ACTIVE)		
					    link.effectcontroller_ptr->create("teleport shimmer 2", SHIMMER,_
														  RECTANGLE,_
														  Vector2D(9, 11) * 16,_
														  Vector2D(3, 3) * 16,_
														  0.01, ACTIVE)						  
					end if
													  		
										  
					pt.to_map = allocate(len("Space Level") + 1)
					*(pt.to_map) = "Space Level"
					pt.to_portal = allocate(len("default") + 1)
					*(pt.to_portal) = "default"
					pt.direction = D_LEFT
					pt.a = Vector2D(9, 11) * 16
					pt.b = Vector2D(9, 11) * 16 + Vector2D(48, 64)
					pt.portal_name = 0
					link.level_ptr->addPortal(pt)
					
				end if
			end if
			completed = 1
		end if
		link.level_ptr->justLoaded = 0
	elseif phase = 4 then
		if setOnceOxy = 0 then
			setOnceOxy = 1
			oxygen = 1000
		end if
		vol = (_max_(1300 - (link.player_ptr->body.p.x() + 200), 64.0) / 1300.0) * 255
		link.gamespace_ptr->setMusicVolume(vol)
		oxygen -= 1
		if oxygen < 0 then oxygen = 0
		if link.level_ptr->checkDestroyedBlocks(7, 13) then 
			link.gamespace_ptr->setMusicVolume(0)
			link.gamespace_ptr->winStatus = 1
			link.gamespace_ptr->shouldBail = 1
			link.gamespace_ptr->lockAction = 1
		elseif oxygen <= 0 then
			link.gamespace_ptr->shouldBail = 2
			link.gamespace_ptr->lockAction = 1
		end if
	end if
end sub

