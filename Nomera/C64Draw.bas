#include "vector2D.bi"
#include "C64Draw.bi"
#include "utility.bi"

sub C64.clearError()
    errorThrown=""
End sub
function C64.loadImage(scnspace as screenSpace, filename as string) as image
    dim as integer ptr tempImg
    dim as integer f
    dim as image   ret
    dim as integer x, y, i, index, col, ccol
    dim as double  r, g, b, dist, cr, cg, cb, cdist
    f = freefile
    open filename for binary access read as #f
    get #f, 19, ret.sizeX
    get #f, 23, ret.sizeY
    close #f
    tempImg = imagecreate(ret.sizeX, ret.sizeY)
    bload filename, tempImg
    ret.pixels = allocate(sizeof(byte) * ret.sizeX * ret.sizeY)
    for y = 0 to ret.sizeY - 1
        for x = 0 to ret.sizeX - 1
            col = point(x, y, tempImg)
            r = (col shr 16) and &hff
            g = (col shr 8) and &hff
            b = (col and &hff)
            dist = 1000000
            index = 0
            for i = 0 to 15
                ccol = scnspace.palletteData[i]
                cr = (ccol shr 16) and &hff
                cg = (ccol shr 8) and &hff
                cb = (ccol and &hff) 
                cdist = sqr((r-cr)^2+(g-cg)^2+(b-cb)^2)
                if cdist < dist then
                    dist = cdist
                    index = i
                end if
            next i
            ret.pixels[y * ret.sizeX + x] = index
        next x
    next y
    return ret
end function
sub C64.deleteImage(im as image)
    deallocate(im.pixels)
end sub
Function C64.loadStandardPallette(byref pallette as screenPallette) as bool
    If pallette<>0 Then throwErr("PALLETTE ALREADY EXISTS")
    pallette = allocate(64)
    If pallette=0 Then throwErr("OUT OF MEMORY")
    pallette[00]=&H000000:pallette[01]=&HFFFFFF:pallette[02]=&H894036:pallette[03]=&H7ABFC7
    pallette[04]=&H8A46AE:pallette[05]=&H68A941:pallette[06]=&H3E31A2:pallette[07]=&HD0DC71
    pallette[08]=&H905F25:pallette[09]=&H5C4700:pallette[10]=&HBB776D:pallette[11]=&H555555
    pallette[12]=&H808080:pallette[13]=&HACEA88:pallette[14]=&H7C70DA:pallette[15]=&HABABAB
    return true
End Function
Function C64.loadCustomPallette(byref pallette as screenPallette, cPal() as uinteger) as bool
    If pallette<>0 Then throwErr("PALLETTE ALREADY EXISTS")
    pallette=allocate(64)
    If pallette=0 then throwErr("OUT OF MEMORY")
    Dim as integer i=lbound(cPal)
    if ubound(cPal)-i <> 15 Then throwErr("INVALID CUSTOM PALLETTE")
    pallette[00]=cPal(i):i+=1:pallette[01]=cPal(i):i+=1:pallette[02]=cPal(i):i+=1:pallette[03]=cPal(i):i+=1
    pallette[04]=cPal(i):i+=1:pallette[05]=cPal(i):i+=1:pallette[06]=cPal(i):i+=1:pallette[07]=cPal(i):i+=1
    pallette[08]=cPal(i):i+=1:pallette[09]=cPal(i):i+=1:pallette[10]=cPal(i):i+=1:pallette[11]=cPal(i):i+=1
    pallette[12]=cPal(i):i+=1:pallette[13]=cPal(i):i+=1:pallette[14]=cPal(i):i+=1:pallette[15]=cPal(i)
    return false
End Function
Function C64.unloadPallette(byref pallette as screenPallette) as bool
    If pallette<>0 Then 
        Deallocate pallette
        pallette = 0
    end if
    return true
end Function
Function C64.loadScreenSpace(byref sDat as screenSpace, pallette as screenPallette) as bool
    If pallette=0 Then throwErr("BAD PALLETTE")
    if sDat.screenData<>0 Then throwErr("SCREEN DATA ALREADY EXISTS")
    sDat.screenData=allocate(32000)
    If sDat.screenData=0 Then throwErr("OUT OF MEMORY")
    sDat.palletteData=pallette
    return true
End Function
Function C64.unloadScreenSpace(byref sDat as screenSpace) as bool
    If sDat.screenData <> 0 Then Deallocate sDat.screenData
    If sDat.palletteData <> 0 Then Deallocate sDat.palletteData
    return true
