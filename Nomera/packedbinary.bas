#include "packedbinary.bi"

#define DEFAULT_CAPACITY 256

constructor PackedBinary()
    data_ = allocate(DEFAULT_CAPACITY)
    capacity = DEFAULT_CAPACITY
    currentOffset = 0
end constructor
destructor PackedBinary()
    deallocate(data_)
end destructor
sub PackedBinary.flush()
    deallocate(data_)
    data_ = allocate(DEFAULT_CAPACITY)
    capacity = DEFAULT_CAPACITY
    currentOffset = 0
end sub

function PackedBinary.getData() as any ptr
    return data_
end function
function PackedBinary.getOffsetData() as any ptr
    return @(data_[currentOffset])
end function
function PackedBinary.getSize() as unsigned long
    return currentOffset
end function

sub PackedBinary.request(size as unsigned long)
    while currentOffset + size >= capacity 
        capacity *= 2
        data_ = reallocate(data_, capacity)
    wend
end sub

sub PackedBinary.store(value_ as integer)
    request(sizeof(integer))
    *cast(integer ptr, @(data_[currentOffset])) = value_
    currentOffset += sizeof(integer)
end sub
sub PackedBinary.store(value_ as double)
    request(sizeof(double))
    *cast(double ptr, @(data_[currentOffset])) = value_
    currentOffset += sizeof(double)
end sub
sub PackedBinary.store(value_ as string)
    dim as unsigned integer i
    request(len(value_) + 1)
    for i = 1 to len(value_) 
        *cast(ubyte ptr, @(data_[currentOffset])) = asc(mid(value_, i, 1))
        currentOffset += 1
    next i
    *cast(ubyte ptr, @(data_[currentOffset])) = 0
    currentOffset += 1
end sub
sub PackedBinary.store(value_ as Vector2D)
    store(cdbl(value_.xs))
    store(cdbl(value_.ys))
end sub
sub PackedBinary.store(value_ as long)
    request(sizeof(long))
    *cast(long ptr, @(data_[currentOffset])) = value_
    currentOffset += sizeof(long)
end sub

sub PackedBinary.retrieve(byref value_ as integer)
    value_ = *cast(integer ptr, @(data_[currentOffset]))
    currentOffset += sizeof(integer)
end sub
sub PackedBinary.retrieve(byref value_ as double)
    value_ = *cast(double ptr, @(data_[currentOffset]))
    currentOffset += sizeof(double)
end sub
sub PackedBinary.retrieve(byref value_ as string)
    dim as ubyte curChar
    value_ = ""
    do
        curChar = *cast(ubyte ptr, @(data_[currentOffset]))
        value_ += chr(curChar)
        currentOffset += 1
    loop while curChar 
    value_ = left(value_, len(value_) - 1)
end sub
sub PackedBinary.retrieve(byref value_ as Vector2D)      
    retrieve(value_.xs)
    retrieve(value_.ys)
end sub  
sub PackedBinary.retrieve(byref value_ as long)      
    value_ = *cast(long ptr, @(data_[currentOffset]))
    currentOffset += sizeof(long)
end sub 
sub PackedBinary.inc(amount as unsigned integer)
    currentOffset += amount
end sub
sub PackedBinary.join(pbin as PackedBinary)
    dim as unsigned long i
    request(pbin.getSize())
    for i = 0 to pbin.getSize() - 1
        data_[currentOffset] = cast(byte ptr, pbin.getData)[i]
        currentOffset += 1
    next i
    pbin.flush()
end sub
