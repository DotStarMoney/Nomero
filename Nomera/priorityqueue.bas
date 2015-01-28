#include "priorityqueue.bi"
#include "crt.bi"

#define COURSE_SCALE_INCREASE 1.5
#define INITIAL_ARRAY_SIZE 16

#define LEFT_CHILD(X) (2 * (X) + 1)
#define RIGHT_CHILD(X) (2 * (X) + 2)
#define PARENT(X) ((X) / 2)

constructor PriorityQueue()
    data_ = 0
    curRollItem = 0
    datasize = 0
    size = 0
    capacity = 0
end constructor


destructor PriorityQueue()
    flush()
end destructor


sub PriorityQueue.init(datasize_p as integer)
    dim as integer i
    flush()
    datasize = datasize_p
    capacity = INITIAL_ARRAY_SIZE
    data_ = allocate(sizeof(PriorityQueueElement_t) * capacity)
    for i = 0 to capacity - 1
        data_[i].data_ = 0
        data_[i].priority = 0
    next i
end sub


sub PriorityQueue.flush()
    dim as integer i
    if data_ <> 0 then
        for i = 0 to capacity - 1
            if data_[i].data_ <> 0 then deallocate(data_[i].data_)
        next i
    end if
    deallocate(data_)
    data_ = 0
    size = 0
    capacity = 0
    datasize = 0
    curRollItem = 0
end sub


function PriorityQueue.insert(datum_ as any ptr, priority as double) as any ptr
    dim as integer i
    dim as integer oldCap
    dim as any ptr retData_
    
    if size >= capacity then
        oldCap = capacity
        capacity *= COURSE_SCALE_INCREASE
        data_ = reallocate(data_, sizeof(PriorityQueueElement_t) * capacity)
        for i = oldCap to capacity - 1
            data_[i].data_ = 0
            data_[i].priority = 0
        next i
    end if
   
    data_[size].data_ = allocate(datasize)
    memcpy(data_[size].data_, datum_, datasize)
    data_[size].priority = priority
    retData_ = data_[size].data_
    
    size += 1
    
    i = size - 1
    while (i > 0) andAlso (data_[i].priority > data_[PARENT(i)].priority)
        swap data_[i], data_[PARENT(i)]
        i = PARENT(i)
    wend
    
    return retData_
end function


function PriorityQueue.getTop() as any ptr
    if size > 0 then
        return data_[0].data_
    else
        return 0
    end if
end function


sub PriorityQueue.removeTop()
    if size > 0 then
        deallocate(data_[0].data_)
        data_[0] = data_[size - 1]
        size -= 1
        heapify(0)
    end if
end sub


function PriorityQueue.roll() as any ptr
    dim as any ptr itemData_
    if curRollItem < size then
        itemData_ = data_[curRollItem].data_
        curRollItem += 1
    else
        itemData_ = 0
    end if
    return itemData_
end function


sub PriorityQueue.rollRemove()
    if curRollItem < size then
        deallocate(data_[curRollItem].data_)
        data_[curRollItem] = data_[size - 1]
        size -= 1
        heapify(curRollItem)
    end if
end sub

sub PriorityQueue.rollModifyPriority(priority as double)
    dim as double oldPriority
    dim as integer i
    
    if curRollItem < size then
        oldPriority = data_[curRollItem].priority
        data_[curRollItem].priority = priority
        if oldPriority > priority then
            heapify(curRollItem)
        elseif oldPriority < priority then
            i = curRollItem
            while (i > 0) andAlso (data_[i].priority > data_[PARENT(i)].priority)
                swap data_[i], data_[PARENT(i)]
                i = PARENT(i)
            wend
        end if
    end if
end sub

sub PriorityQueue.rollReset()
    curRollItem = 0
end sub


sub PriorityQueue.heapify(index as integer)
    dim as integer l_index, r_index, largest
    if size > 0 then
        l_index = LEFT_CHILD(index)
        r_index = RIGHT_CHILD(index)
        if (l_index < size) andAlso (data_[l_index].priority > data_[index].priority) then
            largest = l_index
        else    
            largest = index
        end if
        
        if (r_index < size) andAlso (data_[r_index].priority > data_[largest].priority) then
            largest = r_index
        end if
        
        if largest <> index then
            swap data_[index], data_[largest]
            heapify(largest)
        end if
    end if
end sub


