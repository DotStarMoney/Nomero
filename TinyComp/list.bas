#include "list.bi"
#include "crt.bi"

'#ifdef DEBUG
    #include "utility.bi"
'#endif

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
		oldCurRollNode_ = curRollNode_
        tempNode_ = curRollNode_
        curRollNode_ = curRollNode_->next_
        return tempNode_->data_
    end if
end function
sub List.rollRemove()
    dim as ListNode_t ptr tempNode_
    dim as ListNode_t ptr delNode_
    if oldCurRollNode_ <> 0 then
        delNode_ = oldCurRollNode_
        tempNode_ = delNode_->next_
        
        if size = 1 then
			deallocate(head_->data_)
			deallocate(head_)
			head_ = 0
			tail_ = 0
			size = 0
			oldCurRollNode_ = 0
			curRollNode_ = 0
			exit sub
        end if
        
        if delNode_ = head_ then 
			head_ = head_->next_
			head_->prev_ = 0 
		end if
		if delNode_ = tail_ then 
			tail_ = tail_->prev_
			tail_->next_ = 0
		end if
		
		if delNode_->prev_ then delNode_->prev_ = delNode_->next_
		if delNode_->next_ then delNode_->next_ = delNode_->prev_
		
        deallocate(delNode_->data_)
        deallocate(delNode_)
        
        size -= 1
        
        curRollNode_ = tempNode_
    end if
end sub
sub List.rollReset()
    curRollNode_ = head_
    oldCurRollNode_ = 0
end sub
function List.bufferRoll() as ListNodeRoll_t
	Dim as ListNodeRoll_t ln
	ln.curRollNode_ = curRollNode_
	ln.oldCurRollNode_ = oldCurRollNode_
	ln.lastReturned_ = lastReturned_
	return ln
end function
sub List.setRoll(ln as ListNodeRoll_t)
	curRollNode_ = ln.curRollNode_
	oldCurRollNode_ = ln.oldCurRollNode_
	lastReturned_ = ln.lastReturned_
end sub
