#include "objectslotset.bi"
#include "dynamiccontroller.bi"

#define COARSE_SIZE_INC 5

constructor ObjectSlotSet()
    members_N = 0
    members_cap = 10
    members = allocate(members_cap * sizeof(ObjectSlotSet_member_t))
end constructor
sub ObjectSlotSet.clean()
    dim as integer i
    for i = 0 to members_N - 1
        deallocate(members[i].itemID)
        deallocate(members[i].slot_tag)
    next i
    deallocate(members)
end sub
destructor ObjectSlotSet()
    clean()
end destructor
sub ObjectSlotSet._setlink_(link_ as objectlink)
    link = link_
end sub
sub ObjectSlotSet._addSlot_(itemID as string, slot_tag as string, geom as Shape2D ptr)
    if members_N >= members_cap then 
        members_cap += COARSE_SIZE_INC
        members = reallocate(members, members_cap * sizeof(ObjectSlotSet_member_t))
    end if
    members[members_N].itemID = allocate(len(itemID) + 1)
    *(members[members_N].itemID) = itemID
    members[members_N].slot_tag = allocate(len(slot_tag) + 1)
    *(members[members_N].slot_tag) = slot_tag    
    members[members_N].geometry = geom
    members_N += 1
end sub
sub ObjectSlotSet.throw(parameter_string as string = "")
    dim as integer i
    for i = 0 to members_N - 1
        link.dynamiccontroller_ptr->fireSlot(*(members[i].itemID), *(members[i].slot_tag), parameter_string)
    next i
end sub
function ObjectSlotSet.getMember_N() as integer
    return members_N
end function
function ObjectSlotSet.getMember(i as integer) as ObjectSlotSet
    dim as ObjectSlotSet ret
    ret._addSlot_(*(members[i].itemID), *(members[i].slot_tag), members[i].geometry)
    return ret
end function

sub ObjectSlotSet.getGeometry(byref geom as Shape2D ptr, i as integer) 
    geom = members[i].geometry
end sub
sub ObjectSlotSet.getID(byref ID_ as string, i as integer)
    ID_ = *(members[i].itemID)
end sub
