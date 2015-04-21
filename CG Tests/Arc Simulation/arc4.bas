#include "electricarc.bi"
#include "vector2d.bi"

dim as ElectricArc arc
dim as integer ptr screenBuf
dim as integer arcs(0 to 20)
dim as integer i, mx, my
dim as Vector2D ptA
         
randomize 13                        
screenres 640,480,32

screenbuf = imagecreate(640,480)                

arc.init(640,480)
                     
for i = 0 to 9
    arcs(i) = arc.create()
    arc.setPoints(arcs(i), Vector2D(20 + i*60, 40), Vector2D(60 + i*60, 40))
next i

for i = 10 to 19
    arcs(i) = arc.create()
    arc.setPoints(arcs(i), Vector2D(20 + (i-10)*60, 300), Vector2D(60 + (i-10)*60, 400))
next i

arcs(20) = arc.create()
ptA = Vector2D(320, 200)

do
    getmouse mx, my
    line screenbuf, (0,0)-(639,479), 0, BF
    
    
    arc.setPoints(arcs(20), ptA, Vector2D(mx, my))
    
    
    arc.stepArcs(1.0 / 60.0)
    arc.drawArcs(screenbuf)
        
    put (0,0), screenbuf, pset
    sleep 20
loop until multikey(1)
