#ifndef ITEM_BI
#define ITEM_BI

#include "objectlink.bi"
#include "animation.bi"
#include "pointlight.bi"
#include "shape2d.bi"
#include "hashtable.bi"

'holds per item prefixed types, per item #defines
'item type pointer union for data_ and item_e table, slot_e table
#include "objects\headers\gen_itemdefines.bi" 


type _Item_valueTypes_e
    _ITEM_VALUE_VECTOR2D
    _ITEM_VALUE_INTEGER
    _ITEM_VALUE_DOUBLE
    _ITEM_VALUE_ZSTRING
end type

type _Item_valueContainer_t
    as _Item_valueTypes_e type_
    Union data_
        as Vector2D Vector2D_
        as integer integer_
        as double double_
        as zstring ptr zstring_
    end union
end type

type _Item_slotTable_t
    as _Item_slotEnum_e slotE
end type

type _Item_slotValuePair_t
    as string parameter_tag
    as _Item_valueContainer_t value_
end type


type Item
	public:
		declare constructor()
		declare destructor()
        declare sub setLink(link_ as objectLink)

		declare sub init(itemType_ as Item_Type_e, p_ as Vector2D, size_ as Vector2D, ID_ as string = "")
        
        declare sub flush()
        
        declare function process(t as double) as integer
        declare sub drawItem(scnbuff as integer ptr)
		declare sub drawItemOverlay(scnbuff as integer ptr)
        
		declare sub setPos(v as Vector2D)
        declare sub setSize(s as Vector2D)

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
        
        declare sub fireSlot(slot_tag as string, parameter_string as string)
        
        declare sub getValue(byref value_ as Vector2D, value_tag as string)
        declare sub getValue(byref value_ as integer, value_tag as string) 
        declare sub getValue(byref value_ as double, value_tag as string) 
        declare sub getValue(byref value_ as string, value_tag as string) 
        
        declare function isSignal(signal_tag as string) as integer
	private:
        '#include blocks of function definitions used by methods
    
    
        'used by fireSlot
        declare static sub matchParameter(byref param_ as Vector2D, paramater_tag as string, pvPair() as _Item_slotValuePair_t)
        declare static sub matchParameter(byref param_ as integer,  paramater_tag as string, pvPair() as _Item_slotValuePair_t)
        declare static sub matchParameter(byref param_ as double,   paramater_tag as string, pvPair() as _Item_slotValuePair_t)
        declare static sub matchParameter(byref param_ as string,   paramater_tag as string, pvPair() as _Item_slotValuePair_t)
        
        
        declare static sub valueFormToContainer(value_form as string, byref valueC as _Item_valueContainer_t)
        
        'calls dyncontroller getValue
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
        
        'calls dyncontroller fireSlot with provided value of ID_ and slot_tag
        declare sub throw(signal_tag as string, parameter_string as string)
        
        '''''''publishes set up in item init from dynamiccontroller link'''''''
        declare sub _initAddParameter_(param_tag as string, param_type as _Item_valueTypes_e)
        declare sub _initAddSlot_(slot_tag as string, slot_num as _Item_slotEnum_e)
        declare sub _initAddValue_(value_tag as string, value_type as _Item_valueTypes_e)
        declare sub _initAddSignal_(signal_tag as string)
        
        'calls dyncontroller query, querys MUST be used in same scope as made
        declare sub queryValues(byref value_set as ValueSet, value_tag as string, queryShape as Shape2D = EmptyShape2D())
        declare sub querySlots(byref slot_set as SlotSet, slot_tag as string, queryShape as Shape2D = EmptyShape2D())
        
        'filled in respective generated init functions
        as Hashtable parameterTable 'holds parameter values and types
        as Hashtable slotTable 'holds slot_name_e or whatevs and parameters per slot in struct
        as Hashtable valueTable 'holds published values and value types
        as Hashtable signalTable
    
        as Item_Type_e itemType
        as LightPair   light
        as integer     lightState
        as integer     fastLight
 
		as ObjectLink    link
		as integer       anims_n
		as Animation ptr anims 'automatically cleaned up
        as Vector2D      size
        as Vector2D      p
        as string        ID
        as _objectData_u data_ 
end type


#endif
