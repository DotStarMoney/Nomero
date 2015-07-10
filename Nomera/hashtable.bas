#include "hashtable.bi"
#include "crt.bi"

#ifdef DEBUG
    #include "utility.bi"
#endif


#define MIN_CELLS 4
#define MAX_CAPACITY 0.8
#define EXPAND_FACTOR 2


constructor HashTable(datasize as uinteger)
    ready_flag = 0
    data_ = 0
    init(datasize)
end constructor

constructor HashTable()
    ready_flag = 0
    data_ = 0
end constructor

destructor HashTable()
    clean()
end destructor

sub HashTable.init(datasize as uinteger)
    dim as integer i
    if data_ <> 0 then flush()
    curRollNode = 0
    ready_flag = 1
    dataSizeBytes = datasize
    numObjects = 0
    numCells = MIN_CELLS
    data_ = allocate(sizeof(HashNode_t ptr) * numCells)
    for i = 0 to numCells - 1
        data_[i] = 0
    next i
end sub

sub HashTable.resetRoll()
    curRollNode = 0
    curRollIndx = 0
end sub

function HashTable.roll() as any ptr
    dim as any ptr cn
    dim as integer i
    if curRollNode <> 0 then 
        cn = curRollNode->data_
        curRollNode = curRollNode->next_
        return cn
    else
        for i = curRollIndx to numCells - 1
            if data_[i] <> 0 then
                curRollNode = data_[i]
                curRollIndx = i
                cn = curRollNode->data_
                curRollNode = curRollNode->next_
                curRollIndx += 1
                return cn
            end if
        next i
        return 0
    end if
end function

function HashTable.getSize() as integer
    return numObjects
end function

function HashTable.hashString(r_key as string) as uinteger
    dim as integer  i
    dim as uinteger hash = 31
    for i = 1 to len(r_key)
        hash = (hash * 54059) xor (asc(mid(r_key, i, 1)) * 76963)
    next i
    hash = hash mod numCells
    return hash
end function

function HashTable.hashInteger(r_key as integer) as uinteger
    dim as uinteger key
    key = r_key
    key = key xor ((key shr 20) xor (key shr 12))
    key = key xor ((key shr 7) xor (key shr 4))
    key = key mod numCells
    return key
end function

function HashTable.insert(r_key as integer, data_ as any ptr) as any ptr
    dim as uinteger key
    dim as HashNode_t ptr newNode
    
    key = hashInteger(r_key)
    
    newNode = allocate(sizeof(HashNode_t))
    newNode->key_type    = KEY_INTEGER
    newNode->key_integer = r_key
    newNode->data_       = allocate(dataSizeBytes)
    memcpy(newNode->data_, data_, dataSizeBytes)
    
    if this.data_[key] = 0 then
        newNode->next_ = 0
    else
        newNode->next_ = this.data_[key]
    end if
    
    this.data_[key] = newNode
    numObjects += 1

    rehash()
    return newNode->data_
end function

function HashTable.insert(r_key as string , data_ as any ptr) as any ptr
    dim as uinteger key
    dim as HashNode_t ptr newNode
    
    key = hashString(r_key)

    newNode = allocate(sizeof(HashNode_t))
    newNode->key_type   = KEY_STRING
    newNode->key_string = allocate(len(r_key) + 1)
    *(newNode->key_string) = r_key
    newNode->data_       = allocate(dataSizeBytes)
    memcpy(newNode->data_, data_, dataSizeBytes)
    
    if this.data_[key] = 0 then
        newNode->next_ = 0
    else
        newNode->next_ = this.data_[key]
    end if
    
    this.data_[key] = newNode
    numObjects += 1
    
    rehash()
    return newNode->data_
end function

sub HashTable.remove(r_key as integer)
    dim as uinteger key
    dim as HashNode_t ptr curNode
    dim as HashNode_t ptr lastNode
    
    key = hashInteger(r_key) 
    
    curNode = data_[key]
    lastNode = 0
    while curNode <> 0
        if curNode->key_type = KEY_INTEGER then
            if curNode->key_integer = r_key then
                
                if lastNode = 0 then
                    data_[key] = curNode->next_
                else
                    lastNode->next_ = curNode->next_
                end if
            
                deallocate(curNode->data_)
                deallocate(curNode)
                
                numObjects -= 1
                exit sub
            end if
        end if
        lastNode = curNode
        curNode = curNode->next_
    wend
end sub

