#ifndef LIST_BI
#define LIST_BI

#include "debug.bi"

#macro BEGIN_LIST(x, y)
	y.rollReset()
	do
		x = y.roll()
		if x then
#endmacro

#macro ABORT_LIST()
	exit do
#endmacro

#macro END_LIST()
		else
			exit do
		end if
	loop
#endmacro


type ListNode_t
    as any ptr data_
    as ListNode_t ptr next_
    as ListNode_t ptr prev_
end type

type ListNodeRoll_t
	as ListNode_t ptr curRollNode_
    as ListNode_t ptr oldCurRollNode_
    as ListNode_t ptr lastReturned_
end type

type List
    public:
        declare constructor()
        declare destructor()
        declare sub init(dataSizeBytes as integer)
        
        declare function push_back(data_ as any ptr) as any ptr
        declare function push_front(data_ as any ptr) as any ptr
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
        declare function bufferRoll() as ListNodeRoll_t
        declare sub setRoll(ln as ListNodeRoll_t)
    private:
        as ListNode_t ptr head_
        as ListNode_t ptr tail_
        as integer dataSizeBytes
        as integer size
        as ListNode_t ptr curRollNode_
        as ListNode_t ptr oldCurRollNode_
        as ListNode_t ptr lastReturned_
end type


#endif 
