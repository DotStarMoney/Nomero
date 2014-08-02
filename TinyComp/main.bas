#include "gamespace.bi"

#ifdef DEBUG
    screenres SCRX*2,SCRY*2,32
#else
    screenres SCRX*2,SCRY*2,32,2
    screenset 1,0 
#endif

Dim as GameSpace gameNomero


gameNomero.go


end
