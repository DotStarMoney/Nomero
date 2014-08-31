#include "soundeffects.bi"
#include "fmod.bi"

constructor SoundEffects()


end constructor

sub SoundEffects.init()
	sounds(SND_EXPLODE)	 	= FSOUND_SAMPLE_Load(FSOUND_FREE,"explode.wav",0,0,0)
	sounds(SND_JUMP) 		= FSOUND_SAMPLE_Load(FSOUND_FREE,"jump.wav",0,0,0)
	sounds(SND_FULLCHARGE) 	= FSOUND_SAMPLE_Load(FSOUND_FREE,"fullcharge.wav",0,0,0)
	sounds(SND_LAND) 		= FSOUND_SAMPLE_Load(FSOUND_FREE,"land.wav",0,0,0)
	sounds(SND_THROW)		= FSOUND_SAMPLE_Load(FSOUND_FREE,"throw.wav",0,0,0)
	sounds(SND_SHOOT)		= FSOUND_SAMPLE_Load(FSOUND_FREE,"shoot.wav",0,0,0)
	sounds(SND_ALARM) 		= FSOUND_SAMPLE_Load(FSOUND_FREE,"alert.wav",0,0,0)
	sounds(SND_DOOR) 		= FSOUND_SAMPLE_Load(FSOUND_FREE,"door.wav",0,0,0)
	sounds(SND_DRIP) 		= FSOUND_SAMPLE_Load(FSOUND_FREE,"drip.wav",0,0,0)
	sounds(SND_HURT) 		= FSOUND_SAMPLE_Load(FSOUND_FREE,"hurt.wav",0,0,0)
	sounds(SND_DEATH)		= FSOUND_SAMPLE_Load(FSOUND_FREE,"death.wav",0,0,0)
end sub

sub SoundEffects.setLink(link_ as objectLink)
	link = link_
end sub

sub SoundEffects.playSound(s as SoundEffect_e)
	FSOUND_PlaySound (FSOUND_FREE, sounds(s))
end sub
