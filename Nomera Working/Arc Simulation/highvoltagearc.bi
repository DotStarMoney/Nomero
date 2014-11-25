#ifndef HIGHVOLTAGEARC_BI
#define HIGHVOLTAGEARC_BI

#include "vector3d.bi"
#include "spline2.bi"

type HighVoltageArc_Anchor
    as integer index
    as double  theta
    as double  r
    as double  r_inc
    as integer lifeFrames
end type

type HighVoltageArc_Params
    as double r_inc
    as double r
    as integer life_lo
    as integer life_hi
end type

type HighVoltageArc_Octave
    as Spline2 curve
    as integer               anchor_N
    as HighVoltageArc_Anchor ptr anchor
end type

type HighVoltageArc
    public:
        declare constructor()
        declare destructor()
        declare sub setEndpoints(a as Vector3D, b as Vector3D)
        declare sub step_(t as double)
        declare sub draw_(scnbuff as integer ptr)
        declare sub init()
    private:
        as HighVoltageArc_Params     octaveLevel(1 to 5)
        as integer                   octave_N
        as HighVoltageArc_Octave ptr octave
        as Vector3D pt_a, pt_b
end type


#endif