#ifndef PACKEDBINARY_BI
#define PACKEDBINARY_BI

#include "vector2d.bi"

type PackedBinary
    public:
        declare constructor()
        declare destructor()
        declare sub flush()
     
        declare function getOffsetData() as any ptr
        declare function getData() as any ptr
        declare function getSize() as unsigned long
            
        declare sub store(value_ as integer)
        declare sub store(value_ as double)
        declare sub store(value_ as string)
        declare sub store(value_ as Vector2D)
        declare sub store(value_ as long)

        
        declare sub retrieve(byref value_ as integer)
        declare sub retrieve(byref value_ as double)
        declare sub retrieve(byref value_ as string)
        declare sub retrieve(byref value_ as Vector2D)    
        declare sub retrieve(byref value_ as long)    


        declare sub join(pbin as PackedBinary)
        
        declare sub request(size as unsigned long)
        declare sub inc(amount as unsigned integer)
    private:
        
        as byte ptr data_
        as unsigned long capacity
        as unsigned long currentOffset
        
end type


#endif
