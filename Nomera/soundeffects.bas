#include "soundeffects.bi"
#include "fmod.bi"

constructor SoundEffects()


end constructor

sub SoundEffects.init()
	sounds(SND_EXPLODE_1)	   = FSOUND_SAMPLE_Load(FSOUND_FREE,"explode1.wav",0,0,0)                        :volume(SND_EXPLODE_1)      = 255
	sounds(SND_EXPLODE_2)	   = FSOUND_SAMPLE_Load(FSOUND_FREE,"explode2.wav",0,0,0)                        :volume(SND_EXPLODE_2)      = 255
	sounds(SND_JUMP) 		   = FSOUND_SAMPLE_Load(FSOUND_FREE,"jump.wav",0,0,0)                            :volume(SND_JUMP)           = 128
	sounds(SND_FULLCHARGE) 	   = FSOUND_SAMPLE_Load(FSOUND_FREE,"fullcharge.wav",0,0,0)                      :volume(SND_FULLCHARGE)     = 255
	sounds(SND_LAND) 		   = FSOUND_SAMPLE_Load(FSOUND_FREE,"land.wav",0,0,0)                            :volume(SND_LAND)           = 255
	sounds(SND_THROW)		   = FSOUND_SAMPLE_Load(FSOUND_FREE,"throw.wav",0,0,0)                           :volume(SND_THROW)          = 255
	sounds(SND_SHOOT)		   = FSOUND_SAMPLE_Load(FSOUND_FREE,"shoot.wav",0,0,0)                           :volume(SND_SHOOT)	         = 255
	sounds(SND_ALARM) 		   = FSOUND_SAMPLE_Load(FSOUND_FREE,"alert.wav",0,0,0)                           :volume(SND_ALARM)          = 255
	sounds(SND_DOOR) 		   = FSOUND_SAMPLE_Load(FSOUND_FREE,"door.wav",0,0,0)                            :volume(SND_DOOR)           = 255
	sounds(SND_DRIP) 		   = FSOUND_SAMPLE_Load(FSOUND_FREE,"drip.wav",0,0,0)                            :volume(SND_DRIP)           = 255
	sounds(SND_HURT) 		   = FSOUND_SAMPLE_Load(FSOUND_FREE,"hurt.wav",0,0,0)                            :volume(SND_HURT)           = 255
	sounds(SND_DEATH)		   = FSOUND_SAMPLE_Load(FSOUND_FREE,"death.wav",0,0,0)                           :volume(SND_DEATH)          = 255
    sounds(SND_SPINNER)        = FSOUND_SAMPLE_Load(FSOUND_FREE,"hudspinner2.wav",0,0,0)                     :volume(SND_SPINNER)        = 80
    sounds(SND_SIGNAL)         = FSOUND_SAMPLE_Load(FSOUND_FREE,"signal.wav",0,0,0)                          :volume(SND_SIGNAL)         = 64
    sounds(SND_PLACE_APMINE)   = FSOUND_SAMPLE_Load(FSOUND_FREE,"AntiPersonnelMine.wav",0,0,0)               :volume(SND_PLACE_APMINE)   = 128
    sounds(SND_PLACE_ELECMINE) = FSOUND_SAMPLE_Load(FSOUND_FREE,"ElectricMine.wav",0,0,0)                    :volume(SND_PLACE_ELECMINE) = 200
    sounds(SND_EXPLODE_3)      = FSOUND_SAMPLE_Load(FSOUND_FREE,"ElecBlast.wav",0,0,0)                       :volume(SND_EXPLODE_3)      = 100
    sounds(SND_ARC1)           = FSOUND_SAMPLE_Load(FSOUND_FREE,"Arc1PO.wav",0,0,0)                          :volume(SND_ARC1)           = 56
    sounds(SND_ARC2)           = FSOUND_SAMPLE_Load(FSOUND_FREE,"Arc2PO.wav",0,0,0)                          :volume(SND_ARC2)           = 56
    sounds(SND_PLACE_GASMINE)  = FSOUND_SAMPLE_Load(FSOUND_FREE,"SmokeMinePlace.wav",0,0,0)                  :volume(SND_PLACE_GASMINE)  = 255
    sounds(SND_EXPLODE_4)      = FSOUND_SAMPLE_Load(FSOUND_FREE,"SmokeMineBlast.wav",0,0,0)                  :volume(SND_EXPLODE_4)      = 64
    sounds(SND_GEARS)          = FSOUND_SAMPLE_Load(FSOUND_FREE,"objects\media\gears.wav",0,0,0)             :volume(SND_GEARS)          = 50
    sounds(SND_COLLIDE)        = FSOUND_SAMPLE_Load(FSOUND_FREE,"objects\media\collide.wav",0,0,0)           :volume(SND_COLLIDE)        = 255
    sounds(SND_SELECT)         = FSOUND_SAMPLE_Load(FSOUND_FREE,"objects\media\select.wav",0,0,0)            :volume(SND_SELECT)         = 64   
    sounds(SND_CLACKUP)        = FSOUND_SAMPLE_Load(FSOUND_FREE,"objects\media\clackUP.wav",0,0,0)           :volume(SND_CLACKUP)        = 32
    sounds(SND_CLACKDOWN)      = FSOUND_SAMPLE_Load(FSOUND_FREE,"objects\media\clackDown.wav",0,0,0)         :volume(SND_CLACKDOWN)      = 32     
    sounds(SND_SUCCESS)        = FSOUND_SAMPLE_Load(FSOUND_FREE,"success.wav",0,0,0)                         :volume(SND_SUCCESS)        = 40  
    sounds(SND_RUMBLE)         = FSOUND_SAMPLE_Load(FSOUND_FREE,"objects\media\rockslide_raw2.wav",0,0,0)    :volume(SND_RUMBLE)         = 255   
end sub

sub SoundEffects.setLink(link_ as objectLink)
	link = link_
end sub

sub SoundEffects.stopSound(chnl as integer)
    FSOUND_StopSound(chnl)
end sub

function SoundEffects.playSound(s as SoundEffect_e) as integer
	dim as integer chnl
	if s = SND_EXPLODE then
		if int(rnd * 2) = 0 then
            s = SND_EXPLODE_1
		else
            s = SND_EXPLODE_2
		end if		
	elseif s = SND_ARC then
 		if int(rnd * 2) = 0 then
            s = SND_ARC1
		else
            s = SND_ARC2
		end if	   
	end if
    chnl = FSOUND_PlaySound(FSOUND_FREE, sounds(s))
    select case s
    case SND_GEARS
        FSOUND_SetLoopMode(chnl, FSOUND_LOOP_NORMAL)
    case else
        FSOUND_SetLoopMode(chnl, FSOUND_LOOP_OFF)
    end select
    FSOUND_SetVolumeAbsolute chnl, volume(s)
    return chnl
end function
