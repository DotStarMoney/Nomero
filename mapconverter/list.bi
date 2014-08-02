#ifndef LIST_BI
#define LIST_BI

'#include "debug.bi"

type ListNode_t
    as any ptr data_
    as ListNode_t ptr next_
    as ListNode_t ptr prev_
end type

type List
    public:
        declare constructor()
        declare destructor()
        declare sub init(dataSizeBytes as integer)
        
        declare sub push_back(data_ as any ptr)
        declare sub push_front(data_ as any ptr)
        declare sub pop_back()
        declare sub pop_front()
        declare function getBack() as any ptr
        declare function getFront() as any ptr
        declare function getSize() as integer
        declare sub removeIf(test as function(data_ as any ptr) as integer)
        
        declare sub flush() 
        declare function roll() as any ptr
        declare sub rollRemove()
        declare sub rollReset()
    private:
        as ListNode_t ptr head_
        as ListNode_t ptr tail_
        as integer dataSizeBytes
        as integer size
        as ListNode_t ptr curRollNode_
end type


#endif 