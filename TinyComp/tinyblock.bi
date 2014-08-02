#ifndef TINYBLOCK_BI
#define TINYBLOCK_BI

Enum TinyBlock_Model
    EMPTY = 0
End Enum

type TinyBlock
    public:
        declare constructor
        declare constructor(cModel_ as integer)
        as integer cModel
        as double  surface_speed
        as double  elasticity
        as double  friction
        as double  size
end type






#endif