#ifndef DYNAMICCONTROLLER_BI
#define DYNAMICCONTROLLER_BI

#include "objects\headers\itemtypes.bi"
#include "vector2d.bi"
#include "list.bi"
#include "objectlink.bi"
#include "item.bi"
#include "constants.bi"
#include "pointlight.bi"
#include "hashtable.bi"
#include "keybank.bi"

enum SpawnZoneDespawnType_e
	SPAWN_TIMED
	SPAWN_ONCE
	SPAWN_FRAME
end enum

type SpawnZone_t
	as double                 spawn_time
	as integer                spawn_count
	as DynamicObjectType_e    spawn_type
	as SpawnZoneDespawnType_e spawn_respawn
	as zstring ptr            spawn_objectName
	as integer                hasMember
	as integer                isNew
	as Vector2D               p
	as Vector2D               size
    as Item_Type_e            itemNumber
    as integer                flavor
end type

type DynamicObjectType_t
	as DynamicObjectType_e object_type
	as any ptr             data_
    as orderType           order
end type

type DynamicController
	public:
		declare constructor
		declare destructor
		declare sub setLink(link_ as ObjectLink)
		declare sub addSpawnZone(spawn_objectName as string,_
                                 flavor as integer,_
							     respawn as SpawnZoneDespawnType_e,_
								 p as Vector2D, size as Vector2D,_
								 count_ as integer = 1,_
								 time_ as integer = 0)
		declare sub explosionAlert(p as Vector2D)
		declare sub process(t as double)
		declare sub drawDynamics(scnbuff as integer ptr, order as integer = 0)
		declare sub flush()
		declare function addOneItem(position as Vector2D, itemType_ as Item_Type_e, itemFlavor_ as integer = 0,_
                                    minValue as double = 1, maxValue as double = 1, mode as integer = 0, fast as integer = 65535, order as orderType = ACTIVE) as Item ptr
		declare function populateLightList(ll as LightPair ptr ptr) as integer
        
        
	private:
		
		declare sub addItem(sz as SpawnZone_t)
		
        as KeyBank itemIdGenerator
        as Hashtable itemId
        
		as ObjectLink link
		as List objects_active
        as List objects_activeFront
		as List spawnZones
end type
	
	
#endif
