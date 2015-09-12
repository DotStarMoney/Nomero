#ifndef GEN_ITEMDEFINES_BI
#define GEN_ITEMDEFINES_BI
type ITEM_ACCENTLIGHT_TYPE_DATA 
    as integer mode
    as double minVal
    as double maxVal
end type
type ITEM_AK47SHOT_TYPE_DATA
    as Vector2D heading
    as integer hasTraj
    as integer lifeFrames
    as double cmul
    as Vector2D a
    as Vector2D b
    as integer cbase
end type
type ITEM_ALARMSPINNER_TYPE_DATA
    as integer fade
    as integer fadeDir
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
type ITEM_BALLSPAWNER_TYPE_DATA
    as integer revUpFrames
end type
type ITEM_BIGOSCILLOSCOPE_TYPE_DATA
    as integer dontDraw
    as integer enable
end type
type ITEM_CABINCONTROL_TYPE_DATA
    as integer state
    as integer glowChargeFrames
    as Vector2D muralLoc
    as Vector2D camTarget
    as integer drawMural
    as integer startedSequence
    as integer enablePanel
    as integer actionTimer
    as integer playChime
end type
type ITEM_CASH_TYPE_DATA
    as integer frameCount
    as integer denom
    as TinyBody body
    as integer body_i
    as integer state
    as integer displayFrames
    as integer displayY
end type
type ITEM_COVERSMOKE_TYPE_DATA 
    as integer body_i
    as TinyBody body
    as integer lifeFrames
    as integer animSpeed
    as double driftForce
    as double driftVelocity
end type
type ITEM_DESKLAMP_TYPE_DATA
    as integer isDisabled
    as integer state
    as integer flavor
    as integer fCount
end type
type ITEM_DOORKEY_TYPE_DATA 
    as integer state
    as integer doText
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
type ITEM_ENERGYBALL_TYPE_arcData_t
    as integer arcID
    as Vector2D bPos
    as Vector2D endPos
end type
type ITEM_ENERGYBALL_TYPE_DATA
    as integer body_i
    as integer lastCollide
    as TinyBody body
    as integer flashTimer
    as ITEM_ENERGYBALL_TYPE_arcData_t ptr arcs
    as integer arcs_n
    as integer soundTimer
end type
type ITEM_FLOORLAMP_TYPE_DATA
    as integer isDisabled
    as integer state
    as integer fCount
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
type ITEM_HANGINGBULB_TYPE_DATA
    as integer state
end type
type ITEM_HIDDENSWITCH_TYPE_DATA
    as integer state
    as integer disable
end type
type ITEM_INTELLIGENCE_TYPE_DATA
    as zimage ptr img
    as integer frameCount
end type
type ITEM_INTERFACE_TYPE_DATA
    as integer cycleState
    as integer cycleTime
    as integer dontDraw
end type
type ITEM_KEY_TYPE_DATA
    as integer frameCount
end type
type ITEM_LANTERN_TYPE_DATA
    as integer state
end type
type ITEM_LASEREMITTER_TYPE_DATA
    as integer ptr collisionTexture
    as double lengthHit
    as integer drawHit
    as Vector2D hitSpot
end type
type ITEM_LASERRECEIVER_TYPE_DATA
    as integer state
    as integer targetFrames
end type
type ITEM_MAGICCOUCH_TYPE_DATA 
    as TinyDynamic ptr platform
    as integer platform_i
    as integer lastState
    as vector2D elevatorPos
end type
type ITEM_MAGICMINECART_TYPE_DATA 
    as integer toggleCycle
    as Vector2D curPos
    as double curDire
end type
type ITEM_MINELANTERN_TYPE_mothData_t
    as Vector2D drawP
    as Vector2D p
    as Vector2D v
    as Vector2D f
    as Vector2D target
    as Animation ptr anim
end type
type ITEM_MINELANTERN_TYPE_DATA
    as integer frame
    as integer flickerCounter
    as integer moths_N
    as ITEM_MINELANTERN_TYPE_mothData_t ptr moths
end type
type ITEM_MOMENTARYTOGGLESWITCH_TYPE_DATA 
    as integer toggleCycle
end type
type ITEM_NIXIEFLICKER_TYPE_DATA
    as integer ptr tubeValues
    as integer ptr valueFixed
    as integer countup
    as integer interimCount
    as integer countA
    as integer activated
    as zimage nomeraSplash
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
type ITEM_RAZ200_TYPE_backStar
    as integer flavor
    as integer x, y
    as integer speedX, speedY
