#define SCRX 640
#define SCRY 480

screenres SCRX,SCRY,32

dim as integer ptr tile = imagecreate(128,128)
dim as integer rt = 0, col
dim as integer xtn, ytn
dim as integer xpn, ypn
dim as uinteger ptr src
dim as integer ppos(0 to 1)
dim as integer pdes(0 to 1)
dim as integer pdir(0 to 1)
dim as integer ptr ptile(0 to 1)
dim as integer byCol, byRow, oldCol
dim as integer xpos, ypos, w
dim as integer ptr scnptr
#define X_ 0
#define Y_ 1

scnptr = screenptr

bload "corner.bmp", tile

screenlock
for rt = 0 to 7
   
    xtn = 0
    ytn = 0
    xpn = (rt mod 4) * 128
    ypn = int(rt / 4) * 128
    if rt = 0 then
        put (xpn, ypn), tile, (xtn, ytn)-(xtn+127, ytn+127), PSET
    else
        ptile(X_) = @xtn
        ptile(Y_) = @ytn
        ppos(X_) = xpn
        ppos(Y_) = ypn
        pdes(X_) = xpn
        pdes(Y_) = ypn
        select case rt
        case 1
            byRow = X_
            byCol = Y_
            ppos(byRow) += 127
            ppos(byCol) += 127
            pdes(byRow) += -1
            pdes(byCol) += -1
            pdir(byRow) = -1
            pdir(byCol) = -1
        case 2
            byRow = Y_
            byCol = X_
            ppos(byRow) += 127
            ppos(byCol) += 0
            pdes(byRow) += -1
            pdes(byCol) += 128
            pdir(byRow) = -1
            pdir(byCol) = 1
        case 5
            byRow = X_
            byCol = Y_
            ppos(byRow) += 0
            ppos(byCol) += 127
            pdes(byRow) += 128
            pdes(byCol) += -1
            pdir(byRow) = 1
            pdir(byCol) = -1
        case 4
            byRow = Y_
            byCol = X_
            ppos(byRow) += 0
            ppos(byCol) += 127
            pdes(byRow) += 128
            pdes(byCol) += -1
            pdir(byRow) = 1
            pdir(byCol) = -1
        case 3
            byRow = X_
            byCol = Y_
            ppos(byRow) += 127
            ppos(byCol) += 0
            pdes(byRow) += -1
            pdes(byCol) += 128
            pdir(byRow) = -1
            pdir(byCol) = 1
        case 6
            byRow = Y_
            byCol = X_
            ppos(byRow) += 127
            ppos(byCol) += 127
            pdes(byRow) += -1
            pdes(byCol) += -1
            pdir(byRow) = -1
            pdir(byCol) = -1
        case 7
            byRow = X_
            byCol = Y_
            ppos(byRow) += 0
            ppos(byCol) += 0
            pdes(byRow) += 128
            pdes(byCol) += 128
            pdir(byRow) = 1
            pdir(byCol) = 1
        end select
        ypos = ytn
        oldCol = ppos(byCol)
        while ppos(byRow) <> pdes(byRow)
            ppos(byCol) = oldCol
            xpos = xtn
            while ppos(byCol) <> pdes(byCol)
                
                col = tile[8 + xpos + ypos*128]
                scnptr[ppos(X_) + ppos(Y_) * SCRX] = col 
                ppos(byCol) += pdir(byCol)
                xpos += 1
            wend
            ppos(byRow) += pdir(byRow)
            ypos += 1
        wend
    end if  
    
next rt
screenunlock

sleep

imagedestroy tile