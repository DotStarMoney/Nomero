#include "objectvalueset.bi"

#define COARSE_SIZE_INC 5

constructor ObjectValueSet()
    members_N = 0
    members_cap = 10
    members = allocate(members_cap * sizeof(ObjectValueSet_member_t))
end constructor
destructor ObjectValueSet()
    deallocate(members)
end destructor
sub ObjectValueSet._addValue_(item_ptr_p as Item ptr, value_ as _Item_valueContainer_t)
    if members_N >= members_cap then 
        members_cap += COARSE_SIZE_INC
        members = reallocate(members, members_cap * sizeof(ObjectValueSet_member_t))
    end if
    members[members_N].item_ptr = item_ptr_p
    if value_.type_ = _ITEM_VALUE_ZSTRING then
        members[members_N].value_.data_.zstring_ = allocate(len(*(value_.data_.zstring_)) + 1)
        *(members[members_N].value_.data_.zstring_) = *(value_.data_.zstring_)
        members[members_N].value_.type_ = _ITEM_VALUE_ZSTRING
    else
        members[members_N].value_ = value_
    end if
end sub
function ObjectValueSet.getValue_N() as integer
    return members_N
end function
sub ObjectValueSet.getValue(byref value_ as Vector2D, i as integer)
    if members[i].value_.type_ = _ITEM_VALUE_VECTOR2D then 
        value_ = members[i].value_.data_.Vector2D_
        exit sub
    end if
    value_ = Vector2D(0, 0)
end sub
sub ObjectValueSet.getValue(byref value_ as integer, i as integer)
    if members[i].value_.type_ = _ITEM_VALUE_INTEGER then 
        value_ = members[i].value_.data_.integer_
        exit sub
    end if
    value_ = 0
end sub
sub ObjectValueSet.getValue(byref value_ as double, i as integer)
    if members[i].value_.type_ = _ITEM_VALUE_DOUBLE then 
        value_ = members[i].value_.data_.double_
        exit sub
    end if
    value_ = 0.0
end sub
sub ObjectValueSet.getValue(byref value_ as string, i as integer)
    if members[i].value_.type_ = _ITEM_VALUE_ZSTRING then 
        value_ = *(members[i].value_.data_.zstring_)
        exit sub
    end if
    value_ = ""
end sub
