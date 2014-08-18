#include "gamespace.bi"

#ifdef DEBUG
    screenres SCRX*2,SCRY*2,32
#else
    screenres SCRX*2,SCRY*2,32,2
    screenset 1,0 
#endif

FSOUND_Init(44100, 3, 0)







Dim as GameSpace gameNomero


gameNomero.go


end
