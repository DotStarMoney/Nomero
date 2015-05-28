#ifndef ITEM_BI
#define ITEM_BI

#include "tinybody.bi"
#include "objectlink.bi"
#include "tinyspace.bi"
#include "animation.bi"
#include "pointlight.bi"

#define BOMB_STICKYNESS 0
#define MINE_FREEFALL_MAX 30

enum Item_Type_e
	ITEM_KEY
	ITEM_INTELLIGENCE
	ITEM_SECRETFURNITURE
	ITEM_CASH
	ITEM_BOMB
    ITEM_LIGHT
	ITEM_DYNAMICPLATFORM
end enum

'for bomb, first 3 bits define bomb type.
'	next 2 bits are orientation


type Item
	public:
		declare constructor()
		declare destructor()
		declare sub init(itemType_ as Item_Type_e, itemFlavor_ as integer)
		declare sub setPos(v as Vector2D)
        declare sub setLightModeData(minValue as double, maxValue as double, mode as integer)
		declare function getPos() as Vector2D
		declare sub getBounds(byref a as Vector2D, byref b as Vector2D)
		declare sub drawItem(scnbuff as integer ptr)
		declare sub drawItemTop(scnbuff as integer ptr)
		declare sub setData0(d as integer)
		declare sub setData1(d as integer)
		declare sub setData2(d as integer)
		declare static function getIndicatorColor(i as integer) as integer
		declare function getData0() as integer
		declare function getData1() as integer
		declare function getData2() as integer
		declare function getFlavor() as integer
		declare function getType() as Item_Type_e
		declare function process(t as double) as integer
        declare function hasLight() as integer
        declare sub getLightingData(texture as Pointlight, shaded as Pointlight)
		declare sub flush()
		declare sub setLink(link_ as objectLink)
	private:
		static as uinteger ptr BOMB_COLORS
        as Pointlight  lightTex
        as Pointlight  lightShaded
        as integer     lightState
		as Item_Type_e itemType
		as integer     itemFlavor
        as double      minValue
        as double      maxValue
        as integer     mode
		as TinyBody    body
		as integer     body_i
		as integer     freeFallingFrames
		as integer     orientation
		as ObjectLink  link
		as integer       anims_n
		as Animation ptr anims
		as integer     	data0
		as integer     	data1
		as integer		data2
end type


#endif
