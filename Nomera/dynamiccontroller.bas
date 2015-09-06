#include "dynamiccontroller.bi"
#include "tinyspace.bi"
#include "utility.bi"
#include "soundeffects.bi"
#include "gamespace.bi"
#include "item.bi"
#include "constants.bi"
#include "locktoscreen.bi"


constructor DynamicController()
    stringToTypeTable.init(sizeof(Item_Type_e))
    connections.init(sizeof(DynamicController_connectionNode_t))
    allPublishedValues.init(sizeof(DynamicController_publish_t))
    allPublishedSlots.init(sizeof(DynamicController_publishSlot_t))
    itemIdPairs.init(sizeof(DynamicController_itemPair_t))
    drawobjects_active.init(sizeof(Item ptr))
    drawobjects_activeFront.init(sizeof(Item ptr))
    drawobjects_background.init(sizeof(Item ptr))    
    drawobjects_foreground.init(sizeof(Item ptr))    
    addItemPost.init(sizeof(DynamicController_itemPair_t))
    postPairs.init(sizeof(DynamicController_itemPair_t ptr))
    isProcessing = 0
    
    #include "objects\headers\gen_namestypes.bi"
    
end constructor

destructor DynamicController()
    clean()
end destructor

sub DynamicController.setRegionSize(w as integer, h as integer)
    valueTargets.init(w, h, sizeof(DynamicController_publish_t ptr))
    slotTargets.init(w, h, sizeof(DynamicController_publishSlot_t ptr))
end sub
sub DynamicController.clean()
    dim as DynamicController_connectionNode_t ptr curConnectionNode
    dim as DynamicController_connectionIncoming_t ptr curIncomingConnection
    dim as DynamicController_connectionOutgoing_t ptr curOutgoingConnection
    dim as DynamicController_connectionOutgoingDestination_t ptr curOutgoingDestination
    dim as DynamicController_connectionIncomingSource_t ptr curIncomingSource
    dim as DynamicController_publish_t ptr curPublish
    dim as DynamicController_publishSlot_t ptr curPublishSlot    
    dim as DynamicController_itemPair_t ptr curItem
    
	
    valueTargets.flush()
    slotTargets.flush()
    stringToTypeTable.clean()
    
    drawobjects_active.clean()
    drawobjects_activefront.clean()
    drawobjects_background.clean()
    drawobjects_foreground.clean()
    
    
    BEGIN_DHASH(curPublish, allPublishedValues)
        if curPublish->target then delete(curPublish->target)
        deallocate(curPublish->tag_)
    END_DHASH()
    allPublishedValues.clean()
    BEGIN_DHASH(curPublishSlot, allPublishedSlots)
        if curPublishSlot->target then delete(curPublishSlot->target)
        deallocate(curPublishSlot->tag_)
        deallocate(curPublishSlot->slot_tag_)        
    END_DHASH()
    allPublishedSlots.clean()
    
    BEGIN_HASH(curConnectionNode, connections)
        BEGIN_HASH(curIncomingConnection, curConnectionNode->slots)
            BEGIN_DHASH(curIncomingSource, curIncomingConnection->incomingFromSignals)
                deallocate(curIncomingSource->incomingID)
                deallocate(curIncomingSource->incomingSignalTag)
                deallocate(curIncomingSource->thisSlot)
            END_DHASH()
            curIncomingConnection->incomingFromSignals.clean()
        END_HASH()
        curConnectionNode->slots.clean()
        
        BEGIN_HASH(curOutgoingConnection, curConnectionNode->signals)
            BEGIN_DHASH(curOutgoingDestination, curOutgoingConnection->outgoingToSlots)
                deallocate(curOutgoingDestination->outgoingID)
                deallocate(curOutgoingDestination->outgoingSlotTag)
                deallocate(curOutgoingDestination->thisSignal)
                if curOutgoingDestination->appendParameter then
                    deallocate(curOutgoingDestination->appendParameter)
                end if
            END_DHASH()
            curOutgoingConnection->outgoingToSlots.clean()
        END_HASH()
        curConnectionNode->signals.clean()        
    END_HASH()
    connections.clean()
    
    itemIdGenerator.flush()
    
    BEGIN_HASH(curItem, itemIdPairs)
        delete(curItem->item_)
    END_HASH()
    itemIdPairs.clean()
    
