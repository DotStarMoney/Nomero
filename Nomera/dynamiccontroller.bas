#include "dynamiccontroller.bi"
#include "tinyspace.bi"
#include "enemy.bi"
#include "utility.bi"
#include "soundeffects.bi"
#include "gamespace.bi"
#include "item.bi"

#define N_OBJ_TYPES 4

dim as NamesTypes_t ptr DynamicController.namesTypesTable = 0
dim as integer          DynamicController.hasFilledTable = 0

constructor NamesTypes_t(name_p as string, type_p as DynamicObjectType_e)
	this.name_ = name_p
	this.type_ = type_p
end constructor

constructor DynamicController
	if hasFilledTable = 0 then
		hasFilledTable = 1
		namesTypesTable = allocate(sizeof(NamesTypes_t) * N_OBJ_TYPES)
		namesTypesTable[0] = NamesTypes_t("SOLDIER 1", OBJ_ENEMY)
		namesTypesTable[1] = NamesTypes_t("SOLDIER 2", OBJ_ENEMY)
		namesTypesTable[2] = NamesTypes_t("BEAR", OBJ_ENEMY)
	end if
	objects.init(sizeof(DynamicObjectType_t))
	spawnZones.init(sizeof(SpawnZone_t))
end constructor

destructor DynamicController
	flush()
end destructor

sub DynamicController.flush()
	dim as SpawnZone_t ptr         szptr
	dim as DynamicObjectType_t ptr dynObj
	dim as Item ptr curItem

	spawnZones.rollReset()
	do
		szptr = spawnZones.roll()
		if szptr <> 0 then
			deallocate(szptr->spawn_objectName)
		else
			exit do
		end if
	loop
	spawnZones.flush()
	
	
	objects.rollReset()
	do
		dynObj = objects.roll()
		if dynObj <> 0 then
			if dynObj->object_type = OBJ_ENEMY then
				link.tinyspace_ptr->removeBody(cast(Enemy ptr, dynObj->data_)->body_i)
				delete (cast(Enemy ptr, dynObj->data_))
            elseif dynObj->object_type = OBJ_ITEM then
                'BOMB MEMORY, dont delete what should hang around
                curItem = dynObj->data_
                delete(curItem)

			end if
		else
			exit do
		end if
	loop
	objects.flush()

end sub

sub DynamicController.setLink(link_ as ObjectLink)
	link = link_
end sub

sub DynamicController.explosionAlert(p as Vector2D)
	dim as DynamicObjectType_t ptr dobj
	objects.rollReset()
	do
		dobj = objects.roll()
		if dobj <> 0 then
			if dobj->object_type = OBJ_ENEMY then
				cast(Enemy ptr, dobj->data_)->explosionAlert(p)
			end if
		else
			exit do
		end if
	loop
end sub

function DynamicController.populateLightList(ll as LightPair ptr ptr) as integer
    dim as DynamicObjectType_t ptr dobj
    dim as Item ptr ditem
    dim as ListNodeRoll_t tempR
    dim as integer nlights
    dim as LightPair ptr lp
    dim as Vector2d scn_a, scn_b
    dim as Vector2d light_a, light_b
    
    scn_a = link.gamespace_ptr->camera - Vector2D(SCRX, SCRY)*0.5
    scn_b = link.gamespace_ptr->camera + Vector2D(SCRX, SCRY)*0.5
    
    nlights = 0
    
    tempR = objects.bufferRoll()
    
    BEGIN_LIST(dobj, objects)
    
        if dobj->object_type = OBJ_ITEM then
            ditem = cast(Item ptr, dobj->data_)
            if ditem->hasLight() then
            
                lp = ditem->getLightingData()
                light_a = Vector2D(lp->texture.x, lp->texture.y) - Vector2D(lp->texture.w, lp->texture.h)*0.5 - Vector2D(128, 128)
                light_b = Vector2D(lp->texture.x, lp->texture.y) + Vector2D(lp->texture.w, lp->texture.h)*0.5 + Vector2D(128, 128)
                
                if (light_a.x < scn_b.x) andAlso (light_b.x > scn_a.x) andAlso _
                   (light_a.y < scn_b.y) andAlso (light_b.y > scn_a.y) then

                    ll[nlights] = lp
                    nlights += 1
                end if
                
            end if
        end if
        
    END_LIST()
    objects.setRoll(tempR)
    return nlights
end function

sub DynamicController.addSpawnZone(objectName as string,_
								   respawn as SpawnZoneDespawnType_e,_
								   p as Vector2D, size as Vector2D,_
								   count_ as integer = 1,_
								   time_ as integer = 0)
	dim as SpawnZone_t         zone
	dim as DynamicObjectType_e objType
	dim as integer i
	objType = OBJ_NONE
	for i = 0 to N_OBJ_TYPES - 1
		if ucase(objectName) = namesTypesTable[i].name_ then
			objType = namesTypesTable[i].type_
			exit for
		end if
	next i
	if objType = OBJ_NONE then exit sub
	
	zone.hasMember = 0
	zone.spawn_time  = time_
	zone.spawn_count = count_
	zone.isNew       = 1
	zone.spawn_objectName = allocate(len(objectName) + 1)
	*(zone.spawn_objectName) = objectName
	zone.spawn_respawn = respawn
	zone.spawn_type = objType
	zone.p = p
	zone.size = size

	spawnZones.push_back(@zone)
								   
