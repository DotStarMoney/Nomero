dim as integer ptr image, newimage
dim as integer ptr template

screenres 640,480,32

image = imagecreate(288, 320)
newimage = imagecreate(288*1.5,320*1.5)
template = imagecreate(32, 64)
bload "mrspy.bmp", image

dim as integer xscan, yscan

'48x96

for yscan = 0 to 5 - 1
    for xscan = 0 to 9 - 1  
        get image, (xscan*32,yscan*64)-(xscan*32+31,yscan*64+63), template
        put newimage, (xscan*48 + 8, yscan*96 + 16), template, TRANS
    next xscan
next yscan

bsave "mrspy2.bmp", newimage

imagedestroy image