end sub
sub DynamicController.flush()
    dim as DynamicController_connectionNode_t ptr curConnectionNode
    dim as DynamicController_connectionIncoming_t ptr curIncomingConnection
    dim as DynamicController_connectionOutgoing_t ptr curOutgoingConnection
    dim as DynamicController_connectionOutgoingDestination_t ptr curOutgoingDestination
    dim as DynamicController_connectionIncomingSource_t ptr curIncomingSource
    dim as DynamicController_publish_t ptr curPublish
    dim as DynamicController_publishSlot_t ptr curPublishSlot    
    dim as DynamicController_itemPair_t ptr curItem
    
    
    valueTargets.flush()
    slotTargets.flush()

    drawobjects_active.flush()
    drawobjects_activefront.flush()
    drawobjects_background.flush()
    drawobjects_foreground.flush()
    
    BEGIN_DHASH(curPublish, allPublishedValues)
        if curPublish->target then delete(curPublish->target)
        deallocate(curPublish->tag_)
    END_DHASH()
    allPublishedValues.flush()
    BEGIN_DHASH(curPublishSlot, allPublishedSlots)
        if curPublishSlot->target then delete(curPublishSlot->target)
        deallocate(curPublishSlot->tag_)
        deallocate(curPublishSlot->slot_tag_)        
    END_DHASH()
    allPublishedSlots.flush()
    
    
    BEGIN_HASH(curConnectionNode, connections)
        BEGIN_HASH(curIncomingConnection, curConnectionNode->slots)
            BEGIN_DHASH(curIncomingSource, curIncomingConnection->incomingFromSignals)
                deallocate(curIncomingSource->incomingID)
                deallocate(curIncomingSource->incomingSignalTag)
                deallocate(curIncomingSource->thisSlot)
            END_DHASH()
            curIncomingConnection->incomingFromSignals.clean()
        END_HASH()
        curConnectionNode->slots.clean()
        
        BEGIN_HASH(curOutgoingConnection, curConnectionNode->signals)
            BEGIN_DHASH(curOutgoingDestination, curOutgoingConnection->outgoingToSlots)
                deallocate(curOutgoingDestination->outgoingID)
                deallocate(curOutgoingDestination->outgoingSlotTag)
                deallocate(curOutgoingDestination->thisSignal)
                if curOutgoingDestination->appendParameter then
                    deallocate(curOutgoingDestination->appendParameter)
                end if
            END_DHASH()
            curOutgoingConnection->outgoingToSlots.clean()
        END_HASH()
        curConnectionNode->signals.clean()        
    END_HASH()
    connections.flush()
    
    
    
    itemIdGenerator.flush()
    
    
    BEGIN_HASH(curItem, itemIdPairs)
        delete(curItem->item_)
    END_HASH()
    itemIdPairs.flush()
    
    
end sub
sub serialize_in(bindata as any ptr)


end sub
sub serialize_out(byref bindata as any ptr, byref size as integer)
    dim as DynamicController_itemPair_t ptr curItem
	
    BEGIN_HASH(curItem, itemIdPairs)
        
		
		
    END_HASH()	
end sub

