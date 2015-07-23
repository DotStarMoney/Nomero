#ifndef GEN_ITEMDEFINES_BI
#define GEN_ITEMDEFINES_BI
type ITEM_ACCENTLIGHT_TYPE_DATA 
    as integer mode
    as double minVal
    as double maxVal
end type
type ITEM_ALIENSPINNER_TYPE_DATA
    as integer transitType
    as integer delay
    as integer lightUFO
    as integer scrollLights
    as integer scrollLightsDelay
    as integer curFrame
end type
type ITEM_ANTIPERSONNELMINE_TYPE_DATA 
    as integer body_i
    as TinyBody body
    as integer death
    as integer freeFallingFrames
end type
type ITEM_BIGOSCILLOSCOPE_TYPE_DATA
    as integer dontDraw
end type
type ITEM_COVERSMOKE_TYPE_DATA 
    as integer body_i
    as TinyBody body
    as integer lifeFrames
    as integer animSpeed
    as double driftForce
    as double driftVelocity
end type
type ITEM_ELECTRICMINE_TYPE_ElectricMine_ArcData_t
    as integer arcID
    as Vector2D bPos
    as Vector2D endPos
end type
type ITEM_ELECTRICMINE_TYPE_DATA 
    as integer body_i
    as TinyBody body
    as integer death
    as integer freeFallingFrames
    as ITEM_ELECTRICMINE_TYPE_ElectricMine_ArcData_t ptr arcs
    as integer arcs_n
    as integer deathFrames
end type
type ITEM_FREIGHTELEVATOR_TYPE_DATA 
    as TinyDynamic ptr platformHi
    as TinyDynamic ptr platformLow
    as integer platformHi_i
    as integer platformLow_i
    as integer lastState
    as vector2D elevatorPos
    as integer gearSound
end type
type ITEM_FREQUENCYCOUNTER_TYPE_DATA
    as integer cycleState
    as integer cycleTime
end type
type ITEM_INTERFACE_TYPE_DATA
    as integer cycleState
    as integer cycleTime
    as integer dontDraw
end type
type ITEM_SMALLOSCILLOSCOPE_TYPE_DATA
    as integer dontDraw
end type
type ITEM_SMOKEMINE_TYPE_DATA 
    as integer body_i
    as TinyBody body
    as integer death
    as integer freeFallingFrames
    as integer dyingFrames
end type
enum Item_Type_e
    ITEM_NONE
    ITEM_ACCENTLIGHT
    ITEM_ALIENSPINNER
    ITEM_ANTIPERSONNELMINE
    ITEM_BIGOSCILLOSCOPE
    ITEM_COVERSMOKE
    ITEM_ELECTRICMINE
    ITEM_FREIGHTELEVATOR
    ITEM_FREQUENCYCOUNTER
    ITEM_INTERFACE
    ITEM_SMALLOSCILLOSCOPE
    ITEM_SMOKEMINE
    ITEM_TANDY2000
end enum
enum Item_slotEnum_e
    ITEM_ALIENSPINNER_SLOT_INTERACT_E
    ITEM_ANTIPERSONNELMINE_SLOT_EXPLODE_E
    ITEM_BIGOSCILLOSCOPE_SLOT_INTERACT_E
    ITEM_ELECTRICMINE_SLOT_EXPLODE_E
    ITEM_FREIGHTELEVATOR_SLOT_INTERACT_E
    ITEM_FREQUENCYCOUNTER_SLOT_INTERACT_E
    ITEM_INTERFACE_SLOT_INTERACT_E
    ITEM_SMALLOSCILLOSCOPE_SLOT_INTERACT_E
    ITEM_SMOKEMINE_SLOT_EXPLODE_E
    ITEM_TANDY2000_SLOT_INTERACT_E
end enum
union Item_objectData_u
    as ITEM_ACCENTLIGHT_TYPE_DATA ptr ACCENTLIGHT_DATA
    as ITEM_ALIENSPINNER_TYPE_DATA ptr ALIENSPINNER_DATA
    as ITEM_ANTIPERSONNELMINE_TYPE_DATA ptr ANTIPERSONNELMINE_DATA
    as ITEM_BIGOSCILLOSCOPE_TYPE_DATA ptr BIGOSCILLOSCOPE_DATA
    as ITEM_COVERSMOKE_TYPE_DATA ptr COVERSMOKE_DATA
    as ITEM_ELECTRICMINE_TYPE_DATA ptr ELECTRICMINE_DATA
    as ITEM_FREIGHTELEVATOR_TYPE_DATA ptr FREIGHTELEVATOR_DATA
    as ITEM_FREQUENCYCOUNTER_TYPE_DATA ptr FREQUENCYCOUNTER_DATA
    as ITEM_INTERFACE_TYPE_DATA ptr INTERFACE_DATA
    as ITEM_SMALLOSCILLOSCOPE_TYPE_DATA ptr SMALLOSCILLOSCOPE_DATA
    as ITEM_SMOKEMINE_TYPE_DATA ptr SMOKEMINE_DATA
end union
#endif