end type
type ITEM_RAZ200_TYPE_DATA
    as Vector2D devicePos
    as C64.fontSpace Arena
    as C64.Image     titleImage, bigBunImage
    as zimage ptr glare
    as integer frameCount
    as ITEM_RAZ200_TYPE_backStar ptr stars
end type
type ITEM_REDWALLLIGHT_TYPE_DATA
    as integer curFrame
    as integer speedCount
    as integer frameDir
end type
type ITEM_REVEALINGWALL_TYPE_DATA 
    as integer state
end type
type ITEM_SHOCKTARGET1_TYPE_DATA
    as integer cycleTime 
end type
type ITEM_SIGN_TYPE_DATA
    as integer doText
end type
type ITEM_SMALLOSCILLOSCOPE_TYPE_DATA
    as integer dontDraw
    as integer enable
end type
type ITEM_SMOKEMINE_TYPE_DATA 
    as integer body_i
    as TinyBody body
    as integer death
    as integer freeFallingFrames
    as integer dyingFrames
end type
type ITEM_SOLDIER_TYPE_DATA
    as Enemy enemyWrapper
    as integer death
    as integer zapTime
    as integer bulletCooldown
    as integer frameCount
    as integer kaboom
    as double deathRise
end type
type ITEM_SPOTLIGHTCONTROL_TYPE_DATA
    as integer transitFrames
    as integer dire
    as integer tracking
    as Vector2D stopPos
    as integer sweepDire
    as integer visibleFrames
    as integer caughtFrames
    as double suspicionLevel
    as integer stopBuffer
    as double noticeBuffer
    as Vector2D v
end type
type ITEM_STANDUPSWITCH_TYPE_DATA
    as integer state
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
type ITEM_TOGGLELIGHT_TYPE_DATA
    as integer state
end type
type ITEM_TRIGGERZONE_TYPE_DATA
    as integer lastState
end type
type ITEM_TUBEPUZZLEMAP_TYPE_DATA
    as integer cycle
    as integer state 
end type
type ITEM_WALLSWITCH_TYPE_DATA
    as integer state
end type
enum Item_Type_e
    ITEM_NONE
    ITEM_ACCENTLIGHT
    ITEM_AK47SHOT
    ITEM_ALARMSPINNER
    ITEM_ALIENSPINNER
    ITEM_ANTIPERSONNELMINE
    ITEM_BALLSPAWNER
    ITEM_BIGOSCILLOSCOPE
    ITEM_CABINCONTROL
    ITEM_CASH
    ITEM_CEILINGFAN
    ITEM_COVERSMOKE
    ITEM_CRYSTALGLOW
    ITEM_DEEPSPOTLIGHT
    ITEM_DESKLAMP
    ITEM_DOORKEY
    ITEM_ELECTRICMINE
    ITEM_ENERGYBALL
    ITEM_FISHBOWL
    ITEM_FLOORLAMP
    ITEM_FREIGHTELEVATOR
    ITEM_FREQUENCYCOUNTER
    ITEM_HANGINGBULB
    ITEM_HIDDENSWITCH
    ITEM_INTELLIGENCE
    ITEM_INTERFACE
    ITEM_KEY
    ITEM_LANTERN
    ITEM_LASEREMITTER
    ITEM_LASERRECEIVER
    ITEM_MAGICCOUCH
    ITEM_MAGICMINECART
    ITEM_MINELANTERN
    ITEM_MOMENTARYTOGGLESWITCH
    ITEM_NIXIEFLICKER
    ITEM_PUZZLETUBE1
    ITEM_PUZZLE1234
    ITEM_RAZ200
    ITEM_REDPOSTLIGHT
    ITEM_REDWALLLIGHT
    ITEM_REVEALINGWALL
    ITEM_SHOCKTARGET1
    ITEM_SIGN
    ITEM_SMALLOSCILLOSCOPE
    ITEM_SMOKEMINE
    ITEM_SOLDIER
    ITEM_SPOTLIGHTCONTROL
    ITEM_STANDUPSWITCH
    ITEM_TANDY2000
    ITEM_TELEPORTERREVEALSEQUENCE
    ITEM_TELEPORTERSWITCH
    ITEM_TOGGLELIGHT
    ITEM_TRIGGERZONE
    ITEM_TUBEPUZZLEMAP
    ITEM_VENTWIRES
    ITEM_WALLSWITCH
