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
#include "shape2d.bi"
#include "hash2d.bi"
#include "doublehash.bi"


type DynamicController_publish_t
    as Shape2D target
    as DynamicController_publish_t ptr ptr hash2Dindex 'for when target <> EmptyShape2D for quick removal
    as zstring ptr tag_
    as Item ptr item_
end type

type DynamicController_itemPair
    as Item ptr item_
    as integer usedKeyBank
end type

type DynamicController_connectionIncoming_t
    as zstring ptr incomingID
    as zstring ptr incomingSignalTag
end type
type DynamicController_connectionOutgoing_t
    as DoubleHash destinations 'r_key is destination item, u_key is destination slot
end type
type DynamicController_connectionOutgoingDestination_t
    as zstring ptr outgoingID
    as zstring ptr outgoingSlotTag
end type
type DynamicController_connectionNode_t
    as Hashtable outgoingSignals 
    as DoubleHash incomingSignals
end type


type DynamicController
	public:
		declare constructor
		declare destructor
      	declare sub flush()
        declare sub setRegionSize(w as integer, h as integer)

		declare sub setLink(link_ as ObjectLink)

		declare sub process(t as double)
		declare sub drawDynamics(scnbuff as integer ptr, order as integer = 0)
        
        declare function itemStringToType(item_tag as string) as Item_Type_e
		declare function addItem(itemType_ as Item_Type_e, p_ as Vector2D, size_ as Vector2D, ID_ as string = "") as string
        
        declare function hasItem(ID_ as string) as integer
        
        declare sub setPos(ID_ as string, p_ as Vector2D)
        declare sub setSize(ID_ as string, size_ as Vector2D)
        
        declare function getPos(ID_ as string) as Vector2D
        declare function getSize(ID_ as string) as Vector2D

        declare sub removeItem(ID_ as string)
        
        declare sub setParameter(param_ as Vector2D, ID_ as string, param_tag as string)
        declare sub setParameter(param_ as integer, ID_ as string, param_tag as string)
        declare sub setParameter(param_ as double, ID_ as string, param_tag as string)
        declare sub setParameter(param_ as string, ID_ as string, param_tag as string)
        
        'items keep track of their item types and will reject a call to a non-matching item
        declare sub getValue(byref value_ as Vector2D, ID_ as string, value_tag as string)
        declare sub getValue(byref value_ as integer, ID_ as string, value_tag as string)
        declare sub getValue(byref value_ as double, ID_ as string, value_tag as string)
        declare sub getValue(byref value_ as string, ID_ as string, value_tag as string)
        
        declare sub queryValues(value_set as ObjectValueSet, value_tag as string, queryShape as Shape2D = EmptyShape2D())
        declare sub querySlots(slot_set as ObjectSlotSet, slot_tag as string, queryShape as Shape2D = EmptyShape2D())
        
        'hidden calls from item inits
        declare sub addPublishedValue(publishee_ID as string, value_tag as string, target as Shape2D = EmptyShape2D())
        declare sub addPublishedSlot(publishee_ID as string, slot_tag as string, target as Shape2D = EmptyShape2D())

        declare sub throw(signal_ID as string, signal_tag as string, parameter_string as string = "")
        declare sub fireSlot(ID_ as string, slot_tag as string, parameter_string as string = "")
        declare sub connect(signal_ID as string, signal_tag as string, slot_ID as string, slot_tag as string)
                                    
        '-------------------------------- aux functions -------------------------------------
		declare function populateLightList(ll as LightPair ptr ptr) as integer 
	private:
        declare sub _addStringToType_(tag as string, item_t as Item_Type_e)
        as Hashtable stringToTypeTable
        
    
        'each item gets an entry of type DynamicController_connectionNode_t
        as Hashtable connections
        
        'contain pointers to publish data
        as Hash2D valueTargets
        as Hash2D slotTargets
        
        
        'make double hash, where items can be searched using a key pair, one, or the other
        as DoubleHash allPublishedValues
        as DoubleHash allPublishedSlots
               
        'contain itemPair from ID lookup
		as Hashtable itemIdPairs        'itemptrs

		as Hashtable drawobjects_active      'itemptrs
        as Hashtable drawobjects_activeFront 'itemptrs
        
        as KeyBank itemIdGenerator
		as ObjectLink link
end type
	
	
#endif
