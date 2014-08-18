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
end constructor

sub FBGDTriggerDispatch.setLink(link_ as objectLink)
	link = link_
end sub

sub FBGDTriggerDispatch.process(t as double)
	dim as LevelSwitch_t ls
	dim as PortalType_t pt
	if link.player_ptr->health <= 0 then
		link.player_ptr->health = 100
		if link.gamespace_ptr->getLastFileName() <> link.gamespace_ptr->getCurrentFileName() then
			ls.fileName = link.gamespace_ptr->getLastFileName()
			link.gamespace_ptr->switchRegions(ls)
		end if
		link.player_ptr->body.p = link.gamespace_ptr->getLastPosition()
		link.player_ptr->harmedFlashing = 48
		if phase = 0 then
			link.player_ptr->bombs = 10
			link.player_ptr->facing = 1
		end if
	
	end if
	if phase = 0 then
		'210x17
		
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
	
	end if
end sub

