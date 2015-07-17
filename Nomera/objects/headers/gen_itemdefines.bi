#ifndef GEN_ITEMDEFINES_BI
#define GEN_ITEMDEFINES_BI
type ITEM_ANTIPERSONNELMINE_TYPE_DATA 
    as integer body_i
    as TinyBody body
    as integer death
    as integer freeFallingFrames
end type
enum Item_Type_e
    ITEM_NONE
    ITEM_ANTIPERSONNELMINE
end enum
enum Item_slotEnum_e
    ITEM_ANTIPERSONNELMINE_SLOT_EXPLODE_E
end enum
union Item_objectData_u
    as ITEM_ANTIPERSONNELMINE_TYPE_DATA ptr ANTIPERSONNELMINE_DATA
end union
#endif
