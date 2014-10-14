#ifndef DYNAMICCONTROLLER_BI
#define DYNAMICCONTROLLER_BI

#include "vector2d.bi"
#include "list.bi"
#include "objectlink.bi"
#include "item.bi"

enum DynamicObjectType_e
	OBJ_ENEMY
	OBJ_ITEM
	OBJ_NONE
end enum

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
end type

type NamesTypes_t
	declare constructor(name_p as string, type_p as DynamicObjectType_e)
	as zstring * 32        name_
	as DynamicObjectType_e type_
end type

type DynamicObjectType_t
	as DynamicObjectType_e object_type
	as any ptr             data_
end type

type DynamicController
	public:
		declare constructor
		declare destructor
		declare sub setLink(link_ as ObjectLink)
		declare sub addSpawnZone(spawn_objectName as string,_
							     respawn as SpawnZoneDespawnType_e,_
								 p as Vector2D, size as Vector2D,_
								 count_ as integer = 1,_
								 time_ as integer = 0)
		declare sub explosionAlert(p as Vector2D)
		declare sub process(t as double)
		declare sub drawDynamics(scnbuff as integer ptr)
		declare sub flush()
		declare sub addOneItem(position as Vector2D, itemType_ as Item_Type_e, itemFlavor_ as integer)
		
	private:
		static as NamesTypes_t ptr namesTypesTable
		static as integer          hasFilledTable
		
		declare sub addEnemy(sz as SpawnZone_t)
		declare sub addItem(sz as SpawnZone_t)
		
		as ObjectLink link
		as List objects
		as List spawnZones
end type
	
	
#endif
