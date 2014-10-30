#define SCRX 800
#define SCRY 600
 
SUB triangle_scanline(dest as integer ptr = 0, BYVAL X1 AS INTEGER , BYVAL Y1 AS INTEGER, BYVAL X2 AS INTEGER , BYVAL Y2 AS INTEGER , BYVAL X3 AS INTEGER, BYVAL Y3 AS INTEGER , BYVAL TC AS INTEGER)

DIM AS INTEGER TEMPX,TEMPY,LO,LI
                DIM AS INTEGER PX(3)
                DIM AS INTEGER PY(3)
                DIM TFLAG AS INTEGER
                dim pp as uinteger PTR
                dim dstPxls as uinteger ptr
                dim dst_w as integer
                dim dst_h as integer
                DIM AS INTEGER IL1,IL2,SLICE
                
        if dest = 0 then
            screeninfo dst_w, dst_h
            dstPxls = screenptr
        else
            imageinfo dest, dst_w, dst_h,,,dstPxls
        end if
                
                TFLAG=0
        PX(1)= X1
        PX(2)= X2
        PX(3)= X3
       
        PY(1)= Y1
        PY(2)= Y2
        PY(3)= Y3
FOR LO = 1 TO 2
    FOR LI =1 TO 2     
        IF PY(LI+1) <= PY(LI) THEN
        TEMPX = PX(LI) : TEMPY = PY(LI)
        PX(LI) = PX(LI+1)
        PY(LI) = PY(LI+1)
        PX(LI+1) = TEMPX
        PY(LI+1) = TEMPY
        END IF   
    NEXT LI
NEXT LO

        DIM AS DOUBLE XP1,XP2:' SCREEN POSITIONS.
        DIM AS DOUBLE XI1,XI2:' INTERPOLATIONS.
       
'***
'*** REGULAR TRIANGLE (Y1<Y2 Y2<Y3)
'***

IF PY(1)<PY(2) AND PY(2)<PY(3) or (PY(2) = PY(3)) THEN
    TFLAG=1
XP1 = PX(1)
XP2 = PX(1)
XI1 = (PX(1)-PX(2)) / (PY(2) - PY(1))
XI2 = (PX(1)-PX(3)) / (PY(3) - PY(1))

FOR LO = PY(1) TO PY(2)-1
   
IF LO>=0 AND LO<dst_h THEN

    IF XP1<=XP2 THEN
        IL1=XP1
        IL2=XP2
    ELSE
        IL1=XP2
        IL2=XP1
    END IF
   
    IF IL2>dst_w THEN IL2=dst_w
    IF IL1<0 THEN IL1=0

    SLICE = IL2-IL1
    IF SLICE>0 THEN
    PP = @dstPxls[IL1 + dst_w * LO]
    asm
        mov eax,dword ptr[TC]
        mov ecx, [slice]
        mov edi, [PP]
        rep stosd
    end asm   
    END IF
   

END IF

XP1=XP1-XI1
XP2=XP2-XI2
NEXT

XI1 = (PX(2)-PX(3)) / (PY(3) - PY(2))
XP1 = PX(2)

FOR LO = PY(2) TO PY(3)
IF LO>=0 AND LO<dst_h THEN
    IF XP1<=XP2 THEN
        IL1=XP1
        IL2=XP2
    ELSE
        IL1=XP2
        IL2=XP1
    END IF

    IF IL2>dst_w THEN IL2=dst_w
    IF IL1<0 THEN IL1=0

    SLICE = IL2-IL1
    IF SLICE>0 THEN
    PP = @dstPxls[IL1 + dst_w * LO]
    asm
        mov eax,dword ptr[TC]
        mov ecx, [slice]
        mov edi, [PP]
        rep stosd
    end asm   
    END IF
END IF
XP1=XP1-XI1
XP2=XP2-XI2
NEXT

END IF


'***
'*** FLAT TOPPED TRIANGLE Y1=Y2
'***

IF TFLAG=0 AND PY(1) = PY(2) THEN
   
        TFLAG=1
        XP1 = PX(1)
        XP2 = PX(2)
        XI1 = (PX(1)-PX(3)) / (PY(3) - PY(1))
        XI2 = (PX(2)-PX(3)) / (PY(3) - PY(2))
FOR LO = PY(1) TO PY(3)
IF LO>=0 AND LO<dst_h THEN
    IF XP1<=XP2 THEN
        IL1=XP1
        IL2=XP2
    ELSE
        IL1=XP2
        IL2=XP1
    END IF
   
    IF IL2>dst_w THEN IL2=dst_w
    IF IL1<0 THEN IL1=0
   
    SLICE = IL2-IL1
    IF SLICE>0 THEN
    PP = @dstPxls[IL1 + dst_w * LO]
    asm
        mov eax,dword ptr[TC]
        mov ecx, [slice]
        mov edi, [PP]
        rep stosd
    end asm   
    END IF
END IF
    XP1=XP1-XI1
    XP2=XP2-XI2

NEXT
END IF
END SUB

 
screenres SCRX, SCRY, 32, 2
screenset 1,0
dim as double gadd
dim as integer HALFX = SCRX * 0.5
dim as integer HALFY = SCRY * 0.5


DO
    cls
    
    screenlock
    GADD=GADD+.002
    triangle_scanline ,HALFX+500*SIN(GADD),HALFY+400*COS(GADD),HALFX+150*SIN(GADD*2),HALFY+200*COS(GADD*3),HALFX+300*SIN(GADD/2),HALFY+100*COS(GADD*5),&H88FF55
    GADD=GADD+10
    triangle_scanline ,HALFX+500*SIN(GADD),HALFY+400*COS(GADD),HALFX+150*SIN(GADD*2),HALFY+200*COS(GADD*3),HALFX+300*SIN(GADD/2),HALFY+100*COS(GADD*5),&HFF8855
    GADD=GADD-10
    screenunlock
    flip
    sleep 1
LOOP UNTIL INKEY$ = CHR$(27)

