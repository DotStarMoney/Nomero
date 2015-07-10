#ifndef ITEMVALUECONTAINER_BI
#define ITEMVALUECONTAINER_BI

#include "pvector2d.bi"

enum _Item_valueTypes_e
    _ITEM_VALUE_VECTOR2D
    _ITEM_VALUE_INTEGER
    _ITEM_VALUE_DOUBLE
    _ITEM_VALUE_ZSTRING
end enum

union _Item_valueContainer_data_u
    as pVector2D Vector2D_
    as integer integer_
    as double double_
    as zstring ptr zstring_
end union

type _Item_valueContainer_t
    as _Item_valueTypes_e type_
    as _Item_valueContainer_data_u data_
end type

#endif