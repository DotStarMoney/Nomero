#include "tinybody.bi"

constructor TinyBody
    p = Vector2D(0.0, 0.0)
    v = Vector2D(0.0, 0.0)
    f = Vector2D(0.0, 0.0)
    r = 0
    m = 0
    r_rat = 1.0
    elasticity = 0
    friction = 0
    noCollide = 0
    didCollide = 0
    surfaceV = Vector2D(0,0)
    dynaID = -1
end constructor

constructor TinyBody(p_ as Vector2D, r_ as double, m_ as double)
    p = p_
    m = m_
    r = r_
    r_rat = 1.0
    v = Vector2D(0.0, 0.0)
    f = Vector2D(0.0, 0.0)
    elasticity = 0
    friction = 0
    noCollide = 0
    didCollide = 0
    surfaceV = Vector2D(0,0)
    dynaID = -1
end constructor 


constructor TinyBody(p_ as Vector2D, rx_ as double, ry_ as double, m_ as double)
    p = p_
    m = m_
    r = ry_
    r_rat = ry_ / rx_
    v = Vector2D(0.0, 0.0)
    f = Vector2D(0.0, 0.0)
    elasticity = 0
    friction = 0
    noCollide = 0
    didCollide = 0
    surfaceV = Vector2D(0,0)
    dynaID = -1
end constructor 
