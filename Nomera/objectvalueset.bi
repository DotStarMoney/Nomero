#ifndef OBJECTVALUESET_BI
#define OBJECTVALUESET_BI

#include "item.bi"
#include "vector2d.bi"

type ObjectValueSet_member_t
    as Item ptr item_ptr
    as _Item_valueContainer_t value_
end type


type ObjectValueSet
    public:
        declare constructor()
        declare destructor()
        declare sub _addValue_(item_ptr_p as Item ptr, value_ as _Item_valueContainer_t)
        declare function getValue_N() as integer
        declare sub getValue(byref value_ as Vector2D, i as integer)
        declare sub getValue(byref value_ as integer, i as integer)
        declare sub getValue(byref value_ as double, i as integer)
        declare sub getValue(byref value_ as string, i as integer)
    private:
        as ObjectValueSet_member_t ptr members
        as integer members_N
        as integer members_cap
end type



#endif