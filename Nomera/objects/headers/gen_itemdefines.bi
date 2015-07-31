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
type ITEM_MOMENTARYTOGGLESWITCH_TYPE_DATA 
    as integer toggleCycle
end type
type ITEM_PUZZLETUBE1_TYPE_bubble_t
    as Vector2D p
    as Vector2D v
    as double   size
    as integer  exists
end type
type ITEM_PUZZLETUBE1_TYPE_DATA
    as double tubeLevel 
    as integer isLocked
    as integer targetLevel
    as integer drawLevel
    as ITEM_PUZZLETUBE1_TYPE_bubble_t ptr bubbles
end type
type ITEM_PUZZLE1234_TYPE_DATA
    as integer ptr values
    as integer ptr startValues
    as integer curValue
    as integer startValue
    as zstring ptr ptr tubeIDs
    as integer hasInit 
    as integer complete
    as integer completeDance
    as integer completeDanceFrames
end type
type ITEM_SHOCKTARGET1_TYPE_DATA
    as integer cycleTime 
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
type ITEM_TELEPORTERREVEALSEQUENCE_TYPE_DATA
    as integer enable
    as integer countFrame
    as integer ptr revealLayers
    as integer ptr hideLayers
    as integer ptr glowTargets
    as integer ptr glowCurrent
end type
type ITEM_TELEPORTERSWITCH_TYPE_DATA
    as integer cycleTime
    as integer state
    as integer flashCycle
end type
type ITEM_TUBEPUZZLEMAP_TYPE_DATA
    as integer cycle
    as integer state 
end type
enum Item_Type_e
    ITEM_NONE
    ITEM_ACCENTLIGHT
    ITEM_ALIENSPINNER
    ITEM_ANTIPERSONNELMINE
    ITEM_BIGOSCILLOSCOPE
    ITEM_COVERSMOKE
    ITEM_DEEPSPOTLIGHT
    ITEM_ELECTRICMINE
    ITEM_FREIGHTELEVATOR
    ITEM_FREQUENCYCOUNTER
    ITEM_INTERFACE
    ITEM_MOMENTARYTOGGLESWITCH
    ITEM_PUZZLETUBE1
    ITEM_PUZZLE1234
    ITEM_SHOCKTARGET1
    ITEM_SMALLOSCILLOSCOPE
    ITEM_SMOKEMINE
    ITEM_TANDY2000
    ITEM_TELEPORTERREVEALSEQUENCE
    ITEM_TELEPORTERSWITCH
    ITEM_TUBEPUZZLEMAP
end enum
enum Item_slotEnum_e
    ITEM_ALIENSPINNER_SLOT_INTERACT_E
    ITEM_ANTIPERSONNELMINE_SLOT_EXPLODE_E
    ITEM_BIGOSCILLOSCOPE_SLOT_INTERACT_E
    ITEM_DEEPSPOTLIGHT_SLOT_ENABLE_E
    ITEM_ELECTRICMINE_SLOT_EXPLODE_E
    ITEM_FREIGHTELEVATOR_SLOT_INTERACT_E
    ITEM_FREQUENCYCOUNTER_SLOT_INTERACT_E
    ITEM_INTERFACE_SLOT_INTERACT_E
    ITEM_MOMENTARYTOGGLESWITCH_SLOT_INTERACT_E
    ITEM_PUZZLETUBE1_SLOT_ACTIVATE_E
    ITEM_PUZZLETUBE1_SLOT_RESET_E
    ITEM_PUZZLETUBE1_SLOT_LOCKUP_E
    ITEM_PUZZLETUBE1_SLOT_SETUP_E
    ITEM_PUZZLE1234_SLOT_RESET_E
    ITEM_PUZZLE1234_SLOT_CYCLE_E
    ITEM_SHOCKTARGET1_SLOT_SHOCKTARGET_E
    ITEM_SMALLOSCILLOSCOPE_SLOT_INTERACT_E
    ITEM_SMOKEMINE_SLOT_EXPLODE_E
    ITEM_TANDY2000_SLOT_INTERACT_E
    ITEM_TELEPORTERREVEALSEQUENCE_SLOT_START_E
    ITEM_TELEPORTERSWITCH_SLOT_INTERACT_E
    ITEM_TELEPORTERSWITCH_SLOT_ENABLE_E
    ITEM_TUBEPUZZLEMAP_SLOT_UPDATE_E
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
    as ITEM_MOMENTARYTOGGLESWITCH_TYPE_DATA ptr MOMENTARYTOGGLESWITCH_DATA
    as ITEM_PUZZLETUBE1_TYPE_DATA ptr PUZZLETUBE1_DATA
    as ITEM_PUZZLE1234_TYPE_DATA ptr PUZZLE1234_DATA
    as ITEM_SHOCKTARGET1_TYPE_DATA ptr SHOCKTARGET1_DATA
    as ITEM_SMALLOSCILLOSCOPE_TYPE_DATA ptr SMALLOSCILLOSCOPE_DATA
    as ITEM_SMOKEMINE_TYPE_DATA ptr SMOKEMINE_DATA
    as ITEM_TELEPORTERREVEALSEQUENCE_TYPE_DATA ptr TELEPORTERREVEALSEQUENCE_DATA
    as ITEM_TELEPORTERSWITCH_TYPE_DATA ptr TELEPORTERSWITCH_DATA
    as ITEM_TUBEPUZZLEMAP_TYPE_DATA ptr TUBEPUZZLEMAP_DATA
end union
#endif
