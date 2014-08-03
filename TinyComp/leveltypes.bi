#ifndef LEVELTYPES_BI
#define LEVELTYPES_BI

#include "hashtable.bi"

enum orderType
    FOREGROUND
    ACTIVE
    BACKGROUND
end enum


enum EffectType_t
    ANIMATE
    FLICKER
    DESTRUCT
    NONE
end enum

type Level_FalloutType
    as Vector2D a
    as Vector2D b
    as integer ptr cachedImage
    as integer  flavor
end type

type Level_EffectData
    as short  nextTile
    as ushort effect
    as ushort offset
    as ushort delay
    as ushort tilenum
end type

type Level_Tileset
    as zstring ptr set_name
    as ushort set_width
    as ushort set_height
    as ushort count
    as ushort row_count
    as uinteger ptr set_image
    as HashTable tileEffect
end type

type Level_VisBlock
    as ushort tileset
    as ushort tileNum
    as short frameDelay
    as ushort usesAnim
    as ushort rotatedType
end type

Type Level_LayerData
    as ushort order
    as ushort parallax
    as ushort inRangeSet
    as ushort isDestructible
    as ushort isFallout
    as single depth
end type


type PortalData_t
    as zstring ptr portalName
    as zstring ptr linkMapName
    as zstring ptr linkPortalName
end type
type RegionPortalData_t
    as zstring ptr regionName
    as integer numPortals
    as PortalData_t ptr portals
end type
Type RegionData_t
    as integer numRegions
    as RegionPortalData_t ptr regionPortals
end type

type BoundingBox_t
    as Vector2D a,b
    as double area
    as zstring ptr portalName
end type

type LevelSwitch_t
    as integer shouldSwitch
    as Vector2D p
    as string fileName
    as string portalName
end type


#endif