sub HashTable.remove(r_key as string)
    dim as uinteger key
    dim as HashNode_t ptr curNode
    dim as HashNode_t ptr lastNode
    
    key = hashString(r_key) 
    
    curNode = data_[key]
    lastNode = 0
    while curNode <> 0
        if curNode->key_type = KEY_STRING then
            if *(curNode->key_string) = r_key then
                
                if lastNode = 0 then
                    data_[key] = curNode->next_
                else
                    lastNode->next_ = curNode->next_
                end if
            
                deallocate(curNode->key_string)
                deallocate(curNode->data_)
                deallocate(curNode)
                
                numObjects -= 1
                exit sub
            end if
        end if
        lastNode = curNode
        curNode = curNode->next_
    wend
end sub

function HashTable.retrieve(r_key as integer) as any ptr
    dim as uinteger key
    dim as HashNode_t ptr curNode
    
    key = hashInteger(r_key) 

    curNode = data_[key]
    while curNode <> 0
        if curNode->key_type = KEY_INTEGER then
            if curNode->key_integer = r_key then
                return curNode->data_
            end if
        end if
        curNode = curNode->next_
    wend    
    
    return 0
end function

function HashTable.retrieve(r_key as string) as any ptr
    dim as uinteger key
    dim as HashNode_t ptr curNode
    
    key = hashString(r_key) 

    curNode = data_[key]
    while curNode <> 0
        if curNode->key_type = KEY_STRING then
            if *(curNode->key_string) = r_key then
                return curNode->data_
            end if
        end if
        curNode = curNode->next_
    wend    
    
    return 0
end function

function HashTable.exists(r_key as integer) as integer
    dim as uinteger key
    dim as HashNode_t ptr curNode

    key = hashInteger(r_key) 
    
    
    curNode = data_[key]    
    
    while curNode <> 0
        if curNode->key_type = KEY_INTEGER then
            if curNode->key_integer = r_key then
                return 1
            end if
        end if
        curNode = curNode->next_
    wend    
    
    return 0
end function
function HashTable.exists(r_key as string ) as integer    
    dim as uinteger key
    dim as HashNode_t ptr curNode
    
    key = hashString(r_key) 
    
    curNode = data_[key]
    while curNode <> 0
        if curNode->key_type = KEY_STRING then
            if *(curNode->key_string) = r_key then
                return 1
            end if
        end if
        curNode = curNode->next_
    wend    
    
    return 0
end function

function HashTable.getDataSizeBytes() as integer
    return dataSizeBytes
end function

sub HashTable.rehash()
    dim as double ratio
    dim as HashNode_t ptr ptr newData
    dim as HashNode_t ptr curNode
    dim as HashNode_t ptr nextNode
    dim as integer oldNumCells
    dim as integer i
    dim as uinteger key
 
    oldNumCells = numCells
    ratio = cdbl(numObjects) / numCells
    if ratio > MAX_CAPACITY then
        numCells = numCells * EXPAND_FACTOR
        newData = allocate(sizeof(HashNode_t ptr) * numCells)
        for i = 0 to numCells - 1
            newData[i] = 0
        next i
        for i = 0 to oldNumCells - 1
            curNode = data_[i]
            while curNode <> 0 
                if curNode->key_type = KEY_INTEGER then
                    key = hashInteger(curNode->key_integer)
                elseif curNode->key_type = KEY_STRING then
                    key = hashString(*(curNode->key_string))
                end if
                nextNode = curNode->next_
                
                curNode->next_ = newData[key]
                newData[key] = curNode
                
                curNode = nextNode
            wend
        next i
        deallocate(data_)
        data_ = newData
    end if

end sub
   
sub HashTable.flush()
    dim as HashNode_t ptr curNode
    dim as HashNode_t ptr nextNode
    dim as integer i
    for i = 0 to numCells - 1
        curNode = data_[i]
        while curNode <> 0 
            nextNode = curNode->next_
            
            if curNode->key_type = KEY_STRING then
                deallocate(curNode->key_string)
            end if
            deallocate(curNode->data_)
            deallocate(curNode)
            
            curNode = nextNode
        wend 
    next i
    numObjects = 0
    deallocate(data_)
    data_ = 0
    init(dataSizeBytes)
end sub

sub HashTable.clean()
    dim as HashNode_t ptr curNode
    dim as HashNode_t ptr nextNode
    dim as integer i
    for i = 0 to numCells - 1
        curNode = data_[i]
        while curNode <> 0 
            nextNode = curNode->next_
            
            if curNode->key_type = KEY_STRING then
                deallocate(curNode->key_string)
            end if
            deallocate(curNode->data_)
            deallocate(curNode)
            
            curNode = nextNode
        wend 
    next i
    numObjects = 0
    deallocate(data_)
    data_ = 0
end sub
