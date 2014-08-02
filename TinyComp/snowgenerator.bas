#include "snowgenerator.bi" 
#include "utility.bi"
#include "constants.bi"
#include "debug.bi"

constructor SnowGenerator()
    head_ = 0
    numFlakes = 0
    freq = 1
    quant = 1
    depth_lo = 1
    depth_hi = 1
    fcnt = freq
    flakeType = SMALL
    flakeDrift = 0
    w = 640
    h = 480
    speed = 15
end constructor

destructor SnowGenerator()
    
end destructor
        
sub SnowGenerator.setFreq(f as integer, q as integer)
    freq = f
    quant = q
    fcnt = f
end sub


sub SnowGenerator.setSpeed(s as double)
    speed = s
end sub

sub SnowGenerator.setDepth(d1 as double, d2 as double)
    depth_lo = d1
    depth_hi = d2
end sub

sub SnowGenerator.setType(tp as sgFlakeType_)
    flakeType = tp
end sub

sub SnowGenerator.setSize(levelWidth as integer,_
                          levelHeight as integer)
    w = levelWidth
    h = levelHeight
end sub

sub SnowGenerator.setDrift(drift as double)
    flakeDrift = drift
end sub

sub SnowGenerator.stepFlakes(cam as Vector2D, t as double)
    dim as integer i, q
    dim as sgFlake_t_ ptr np, nextP, prevP
    dim as double tl_x, tl_y
    dim as double br_x, br_y
    dim as double px, py
    
    
    fcnt -= 1
    if fcnt < 0 then
        fcnt = freq
                       
        for i = 1 to quant
            np = head_
            
            head_ = allocate(sizeof(sgFlake_t_))
            head_->flake_t = flakeType
            head_->depth = rndRange(depth_lo, depth_hi)
            
            tl_x = cam.x() - SCRX*0.5*head_->depth
            tl_y = cam.y() - SCRY*0.5*head_->depth
            br_x = cam.x() + SCRX*0.5*head_->depth
            br_y = cam.y() + SCRY*0.5*head_->depth
            
            if flakeDrift > 0 then
                if rnd * (SCRX+SCRY) < SCRY then
                    head_->p = Vector2D(tl_x - 10, rndRange(tl_y, br_y))
                else
                    head_->p = Vector2D(rndRange(tl_x, br_x), tl_y - 10)
                end if
            else
                if rnd * (SCRX+SCRY) < SCRY then
                    head_->p = Vector2D(br_x + 10, rndRange(tl_y, br_y))
                else
                    head_->p = Vector2D(rndRange(tl_x, br_x), tl_y - 10)
                end if
            end if
            
            head_->v = Vector2D(rnd * 2 - 1 + flakeDrift, speed + rnd * 2)
            head_->f = Vector2D(rnd * 1 - 0.5, rnd * 0.1)              
            
            head_->prev_ = 0
            head_->next_ = np
            
            
            if np <> 0 then np->prev_ = head_
            
            numFlakes += 1
        next i
    end if
    q = 0 
    np = head_
    while np <> 0
        if(int(rnd * 10) = 0) then np->f = Vector2D(rnd * 0.1 - 0.05, rnd * 0.1)
        
        np->v = np->v + np->f * t
        np->p = np->p + np->v
        
        tl_x = cam.x() - SCRX*0.5*np->depth
        tl_y = cam.y() - SCRY*0.5*np->depth
        br_x = cam.x() + SCRX*0.5*np->depth
        br_y = cam.y() + SCRY*0.5*np->depth
        q += 1
        if np->p.y() > br_y orElse _
           (flakeDrift < 0 andAlso np->p.x() < tl_x) orElse _
           (flakeDrift > 0 andALso np->p.x() > br_x) then 
           
            nextP = np->next_
            prevP = np->prev_
           
            if np = head_ then head_ = np->next_
            
            numFlakes -= 1
            deallocate(np)
           
            if nextP <> 0 then nextP->prev_ = prevP
            if prevP <> 0 then prevP->next_ = nextP
            
            np = nextP
        else
            np = np->next_
        end if        
    wend
    
end sub

sub SnowGenerator.drawFlakes(scnbuff as uinteger ptr, cam as Vector2D)
    dim as sgFlake_t_ ptr np
    dim as double xp, yp
    np = head_
   
    while np <> 0
        xp = (np->p.x() - cam.x()) * (1 / np->depth) + cam.x()
        yp = (np->p.y() - cam.y()) * (1 / np->depth) + cam.y()
        circle scnbuff, (xp, yp), 3 / np->depth, &hffffff,,,,F
        np = np->next_
    wend
end sub