sub DynamicController.removeItem(ID_ as string)
    dim as any ptr ptr parameterPtrPtr
    dim as DynamicController_itemPair_t ptr itemPair_
    dim as DynamicController_publish_t ptr ptr publishedVals
    dim as DynamicController_publishSlot_t ptr ptr publishedSlots
    dim as DynamicController_connectionNode_t ptr curConnectionNode
    dim as DynamicController_connectionIncoming_t ptr curIncomingConnection
    dim as DynamicController_connectionOutgoing_t ptr curOutgoingConnection
    dim as DynamicController_connectionOutgoingDestination_t ptr curOutgoingDestination
    dim as DynamicController_connectionIncomingSource_t ptr curIncomingSource
    dim as DynamicController_connectionNode_t ptr connectedNode
    dim as DynamicController_connectionOutgoing_t ptr connectedSignal
    dim as DynamicController_connectionOutgoingDestination_t ptr connectedDestination
    dim as DynamicController_connectionIncoming_t ptr connectedSlot
    dim as DynamicController_connectionIncomingSource_t ptr connectedSource    
    dim as integer outConnections_n, removeConnections_n
    dim as string removeID, removeTag, thisTag
    dim as integer publishedVals_N, i

    itemPair_ = itemIdPairs.retrieve(ID_)
    if itemPair_->usedKeyBank then itemIdGenerator.relinquish(ID_)
     
    publishedVals_N = allPublishedValues.retrieveKey1(ID_, parameterPtrPtr)
    publishedVals = parameterPtrPtr
    if publishedVals_N then

        for i = 0 to publishedVals_N - 1
            if publishedVals[i]->target then
                valueTargets.remove(publishedVals[i]->hash2Dindex)
                delete(publishedVals[i]->target)
            end if
            deallocate(publishedVals[i]->tag_)
        next i
        allPublishedValues.removeKey1(ID_)
        deallocate(publishedVals)
    end if
    
    publishedVals_N = allPublishedSlots.retrieveKey1(ID_, parameterPtrPtr)
    publishedSlots = parameterPtrPtr
    if publishedVals_N then

        for i = 0 to publishedVals_N - 1
            if publishedSlots[i]->target then
                slotTargets.remove(publishedSlots[i]->hash2Dindex)
                delete(publishedSlots[i]->target)            
            end if
            deallocate(publishedSlots[i]->tag_)
            deallocate(publishedSlots[i]->slot_tag_)
        next i
        allPublishedSlots.removeKey1(ID_)
        deallocate(publishedSlots)
    end if
    

    
    if drawObjects_active.exists(ID_) then
        drawObjects_active.remove(ID_)
    elseif drawObjects_activeFront.exists(ID_) then
        drawObjects_activeFront.remove(ID_)
    elseif drawObjects_background.exists(ID_) then
        drawObjects_background.remove(ID_)
    elseif drawObjects_foreground.exists(ID_) then
        drawobjects_foreground.remove(ID_)
    end if
    

    curConnectionNode = connections.retrieve(ID_)
    'sever connections coming in to this item
    if curConnectionNode then
        BEGIN_HASH(curIncomingConnection, curConnectionNode->slots)

            BEGIN_DHASH(curIncomingSource, curIncomingConnection->incomingFromSignals)
                removeID = *(curIncomingSource->incomingID)        
                removeTag = *(curIncomingSource->incomingSignalTag)
                thisTag = *(curIncomingSource->thisSlot)          
                
                deallocate(curIncomingSource->incomingID)
                deallocate(curIncomingSource->incomingSignalTag)
                deallocate(curIncomingSource->thisSlot)
                
                connectedNode = connections.retrieve(removeID)
                connectedSignal = connectedNode->signals.retrieve(removeTag)
                connectedDestination = connectedSignal->outgoingToSlots.retrieve(ID_, thisTag)
                
                deallocate(connectedDestination->outgoingID)
                deallocate(connectedDestination->outgoingSlotTag)
                deallocate(connectedDestination->thisSignal)
                if connectedDestination->appendParameter then
                    deallocate(connectedDestination->appendParameter)
                end if
                
                connectedSignal->outgoingToSlots.remove(ID_, thisTag)
                
            END_DHASH()
            curIncomingConnection->incomingFromSignals.clean()
        END_HASH()
        curConnectionNode->slots.clean()

     

        'sever connections leaving this item
        BEGIN_HASH(curOutgoingConnection, curConnectionNode->signals)
            BEGIN_DHASH(curOutgoingDestination, curOutgoingConnection->outgoingToSlots)
                removeID = *(curOutgoingDestination->outgoingID)        
                removeTag = *(curOutgoingDestination->outgoingSlotTag)
                thisTag = *(curOutgoingDestination->thisSignal)          
                
                deallocate(curOutgoingDestination->outgoingID)
                deallocate(curOutgoingDestination->outgoingSlotTag)
                deallocate(curOutgoingDestination->thisSignal)
                if curOutgoingDestination->appendParameter then
                    deallocate(curOutgoingDestination->appendParameter)
                end if
                
                connectedNode = connections.retrieve(removeID)
                connectedSlot = connectedNode->slots.retrieve(removeTag)
                connectedSource = connectedSlot->incomingFromSignals.retrieve(ID_, thisTag)
                
                deallocate(connectedSource->incomingId)
                deallocate(connectedSource->incomingSignalTag)
                deallocate(connectedSource->thisSlot)
                
                connectedSlot->incomingFromSignals.remove(ID_, thisTag)
                
            END_DHASH()
            curOutgoingConnection->outgoingToSlots.clean()
        END_HASH()
        curConnectionNode->signals.clean()    
        connections.remove(ID_)
    end if

        
    delete(itemPair_->item_)
    itemIdPairs.remove(ID_)
    
end sub

sub DynamicController.setLink(link_ as ObjectLink)
    link = link_
end sub

sub DynamicController.process(t as double)
    dim as DynamicController_itemPair_t ptr curItem
    redim as string removalList(0)
    dim as integer removalList_n, i


    isProcessing = 1
    removalList_n = 0
    BEGIN_HASH(curItem, itemIdPairs)
        if curItem->item_->process(t) then
            if removalList_n > 0 then redim preserve as string removalList(removalList_n)
            removalList(removalList_n) = curItem->item_->getID()
            removalList_n += 1
        end if
    END_HASH()
    isProcessing = 0
 
    for i = 0 to removalList_n - 1
        removeItem(removalList(i))
    next i
    
    BEGIN_LIST(curItem, addItemPost)
        itemIdPairs.insert(curItem->item_->getID(), curItem)
    END_LIST()
    addItemPost.flush()
    postPairs.flush()
    
