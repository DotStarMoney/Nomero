#include "objectslotset.bi"

#define COARSE_SIZE_INC 5

constructor ObjectSlotSet()
    members_N = 0
    members_cap = 10
    members = allocate(members_cap * sizeof(ObjectSlotSet_member_t))
end constructor
destructor ObjectSlotSet()
    deallocate(members)
end destructor
sub ObjectSlotSet._addSlot_(item_ptr_p as Item ptr, slot_tag_p as string)
    if members_N >= members_cap then 
        members_cap += COARSE_SIZE_INC
        members = reallocate(members, members_cap * sizeof(ObjectSlotSet_member_t))
    end if
    members[members_N].item_ptr = item_ptr_p
    members[members_N].slot_tag = slot_tag_p
end sub
sub ObjectSlotSet.throw(parameter_string as string = "")
    dim as integer i
    for i = 0 to members_N - 1
        members[i].item_ptr->fireSlot(members[i].slot_tag, parameter_string)
    next i
end sub
function ObjectSlotSet.getMember_N() as integer
    return members_N
end function
function ObjectSlotSet.getMember(i as integer) as ObjectSlotSet
    dim as ObjectSlotSet ret
    ret._addSlot(members[i].item_ptr, members[i].slot_tag)
    return ret
end function

