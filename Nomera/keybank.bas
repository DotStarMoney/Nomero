#include "keybank.bi"

constructor KeyBank()
    keys.init(sizeof(KeyBank_node_t))
end constructor
destructor KeyBank()
    flush()
end destructor
function KeyBank.acquire() as string
    dim as KeyBank_node_t curNode
    dim as string keyString
    curNode.memAddr = allocate(sizeof(integer))
    keyString = "[" + str(curNode.memAddr) + "]"
    curNode.key = allocate(len(keyString) + 1)
    *(curNode.key) = keyString
    keys.insert(keyString, @curNode)
    return keyString
end function
sub KeyBank.relinquish(key as string)
    dim as KeyBank_node_t ptr curNode_
    curNode_ = keys.retrieve(key)
    if curNode_ then
        deallocate(curNode_->memAddr)
        deallocate(curNode_->key)
        keys.remove(key)
    end if
end sub
sub KeyBank.flush()
    dim as KeyBank_node_t ptr curNode_
    BEGIN_HASH(curNode_, keys)
        deallocate(curNode_->memAddr)
        deallocate(curNode_->key)
    END_HASH()
end sub

