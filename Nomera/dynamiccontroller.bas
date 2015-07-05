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
    itemIdPairs.init(sizeof(DynamicController_itemPair_t))
    drawobjects_active.init(sizeof(Item ptr))
    drawobjects_activeFront.init(sizeof(Item ptr))
    
    #include "objects\headers\gen_namestypes.bi"
    
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
    dim as DynamicController_connectionIncomingSource_t ptr curIncomingSource
    dim as DynamicController_publish_t ptr curPublish
    dim as DynamicController_itemPair_t ptr curItem
    
    valueTargets.flush()
    slotTargets.flush()
    stringToTypeTable.flush()
    drawobjects_active.flush()
    drawobjects_activefront.flush()
    
    BEGIN_DHASH(curPublish, allPublishedValues)
        deallocate(curPublish->tag_)
    END_DHASH()
    allPublishedValues.flush()
    BEGIN_DHASH(curPublish, allPublishedSlots)
        deallocate(curPublish->tag_)
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
                deallocate(curOutgoingDestination->outgoingSignalTag)
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
        curItem->item_->flush()
        delete(curItem->item_)
    END_HASH()
    itemIdPairs.flush()
    
end sub
sub DynamicController.removeItem(ID_ as string)
    dim as DynamicController_itemPair_t ptr itemPair_
    dim as DynamicController_publish_t ptr ptr publishedVals
    dim as DynamicController_connectionNode_t ptr curConnectionNode
    dim as DynamicController_connectionIncoming_t ptr curIncomingConnection
    dim as DynamicController_connectionOutgoing_t ptr curOutgoingConnection
    dim as DynamicController_connectionOutgoingDestination_t ptr curOutgoingDestination
    dim as DynamicController_connectionIncomingSource_t ptr curIncomingSource
    dim as DynamicController_connectionNode_t ptr connectedNode
    dim as DynamicController_connectionOutgoing_t ptr connectedSignal
    dim as DynamicController_connectionOutgoingDestination_t connectedDestination
    dim as DynamicController_connectionIncoming_t ptr connectedSlot
    dim as DynamicController_connectionIncomingSource_t connectedSource    
    dim as integer outConnections_n, removeConnections_n
    dim as string removeID, removeTag, thisTag
    dim as integer publishedVals_N, i
    
    itemPair_ = itemIdPairs.retrieve(ID_)
    if itemPair_->usedKeyBank then itemIdGenerator.relinquish(ID_)
     
    publishedVals_N = allPublishedValues.retrieveKey1(ID_, publishedVals)
    if publishedVals_N then
        for i = 0 to publishedVals_N - 1
            if not(publishedVals[i]->target is EmptyShape2D) then
                valueTargets.remove(publishedVals[i]->hash2Dindex)
            end if
            deallocate(publishedVals[i]->tag_)
        next i
        allPublishedValues.removeKey1(ID_)
        deallocate(publishedVals)
    end if
    
    publishedVals_N = allPublishedSlots.retrieveKey1(ID_, publishedVals)
    if publishedVals_N then
        for i = 0 to publishedVals_N - 1
            if not(publishedVals[i]->target is EmptyShape2D) then
                slotTargets.remove(publishedVals[i]->hash2Dindex)
            end if
            deallocate(publishedVals[i]->tag_)
        next i
        allPublishedSlots.removeKey1(ID_)
        deallocate(publishedVals)
    end if
    
    if drawObjects_active.exists(ID_) then
        drawObjects_active.remove(ID_)
    elseif drawObjects_activeFront.exists(ID_) then
        drawObjects_activeFront.remove(ID_)
    end if
    
    curConnectionNode = connections.retrieve(ID_)
    'sever connections coming in to this item
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
        curOutgoingConnection->outgoingToSlots.clean()s
    END_HASH()
    curConnectionNode->signals.clean()    
    connections.remove(ID_)
    
    delete(itemPair_->item_)
    itemIdPairs.remove(ID_)
    
end sub

sub DynamicController.setLink(link_ as ObjectLink)
    link = link_
end sub

sub DynamicController.process(t as double)
    dim as DynamicController_itemPair ptr curItem
    redim as string removalList(0)
    dim as integer removalList_n, i
    
    removalList_n = 0
    BEGIN_HASH(curItem, itemIdPairs)
        if curItem->item_->process(t) then
            if removalList_n > 0 then redim preserve as string removalList(removalList_n)
            removalList(removalList_n) = curItem->item_->getID()
            removalList_n += 1
        end if
    END_HASH()
    
    for i = 0 to removalList_n - 1
        removeItem(removalList(i))
    next i
    
end sub
sub DynamicController.drawDynamics(scnbuff as integer ptr, order as integer = ACTIVE)
    dim as Item ptr curItem
    select case order
    case ACTIVE
        BEGIN_HASH(curItem, drawobjects_active)
            (*curItem)->drawItem(scnbuff)
        END_HASH()
    case ACTIVE_FRONT
        BEGIN_HASH(curItem, drawobjects_activefront)
            (*curItem)->drawItem(scnbuff)
        END_HASH()    
    case OVERLAY
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
    itemE = stringToTypeTable.retrieve(item_tag)
    if itemE then
        return *itemE
    else
        return ITEM_NONE
    end if
