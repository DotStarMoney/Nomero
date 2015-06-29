#include "keybank.bi"

constructor KeyBank()
    keys.init(sizeof(KeyBank_node_t))
end constructor
destructor KeyBank()
    flush()
end destructor
function KeyBank.acquire() as string
    dim as KeyBank_node_t curNode
    curNode.memAddr = allocate(sizeof(integer))
    curNode.key = "[" + str(cast(ULongInt, curNode.memAddr)) + "]"
    keys.insert(curNode.key, @curNode)
    return curNode.key
end function
sub KeyBank.relinquish(key as string)
    dim as KeyBank_node_t ptr curNode_
    curNode_ = keys.retrieve(key)
    if curNode_ then
        deallocate(curNode_->memAddr)
        curNode_->key = ""
        keys.delete(key)
    end if
end sub
sub KeyBank.flush()
    dim as KeyBank_node_t ptr curNode_
    BEGIN_HASH(curNode_, keys)
        deallocate(curNode_->memAddr)
        curNode_->key = ""
    END_HASH()
end sub

