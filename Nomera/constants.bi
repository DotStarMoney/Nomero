#ifndef CONSTANTS_BI
#define CONSTANTS_BI

#include "debug.bi"

'#define KICKSTARTER
'#define NO_PLAYER

'#define SCALE_2X
'#define SCALE_ELLIOTT
#define SCRX 640
#define SCRY 480

enum orderType
    FOREGROUND = 0
    ACTIVE_COVER = 1
    ACTIVE = 2
    BACKGROUND = 3
    ACTIVE_FRONT = 4
    OVERLAY = 5
end enum

enum shapeType
    ELLIPSE
    RECTANGLE
end enum


#ifdef KICKSTARTER
#include "vector2d.bi"
#define RED_SOLDIER 0
#define YELLOW_SOLDIER 1
#define KARTOFEL 2
type recordFrame_t field = 1
    as Vector2D p
    as integer direLEFTRIGHT
    as integer dire2AS
    as integer jumpZ
    as integer fireX
    as integer upsUPDOWN
    as integer sprintSHIFT
    as integer pressQ
    as integer pressW
    as integer onLadder
    as integer grounded
end type
#endif

#define ITEM_HEADER "objects\headers\"


#endif
