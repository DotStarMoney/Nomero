#ifndef DOUBLEHASH_BI
#define DOUBLEHASH_BI


#include "debug.bi"

#macro BEGIN_DHASH(x, y)
	y.resetRoll()
	do
		x = y.roll()
		if x then
#endmacro

#macro END_DHASH()
		else
			exit do
		end if
	loop
#endmacro


enum DoubleHashNodeKeyType_e
    KEY_STRING
    KEY_INTEGER
end enum

union DoubleHashNode_data_u
    key_string  as zstring ptr
    key_integer as integer
end union

type DoubleHashFrame_t
    as any ptr data_
    as DoubleHashNodeKeyType_e key_type1
    as DoubleHashNode_data_u   data1
    as DoubleHashNodeKeyType_e key_type2
    as DoubleHashNode_data_u   data2
end type

type DoubleHashNode_t
    as DoubleHashNode_t ptr next_
    as DoubleHashNode_t ptr last_
    as DoubleHashNode_t ptr sibling_
    as DoubleHashFrame_t ptr data_
    as uinteger index
end type

type DoubleHash
    public:
        declare constructor()
        declare constructor(datasize as uinteger)
        declare destructor()
  
        declare sub construct_()
        declare sub init(datasize as uinteger)
        
        declare function insert(key1 as integer, key2 as integer, data_ as any ptr) as any ptr
        declare function insert(key1 as string , key2 as integer, data_ as any ptr) as any ptr
        declare function insert(key1 as integer, key2 as string , data_ as any ptr) as any ptr
        declare function insert(key1 as string , key2 as string , data_ as any ptr) as any ptr
        
        declare sub removeKey1(key1 as integer)
        declare sub removeKey1(key1 as string)
        declare sub removeKey2(key2 as integer)
        declare sub removeKey2(key2 as string)        
        declare sub remove(key1 as integer, key2 as integer)
        declare sub remove(key1 as string , key2 as integer)
        declare sub remove(key1 as integer, key2 as string )
        declare sub remove(key1 as string , key2 as string )   
        
        declare function retrieveKey1(key1 as integer, byref ret_ as any ptr ptr) as integer
        declare function retrieveKey1(key1 as string , byref ret_ as any ptr ptr) as integer
        declare function retrieveKey2(key2 as integer, byref ret_ as any ptr ptr) as integer
        declare function retrieveKey2(key2 as string , byref ret_ as any ptr ptr) as integer     
        declare function retrieve(key1 as integer, key2 as integer) as any ptr
        declare function retrieve(key1 as string , key2 as integer) as any ptr
        declare function retrieve(key1 as integer, key2 as string ) as any ptr
        declare function retrieve(key1 as string , key2 as string ) as any ptr
        
        declare function existsKey1(key1 as integer) as integer
        declare function existsKey1(key1 as string ) as integer
        declare function existsKey2(key2 as integer) as integer
        declare function existsKey2(key2 as string ) as integer     
        declare function exists(key1 as integer, key2 as integer) as integer
        declare function exists(key1 as string , key2 as integer) as integer
        declare function exists(key1 as integer, key2 as string ) as integer
        declare function exists(key1 as string , key2 as string ) as integer
        
        declare function getSize() as integer
        declare function getDataSizeBytes() as integer
        declare sub resetRoll()
        declare function roll() as any ptr
        declare sub flush()
        declare sub clean()
    private:
        declare function hashString1(key as string)   as uinteger
        declare function hashInteger1(s_key as integer) as uinteger
        declare function hashString2(key as string)   as uinteger
        declare function hashInteger2(s_key as integer) as uinteger        
        
        declare sub rehash1()
        declare sub rehash2()
        
        as uinteger dataSizeBytes
        
        as uinteger numObjects
        
        as uinteger numCells1
        as uinteger numCells2
        
        as DoubleHashNode_t ptr ptr data1_
        as DoubleHashNode_t ptr ptr data2_

        as DoubleHashNode_t ptr curRollNode
        as integer              curRollIndx
        as integer              curRollTble
end type



#endif