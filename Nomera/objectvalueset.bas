#include "objectvalueset.bi"

#define COARSE_SIZE_INC 5

constructor ObjectValueSet()
    members_N = 0
    members_cap = 10
    members = allocate(members_cap * sizeof(ObjectValueSet_member_t))
end constructor
destructor ObjectValueSet()
    clean()
end destructor
sub ObjectValueSet.clean()
    dim as integer i
    for i = 0 to members_N - 1
        if members[i].value_.type_ = _ITEM_VALUE_ZSTRING then
            deallocate(members[i].value_.data_.zstring_)
        end if
        deallocate(members[i].itemID)
    next i
    deallocate(members)
end sub
sub ObjectValueSet._addValue_(ID_ as string, value_ as _Item_valueContainer_t ptr, geom as Shape2D)
    if members_N >= members_cap then 
        members_cap += COARSE_SIZE_INC
        members = reallocate(members, members_cap * sizeof(ObjectValueSet_member_t))
    end if
    members[members_N].itemID = allocate(len(ID_) + 1)
    *(members[members_N].itemID) = ID_
    members[members_N].geometry = geom
    if value_->type_ = _ITEM_VALUE_ZSTRING then
        members[members_N].value_.data_.zstring_ = allocate(len(*(value_->data_.zstring_)) + 1)
        *(members[members_N].value_.data_.zstring_) = *(value_->data_.zstring_)
        members[members_N].value_.type_ = _ITEM_VALUE_ZSTRING
    else
        members[members_N].value_ = *(value_)
    end if
    members_N += 1
end sub
sub ObjectValueSet.getGeometry(byref geom_ as Shape2D, i as integer)
    geom_ = members[i].geometry
end sub
sub ObjectValueSet.getID(byref ID_ as string, i as integer)
    ID_ = *(members[i].itemID)
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
