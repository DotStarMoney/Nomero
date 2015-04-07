
Const RR2 As Double = Sqr(2)^-1
#define SCRX 640
#define SCRY 480


Sub CastLight(source As Integer Ptr, xp As Integer, yp As Integer,_
              rad As Double, col As Integer = &HFF400000, tcol As Integer = &HFF000000)
              
    #macro _setaddr(dest, src)
        asm mov eax, offset src
        asm mov [dest], eax
    #endmacro
    #define _gosub(addr) asm Call [addr]
    #define _return asm ret

    #define _Ek 1
    #define _Dn 2
    #define _Dp 3
    #define _Xd 4
    #define _Ub 5
    #define _Xx 6

    #macro _addelement(a)
        _N += 1
        Redim Preserve As Integer ShadowsB(1 To _N, 1 To 6)
        ShadowsB(_N,_Xx) = a: ShadowsB(_N,_Xd) = Sgn(dx)
        dx = Abs(dx): dy = Abs(dy)
        ShadowsB(_N,_Ek) = dx SHL 1 - dy
        ShadowsB(_N,_Dn) = ShadowsB(_N,_Ek) + dy
        ShadowsB(_N,_Dp) = ShadowsB(_N,_Ek) - dy
        ShadowsB(_N,_Ub) = 1
    #endmacro
    
    #macro _copyelement(x)
        _N += 1
        Redim Preserve As Integer ShadowsB(1 To _N, 1 To 6)
        ShadowsB(_N,_Ek) = ShadowsA(x,_Ek)
        ShadowsB(_N,_Dn) = ShadowsA(x,_Dn)
        ShadowsB(_N,_Dp) = ShadowsA(x,_Dp)
        ShadowsB(_N,_Xx) = ShadowsA(x,_Xx)
        ShadowsB(_N,_Xd) = ShadowsA(x,_Xd)
        ShadowsB(_N,_Ub) = ShadowsA(x,_Ub)
    #endmacro
    
    #macro _copylist()
        For i = 1 To _N
            ShadowsA(i,1)=ShadowsB(i,1)
            ShadowsA(i,2)=ShadowsB(i,2)
            ShadowsA(i,3)=ShadowsB(i,3)
            ShadowsA(i,4)=ShadowsB(i,4)
            ShadowsA(i,5)=ShadowsB(i,5)
            ShadowsA(i,6)=ShadowsB(i,6)
        Next i
    #endmacro
    

    Redim As Integer ShadowsA(1 To 2, 1 To 6), ShadowsB(1 To 1, 1 To 6)
    Dim As Integer inc, scan, xs, xe, yend = rad*RR2, xcirc, dx, dy, s1, s2, prad, oxs, oxe, txe
    Dim As Integer xpos, ypos, segs, i, _N, ccol, LeftBnd, RightBnd, Offset, yadd,q
    Dim As Any Ptr FillLoop, SearchLoop, Proc
    Dim As Integer QuadBnd(1 To 8, 1 To 5), WorkCol
    
    Dim As Uinteger Ptr Sptr = ScreenPtr                        

    QuadBnd(1,_Ek) = 1: QuadBnd(1,_Dn) = 2: QuadBnd(1,_Dp) = 0: QuadBnd(1,_Xd) = -1: QuadBnd(1,_Ub) = 0
    QuadBnd(2,_Ek) = 1: QuadBnd(2,_Dn) = 2: QuadBnd(2,_Dp) = 0: QuadBnd(2,_Xd) =  1: QuadBnd(2,_Ub) = 0
    QuadBnd(3,_Ek) = 1: QuadBnd(3,_Dn) = 2: QuadBnd(3,_Dp) = 0: QuadBnd(3,_Xd) = -1: QuadBnd(3,_Ub) = 0
    QuadBnd(4,_Ek) = 1: QuadBnd(4,_Dn) = 2: QuadBnd(4,_Dp) = 0: QuadBnd(4,_Xd) =  1: QuadBnd(4,_Ub) = 0
    QuadBnd(5,_Ek) = 1: QuadBnd(5,_Dn) = 2: QuadBnd(5,_Dp) = 0: QuadBnd(5,_Xd) =  1: QuadBnd(5,_Ub) = 0
    QuadBnd(6,_Ek) = 1: QuadBnd(6,_Dn) = 2: QuadBnd(6,_Dp) = 0: QuadBnd(6,_Xd) = -1: QuadBnd(6,_Ub) = 0
    QuadBnd(7,_Ek) = 1: QuadBnd(7,_Dn) = 2: QuadBnd(7,_Dp) = 0: QuadBnd(7,_Xd) =  1: QuadBnd(7,_Ub) = 0
    QuadBnd(8,_Ek) = 1: QuadBnd(8,_Dn) = 2: QuadBnd(8,_Dp) = 0: QuadBnd(8,_Xd) = -1: QuadBnd(8,_Ub) = 0
    prad = rad-yend
    Dim as integer CurveOff(1 to prad), cind
    dx = 0
    dy = Rad
    xs = 1 - Rad
    i = prad
    Do
        If xs < 0 Then
            xs += dx SHL 1 + 3
        Else
            xs += (dx - dy) SHL 1 + 5
            CurveOff(i) = dx
            dy -= 1
            i -= 1
        End If
        dx += 1
    Loop Until i = 0
    '-------------------------------------------------QUAD 1---------------------------------------
    
        _setaddr(FillLoop, FillQ1)
        _setaddr(SearchLoop, SearchQ1)
    
        ShadowsA(1,_Ek) = QuadBnd(1,_Ek): ShadowsA(1,_Dn) = QuadBnd(1,_Dn): ShadowsA(1,_Dp) = QuadBnd(1,_Dp)
        ShadowsA(1,_Xx) = xp: ShadowsA(1,_Xd) = QuadBnd(1,_Xd): ShadowsA(1,_Ub) = QuadBnd(1,_Ub)
        ShadowsA(2,_Ek) = QuadBnd(2,_Ek): ShadowsA(2,_Dn) = QuadBnd(2,_Dn): ShadowsA(2,_Dp) = QuadBnd(2,_Dp)
        ShadowsA(2,_Xx) = xp: ShadowsA(2,_Xd) = QuadBnd(2,_Xd): ShadowsA(2,_Ub) = QuadBnd(2,_Ub)
        yadd = yp * SCRX
        If yp - rad < 0 Then 
            prad = yp 
        Else
            prad = rad
        Endif
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc - yend
                RightBnd = xp + CurveOff(xcirc)
                LeftBnd  = xp - CurveOff(xcirc)
            Else
                RightBnd = xp + inc - 1
                LeftBnd  = xp - inc
            Endif
            If RightBnd >= SCRX Then RightBnd = SCRX-1
            If LeftBnd  <  0    Then LeftBnd  = 0
            ypos = yp - inc
            yadd -= SCRX
            segs = Ubound(ShadowsA)
            _N = 0
            For i = 1 To segs Step 2
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
                    if (Sptr[yadd+xs+1] <> tcol) andAlso (Sptr[yadd+xs+SCRX] <> tcol) then
                        xs += 1
                    end if
                end if
                If (txe - oxe) > 0 then
                    if (Sptr[yadd+xe-1] <> tcol) andAlso (Sptr[yadd+xe+SCRX] <> tcol) then
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
                
                Sptr[yadd+xpos] = col
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
            Redim Preserve As Integer ShadowsA(1 To _N, 1 To 6)
            _copylist()
            Redim As Integer ShadowsB(1 To 1, 1 To 6)
        Next inc
 /'   
 
    '----------------------------------------------------QUAD 2------------------------------------
    
        Redim As Integer ShadowsA(1 To 2, 1 To 6), ShadowsB(1 To 1, 1 To 6)
    
        _setaddr(FillLoop, FillQ2)
        _setaddr(SearchLoop, SearchQ2)
    
        ShadowsA(1,_Ek) = QuadBnd(3,_Ek): ShadowsA(1,_Dn) = QuadBnd(3,_Dn): ShadowsA(1,_Dp) = QuadBnd(3,_Dp)
        ShadowsA(1,_Xx) = yp: ShadowsA(1,_Xd) = QuadBnd(3,_Xd): ShadowsA(1,_Ub) = QuadBnd(3,_Ub)
        ShadowsA(2,_Ek) = QuadBnd(4,_Ek): ShadowsA(2,_Dn) = QuadBnd(4,_Dn): ShadowsA(2,_Dp) = QuadBnd(4,_Dp)
        ShadowsA(2,_Xx) = yp: ShadowsA(2,_Xd) = QuadBnd(4,_Xd): ShadowsA(2,_Ub) = QuadBnd(4,_Ub)
        
        If xp + rad >= SCRX Then
            prad = SCRX-xp-1
        Else
            prad = rad
        Endif
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc-yend
                RightBnd = yp + CurveOff(xcirc)
                LeftBnd  = yp - CurveOff(xcirc)
            Else
                RightBnd = yp + inc - 1
                LeftBnd  = yp - inc 
            Endif
            If RightBnd >= SCRY Then RightBnd = SCRY-1
            If LeftBnd  <  0    Then LeftBnd  = 0
            xpos = xp + inc
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
                
                xs = ShadowsA(s1,_Xx)
                xe = ShadowsA(s2,_Xx)
                
                If xe < LeftBnd Then 
                    Goto SkipScanQ2
                Elseif xs > RightBnd Then
                    Goto SkipScanQ2
                Elseif xs < LeftBnd Then
                    xs = LeftBnd
                Endif
                If xe > RightBnd Then xe = RightBnd
                ypos = xs
                yadd = xs * SCRX
                If Sptr[yadd+xpos] <> tcol Then
                    Do
                        ypos += 1
                        If ypos >= xe Then Goto SkipScanQ2
                        yadd += SCRX
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
                Pset (xpos, ypos), col
                Proc = FillLoop
                Do
                    ypos += 1
                    yadd += SCRX
                    If ypos > xe Then Exit Do
                    _gosub(Proc)
                Loop
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                Endif
                SkipScanQ2:
            Next i
            If _N = 0 Then Exit For
            Redim Preserve As Integer ShadowsA(1 To _N, 1 To 6)
            _copylist()
            Redim As Integer ShadowsB(1 To 1, 1 To 6)
        Next inc


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
    Exit Sub
    
    '======================================FILLING LOOPS======================================
    
    asm FillQ1:
        If Sptr[yadd+xpos] <> tcol Then
            dx = xpos-xp-1: dy = inc
            _addelement(xpos-1)
            Proc = SearchLoop
        Else
            'Sptr[yadd+xpos] = col
            Pset(xpos,ypos),col
        Endif
    _return
    
    asm SearchQ1:
        If Sptr[yadd+xpos] = tcol Then
            dx = xpos-xp: dy = inc 
            _addelement(xpos)
            Proc = FillLoop
            'Sptr[yadd+xpos] = Col
            Pset(xpos,ypos),col
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
Dim As Integer Ptr Img
Dim As Integer mx, my, f, fps
Img = ImageCreate(640,480,&HFF000000)
'Bload "ShadowTest2.bmp", Img
randomize timer
For mx = 1 to 10
    Circle Img,(rnd*640,rnd*480),rnd*100, &h0000ff
Next mx
Line Img,(10,10)-(300,300)
Dim as double T = TIMER
Do  
    'ScreenLock
    getmouse mx,my
    If mx = -1 Then 
        mx = 320
        my = 240
    Endif
    Locate 1,1: Print mx, my
    Put (0,0), Img, Pset
    mx = 320: my = 240
    CastLight Img,mx,my,300
    Circle (mx,my),10,&H800000,,,,F
    Locate 2,1: Print fps
    'ScreenUnLock
    sleep 1,1
    f += 1
    If TIMER-T > 1 Then 
        fps = f
        f = 0
        T = Timer
    Endif
Loop Until multikey(1)
ImageDestroy Img
End

 