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
#include "fbgdtriggerdispatch.bi"
#include "soundeffects.bi"
#include "pathtracker.bi"
#include "electricarc.bi"

#define FPS_TARGET 60



type GameSpace
    public:
        declare constructor
        declare destructor
        
        declare function go() as integer
        declare sub reconnectCollision()
        declare sub switchRegions(ls as LevelSwitch_t)
        declare sub centerCamera(c as Vector2D)
        declare function getLastFileName() as string
        declare function getCurrentFileName() as string
        declare function getLastPosition() as Vector2D
        declare sub hardSwitchMusic(filename as string)
        declare sub setMusicVolume(v as integer)
        declare sub fadeMusicIn()
        declare sub fadeMusicOut()
        declare sub resetMusicFade()
        
        '---------- screen functions -------------
        declare sub setShakeStyle(style as integer)
        declare sub vibrateScreen(vibAmount as integer = 8)
        as Vector2D lastSpawn
        as string lastMap
        as integer lockAction
        as integer lockCamera
        as integer winStatus
        as integer shouldBail
        as integer bailFrame
        as Vector2D  camera
    private:
		declare sub performSwitch(ls as LevelSwitch_t)
        declare sub step_input()
        declare sub step_draw()
        declare sub step_process()
        declare sub doGameEnd()
        
        
        as integer ptr hud_image
        as integer musicVol
        as integer musicVolDir
        as integer slowdownShake
        as integer vibCount
        as string curMusic
        as integer switchTracks
        as integer lastTurnstyleInput
        as integer ptr fadeoutTex
        as integer fadeOutMusic
        
        as PathTracker tracker
        as SoundEffects soundfx
        as FBGDTriggerDispatch triggers
        as OneShotEffects effects
        as ProjectileCollection projectiles
        as SnowGenerator backgroundSnow
        as SnowGenerator foregroundSnow
        as EffectController graphicFX
        as DynamicController dynControl
        as ElectricArc arcEffects
        as uinteger ptr music(0 to 1)
        as integer currentMusic
        as integer shake
        as TinySpace world
        as Player    spy
        as Level     lvlData
        as integer   	 isSwitching
        as integer   	 switchFrame
        as LevelSwitch_t pendingSwitch
                
        as byte ptr      pathData
        as integer       pathBytes
        as string        pathFile
        as integer       pathFileNum
        
        as integer   keypress(0 to 255)
        as integer   last_keypress(0 to 255)
        as uinteger ptr scnbuff
		as double movingFrmAvg
		as integer stallTime_mili
		as double frameTime
        
       
end type
        
        
        
        
        
#endif