End Function
function C64.drawScreen(dstbuffer as integer ptr, x as integer, y as integer, sDat as screenSpace) as bool
    if sDat.palletteData=0 orElse sDat.screenData=0 Then throwErr("BAD SCREEN SPACE")
    dim as integer scrnW,scrnH,bd
    dim as uinteger ptr dest
    dim as ubyte ptr    src
    dim as integer xs, ys, xoff, yoff, col
    dim as integer x0, y0, x1, y1, stride
    dim as integer src_ystep, dst_ystep, stp, dimmer
    imageinfo dstbuffer,scrnW,scrnH,bd,stride,dest
    
    if dest=0 Then throwErr("NO VISIBLE DRAW SCREEN")
    if bd<>4 then throwErr("GRAPHICS MODE NOT 32 BIT")
    If scrnW<320 orElse scrnH<200 Then throwErr("DRAW SCREEN TOO SMALL") 
    src  = sDat.screenData
    
    if anyClip(x, y, 320, 200, 0, 0, scrnW - 1, scrnH - 1,_
               xoff, yoff, x0, y0, x1, y1) then
        
        stride /= 4
         
        src_ystep = 160 - int((x1 - x0 + 1) / 2)
        dst_ystep = stride - (x1 - x0 + 1)
        stp = x0 and 1
        
        dest += stride * yoff + xoff
        src  += 160 * y0 + x0 shr 1 
        
        dimmer = &h3F3F3F
        
        For ys = y0 to y1
            for xs = x0 to x1
                if ys and 1 then
                    col = sDat.palletteData[*src]
                    asm
                        movd    xmm0,   [col]
                        movd    xmm1,   [dimmer]
                        psubusb xmm0,   xmm1
                        movd    [col],  xmm0
                    end asm
                    *dest = col
                else
                    *dest = sDat.palletteData[*src]
                end if
                dest += 1            
                src += (xs + stp) and 1
            Next xs
            src += src_ystep
            dest += dst_ystep
        Next ys
        
    end if
    return true
end function
function C64.copyScreen(s1 as screenSpace, s2 as screenSpace) as ubyte
    if s1.palletteData=0 orElse s1.screenData=0 Then throwErr("BAD SCREEN SPACE")
    if s2.palletteData=0 orElse s2.screenData=0 Then throwErr("BAD SCREEN SPACE")
    dim as ubyte ptr offsetRead = s1.screenData, offsetWrite = s2.screenData
    asm
        mov ecx, 400
        mov eax, [offsetRead]
        mov ebx, [offsetWrite]
        C64Draw_BI_copyScreen_copyLoop:
        movq mm0, [eax]
        movq [ebx], mm0
        add eax,8
        add ebx,8
        movq mm0, [eax]
        movq [ebx], mm0
        add eax,8
        add ebx,8
        movq mm0, [eax]
        movq [ebx], mm0
        add eax,8
        add ebx,8
        movq mm0, [eax]
        movq [ebx], mm0
        add eax,8
        add ebx,8
        movq mm0, [eax]
        movq [ebx], mm0
        add eax,8
        add ebx,8
        movq mm0, [eax]
        movq [ebx], mm0
        add eax,8
        add ebx,8
        movq mm0, [eax]
        movq [ebx], mm0
        add eax,8
        add ebx,8
        movq mm0, [eax]
        movq [ebx], mm0
        add eax,8
        add ebx,8
        movq mm0, [eax]
        movq [ebx], mm0
        add eax,8
        add ebx,8
        movq mm0, [eax]
        movq [ebx], mm0
        add eax,8
        add ebx,8
        dec ecx
        jnz C64Draw_BI_copyScreen_copyLoop
        emms
    end asm
    return true
end function
function C64.clearScreen(sDat as screenSpace, col as ubyte = 0) as ubyte
    if sDat.palletteData=0 orElse sDat.screenData=0 Then throwErr("BAD SCREEN SPACE")
    if col < 0 orElse col > 15 Then throwErr("INVALID PALLETTE COLOR")
    dim as ubyte ptr offsetWrite=sDat.screenData
    dim as uinteger col4 = col
    col4 = col4 or (col4 shl 8) or (col4 shl 16) or (col4 shl 24)
    asm
        mov eax, [col4]
        movd mm0, eax
        punpckldq mm0, mm0
        mov ebx, 400
        mov eax, [offsetWrite]
        C64Draw_BI_clearScreen_clearLoop:
        movq [eax], mm0
        add eax,8
        movq [eax], mm0
        add eax,8
        movq [eax], mm0
        add eax,8
        movq [eax], mm0
        add eax,8
        movq [eax], mm0
        add eax,8
        movq [eax], mm0
        add eax,8
        movq [eax], mm0
        add eax,8
        movq [eax], mm0
        add eax,8
        movq [eax], mm0
        add eax,8
        movq [eax], mm0
        add eax,8
        dec ebx
        jnz C64Draw_BI_clearScreen_clearLoop
        emms
    end asm
    return true
end function
function C64.PIXEL(sDat as screenSpace, x as ubyte, y as ubyte, col as ubyte) as bool
    If col < 0 orElse col > 15 Then throwErr("INVALID PALETTE COLOR")
    If x < 0 or x > 159 Then throwErr("INVALID X COORDINATE")
    If y < 0 or y > 199 Then throwErr("INVALID Y COORDINATE")
    If sDat.screenData=0 orElse sDat.palletteData=0 Then throwErr("BAD SCREEN SPACE")
    dim as uinteger address=x+y*160
    sDat.screenData[address] = col
    return true
