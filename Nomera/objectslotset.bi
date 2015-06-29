#ifndef OBJECTSLOTSET_BI
#define OBJECTSLOTSET_BI

#include "item.bi"

type ObjectSlotSet_member_t
    as Item ptr item_ptr
    as string slot_tag
end type


type ObjectSlotSet
    public:
        declare constructor()
        declare destructor()
        declare sub _addSlot_(item_ptr_p as Item ptr, slot_tag_p as string)
        declare sub throw(parameter_string as string = "")
        declare function getMember_N() as integer
        declare function getMember(i as integer) as ObjectSlotSet
    private:
        as ObjectSlotSet_member_t ptr members
        as integer members_N
        as integer members_cap
end type



#endif