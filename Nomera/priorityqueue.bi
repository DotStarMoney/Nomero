#ifndef PRIORITYQUEUE_BI
#define PRIORITYQUEUE_BI

#macro BEGIN_PRIORITYQUEUE(x, y)
	y.rollReset()
	do
		x = y.roll()
		if x then
#endmacro

#macro ABORT_PRIORITYQUEUE()
	exit do
#endmacro

#macro END_PRIORITYQUEUE()
		else
			exit do
		end if
	loop
#endmacro

type PriorityQueueElement_t
	as any ptr data_
	as double priority
end type

type PriorityQueue
	public:
		declare constructor() 
		declare destructor()
		declare sub init(datasize_p as integer)
		declare sub flush()
		
		declare function insert(datum_ as any ptr, priority as double) as any ptr
		declare function getTop() as any ptr
		declare sub removeTop()
		
		declare function roll() as any ptr
        declare sub rollReset()

        declare sub rollRemove()
        declare sub rollModifyPriority(priority as double)
	
    private:
		declare sub heapify(index as integer)
		
		as integer curRollItem
		as integer datasize
		as integer size
		as integer capacity
		as PriorityQueueElement_t ptr data_
end type


#endif
