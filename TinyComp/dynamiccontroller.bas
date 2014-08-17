#include "dynamiccontroller.bi"
#include "tinyspace.bi"
#include "enemy.bi"
#include "utility.bi"

#define N_OBJ_TYPES 3

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
	objects.push_back(@dobj)
end sub

sub DynamicController.addItem(sz as SpawnZone_t)

end sub
								   
sub DynamicController.process(t as double)
	dim as SpawnZone_t ptr szptr
	dim as DynamicObjectType_t ptr dobj
	dim as Enemy ptr enemyDelete
	dim as integer spawnOne, shouldDelete, i
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
					addItem(*szptr)
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
				shouldDelete = cast(Enemy ptr, dobj->data_)->process(t)
				if shouldDelete = 1 then
					for i = 0 to 3
						link.oneshoteffects_ptr->create(cast(Enemy ptr, dobj->data_)->body.p + Vector2D(rnd * 48 - 24, rnd * 48 - 24),SMOKE,Vector2D(0,-2))
						link.projectilecollection_ptr->create(cast(Enemy ptr, dobj->data_)->body.p, Vector2D(rnd*2 - 1, -1) * (300 + rnd*300), HEART)
					next i
					
					link.tinyspace_ptr->removeBody(cast(Enemy ptr, dobj->data_)->body_i)
					delete (cast(Enemy ptr, dobj->data_))
					objects.rollRemove()
				end if
			elseif dobj->object_type = OBJ_ITEM then
				'process items
			end if
		else
			exit do
		end if
	loop
end sub

sub DynamicController.drawDynamics(scnbuff as integer ptr)
	dim as DynamicObjectType_t ptr dobj
	objects.rollReset()
	do
		dobj = objects.roll()
		if dobj <> 0 then
			if dobj->object_type = OBJ_ENEMY then
				cast(Enemy ptr, dobj->data_)->drawEnemy(scnbuff)
			elseif dobj->object_type = OBJ_ITEM then
				'draw items
			end if
		else
			exit do
		end if
	loop
end sub

