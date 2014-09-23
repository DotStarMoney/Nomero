#ifndef ARBITER_BI
#define ARBITER_BI

type ArbiterData_t
    as Vector2D a
    as Vector2D b
    as Vector2D impulse
    as double   depth
    as Vector2D velocity
    as integer  ignore
    as integer  new_
    as integer  dynamic_
    as integer	tag
    as integer  dynamic_tag
    as Vector2D dynamic_norm
    as Vector2D guide_axis
    as Vector2D guide_dot
    as Vector2D dynaV
end type

#endif