end enum
enum Item_slotEnum_e
    ITEM_ALIENSPINNER_SLOT_INTERACT_E
    ITEM_ANTIPERSONNELMINE_SLOT_EXPLODE_E
    ITEM_BALLSPAWNER_SLOT_SPAWN_E
    ITEM_BIGOSCILLOSCOPE_SLOT_ENABLE_E
    ITEM_BIGOSCILLOSCOPE_SLOT_INTERACT_E
    ITEM_CABINCONTROL_SLOT_STARTSEQUENCE_E
    ITEM_CABINCONTROL_SLOT_TOGGLELIGHTS_E
    ITEM_DEEPSPOTLIGHT_SLOT_ENABLE_E
    ITEM_DESKLAMP_SLOT_INTERACT_E
    ITEM_DESKLAMP_SLOT_ENABLE_E
    ITEM_DOORKEY_SLOT_INTERACT_E
    ITEM_ELECTRICMINE_SLOT_EXPLODE_E
    ITEM_ENERGYBALL_SLOT_REACT_E
    ITEM_FLOORLAMP_SLOT_INTERACT_E
    ITEM_FLOORLAMP_SLOT_TOGGLE_E
    ITEM_FLOORLAMP_SLOT_ENABLE_E
    ITEM_FREIGHTELEVATOR_SLOT_INTERACT_E
    ITEM_FREQUENCYCOUNTER_SLOT_INTERACT_E
    ITEM_HANGINGBULB_SLOT_TOGGLE_E
    ITEM_HIDDENSWITCH_SLOT_INTERACT_E
    ITEM_HIDDENSWITCH_SLOT_ENABLE_E
    ITEM_INTERFACE_SLOT_INTERACT_E
    ITEM_LANTERN_SLOT_TOGGLE_E
    ITEM_LASERRECEIVER_SLOT_RECIEVE_E
    ITEM_MAGICCOUCH_SLOT_MOVE_E
    ITEM_MAGICMINECART_SLOT_DRAWASOCCLUDER_E
    ITEM_MAGICMINECART_SLOT_ENABLE_E
    ITEM_MOMENTARYTOGGLESWITCH_SLOT_INTERACT_E
    ITEM_NIXIEFLICKER_SLOT_BEGINSEQ_E
    ITEM_PUZZLETUBE1_SLOT_ACTIVATE_E
    ITEM_PUZZLETUBE1_SLOT_RESET_E
    ITEM_PUZZLETUBE1_SLOT_LOCKUP_E
    ITEM_PUZZLETUBE1_SLOT_SETUP_E
    ITEM_PUZZLE1234_SLOT_RESET_E
    ITEM_PUZZLE1234_SLOT_CYCLE_E
    ITEM_REVEALINGWALL_SLOT_REACT_E
    ITEM_SHOCKTARGET1_SLOT_SHOCKTARGET_E
    ITEM_SIGN_SLOT_INTERACT_E
    ITEM_SMALLOSCILLOSCOPE_SLOT_ENABLE_E
    ITEM_SMALLOSCILLOSCOPE_SLOT_INTERACT_E
    ITEM_SMOKEMINE_SLOT_EXPLODE_E
    ITEM_SOLDIER_SLOT_DRAWASOCCLUDER_E
    ITEM_SOLDIER_SLOT_CLOSESOLDIERALERT_E
    ITEM_SOLDIER_SLOT_REACT_E
    ITEM_SOLDIER_SLOT_SHOCKTARGET_E
    ITEM_STANDUPSWITCH_SLOT_INTERACT_E
    ITEM_TANDY2000_SLOT_INTERACT_E
    ITEM_TELEPORTERREVEALSEQUENCE_SLOT_START_E
    ITEM_TELEPORTERSWITCH_SLOT_INTERACT_E
    ITEM_TELEPORTERSWITCH_SLOT_ENABLE_E
    ITEM_TOGGLELIGHT_SLOT_TOGGLE_E
    ITEM_TUBEPUZZLEMAP_SLOT_UPDATE_E
    ITEM_WALLSWITCH_SLOT_INTERACT_E