End function
function C64.loadFont(fontLoad as fontSpace, identifier as FontStyle) as bool
    If fontLoad.fontData<>0 Then throwErr("FONT ALREADY EXISTS")
    Dim as integer i, q, o
    Dim as uinteger uUpper, uLower
    Select Case identifier
    Case ArenaB
        static as uinteger ArenaB_packed(107) = _
        {103180030,4267712512,270014540,1824980734,4244508412,4228841212,1065345216,3235937854,_
        4244506310,3335453944,4294902008,4173397758,4278059256,4173381824,2147467486,3737583230,_
        3772834046,4276150496,943194168,943208504,2122186766,235863804,507279600,4034411550,_
        3772834016,3772841726,4244555478,3604403926,4244555462,3334915782,4244506310,3334930044,_
        4244506366,4242596064,2097022662,3738107518,4244506366,4228779534,1886419004,504299260,_
        4294901984,3772841598,3334915782,3334930046,3334915822,1820080184,3604403926,3603365502,_
        3334915692,4006004422,3334915838,2080389176,4278059036,946929406,0,0,_
        1010580508,469769244,0,0,0,0,0,0,_
        0,0,0,0,0,0,0,0,_
        0,0,0,0,0,0,0,3684464,_
        0,0,0,3947580,0,0,2097024734,4142333564,_
        4177271836,471604252,4244508414,4227923710,4244506366,4261871356,946921726,4261416462,_
        4278059260,4261871356,473460988,4261871228,4278059036,943222896,2097071740,4274454140,_
        2130624766,2114850318,0,0}
        fontLoad.style = ArenaB
        fontLoad.fontData = allocate(3456)
        If fontLoad.fontData = 0 Then throwErr("OUT OF MEMORY")
        For i = 0 to 255: fontLoad.ASCIImap(i)=53: Next i
        For i = 65 to 90: fontLoad.ASCIImap(i)=i-64: Next i
        For i = 48 to 57: fontLoad.ASCIImap(i)=i-5: Next i
        fontLoad.ASCIImap(33)=28
        fontLoad.ASCIImap(46)=41
        fontLoad.ASCIImap(44)=39
        fontLoad.ASCIImap(32)=27
        fontLoad.ASCIImap(60)=0
        For i = 0 to 107 step 2
            uLower = ArenaB_packed(i)
            uUpper = ArenaB_packed(i+1)
            For q =  0 to 31: fontLoad.fontData[o+q] = ((uLower shr (31-q)) And 1) * &HFF: Next q
            For q = 32 to 63: fontLoad.fontData[o+q] = ((uUpper shr (63-q)) And 1) * &HFF: Next q
            o += 64
        Next i
    Case AlternateReality
        static as uinteger AlternateReality_packed(255) = _
        {4079965,1365066046,15974,1717975808,1064329340,1717992448,15456,1617312768,_
        4228253246,1717975552,15968,4235214336,236460056,1041766400,425164,3430466172,_
        3227541612,1986424576,1879054348,202116096,939527180,202116216,2019582572,2020402688,_
        806885400,404229120,12609150,2120901376,12614758,1717986048,15470,1719024640,_
        12614758,1719427296,15206,1715340807,12614774,1616928768,212584,1016495104,_
        1605400,813052444,58982,1718500096,58982,1715214336,58219,2134783488,_
        222780,406611648,58982,1715391608,15172,403588668,0,0,_
        0,0,0,0,0,0,0,0,_
        0,0,31800,268449848,3543552,0,9342,612246528,_
        406741052,108795904,6712344,812008960,473308216,1868970752,470550560,0,_
        1047981272,3639375422,2087597851,456617596,4794973,1563052288,792702,405798912,_
        0,404228144,32322,2113929216,0,813182976,924700,943222784,_
        2093926086,3336993792,943200280,404232192,2095451160,811662848,2114721804,107363328,_
        203177068,3439201280,2120252422,107363328,2093400316,3469108280,2114325528,808464384,_
        2093934204,3471211520,2093926118,2114721840,942422016,942422016,0,0,_
        0,0,0,0,0,0,1011246604,402659328,_
        0,0,2023504950,1046898371,4000539491,1852007390,1011271360,3267520056,_
        4000539491,1667458014,1046997244,3974587964,4284706172,1818255456,1011271360,3737544248,_
        3301361398,3469133510,806885400,404232204,504105996,215791712,3328994424,2020371654,_
        3764412512,1617329784,3286761435,3687039975,3334924022,3738093254,2093926086,3334923900,_
        4234569318,1818255552,2095498950,3334917759,4000540268,1717986243,1013149756,235294332,_
        4264583360,2160229948,3865470566,1717988927,3278268006,1717976088,3284386771,3420419938,_
        3252909628,1009674179,3328599654,1044125816,2126908536,1046529022,0,0,_
        0,0,0,1064626431,0,4286677503,0,4230879231,_
        3254763969,3254714368,619127832,16711680,2214560643,2214526976,3907707624,3940739306,_
        665290535,2810652583,4294923775,2854354944,8874,4283826175,4294956543,3573470960,_
        4294945791,729770767,4040621780,4292214783,258703147,4289462271,8352,3765102830,_
        1029,123082615,2631720,943208464,4038655164,3170679024,705969763,2071166774,_
        271061048,1149387832,16909320,2422235280,410937051,3680927256,4285159084,3563782143,_
        4168110192,2395569664,6733229,3048029184,1617825358,3815480,1009031526,409370880,_
        239,2330601704,174,2762253476,161,2715918753,221,1440027933,_
        220,1356337180,0,0,0,0,0,0}
        fontLoad.style = AlternateReality
        fontLoad.fontData = allocate(8192)
        If fontLoad.fontData = 0 Then throwErr("OUT OF MEMORY")
        For i = 0 to 255: fontLoad.ASCIImap(i)=127: Next i
        For i = 97 to 122: fontLoad.ASCIImap(i)=i-96: Next i
        For i = 33 to 58: fontLoad.ASCIImap(i)=i: Next i
        For i = 65 to 90: fontLoad.ASCIImap(i)=i: Next i
        For i = 91 to 93: fontLoad.ASCIImap(i)=i+2: Next i
        For i = 123 to 125: fontLoad.ASCIImap(i)=i-27: Next i
        For i = 128 to 148: fontLoad.ASCIImap(i)=i-29: Next i
        fontLoad.ASCIImap(32)=32
        fontLoad.ASCIImap(63)=63
        fontLoad.ASCIImap(0)=127
        For i = 0 to 255 step 2
            uLower = AlternateReality_packed(i)
            uUpper = AlternateReality_packed(i+1)
            For q =  0 to 31: fontLoad.fontData[o+q] = ((uLower shr (31-q)) And 1) * &HFF: Next q
            For q = 32 to 63: fontLoad.fontData[o+q] = ((uUpper shr (63-q)) And 1) * &HFF: Next q
            o += 64
        Next i
    Case SevenUp
        static as uinteger SevenUp_packed(127) = _
        {0,0,4274439934,3337020928,4240885500,3873897472,4274438336,3773234688,_
        4174169798,3873897984,4274045176,3772841472,4261462264,3772833792,4274438350,3873897984,_
        3334915838,3873891840,2083532848,943225856,504105996,484210688,3335313616,4176274944,_
        3233857728,3772841472,3337551574,3873891840,3335970526,4008109568,4274439910,3873897984,_
        4274439934,3772833792,4274439878,4008640256,4274439934,4176274944,4274438398,115801600,_
        4264570928,943208448,3334915782,3873897984,3334915814,3875437568,3334919902,4008109568,_
        3334896696,2095506944,3334915708,808990720,4261809208,1893793280,1852730990,1852730990,_
        4278190080,0,4294901760,0,1588350,404232216,1060991,2133856256,_
        0,0,808464440,3684352,1717986816,0,1718026086,4284900864,_
        406741052,108795904,1650854936,812008960,1013333048,1734754048,101455872,0,_
        202911792,806882304,806882316,202911744,6700287,1013317632,1579134,404226048,_
        0,3158128,126,0,0,1579008,198156,405823488,_
        2093403862,3873864704,812675120,943259136,2095449612,1893793280,2093352476,113671168,_
        506881734,4278584832,4274060294,115801088,2093400316,3873864704,4274392112,808990720,_
        2093401724,3873864704,2093401726,115768320,6144,1572864,6144,1579056,_
        236466400,1882725888,32256,2113929216,1880624135,236746752,0,0}
        fontLoad.style = SevenUp
        fontLoad.fontData = allocate(4096)
        If fontLoad.fontData = 0 Then throwErr("OUT OF MEMORY")
        For i = 0 to 255: fontLoad.ASCIImap(i)=63: Next i
        For i = 65 to 90: fontLoad.ASCIImap(i)=i-64: Next i
        For i = 33 to 62: fontLoad.ASCIImap(i)=i: Next i
        For i = 123 to 125: fontLoad.ASCIImap(i)=i-96: Next i
        fontLoad.ASCIImap(32)=32
        fontLoad.ASCIImap(94)=31
        fontLoad.ASCIImap(92)=32
        For i = 0 to 127 step 2
            uLower = SevenUp_packed(i)
            uUpper = SevenUp_packed(i+1)
            For q =  0 to 31: fontLoad.fontData[o+q] = ((uLower shr (31-q)) And 1) * &HFF: Next q
            For q = 32 to 63: fontLoad.fontData[o+q] = ((uUpper shr (63-q)) And 1) * &HFF: Next q
            o += 64
        Next i
    Case DefaultUpperCase
        static as uinteger DefaultUpperCase_packed(511) = _
        {1013345902,1617050624,406611582,1717986816,2087085692,1717992448,1013342304,1617312768,_
        2020370022,1718384640,2120245368,1616936448,2120245368,1616928768,1013342318,1717976064,_
        1717986942,1717986816,1008211992,404241408,504105996,208418816,1718384752,2020369920,_
        1616928864,1616936448,1668775787,1667457792,1719041662,1852204544,1013343846,1717976064,_
        2087085692,1616928768,1013343846,1715211776,2087085692,2020369920,1013342268,107363328,_
        2115508248,404232192,1717986918,1717976064,1717986918,1715214336,1667457899,2138530560,_
        1717976088,1013343744,1717986876,404232192,2114325528,811630080,1009791024,808467456,_
        202518652,811793408,1007422476,202128384,1588350,404232216,1060991,2133856256,_
        0,0,404232216,6144,1717986816,0,1718026086,4284900864,_
        406741052,108795904,1650854936,812008960,1013333048,1734754048,101455872,0,_
        202911792,806882304,806882316,202911744,6700287,1013317632,1579134,404226048,_
        0,1579056,126,0,0,1579008,198156,405823488,_
        1013345910,1717976064,404240408,404258304,1013319180,811630080,1013319196,107363328,_
        101588582,2131101184,2120252422,107363328,1013342332,1717976064,2120616984,404232192,_
        1013343804,1717976064,1013343806,107363328,6144,1572864,6144,1579056,_
        236466272,806882816,32256,2113929216,1880624134,202928128,1013319180,402659328,_
        255,4278190080,136068735,2132557312,404232216,404232216,255,4278190080,_
        65535,0,16776960,0,0,4294901760,808464432,808464432,_
        202116108,202116108,224,4030208024,404233231,117440512,404240624,3758096384,_
        3233857728,3233873919,3235934264,470681347,50794012,946921664,4294951104,3233857728,_
        4294902531,50529027,3964542,2122202112,0,16776960,914325375,1042024448,_
        1616928864,1616928864,7,253499416,3286728252,1014949827,3964518,1719548928,_
        404252262,404241408,101058054,101058054,136068735,1042024448,404232447,4279769112,_
        3233820720,3233820720,404232216,404232216,830,1983264256,4286529311,252117761,_
        0,0,4042322160,4042322160,0,4294967295,4278190080,0,_
        0,255,3233857728,3233857728,3435934515,3435934515,50529027,50529027,_
        0,3435934515,4294900984,4041261184,50529027,50529027,404232223,521672728,_
        0,252645135,404232223,520093696,248,4162328600,0,65535,_
        31,521672728,404232447,4278190080,255,4279769112,404232440,4162328600,_
        3233857728,3233857728,3772834016,3772834016,117901063,117901063,4294901760,0,_
        4294967040,0,0,16777215,50529027,50593791,0,4042322160,_
        252645135,0,404232440,4160749568,4042322160,0,4042322160,252645135,_
        3281621393,2677654527,3888355713,2576980479,2207881603,2576974847,3281624991,2677654527,_
        2274597273,2576582655,2174721927,2678030847,2174721927,2678038527,3281624977,2576991231,_
        2576980353,2576980479,3286755303,3890725887,3790861299,4086548479,2576582543,2274597375,_
        2678038431,2678030847,2626191508,2627509503,2575925633,2442762751,3281623449,2576991231,_
        2207881603,2678038527,3281623449,2579755519,2207881603,2274597375,3281625027,4187603967,_
        2179459047,3890735103,2576980377,2576991231,2576980377,2579752959,2627509396,2156436735,_
        2576991207,3281623551,2576980419,3890735103,2180641767,3483337215,3285176271,3486499839,_
        4092448643,3483173887,3287544819,4092838911,4293378945,3890735079,4293906304,2161111039,_
        4294967295,4294967295,3890735079,4294961151,2576980479,4294967295,2576941209,10066431,_
        3888226243,4186171391,2644112359,3482958335,3281634247,2560213247,4193511423,4294967295,_
        4092055503,3488084991,3488084979,4092055551,4288267008,3281649663,4293388161,3890741247,_
        4294967295,4293388239,4294967169,4294967295,4294967295,4293388287,4294769139,3889143807,_
        3281621385,2576991231,3890726887,3890708991,3281648115,3483337215,3281648099,4187603967,_
        4193378713,2163866111,2174714873,4187603967,3281624963,2576991231,2174350311,3890735103,_
        3281623491,2576991231,3281623489,4187603967,4294961151,4293394431,4294961151,4293388239,_
        4058501023,3488084479,4294935039,2181038079,2414343161,4092039167,3281648115,3892307967,_
        4294967040,16777215,4158898560,2162409983,3890735079,3890735079,4294967040,16777215,_
        4294901760,4294967295,4278190335,4294967295,4294967295,65535,3486502863,3486502863,_
        4092851187,4092851187,4294967071,264759271,3890734064,4177526783,3890726671,536870911,_
        1061109567,1061093376,1059033031,3824285948,4244173283,3348045631,16191,1061109567,_
        64764,4244438268,4291002753,2172765183,4294967295,4278190335,3380641920,3252942847,_
        2678038431,2678038431,4294967288,4041467879,1008239043,3280017468,4291002777,2575418367,_
        3890715033,3890725887,4193909241,4193909241,4158898560,3252942847,3890734848,15198183,_
        1061146575,1061146575,3890735079,3890735079,4294966465,2311703039,8437984,4042849534,_
        4294967295,4294967295,252645135,252645135,4294967295,0,16777215,4294967295,_
        4294967295,4294967040,1061109567,1061109567,859032780,859032780,4244438268,4244438268,_
        4294967295,859032780,66311,253706111,4244438268,4244438268,3890735072,3773294567,_
        4294967295,4042322160,3890735072,3774873599,4294967047,132638695,4294967295,4294901760,_
        4294967264,3773294567,3890734848,16777215,4294967040,15198183,3890734855,132638695,_
        1061109567,1061109567,522133279,522133279,4177066232,4177066232,65535,4294967295,_
        255,4294967295,4294967295,4278190080,4244438268,4244373504,4294967295,252645135,_
        4042322160,4294967295,3890734855,134217727,252645135,4294967295,252645135,4042322160}
        fontLoad.style = DefaultUpperCase
        fontLoad.fontData = allocate(16384)
        If fontLoad.fontData = 0 Then throwErr("OUT OF MEMORY")
        For i = 64 to 91: fontLoad.ASCIImap(i)=i-64: Next i
        For i = 93 to 95: fontLoad.ASCIImap(i)=i-64: Next i
        For i = 32 to 63: fontLoad.ASCIImap(i)=i: Next i
        For i = 0 to 31: fontLoad.ASCIImap(i)=i+64: Next i
        For i = 96 to 127: fontLoad.ASCIImap(i)=i: Next i
        fontLoad.ASCIImap(156)=29
        For i = 128 to 255: fontLoad.ASCIImap(i)=FontLoad.ASCIImap(i)+128: Next i
        For i = 0 to 511 step 2
            uLower = DefaultUpperCase_packed(i)
            uUpper = DefaultUpperCase_packed(i+1)
            For q =  0 to 31: fontLoad.fontData[o+q] = ((uLower shr (31-q)) And 1) * &HFF: Next q
            For q = 32 to 63: fontLoad.fontData[o+q] = ((uUpper shr (63-q)) And 1) * &HFF: Next q
            o += 64
        Next i
    Case DefaultLowerCase
        static as uinteger DefaultLowerCase_packed(511) = _
        {1013345902,1617050624,15366,1046887936,6316156,1717992448,15456,1616919552,_
        394814,1717976576,15462,2120236032,923710,404232192,15974,1715340924,_
        6316156,1717986816,1572920,404241408,393222,101058108,6316140,2020369920,_
        3676184,404241408,26239,2137744128,31846,1717986816,15462,1717976064,_
        31846,1719427168,15974,1715340806,31846,1616928768,15968,1007057920,_
        1605144,404229632,26214,1717976576,26214,1715214336,25451,2134783488,_
        26172,406611456,26214,1715342456,32268,405831168,1009791024,808467456,_
        202518652,811793408,1007422476,202128384,1588350,404232216,1060991,2133856256,_
        0,0,404232216,6144,1717986816,0,1718026086,4284900864,_
        406741052,108795904,1650854936,812008960,1013333048,1734754048,101455872,0,_
        202911792,806882304,806882316,202911744,6700287,1013317632,1579134,404226048,_
        0,1579056,126,0,0,1579008,198156,405823488,_
        1013345910,1717976064,404240408,404258304,1013319180,811630080,1013319196,107363328,_
        101588582,2131101184,2120252422,107363328,1013342332,1717976064,2120616984,404232192,_
        1013343804,1717976064,1013343806,107363328,6144,1572864,6144,1579056,_
        236466272,806882816,32256,2113929216,1880624134,202928128,1013319180,402659328,_
        255,4278190080,406611582,1717986816,2087085692,1717992448,1013342304,1617312768,_
        2020370022,1718384640,2120245368,1616936448,2120245368,1616928768,1013342318,1717976064,_
        1717986942,1717986816,1008211992,404241408,504105996,208418816,1718384752,2020369920,_
        1616928864,1616936448,1668775787,1667457792,1719041662,1852204544,1013343846,1717976064,_
        2087085692,1616928768,1013343846,1715211776,2087085692,2020369920,1013342268,107363328,_
        2115508248,404232192,1717986918,1717976064,1717986918,1715214336,1667457899,2138530560,_
        1717976088,1013343744,1717986876,404232192,2114325528,811630080,404232447,4279769112,_
        3233820720,3233820720,404232216,404232216,859032780,859032780,865717350,865717350,_
        0,0,4042322160,4042322160,0,4294967295,4278190080,0,_
        0,255,3233857728,3233857728,3435934515,3435934515,50529027,50529027,_
        0,3435934515,3432592230,3432592230,50529027,50529027,404232223,521672728,_
        0,252645135,404232223,520093696,248,4162328600,0,65535,_
        31,521672728,404232447,4278190080,255,4279769112,404232440,4162328600,_
        3233857728,3233857728,3772834016,3772834016,117901063,117901063,4294901760,0,_
        4294967040,0,0,16777215,16975468,2020630528,0,4042322160,_
        252645135,0,404232440,4160749568,4042322160,0,4042322160,252645135,_
        3281621393,2677654527,4294951929,3248079359,4288651139,2576974847,4294951839,2678047743,_
        4294572481,2576990719,4294951833,2174731263,4294043585,3890735103,4294951321,2579626371,_
        4288651139,2576980479,4293394375,3890725887,4294574073,4193909187,4288651155,2274597375,_
        4291291111,3890725887,4294941056,2157223167,4294935449,2576980479,4294951833,2576991231,_
        4294935449,2575540127,4294951321,2579626489,4294935449,2678038527,4294951327,3287909375,_
        4293362151,3890737663,4294941081,2576990719,4294941081,2579752959,4294941844,2160183807,_
        4294941123,3888355839,4294941081,2579624839,4294935027,3889136127,3285176271,3486499839,_
        4092448643,3483173887,3287544819,4092838911,4293378945,3890735079,4293906304,2161111039,_
        4294967295,4294967295,3890735079,4294961151,2576980479,4294967295,2576941209,10066431,_
        3888226243,4186171391,2644112359,3482958335,3281634247,2560213247,4193511423,4294967295,_
        4092055503,3488084991,3488084979,4092055551,4288267008,3281649663,4293388161,3890741247,_
        4294967295,4293388239,4294967169,4294967295,4294967295,4293388287,4294769139,3889143807,_
        3281621385,2576991231,3890726887,3890708991,3281648115,3483337215,3281648099,4187603967,_
        4193378713,2163866111,2174714873,4187603967,3281624963,2576991231,2174350311,3890735103,_
        3281623491,2576991231,3281623489,4187603967,4294961151,4293394431,4294961151,4293388239,_
        4058501023,3488084479,4294935039,2181038079,2414343161,4092039167,3281648115,3892307967,_
        4294967040,16777215,3888355713,2576980479,2207881603,2576974847,3281624991,2677654527,_
        2274597273,2576582655,2174721927,2678030847,2174721927,2678038527,3281624977,2576991231,_
        2576980353,2576980479,3286755303,3890725887,3790861299,4086548479,2576582543,2274597375,_
        2678038431,2678030847,2626191508,2627509503,2575925633,2442762751,3281623449,2576991231,_
        2207881603,2678038527,3281623449,2579755519,2207881603,2274597375,3281625027,4187603967,_
        2179459047,3890735103,2576980377,2576991231,2576980377,2579752959,2627509396,2156436735,_
        2576991207,3281623551,2576980419,3890735103,2180641767,3483337215,3890734848,15198183,_
        1061146575,1061146575,3890735079,3890735079,3435934515,3435934515,3429249945,3429249945,_
        4294967295,4294967295,252645135,252645135,4294967295,0,16777215,4294967295,_
        4294967295,4294967040,1061109567,1061109567,859032780,859032780,4244438268,4244438268,_
        4294967295,859032780,862375065,862375065,4244438268,4244438268,3890735072,3773294567,_
        4294967295,4042322160,3890735072,3774873599,4294967047,132638695,4294967295,4294901760,_
        4294967264,3773294567,3890734848,16777215,4294967040,15198183,3890734855,132638695,_
        1061109567,1061109567,522133279,522133279,4177066232,4177066232,65535,4294967295,_
        255,4294967295,4294967295,4278190080,4277991827,2274336767,4294967295,252645135,_
        4042322160,4294967295,3890734855,134217727,252645135,4294967295,252645135,4042322160}
        fontLoad.style = DefaultLowerCase
        fontLoad.fontData = allocate(16384)
        If fontLoad.fontData = 0 Then throwErr("OUT OF MEMORY")
        For i = 97 to 122: fontLoad.ASCIImap(i)=i-96: Next i
        For i = 93 to 95: fontLoad.ASCIImap(i)=i-64: Next i
        For i = 32 to 63: fontLoad.ASCIImap(i)=i: Next i
        For i = 65 to 90: fontLoad.ASCIImap(i)=i: Next i
        For i = 123 to 127: fontLoad.ASCIImap(i)=i-32: Next i
        For i = 0 to 31: fontLoad.ASCIImap(i)=i+96: Next i
        fontLoad.ASCIImap(91)=28
        fontLoad.ASCIImap(156)=29
        fontLoad.ASCIImap(22)=65
        For i = 128 to 255: fontLoad.ASCIImap(i)=FontLoad.ASCIImap(i)+128: Next i
        For i = 0 to 511 step 2
            uLower = DefaultLowerCase_packed(i)
            uUpper = DefaultLowerCase_packed(i+1)
            For q =  0 to 31: fontLoad.fontData[o+q] = ((uLower shr (31-q)) And 1) * &HFF: Next q
            For q = 32 to 63: fontLoad.fontData[o+q] = ((uUpper shr (63-q)) And 1) * &HFF: Next q
            o += 64
        Next i
    Case else
        throwErr("INVALID FONT IDENTIFIER")
    End select
    return true
