#include "hash2d.bi"
#include "utility.bi"
#include "crt.bi"

#define MINESCULE 0.00001

constructor Hash2D
    dataSizeBytes = 0
    curRollX = 0
    curRollY = 0
    curRollNode = 0
    cellWidth = 0
    cellHeight = 0
    cellRows_N = 0
    cellCols_N = 0
    spacialHash = 0
    curRollFoundNodes.init(sizeof(Hash2dData_t ptr))
    pointerToHashData.init(sizeof(Hash2dData_t ptr))
end constructor

destructor Hash2D
    flush()
    deallocate(spacialHash)
end destructor

sub Hash2D.init(spaceWidth as double, spaceHeight as double, dataSizeBytes as integer)
    dim as integer i
    if spacialHash <> 0 then deallocate(spacialHash)
    this.spaceWidth  = spaceWidth
    this.spaceHeight = spaceHeight
    this.cellWidth  = CELL_WIDTH
    this.cellHeight = CELL_HEIGHT
    this.cellCols_N = int(spaceWidth  / this.cellWidth) + 1
    this.cellRows_N = int(spaceHeight / this.cellHeight) + 1
    this.dataSizeBytes = dataSizeBytes
    spacialHash = allocate(sizeof(Hash2dNode_t ptr) * this.cellRows_N * this.cellCols_N)
    flush(1)
end sub

function Hash2D.getBounds(byref a as Vector2D, byref b as Vector2D,_
                          byref tl_x as integer, byref tl_y as integer,_
                          byref br_x as integer, byref br_y as integer) as integer
    a = Vector2D(min(a.x(), b.x()), min(a.y(), b.y()))
    b = Vector2D(max(a.x(), b.x()), max(a.y(), b.y()))
    if a.x() > this.spaceWidth then 
        return 0
    elseif a.x() < 0 then
        a.setX(0)
    end if
    if a.y() > this.spaceHeight then 
        return 0
    elseif a.y() < 0 then
        a.setY(0)
    end if
    if b.x() < 0 then 
        return 0
    elseif b.x() >= this.spaceWidth then
        b.setX(this.spaceWidth - MINESCULE)
    end if
    if b.y() < 0 then 
        return 0
    elseif b.y() >= this.spaceHeight then
        b.setY(this.spaceHeight - MINESCULE)
    end if
    tl_x = int(a.x() / this.cellWidth)
    tl_y = int(a.y() / this.cellHeight)
    br_x = int(b.x() / this.cellWidth)
    br_y = int(b.y() / this.cellHeight) 
    return 1
end function

function Hash2D.insert(a as Vector2D, b as Vector2D, data_ as any ptr) as any ptr
    dim as Vector2D a1, b1
    dim as integer tl_x, tl_y
    dim as integer br_x, br_y
    dim as integer xscan, yscan
    dim as Hash2dNode_t ptr head_, new_
    dim as Hash2dData_t ptr newDataNode_
    dim as Vector2D newLoc
    
    a1 = a
    b1 = b
    if getBounds(a1, b1, tl_x, tl_y, br_x, br_y) = 1 then
        newDataNode_ = new Hash2dData_t

        newDataNode_->parentNodesList.init(sizeof(Vector2D))
        newDataNode_->data_ = allocate(dataSizeBytes)
        memcpy(newDataNode_->data_, data_, dataSizeBytes)
        
        pointerToHashData.insert(cast(integer, newDataNode_->data_), @newDataNode_)
        
        for yscan = tl_y to br_y
            for xscan = tl_x to br_x
                head_ = spacialHash[yscan * this.cellCols_N + xscan]
                new_ = allocate(sizeof(Hash2dNode_t))
                new_->a = a
                new_->b = b
                new_->data_ = newDataNode_
                new_->next_ = head_
                
                newLoc = Vector2D(xscan, yscan)
                newDataNode_->parentNodesList.push_back(@newLoc)
                
                spacialHash[yscan * this.cellCols_N + xscan] = new_
            next xscan
        next yscan
		return newDataNode_->data_
    end if
    
    return 0
end function

