#ifndef GAMESPACE_BI
#define GAMESPACE_BI

#include "debug.bi"
#include "constants.bi"
#include "tinyspace.bi"
#include "level.bi"
#include "fmod.bi"
#include "utility.bi"
#include "vector2d.bi"
#include "player.bi"
#include "snowgenerator.bi"
#include "projectilecollection.bi"
#include "oneshoteffects.bi"

#ifdef DEBUG
    kill "debug.txt"
#endif

#define FPS_TARGET 30

type GameSpace
    public:
        declare constructor
        declare destructor
        
        declare function go() as integer
        declare sub reconnectCollision()
        
        '---------- screen functions -------------
        
        declare sub vibrateScreen()
        declare sub pow(x as double, y as double, r as double)
            
    private:
        declare sub step_input()
        declare sub step_draw()
        declare sub step_process()
        
        as integer vibCount
        
        as OneShotEffects effects
        as ProjectileCollection projectiles
        as SnowGenerator backgroundSnow
        as SnowGenerator foregroundSnow
        as uinteger ptr music
        as TinySpace world
        as Player    spy
        as Level     lvlData
        as Vector2D  camera
        as integer   keypress(0 to 255)
        as uinteger ptr scnbuff
        dim as double movingFrmAvg
end type
        
        
        
        
        
#endif