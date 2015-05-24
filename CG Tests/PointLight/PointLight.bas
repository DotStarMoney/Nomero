
' need to find a fast method to split over scratch textures, perhaps two seperate methods

Sub CastLight(dest as integer ptr, source As Integer Ptr, xp As Integer, yp As Integer,_
              rad As integer, col As Integer = &HFFFF00, tcol As Integer = &HFF000000,_
              memoryPool as integer ptr = 0)
              
    'may hit the skids when image pitch is not in words

    #define _Ek 0
    #define _Dn 1
    #define _Dp 2
    #define _Xd 3
    #define _Xx 4
        
    #define SEARCH_LOOP 0
    #define FILL_LOOP 1
    
    #define RR2 0.70710678118654
    
    #define MAX_DWORDS 512

    #define ShadowsA(_I_, _P_) readList[(_I_)*5 + _P_]
    #define ShadowsB(_I_, _P_) writeList[(_I_)*5 + _P_]

    #macro _addelement(a)
        ShadowsB(_N,_Xx) = a: ShadowsB(_N,_Xd) = Sgn(dx)
        dx = Abs(dx): dy = Abs(dy)
        ShadowsB(_N,_Ek) = dx SHL 1 - dy
        ShadowsB(_N,_Dn) = ShadowsB(_N,_Ek) + dy
        ShadowsB(_N,_Dp) = ShadowsB(_N,_Ek) - dy
        _N += 1
    #endmacro
    
    #macro _copyelement(x)
        ShadowsB(_N,_Ek) = ShadowsA(x,_Ek)
        ShadowsB(_N,_Dn) = ShadowsA(x,_Dn)
        ShadowsB(_N,_Dp) = ShadowsA(x,_Dp)
        ShadowsB(_N,_Xx) = ShadowsA(x,_Xx)
        ShadowsB(_N,_Xd) = ShadowsA(x,_Xd)
        _N += 1
    #endmacro
    
    #macro _copylist()
        swap readList, writeList
    #endmacro
        
    dim as integer ptr readList, writeList, Sptr, tex
    Dim As Integer inc, scan, xs, xe, yend = rad*RR2, xcirc, dx, dy, s1, s2, prad, oxs, oxe, txe
    Dim As Integer xpos, ypos, segs, i, _N, ccol, LeftBnd, RightBnd, Offset, yadd,q
    Dim As integer proc, checkAddr, cind, srcW, srcH, sourceStride, texOffset, texCurOffset
    Dim As Integer QuadBnd(0 To 7, 0 To 4), WorkCol, destW, destH, destStride, texCenter
    redim as integer CurveOff(0)
    
    imageinfo dest, destW, destH,, destStride, Sptr 
    imageinfo source, srcW, srcH,, sourceStride, tex
    sourceStride shr=2
    destStride shr= 2
    
    if memoryPool = 0 then
        readList  = new integer[MAX_DWORDS]
        writeList = new integer[MAX_DWORDS]
    else
        readList = memoryPool
        writeList = @(memoryPool[MAX_DWORDS])
    end if
    
    texCenter = (srcW*0.5) + (srcH*0.5)*sourceStride
    
    QuadBnd(0,_Ek) = 1: QuadBnd(0,_Dn) = 2: QuadBnd(0,_Dp) = 0: QuadBnd(0,_Xd) = -1
    QuadBnd(1,_Ek) = 1: QuadBnd(1,_Dn) = 2: QuadBnd(1,_Dp) = 0: QuadBnd(1,_Xd) =  1
    QuadBnd(2,_Ek) = 1: QuadBnd(2,_Dn) = 2: QuadBnd(2,_Dp) = 0: QuadBnd(2,_Xd) = -1
    QuadBnd(3,_Ek) = 1: QuadBnd(3,_Dn) = 2: QuadBnd(3,_Dp) = 0: QuadBnd(3,_Xd) =  1
    QuadBnd(4,_Ek) = 1: QuadBnd(4,_Dn) = 2: QuadBnd(4,_Dp) = 0: QuadBnd(4,_Xd) =  1
    QuadBnd(5,_Ek) = 1: QuadBnd(5,_Dn) = 2: QuadBnd(5,_Dp) = 0: QuadBnd(5,_Xd) = -1
    QuadBnd(6,_Ek) = 1: QuadBnd(6,_Dn) = 2: QuadBnd(6,_Dp) = 0: QuadBnd(6,_Xd) =  1
    QuadBnd(7,_Ek) = 1: QuadBnd(7,_Dn) = 2: QuadBnd(7,_Dp) = 0: QuadBnd(7,_Xd) = -1
    
    prad = rad-yend
    redim as integer CurveOff(0 to prad-1)
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
    
    if (yp > 0) andAlso (yp < destH) andAlso (xp > 0) andALso (xp < destW) then
        checkAddr = yp*destStride+xp
        if Sptr[checkAddr] = tcol then
            Sptr[yp*destStride+xp] = Col
        else
            exit sub
        end if
    else
        exit sub
    end if
    
    if yp > 0 then
        ShadowsA(0,_Ek) = QuadBnd(0,_Ek): ShadowsA(0,_Dn) = QuadBnd(0,_Dn): ShadowsA(0,_Dp) = QuadBnd(0,_Dp)
        ShadowsA(0,_Xx) = xp: ShadowsA(0,_Xd) = QuadBnd(0,_Xd)
        ShadowsA(1,_Ek) = QuadBnd(1,_Ek): ShadowsA(1,_Dn) = QuadBnd(1,_Dn): ShadowsA(1,_Dp) = QuadBnd(1,_Dp)
        ShadowsA(1,_Xx) = xp: ShadowsA(1,_Xd) = QuadBnd(1,_Xd)
        _N = 2
        texOffset = texCenter
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
            End if
            If RightBnd >= destW Then RightBnd = destW-1
            If LeftBnd  <  0     Then LeftBnd  = 0
            ypos = yp - inc
            yadd -= destStride
            texOffset -= sourceStride
            segs = _N
            _N = 0
            For i = 0 To segs-1 Step 2
                
                s1 = i
                s2 = i + 1

                oxs = ShadowsA(s1,_Xx)
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
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
                End if
                txe = xe
                If xe > RightBnd Then xe = RightBnd
                        
                If (xs - oxs) < 0 then
                    if (Sptr[yadd+xs+1] <> tcol) andAlso (Sptr[yadd+xs+destStride] <> tcol) then
                        xs += 1
                    end if
                end if
                If (txe - oxe) > 0 andAlso xe > 0 then
                    if (Sptr[yadd+xe-1] <> tcol) andAlso (Sptr[yadd+xe+destStride] <> tcol) then
                        xe -= 1
                    end if
                end if
                
                if xe < xs then goto SkipScanQ1

                xpos = xs
                texCurOffset = texOffset + (xs - xp)
                If Sptr[yadd+xpos] <> tcol Then
                    Do
                        xpos += 1
                        texCurOffset += 1
                        If xpos >= xe Then Goto SkipScanQ1
                        ccol = Sptr[yadd+xpos]
                        If ccol = tcol Then
                            If xpos < xe Then
                                dx = xpos-xp: dy = inc
                                _addelement(xpos)
                            Else
                                Sptr[yadd+xpos] = tex[texCurOffset]
                            End if
                            Exit Do
                        End if
                    Loop
                Else
                    _copyelement(s1)
                End if
                
                proc = FILL_LOOP
                
                Do
                    if proc = FILL_LOOP then
                        If Sptr[yadd+xpos] <> tcol Then
                            dx = xpos-xp-1: dy = inc
                            _addelement(xpos-1)
                            proc = SEARCH_LOOP
                        Else
                            Sptr[yadd+xpos] = tex[texCurOffset]
                        End if
                    else
                        If Sptr[yadd+xpos] = tcol Then
                            dx = xpos-xp: dy = inc 
                            _addelement(xpos)
                            Proc = FILL_LOOP
                            Sptr[yadd+xpos] = tex[texCurOffset]
                        End if
                    end if
                    xpos += 1
                    texCurOffset += 1
                Loop until xpos > xe
                
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                End if
                SkipScanQ1:    
            Next i
            If _N = 0 Then Exit For
            _copylist()
        Next inc
    end if
    
    '----------------------------------------------------QUAD 2------------------------------------
    
    if xp < destW then
        
        ShadowsA(0,_Ek) = QuadBnd(2,_Ek): ShadowsA(0,_Dn) = QuadBnd(2,_Dn): ShadowsA(0,_Dp) = QuadBnd(2,_Dp)
        ShadowsA(0,_Xx) = yp: ShadowsA(0,_Xd) = QuadBnd(2,_Xd)
        ShadowsA(1,_Ek) = QuadBnd(3,_Ek): ShadowsA(1,_Dn) = QuadBnd(3,_Dn): ShadowsA(1,_Dp) = QuadBnd(3,_Dp)
        ShadowsA(1,_Xx) = yp: ShadowsA(1,_Xd) = QuadBnd(3,_Xd)
        _N = 2
        texOffset = texCenter
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
            texOffset += 1
            segs = _N
            _N = 0
            For i = 0 To segs-1 Step 2               
                s1 = i
                s2 = i + 1
                
                oxs = ShadowsA(s1,_Xx)
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
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
                End if
                txe = xe
                If xe > RightBnd Then xe = RightBnd
                
                
                If (xs - oxs) < 0 then
                    checkAddr = xs*destStride + xpos
                    if (Sptr[checkAddr + destStride] <> tcol) andAlso (Sptr[checkAddr - 1] <> tcol) then
                        xs += 1
                    end if
                end if
                
                If (txe - oxe) > 0 andAlso xe > 0 then
                    checkAddr = xe*destStride + xpos
                    if (Sptr[checkAddr - destStride] <> tcol) andAlso (Sptr[checkAddr - 1] <> tcol) then
                        xe -= 1
                    end if
                end if                
                
                if xe < xs then goto SkipScanQ2
                
                ypos = xs
                yadd = xs * destStride
                texCurOffset = texOffset + (xs - yp)*sourceStride
                If Sptr[yadd+xpos] <> tcol Then
                    Do
                        ypos += 1
                        yadd += destStride
                        texCurOffset += sourceStride
                        If ypos >= xe Then Goto SkipScanQ2
                        ccol = Sptr[yadd+xpos]
                        If ccol = tcol Then
                            If ypos < xe Then
                                dx = ypos-yp: dy = inc
                                _addelement(ypos)
                            Else
                                Sptr[yadd+xpos] = tex[texCurOffset]
                            End if
                            Exit Do
                        Endif
                    Loop
                Else
                    _copyelement(s1)
                End if

                proc = FILL_LOOP
                Do
                    if proc = FILL_LOOP then
                        If Sptr[yadd+xpos] <> tcol Then
                            dx = ypos-yp-1: dy = inc
                            _addelement(ypos-1)
                            proc = SEARCH_LOOP
                        Else
                            Sptr[yadd+xpos] = tex[texCurOffset]
                        End if 
                    else
                        If Sptr[yadd+xpos] = tcol Then
                            dx = ypos-yp: dy = inc
                            _addelement(ypos)
                            proc = FILL_LOOP
                            Sptr[yadd+xpos] = tex[texCurOffset]
                        End if
                    end if
                    ypos += 1
                    yadd += destStride
                    texCurOffset += sourceStride
                Loop until ypos > xe
                
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                End if

                SkipScanQ2:
            Next i
        
            If _N = 0 Then Exit For
            _copylist()
            
        Next inc
    end if
    

    '------------------------------------------------QUAD 3---------------------------------------
    if yp < destH then
        ShadowsA(0,_Ek) = QuadBnd(4,_Ek): ShadowsA(0,_Dn) = QuadBnd(4,_Dn): ShadowsA(0,_Dp) = QuadBnd(4,_Dp)
        ShadowsA(0,_Xx) = xp: ShadowsA(0,_Xd) = QuadBnd(4,_Xd)
        ShadowsA(1,_Ek) = QuadBnd(5,_Ek): ShadowsA(1,_Dn) = QuadBnd(5,_Dn): ShadowsA(1,_Dp) = QuadBnd(5,_Dp)
        ShadowsA(1,_Xx) = xp: ShadowsA(1,_Xd) = QuadBnd(5,_Xd)
        texOffset = texCenter
        yadd = yp * destStride
        If yp + rad >= destH Then
            prad = destH-yp-1
        Else
            prad = rad
        Endif
        _N = 2
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc - yend - 1
                RightBnd = xp + CurveOff(xcirc)
                LeftBnd  = xp - CurveOff(xcirc)
            Else
                RightBnd = xp + inc
                LeftBnd  = xp - inc + 1
            End if
            If RightBnd >= destW Then RightBnd = destW - 1
            If LeftBnd  <  0     Then LeftBnd  = 0
            ypos = yp + inc
            yadd += destStride
            texOffset += sourceStride
            segs = _N
            _N = 0
            For i = 0 To segs-1 Step 2
                
                s1 = i
                s2 = i + 1
                oxs = ShadowsA(s1,_Xx)
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
                oxe = ShadowsA(s2,_Xx)
                If ShadowsA(s2,_Ek) < 0 Then
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dn)
                Else
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dp)
                    ShadowsA(s2,_Xx) += ShadowsA(s2,_Xd)
                End If
                xs = ShadowsA(s1,_Xx)
                xe = ShadowsA(s2,_Xx)
                
                If xe > RightBnd Then 
                    Goto SkipScanQ3
                Elseif xs < LeftBnd Then
                    Goto SkipScanQ3
                Elseif xs > RightBnd Then
                    xs = RightBnd
                End if
                
                txe = xe
                If xe < LeftBnd Then xe = LeftBnd
                
                If (xs - oxs) > 0 andalso xs > 0 then
                    if (Sptr[yadd+xs-1] <> tcol) andAlso (Sptr[yadd+xs-destStride] <> tcol) then
                        xs -= 1
                    end if
                end if
                If (txe - oxe) < 0 then
                    if (Sptr[yadd+xe+1] <> tcol) andAlso (Sptr[yadd+xe-destStride] <> tcol) then
                        xe += 1
                    end if
                end if
                
                if xe > xs then goto SkipScanQ3

                xpos = xs
                texCurOffset = texOffset + (xs - xp)
                If Sptr[yadd+xpos] <> tcol Then
                    Do
                        xpos -= 1
                        texCurOffset -= 1
                        If xpos <= xe Then Goto SkipScanQ3
                        ccol = Sptr[yadd+xpos]
                        If ccol = tcol Then
                            If xpos > xe Then
                                dx = xpos-xp: dy = inc
                                _addelement(xpos)
                            Else
                                Sptr[yadd+xpos] = tex[texCurOffset]
                            End if
                            Exit Do
                        End if
                    Loop
                Else
                    _copyelement(s1)
                End if
                
                proc = FILL_LOOP
                Do
                    if proc = FILL_LOOP then
                        If Sptr[yadd+xpos] <> tcol Then
                            dx = xpos-xp+1: dy = inc
                            _addelement(xpos+1)
                            proc = SEARCH_LOOP
                        Else
                            Sptr[yadd+xpos] = tex[texCurOffset]
                        End if
                    else
                        If Sptr[yadd+xpos] = tcol Then
                            dx = xpos-xp: dy = inc 
                            _addelement(xpos)
                            proc = FILL_LOOP
                            Sptr[yadd+xpos] = tex[texCurOffset]
                        End if                   
                    end if
                    xpos -= 1
                    texCurOffset -= 1
                Loop until xpos < xe
                
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                End if
                SkipScanQ3:
            Next i
            If _N = 0 Then Exit For
            _copylist()
        Next inc
    end if
    
    '------------------------------------------------QUAD 4---------------------------------------
    if xp > 0 then
        ShadowsA(0,_Ek) = QuadBnd(6,_Ek): ShadowsA(0,_Dn) = QuadBnd(6,_Dn): ShadowsA(0,_Dp) = QuadBnd(6,_Dp)
        ShadowsA(0,_Xx) = yp: ShadowsA(0,_Xd) = QuadBnd(6,_Xd)
        ShadowsA(1,_Ek) = QuadBnd(7,_Ek): ShadowsA(1,_Dn) = QuadBnd(7,_Dn): ShadowsA(1,_Dp) = QuadBnd(7,_Dp)
        ShadowsA(1,_Xx) = yp: ShadowsA(1,_Xd) = QuadBnd(7,_Xd)
        texOffset = texCenter
        _N = 2
        If xp - rad < 0 Then
            prad = xp
        Else
            prad = rad
        End if
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc - yend - 1
                RightBnd = yp + CurveOff(xcirc)
                LeftBnd  = yp - CurveOff(xcirc)
            Else
                RightBnd = yp + inc
                LeftBnd  = yp - inc + 1
            End if
            If RightBnd >= destH Then RightBnd = destH-1
            If LeftBnd  <  0     Then LeftBnd  = 0
            xpos = xp - inc
            texOffset -= 1
            segs = _N
            _N = 0
            For i = 0 To segs-1 Step 2
                
                s1 = i
                s2 = i + 1
                oxs = ShadowsA(s1,_Xx)
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
                oxe = ShadowsA(s2,_Xx)
                If ShadowsA(s2,_Ek) < 0 Then
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dn)
                Else
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dp)
                    ShadowsA(s2,_Xx) += ShadowsA(s2,_Xd)
                End If
                xs = ShadowsA(s1,_Xx)
                xe = ShadowsA(s2,_Xx)
                
                If xe > RightBnd Then 
                    Goto SkipScanQ4
                Elseif xs < LeftBnd Then
                    Goto SkipScanQ4
                Elseif xs > RightBnd Then
                    xs = RightBnd
                End if
                
                txe = xe
                If xe < LeftBnd Then xe = LeftBnd
                
                
                If (xs - oxs) > 0 andalso xs > 0 then
                    checkAddr = xs*destStride + xpos
                    if (Sptr[checkAddr - destStride] <> tcol) andAlso (Sptr[checkAddr + 1] <> tcol) then
                        xs -= 1
                        
                    end if
                end if
                If (txe - oxe) < 0 then
                    checkAddr = xe*destStride + xpos
                    if (Sptr[checkAddr + destStride] <> tcol) andAlso (Sptr[checkAddr + 1] <> tcol) then
                        xe += 1
                    end if
                end if
                
                if xe > xs then goto SkipScanQ4
                
                ypos = xs
                yadd = xs * destStride
                texCurOffset = texOffset + (xs - yp)*sourceStride
                If Sptr[yadd+xpos] <> tcol Then
                    Do
                        ypos -= 1
                        yadd -= destStride
                        texCurOffset -= sourceStride
                        If ypos <= xe Then Goto SkipScanQ4
                        ccol = Sptr[yadd+xpos]
                        If ccol = tcol Then
                            If ypos > xe Then
                                dx = ypos-yp: dy = inc
                                _addelement(ypos)
                            Else
                                Sptr[yadd+xpos] = tex[texCurOffset]
                            End if
                            Exit Do
                        End if
                    Loop
                Else
                    _copyelement(s1)
                End if
                
                proc = FILL_LOOP
                Do
                    if proc = FILL_LOOP then
                        If Sptr[yadd+xpos] <> tcol Then
                            dx = ypos-yp+1: dy = inc
                            _addelement(ypos+1)
                            Proc = SEARCH_LOOP
                        Else
                            Sptr[yadd+xpos] = tex[texCurOffset]
                        End if
                    else
                        If Sptr[yadd+xpos] = tcol Then
                            dx = ypos-yp: dy = inc
                            _addelement(ypos)
                            Proc = FILL_LOOP
                            Sptr[yadd+xpos] = tex[texCurOffset]          
                        End if                        
                    end if
                    ypos -= 1
                    yadd -= destStride
                    texCurOffset -= sourceStride
                Loop until ypos < xe
                
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                End if
                SkipScanQ4:
            Next i
            If _N = 0 Then Exit For
            _copylist()
        Next inc
    end if
   
    if memoryPool = 0 then
        delete(readList)
        delete(writeList)
    end if
  
End Sub


screenres 640,480,32
Dim As Integer Ptr Img, Img2, tex
Dim As Integer mx, my, f, fps
Img = ImageCreate(640,480,&HFF000000)
Img2 = ImageCreate(640,480,&HFF000000)
tex = ImageCreate(650,650)
bload "nlight.bmp", tex
randomize 24
For mx = 1 to 10
    Circle Img2,(rnd*640,rnd*480),rnd*100, &hff0000
Next mx
Dim as double T = TIMER
Do  
    'ScreenLock
    getmouse mx,my
    If mx = -1 Then 
        mx = 320
        my = 240
    End if
        
    Put Img, (0,0), Img2, Pset
    
    'mx = 417: my = 264
    
    CastLight Img,tex,mx,my,324
    pset Img, (mx, my), &hff0000
    
    draw string Img, (0, 0), "Mouse X,Y: "+str(mx) + ", " + str(my), &h7f7f7f
    draw string Img, (0, 8), "FPS: " + str(fps), &h7f7f7f

    
    put (0,0), Img, Pset
    
    f += 1
    If TIMER-T > 1 Then 
        fps = f
        f = 0
        T = Timer
    Endif
Loop Until multikey(1)
ImageDestroy Img
End

 