#include "keybank.bi"

constructor KeyBank()
    keys.init(sizeof(KeyBank_node_t))
    curVal = 0
end constructor
destructor KeyBank()
    flush()
end destructor
function KeyBank.acquire() as string
    dim as KeyBank_node_t curNode
    dim as string keyString
    
    keyString = "[" + str(curVal) + "]"
    curNode.key = allocate(len(keyString) + 1)
    *(curNode.key) = keyString
    keys.insert(keyString, @curNode)
    
    curVal += 1
    
    return keyString
end function
sub KeyBank.relinquish(key as string)
    dim as KeyBank_node_t ptr curNode_
    curNode_ = keys.retrieve(key)
    if curNode_ then
        deallocate(curNode_->key)
        keys.remove(key)
    end if
end sub
sub KeyBank.flush()
    dim as KeyBank_node_t ptr curNode_
    BEGIN_HASH(curNode_, keys)
        deallocate(curNode_->key)
    END_HASH()
    keys.flush()
    curVal = 0
end sub
sub KeyBank.serialize_out(pbin as PackedBinary)
    dim as KeyBank_node_t ptr curNode_
    pbin.store(keys.getSize())
    BEGIN_HASH(curNode_, keys)
        pbin.store(*(curNode_->key))
    END_HASH()   
    pbin.store(curVal)
end sub
sub KeyBank.serialize_in(pbin as PackedBinary)
    dim as integer numKeys
    dim as integer i
    dim as string keyString
    dim as KeyBank_node_t curNode
    flush()
    pbin.retrieve(numKeys)
    for i = 0 to numKeys - 1
        pbin.retrieve(keyString)
        curNode.key = allocate(len(keyString) + 1)
        *(curNode.key) = keyString
        keys.insert(keyString, @curNode)    
    next i
    pbin.retrieve(curVal)
end sub
