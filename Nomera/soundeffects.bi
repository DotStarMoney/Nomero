#ifndef SOUNDEFFECTS_BI
#define SOUNDEFFECTS_BI


#include "objectlink.bi"

#define NUM_SOUNDS 14

enum SoundEffect_e
	SND_EXPLODE_1
	SND_EXPLODE_2
	SND_FULLCHARGE
	SND_JUMP
	SND_LAND
	SND_THROW
	SND_SHOOT
	SND_ALARM
	SND_DOOR
	SND_DRIP
	SND_HURT
	SND_DEATH
	SND_EXPLODE
    SND_SPINNER
    SND_SIGNAL
end enum

type SoundEffects
	public:
		declare constructor()
		declare sub init()
		declare sub setLink(link_ as objectLink)
		declare sub playSound(s as SoundEffect_e)
		
	private:
		as ObjectLink link
		as integer ptr sounds(0 to NUM_SOUNDS - 1)
end type
	

#endif