end sub
sub DynamicController.drawDynamics(scnbuff as integer ptr, order as integer = ACTIVE)
    dim as Item ptr ptr curItem
    select case order
    case ACTIVE
        BEGIN_HASH(curItem, drawobjects_active)
            (*curItem)->drawItem(scnbuff)
        END_HASH()
    case ACTIVE_FRONT
        BEGIN_HASH(curItem, drawobjects_activefront)
            (*curItem)->drawItem(scnbuff)
        END_HASH() 
    case BACKGROUND
        BEGIN_HASH(curItem, drawobjects_background)
            (*curItem)->drawItem(scnbuff)
        END_HASH()     
    case FOREGROUND
        BEGIN_HASH(curItem, drawobjects_foreground)
            (*curItem)->drawItem(scnbuff)
        END_HASH()         
    case OVERLAY
        BEGIN_HASH(curItem, drawobjects_background)
            (*curItem)->drawItemOverlay(scnbuff)
        END_HASH() 
        BEGIN_HASH(curItem, drawobjects_active)
            (*curItem)->drawItemOverlay(scnbuff)
        END_HASH()  
        BEGIN_HASH(curItem, drawobjects_activefront)
            (*curItem)->drawItemOverlay(scnbuff)
        END_HASH()  
    end select 
end sub
sub DynamicController._addStringToType_(tag as string, item_t as Item_Type_e)
    stringToTypeTable.insert(tag, @item_t)
end sub
function DynamicController.itemStringToType(item_tag as string) as Item_Type_e
    dim as Item_Type_e ptr itemE_
    itemE_ = stringToTypeTable.retrieve(ucase(item_tag))
    if itemE_ then
        return *itemE_
    else
        return ITEM_NONE
    end if
end function

function DynamicController.constructItem(itemType_ as Item_Type_e, order as integer = ACTIVE, ID_ as string = "", drawless as integer) as Item ptr
    dim as DynamicController_itemPair_t ptr newItem
    dim as DynamicController_itemPair_t ptr refItem
    
    if itemType_ = ITEM_NONE then return 0
    
    newItem = allocate(sizeof(DynamicController_itemPair_t))
    
    if ID_ = "" then
        newItem->usedKeyBank = 1
        ID_ = itemIdGenerator.acquire()
    else
        newItem->usedKeyBank = 0
    end if
    
    newItem->item_ = new Item()
    newItem->item_->setLink(link)
    
    if isProcessing = 0 then
        refItem = itemIdPairs.insert(ID_, newItem)    
    else
        refItem = addItemPost.push_back(newItem)
        postPairs.insert(ID_, @refItem)
    end if

    if drawLess = 0 then
        if order = ACTIVE_FRONT then
            drawobjects_activeFront.insert(ID_, @refItem->item_)
        elseif order = ACTIVE then
            drawobjects_active.insert(ID_, @refItem->item_)
        elseif order = BACKGROUND then
            drawobjects_background.insert(ID_, @refItem->item_) 
        elseif order = FOREGROUND then
            drawobjects_foreground.insert(ID_, @refItem->item_) 
        end if
    end if
  
    refItem->item_->construct(itemType_, ID_)

    deallocate(newItem)
      
    return refItem->item_
end function
sub DynamicController.initItem(itemToInit as Item ptr, p_ as Vector2D = Vector2D(0, 0), size_ as Vector2D = Vector2D(0, 0), depth_ as single = 1.0)
    itemToInit->initPost(p_, size_, depth_)
end sub
function DynamicController.addItem(itemType_ as Item_Type_e, order as integer = ACTIVE, p_ as Vector2D, size_ as Vector2D, _
                                   ID_ as string = "", depth_ as single = 1.0, drawLess as integer = 0) as string
    dim as DynamicController_itemPair_t ptr newItem
    dim as DynamicController_itemPair_t ptr refItem
    
    
    if itemType_ = ITEM_NONE then return ""
    
    newItem = allocate(sizeof(DynamicController_itemPair_t))
    
    if ID_ = "" then
        newItem->usedKeyBank = 1
        ID_ = itemIdGenerator.acquire()
    else
        newItem->usedKeyBank = 0
    end if
    
    newItem->item_ = new Item()
    newItem->item_->setLink(link)
    
    if isProcessing = 0 then
        refItem = itemIdPairs.insert(ID_, newItem)    
    else
        refItem = addItemPost.push_back(newItem)
    end if
    
    if drawLess = 0 then
        if order = ACTIVE_FRONT then
            drawobjects_activeFront.insert(ID_, @refItem->item_)
        elseif order = ACTIVE then
            drawobjects_active.insert(ID_, @refItem->item_)
        elseif order = BACKGROUND then
            drawobjects_background.insert(ID_, @refItem->item_) 
        elseif order = FOREGROUND then
            drawobjects_foreground.insert(ID_, @refItem->item_) 
        end if
    end if
  
    refItem->item_->init(itemType_, p_, size_, ID_, depth_)
   
    deallocate(newItem)
 
    return ID_
