#include "dynamiccontroller.bi"
#include "tinyspace.bi"
#include "utility.bi"
#include "soundeffects.bi"
#include "gamespace.bi"
#include "item.bi"
#include "constants.bi"


constructor DynamicController()
    stringToTypeTable.init(sizeof(Item_Type_e))
    connections.init(sizeof(DynamicController_connectionNode_t))
    allPublishedValues.init(sizeof(DynamicController_publish_t))
    allPublishedSlots.init(sizeof(DynamicController_publish_t))
    itemIdPairs.init(sizeof(DynamicController_itemPair))
    drawobjects_active.init(sizeof(Item ptr))
    drawobjects_activeFront.init(sizeof(Item ptr))
    
    
    '#include namestypestable inserts
    
end constructor

destructor DynamicController()
    flush()
end destructor

sub DynamicController.setRegionSize(w as integer, h as integer)
    valueTargets.init(w, h, sizeof(DynamicController_publish_t ptr))
    slotTargets.init(w, h, sizeof(DynamicController_publish_t ptr))
end sub
declare sub flush()
    dim as DynamicController_connectionNode_t ptr curConnectionNode
    dim as DynamicController_connectionIncoming_t ptr curIncomingConnection
    dim as DynamicController_connectionOutgoing_t ptr curOutgoingConnection
    dim as DynamicController_connectionOutgoingDestination_t ptr curOutgoingDestination
    dim as DynamicController_publish_t ptr curPublish
    dim as DynamicController_itemPair ptr curItem
    
    valueTargets.flush()
    slotTargets.flush()
    stringToTypeTable.flush()
    drawobjects_active.flush()
    drawobjects_activefront.flush()
    
    BEGIN_HASH(curPublish, allPublishedValues)
        deallocate(curPublish->tag_)
    END_HASH()
    allPublishedValues.flush()
    BEGIN_HASH(curPublish, allPublishedSlots)
        deallocate(curPublish->tag_)
    END_HASH()
    allPublishedSlots.flush()
    
    BEGIN_HASH(curConnectionNode, connections)
        BEGIN_HASH(curIncomingConnection, curConnectionNode->incomingSignals)
            deallocate(curIncomingConnection->incomingID)
            deallocate(curIncomingConnection->incomingSignalTag)
        END_HASH()
        curConnectionNode->incomingSignals.flush()
        BEGIN_HASH(curOutgoingConnection, curConnectionNode->outgoingSignals)
            BEGIN_HASH(curOutgoingDestination, curOutgoingConnection->destinations)
                deallocate(curOutgoingDestination->outgoingID)
                deallocate(curOutgoingDestination->outgoingSlotTag)                    
            END_HASH()
            curOutgoingConnection->destinations.flush()
        END_HASH()        
        curConnectionNode->outgoingSignals.flush()
    END_HASH()
    connections.flush()
    
    itemIdGenerator.flush()
    
    BEGIN_HASH(curItem, itemIdPairs)
        curItem->item_->flush()
        deallocate(curItem->item_)
    END_HASH()
    itemIdPairs.flush()
    
end sub
sub DynamicController.removeItem(ID_ as string)
    dim as DynamicController_itemPair ptr itemPair_
    dim as DynamicController_publish_t ptr ptr publishedVals
    dim as DynamicController_connectionNode_t ptr curConnection
    dim as DynamicController_connectionIncoming_t ptr curRemoveConnection
    dim as DynamicController_connectionNode_t ptr nodeConnected
    Dim as DynamicController_connectionOutgoing_t ptr signalConnected
    dim as DynamicController_connectionOutgoingDestination_t ptr ptr outConnections
    dim as integer outConnections_n
    dim as string removeID, removeTag
    dim as integer publishedVals_N, i
    itemPair_ = itemIdPairs.retrieve(ID_)
    if itemPair_->usedKeyBank then itemIdGenerator.relinquish(ID_)
    
    publishedVals_N = allPublishedValues.retrieveDuplicates(ID_, publishedVals)
    if publishedVals_N then
        for i = 0 to publishedVals_N - 1
            if not(publishedVals[i]->target is EmptyShape2D) then
                valueTargets.remove(publishedVals[i]->hash2Dindex)
            end if
            deallocate(publishedVals[i]->tag_)
        next i
    end if
    allPublishedValues.remove(ID_)
    deallocate(publishedVals)
    
    publishedVals_N = allPublishedSlots.retrieveDuplicates(ID_, publishedVals)
    if publishedVals_N then
        for i = 0 to publishedVals_N - 1
            if not(publishedVals[i]->target is EmptyShape2D) then
                slotTargets.remove(publishedVals[i]->hash2Dindex)
            end if
            deallocate(publishedVals[i]->tag_)
        next i
    end if
    allPublishedSlots.remove(ID_)
    deallocate(publishedVals)
       
    if drawObjects_active.exists(ID_) then
        drawObjects_active.remove(ID_)
    elseif drawObjects_activeFront.exists(ID_) then
        drawObjects_activeFront.remove(ID_)
    end if
    
    curConnection = connections.retrieve(ID_)
    BEGIN_HASH(curRemoveConnection, curConnection->incomingSignals)
        'sever connections coming in to this item
        removeID = *(curRemoveConnection->incomingID)
        removeTag = *(curRemoveConnection->incomingSignalTag)
        nodeConnected = connections.retrieve(removeID)
        signalConnected = nodeConnected->outgoingSignals.retrieve(removeTag)
        outconnections_n = signalConnected->destinations.retrieveDuplicates(ID_, outConnections)
        for i = 0 to outconnections_n - 1
            deallocate(outConnections[i].outgoingID)
            deallocate(outConnections[i].outgoingSlotTag)
        next i
        signalConnected->remove(ID_)
    END_HASH()
    
    