end function
function DynamicController.addItem(itemType_ as Item_Type_e, order as integer = ACTIVE, p_ as Vector2D, size_ as Vector2D, ID_ as string = "") as string
    dim as DynamicController_itemPair_t ptr newItem
    
    if itemType_ = ITEM_NONE then return ""
    
    newItem = allocate(sizeof(DynamicController_itemPair_t))
    
    if ID_ = "" then
        newItem->usedKeyBank = 1
        ID_ = itemIdGenerator.acquire()
    else
        newItem->usedKeyBank = 0
    end if
    
    newItem->item_ = new Item()
    
    itemIdPairs.insert(ID_, newItem)
    if order = ACTIVE_FRONT then
        drawobjects_activeFront.insert(ID_, @newItem->item_)
    else
        drawobjects_active.insert(ID_, @newItem->item_)
    end if

    'adds published values and slots itself
    newItem->init(itemType_, p_, size_, ID_)

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
    if curItem then curItem->setParameter(param_, param_tag)
end sub
sub DynamicController.setParameter(param_ as integer, ID_ as string, param_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then curItem->setParameter(param_, param_tag)
end sub
sub DynamicController.setParameter(param_ as double, ID_ as string, param_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then curItem->setParameter(param_, param_tag)
end sub
sub DynamicController.setParameter(param_ as string, ID_ as string, param_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then curItem->setParameter(param_, param_tag)
end sub

sub DynamicController.getValue(byref value_ as Vector2D, ID_ as string, value_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then 
        curItem->getValue(value_, value_tag)
    else
        value_ = Vector2D(0, 0)
    end if
end sub
sub DynamicController.getValue(byref value_ as integer, ID_ as string, value_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then 
        curItem->getValue(value_, value_tag)
    else
        value_ = 0
    end if
end sub
sub DynamicController.getValue(byref value_ as double, ID_ as string, value_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then 
        curItem->getValue(value_, value_tag)
    else
        value_ = 0.0
    end if
end sub
sub DynamicController.getValue(byref value_ as string, ID_ as string, value_tag as string)
    dim as DynamicController_itemPair_t ptr curItem
    curItem = itemIdPairs.retrieve(ID_)   
    if curItem then 
        curItem->getValue(value_, value_tag)
    else
        value_ = ""
    end if
end sub

sub DynamicController.queryValues(value_set as ObjectValueSet, value_tag as string, queryShape as Shape2D = EmptyShape2D())
    dim as DynamicController_publish_t ptr ptr ptr publishedValuesPtr
    dim as DynamicController_publish_t ptr ptr publishedValues
    dim as integer publishedValues_n, i
    dim as string tag
    dim as Vector2D a, b, curOffset
    if queryShape is EmptyShape2D then
        publishedValues_n = allPublishedValues.retrieveKey2(value_tag, publishedValues)
        for i = 0 to publishedValues_n - 1
            tag = *(publishedValues[i]->tag_)
            value_set._addValue_(publishedValues[i]->item_->getID(), publishedValues[i]->item_->getValueContainer(tag), EmptyShape2D())
        next i
        if publishedValues_n then deallocate(publishedValues)
    else
        queryShape.getBoundingBox(a, b)
        publishedValues_n = valueTargets.search(a, b, publishedValuesPtr)
        curOffset = queryShape.getOffset()
        for i = 0 to pubilshedValues_n - 1
            tag = *((*(publishedValuesPtr[i]))->tag_)
            if tag = value_tag then
                queryShape.setOffset(curOffset - (*(publishedValuesPtr[i]))->item_->getPos())
                if intersect2D((*(publishedValuesPtr[i]))->target, queryShape) then
                    value_set._addValue_((*(publishedValuesPtr[i]))->item_->getID(), (*(publishedValuesPtr[i]))->item_->getValueContainer(tag), (*(publishedValuesPtr[i]))->target)
                end if
            end if
        next i
        queryShape.setOffset(curOffset)
        if publishedValues_n then deallocate(publishedValuesPtr)
    end if
end sub

sub DynamicController.querySlots(slot_set as ObjectSlotSet, slot_tag as string, queryShape as Shape2D = EmptyShape2D())
    dim as DynamicController_publish_t ptr ptr ptr publishedSlotsPtr
    dim as DynamicController_publish_t ptr ptr publishedSlots
    dim as integer publishedSlots_n, i
    dim as string tag
    dim as Vector2D a, b, curOffset
    slot_set.setLink(link)
    if queryShape is EmptyShape2D then
        publishedSlots_n = allPublishedSlots.retrieveKey2(slot_tag, publishedSlots)
        for i = 0 to publishedSlots_n - 1
            tag = *(publishedSlots[i]->tag_)
            slot_set._addSlot_(publishedSlots[i]->item_->getID(), tag, EmptyShape2D())
        next i
        if publishedSlots_n then deallocate(publishedSlots)
    else
        queryShape.getBoundingBox(a, b)
        publishedSlots_n = slotTargets.search(a, b, publishedSlotsPtr)
        curOffset = queryShape.getOffset()
        for i = 0 to publishedSlots_n - 1
            tag = *((*(publishedSlotsPtr[i]))->tag_)
            if tag = slot_tag then
                queryShape.setOffset(curOffset - (*(publishedSlotsPtr[i]))->item_->getPos())
                if intersect2D((*(publishedSlotsPtr[i]))->target, queryShape) then    
                    slot_set._addSlot_((*(publishedSlotsPtr[i]))->item_->getID(), tag, (*(publishedSlotsPtr[i]))->target)
                end if
            end if
        next i
        queryShape.setOffset(curOffset)
        if publishedSlots_n then deallocate(publishedSlotsPtr)
    end if
end sub
sub DynamicController.addPublishedValue(publishee_ID as string, value_tag as string, target as Shape2D = EmptyShape2D())
    dim as DynamicController_publish_t pvalue
    dim as DynamicController_publish_t ptr pvaluePtr
    dim as Vector2D a, b
    pvalue.tag_ = allocate(len(value_tag) + 1)
    *(pvalue.tag_) = value_tag
    pvalue.target = target
    pvalue.item_ = cast(DynamicController_itemPair_t ptr, itemIdPairs.retrieve(publishee_ID))->item_
    pvaluePtr = allPublishedValues.insert(publishee_ID, value_tag, @pvalue)
    if not (target is EmptyShape2D) then
        target.getBoundingBox(a, b)
        pvaluePtr->hash2Dindex = valueTargets.insert(a, b, @pvaluePtr)
    end if
end sub
sub DynamicController.addPublishedSlot(publishee_ID as string, slot_tag as string, target as Shape2D = EmptyShape2D())
    dim as DynamicController_publish_t pslot
    dim as DynamicController_publish_t ptr pslotPtr
    dim as Vector2D a, b
    pslot.tag_ = allocate(len(slot_tag) + 1)
    *(pslot.tag_) = slot_tag
    pslot.target = target
    pslot.item_ = cast(DynamicController_itemPair_t ptr, itemIdPairs.retrieve(publishee_ID))->item_
    pslotPtr = allPublishedSlots.insert(publishee_ID, slot_tag, @pslot)
    if not (target is EmptyShape2D) then
        target.getBoundingBox(a, b)
        pslotPtr->hash2Dindex = slotTargets.insert(a, b, @pslotPtr)
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
    if not item_->isSignal(signal_tag) then exit sub
    /'
    item_ = getItem(slot_ID)
    if not item_->isSignal(slot_tag) then exit sub   
    '/
    
    itemNode = connections.retrieve(signal_ID)
    if itemNode = 0 then 
        newItemNode = new DynamicController_connectionNode_t()
        newItemNode->slots.init(sizeof(DynamicController_connectionIncoming_t))
        newItemNode->signals.init(sizeof(DynamicController_connectionOutgoing_t))
        itemNode = connections.insert(signal_ID, newItemNode)
        delete newItemNode
    end if
    
    signalNode = itemNode->signals.retrieve(signal_tag)
    if signalNode = 0 then 
        newSignalNode = new DynamicController_connectionOutgoing_t()
        newSignalNode->outgoingToSlots.init(sizeof(DynamicController_connectionOutgoingDestination_t))
        signalNode = itemNode->signals.insert(signal_tag, newSignalNode)
        delete newSignalNode
    end if    
    
    if signalNode->outgoingToSlots.exists(slot_ID, slot_tag) then exit sub
    
    signalDestination.outgoingID = allocate(len(slot_ID) + 1)
    *(signalDestination.outgoingID) = slot_ID
    signalDestination.outgoingSlotTag = allocate(len(slot_tag) + 1)
    *(signalDestination.outgoingSlotTag) = slot_tag  
    
    parameter_string = stripwhie(parameter_string)
    if parameter_string = "" then
        signalDestination.appendParameter = 0
    else
        signalDestination.appendParameter = allocate(len(parameter_string) + 1)
        *(signalDestination.appendParameter) = parameter_string
    end if
    
    signalDestination.thisSignal = allocate(len(signal_tag) + 1)
    *(signalDestination.thisSignal) = signal_tag        
    
    signalNode->outgoingToSlots.insert(slotID, slot_tag, @signalDestination)
    
    
    itemNode = connections.retrieve(slot_ID)
        if itemNode = 0 then 
        newItemNode = new DynamicController_connectionNode_t()
        newItemNode->slots.init(sizeof(DynamicController_connectionIncoming_t))
        newItemNode->signals.init(sizeof(DynamicController_connectionOutgoing_t))
        itemNode = connections.insert(slot_ID, newItemNode)
        delete newItemNode
    end if
    
    slotNode = itemNode->slots.retrieve(slot_tag)
    if slotNode = 0 then 
        newSlotNode = new DynamicController_connectionIncoming_t()
        newSlotNode->incomingFromSignals.init(sizeof(DynamicController_connectionIncomingSource_t))
        slotNode = itemNode->slots.insert(slot_tag, newSlotNode)
        delete newSlotNode
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
        setParameter(value_.data_.Vector2D_, ID_, param_tag)
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