end function
function DynamicController.hasItem(ID_ as string) as integer
    return itemIdPairs.exists(ID_)
end function
sub DynamicController.setPos(ID_ as string, p_ as Vector2D)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)
    if curItem then curItem->item_->setPos(p_)
end sub
sub DynamicController.setSize(ID_ as string, size_ as Vector2D)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)
    if curItem then curItem->item_->setSize(size_)
end sub

function DynamicController.getPos(ID_ as string) as Vector2D
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)
    if curItem then return(curItem->item_->getPos())
    return Vector2D(0, 0)
end function

function DynamicController.getSize(ID_ as string) as Vector2D
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)
    if curItem then return(curItem->item_->getSize())
    return Vector2D(0, 0)
end function

sub DynamicController.getBounds(ID_ as string, byref a as Vector2D, byref b as Vector2D)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)
    if curItem then 
        curItem->item_->getBounds(a, b)
    else
        a = Vector2D(0, 0)
        b = Vector2D(0, 0)
    end if
end sub

sub DynamicController.setParameter(param_ as Vector2D, ID_ as string, param_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then curItem->item_->setParameter(param_, param_tag)
end sub
sub DynamicController.setParameter(param_ as integer, ID_ as string, param_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then curItem->item_->setParameter(param_, param_tag)
end sub
sub DynamicController.setParameter(param_ as double, ID_ as string, param_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then curItem->item_->setParameter(param_, param_tag)
end sub
sub DynamicController.setParameter(param_ as string, ID_ as string, param_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then curItem->item_->setParameter(param_, param_tag)
end sub

sub DynamicController.getValue(byref value_ as Vector2D, ID_ as string, value_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    ID_ = ucase(ID_)
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then 
        curItem->item_->getValue(value_, value_tag)
    else
        value_ = Vector2D(0, 0)
    end if
end sub
sub DynamicController.getValue(byref value_ as integer, ID_ as string, value_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    ID_ = ucase(ID_)
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then 
        curItem->item_->getValue(value_, value_tag)
    else
        value_ = 0
    end if
end sub
sub DynamicController.getValue(byref value_ as double, ID_ as string, value_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    ID_ = ucase(ID_)
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then 
        curItem->item_->getValue(value_, value_tag)
    else
        value_ = 0.0
    end if
end sub
sub DynamicController.getValue(byref value_ as string, ID_ as string, value_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    ID_ = ucase(ID_)
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then 
        curItem->item_->getValue(value_, value_tag)
    else
        value_ = ""
    end if
end sub

sub DynamicController.queryValues(value_set as ObjectValueSet, value_tag as string, queryShape as Shape2D ptr)
    dim as DynamicController_publish_t ptr ptr ptr publishedValuesPtr
    dim as DynamicController_publish_t ptr ptr publishedValues
    dim as any ptr ptr parameterPtrPtr
    dim as integer publishedValues_n, i
    dim as string tag
    dim as Vector2D a, b, curOffset
    value_tag = ucase(value_tag)
    if queryShape = 0 then
        publishedValues_n = allPublishedValues.retrieveKey2(value_tag, parameterPtrPtr)
        publishedValues = parameterPtrPtr
        for i = 0 to publishedValues_n - 1
            tag = *(publishedValues[i]->tag_)
            value_set._addValue_(publishedValues[i]->item_->getID(), publishedValues[i]->item_->getValueContainer(tag), 0)
        next i
        if publishedValues_n then deallocate(publishedValues)
    else
        queryShape->getBoundingBox(a, b)
        publishedValues_n = valueTargets.search(a, b, publishedValuesPtr)
        
        for i = 0 to publishedValues_n - 1
            tag = *((*(publishedValuesPtr[i]))->tag_)
            if tag = value_tag orElse (value_tag = "") then
                if intersect2D((*(publishedValuesPtr[i]))->target, queryShape) then
                    value_set._addValue_((*(publishedValuesPtr[i]))->item_->getID(), (*(publishedValuesPtr[i]))->item_->getValueContainer(tag), (*(publishedValuesPtr[i]))->target)
                end if
            end if
        next i
        if publishedValues_n then deallocate(publishedValuesPtr)

    end if
end sub

sub DynamicController.querySlots(slot_set as ObjectSlotSet, slot_tag as string, queryShape as Shape2D ptr)
    dim as DynamicController_publishSlot_t ptr ptr ptr publishedSlotsPtr
    dim as DynamicController_publishSlot_t ptr ptr publishedSlots
    dim as any ptr ptr parameterPtrPtr 
    dim as integer publishedSlots_n, i
    dim as string tag
    dim as Vector2D a, b, curOffset
    slot_set._setLink_(link)
    slot_tag = ucase(slot_tag)
    if queryShape = 0 then
        
        publishedSlots_n = allPublishedSlots.retrieveKey2(slot_tag, parameterPtrPtr)
        publishedSlots = parameterPtrPtr
        for i = 0 to publishedSlots_n - 1
            tag = *(publishedSlots[i]->slot_tag_)
            slot_set._addSlot_(publishedSlots[i]->item_->getID(), tag, 0)
        next i
        if publishedSlots_n then deallocate(publishedSlots)
    else
        queryShape->getBoundingBox(a, b)
        publishedSlots_n = slotTargets.search(a, b, publishedSlotsPtr)
        
        for i = 0 to publishedSlots_n - 1
            tag = *((*(publishedSlotsPtr[i]))->slot_tag_)
            if *((*(publishedSlotsPtr[i]))->tag_) = slot_tag orElse (slot_tag = "") then            
                if intersect2D((*(publishedSlotsPtr[i]))->target, queryShape) then    
                    slot_set._addSlot_((*(publishedSlotsPtr[i]))->item_->getID(), tag, (*(publishedSlotsPtr[i]))->target)
                end if
            end if
        next i
        if publishedSlots_n then deallocate(publishedSlotsPtr)
       
    end if
end sub
sub DynamicController.addPublishedValue(publishee_ID as string, value_tag as string, target as Shape2D ptr = 0)
    dim as DynamicController_publish_t pvalue
    dim as DynamicController_publish_t ptr pvaluePtr
    dim as Vector2D a, b
    pvalue.tag_ = allocate(len(value_tag) + 1)
    *(pvalue.tag_) = value_tag
    pvalue.target = target
    if isProcessing = 0 then
        pvalue.item_ = cast(DynamicController_itemPair_t ptr, itemIdPairs.retrieve(publishee_ID))->item_
    else
        pvalue.item_ = (*cast(DynamicController_itemPair_t ptr ptr, postPairs.retrieve(publishee_ID)))->item_
    end if
    pvaluePtr = allPublishedValues.insert(publishee_ID, value_tag, @pvalue)
    pvaluePtr->hash2Dindex = 0
end sub
sub DynamicController.addPublishedSlot(publishee_ID as string, slot_tag as string, actual_slot_tag as string, target as Shape2D ptr)
    dim as DynamicController_publishSlot_t pslot
    dim as DynamicController_publishSlot_t ptr pslotPtr
    dim as Vector2D a, b
 
    pslot.tag_ = allocate(len(slot_tag) + 1)
    *(pslot.tag_) = slot_tag
    pslot.slot_tag_ = allocate(len(actual_slot_tag) + 1)
    *(pslot.slot_tag_) = actual_slot_tag  

    pslot.target = target
    if isProcessing = 0 then
        pslot.item_ = cast(DynamicController_itemPair_t ptr, itemIdPairs.retrieve(publishee_ID))->item_
    else
        pslot.item_ = (*cast(DynamicController_itemPair_t ptr ptr, postPairs.retrieve(publishee_ID)))->item_    
    end if
   
    pslotPtr = allPublishedSlots.insert(publishee_ID, slot_tag, @pslot)
    pslotPtr->hash2Dindex = 0
end sub
sub DynamicController.setTargetValueOffset(ID_ as string, value_tag as string, offset as Vector2D) 
    dim as DynamicController_publish_t ptr publishValue
    dim as Vector2D a, b
    value_tag = ucase(value_tag)
    publishValue = allPublishedValues.retrieve(ID_, value_tag)
    if publishValue then
        if publishValue->target then
            publishValue->target->setOffset(offset)
            publishValue->target->getBoundingBox(a, b)         
            
            if publishValue->hash2Dindex then valueTargets.remove(publishValue->hash2Dindex)
            publishValue->hash2dindex = valueTargets.insert(a, b, @publishValue)
        end if
    end if
end sub
sub DynamicController.setTargetSlotOffset(ID_ as string, slot_tag as string, offset as Vector2D)
    dim as DynamicController_publishSlot_t ptr publishSlot
    dim as Vector2D a, b
    slot_tag = ucase(slot_tag)
    publishSlot = allPublishedSlots.retrieve(ID_, slot_tag)
    if publishSlot then
        if publishSlot->target then 
            publishSlot->target->setOffset(offset)
            publishSlot->target->getBoundingBox(a, b)
            
            if publishSlot->hash2Dindex then slotTargets.remove(publishSlot->hash2Dindex)
            publishSlot->hash2dindex = slotTargets.insert(a, b, @publishSlot)
        end if
    end if
end sub
sub DynamicController.throw(signal_ID as string, signal_tag as string, parameter_string as string = "")
    dim as DynamicController_connectionNode_t ptr itemNode
    dim as DynamicController_connectionOutgoing_t ptr outgoingSignal
    dim as DynamicController_connectionOutgoingDestination_t ptr curSlot
    dim as string thisParameterString
   
    itemNode = connections.retrieve(signal_ID)

    if itemNode then
     
        outgoingSignal = itemNode->signals.retrieve(signal_tag)
        if outgoingSignal then
            BEGIN_DHASH(curSlot, outgoingSignal->outgoingToSlots)
                if curSlot->appendParameter then
                    if parameter_string = "" then
                        thisParameterString = *(curSlot->appendParameter)
                    else
                        thisParameterString = parameter_string + "," + *(curSlot->appendParameter)
                    end if
                else
                    thisParameterString = parameter_string
                end if
                
                fireSlot(*(curSlot->outgoingID), *(curSlot->outgoingSlotTag), thisParameterString)
            END_DHASH()
        end if
    end if
end sub
sub DynamicController.fireSlot(ID_ as string, slot_tag as string, parameter_string as string = "")
    dim as DynamicController_itemPair_t ptr curItem
    ID_ = ucase(ID_)
    curItem = itemIdPairs.retrieve(ID_)
    if curItem then curItem->item_->fireSlot(slot_tag, parameter_string)
end sub

function DynamicController.getItem(ID_ as string) as Item ptr
    if hasItem(ID_) then
        return cast(DynamicController_itemPair_t ptr, itemIdPairs.retrieve(ID_))->item_
    end if
    return 0
end function

sub DynamicController.connect(signal_ID as string, signal_tag as string, slot_ID as string, slot_tag as string, parameter_string as string = "")
    dim as DynamicController_connectionNode_t ptr itemNode
    dim as DynamicController_connectionNode_t ptr newItemNode
    
    dim as DynamicController_connectionOutgoing_t ptr signalNode
    dim as DynamicController_connectionOutgoing_t ptr newSignalNode   
    
    dim as DynamicController_connectionIncoming_t ptr slotNode
    dim as DynamicController_connectionIncoming_t ptr newSlotNode
    
    dim as DynamicController_connectionOutgoingDestination_t signalDestination
    dim as DynamicController_connectionIncomingSource_t slotSource
    
    dim as Item ptr item_
    
    signal_ID = ucase(signal_ID)
    signal_tag = ucase(signal_tag)
    slot_ID = ucase(slot_ID)
    slot_tag = ucase(slot_tag)
    
    item_ = getItem(signal_ID)
    if item_->isSignal(signal_tag) = 0 then exit sub


    itemNode = connections.retrieve(signal_ID)
    if itemNode = 0 then 
        newItemNode = allocate(sizeof(DynamicController_connectionNode_t))
        newItemNode->slots.construct_()
        newItemNode->signals.construct_() 
        
        newItemNode->slots.init(sizeof(DynamicController_connectionIncoming_t))
        newItemNode->signals.init(sizeof(DynamicController_connectionOutgoing_t))
        itemNode = connections.insert(signal_ID, newItemNode)
        
        deallocate(newItemNode)
    end if
    
    
    signalNode = itemNode->signals.retrieve(signal_tag)
    if signalNode = 0 then 
        newSignalNode = allocate(sizeof(DynamicController_connectionOutgoing_t))
        newSignalNode->outgoingToSlots.construct_()
        
        newSignalNode->outgoingToSlots.init(sizeof(DynamicController_connectionOutgoingDestination_t))
        signalNode = itemNode->signals.insert(signal_tag, newSignalNode)
        
        deallocate(newSignalNode) 
    end if    
    
    
    
    if signalNode->outgoingToSlots.exists(slot_ID, slot_tag) then exit sub
    
    signalDestination.outgoingID = allocate(len(slot_ID) + 1)
    *(signalDestination.outgoingID) = slot_ID
    signalDestination.outgoingSlotTag = allocate(len(slot_tag) + 1)
    *(signalDestination.outgoingSlotTag) = slot_tag  
    
    parameter_string = stripwhite(parameter_string)
    if parameter_string = "" then
        signalDestination.appendParameter = 0
    else
        signalDestination.appendParameter = allocate(len(parameter_string) + 1)
        *(signalDestination.appendParameter) = parameter_string
    end if
    
    signalDestination.thisSignal = allocate(len(signal_tag) + 1)
    *(signalDestination.thisSignal) = signal_tag        
    
    signalNode->outgoingToSlots.insert(slot_ID, slot_tag, @signalDestination)
    
    
    itemNode = connections.retrieve(slot_ID)
    if itemNode = 0 then 
        newItemNode = allocate(sizeof(DynamicController_connectionNode_t))
        newItemNode->slots.construct_()
        newItemNode->signals.construct_()
        
        newItemNode->slots.init(sizeof(DynamicController_connectionIncoming_t))
        newItemNode->signals.init(sizeof(DynamicController_connectionOutgoing_t))
        itemNode = connections.insert(slot_ID, newItemNode)
        
        deallocate(newItemNode)
    end if
    
    slotNode = itemNode->slots.retrieve(slot_tag)
    if slotNode = 0 then 
        newSlotNode = allocate(sizeof(DynamicController_connectionIncoming_t))
        newSlotNode->incomingFromSignals.construct_()
        
        newSlotNode->incomingFromSignals.init(sizeof(DynamicController_connectionIncomingSource_t))
        slotNode = itemNode->slots.insert(slot_tag, newSlotNode)
        
        deallocate(newSlotNode)
    end if    
    
    slotSource.incomingId = allocate(len(signal_ID) + 1)
    *(slotSource.incomingId) = signal_ID
    slotSource.incomingSignalTag = allocate(len(signal_tag) + 1)
    *(slotSource.incomingSignalTag) = signal_tag    
    slotSource.thisSlot = allocate(len(slot_tag) + 1)
    *(slotSource.thisSlot) = slot_tag        
    
    slotNode->incomingFromSignals.insert(signal_ID, signal_tag, @slotSource)
    
end sub                 

sub DynamicController.setParameterFromString(param_string as string, ID_ as string, param_tag as string)
    dim as _Item_valueContainer_t value_   
    Item.valueFormToContainer(param_string, value_)
    select case value_.type_
    case _ITEM_VALUE_VECTOR2D
        setParameter(Vector2D(value_.data_.Vector2D_.xs, value_.data_.Vector2D_.ys), ID_, param_tag)
    case _ITEM_VALUE_INTEGER
        setParameter(value_.data_.integer_, ID_, param_tag)
    case _ITEM_VALUE_DOUBLE
        setParameter(value_.data_.double_, ID_, param_tag)
    case _ITEM_VALUE_ZSTRING
        setParameter(*(value_.data_.zstring_), ID_, param_tag)       
        deallocate(value_.data_.zstring_)
    end select
end sub

function DynamicController.populateLightList(ll as LightPair ptr ptr) as integer 
    dim as DynamicController_itemPair_t ptr curItem
    dim as Item ptr ditem
    dim as integer nlights, i
    dim as LightPair ptr lp
    dim as Vector2d scn_a, scn_b
    dim as Vector2d light_a, light_b
    
    scn_a = link.gamespace_ptr->camera - Vector2D(SCRX, SCRY)*0.5
    scn_b = link.gamespace_ptr->camera + Vector2D(SCRX, SCRY)*0.5
    
    nlights = 0
   
    BEGIN_HASH(curItem, itemIdPairs)
        ditem = curItem->item_
 
        if ditem->hasLight() then
        
            lp = ditem->getLightingData()
            light_a = Vector2D(lp->texture.x, lp->texture.y) - Vector2D(lp->texture.w, lp->texture.h)*0.5 - Vector2D(128, 128)
            light_b = Vector2D(lp->texture.x, lp->texture.y) + Vector2D(lp->texture.w, lp->texture.h)*0.5 + Vector2D(128, 128)
            
            if (light_a.x < scn_b.x) andAlso (light_b.x > scn_a.x) andAlso _
               (light_a.y < scn_b.y) andAlso (light_b.y > scn_a.y) then

                ll[nlights] = lp
                nlights += 1
            end if
            
        end if
    
    END_HASH()
   
    return nlights	
end function