end enum
union Item_objectData_u
    as ITEM_ACCENTLIGHT_TYPE_DATA ptr ACCENTLIGHT_DATA
    as ITEM_AK47SHOT_TYPE_DATA ptr AK47SHOT_DATA
    as ITEM_ALARMSPINNER_TYPE_DATA ptr ALARMSPINNER_DATA
    as ITEM_ALIENSPINNER_TYPE_DATA ptr ALIENSPINNER_DATA
    as ITEM_ANTIPERSONNELMINE_TYPE_DATA ptr ANTIPERSONNELMINE_DATA
    as ITEM_BALLSPAWNER_TYPE_DATA ptr BALLSPAWNER_DATA
    as ITEM_BIGOSCILLOSCOPE_TYPE_DATA ptr BIGOSCILLOSCOPE_DATA
    as ITEM_CABINCONTROL_TYPE_DATA ptr CABINCONTROL_DATA
    as ITEM_CASH_TYPE_DATA ptr CASH_DATA
    as ITEM_COVERSMOKE_TYPE_DATA ptr COVERSMOKE_DATA
    as ITEM_DESKLAMP_TYPE_DATA ptr DESKLAMP_DATA
    as ITEM_DOORKEY_TYPE_DATA ptr DOORKEY_DATA
    as ITEM_ELECTRICMINE_TYPE_DATA ptr ELECTRICMINE_DATA
    as ITEM_ENERGYBALL_TYPE_DATA ptr ENERGYBALL_DATA
    as ITEM_FLOORLAMP_TYPE_DATA ptr FLOORLAMP_DATA
    as ITEM_FREIGHTELEVATOR_TYPE_DATA ptr FREIGHTELEVATOR_DATA
    as ITEM_FREQUENCYCOUNTER_TYPE_DATA ptr FREQUENCYCOUNTER_DATA
    as ITEM_HANGINGBULB_TYPE_DATA ptr HANGINGBULB_DATA
    as ITEM_HIDDENSWITCH_TYPE_DATA ptr HIDDENSWITCH_DATA
    as ITEM_INTELLIGENCE_TYPE_DATA ptr INTELLIGENCE_DATA
    as ITEM_INTERFACE_TYPE_DATA ptr INTERFACE_DATA
    as ITEM_KEY_TYPE_DATA ptr KEY_DATA
    as ITEM_LANTERN_TYPE_DATA ptr LANTERN_DATA
    as ITEM_LASEREMITTER_TYPE_DATA ptr LASEREMITTER_DATA
    as ITEM_LASERRECEIVER_TYPE_DATA ptr LASERRECEIVER_DATA
    as ITEM_MAGICCOUCH_TYPE_DATA ptr MAGICCOUCH_DATA
    as ITEM_MAGICMINECART_TYPE_DATA ptr MAGICMINECART_DATA
    as ITEM_MINELANTERN_TYPE_DATA ptr MINELANTERN_DATA
    as ITEM_MOMENTARYTOGGLESWITCH_TYPE_DATA ptr MOMENTARYTOGGLESWITCH_DATA
    as ITEM_NIXIEFLICKER_TYPE_DATA ptr NIXIEFLICKER_DATA
    as ITEM_PUZZLETUBE1_TYPE_DATA ptr PUZZLETUBE1_DATA
    as ITEM_PUZZLE1234_TYPE_DATA ptr PUZZLE1234_DATA
    as ITEM_RAZ200_TYPE_DATA ptr RAZ200_DATA
    as ITEM_REDWALLLIGHT_TYPE_DATA ptr REDWALLLIGHT_DATA
    as ITEM_REVEALINGWALL_TYPE_DATA ptr REVEALINGWALL_DATA
    as ITEM_SHOCKTARGET1_TYPE_DATA ptr SHOCKTARGET1_DATA
    as ITEM_SIGN_TYPE_DATA ptr SIGN_DATA
    as ITEM_SMALLOSCILLOSCOPE_TYPE_DATA ptr SMALLOSCILLOSCOPE_DATA
    as ITEM_SMOKEMINE_TYPE_DATA ptr SMOKEMINE_DATA
    as ITEM_SOLDIER_TYPE_DATA ptr SOLDIER_DATA
    as ITEM_SPOTLIGHTCONTROL_TYPE_DATA ptr SPOTLIGHTCONTROL_DATA
    as ITEM_STANDUPSWITCH_TYPE_DATA ptr STANDUPSWITCH_DATA
    as ITEM_TELEPORTERREVEALSEQUENCE_TYPE_DATA ptr TELEPORTERREVEALSEQUENCE_DATA
    as ITEM_TELEPORTERSWITCH_TYPE_DATA ptr TELEPORTERSWITCH_DATA
    as ITEM_TOGGLELIGHT_TYPE_DATA ptr TOGGLELIGHT_DATA
    as ITEM_TRIGGERZONE_TYPE_DATA ptr TRIGGERZONE_DATA
    as ITEM_TUBEPUZZLEMAP_TYPE_DATA ptr TUBEPUZZLEMAP_DATA
    as ITEM_WALLSWITCH_TYPE_DATA ptr WALLSWITCH_DATA
end union
#endif
