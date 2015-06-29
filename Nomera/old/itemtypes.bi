#ifndef ITEMTYPES_BI
#define ITEMTYPES_BI


#define BOMB_STICKYNESS 0
#define MINE_FREEFALL_MAX 30

type ElectricMine_ArcData_t
    as integer arcID
    as Vector2D bPos
    as Vector2D endPos
end type
#define MAX_RAYCAST_ATTEMPTS 10
#define RAYCAST_DIST 80
#define ELECMINE_TIME 50

#define SMOKEMINE_TIME 150

#define COVERSMOKE_LIFETIME 300 
#define COVERSMOKE_FRAMES 12
#define COVERSMOKE_DAMPING_MAX 0.95



#endif