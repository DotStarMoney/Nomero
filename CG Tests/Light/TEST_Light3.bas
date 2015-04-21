
Const RR2 As Double = Sqr(2)^-1

Sub CastLight(dest as integer ptr, source As Integer Ptr, xp As Integer, yp As Integer,_
              rad As Double, col As Integer = &HFF400000, tcol As Integer = &HFF000000)
              
    #macro _setaddr(dest, src)
        asm mov eax, offset src
        asm mov [dest], eax
    #endmacro
    #define _gosub(addr) asm Call [addr]
    #define _return asm ret

    #define _Ek 0
    #define _Dn 1
    #define _Dp 2
    #define _Xd 3
    #define _Ub 4
    #define _Xx 5
    
    #define MAX_PAIRS 128

    #define ShadowsA(_I_, _P_) readList[(_I_)*6 + _P_]
    #define ShadowsB(_I_, _P_) writeList[(_I_)*6 + _P_]

    #macro _addelement(a)
        ShadowsB(_N,_Xx) = a: ShadowsB(_N,_Xd) = Sgn(dx)
        dx = Abs(dx): dy = Abs(dy)
        ShadowsB(_N,_Ek) = dx SHL 1 - dy
        ShadowsB(_N,_Dn) = ShadowsB(_N,_Ek) + dy
        ShadowsB(_N,_Dp) = ShadowsB(_N,_Ek) - dy
        ShadowsB(_N,_Ub) = 1
        _N += 1
    #endmacro
    
    #macro _copyelement(x)
        ShadowsB(_N,_Ek) = ShadowsA(x,_Ek)
        ShadowsB(_N,_Dn) = ShadowsA(x,_Dn)
        ShadowsB(_N,_Dp) = ShadowsA(x,_Dp)
        ShadowsB(_N,_Xx) = ShadowsA(x,_Xx)
        ShadowsB(_N,_Xd) = ShadowsA(x,_Xd)
        ShadowsB(_N,_Ub) = ShadowsA(x,_Ub)
        _N += 1
    #endmacro
    
    #macro _copylist()
        swap readList, writeList
    #endmacro
        
    dim as integer ptr readList, writeList, Sptr
    Dim As Integer inc, scan, xs, xe, yend = rad*RR2, xcirc, dx, dy, s1, s2, prad, oxs, oxe, txe
    Dim As Integer xpos, ypos, segs, i, _N, ccol, LeftBnd, RightBnd, Offset, yadd,q
    Dim As Any Ptr FillLoop, SearchLoop, Proc
    Dim As Integer QuadBnd(0 To 7, 0 To 4), WorkCol, destW, destH, destStride
    
    imageinfo dest, destW, destH,, destStride, Sptr 
    destStride shr= 2
    
    readList  = new integer[MAX_PAIRS*2]
    writeList = new integer[MAX_PAIRS*2]
    
    QuadBnd(0,_Ek) = 1: QuadBnd(0,_Dn) = 2: QuadBnd(0,_Dp) = 0: QuadBnd(0,_Xd) = -1: QuadBnd(0,_Ub) = 0
    QuadBnd(1,_Ek) = 1: QuadBnd(1,_Dn) = 2: QuadBnd(1,_Dp) = 0: QuadBnd(1,_Xd) =  1: QuadBnd(1,_Ub) = 0
    QuadBnd(2,_Ek) = 1: QuadBnd(2,_Dn) = 2: QuadBnd(2,_Dp) = 0: QuadBnd(2,_Xd) = -1: QuadBnd(2,_Ub) = 0
    QuadBnd(3,_Ek) = 1: QuadBnd(3,_Dn) = 2: QuadBnd(3,_Dp) = 0: QuadBnd(3,_Xd) =  1: QuadBnd(3,_Ub) = 0
    QuadBnd(4,_Ek) = 1: QuadBnd(4,_Dn) = 2: QuadBnd(4,_Dp) = 0: QuadBnd(4,_Xd) =  1: QuadBnd(4,_Ub) = 0
    QuadBnd(5,_Ek) = 1: QuadBnd(5,_Dn) = 2: QuadBnd(5,_Dp) = 0: QuadBnd(5,_Xd) = -1: QuadBnd(5,_Ub) = 0
    QuadBnd(6,_Ek) = 1: QuadBnd(6,_Dn) = 2: QuadBnd(6,_Dp) = 0: QuadBnd(6,_Xd) =  1: QuadBnd(6,_Ub) = 0
    QuadBnd(7,_Ek) = 1: QuadBnd(7,_Dn) = 2: QuadBnd(7,_Dp) = 0: QuadBnd(7,_Xd) = -1: QuadBnd(7,_Ub) = 0
    prad = rad-yend
    Dim as integer CurveOff(0 to prad-1), cind
    dx = 0
    dy = Rad
    xs = 1 - Rad
    i = prad
    Do
        If xs < 0 Then
            xs += dx SHL 1 + 3
        Else
            xs += (dx - dy) SHL 1 + 5
            CurveOff(i - 1) = dx
            dy -= 1
            i -= 1
        End If
        dx += 1
    Loop Until i = 0
    '-------------------------------------------------QUAD 1---------------------------------------
    
        _setaddr(FillLoop, FillQ1)
        _setaddr(SearchLoop, SearchQ1)
    
        ShadowsA(0,_Ek) = QuadBnd(0,_Ek): ShadowsA(0,_Dn) = QuadBnd(0,_Dn): ShadowsA(0,_Dp) = QuadBnd(0,_Dp)
        ShadowsA(0,_Xx) = xp: ShadowsA(0,_Xd) = QuadBnd(0,_Xd): ShadowsA(0,_Ub) = QuadBnd(0,_Ub)
        ShadowsA(1,_Ek) = QuadBnd(1,_Ek): ShadowsA(1,_Dn) = QuadBnd(1,_Dn): ShadowsA(1,_Dp) = QuadBnd(1,_Dp)
        ShadowsA(1,_Xx) = xp: ShadowsA(1,_Xd) = QuadBnd(1,_Xd): ShadowsA(1,_Ub) = QuadBnd(1,_Ub)
        _N = 2
        yadd = yp * destStride
        If yp - rad < 0 Then 
            prad = yp 
        Else
            prad = rad
        Endif
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc - yend - 1
                RightBnd = xp + CurveOff(xcirc)
                LeftBnd  = xp - CurveOff(xcirc)
            Else
                RightBnd = xp + inc - 1
                LeftBnd  = xp - inc
            Endif
            If RightBnd >= destW Then RightBnd = destW-1
            If LeftBnd  <  0     Then LeftBnd  = 0
            ypos = yp - inc
            yadd -= destStride
            segs = _N
            _N = 0
            For i = 0 To segs-1 Step 2
                s1 = i
                oxs = ShadowsA(s1,_Xx)
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
                s2 = i + 1
                oxe = ShadowsA(s2,_Xx)
                If ShadowsA(s2,_Ek) < 0 Then
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dn)
                Else
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dp)
                    ShadowsA(s2,_Xx) += ShadowsA(s2,_Xd)
                End If
                xs = ShadowsA(s1,_Xx)
                xe = ShadowsA(s2,_Xx)
                
                If xe < LeftBnd Then 
                    Goto SkipScanQ1
                Elseif xs > RightBnd Then
                    Goto SkipScanQ1
                Elseif xs < LeftBnd Then
                    xs = LeftBnd
                Endif
                txe = xe
                If xe > RightBnd Then xe = RightBnd
                        
                If (xs - oxs) < 0 then
                    if (Sptr[yadd+xs+1] <> tcol) andAlso (Sptr[yadd+xs+destStride] <> tcol) then
                        xs += 1
                    end if
                end if
                If (txe - oxe) > 0 then
                    if (Sptr[yadd+xe-1] <> tcol) andAlso (Sptr[yadd+xe+destStride] <> tcol) then
                        xe -= 1
                    end if
                end if

                
                
                xpos = xs
                If Sptr[yadd+xpos] <> tcol Then
                    Do
                        xpos += 1
                        If xpos >= xe Then Goto SkipScanQ1
                        ccol = Sptr[yadd+xpos]
                        If ccol = tcol Or ccol = -1 Then
                            If xpos < xe Then
                                dx = xpos-xp: dy = inc
                                _addelement(xpos)
                            Else
                                Sptr[yadd+xpos] = col
                            Endif
                            Exit Do
                        Endif
                    Loop
                Else
                    _copyelement(s1)
                Endif
                
                'Sptr[yadd+xpos] = col
                Proc = FillLoop
                
                Do
                    xpos += 1
                    If xpos > xe Then Exit Do
                    _gosub(Proc)
                Loop
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                Endif
                SkipScanQ1:    
                
                
            Next i
            If _N = 0 Then Exit For
            _copylist()
        Next inc
 
    '----------------------------------------------------QUAD 2------------------------------------
    
    
        _setaddr(FillLoop, FillQ2)
        _setaddr(SearchLoop, SearchQ2)
    
        ShadowsA(0,_Ek) = QuadBnd(2,_Ek): ShadowsA(0,_Dn) = QuadBnd(2,_Dn): ShadowsA(0,_Dp) = QuadBnd(2,_Dp)
        ShadowsA(0,_Xx) = yp: ShadowsA(0,_Xd) = QuadBnd(2,_Xd): ShadowsA(0,_Ub) = QuadBnd(2,_Ub)
        ShadowsA(1,_Ek) = QuadBnd(3,_Ek): ShadowsA(1,_Dn) = QuadBnd(3,_Dn): ShadowsA(1,_Dp) = QuadBnd(3,_Dp)
        ShadowsA(1,_Xx) = yp: ShadowsA(1,_Xd) = QuadBnd(3,_Xd): ShadowsA(1,_Ub) = QuadBnd(3,_Ub)
        _N = 2
        If xp + rad >= destW Then
            prad = destW-xp-1
        Else
            prad = rad
        Endif
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc - yend - 1
                RightBnd = yp + CurveOff(xcirc)
                LeftBnd  = yp - CurveOff(xcirc)
            Else
                RightBnd = yp + inc - 1
                LeftBnd  = yp - inc
            Endif
            If RightBnd >= destH Then RightBnd = destH-1
            If LeftBnd  <  0     Then LeftBnd  = 0
            xpos = xp + inc
            segs = _N
            _N = 0
            For i = 0 To segs-1 Step 2
                s1 = i
                oxs = ShadowsA(s1,_Xx)
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
                s2 = i + 1
                oxe = ShadowsA(s2,_Xx)
                If ShadowsA(s2,_Ek) < 0 Then
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dn)
                Else
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dp)
                    ShadowsA(s2,_Xx) += ShadowsA(s2,_Xd)
                End If
                
                xs = ShadowsA(s1,_Xx)
                xe = ShadowsA(s2,_Xx)
                
                If xe < LeftBnd Then 
                    Goto SkipScanQ2
                Elseif xs > RightBnd Then
                    Goto SkipScanQ2
                Elseif xs < LeftBnd Then
                    xs = LeftBnd
                Endif
                txe = xe
                If xe > RightBnd Then xe = RightBnd
                
                /'
                If (xs - oxs) < 0 then
                    if (Sptr[yadd+xs+destStride] <> tcol) andAlso (Sptr[yadd+xs-1] <> tcol) then
                        xs += 1
                    end if
                end if
                If (txe - oxe) > 0 then
                    if (Sptr[yadd+xe-destStride] <> tcol) andAlso (Sptr[yadd+xe-1] <> tcol) then
                        xe -= 1
                    end if
                end if
                '/
                
                ypos = xs
                yadd = xs * destStride
                If Sptr[yadd+xpos] <> tcol Then
                    Do
                        ypos += 1
                        If ypos >= xe Then Goto SkipScanQ2
                        yadd += destStride
                        ccol = Sptr[yadd+xpos]
                        If ccol = tcol Or ccol = -1 Then
                            If ypos < xe Then
                                dx = ypos-yp: dy = inc
                                _addelement(ypos)
                            Else
                                Sptr[yadd+xpos] = col
                            Endif
                            Exit Do
                        Endif
                    Loop
                Else
                    _copyelement(s1)
                Endif

                'Sptr[yadd+xpos] = col
                
                Proc = FillLoop
                Do
                    ypos += 1
                    yadd += destStride
                    If ypos > xe Then Exit Do
                    _gosub(Proc)
                Loop
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                Endif
                
                SkipScanQ2:
            Next i
            If _N = 0 Then Exit For
            _copylist()
        Next inc