function Hash2D.search(a as Vector2D, b as Vector2D, byref ret_ as any ptr ptr) as integer
    dim as Vector2D a1, b1
    dim as integer tl_x, tl_y
    dim as integer br_x, br_y
    dim as integer xscan, yscan
    dim as integer noCollide
    dim as any ptr ptr retList
    dim as integer retList_cap, retList_size
    dim as Hash2dNode_t ptr curNode_
    dim as HashTable foundDataPointers
    
    foundDataPointers.init(sizeof(Hash2dData_t ptr))

    retList_cap = 0
    retList_size = 0
    retList = 0
    
    a1 = a
    b1 = b
    if getBounds(a1, b1, tl_x, tl_y, br_x, br_y) = 1 then
        
        for yscan = tl_y to br_y
            for xscan = tl_x to br_x
                curNode_ = spacialHash[yscan * this.cellCols_N + xscan]
                while curNode_ > 0
                    noCollide = 0
                    
                    if (curNode_->b.x() < a.x()) orElse _ 
                       (curNode_->b.y() < a.y()) orElse _
                       (curNode_->a.x() > b.x()) orElse _
                       (curNode_->a.y() > b.y()) then
                        noCollide = 1
                    end if
                    if noCollide = 0 then
                        
                        if foundDataPointers.exists(cast(integer, curNode_->data_)) = 0 then
                            if retList_cap = 0 orElse (retList_cap = retList_size) then
                                retList_cap += 8
                                retList = reallocate(retList, retList_cap * sizeof(any ptr))
                            end if
                            retList[retList_size] = curNode_->data_->data_
                            retList_size += 1
                            
                            foundDataPointers.insert(cast(integer, curNode_->data_), @(curNode_->data_))
                        end if
                    end if
                    
                    curNode_ = curNode_->next_
                    
                wend
                
            next xscan
        next yscan
        ret_ = retList
        return retList_size
    else
        ret_ = 0
        return 0
    end if
end function

sub Hash2D.remove(data_ptr as any ptr)
    dim as Hash2dNode_t ptr curNode_, prevNode_, delNode_
    dim as Hash2dData_t ptr curDataNode_
    dim as Vector2D ptr curPos

    curDataNode_ = *cast(Hash2dData_t ptr ptr, pointerToHashData.retrieve(cast(integer, data_ptr)))
    if curDataNode_ = 0 then exit sub
    
    curDataNode_->parentNodesList.rollReset()
    do
        curPos = curDataNode_->parentNodesList.roll()
        if curPos <> 0 then
            curNode_ = spacialHash[curPos->y() * this.cellCols_N + curPos->x()]
            prevNode_ = 0
            while curNode_ <> 0
                
                if curNode_->data_->data_ = data_ptr then
                    delNode_ = curNode_
                    if prevNode_ = 0 then
                        spacialHash[curPos->y() * this.cellCols_N + curPos->x()] = curNode_->next_
                    else
                        prevNode_->next_ = curNode_->next_
                    end if
                    
                    deallocate(delNode_)                    
                    exit while
                else
                    prevNode_ = curNode_
                    curNode_ = curNode_->next_
                end if
            wend
        else
            exit do
        end if
    loop
    
    deallocate(curDataNode_->data_)
    delete curDataNode_
    
    pointerToHashData.remove(cast(integer, data_ptr))
end sub

sub Hash2D.flush(clr as integer = 0)
    dim as integer i
    dim as Hash2dNode_t ptr curNode_, nextNode_
    dim as HashTable foundDataPointers
    
    foundDataPointers.init(sizeof(Hash2dData_t ptr))
    pointerToHashData.flush()
    
    for i = 0 to this.cellRows_N * this.cellCols_N - 1
        if clr = 0 then
            curNode_ = spacialHash[i]
            while curNode_ <> 0
                nextNode_ = curNode_->next_
                
                if foundDataPointers.exists(cast(integer, curNode_->data_)) = 0 then
                    foundDataPointers.insert(cast(integer, curNode_->data_), @(curNode_->data_))
                    deallocate(curNode_->data_->data_)
                    delete curNode_->data_
                end if
                
                deallocate(curNode_)
                
                curNode_ = nextNode_
            wend
        end if
        spacialHash[i] = 0
    next i 
end sub

sub Hash2D.rollReset()
    if spacialHash <> 0 then
        curRollX    = 0
        curRollY    = 0
        curRollNode = spacialHash[curRollY * this.cellCols_N + curRollX]
        curRollFoundNodes.flush()
        curRollEnd = 0
    end if
end sub

function Hash2D.roll() as any ptr
    dim as Hash2dNode_t ptr searchNode_
    dim as Hash2dData_t ptr foundData_
    
    if (curRollEnd = 0) andALso (spacialHash <> 0) then
        do
            if curRollNode = 0 then
                curRollX += 1
                if curRollX = this.cellCols_N then
                    curRollY += 1
                    curRollX = 0
                    if curRollY = this.cellRows_N then
                        curRollY = 0
                        curRollEnd = 1
                        return 0
                    end if
                end if
                curRollNode = spacialHash[curRollY * this.cellCols_N + curRollX]
            else
                if curRollFoundNodes.exists(cast(integer, curRollNode->data_)) = 1 then
                    curRollNode = curRollNode->next_
                else
                    foundData_ = curRollNode->data_
                    curRollFoundNodes.insert(cast(integer, foundData_), @foundData_)
                    curRollNode = curRollNode->next_
                    return foundData_->data_
                end if
            end if
        loop
    else
        return 0
    end if
end function



