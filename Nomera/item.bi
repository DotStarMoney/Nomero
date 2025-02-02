#ifndef ITEM_BI
#define ITEM_BI

#include "zimage.bi"
#include "objectlink.bi"
#include "animation.bi"
#include "pointlight.bi"
#include "shape2d.bi"
#include "hashtable.bi"
#include "pvector2d.bi"
#include "tinybody.bi"
#include "tinyspace.bi"
#include "objectslotset.bi"
#include "objectvalueset.bi"
#include "constants.bi"
#include "C64Draw.bi"
#include "enemy.bi"


#include "objects\headers\gen_itemdefines.bi"

#include "itemvaluecontainer.bi"

type _Item_slotTable_t
    as Item_slotEnum_e slotE
end type

type _Item_slotValuePair_t
    as string parameter_tag
    as _Item_valueContainer_t value_
end type

enum _Item_persistenceType_e
    ITEM_PERSISTENCE_NONE
    ITEM_PERSISTENCE_ITEM
    ITEM_PERSISTENCE_LEVEL
end enum


type Item
	public:
		declare constructor()
		declare destructor()
        
        declare sub construct_()
        
        declare sub setLink(link_ as objectLink)
        
        declare sub construct(itemType_ as Item_Type_e, ID_ as string = "")
        declare sub initPost(p_ as Vector2D, size_ as Vector2D, depth_ as single = 1.0)

		declare sub init(itemType_ as Item_Type_e, p_ as Vector2D, size_ as Vector2D, ID_ as string = "", depth_ as single = 1.0)
        
        declare sub flush()
        
        declare function process(t as double) as integer
        declare sub drawItem(scnbuff as integer ptr)
		declare sub drawItemOverlay(scnbuff as integer ptr)
        
		declare sub setPos(v as Vector2D)
        declare sub setSize(s as Vector2D)

        declare function getID() as string
        
		declare function getPos() as Vector2D
        declare function getSize() as Vector2D
        
		declare sub getBounds(byref a as Vector2D, byref b as Vector2D) 'directly related to size
        
		declare function getType() as Item_Type_e
        
        declare function hasLight() as integer
        declare function getLightingData() as LightPair ptr
        
        declare sub setParameter(param_ as Vector2D, param_tag as string)
        declare sub setParameter(param_ as integer, param_tag as string)
        declare sub setParameter(param_ as double, param_tag as string)
        declare sub setParameter(param_ as string, param_tag as string)
        
        declare sub fireSlot(slot_tag as string, parameter_string as string = "")
        
        declare sub getValue(byref value_ as Vector2D, value_tag as string)
        declare sub getValue(byref value_ as integer, value_tag as string) 
        declare sub getValue(byref value_ as double, value_tag as string) 
        declare sub getValue(byref value_ as string, value_tag as string) 
        declare function getValueContainer(value_tag as string) as _Item_valueContainer_t ptr
        
        declare function isSignal(signal_tag as string) as integer
        declare function isSlot(slot_tag as string) as integer
		
		declare sub serialize_in(pbin as PackedBinary)
		declare sub serialize_out(pbin as PackedBinary)
        
        declare function canSerialize() as integer
        declare function shouldReload() as integer
        declare function shouldSaveILI() as integer
        
        declare static sub valueFormToContainer(value_form as string, byref valueC as _Item_valueContainer_t)
        
        declare static function getIndicatorColor(i as integer) as integer
	
        as integer ILI
        as orderType orderClass
    
    private:
        #include "objects\headers\gen_methodprototypes.bi"
        
        declare function drawX() as double
        declare function drawY() as double
    
        declare static sub matchParameter(byref param_ as Vector2D, parameter_tag as string, pvPair() as _Item_slotValuePair_t)
        declare static sub matchParameter(byref param_ as integer,  parameter_tag as string, pvPair() as _Item_slotValuePair_t)
        declare static sub matchParameter(byref param_ as double,   parameter_tag as string, pvPair() as _Item_slotValuePair_t)
        declare static sub matchParameter(byref param_ as string,   parameter_tag as string, pvPair() as _Item_slotValuePair_t)
        
        
        
        declare sub getOtherValue(byref value_ as Vector2D, ID_ as string, value_tag as string)
        declare sub getOtherValue(byref value_ as integer,  ID_ as string, value_tag as string)
        declare sub getOtherValue(byref value_ as double,   ID_ as string, value_tag as string)
        declare sub getOtherValue(byref value_ as string,   ID_ as string, value_tag as string)
        
        declare sub getParameter(byref param_ as Vector2D, param_tag as string) 
        declare sub getParameter(byref param_ as integer,  param_tag as string)
        declare sub getParameter(byref param_ as double,   param_tag as string)
        declare sub getParameter(byref param_ as string,   param_tag as string)
        
        declare sub setValue(value_ as Vector2D, value_tag as string)
        declare sub setValue(value_ as integer, value_tag as string)
        declare sub setValue(value_ as double, value_tag as string)
        declare sub setValue(value_ as string, value_tag as string)
        
        declare sub throw(signal_tag as string, parameter_string as string = "")
        declare sub fireExternalSlot(ID as string, slot_tag as string, parameter_string as string = "")
        
        declare sub _initAddParameter_(param_tag as string, param_type as _Item_valueTypes_e)
        declare sub _initAddSlot_(slot_tag as string, slot_num as Item_slotEnum_e)
        declare sub _initAddValue_(value_tag as string, value_type as _Item_valueTypes_e)
        declare sub _initAddSignal_(signal_tag as string)
        
        declare sub setTargetValueOffset(value_tag as string, offset as Vector2D)        
        declare sub setTargetSlotOffset(slot_tag as string, offset as Vector2D)

        declare sub queryValues(byref value_set as ObjectValueSet, value_tag as string, queryShape as Shape2D ptr = 0)
        declare sub querySlots(byref slot_set as ObjectSlotSet, slot_tag as string, queryShape as Shape2D ptr = 0)

        as Hashtable parameterTable 
        as Hashtable slotTable 
        as Hashtable valueTable 
        as Hashtable signalTable
    
        as Item_Type_e itemType
      
        as LightPair   light
        as integer     lightState
        as integer     fastLight
        as Animation ptr diffuseTex_
        as Animation ptr specularTex_
        as integer usesLights_
        
		as ObjectLink    link
		as integer       anims_n
		as Animation ptr anims 
                
        as Vector2D      size
        as Vector2D      p
        as Vector2D      bounds_tl
        as Vector2D      bounds_br
        as string        ID
        as double        depth
        as _Item_persistenceType_e persistenceLevel_
        
        as integer canExport_

        as Item_objectData_u data_ 
        
        
        static as uinteger ptr BOMB_COLORS
end type


#endif
