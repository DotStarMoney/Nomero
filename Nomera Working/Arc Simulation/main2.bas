#include "highvoltagearc.bi"
#define SCRX 640
#define SCRY 480

dim as Spline2 bs
dim as Vector2D p, op, d
dim as Vector3D sp
dim as double tpos, length, colF, radF, mag, smallest, theta, phi
dim as integer i, pts_n = 12, mx, my, mb, o_mb, click, isGrabbing = 0, grabIndex
dim as HighVoltageArc arc
dim as Vector3D a, b, c

screenres SCRX,SCRY,32,2
screenset 1,0
randomize 15

arc.setEndpoints(Vector3D(-300, 200, 0), Vector3D(300, 200, 0))
arc.init()
do
    cls

    arc.step_(1)
    arc.draw_(1)
    
    
    flip
    sleep 33
loop until multikey(1)
end
 