end function
Function C64.unloadFont(fontUnload as fontSpace) as bool
    if fontUnload.fontData = 0 Then throwErr("BAD FONT SPACE")
    Deallocate fontUnload.fontData
    return true
end function
function C64.TEXT(sDat as screenSpace, x as integer, y as integer, textS as string, font as fontSpace, col as integer=1) as bool
    
    'temporary, must add clipping support     
    If x < 0 or x > 159-Len(textS)*8+1 Then throwErr("INVALID X COORDINATE")
    If y < 0 or y > 191 Then throwErr("INVALID Y COORDINATE")
    
    
    If col < 0 orElse col > 15 Then throwErr("INVALID PALETTE COLOR")
    If sDat.screenData=0 orElse sDat.palletteData=0 Then throwErr("BAD SCREEN SPACE")
    If font.fontData=0 then throwErr("BAD FONT SPACE")
    If textS="" then return true
    Dim as integer i
    Dim as ubyte ptr sO, cO
    sO = @sDat.screenData[y*160+x]
    dim as uinteger col4 = col
    col4 = col4 or (col4 shl 8) or (col4 shl 16) or (col4 shl 24)
    For i = 1 to Len(textS)
        cO = @font.fontData[font.ASCIImap(ASC(MID$(textS,i,1)))*64]
        asm
            mov eax, [col4]
            movd mm0, eax
            punpckldq mm0, mm0
            mov eax, &HFFFFFFFF
            movd mm1, eax
            punpckldq mm1, mm1
            mov eax, [cO]
            mov ebx, [sO]
            mov ecx, 8
            C64Draw_BI_TEXT_CharCopyLoop:
            movq mm2, [eax] 
            movq mm3, mm2   
            pxor mm3, mm1 
            movq mm4, [ebx]
            pand mm4, mm3
            movq [ebx], mm4
            pand mm2, mm0 
            movq mm4, [ebx]
            por mm4, mm2 
            movq [ebx], mm4
            add eax, 8 
            add ebx, 160  
            dec ecx
            jnz C64Draw_BI_TEXT_CharCopyLoop
            emms
        end asm
        sO = @sO[8]
    Next i
    return true