/'

    '------------------------------------------------QUAD 3---------------------------------------
     
 
        Redim As Integer ShadowsA(1 To 2, 1 To 6), ShadowsB(1 To 1, 1 To 6)
      
        _setaddr(FillLoop, FillQ3)
        _setaddr(SearchLoop, SearchQ3)

        ShadowsA(1,_Ek) = QuadBnd(5,_Ek): ShadowsA(1,_Dn) = QuadBnd(5,_Dn): ShadowsA(1,_Dp) = QuadBnd(5,_Dp)
        ShadowsA(1,_Xx) = xp: ShadowsA(1,_Xd) = QuadBnd(5,_Xd): ShadowsA(1,_Ub) = QuadBnd(5,_Ub)
        ShadowsA(2,_Ek) = QuadBnd(6,_Ek): ShadowsA(2,_Dn) = QuadBnd(6,_Dn): ShadowsA(2,_Dp) = QuadBnd(6,_Dp)
        ShadowsA(2,_Xx) = xp: ShadowsA(2,_Xd) = QuadBnd(6,_Xd): ShadowsA(2,_Ub) = QuadBnd(6,_Ub)
        yadd = yp * SCRX
        If yp + rad > SCRY Then
            prad = SCRY - yp
        Else
            prad = rad
        Endif
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc - yend
                RightBnd = xp + CurveOff(xcirc)
                LeftBnd  = xp - CurveOff(xcirc)
            Else
                RightBnd = xp + inc
                LeftBnd  = xp - inc + 1
            Endif
            If RightBnd >= SCRX Then RightBnd = SCRX - 1
            If LeftBnd  <  0    Then LeftBnd  = 0
            ypos = yp + inc
            yadd += SCRX
            segs = Ubound(ShadowsA)
            _N = 0
            For i = 1 To segs Step 2
                s1 = i
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
                s2 = i + 1
                If ShadowsA(s2,_Ek) < 0 Then
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dn)
                Else
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dp)
                    ShadowsA(s2,_Xx) += ShadowsA(s2,_Xd)
                End If
                xs = ShadowsA(s1,_Xx): xe = ShadowsA(s2,_Xx)
                If xe > RightBnd Then 
                    Goto SkipScanQ3
                Elseif xs < LeftBnd Then
                    Goto SkipScanQ3
                Elseif xs > RightBnd Then
                    xs = RightBnd
                Endif
                If xe < LeftBnd Then xe = LeftBnd
                xpos = xs
                If Sptr[yadd+xpos] <> tcol Then
                    Do
                        xpos -= 1
                        If xpos <= xe Then Goto SkipScanQ3
                        ccol = Sptr[yadd+xpos]
                        If ccol = tcol Or ccol = -1 Then
                            If xpos > xe Then
                                dx = xpos-xp: dy = inc
                                _addelement(xpos)
                            Else
                                Sptr[yadd+xpos] = col
                            Endif
                            Exit Do
                        Endif
                    Loop
                Else
                    _copyelement(s1)
                Endif
                Sptr[yadd+xpos] = col
                Proc = FillLoop
                Do
                    xpos -= 1
                    If xpos < xe Then Exit Do
                    _gosub(Proc)
                Loop
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                Endif
                SkipScanQ3:
            Next i
            If _N = 0 Then Exit For
            Redim Preserve As Integer ShadowsA(1 To _N, 1 To 6)
            _copylist()
            Redim As Integer ShadowsB(1 To 1, 1 To 6)
        Next inc

    '------------------------------------------------QUAD 4---------------------------------------
 

        Redim As Integer ShadowsA(1 To 2, 1 To 6), ShadowsB(1 To 1, 1 To 6)
        
        _setaddr(FillLoop, FillQ4)
        _setaddr(SearchLoop, SearchQ4)
        
        ShadowsA(1,_Ek) = QuadBnd(7,_Ek): ShadowsA(1,_Dn) = QuadBnd(7,_Dn): ShadowsA(1,_Dp) = QuadBnd(7,_Dp)
        ShadowsA(1,_Xx) = yp: ShadowsA(1,_Xd) = QuadBnd(7,_Xd): ShadowsA(1,_Ub) = QuadBnd(7,_Ub)
        ShadowsA(2,_Ek) = QuadBnd(8,_Ek): ShadowsA(2,_Dn) = QuadBnd(8,_Dn): ShadowsA(2,_Dp) = QuadBnd(8,_Dp)
        ShadowsA(2,_Xx) = yp: ShadowsA(2,_Xd) = QuadBnd(8,_Xd): ShadowsA(2,_Ub) = QuadBnd(8,_Ub)
        If xp - rad < 0 Then
            prad = xp
        Else
            prad = rad
        Endif
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc-yend
                RightBnd = yp + CurveOff(xcirc)
                LeftBnd  = yp - CurveOff(xcirc)
            Else
                RightBnd = yp + inc
                LeftBnd  = yp - inc + 1
            Endif
            If RightBnd >= SCRY Then RightBnd = SCRY-1
            If LeftBnd  <  0    Then LeftBnd  = 0
            xpos = xp - inc
            segs = Ubound(ShadowsA)
            _N = 0
            For i = 1 To segs Step 2
                s1 = i
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
                s2 = i + 1
                If ShadowsA(s2,_Ek) < 0 Then
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dn)
                Else
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dp)
                    ShadowsA(s2,_Xx) += ShadowsA(s2,_Xd)
                End If
                xs = ShadowsA(s1,_Xx): xe = ShadowsA(s2,_Xx)
                If xe > RightBnd Then 
                    Goto SkipScanQ4
                Elseif xs < LeftBnd Then
                    Goto SkipScanQ4
                Elseif xs > RightBnd Then
                    xs = RightBnd
                Endif
                If xe < LeftBnd Then xe = LeftBnd
                ypos = xs
                yadd = xs * SCRX
                If Sptr[yadd+xpos] <> tcol Then
                    Do
                        ypos -= 1
                        If ypos <= xe Then Goto SkipScanQ4
                        yadd -= SCRX
                        ccol = Sptr[yadd+xpos]
                        If ccol = tcol Or ccol = -1 Then
                            If ypos > xe Then
                                dx = ypos-yp: dy = inc
                                _addelement(ypos)
                            Else
                                Sptr[yadd+xpos] = col
                            Endif
                            Exit Do
                        Endif
                    Loop
                Else
                    _copyelement(s1)
                Endif
                Sptr[yadd+xpos] = col
                Proc = FillLoop
                Do
                    ypos -= 1
                    yadd -= SCRX
                    If ypos < xe Then Exit Do
                    _gosub(Proc)
                Loop 
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                Endif
                SkipScanQ4:
            Next i
            If _N = 0 Then Exit For
            Redim Preserve As Integer ShadowsA(1 To _N, 1 To 6)
            _copylist()
            Redim As Integer ShadowsB(1 To 1, 1 To 6)
        Next inc
   '/
   
    delete(readList)
    delete(writeList)
    
    Exit Sub
    
    '======================================FILLING LOOPS======================================
    
    asm FillQ1:
        If Sptr[yadd+xpos] <> tcol Then
            dx = xpos-xp-1: dy = inc
            _addelement(xpos-1)
            Proc = SearchLoop
        Else
            Sptr[yadd+xpos] = col
        Endif
    _return
    
    asm SearchQ1:
        If Sptr[yadd+xpos] = tcol Then
            dx = xpos-xp: dy = inc 
            _addelement(xpos)
            Proc = FillLoop
            Sptr[yadd+xpos] = Col
        Endif
    _return
    
    asm FillQ2:
        If Sptr[yadd+xpos] <> tcol Then
            dx = ypos-yp-1: dy = inc
            _addelement(ypos-1)
            Proc = SearchLoop
        Else
            Sptr[yadd+xpos] = Col
        Endif
    _return
    
    asm SearchQ2:
        If Sptr[yadd+xpos] = tcol Then
            dx = ypos-yp: dy = inc
            _addelement(ypos)
            Proc = FillLoop
            Sptr[yadd+xpos] = Col
        Endif
    _return
    
    asm FillQ3:
        If Sptr[yadd+xpos] <> tcol Then
            dx = xpos-xp+1: dy = inc
            _addelement(xpos+1)
            Proc = SearchLoop
        Else
            Sptr[yadd+xpos] = Col
        Endif
    _return
    
    asm SearchQ3:
        If Sptr[yadd+xpos] = tcol Then
            dx = xpos-xp: dy = inc 
            _addelement(xpos)
            Proc = FillLoop
            Sptr[yadd+xpos] = Col
        Endif
    _return
    
    asm FillQ4:
        If Sptr[yadd+xpos] <> tcol Then
            dx = ypos-yp+1: dy = inc
            _addelement(ypos+1)
            Proc = SearchLoop
        Else
            Sptr[yadd+xpos] = Col
        Endif
    _return
    
    asm SearchQ4:
        If Sptr[yadd+xpos] = tcol Then
            dx = ypos-yp: dy = inc
            _addelement(ypos)
            Proc = FillLoop
            Sptr[yadd+xpos] = Col
        Endif
    _return
    
End Sub


screenres 640,480,32
setmouse ,,0
Dim As Integer Ptr Img, Img2
Dim As Integer mx, my, f, fps
Img = ImageCreate(640,480,&HFF000000)
Img2 = ImageCreate(640,480,&HFF000000)
'Bload "ShadowTest2.bmp", Img
randomize timer
For mx = 1 to 10
    Circle Img2,(rnd*640,rnd*480),rnd*100, &h0000ff
Next mx
Line Img2,(10,10)-(300,300)
Dim as double T = TIMER
Do  
    'ScreenLock
    getmouse mx,my
    If mx = -1 Then 
        mx = 320
        my = 240
    Endif
    Locate 1,1: Print mx, my
    
    Put Img, (0,0), Img2, Pset
    
    mx = 320: my = 240
    CastLight Img,0,mx,my,300
    
    put (0,0), Img, Pset
    
    Locate 2,1: Print fps
    f += 1
    If TIMER-T > 1 Then 
        fps = f
        f = 0
        T = Timer
    Endif
Loop Until multikey(1)
ImageDestroy Img
End

 