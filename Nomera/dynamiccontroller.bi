#ifndef DYNAMICCONTROLLER_BI
#define DYNAMICCONTROLLER_BI

#include "item.bi"
#include "vector2d.bi"
#include "list.bi"
#include "objectlink.bi"
#include "item.bi"
#include "constants.bi"
#include "pointlight.bi"
#include "hashtable.bi"
#include "keybank.bi"
#include "shape2d.bi"
#include "hash2d.bi"
#include "doublehash.bi"

'item adds its own position to query shape
type DynamicController_publish_t
    as Shape2D ptr target
    as DynamicController_publish_t ptr ptr hash2Dindex 'for when target <> EmptyShape2D for quick removal
    as zstring ptr tag_
    as Item ptr item_
end type

type DynamicController_publishSlot_t
    as Shape2D ptr target
    as DynamicController_publish_t ptr ptr hash2Dindex 
    as zstring ptr tag_
    as zstring ptr slot_tag_
    as Item ptr item_
end type

type DynamicController_itemPair_t
    as Item ptr item_
    as integer usedKeyBank
end type

/'
type DynamicController_postFrame_t
    as DynamicController_itemPair_t itemPair_
    as Vector2D p_
    as Vector2D size_
    as double depth_
end type
'/
type DynamicController_connectionNode_t
    as Hashtable slots   'on slot name
    as Hashtable signals 'on signal name
end type
type DynamicController_connectionIncoming_t
    as DoubleHash incomingFromSignals 'on incoming from item ID, and incoming signal tag
end type
type DynamicController_connectionOutgoing_t
    as DoubleHash outgoingToSlots 'on outoing to item ID, and outoing to slot tag
end type
type DynamicController_connectionIncomingSource_t
    as zstring ptr incomingId
    as zstring ptr incomingSignalTag
    as zstring ptr thisSlot
end type
type DynamicController_connectionOutgoingDestination_t
    as zstring ptr outgoingID
    as zstring ptr outgoingSlotTag
    as zstring ptr appendParameter
    as zstring ptr thisSignal
end type

type DynamicController
	public:
		declare constructor
		declare destructor
      	declare sub flush()
        declare sub setRegionSize(w as integer, h as integer)

		declare sub setLink(link_ as ObjectLink)

		declare sub process(t as double)
		declare sub drawDynamics(scnbuff as integer ptr, order as integer = ACTIVE)

        declare function hasItem(ID_ as string) as integer
        
        declare sub setPos(ID_ as string, p_ as Vector2D)
        declare sub setSize(ID_ as string, size_ as Vector2D)
        
        declare function getPos(ID_ as string) as Vector2D
        declare function getSize(ID_ as string) as Vector2D
        declare sub getBounds(ID_ as string, byref a as Vector2D, byref b as Vector2D)

        declare sub removeItem(ID_ as string)
        
        '---------------- used by outside to create objects ---------------
        declare function itemStringToType(item_tag as string) as Item_Type_e
		declare function addItem(itemType_ as Item_Type_e, order as integer = ACTIVE, p_ as Vector2D = Vector2D(0, 0), size_ as Vector2D = Vector2D(0, 0), _
                                 ID_ as string = "", depth_ as single = 1.0, drawLess as integer = 0) as string
        declare function constructItem(itemType_ as Item_Type_e, order as integer = ACTIVE, ID_ as string = "", drawLess as integer = 0) as Item ptr
        declare sub initItem(itemToInit as Item ptr, p_ as Vector2D = Vector2D(0, 0), size_ as Vector2D = Vector2D(0, 0), _
                             depth_ as single = 1.0)
        declare sub setParameterFromString(param_string as string, ID_ as string, param_tag as string)
        declare sub connect(signal_ID as string, signal_tag as string, slot_ID as string, slot_tag as string, parameter_string as string = "")
        declare sub addPublishedValue(publishee_ID as string, value_tag as string, target as Shape2D ptr = 0)
        declare sub addPublishedSlot(publishee_ID as string, slot_tag as string, actual_slot_tag as string, target as Shape2D ptr = 0)
        '------------------------------------------------------------------
        
        declare sub setParameter(param_ as Vector2D, ID_ as string, param_tag as string)
        declare sub setParameter(param_ as integer, ID_ as string, param_tag as string)
        declare sub setParameter(param_ as double, ID_ as string, param_tag as string)
        declare sub setParameter(param_ as string, ID_ as string, param_tag as string)
        
        declare sub getValue(byref value_ as Vector2D, ID_ as string, value_tag as string)
        declare sub getValue(byref value_ as integer, ID_ as string, value_tag as string)
        declare sub getValue(byref value_ as double, ID_ as string, value_tag as string)
        declare sub getValue(byref value_ as string, ID_ as string, value_tag as string)
        
        declare sub setTargetValueOffset(ID_ as string, value_tag as string, offset as Vector2D)
        declare sub setTargetSlotOffset(ID_ as string, slot_tag as string, offset as Vector2D)        
        
        declare sub queryValues(value_set as ObjectValueSet, value_tag as string, queryShape as Shape2D ptr = 0)
        declare sub querySlots(slot_set as ObjectSlotSet, slot_tag as string, queryShape as Shape2D ptr = 0)
        
        declare sub throw(signal_ID as string, signal_tag as string, parameter_string as string = "")
        declare sub fireSlot(ID_ as string, slot_tag as string, parameter_string as string = "")
                                    
        '-------------------------------- aux functions -------------------------------------
		declare function populateLightList(ll as LightPair ptr ptr) as integer 
    
    private:
        declare sub _addStringToType_(tag as string, item_t as Item_Type_e)
        declare function getItem(ID_ as string) as Item ptr

        as Hashtable stringToTypeTable
        
        as Hashtable connections
        
        as Hash2D valueTargets
        as Hash2D slotTargets
        
        as DoubleHash allPublishedValues
        as DoubleHash allPublishedSlots
               
		as Hashtable itemIdPairs        

        as Hashtable drawobjects_background
		as Hashtable drawobjects_active      
        as Hashtable drawobjects_activeFront 
        
        as KeyBank itemIdGenerator
		as ObjectLink link
        
        as integer isProcessing
        as List addItemPost
        as Hashtable postPairs
        
end type
	
	
#endif