end sub

function DynamicController.addOneItem(position as Vector2D, itemType_ as Item_Type_e, itemFlavor_ as integer,_
                                      minValue as double, maxValue as double, mode as integer) as Item ptr
	dim as Item ptr curItem
	dim as DynamicObjectType_t dobj

	curItem = new Item
	curItem->setLink(link)
	curItem->init(itemType_, itemFlavor_)
    curItem->setPos(position)
    curItem->setLightModeData(minValue, maxValue, mode)
	
	dobj.object_type = OBJ_ITEM
	dobj.data_ = curItem
	
	objects.push_back(@dobj)
	
	return dobj.data_
    
end function

sub DynamicController.addEnemy(sz as SpawnZone_t)
	dim as string objName
	dim as Enemy ptr newEnemy
	dim as DynamicObjectType_t dobj
	
	objName = ucase(*(sz.spawn_objectName))
	
	newEnemy = new Enemy
	newEnemy->setParent(link.tinyspace_ptr, link.level_ptr,_
	                    link.projectilecollection_ptr,_
	                    link.gamespace_ptr,_
	                    link.player_ptr)            
	
	select case objName
	case "SOLDIER 1"
		newEnemy->loadType(SOLDIER_1)
	case "SOLDIER 2"
		newEnemy->loadType(SOLDIER_2)
	case "BEAR"
		newEnemy->loadType(BEAR)
	end select
	
	newEnemy->body.r = 18
    newEnemy->body.m = 5
    newEnemy->body.p = Vector2D(sz.p.x() + sz.size.x() * 0.5,_
                                sz.p.y() + sz.size.y() - newEnemy->body.r)
    newEnemy->body.friction = 2        
	newEnemy->body_i = link.tinyspace_ptr->addBody(@(newEnemy->body))
           
	dobj.object_type = OBJ_ENEMY
	dobj.data_ = newEnemy

	newEnemy->setLink(link)

	objects.push_back(@dobj)
end sub

sub DynamicController.addItem(sz as SpawnZone_t)

end sub
								   
sub DynamicController.process(t as double)
	dim as SpawnZone_t ptr szptr
	dim as DynamicObjectType_t ptr dobj
	dim as Enemy ptr enemyDelete
	dim as Item ptr curItem
	dim as integer spawnOne, shouldDelete, i
	dim as ListNodeRoll_t lnr

	spawnZones.rollReset()
	do
		szptr = spawnZones.roll()
		spawnOne = 0
		if szptr <> 0 then
			if szptr->isNew = 1 then
				szptr->isNew = 0
				spawnOne = 1
			end if
			'run despawn logic on enemy death flag (hasMember = 0)
			
			if spawnOne = 1 andAlso szptr->hasMember = 0 then
				szptr->hasMember = 1
				select case szptr->spawn_type
				case OBJ_ENEMY
					addEnemy(*szptr)			
				case OBJ_ITEM
					'addItem(*szptr)
				end select
			end if
		else
			exit do
		end if
	loop
	
	objects.rollReset()
	do
		dobj = objects.roll()
		if dobj <> 0 then
			if dobj->object_type = OBJ_ENEMY then
				lnr = objects.bufferRoll()
				shouldDelete = cast(Enemy ptr, dobj->data_)->process(t)
				objects.setRoll(lnr)
				if shouldDelete = 1 then
					for i = 0 to 3
						link.oneshoteffects_ptr->create(cast(Enemy ptr, dobj->data_)->body.p + Vector2D(rnd * 48 - 24, rnd * 48 - 24),SMOKE,Vector2D(0,-2))
						link.projectilecollection_ptr->create(cast(Enemy ptr, dobj->data_)->body.p, Vector2D(rnd*2 - 1, -1) * (300 + rnd*300), HEART)
					next i
					link.soundeffects_ptr->playSound(SND_DEATH)
					link.tinyspace_ptr->removeBody(cast(Enemy ptr, dobj->data_)->body_i)
					delete (cast(Enemy ptr, dobj->data_))
					objects.rollRemove()
				end if
				
			elseif dobj->object_type = OBJ_ITEM then
				curItem = dobj->data_
				
				lnr = objects.bufferRoll()
				shouldDelete = curItem->process(t)
				objects.setRoll(lnr)
                
				if shouldDelete then
					delete (cast(Item ptr, dobj->data_))
					objects.rollRemove()
				end if
			end if
		else
			exit do
		end if
	loop
	
	
end sub

sub DynamicController.drawDynamics(scnbuff as integer ptr, order as integer = 0)
	dim as DynamicObjectType_t ptr dobj
	
	objects.rollReset()
	do
		dobj = objects.roll()
		if dobj <> 0 then
			if dobj->object_type = OBJ_ENEMY then
				if order = 1 then
					cast(Enemy ptr, dobj->data_)->drawEnemy(scnbuff)
				end if
			elseif dobj->object_type = OBJ_ITEM then
				if order = 2 then
					cast(Item ptr, dobj->data_)->drawItem(scnbuff)
				elseif order = 0 then
					cast(Item ptr, dobj->data_)->drawItemTop(scnbuff)
				end if
			end if
		else
			exit do
		end if
	loop
	
end sub

