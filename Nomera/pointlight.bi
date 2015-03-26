#ifndef POINTLIGHT_BI
#define POINTLIGHT_BI

#define LIGHT_MAX 8

type PointLight
    as integer ptr diffuse_fbimg
    as integer ptr specular_fbimg
    as integer x, y
    as integer w, h
end type

type LightPair
    as PointLight texture
    as PointLight shaded
end type

#endif