#include "spline2.bi"
#define SCRX 640
#define SCRY 480

dim as Spline2 bs
dim as integer i, q, anchors(0 to 7)
dim as Vector3D vecs(0 to 4)
dim as Vector2D p
dim as Vector3D sp
dim as double tpos, length, colF, radF

screenres SCRX,SCRY,32,2
screenset 1,0
randomize 13

for i = 0 to 4
    bs.addControlPoint(Vector3D(SCRX*rnd - SCRX*0.5,SCRY*rnd - SCRY*0.5,0))
next i
q = 0

length = bs.getLength()

for i = 0 to 7
    anchors(i) = bs.createAnchor(length * rnd)
next i

for i = 0 to 4
    vecs(i) = Vector3D(2*rnd - 1, 2*rnd - 1, 2*rnd - 1)
    vecs(i) = vecs(i).normalize()
next i


do
    cls
    print q
        
    tpos = 0
    while tpos < bs.getLength()
        sp = bs.getPoint(tpos)  
        p = perspective(sp, Vector3D(0, 0, -256), 256, Vector2D(SCRX, SCRY), Vector2D(SCRX, SCRY))

        colF = (128 + sp.z)
        if colF < 0 then colF = 0
        if colF > 255 then colF = 255
        pset (p.x, p.y), rgb(colF, colF, colF)
        tpos += 4
    wend
    
    for i = 0 to 7
        sp = bs.getAnchor(anchors(i))
        p = perspective(sp, Vector3D(0, 0, -256), 256, Vector2D(SCRX, SCRY), Vector2D(SCRX, SCRY))
        radF = abs(1 / (sp.z - 255)) * 1000
        colF = (128 + sp.z)
        if colF < 0 then colF = 0
        if colF > 255 then colF = 255
        circle (p.x, p.y), radF, rgb(colF,0,0),,,,F
    next i
    
    
    for i = 0 to 4
        bs.setControlPoint(i, bs.getControlPoint(i) + vecs(i))
    next i

    q += 1
    flip
    sleep 33
loop until multikey(1)
end
 