end function
Function C64.imageClip(px as integer, py as integer ,_
                    sx as integer, sy as integer ,_
                    byref npx  as integer, byref npy  as integer ,_
                    byref sdx1 as integer, byref sdy1 as integer ,_
                    byref sdx2 as integer, byref sdy2 as integer) as integer
    Dim as integer px1,py1,px2,py2,SW,SH
    dim as integer bbx1, bbx2, bby1, bby2
    SW = 160
    SH = 200
    px1 = px       : py1 = py
    px2 = px+sx - 1: py2 = py+sy - 1
    If px2 <  0  Then Return 0
    If px1 >= sw Then Return 0
    If py2 <  0  Then Return 0
    If py1 >= sh Then Return 0
    
    bbx1 = iif(px1 <   0, 0     , px1)
    bby1 = iif(py1 <   0, 0     , py1)
    bbx2 = iif(px2 >= SW, SW - 1, px2)
    bby2 = iif(py2 >= SH, SH - 1, py2)
    
    npx  = bbx1
    npy  = bby1
    sdx1 = bbx1 - px1
    sdy1 = bby1 - py1
    sdx2 = sx - (px2 - bbx2) - 1
    sdy2 = sy - (py2 - bby2) - 1

    Return 1
End Function
sub C64.drawImage(sDat as screenSpace, x as integer, y as integer,_
              im as image, x0 as integer, y0 as integer,_
              x1 as integer, y1 as integer, method as string, _
              shiftspd as double = 0, shiftamp as double = 0, shiftfreq as double = 0)
    dim as integer locX, locY, col
    dim as integer sx, sy, ex, ey, nx, ny, tx, ttx
    dim as integer xscan, yscan
    dim as integer offsetSrc, offsetDest, destShift, srcShift, src, dest
    dim as double  shift, t
            
    if imageClip(x, y, (x1 - x0) + 1, (y1 - y0) + 1, locX, locY, sx, sy, ex, ey) = 1 then
        sx += x0
        sy += y0
        ex += x0
        ey += y0
        method = ucase(method)
        offsetDest = locX + locY * 160
        offsetSrc = sx + sy * im.sizeX
        destShift = 160
        srcShift  = im.sizeX
        t = timer
        if method = "PSET" then
            for yscan = sy to ey
                shift = shiftamp*(sin((yscan*shiftfreq+t*shiftspd)*0.1))
                tx = sx - shift
                ttx = ex - shift
                if tx < 0 then tx = 0
                if ttx > 159 then ttx = 159
                for xscan = tx to ttx
                    nx = locX + xscan + shift
                    ny = locY + yscan     
                    col = im.pixels[yscan*srcShift + xscan]
                    if col <> 0 then sDat.screenData[ny*160 + nx] = col
                next xscan
            next yscan
        elseif method = "OR" then
            for yscan = sy to ey
                src  = offsetSrc
                dest = offsetDest
                for xscan = sx to ex
                    sDat.screenData[dest] or= im.pixels[src]
                    src  += 1
                    dest += 1
                next xscan
                offsetSrc  += srcShift
                offsetDest += destShift
            next yscan    
        elseif method = "AND" then
            for yscan = sy to ey
                src  = offsetSrc
                dest = offsetDest
                for xscan = sx to ex
                    sDat.screenData[dest] and= im.pixels[src]
                    src  += 1
                    dest += 1
                next xscan
                offsetSrc  += srcShift
                offsetDest += destShift
            next yscan  
        elseif method = "TRANS" then 
            for yscan = sy to ey
                src  = offsetSrc
                dest = offsetDest
                for xscan = sx to ex
                    if im.pixels[src] <> 0 then sDat.screenData[dest] = im.pixels[src] 
                    src  += 1
                    dest += 1
                next xscan
                offsetSrc  += srcShift
                offsetDest += destShift
            next yscan 
        end if
    end if
end sub




