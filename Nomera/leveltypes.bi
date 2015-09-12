#ifndef LEVELTYPES_BI
#define LEVELTYPES_BI

#include "hash2d.bi"
#include "hashtable.bi"
#include "list.bi"
#include "constants.bi"
#include "zimage.bi"

#define LIGHT_EFFECT_VALUE 5
#define MIST_OBJECTS_PER_LAYER 30

#define LEVEL_ON 1
#define LEVEL_OFF 65535

enum ObjectType_t
    EFFECT
    PORTAL
    TRIGGER
    SPAWN
end enum

type Object_t
    as zstring * 128 object_name
    as ushort object_flavor
    as ushort object_type
    as ushort object_shape
    as ushort inRangeSet
    as Vector2D p
    as Vector2D size
    as any ptr data_
    as single depth
    as ushort drawless
end type

type destroyedBlocks_t
	as integer width_
	as integer height_
	as byte ptr data_
end type

enum EffectType_t
    ANIMATE
    FLICKER
    DESTRUCT
    NONE
end enum

type Level_layerGroup
    as List ptr layers
end type

type Level_CoverageBlockInfo_t
	as integer ptr img
	as integer l
	as integer x0
	as integer y0
	as integer x1
	as integer y1
	as integer rpx
	as integer rpy
end type

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
    as zimage set_image
    as HashTable tileEffect
end type

type Level_VisBlock
    as ushort tileset
    as ushort tileNum
    as short  frameDelay
    as ushort usesAnim
    as PointLight ptr light(0 to 2)
    as integer numLights
end type

Type Level_LayerData
    as ushort order
    as ushort parallax
    as ushort inRangeSet
    as ushort isDestructible
    as ushort isFallout
    as ushort illuminated
    as integer ambientLevel
    as integer windyMistLayer
    as ushort coverage
    as ushort receiver
    as ushort occluding
    as single depth
    as ushort isHidden
    as integer glow
    as zstring ptr groupName
end type

enum PortalDirection_t
    D_LEFT
    D_UP
    D_RIGHT
    D_DOWN
    D_IN
    NO_FACING
end enum

enum EffectMode_e
    MODE_FLICKER = 0
    MODE_TOGGLE  = 1
    MODE_STATIC  = 2
end enum

type PortalType_t
    as Vector2D a, b
    as zstring ptr portal_name
    as zstring ptr to_map
    as zstring ptr to_portal
    as PortalDirection_t direction
    as integer enable
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
    as PortalDirection_t facing
end type

type MistObject_t
    as Vector2D p
    as double zd
end type
type MistLayer_t
    as MistObject_t ptr objects
    as integer objects_n
    as double zdepth
    as integer layerNum
    as Vector2D tl
    as Vector2D br
end type


#endif
