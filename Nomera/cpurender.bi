#ifndef CPURENDER_BI
#define CPURENDER_BI

#include "vector2d.bi"


type CPURender
    public:
        const as integer SCALE_MODE_2X = 1
        const as integer SCALE_MODE_1X = 0
        const as integer BACKGROUND_LAYER   = 0
        const as integer ACTIVE_LAYER       = 1
        const as integer ACTIVE_COVER_LAYER = 2
        const as integer FOREGROUND_LAYER   = 3
        
        declare constructor()
        declare destructor()
        
        declare sub openScreen(scalemode as integer)
        declare sub setCamera(cam as vector2d)
        
        declare sub render()
        'put
        'trans put
        
    
    
    private:
        as integer test

end type


#endif