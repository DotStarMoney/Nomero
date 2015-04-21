#define NUM_SPLITS 1023

function dxrnd() as double
    return (rnd-0.5)*2
end function

sub drawArc(ax as double, ay as double, bx as double, by as double, splits() as double, maxSplits as integer, node as integer = 0)
    dim as double mx, my
    mx = (bx + ax)*0.5 + splits(node, 0)
    my = (by + ay)*0.5 + splits(node, 1)
    if ((2*node + 1) >= maxSplits) orElse ((2*(node + 1)) >= maxSplits) then
        mx += dxrnd()
        my += dxrnd()
        line (ax, ay)-(mx, my), &hcfcfff
        line (mx, my)-(bx, by), &hcfcfff
    else
        drawArc(ax, ay, mx, my, splits(), maxSplits, 2*node + 1)
        drawArc(mx, my, bx, by, splits(), maxSplits, 2*(node + 1))
    end if
end sub





dim as double splits(0 to NUM_SPLITS-1, 0 to 1)
dim as double drifts(0 to NUM_SPLITS-1, 0 to 1)


screenres 640,480,32,2
screenset 1,0
randomize timer

dim as double persist = 300
dim as integer i, cnt, lvl, numIters, mx, my, omx, omy, curSplits
numIters = 0

do
    cls
    omx = mx
    omy = my
    getmouse mx, my
    drawArc(0, 240, mx, my, splits(), curSplits)
    if (omx <> mx) orELse (omy <> my) then numIters *= 0.5
    if numIters <= 0 then
        lvl = 0
        cnt = 1 shl lvl
        persist = Sqr((mx - 0)^2 + (my - 240)^2) * 0.5
        curSplits = (1 shl (int(log(persist*2) / log(2)) + 1)) - 1
        if curSplits > NUM_SPLITS then curSplits = NUM_SPLITS
        for i = 0 to curSplits-1
            splits(i,0) = (rnd-0.5) * persist
            if i = 0 then
                splits(i,1) = -rnd*0.5 * persist
            else
                splits(i,1) = (rnd-0.5) * persist
            end if
            drifts(i,0) = (rnd-0.5) * sqr(persist) * 0.2
            drifts(i,1) = -persist / 90 + (rnd - 0.5) * 0.1
            
            cnt -= 1
            if cnt = 0 then
                lvl += 1
                cnt = 1 shl lvl
                persist *= 0.55
            end if
        next i
        numIters = int(rnd * 40)
    else
        lvl = 0
        cnt = 1 shl lvl
        persist = 4
        for i = 0 to curSplits-1
            splits(i,0) += drifts(i, 0)
            splits(i,1) += drifts(i, 1)
            cnt -= 1
            if cnt = 0 then
                lvl += 1
                cnt = 1 shl lvl
                persist *= 0.5
            end if
        next i
        numIters -= 1
    end if
    
    flip
    sleep 20
loop until multikey(1)
end
