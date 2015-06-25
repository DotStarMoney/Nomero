#ifndef ITEMTYPES_BI
#define ITEMTYPES_BI

#include "itemtypes.bi"
#include "gen_itemdefines.bi"

type NamesTypes_t
	declare constructor(name_p as string, type_p as DynamicObjectType_e, itemNumber_p as Item_Type_e)
	as string              name_
	as DynamicObjectType_e type_
    as Item_Type_e         itemNumber_
end type



#endif