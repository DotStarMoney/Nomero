#ifndef C64DRAW_BI
#define C64DRAW_BI

#include "vector2D.bi"

#define throwErr(x) errorThrown=errorThrown+x+"|":return false
namespace C64
    type bool as ubyte
    type screenPallette as uinteger ptr
    const false as bool = 0
    const true as bool = NOT false
    Enum FontStyle
        DefaultUpperCase
        DefaultLowerCase
        AlternateReality
        SevenUp
        ArenaB
    End Enum
    type image 
        as byte ptr pixels    
        as integer  sizeX
        as integer  sizeY
    end type
    type fontSpace
        as ubyte ptr fontData
        as integer ASCIImap(255)
        as FontStyle style
    end type
    Dim shared as string errorThrown
    type screenSpace
        as ubyte ptr screenData
        as uinteger ptr palletteData
    End type
    declare sub clearError()

    declare function loadImage(scnspace as screenSpace, filename as string) as image

    declare sub deleteImage(im as image)
 
    declare Function loadStandardPallette(byref pallette as screenPallette) as bool

    declare Function loadCustomPallette(byref pallette as screenPallette, cPal() as uinteger) as bool

    declare Function unloadPallette(byref pallette as screenPallette) as bool
   
    declare Function loadScreenSpace(byref sDat as screenSpace, pallette as screenPallette) as bool

    declare Function unloadScreenSpace(byref sDat as screenSpace) as bool

    declare function drawScreen(dstbuffer as integer ptr, x as integer, y as integer, sDat as screenSpace) as bool

    declare function copyScreen(s1 as screenSpace, s2 as screenSpace) as ubyte

    declare function clearScreen(sDat as screenSpace, col as ubyte = 0) as ubyte

    declare function PIXEL(sDat as screenSpace, x as ubyte, y as ubyte, col as ubyte) as bool

    declare function loadFont(fontLoad as fontSpace, identifier as FontStyle) as bool

    declare Function unloadFont(fontUnload as fontSpace) as bool

    declare function TEXT(sDat as screenSpace, x as integer, y as integer, textS as string, font as fontSpace, col as integer=1) as bool

    declare Function imageClip(px as integer, py as integer ,_
                        sx as integer, sy as integer ,_
                        byref npx  as integer, byref npy  as integer ,_
                        byref sdx1 as integer, byref sdy1 as integer ,_
                        byref sdx2 as integer, byref sdy2 as integer) as integer
 
    declare sub drawImage(sDat as screenSpace, x as integer, y as integer,_
                  im as image, x0 as integer, y0 as integer,_
                  x1 as integer, y1 as integer, method as string, _
                  shiftspd as double = 0, shiftamp as double = 0, shiftfreq as double = 0)
        
End namespace
Dim shared as C64.screenPallette C64_standardPallette
Dim shared as C64.fontSpace C64_standardFont
Dim shared as C64.screenSpace C64_standardScreen
#endif

