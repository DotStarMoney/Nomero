#ifndef ANIMATION_BI
#define ANIMATION_BI

#include "vector2d.bi"
#include "hashtable.bi"

enum ANIM_TYPE
    ANIM_ONE_SHOT
    ANIM_LOOP
    ANIM_STILL
end enum
enum ANIM_RELEASE_TYPE
    ANIM_TO_COMPLETION
    ANIM_INSTANT
    ANIM_FINISH_FRAME
    ANIM_AFTER_RELEASE_POINT
    ANIM_REVERSE
    ANIM_JUMP_TO_RELEASE_THEN_REVERSE
end enum

type FrameData_t
    as Vector2D offset
    as integer  delay
end type

type Animation_t
    as ANIM_TYPE         anim_type
    as ANIM_RELEASE_TYPE anim_release_type
    as integer           usePerFrameDelay
    
    as integer     ptr release_frames
    as integer         release_frames_n
    as FrameData_t ptr frame_data
    as integer         frame_hasData
    as integer         frame_n
    as integer         frame_width
    as integer         frame_height
    as integer         frame_delay
    as integer         frame_startCell
    as integer         frame_endCell
    as integer         frame_loopPoint
    as Vector2D        frame_offset
end type

type AnimationData_t
    as zstring ptr animName
    as Animation_t ptr animations
    as integer animations_n
    as zstring ptr imgName
    as integer ptr image
    as integer w
    as integer h
    as integer defaultAnim
end type



type Animation
        declare constructor
        declare constructor(filename as string)
        declare destructor
        declare sub load(filename as string)
        
        declare sub switch(next_anim as integer)
        declare sub hardSwitch(next_anim as integer)
        declare sub pause()
        declare sub play()
        declare sub restart()
        declare function done() as integer
        
        declare sub setSpeed(s as integer)
        
        declare sub drawAnimation(scnbuff as uinteger ptr, x as integer, y as integer)
        
        declare sub step_animation()
        declare function getWidth() as integer
        declare function getHeight() as integer 
        declare function getOffset() as Vector2D
    private:
        declare sub init()
        declare sub applySwitch()
        declare sub step_OneShot()
        declare sub step_Loop()
        declare sub step_Still()
        
        declare sub advance()
    
        as AnimationData_t ptr data_
        
        as integer completed
        as integer reachedEnd
        as integer currentAnim
        as integer delayCounter
        as integer currentFrame
        as integer drawFrame
        as integer isPaused
        as integer isReleasing
        as integer pendingSwitch
        as integer speed
    
        static as HashTable animHash
        static as integer initAnimHash
        
end type


#endif