#include "list.bi"
#include "crt.bi"

#ifdef DEBUG
    #include "utility.bi"
#endif

constructor List()
    head_ = 0
    tail_ = 0
    size = 0
    dataSizeBytes = 0
    curRollNode_ = 0
end constructor

destructor List()
    flush()
end destructor

sub List.init(dataSizeBytes as integer)
    this.dataSizeBytes = dataSizeBytes
end sub
        
sub List.push_back(data_ as any ptr)
    dim as ListNode_t ptr newNode_
    
    newNode_ = allocate(sizeof(ListNode_t))
    newNode_->data_ = allocate(dataSizeBytes)
    memcpy(newNode_->data_, data_, dataSizeBytes)
    newNode_->next_ = 0
    
    if tail_ = 0 then
        newNode_->prev_ = 0
    else
        newNode_->prev_ = tail_
        tail_->next_ = newNode_
    end if
    
    tail_ = newNode_
    
    if head_ = 0 then
        head_ = newNode_
    end if
    
    size += 1
end sub

sub List.push_front(data_ as any ptr)
    dim as ListNode_t ptr newNode_
    
    newNode_ = allocate(sizeof(ListNode_t))
    newNode_->data_ = allocate(dataSizeBytes)
    memcpy(newNode_->data_, data_, dataSizeBytes)
    newNode_->prev_ = 0
    
    if head_ = 0 then
        newNode_->next_ = 0
    else
        newNode_->next_ = head_
        head_->prev_ = newNode_
    end if
    
    head_ = newNode_
    
    if tail_ = 0 then
        tail_ = newNode_
    end if
    
    size += 1
    
end sub

sub List.pop_back()
    dim as ListNode_t ptr delNode_
    delNode_ = tail_
    
    if size = 0 then
        exit sub
    elseif size = 1 then
        head_ = 0
        tail_ = 0
    elseif size > 1 then
        tail_->prev_->next_ = 0
        tail_ = tail_->prev_
    end if
    
    size -= 1
        
    deallocate(delNode_)
        
end sub

sub List.pop_front()
    dim as ListNode_t ptr delNode_
    delNode_ = tail_
    
    if size = 0 then
        exit sub
    elseif size = 1 then
        head_ = 0
        tail_ = 0
    elseif size > 1 then
        head_->next_->prev_ = 0
        head_ = head_->next_
    end if
        
    size -= 1
        
    deallocate(delNode_)
        
end sub

function List.getBack() as any ptr
    if size = 0 then 
        return 0
    else
        return tail_->data_
    end if
end function
function List.getFront() as any ptr
    if size = 0 then 
        return 0
    else
        return head_->data_
    end if
end function
function List.getSize() as integer
    return size
end function

sub List.removeIf(test as function(data_ as any ptr) as integer)
    dim as ListNode_t ptr curNode_
    dim as ListNode_t ptr nxtNode_
    
    nxtNode_ = 0
    curNode_ = head_
    while curNode_ > 0
        nxtNode_ = curNode_->next_
    
        if test(curNode_->data_) = 1 then
            
            if curNode_->prev_ = 0 then
                head_ = curNode_->next_
            else
                curNode_->prev_->next_ = curNode_->next_
            end if
            
            if curNode_->next_ = 0 then
                tail_ = curNode_->prev_
            else
                curNode_->next_->prev_ = curNode_->prev_
            end if
            
            deallocate (curNode_->data_)
            deallocate (curNode_)
            
            size -= 1
        end if

        curNode_ = nxtNode_
    wend

end sub

sub List.flush() 
    dim as ListNode_t ptr curNode_
    dim as ListNode_t ptr nxtNode_
    
    nxtNode_ = 0
    curNode_ = head_
    while curNode_ > 0
        nxtNode_ = curNode_->next_
        
        deallocate(curNode_->data_)
        deallocate(curNode_)
        
        curNode_ = nxtNode_
    wend
    head_ = 0
    tail_ = 0
    curRollNode_ = 0
    size = 0
end sub

function List.roll() as any ptr
    dim as ListNode_t ptr tempNode_
    if curRollNode_ = 0 then
        return 0
    else
        tempNode_ = curRollNode_
        curRollNode_ = curRollNode_->next_
        return tempNode_->data_
    end if
end function
sub List.rollRemove()
    dim as ListNode_t ptr tempNode_
    if curRollNode_ <> 0 then
        tempNode_ = curRollNode_->next_
        
        deallocate(curRollNode_->data_)
        deallocate(curRollNode_)
        
        curRollNode_ = tempNode_
    end if
end sub
sub List.rollReset()
    curRollNode_ = head_
end sub

