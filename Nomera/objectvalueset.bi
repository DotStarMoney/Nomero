#ifndef OBJECTVALUESET_BI
#define OBJECTVALUESET_BI

#include "shape2d.bi"
#include "vector2d.bi"
#include "itemvaluecontainer.bi"

type ObjectValueSet_member_t
    as zstring ptr itemID
    as Shape2D geometry
    as _Item_valueContainer_t value_
end type

type ObjectValueSet
    public:
        declare constructor()
        declare destructor()
        declare sub _addValue_(ID_ as string, value_ as _Item_valueContainer_t ptr, geom as Shape2D)
        declare function getValue_N() as integer
        declare sub getValue(byref value_ as Vector2D, i as integer)
        declare sub getValue(byref value_ as integer, i as integer)
        declare sub getValue(byref value_ as double, i as integer)
        declare sub getValue(byref value_ as string, i as integer)
        declare sub getGeometry(byref geom_ as Shape2D, i as integer)
        declare sub getID(byref ID_ as string, i as integer)
        declare sub clean()
    private:
        as ObjectValueSet_member_t ptr members
        as integer members_N
        as integer members_cap
end type



#endif