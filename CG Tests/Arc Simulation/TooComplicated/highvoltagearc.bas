#include "highvoltagearc.bi"
#include "vector2d.bi"

constructor HighVoltageArc()
    dim as integer i
    
    octave_N = 3
    
    octave = new HighVoltageArc_Octave[octave_N]
    for i = 0 to octave_N - 1
        octave[i].anchor_N = 16 + 8 ^ i
        octave[i].anchor = new HighVoltageArc_Anchor[octave[i].anchor_N]
    next i
    pt_a = Vector3D(0,0,0)
    pt_b = Vector3D(0,0,0)
end constructor

destructor HighVoltageArc()
    dim as integer i
    for i = 0 to octave_N - 1
        octave[i].anchor_N = 0
        delete(octave[i].anchor)
    next i
    octave_N = 0
    delete(octave)
end destructor

sub HighVoltageArc.init()
    dim as integer i, q
    dim as double anchStep
    dim as double persistence
    dim as double param
    dim as Vector3D ep_v
    ep_v = pt_b - pt_a
    persistence = 1
    for i = 0 to octave_N - 1
        anchStep = 1 / (octave[i].anchor_N + 1)
        
        octave[i].curve.flush()
        octave[i].curve.addControlPoint(pt_a)
        for q = 0 to octave[i].anchor_N - 1
            octave[i].curve.addControlPoint(ep_v * ((q + 1) * anchStep) + pt_a)
        next q
        octave[i].curve.addControlPoint(pt_b)
       
        for q = 0 to octave[i].anchor_N - 1
            param = (q + 1) * anchStep
            if i <> 0 then
                octave[i].anchor[q].index = octave[i - 1].curve.createAnchor(param * octave[i - 1].curve.getLength())
                octave[i].anchor[q].theta = (rnd * (atn(1) * 8))
                octave[i].anchor[q].r = (rnd * ep_v.magnitude() * 0.5) * persistence
                octave[i].anchor[q].r_inc = (rnd * persistence)
                octave[i].anchor[q].lifeFrames = (int(rnd * 90) + 30)
            else
                octave[i].anchor[q].index = -1
                octave[i].anchor[q].theta = 0
                octave[i].anchor[q].r = rnd * ep_v.magnitude() * 0.5
                octave[i].anchor[q].r_inc = rnd
                octave[i].anchor[q].lifeFrames = int(rnd * 90) + 30
            end if
        next q
        persistence *= 0.1
    next i
end sub

sub HighVoltageArc.setEndpoints(a as Vector3D, b as Vector3D)
    pt_a = a
    pt_b = b
end sub
sub HighVoltageArc.step_(t as double)
    dim as integer i, q
    dim as double persistence, anchStep, phi, theta
    dim as Vector3D pt_q, tan_q, offset_q
    dim as Vector3D ep_v, rpt
    ep_v = pt_b - pt_a
    anchStep = 1 / (octave[0].anchor_N + 1)
    
    persistence = 1
    for i = 0 to octave_N - 1
        with octave[i]
            for q = 0 to .anchor_N - 1
                .anchor[q].lifeFrames -= 1
                if .anchor[q].lifeFrames < 0 then
                    .anchor[q].lifeFrames = (int(rnd * 90) + 30)
                    .anchor[q].r = (rnd * .anchor[q].r) * persistence
                    .anchor[q].r_inc = (rnd * persistence)
                    if i <> 0 then
                        .anchor[q].theta = (rnd * (atn(1) * 8))
                    else
                        .anchor[q].theta = 0
                    end if
                else
                    .anchor[q].r += .anchor[q].r_inc
                end if
                if i = 0 then
                    pt_q = ep_v * ((q + 1) * anchStep) + pt_a
                    tan_q = ep_v.normalize()
                else
                    pt_q = octave[i - 1].curve.getAnchor(.anchor[q].index)
                    tan_q = octave[i - 1].curve.getTangent()
                end if
                rpt = Vector3D(0, 1, 0)
                rpt = rpt.rotate(Vector3D(0,0,0), Vector3D(1,0,0), .anchor[q].theta)
                phi = rpt.phi() + tan_q.phi()
                theta = rpt.theta() + tan_q.theta()
                offset_q = pt_q + rpt
                .curve.setControlPoint(1 + q, offset_q)
            next q
        end with
        persistence *= 0.1
    next i
end sub
sub HighVoltageArc.draw_(scnbuff as integer ptr)
    dim as Vector2D tp
    dim as Vector3D p
    dim as double tpos
    tpos = 0
    while tpos < octave[0].curve.getLength()
        p = octave[0].curve.getPoint(tpos)
        tp = perspective(p, Vector3D(0,0,-256), 256, Vector2D(640,480), Vector2D(640,480))
        pset (tp.x, tp.y)
        tpos += 1
    wend
    /'
    dim as integer i
    for i = 0 to octave[1].curve.getControlPointN() - 1
        p = octave[1].curve.getControlPoint(i)
        tp = perspective(p, Vector3D(0,0,-256), 256, Vector2D(640,480), Vector2D(640,480))
        circle (tp.x, tp.y), 4, rgb(255,0,0)
    next i
    '/
end sub