end sub

sub DynamicController.setLink(link_ as ObjectLink)
    link = link_
end sub

sub DynamicController.process(t as double)

end sub
sub DynamicController.drawDynamics(scnbuff as integer ptr, order as integer = 0)

end sub
sub DynamicController._addStringToType_(tag as string, item_t as Item_Type_e)

end sub
function DynamicController.itemStringToType(item_tag as string) as Item_Type_e

end function
function DynamicController.addItem(itemType_ as Item_Type_e, p_ as Vector2D, size_ as Vector2D, ID_ as string = "") as string

end function
function DynamicController.hasItem(ID_ as string) as integer

end function
sub DynamicController.setPos(ID_ as string, p_ as Vector2D)

end sub
sub DynamicController.setSize(ID_ as string, size_ as Vector2D)

end sub

function DynamicController.getPos(ID_ as string) as Vector2D

end function

function DynamicController.getSize(ID_ as string) as Vector2D

end function

sub DynamicController.setParameter(param_ as Vector2D, ID_ as string, param_tag as string)

end sub
sub DynamicController.setParameter(param_ as integer, ID_ as string, param_tag as string)

end sub
sub DynamicController.setParameter(param_ as double, ID_ as string, param_tag as string)


end sub

sub DynamicController.setParameter(param_ as string, ID_ as string, param_tag as string)

end sub
sub DynamicController.getValue(byref value_ as Vector2D, ID_ as string, value_tag as string)

end sub
sub DynamicController.getValue(byref value_ as integer, ID_ as string, value_tag as string)

end sub
sub DynamicController.getValue(byref value_ as double, ID_ as string, value_tag as string)

end sub
sub DynamicController.getValue(byref value_ as string, ID_ as string, value_tag as string)

end sub

sub DynamicController.queryValues(value_set as ObjectValueSet, value_tag as string, queryShape as Shape2D = EmptyShape2D())

end sub
sub DynamicController.querySlots(slot_set as ObjectSlotSet, slot_tag as string, queryShape as Shape2D = EmptyShape2D())

end sub
sub DynamicController.addPublishedValue(publishee_ID as string, value_tag as string, target as Shape2D = EmptyShape2D())

end sub
sub DynamicController.addPublishedSlot(publishee_ID as string, slot_tag as string, target as Shape2D = EmptyShape2D())

end sub
sub DynamicController.throw(signal_ID as string, signal_tag as string, parameter_string as string = "")

end sub
sub DynamicController.fireSlot(ID_ as string, slot_tag as string, parameter_string as string = "")

end sub
sub DynamicController.connect(signal_ID as string, signal_tag as string, slot_ID as string, slot_tag as string)

end sub                 
function DynamicController.populateLightList(ll as LightPair ptr ptr) as integer 
	
end function
/'
type DynamicController_publish_t
    as Shape2D target
    as zstring ptr tag_
    as Item ptr item_
end type

type DynamicController_itemPair
    as zstring ptr ID_
    as Item ptr item_
    as integer usedKeyBank
end type

type DynamicController_connectionIncoming_t
    as zstring ptr incomingID
    as zstring ptr incomingSignalTag
end type
type DynamicController_connectionOutgoing_t
    as Hashtable destinations
end type
type DynamicController_connectionOutgoingDestination_t
    as zstring ptr outgoingID
    as zstring ptr outgoingSlotTag
end type
type DynamicController_connectionNode_t
    as Hashtable outgoingSignals
    as Hashtable incomingSignals
end type


type DynamicController
	public:
		declare constructor
		declare destructor
      	declare sub flush()

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

        'each item gets an entry of type DynamicController_connectionNode_t
        as Hashtable connections
    
        as Hash2D valueTargets
        as Hash2D slotsTargets
        as Hashtable allPublishedValues
        as Hashtable allPublishedSlots
               
		as Hashtable itemIdPairs        'itemptrs
        
        as List allItems                'pair list for processing and removal
        
		as List drawobjects_active      'itemptrs
        as List drawobjects_activeFront 'itemptrs

        as KeyBank itemIdGenerator
		as ObjectLink link
end type
'/
	