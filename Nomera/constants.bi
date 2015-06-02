#ifndef CONSTANTS_BI
#define CONSTANTS_BI

#include "debug.bi"

'#define SCALE_2X
#define SCRX 640
#define SCRY 480

enum orderType
    FOREGROUND = 0
    ACTIVE_COVER = 1
    ACTIVE = 2
    BACKGROUND = 3
    ACTIVE_FRONT = 4
end enum

enum shapeType
    ELLIPSE
    RECTANGLE
end enum


#endif
