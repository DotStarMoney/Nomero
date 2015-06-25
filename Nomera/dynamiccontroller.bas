#include "dynamiccontroller.bi"
#include "tinyspace.bi"
#include "utility.bi"
#include "soundeffects.bi"
#include "gamespace.bi"
#include "item.bi"
#include "constants.bi"

#include "objects\headers\gen_namestypestable.bi"

constructor NamesTypes_t(name_p as string, type_p as DynamicObjectType_e, itemNumber_p as Item_Type_e)
	this.name_ = name_p
	this.type_ = type_p
    this.itemNumber_ = itemNumber_p
end constructor

constructor DynamicController
	objects_active.init(sizeof(DynamicObjectType_t))
    objects_activefront.init(sizeof(DynamicObjectType_t))
	spawnZones.init(sizeof(SpawnZone_t))
end constructor

destructor DynamicController
	flush()
end destructor

sub DynamicController.flush()
	dim as SpawnZone_t ptr         szptr
	dim as DynamicObjectType_t ptr dynObj
	dim as Item ptr curItem
    dim as List ptr objectList
    dim as integer i
    
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
	
	for i = 0 to 1
        select case i
        case 0
            objectList = @objects_active
        case 1
            objectList = @objects_activefront
        end select
   
    
        objectList->rollReset()
        do
            dynObj = objectList->roll()
            if dynObj <> 0 then
                if dynObj->object_type = OBJ_ITEM then
                    'BOMB MEMORY, dont delete what should hang around
                    curItem = dynObj->data_
                    delete(curItem)

                end if
            else
                exit do
            end if
        loop
        objectList->flush()
    next i

end sub

sub DynamicController.setLink(link_ as ObjectLink)
	link = link_
end sub

function DynamicController.populateLightList(ll as LightPair ptr ptr) as integer
    dim as DynamicObjectType_t ptr dobj
    dim as Item ptr ditem
    dim as ListNodeRoll_t tempR
    dim as integer nlights, i
    dim as List ptr objectList
    dim as LightPair ptr lp
    dim as Vector2d scn_a, scn_b
    dim as Vector2d light_a, light_b
    
    scn_a = link.gamespace_ptr->camera - Vector2D(SCRX, SCRY)*0.5
    scn_b = link.gamespace_ptr->camera + Vector2D(SCRX, SCRY)*0.5
    
    nlights = 0
    
    for i = 0 to 1
        select case i
        case 0
            objectList = @objects_active
        case 1
            objectList = @objects_activefront
        end select
    
        tempR = objectList->bufferRoll()
        BEGIN_LIST(dobj, (*objectList))

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
        objectList->setRoll(tempR)
        
    next i
   
    return nlights
end function

sub DynamicController.addSpawnZone(objectName as string,_
                                   flavor as integer,_
								   respawn as SpawnZoneDespawnType_e,_
								   p as Vector2D, size as Vector2D,_
								   count_ as integer = 1,_
								   time_ as integer = 0)
	dim as SpawnZone_t         zone
	dim as DynamicObjectType_e objType
	dim as integer i
	objType = OBJ_NONE
	for i = 0 to N_OBJ_TYPES - 1
		if ucase(objectName) = namesTypesTable(i).name_ then
			objType = namesTypesTable(i).type_
			exit for
		end if
	next i
	if objType = OBJ_NONE then exit sub
	
    zone.itemNumber = namesTypesTable(i).itemNumber_
    zone.flavor = flavor
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
                                      minValue as double, maxValue as double, mode as integer, fast as integer, order as orderType = ACTIVE) as Item ptr
	dim as Item ptr curItem
	dim as DynamicObjectType_t dobj

	curItem = new Item
	curItem->setLink(link)    
	curItem->init(itemType_, itemFlavor_, fast)    
    curItem->setPos(position)   
    curItem->setLightModeData(minValue, maxValue, mode)
	
	dobj.object_type = OBJ_ITEM
	dobj.data_ = curItem
    dobj.order = order
	
    if order = ACTIVE then
        objects_active.push_back(@dobj)
    elseif order = ACTIVE_FRONT then
        objects_activefront.push_back(@dobj)
    end if
	
	return dobj.data_
    
end function



sub DynamicController.addItem(sz as SpawnZone_t)
	dim as Item ptr curItem
	dim as DynamicObjectType_t dobj

	curItem = new Item
	curItem->setLink(link)
	curItem->init(sz.itemNumber, sz.flavor, 0)
    curItem->setPos(sz.p)
    curItem->setSize(sz.size)
    	
	dobj.object_type = OBJ_ITEM
	dobj.data_ = curItem
    dobj.order = ACTIVE
	
	objects_active.push_back(@dobj)
	   
end sub
								   
sub DynamicController.process(t as double)
	dim as SpawnZone_t ptr szptr
	dim as DynamicObjectType_t ptr dobj
	dim as Item ptr curItem
	dim as integer spawnOne, shouldDelete, i
	dim as ListNodeRoll_t lnr
    dim as List ptr objectList

	spawnZones.rollReset()
	do
		szptr = spawnZones.roll()
		spawnOne = 0
		if szptr <> 0 then
			if szptr->isNew = 1 then
				szptr->isNew = 0
				spawnOne = 1
			end if
			
			if spawnOne = 1 andAlso szptr->hasMember = 0 then
				szptr->hasMember = 1
				select case szptr->spawn_type			
				case OBJ_ITEM
					addItem(*szptr)
				end select
			end if
		else
			exit do
		end if
	loop
	
    for i = 0 to 1
        select case i
        case 0
            objectList = @objects_active
        case 1
            objectList = @objects_activefront
        end select
    
        objectList->rollReset()
        do
            dobj = objectList->roll()
            if dobj <> 0 then
                if dobj->object_type = OBJ_ITEM then
                    curItem = dobj->data_
                    
                    lnr = objectList->bufferRoll()
                    shouldDelete = curItem->process(t)
                    objectList->setRoll(lnr)
                    
                    if shouldDelete then
                        delete (cast(Item ptr, dobj->data_))
                        objectList->rollRemove()
                    end if
                end if
            else
                exit do
            end if
        loop
	next i
	
end sub

sub DynamicController.drawDynamics(scnbuff as integer ptr, order as integer = 0)
	dim as DynamicObjectType_t ptr dobj
	dim as List ptr objectList
    dim as integer i
    
    if order <> OVERLAY then
        select case order
        case ACTIVE
            objectList = @objects_active
        case ACTIVE_FRONT
            objectList = @objects_activefront
        case else
            exit sub
        end select
        
    
        objectList->rollReset()
        do
            dobj = objectList->roll()
            if dobj <> 0 then
                if dobj->object_type = OBJ_ITEM then
                    cast(Item ptr, dobj->data_)->drawItem(scnbuff)
                end if
            else
                exit do
            end if
        loop
    else
        for i = 0 to 1
        
            select case i
            case 0
                objectList = @objects_active
            case 1
                objectList = @objects_activefront
            end select
    
            objectList->rollReset()
            do
                dobj = objectList->roll()
                if dobj <> 0 then
                    if dobj->object_type = OBJ_ITEM then
                        cast(Item ptr, dobj->data_)->drawItemTop(scnbuff)
                    end if
                else
                    exit do
                end if
            loop
        next i
	end if
end sub

