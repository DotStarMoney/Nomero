#ifndef GAMESPACE_BI
#define GAMESPACE_BI

#include "debug.bi"
#include "constants.bi"
#include "tinyspace.bi"
#include "effectcontroller.bi"
#include "level.bi"
#include "fmod.bi"
#include "utility.bi"
#include "vector2d.bi"
#include "player.bi"
#include "snowgenerator.bi"
#include "projectilecollection.bi"
#include "oneshoteffects.bi"
#include "leveltypes.bi"
#include "dynamiccontroller.bi"

#define FPS_TARGET 60


type GameSpace
    public:
        declare constructor
        declare destructor
        
        declare function go() as integer
        declare sub reconnectCollision()
        declare sub switchRegions(ls as LevelSwitch_t)
        declare sub centerCamera(c as Vector2D)
        
        '---------- screen functions -------------
        
        declare sub vibrateScreen()
        declare sub pow(x as double, y as double, r as double)
            
    private:
		declare sub performSwitch(ls as LevelSwitch_t)
        declare sub step_input()
        declare sub step_draw()
        declare sub step_process()
        
        as integer gamePhase
        as integer ptr pieces
        as integer pieces_N
        
        as integer ptr hud_image
        
        as integer vibCount
        as Vector2D lastSpawn
        as string lastMap
        
        as OneShotEffects effects
        as ProjectileCollection projectiles
        as SnowGenerator backgroundSnow
        as SnowGenerator foregroundSnow
        as EffectController graphicFX
        as DynamicController dynControl
        as uinteger ptr music
        as TinySpace world
        as Player    spy
        as Level     lvlData
        as Vector2D  camera
        as integer   	 isSwitching
        as integer   	 switchFrame
        as LevelSwitch_t pendingSwitch
        
        as integer   keypress(0 to 255)
        as uinteger ptr scnbuff
		as double movingFrmAvg
end type
        
        
        
        
        
#endif
