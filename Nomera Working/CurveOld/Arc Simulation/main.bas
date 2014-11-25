#include "spline2.bi"
#define SCRX 640
#define SCRY 480

dim as Spline2 bs
dim as integer i
dim as Vector2D p
dim as Vector3D sp
dim as double tpos

screenres SCRX,SCRY,32,2
screenset 1,0
randomize 13

for i = 0 to 4
    bs.addControlPoint(Vector3D(SCRX*rnd - SCRX*0.5,SCRY*rnd - SCRY*0.5,0))
next i

do
    cls
    'print bs.getLength()
    
    
    for i = 0 to bs.getControlPointN() - 1
        sp = bs.getControlPoint(i)
        p = perspective(sp, Vector3D(0,0,-256), 256, Vector2D(SCRX, SCRY), Vector2D(SCRX, SCRY))
        circle (p.x, p.y), 5+i
        circle (p.x, p.y), 3
    next i

    
    tpos = 0
    while tpos < bs.getLength()
        sp = bs.getPoint(tpos)
        locate 2,1: print sp, tpos

        tpos += 5
        
        p = perspective(sp, Vector3D(0,0,-256), 256, Vector2D(SCRX, SCRY), Vector2D(SCRX, SCRY))
       ' print sp
        
        pset (p.x, p.y)
        flip
        sleep
    wend
    
    

    flip
    sleep 100
loop until multikey(1)
end
