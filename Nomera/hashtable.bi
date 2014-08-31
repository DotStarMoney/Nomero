#ifndef HASHTABLE_BI
#define HASHTABLE_BI


#define MIN_CELLS 4
#define MAX_CAPACITY 0.8
#define EXPAND_FACTOR 2

#include "debug.bi"

enum HashNodeKeyType_e
    KEY_STRING
    KEY_INTEGER
end enum


type HashNode_t
    as any ptr data_
    as HashNode_t ptr next_
    as HashNodeKeyType_e key_type
    key_string  as zstring ptr
    key_integer as integer
end type

type HashTable
    public:
        declare constructor()
        declare constructor(datasize as uinteger)
        declare destructor()
        declare sub init(datasize as uinteger)
        declare sub insert(r_key as integer, data_ as any ptr)
        declare sub insert(r_key as string , data_ as any ptr)
        declare sub remove(r_key as integer)
        declare sub remove(r_key as string)
        declare function retrieve(r_key as integer) as any ptr
        declare function retrieve(r_key as string ) as any ptr
        declare function exists(r_key as integer) as integer
        declare function exists(r_key as string ) as integer 
        declare function getSize() as integer
        declare function getDataSizeBytes() as integer
        declare sub resetRoll()
        declare function roll() as any ptr
        declare sub flush()
    private:
        declare function hashString(r_key as string)   as uinteger
        declare function hashInteger(r_key as integer) as uinteger
        declare sub rehash()
        as integer  ready_flag
        as uinteger dataSizeBytes
        as uinteger numObjects
        as uinteger numCells
        as HashNode_t ptr ptr data_
        as HashNode_t ptr curRollNode
        as integer        curRollIndx
end type



#endif