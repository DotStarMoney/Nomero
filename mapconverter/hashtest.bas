screenres 640,480,32


dim as integer ptr little = imagecreate(16,16)

function hashImage(img as integer ptr) as integer
    dim as integer x, y
    dim as integer col
    dim as integer hash
    for y = 0 to 15
        for x = 0 to 15
            hash = hash xor point(x, y, img)
        next x
    next y
    return hash
end function

bload "little.bmp", little
print hashImage(little)
sleep
end
