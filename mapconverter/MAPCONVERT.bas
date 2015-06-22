#include "list.bi"
#include "hashtable.bi"
#include "vector2d.bi"
#include "dir.bi"
#include "file.bi"
#include "fbpng.bi"
#include "vbcompat.bi"

Enum MaskResult_e
    SUBSET
    DISJOINT
    OVERLAP
    COVERING
    FULL_COVERING
end enum
dim shared as integer maskComparePixels = 0

function equalImages(imgA as integer ptr, imgB as integer ptr) as integer
    dim as integer x, y
    for y = 0 to 15
        for x = 0 to 15
            if (point(x, y, imgA) and &h00ffffff) <> (point(x, y, imgB) and &h00ffffff) then 
                return 0
            end if
        next x
    next y
    return 1
end function
function imageIsNotEmpty(imgA as integer ptr) as integer
    dim as integer x, y
    for y = 0 to 15
        for x = 0 to 15
            if ((point(x, y, imgA) and &h00ffffff) <> &h00ff00ff) then return 1
        next x
    next y
    return 0
end function
function hashImage(img as integer ptr) as integer
    dim as integer x, y
    dim as integer col
    dim as integer hash
    for y = 0 to 15
        for x = 0 to 15
            hash = hash xor (point(x, y, img) and &h00ffffff)
        next x
    next y
    return hash
end function
function maskCompare(low as integer ptr, high as integer ptr) as MaskResult_e
    dim as integer x, y
    dim as integer col1, col2
    dim as integer low_Count = 0, high_Count = 0, or_Count = 0
    for y = 0 to 15
        for x = 0 to 15
            col1 = point(x, y, low) and &h00ffffff
            col2 = point(x, y, high) and &h00ffffff
            if( col1 = &hFFFFFF ) then
                low_Count += 1
            end if
            if( col2 = &hFFFFFF ) then
                high_Count += 1
            end if    
            if( (col1 = &hFFFFFF) or (col2 = &hFFFFFF) ) then
                or_Count += 1
            end if
        next x
    next y
    maskComparePixels = or_Count
    if high_Count = 256 then 
        if low_Count = 0 then
            return DISJOINT
        else
            return FULL_COVERING
        end if
    end if
    if low_Count + high_Count = or_Count then return DISJOINT
    if high_Count >= low_Count then
        if or_Count = high_Count then
            return COVERING
        else
            return OVERLAP
        end if
    else
        if or_Count = low_Count then
            return SUBSET
        else
            return OVERLAP
        end if
    end if
end function

sub extractMask(dest as integer ptr, src as integer ptr, xoff as integer, yoff as integer)
    dim as integer x, y
    dim as integer col
    for y = 0 to 15
        for x = 0 to 15
            if( (point(xoff + x, yoff + y, src) and &h00ffffff) = &hFF00FF ) then
                pset dest, (x, y), &h00000000
            else
                pset dest, (x, y), &h00ffffff
            end if
        next x
    next y
end sub

Public Sub Split(Text As String, Delim As String = " ", Count As Long = -1, Ret() As String)

    Dim As Long x, p
    If Count < 1 Then
        Do
            x = InStr(x + 1, Text, Delim)
            p += 1
        Loop Until x = 0
        Count = p - 1
    ElseIf Count = 1 Then
        ReDim Ret(Count)
        Ret(0) = Text
    Else
        Count -= 1
    End If
    Dim RetVal(Count) As Long
    x = 0
    p = 0
    Do Until p = Count
        x = InStr(x + 1,Text,Delim)
        RetVal(p) = x
        p += 1
    Loop
    ReDim Ret(Count)
    Ret(0) = Left(Text, RetVal(0) - 1 )
    p = 1
    Do Until p = Count
        Ret(p) = Mid(Text, RetVal(p - 1) + 1, RetVal(p) - RetVal(p - 1) )
        p += 1
    Loop
    Ret(Count) = Mid(Text, RetVal(Count - 1) + 1)
   
End Sub

#define trimQuotes(x) (mid(x, 2, len(x)-2))

enum RangeSet_t
    FOREGROUND
    ACTIVE_COVER
    ACTIVE
    BACKGROUND
    ACTIVE_FRONT
end enum

enum EffectType_t
    ANIMATE
    FLICKER
    DESTRUCT
    NONE
end enum

enum PortalDirection_t
    D_LEFT
    D_UP
    D_RIGHT
    D_DOWN
    D_IN
    NO_FACING
end enum

type singleTile_t
    as integer tileset
    as integer tileNum
    as integer tileID
    as integer usesAnim
end type

type tileEffect_t
    as ushort tilenum
    as ushort effect
    as short  nextTile
    as ushort delay
    as ushort offset
end type

type set_t
    as zstring * 128 set_name
    as zstring * 128 set_filename
    as ushort set_width
    as ushort set_height
    as ushort set_firstID
    as integer used
    as List ptr tilePropList
end type

type layer_t
    as zstring * 128 layer_name
    as uinteger ptr layer_data
    as ushort parallax
    as ushort coverage
    as ushort illuminated
    as integer ambientLevel
    as single depth
    as ushort inRangeSet
    as ushort isDestructible
    as ushort isFallout
    as ushort isReceiver
    as ushort occluding
    as ushort mergeless
    as ushort order
    as integer empty
end type


'----------- object fields ---------

enum ObjectShape_t
    ELLIPSE
    RECTANGLE
end enum

enum ObjectType_t
    EFFECT
    PORTAL
    TRIGGER
    SPAWN
end enum

enum SpawnerRespawnType_t
    SPAWN_TIMED
    SPAWN_ONCE
    SPAWN_FRAME
end enum

type objectSpawner_t
    as zstring * 128 spawn_objectName
    as single spawn_time
    as ushort spawn_count
    as ushort flavor
    as ushort spawn_respawnType
end type


type objectPortal_t
    as zstring * 128 portal_to_map
    as zstring * 128 portal_to_portal
    as ushort        portal_direction
end type

enum ObjectEffectType_t
    RADAR_PULSE         = 0
    SHIMMER             = 1
    SMOKE               = 2
    DRIP                = 3
    TELEPORTER_SHIELD   = 4
    LIGHT_1             = 5
    LIGHT_2             = 6
    LIGHT_3             = 7
    LIGHT_4             = 8
    LIGHT_5             = 9
    LIGHT_6             = 10
    LIGHT_7             = 11
    LIGHT_8             = 12
end enum

enum ObjectEffectMode_t
    MODE_FLICKER = 0
    MODE_TOGGLE  = 1
    MODE_STATIC  = 2
end enum

type objectEffect_t
    as ushort effect_type
    as ushort effect_density
    as ushort minValue
    as ushort maxValue
    as ushort mode
    as ushort fast
end type

dim as objectPortal_t  ptr tempObjPortal
dim as objectEffect_t  ptr tempObjEffect
dim as objectSpawner_t ptr tempObjSpawner

type object_t
    as zstring * 128 object_name
    as ushort object_type
    as ushort object_shape
    as ushort inRangeSet
    as Vector2D p
    as Vector2D size
    as any ptr data_
end type


'------- fields to fill out ----------
dim as zstring * 128 map_name
dim as zstring * 128 music_file
dim as ushort default_x
dim as ushort default_y
dim as ushort pcenter_x
dim as ushort pcenter_y
dim as ushort snowfall = 0
dim as ushort shouldLight = 65535
dim as ushort aurora = 65535
dim as integer objectAmbientLevel = &hffffffff
dim as integer hiddenObjectAmbientLevel = &hffffffff
dim as ushort map_width, map_height
dim as ushort N_tilesets, N_layers, N_objects

N_tilesets = 0
N_layers = 0
N_objects = 0

redim as set_t tilesets(0)
redim as layer_t layers(0)
redim as object_t objects(0)
redim as integer ptr setImages(0)
redim as integer ptr setImages_norm(0)
'-------------------------------------


type tag_index_t
    as string tag
    as integer index
end type

dim as tag_index_t tag_index_stack(0 to 9)
dim as integer     tag_index_n = 0

#macro PUSH()
    tag_index_stack(tag_index_n) = ti_pair
    tag_index_n += 1
#endmacro

#macro POP()
    tag_index_n -= 1
    ti_pair = tag_index_stack(tag_index_n)
#endmacro

#macro TOP()
    if tag_index_n = 0 then
        ti_pair.tag = ""
        ti_pair.index = 0
    else
        ti_pair = tag_index_stack(tag_index_n - 1)
    end if
#endmacro

#define NUM_COLLISION_BLOCKS 84

dim as string filename, lne, item_tag, item_content, tempMap
redim as string pieces(0 to 0)
dim as tag_index_t ti_pair
dim as integer f, itemNestLevel, itemIndex, curPos, curTile, hasCenter
dim as integer dataline, curChar, row, col, colIndex, propertyline = 0
dim as integer propertyType = 0, isObject, readObjects, curObjDepth
dim as tileEffect_t tempEffect
dim as tileEffect_t ptr tempEffectPtr
dim as string ls, rs


screenres 640,480,32

hasCenter = 0

filename = command(1)
if len(filename) = 0 then end

f = freefile
open filename for input as #f

tempMap = left(filename, len(filename)-4)
tempMap = right(tempMap, len(tempMap) - instrrev(tempMap, "\"))
map_name = tempMap

itemNestLevel = 0
itemIndex = 1
dataline = 0
isObject = 0
readObjects = 0
curObjDepth = ACTIVE
do
    'cls
 
    Line Input #f, lne
    while left(lne, 1) = " "
        lne = right(lne, len(lne)-1)
    wend
    while right(lne, 1) = " "
        lne = left(lne, len(lne)-1)
    wend
    
    if dataline = 0 then
        if propertyline = 0 then
            curPos = instr(lne,"=") 
            if curPos < 1 then
                if right(lne, 1) = "{" then
                    
                    TOP()
                    ti_pair.index = itemIndex
                    PUSH()
                    itemIndex = 1
                    itemNestLevel += 1
                    
                elseif right(lne, 2) = "}," then
                    
                    POP()
                    itemIndex = ti_pair.index
                    itemIndex += 1
                    itemNestLevel -= 1
                    
                elseif right(lne, 1) = "}" then
                    
                    if readObjects = 1 then
                        readObjects = 0
                    else
                        readObjects = 0
                        isObject = 0
                    end if
                    POP()
                    itemNestLevel -= 1
                
                end if
            else
                item_tag     = left(lne, curPos-2)
                item_content = right(lne, len(lne) - curPos - 1)
                if right(item_content, 1) = "," then
                    item_content = left(item_content, len(item_content) - 1)
                end if
                
                if itemNestLevel = 1 then
                    if item_tag = "width" then
                        map_width = val(item_content)
                    elseif item_tag = "height" then
                        map_height = val(item_content)
                    elseif item_tag = "tilesets" then
                        ti_pair.tag = "tilesets"
                        ti_pair.index = itemIndex
                        PUSH()
                        itemIndex = 1
                        itemNestLevel += 1
                    elseif item_tag = "layers" then
                        ti_pair.tag = "layers"
                        ti_pair.index = itemIndex
                        PUSH()
                        itemIndex = 1
                        itemNestLevel += 1
                    elseif item_tag = "properties" then
                        snowfall = 0
                        if item_content <> "{}" then
                            propertyline = 1
                            propertytype = 2
                        end if
                    end if
                elseif itemNestLevel > 1 then
                    TOP()
                    if isObject = 0 then
                        if ti_pair.tag = "tilesets" then
                            if item_tag = "name" then
                                N_tilesets += 1
                                redim preserve as set_t tilesets(0 to N_tilesets - 1)                        
                                tilesets(N_tilesets - 1).set_name = mid(item_content, 2, len(item_content)-2)
                                tilesets(N_tilesets - 1).tilePropList = 0
                            elseif item_tag = "firstgid" then
                                tilesets(N_tilesets - 1).set_firstID = val(item_content)
                            elseif item_tag = "imagewidth" then
                                tilesets(N_tilesets - 1).set_width = val(item_content)
                            elseif item_tag = "imageheight" then
                                tilesets(N_tilesets - 1).set_height = val(item_content)
                            elseif item_tag = "image" then
                                tilesets(N_tilesets - 1).set_filename = mid(item_content, 2, len(item_content)-2)
                            elseif item_tag = "tiles" andAlso item_content <> "{}" then
                                tilesets(N_tilesets - 1).tilePropList = new List
                                tilesets(N_tilesets - 1).tilePropList->init(sizeof(tileEffect_t))
                                ti_pair.tag = "tiles"
                                ti_pair.index = itemIndex
                                PUSH()
                                itemIndex = 1
                                itemNestLevel += 1
                            end if
                        elseif ti_pair.tag = "layers" then
                            if item_tag = "name" then
                                N_layers += 1
                                redim preserve as layer_t layers(0 to N_layers - 1)
                                layers(N_layers - 1).layer_name = mid(item_content, 2, len(item_content)-2)
                                layers(N_layers - 1).layer_data = allocate(sizeof(uinteger) * map_width*map_height)
                            elseif item_tag = "type" then
                                if isObject = 0 then
                                    if mid(item_content, 2, len(item_content)-2) = "objectgroup" then
                                        isObject = 1
                                        curObjDepth = ACTIVE
                                    end if
                                end if
                            elseif item_tag = "data" then
                                dataline = 1
                                row = 0
                                col = 0
                            elseif item_tag = "properties" then
                                layers(N_layers - 1).order = N_layers - 1
                                layers(N_layers - 1).depth = 1
                                layers(N_layers - 1).parallax = 65535
                                layers(N_layers - 1).coverage = 65535
                                layers(N_layers - 1).mergeless = 65535
                                layers(N_layers - 1).ambientLevel = 0
                                layers(N_layers - 1).illuminated = 65535
                                layers(N_layers - 1).inRangeSet = ACTIVE
                                layers(N_layers - 1).isDestructible = 65535
                                layers(N_layers - 1).isFallout = 65535
                                layers(N_layers - 1).isReceiver = 65535
                                layers(N_layers - 1).occluding = 65535
                                if item_content <> "{}" then 
                                    propertyline = 1
                                    propertyType = 0
                                end if
                            end if
                        elseif ti_pair.tag = "tiles" then
                            if item_tag = "properties" then
                                if item_content <> "{}" then 
                                    propertyline = 1
                                    propertyType = 1
                                end if
                            elseif item_tag = "id" then
                                with tempEffect
                                    .tilenum = val(item_content)
                                    .nextTile = 0
                                    .delay = 0
                                    .offset = 0
                                    .effect = NONE
                                end with
                            end if
                        end if
                    else
                        if readObjects = 0 then
                            if item_tag = "objects" then
                                if item_content <> "{}" then
                                    readObjects = 1
                                    ti_pair.tag = "objects"
                                    ti_pair.index = itemIndex
                                    PUSH()
                                    itemIndex = 1
                                    itemNestLevel += 1
                                end if
                            elseif item_tag = "properties" then
                                if item_content <> "{}" then 
                                    propertyline = 1
                                    propertyType = 4
                                end if
                            end if
                        else
                            if item_tag = "name" then
                                N_objects += 1 
                                redim preserve as object_t objects(0 to N_objects - 1)   
                                objects(N_objects - 1).object_name = trimQuotes(item_content)
                                objects(N_objects - 1).data_ = 0
                                objects(N_objects - 1).inRangeSet = curObjDepth
                            elseif item_tag = "type" then
                                item_content = trimQuotes(item_content)
                                if left(ucase(item_content), 6) = "EFFECT" then
                                    objects(N_objects - 1).object_type = EFFECT
                                elseif left(ucase(item_content), 6) = "PORTAL" then
                                    objects(N_objects - 1).object_type = PORTAL
                                elseif left(ucase(item_content), 5) = "SPAWN" then
                                    objects(N_objects - 1).object_type = SPAWN
                                end if
                            elseif item_tag = "shape" then
                                item_content = trimQuotes(item_content)
                                if item_content = "ellipse" then
                                    objects(N_objects - 1).object_shape = ELLIPSE
                                elseif item_content = "rectangle" then
                                    objects(N_objects - 1).object_shape = RECTANGLE
                                end if
                            elseif item_tag = "x" then
                                objects(N_objects - 1).p.setX(val(item_content))
                            elseif item_tag = "y" then
                                objects(N_objects - 1).p.setY(val(item_content))
                            elseif item_tag = "width" then
                                objects(N_objects - 1).size.setX(val(item_content))
                            elseif item_tag = "height" then
                                objects(N_objects - 1).size.setY(val(item_content))
                            elseif item_tag = "properties" then
                                if item_content <> "{}" then 
                                    propertyline = 1
                                    propertyType = 3
                                    select case objects(N_objects - 1).object_type
                                    case EFFECT
                                        objects(N_objects - 1).data_ = allocate(sizeof(ObjectEffect_t))
                                        tempObjEffect = objects(N_objects - 1).data_
                                        tempObjEffect->effect_type = LIGHT_1
                                        tempObjEffect->effect_density = 65536 * 0.5
                                        tempObjEffect->minValue = 65535
                                        tempObjEffect->maxValue = 65535
                                        tempObjEffect->mode = MODE_STATIC
                                        tempObjEffect->fast = 65535
                                    case PORTAL
                                        objects(N_objects - 1).data_ = allocate(sizeof(ObjectPortal_t))
                                        tempObjPortal = objects(N_objects - 1).data_
                                        tempObjPortal->portal_direction = D_IN
                                    case SPAWN
                                        objects(N_objects - 1).data_ = allocate(sizeof(ObjectSpawner_t))
                                        tempObjSpawner = objects(N_objects - 1).data_
                                        tempObjSpawner->spawn_time = 0
                                        tempObjSpawner->spawn_objectName = ""
                                        tempObjSpawner->spawn_count = 1
                                        tempObjSpawner->spawn_respawnType = SPAWN_ONCE
                                        tempObjSpawner->flavor = 0
                                    end select
                                end if
                            end if
                            
                        end if
                    end if
                end if
                itemIndex += 1
                                 

             end if
        else
            if right(lne, 1) = "}" orElse right(lne,2) = "}," then 
                propertyline = 0
                if propertyType = 1 then
                    tilesets(N_tilesets - 1).tilePropList->push_back(@tempEffect)
                end if
            else
                curPos = instr(lne,"=") 
                item_tag     = mid(lne, 3, curPos - 6)
                item_content = right(lne, len(lne) - curPos - 1)
                if right(item_content, 1) = "," then
                    item_content = left(item_content, len(item_content) - 1)
                end if
                item_content = mid(item_content, 2, len(item_content)-2)
                if propertyType = 0 then
                    if left(lcase(item_tag), 5) = "order" then
                        'layers(N_layers - 1).order = val(item_content)
                    elseif left(lcase(item_tag), 5) = "depth" then
                        layers(N_layers - 1).depth = val(item_content)
                    elseif left(lcase(item_tag), 8) = "parallax" then
                        layers(N_layers - 1).parallax = 1
                    elseif left(lcase(item_tag), 10) = "foreground" then
                        layers(N_layers - 1).inRangeSet = FOREGROUND
                    elseif left(lcase(item_tag), 10) = "background" then
                        layers(N_layers - 1).inRangeSet = BACKGROUND
                    elseif left(lcase(item_tag), 12) = "active cover" then
                        layers(N_layers - 1).inRangeSet = ACTIVE_COVER
                    elseif left(lcase(item_tag), 12) = "active front" then
                        layers(N_layers - 1).inRangeSet = ACTIVE_FRONT                  
                    elseif left(lcase(item_tag), 6) = "active" then
                        layers(N_layers - 1).inRangeSet = ACTIVE
                    elseif left(lcase(item_tag), 12) = "destructible" then
                        layers(N_layers - 1).isDestructible = 1
                    elseif left(lcase(item_tag), 7) = "fallout" then
                        layers(N_layers - 1).isFallout = 1
                    elseif left(lcase(item_tag), 9) = "mergeless" then
                        layers(N_layers - 1).mergeless = 1
                    elseif left(lcase(item_tag), 13) = "ambient level" then
                        layers(N_layers - 1).ambientLevel = val(item_content)
                    elseif left(lcase(item_tag), 11) = "illuminated" then
                        layers(N_layers - 1).illuminated = 1
                    elseif left(lcase(item_tag), 8) = "coverage" then
                        layers(N_layers - 1).coverage = 1         
                    elseif left(lcase(item_tag), 8) = "receiver" then
                        layers(N_layers - 1).isReceiver = 1 
                    elseif left(lcase(item_tag), 9) = "occluding" then
                        layers(N_layers - 1).occluding = 1    
                    end if
                elseif propertyType = 1 then
                    with tempEffect
                        if left(lcase(item_tag), 6) = "effect" then
                            if left(lcase(item_content), 7) = "animate" then
                                .effect = ANIMATE
                            elseif left(lcase(item_content), 7) = "flicker" then
                                .effect = FLICKER
                            elseif left(lcase(item_content), 8) = "destruct" then
                                .effect = DESTRUCT
                            end if
                        elseif left(lcase(item_tag), 4) = "next" then 
                            .nextTile = val(item_content)
                        elseif left(lcase(item_tag), 5) = "delay" then
                            .delay = val(item_content)
                        elseif left(lcase(item_tag), 6) = "offset" then
                            .offset = val(item_content)
                        end if
                    end with
                elseif propertyType = 2 then
                    if left(lcase(item_tag), 4) = "snow" then
                        'if left(lcase(item_content), 2) = "on" then
                            snowfall = 1
                        'end if
                    elseif left(lcase(item_tag), 6) = "aurora" then                    
                        aurora = 1
                    elseif left(lcase(item_tag), 15) = "parallax center" then   
                        split item_content,,,pieces()
                        pcenter_x = val(pieces(0)) * 16
                        pcenter_y = val(pieces(1)) * 16
                        hasCenter = 1
                    elseif left(lcase(item_tag), 13) = "default start" then
                        split item_content,,,pieces()
                        default_x = val(pieces(0))
                        default_y = val(pieces(1))
                    elseif left(lcase(item_tag), 5) = "music" then
                        music_file = item_content
                    elseif left(lcase(item_tag), 13) = "light objects" then
                        shouldLight = 1
                    elseif left(lcase(item_tag), 13) = "ambient level" then
                        objectAmbientLevel = val(item_content)
                    elseif left(lcase(item_tag), 20) = "hidden ambient level" then    
                        hiddenObjectAmbientLevel = val(item_content)                        
                    end if
                elseif propertyType = 3 then
                    select case objects(N_objects - 1).object_type
                    case EFFECT
                        if left(lcase(item_tag), 6) = "effect" then 
                            if left(lcase(item_content), 7) = "shimmer" then
                                tempObjEffect->effect_type = SHIMMER
                            elseif left(lcase(item_content), 5) = "smoke" then
                                tempObjEffect->effect_type = SMOKE
                            elseif left(lcase(item_content), 11) = "radar pulse" then
                                tempObjEffect->effect_type = RADAR_PULSE
                            elseif left(lcase(item_content), 4) = "drip" then
                                tempObjEffect->effect_type = DRIP
                            elseif left(lcase(item_content), 17) = "teleporter shield" then
                                tempObjEffect->effect_type = TELEPORTER_SHIELD
                            elseif left(lcase(item_content), 7) = "light 1" then
                                tempObjEffect->effect_type = LIGHT_1 
                            elseif left(lcase(item_content), 7) = "light 2" then
                                tempObjEffect->effect_type = LIGHT_2
                            elseif left(lcase(item_content), 7) = "light 3" then
                                tempObjEffect->effect_type = LIGHT_3   
                            elseif left(lcase(item_content), 7) = "light 4" then
                                tempObjEffect->effect_type = LIGHT_4
                            elseif left(lcase(item_content), 7) = "light 5" then
                                tempObjEffect->effect_type = LIGHT_5   
                            elseif left(lcase(item_content), 7) = "light 6" then
                                tempObjEffect->effect_type = LIGHT_6
                            elseif left(lcase(item_content), 7) = "light 7" then
                                tempObjEffect->effect_type = LIGHT_7   
                            elseif left(lcase(item_content), 7) = "light 8" then
                                tempObjEffect->effect_type = LIGHT_8
                            end if
                        elseif left(lcase(item_tag), 7) = "density" then
                            tempObjEffect->effect_density = val(item_content) * 65535.0
                        elseif left(lcase(item_tag), 9) = "min value" then
                            tempObjEffect->minValue = val(item_content)
                        elseif left(lcase(item_tag), 9) = "max value" then
                            tempObjEffect->maxValue = val(item_content)
                        elseif left(lcase(item_tag), 4) = "fast" then
                            tempObjEffect->fast = 1
                        elseif left(lcase(item_tag), 4) = "mode" then
                            if left(lcase(item_content), 7) = "flicker" then
                                tempObjEffect->mode = MODE_FLICKER
                            elseif left(lcase(item_content), 6) = "toggle" then
                                tempObjEffect->mode = MODE_TOGGLE
                            elseif left(lcase(item_content), 6) = "static" then
                                tempObjEffect->mode = MODE_STATIC
                            end if                        
                        end if
                    case PORTAL
                        if left(lcase(item_tag), 9) = "direction" then 
                            if left(lcase(item_content), 2) = "up" then
                                tempObjPortal->portal_direction = D_UP
                            elseif left(lcase(item_content), 4) = "down" then
                                tempObjPortal->portal_direction = D_DOWN
                            elseif left(lcase(item_content), 4) = "left" then
                                tempObjPortal->portal_direction = D_LEFT
                            elseif left(lcase(item_content), 5) = "right" then
                                tempObjPortal->portal_direction = D_RIGHT
                            elseif left(lcase(item_content), 2) = "in" then
                                tempObjPortal->portal_direction = D_IN                             
                            end if
                        elseif left(lcase(item_tag), 6) = "to map" then
                            tempObjPortal->portal_to_map = item_content
                        elseif left(lcase(item_tag), 9) = "to portal" then
                            tempObjPortal->portal_to_portal = item_content
                        end if
                    case SPAWN
                        if left(lcase(item_tag), 5) = "spawn" then
                            tempObjSpawner->spawn_objectName = item_content
                        elseif left(lcase(item_tag), 7) = "respawn" then
                            if left(lcase(item_content), 5) = "timed" then
                                tempObjSpawner->spawn_respawnType = SPAWN_TIMED
                            elseif left(lcase(item_content), 5) = "once" then
                                tempObjSpawner->spawn_respawnType = SPAWN_ONCE
                            elseif left(lcase(item_content), 5) = "frame" then
                                tempObjSpawner->spawn_respawnType = SPAWN_FRAME
                            end if
                        elseif left(lcase(item_tag), 4) = "time" then
                            tempObjSpawner->spawn_time = val(item_content)
                        elseif left(lcase(item_tag), 5) = "count" then
                            tempObjSpawner->spawn_count = val(item_content)
                        elseif left(lcase(item_tag), 6) = "flavor" then
                            tempObjSpawner->flavor = val(item_content)
                        end if
                    end select  
                elseif propertyType = 4 then
                    if left(lcase(item_tag), 10) = "foreground" then 
                        curObjDepth = FOREGROUND
                    elseif left(lcase(item_tag), 10) = "background" then 
                        curObjDepth = BACKGROUND
                    elseif left(lcase(item_tag), 12) = "active front" then 
                        curObjDepth = ACTIVE_FRONT   
                    elseif left(lcase(item_tag), 12) = "active cover" then 
                        curObjDepth = ACTIVE_COVER
                    elseif left(lcase(item_tag), 6) = "active" then 
                        curObjDepth = ACTIVE           
                    end if
                end if
            end if
        end if
    else
        
        curChar = 1
        while curChar <= len(lne)
            if mid(lne, curChar, 1) = "," then
                ls = left(lne, curChar-1)
                rs = right(lne, len(lne) - curChar)
                lne = ls + rs
            else
                curChar += 1
            end if
        wend

        if right(lne, 1) = "}" then 
            dataline = 0
        else
            split lne,,,pieces()
            for col = 0 to map_width - 1
                layers(N_layers - 1).layer_data[row * map_width + col] = val(pieces(col))
            next col
            row += 1
        end if
        
    end if
loop until itemNestLevel = 0

close #f

print "File parsing complete..."

dim as integer i, q

print map_name
print map_width;", "; map_height
print iif(snowfall = 1, "With snowfall.", "No snowfall.")
print "Tilesets: "; N_tilesets
dim as any ptr tempPtr

for i = 0 to N_tilesets - 1
    print "--------------------------------------"
    print "   ";tilesets(i).set_name
    print "   ";tilesets(i).set_filename
    print "   ";tilesets(i).set_width;", ";tilesets(i).set_height
    print "   ";tilesets(i).set_firstID
    if tilesets(i).tilePropList <> 0 then
        tilesets(i).tilePropList->rollReset()
        do
            tempPtr = tilesets(i).tilePropList->roll()
            if tempPtr <> 0 then
                tempEffect = *cast(tileEffect_t ptr, tempPtr)
                print "--------------------------------------"
                print "      ";tempEffect.tilenum
                print "      ";tempEffect.nextTile
                print "      ";tempEffect.delay
                print "      ";tempEffect.offset
                print "      ";tempEffect.effect
            else
                exit do            
            end if
        loop
    end if
    tilesets(i).used = 0
next i

print
print "Layers: "; N_layers

for i = 0 to N_layers - 1
    print "   ";layers(i).layer_name
    print "   ";layers(i).order
    print "   ";layers(i).depth
    print "   ";layers(i).parallax
    print "   ";layers(i).inRangeSet
    print "   ";layers(i).isDestructible
    print "   ";layers(i).isFallout
next i

Print "Analyzing map contents..."

dim as ushort temp
dim as integer collisionLayer, highTileValue = 0, highCheck

for i = 0 to N_tilesets - 1
    if ucase(left(tilesets(i).set_name, 9)) = "COLLISION" then
        Print "Found Collision set... " & str(i)
        colIndex = tilesets(i).set_firstID
        exit for
    end if
next i



for i = 0 to N_tilesets - 1
    if ucase(left(tilesets(i).set_name, 9)) <> "COLLISION" then
        if tilesets(i).set_firstID > colIndex then
            tilesets(i).set_firstID -= NUM_COLLISION_BLOCKS
        end if
        highCheck = tilesets(i).set_firstID + int(tilesets(i).set_width / 16) * int(tilesets(i).set_height / 16)
        if highCheck > highTileValue then highTileValue = highCheck
    end if
next i

for i = 0 to N_layers - 1
    if ucase(left(layers(i).layer_name, 9)) <> "COLLISION" then
        for q = 0 to map_width*map_height - 1
            if (layers(i).layer_data[q] and &h1fffffff) > colIndex then
                layers(i).layer_data[q] = ((layers(i).layer_data[q] and &h1fffffff) - NUM_COLLISION_BLOCKS) or (layers(i).layer_data[q] and &hE0000000)
            end if
        next q
    else
        Print "Found Collision layer... " & str(i)
        collisionLayer = i
        for q = 0 to map_width*map_height - 1
            if layers(i).layer_data[q] > 0 then 
                layers(i).layer_data[q] = (layers(i).layer_data[q] and &h1fffffff) - (colIndex - 1) 
            end if
        next q
    end if
next i



dim as integer numMerged, newTileNum, tn, xtn, ytn, rt
dim as integer xpn, ypn

#define X_ 0
#define Y_ 1

dim as uinteger ptr src
dim as integer ppos(0 to 1)
dim as integer pdes(0 to 1)
dim as integer pdir(0 to 1)
dim as integer ptr ptile(0 to 1)
dim as integer byCol, byRow, oldCol
dim as integer xpos, ypos, w

redim as integer ptr setImages(N_tilesets)
redim as integer ptr setImages_norm(N_tilesets)
dim as string normFilename

dim as HashTable combinedTiles
dim as HashTable rotatedTiles
dim as integer foundOneRotated = 0
dim as integer curRotatedHeight = 1024
dim as integer ptr tempRotatedImg
dim as integer finalHeight, j
dim as integer N_rotated = 0
dim as integer tileNum, curSet, newRTile

rotatedTiles.init(sizeof(integer))

for i = 0 to N_tilesets - 1
    if right(tilesets(i).set_filename, 3) = "bmp" then
        setImages(i) = imagecreate(tilesets(i).set_width, tilesets(i).set_height)
        bload tilesets(i).set_filename, setImages(i)
    else
        setImages(i) = png_load(tilesets(i).set_filename)
    end if
    
    normFilename = left(tilesets(i).set_filename, len(tilesets(i).set_filename) - 4) + "_surface"
    if fileexists(normFilename + ".bmp") then
        setImages_norm(i) = imagecreate(tilesets(i).set_width, tilesets(i).set_height)
        bload normFilename+".bmp", setImages_norm(i)        
    elseif fileexists(normFilename + ".png") then
        setImages_norm(i) = png_load(normFilename+".png")
    else
        setImages_norm(i) = imagecreate(tilesets(i).set_width, tilesets(i).set_height)
    end if
next i
N_tilesets += 1
setImages(N_tilesets - 1) = imagecreate(320, curRotatedHeight)
setImages_norm(N_tilesets - 1) = imagecreate(320, curRotatedHeight)
redim preserve as set_t tilesets(0 to N_tilesets-1)

tilesets(N_tilesets - 1).set_name     = map_name + "_rotated"
tilesets(N_tilesets - 1).set_filename = map_name + "_rotated.png"
tilesets(N_tilesets - 1).set_firstID  = highTileValue
tilesets(N_tilesets - 1).tilePropList = 0
tilesets(N_tilesets - 1).set_width = 320

for i = 0 to N_layers - 1
    if i <> collisionLayer then
        for q = 0 to map_width*map_height - 1
            if layers(i).layer_data[q] and &hE0000000 then
                if rotatedTiles.exists(layers(i).layer_data[q]) = 0 then
                    
                    foundOneRotated = 1
                    
                    tileNum = layers(i).layer_data[q] and &h1FFFFFFF
                    
                    for j = N_tilesets - 1 to 0 step -1
                        if tileNum >= tilesets(j).set_firstID then
                            curSet = j
                            exit for
                        end if
                    next j
                    
                    tileNum -= tilesets(curSet).set_firstID
                    
                    tn = tileNum
                    rt = layers(i).layer_data[q] shr 29
                    xtn = (tn * 16) mod ((tilesets(curSet).set_width \ 16) * 16)
                    ytn = int((tn * 16) / ((tilesets(curSet).set_width \ 16) * 16)) * 16 
                    xpn = ((N_rotated) mod 20) * 16
                    ypn = int((N_rotated) / 20) * 16
 
                    if rt = 0 then
                        put setImages(N_tilesets - 1), (xpn, ypn), setImages(curSet), (xtn, ytn)-(xtn+15, ytn+15), PSET
                    else
                        ptile(X_) = @xtn
                        ptile(Y_) = @ytn
                        ppos(X_) = xpn
                        ppos(Y_) = ypn
                        pdes(X_) = xpn
                        pdes(Y_) = ypn
                        select case rt
                        case 7
                            byRow = X_
                            byCol = Y_
                            ppos(byRow) += 15
                            ppos(byCol) += 15
                            pdes(byRow) += -1
                            pdes(byCol) += -1
                            pdir(byRow) = -1
                            pdir(byCol) = -1
                        case 2
                            byRow = Y_
                            byCol = X_
                            ppos(byRow) += 15
                            ppos(byCol) += 0
                            pdes(byRow) += -1
                            pdes(byCol) += 16
                            pdir(byRow) = -1
                            pdir(byCol) = 1
                        case 3
                            byRow = X_
                            byCol = Y_
                            ppos(byRow) += 0
                            ppos(byCol) += 15
                            pdes(byRow) += 16
                            pdes(byCol) += -1
                            pdir(byRow) = 1
                            pdir(byCol) = -1
                        case 4
                            byRow = Y_
                            byCol = X_
                            ppos(byRow) += 0
                            ppos(byCol) += 15
                            pdes(byRow) += 16
                            pdes(byCol) += -1
                            pdir(byRow) = 1
                            pdir(byCol) = -1
                        case 5
                            byRow = X_
                            byCol = Y_
                            ppos(byRow) += 15
                            ppos(byCol) += 0
                            pdes(byRow) += -1
                            pdes(byCol) += 16
                            pdir(byRow) = -1
                            pdir(byCol) = 1
                        case 6
                            byRow = Y_
                            byCol = X_
                            ppos(byRow) += 15
                            ppos(byCol) += 15
                            pdes(byRow) += -1
                            pdes(byCol) += -1
                            pdir(byRow) = -1
                            pdir(byCol) = -1
                        case 1
                            byRow = X_
                            byCol = Y_
                            ppos(byRow) += 0
                            ppos(byCol) += 0
                            pdes(byRow) += 16
                            pdes(byCol) += 16
                            pdir(byRow) = 1
                            pdir(byCol) = 1
                        end select
                        ypos = ytn
                        oldCol = ppos(byCol)
                        
                        dim as integer test = 0
                        
                        while ppos(byRow) <> pdes(byRow)
                            ppos(byCol) = oldCol
                            xpos = xtn
                            while ppos(byCol) <> pdes(byCol)
                                
                                col = point(xpos, ypos, setImages(curSet))'setImages(curSet)[8 + xpos + ypos*tilesets(curSet).set_width]
             
                                if col <> &hffff00ff then 
                                    setImages(N_tilesets - 1)[8 + ppos(X_) + ppos(Y_) * 320] = col
                                end if
                                setImages_norm(N_tilesets - 1)[8 + ppos(X_) + ppos(Y_) * 320] = point(xpos, ypos, setImages_norm(curSet))
                                
                                ppos(byCol) += pdir(byCol)
                                xpos += 1
                            wend
                            ppos(byRow) += pdir(byRow)
                            ypos += 1
                        wend
                    
                    end if  
                    newRTile = highTileValue + N_rotated
                    rotatedTiles.insert(layers(i).layer_data[q], @newRTile)
                    layers(i).layer_data[q] = newRTile
                    N_rotated += 1
                else
                    layers(i).layer_data[q] = *cast(integer ptr, rotatedTiles.retrieve(layers(i).layer_data[q]))
                end if
                
            end if
        next q
    end if
next i
'32x21
if foundOneRotated = 0 then 
    imagedestroy(setImages(N_tilesets - 1))
    imagedestroy(setImages_norm(N_tilesets - 1))
    N_tilesets -= 1
else
    tilesets(N_tilesets - 1).set_width = 320
    curRotatedHeight = (int(N_rotated / 20) + 1) * 16
    tilesets(N_tilesets - 1).set_height = curRotatedHeight
    tilesets(N_tilesets - 1).used = 0
    
    tempRotatedImg = imagecreate(320, curRotatedHeight)
    put tempRotatedImg,(0,0), setImages(N_tilesets - 1), (0,0)-(319, curRotatedHeight - 1), PSET
    imagedestroy(setImages(N_tilesets - 1))
    setImages(N_tilesets - 1) = tempRotatedImg
    
    tempRotatedImg = imagecreate(320, curRotatedHeight)
    put tempRotatedImg,(0,0), setImages_norm(N_tilesets - 1), (0,0)-(319, curRotatedHeight - 1), PSET
    imagedestroy(setImages_norm(N_tilesets - 1))
    setImages_norm(N_tilesets - 1) = tempRotatedImg    
    
    highTileValue += 20 * int(curRotatedHeight / 16)
end if



dim as ushort curRange

'can merge when 
curRange = ACTIVE

#define ILLUMINATED_MASK &h01
#define FALLOUT_MASK &h02
#define DESTRUCTIBLE_MASK &h04
#define COVERAGE_MASK &h08
#define PARALLAX_MASK &h10
#define MERGELESS_MASK &h20
#define NONE_MASK &h00
#define RECEIVER_MASK &h40
#define OCCLUDING_MASK &h80

type mergeStack_t
    as integer ptr mask
    as integer ptr image
    as integer ptr image_norm
    as integer     flags
    as single      depth
    as integer     ambientLevel
    as integer     layer
    as integer     newTile
    as integer     tileset
    as integer     tileNum
end type


'-------------------------------
type imageTilePair_t
    as integer tilenum
    as integer ptr image   
    as integer ptr image_norm
end type
type auxTable_t
    as Hashtable   hashedImageLists
    as integer set_width
    as integer set_height
    as integer set_firstID
    as integer set_num
end type
'--------------------------------

dim as integer curLayer, nextLayer, minID, N_merges, tempData, imgTag
dim as integer tilesetA, tilesetB, canMerge, mustMerge, highTile
dim as tileEffect_t ptr animA, animB, effectPtr
dim as integer tileA, tileB, foundMergeLayer, didMerge, fullCover
dim as string searchKey

dim as mergeStack_t tempStackItem
dim as integer N_runs = 0, curFlags, pushRun = 0, findFullCoverage, deleteTile
dim as integer ptr curMask, coverageMask, foMask, dMask, sMask, curImage, tempMaskImg, storeImg, curImage_norm, storeImg_norm
dim as integer stackPos, tileX, tileY, remInd, isAnim, animSearch, firstInLoop, activeLayer
dim as integer ptr cmpImg(0 to 1)
dim as integer tileEmpty, maskComp, numTilesSet
stackPos = 0
redim as mergeStack_t mergeStack(N_runs)
dim as any ptr rollReturn
dim as Hashtable curListHash
dim as List tilesetListHashes
dim as List ptr tempTileList
dim as auxTable_t ptr tempTable
dim as imageTilePair_t ptr tempITPair
dim as integer ptr curAtlas, curAtlas_norm
dim curfile as string
dim as string setname
dim f2 as integer = freefile
dim as integer ptr curTilePtr, curTilePtr_norm

curTilePtr = imagecreate(16,16)
curTilePtr_norm = imagecreate(16,16)

tilesetListHashes.init(sizeof(auxTable_t ptr))

print "Loading external tilesets..."
curfile = Dir("tilesets\*", fbNormal )
Do
    if left(right(curfile, 11), 7) = "_merged" then
        if right(curfile, 3) = "png" then
            curAtlas = png_load("tilesets\" & curfile)
        else
            curAtlas = imagecreate(320,4096)
            bload "tilesets\" & curfile, curAtlas
        end if
        
        normFilename = left(curfile, len(curfile) - 4) + "_norm"
        if fileexists(normFilename+".bmp") then
            curAtlas_norm = imagecreate(320,4096)
            bload "tilesets\" & normFilename & ".bmp", curAtlas_norm           
        elseif fileexists(normFilename+".png") then
            curAtlas_norm = png_load("tilesets\" & normFilename & ".png")
        else
            curAtlas_norm = imagecreate(320,4096)
        end if
        
        tileA = 0
        
        tempTable = new auxTable_t
        tempTable->set_width = 320
        tempTable->set_firstID = highTileValue
        tempTable->hashedImageLists.init(sizeof(List ptr))
        numTilesSet = 0
        do
            tileX = (tileA mod 20) * 16
            tileY = int(tileA / 20) * 16
            
            put curTilePtr, (0,0), curAtlas, (tileX,tileY)-(tileX+15,tileY+15), PSET
            put curTilePtr_norm, (0,0), curAtlas_norm, (tileX,tileY)-(tileX+15,tileY+15), PSET
            
            if imageIsNotEmpty(curTilePtr) then
                imgTag = hashImage(curTilePtr)
                tempITPair = new imageTilePair_t
                tempITPair->tilenum = highTileValue + numTilesSet
                
                tempITPair->image = imagecreate(16,16)
                tempITPair->image_norm = imagecreate(16,16)
                put tempITPair->image, (0,0), curTilePtr, PSET
                put tempITPair->image_norm, (0,0), curTilePtr_norm, PSET

                numTilesSet += 1
                if tempTable->hashedImageLists.exists(imgTag) then
                    tempTileList = *cast(List ptr ptr, tempTable->hashedImageLists.retrieve(imgTag))
                    tempTileList->push_back(@tempITPair)
                else
                    tempTileList = new List
                    tempTileList->init(sizeof(imageTilePair_t ptr))
                    tempTileList->push_back(@tempITPair)
                    tempTable->hashedImageLists.insert(imgTag, @tempTileList)
                end if
            else
                exit do
            end if
            tileA += 1
        loop
        tempTable->set_height = (int(numTilesSet / 20) + 1) * 16
        highTileValue += 20 * int(tempTable->set_height / 16)
        
        
        N_tilesets += 1
        redim preserve as set_t tilesets(N_tilesets - 1)
        with tilesets(N_tilesets - 1)
            setname = left(curfile, instr(curfile, ".") - 1)
            .set_name = setname
            .set_filename = curfile
            .set_width = tempTable->set_width
            .set_height = tempTable->set_height
            .set_firstID = tempTable->set_firstID
            .used = 0
            .tilePropList = 0
        end with        
        
        tempTable->set_num = N_tilesets - 1
        tilesetListHashes.push_back(@tempTable)
        
        imagedestroy(curAtlas)
    end if
    curfile = Dir( )
Loop While Len( curfile ) > 0

print "Computing optimal layers and merges..."

curListHash.init(sizeof(List ptr))

N_merges = 0
foMask = imagecreate(16, 16, 0)
dMask = imagecreate(16, 16, 0)
sMask = imagecreate(16, 16, 0)
curMask = imagecreate(16, 16, 0)
coverageMask = imagecreate(16, 16, 0)
curImage = imagecreate(16,16,0)
curImage_norm = imagecreate(16,16,0)
tempMaskImg = imagecreate(16,16,0)
cmpImg(0) = imagecreate(16,16,0)
cmpImg(1) = imagecreate(16,16,0)

dim as integer ptr mergedTiles = imagecreate(320, 4096)
dim as integer ptr mergedTiles_norm = imagecreate(320, 4096)

print
print
for activeLayer = 0 to 4
    select case activeLayer
    case 0
        curRange = BACKGROUND
    case 1
        curRange = ACTIVE
    case 2
        curRange = ACTIVE_COVER
    case 3
        curRange = FOREGROUND
    case 4
        curRange = ACTIVE_FRONT
    end select
    for q = 0 to map_width*map_height - 1
        locate Csrlin - 2, 1: print space(20)
        locate Csrlin - 1, 1: print "Progress... " & str(int(((q + (map_width*map_height) * activeLayer)  / (map_width * map_height * 4 - 1)) * 100)) & "%"
        print "Refactored tiles: " & str(N_merges)
        N_runs = 0
        for i = N_layers - 1 to 0 step -1
            if i <> collisionLayer andAlso layers(i).inRangeSet = curRange then
                if layers(i).layer_data[q] <> 0 then
                    
                    tileNum = layers(i).layer_data[q]
                    for j = N_tilesets - 1 to 0 step -1
                        if tileNum >= tilesets(j).set_firstID then
                            curSet = j
                            tileNum -= tilesets(j).set_firstID
                            exit for
                        end if
                    next j
                    tileX = (tileNum * 16) mod ((tilesets(curSet).set_width \ 16) * 16)
                    tileY = int((tileNum * 16) / ((tilesets(curSet).set_width \ 16) * 16)) * 16
                    
                    put curImage, (0,0), setImages(curSet), (tileX, tileY)-(tileX+15, tileY+15), PSET
                    put curImage_norm, (0,0), setImages_norm(curSet), (tileX, tileY)-(tileX+15, tileY+15), PSET

                    if imageIsNotEmpty(curImage) then
                                        
                        curFlags = iif(layers(i).illuminated < 65535, ILLUMINATED_MASK, NONE_MASK) OR _
                                   iif(layers(i).isFallout < 65535, FALLOUT_MASK, NONE_MASK) OR _
                                   iif(layers(i).isDestructible < 65535, DESTRUCTIBLE_MASK, NONE_MASK) OR _
                                   iif(layers(i).coverage < 65535, COVERAGE_MASK, NONE_MASK) OR _
                                   iif(layers(i).parallax < 65535, PARALLAX_MASK, NONE_MASK)  OR _
                                   iif(layers(i).mergeless < 65535, MERGELESS_MASK, NONE_MASK) OR _
                                   iif(layers(i).isReceiver < 65535, RECEIVER_MASK, NONE_MASK) OR _
                                   iif(layers(i).occluding < 65535, OCCLUDING_MASK, NONE_MASK) 

                        
                        line curMask, (0,0)-(15,15),0, BF
                    
                        isAnim = 0
                        animSearch = tileNum
                        firstInLoop = tileNum
                        if tilesets(curSet).tilePropList then
                            do
                                tilesets(curSet).tilePropList->rollReset()
                                do
                                    tempEffectPtr = tilesets(curSet).tilePropList->roll()
                                    if tempEffectPtr then
                                        if animSearch = tempEffectPtr->tilenum then 
                                            isAnim = 1
                                            extractMask(tempMaskImg, setImages(curSet), _
                                                        (animSearch * 16) mod ((tilesets(curSet).set_width \ 16) * 16), _
                                                        int((animSearch * 16) / ((tilesets(curSet).set_width \ 16) * 16)) * 16)
                                            put curMask, (0,0), tempMaskImg, OR
                                            animSearch += tempEffectPtr->nextTile
                                            exit do
                                        end if
                                    else
                                        animSearch = -1
                                        exit do
                                    end if
                                loop
                            loop until (animSearch = -1) or (animSearch = firstInLoop)
                        end if
                        if isAnim = 0 then 
                            extractMask(curMask, setImages(curSet), tileX, tileY)
                        end if
                        pushRun = 1
                        
                        findFullCoverage = 0
                        line coverageMask, (0,0)-(15,15), 0, BF
                        line foMask, (0,0)-(15,15), 0, BF
                        line dMask, (0,0)-(15,15), 0, BF
                        line sMask, (0,0)-(15,15), 0, BF
                        
                        if (not (curFlags and MERGELESS_MASK)) andAlso (isAnim = 0) then
                            for j = N_runs - 1 to 0 step -1                            
                                if (mergeStack(j).depth <> layers(i).depth) then
                                    findFullCoverage = 1
                                else    
                                    
                                    if (not (mergeStack(j).flags and MERGELESS_MASK)) andAlso (mergeStack(j).newTile = 1) then
                                        if (mergeStack(j).ambientLevel = layers(i).ambientLevel) andALso _
                                           (mergeStack(j).flags = curFlags) andAlso _
                                           (findFullCoverage = 0) then    
                                            
                                            if maskCompare(coverageMask, mergeStack(j).mask) = DISJOINT then                                                
                                                if N_runs > 1 then
                                                    tempStackItem = mergeStack(j)
                                                    for remInd = j to N_runs-2
                                                        mergeStack(remInd) = mergeStack(remInd + 1)
                                                    next remInd
                                                    mergeStack(N_runs - 1) = tempStackItem
                                                end if
                                                
                                                layers(mergeStack(N_runs - 1).layer).layer_data[q] = 0
                                                
                                                mergeStack(N_runs - 1).layer = i
                                                put mergeStack(N_runs - 1).mask, (0,0), curMask, OR
                                                
                                                put curImage, (0,0), mergeStack(N_runs - 1).image, TRANS
                                                put curImage_norm, (0,0), mergeStack(N_runs - 1).image_norm, TRANS

                                                put mergeStack(N_runs - 1).image, (0,0), curImage, PSET
                                                put mergeStack(N_runs - 1).image_norm, (0,0), curImage_norm, PSET                                                
                                                                                            
                                                pushRun = 0
                                                exit for
                                            end if
                                        end if
                                    end if
        
                                    put coverageMask, (0,0), mergeStack(j).mask, OR
                                    if mergeStack(j).flags and FALLOUT_MASK then put foMask, (0,0), mergeStack(j).mask, OR
                                    if mergeStack(j).flags and DESTRUCTIBLE_MASK then put dMask, (0,0), mergeStack(j).mask, OR
                                    if ((mergeStack(j).flags and DESTRUCTIBLE_MASK) = 0) and _
                                       ((mergeStack(j).flags and FALLOUT_MASK) = 0) then 
                                        put sMask, (0,0), mergeStack(j).mask, OR 
                                        put foMask, (0,0), mergeStack(j).mask, OR 
                                        put dMask, (0,0), mergeStack(j).mask, OR 
                                    end if
                                    deleteTile = 0
                                    if (curFlags and DESTRUCTIBLE_MASK) and (curFlags and FALLOUT_MASK) then
                                        maskComp = maskCompare(curMask, coverageMask)
                                        if findFullCoverage = 0 then
                                            if maskComp = COVERING orElse maskComp = FULL_COVERING then deleteTile = 1
                                        else
                                            if maskComp = FULL_COVERING then deleteTile = 1
                                        end if
                                    elseif (curFlags and DESTRUCTIBLE_MASK) then
                                        maskComp = maskCompare(curMask, dMask)
                                        if findFullCoverage = 0 then
                                            if maskComp = COVERING orElse maskComp = FULL_COVERING then deleteTile = 1
                                        else
                                            if maskComp = FULL_COVERING then deleteTile = 1
                                        end if
                                    elseif (curFlags and FALLOUT_MASK) then
                                        maskComp = maskCompare(curMask, foMask)
                                        if findFullCoverage = 0 then
                                            if maskComp = COVERING orElse maskComp = FULL_COVERING then deleteTile = 1
                                        else
                                            if maskComp = FULL_COVERING then deleteTile = 1
                                        end if
                                    else
                                        maskComp = maskCompare(curMask, sMask)
                                        if findFullCoverage = 0 then
                                            if maskComp = COVERING orElse maskComp = FULL_COVERING then deleteTile = 1
                                        else
                                            if maskComp = FULL_COVERING then deleteTile = 1
                                        end if
                                        
                                    end if
                                end if
                                if deleteTile = 1 then
                                    
                                    layers(i).layer_data[q] = 0

                                    pushRun = 0
                                    exit for
                                end if
                        
                            next j
                        end if
                            
                        if pushRun = 1 then
                            N_runs += 1
                            redim preserve as mergeStack_t mergeStack(N_runs - 1)
                            mergeStack(N_runs - 1).layer = i
                            mergeStack(N_runs - 1).mask = imagecreate(16,16,0)
                            mergeStack(N_runs - 1).depth = layers(i).depth
                            mergeStack(N_runs - 1).ambientLevel = layers(i).ambientLevel
                            mergeStack(N_runs - 1).flags = curFlags
                            mergeStack(N_runs - 1).image = imagecreate(16, 16, 0)
                            mergeStack(N_runs - 1).image_norm = imagecreate(16, 16, 0)                            
                            
                            if isAnim = 1 then
                                mergeStack(N_runs - 1).newTile = 0
                                mergeStack(N_runs - 1).tileset = curSet
                                tilesets(curSet).used = 1
                                mergeStack(N_runs - 1).tilenum = layers(i).layer_data[q]
                            else
                                mergeStack(N_runs - 1).newTile = 1
                            end if
                            put mergeStack(N_runs - 1).image_norm, (0,0), curImage_norm, PSET                            
                            put mergeStack(N_runs - 1).image, (0,0), curImage, PSET
                            put mergeStack(N_runs - 1).mask, (0,0), curMask, OR

                        end if
                    else
                        tileEmpty = 1
                    end if
                else
                    tileEmpty = 1
                end if
                if tileEmpty = 1 then
                    curFlags = iif(layers(i).illuminated < 65535, ILLUMINATED_MASK, NONE_MASK) OR _
                               iif(layers(i).isFallout < 65535, FALLOUT_MASK, NONE_MASK) OR _
                               iif(layers(i).isDestructible < 65535, DESTRUCTIBLE_MASK, NONE_MASK) OR _
                               iif(layers(i).coverage < 65535, COVERAGE_MASK, NONE_MASK) OR _
                               iif(layers(i).parallax < 65535, PARALLAX_MASK, NONE_MASK)  OR _
                               iif(layers(i).mergeless < 65535, MERGELESS_MASK, NONE_MASK) OR _
                               iif(layers(i).isReceiver < 65535, RECEIVER_MASK, NONE_MASK) OR _
                               iif(layers(i).occluding < 65535, OCCLUDING_MASK, NONE_MASK) 

                    line coverageMask, (0,0)-(15,15), 0, BF
                    layers(i).layer_data[q] = 0
                    for j = N_runs - 1 to 0 step -1
                        if (mergeStack(j).depth <> layers(i).depth) then
                            exit for
                        else    
                            if (not (mergeStack(j).flags and MERGELESS_MASK)) andAlso (mergeStack(j).newTile = 1) then
                                if (mergeStack(j).ambientLevel = layers(i).ambientLevel) andALso _
                                   (mergeStack(j).flags = curFlags) then
                                    if maskCompare(coverageMask, mergeStack(j).mask) = DISJOINT then
                                        
                                        if N_runs > 1 then
                                            tempStackItem = mergeStack(j)
                                            for remInd = j to N_runs-2
                                                mergeStack(remInd) = mergeStack(remInd + 1)
                                            next remInd
                                            mergeStack(N_runs - 1) = tempStackItem
                                        end if
                                        layers(mergeStack(N_runs - 1).layer).layer_data[q] = 0
                                        mergeStack(N_runs - 1).layer = i
                                        exit for
                                    end if
                                end if
                            end if
                            
                            put coverageMask, (0,0), mergeStack(j).mask, OR
                                
                        end if
                    next j
                end if
                
            end if
        next i
                
        for j = 0 to N_runs - 1
            if mergeStack(j).newTile = 1 then
                imgTag = hashImage(mergeStack(j).image)
                canMerge = 1 
                if tilesetListHashes.getSize() <> 0 then
                    tilesetListHashes.rollReset()
                    do
                        rollReturn = tilesetListHashes.roll()
                        if rollReturn then
                            tempTable = *cast(auxTable_t ptr ptr, rollReturn)
                            if tempTable->hashedImageLists.exists(imgTag) then
                                tempTileList = *cast(List ptr ptr, tempTable->hashedImageLists.retrieve(imgTag))
                                tempTileList->rollReset()
                                do
                                    rollReturn = tempTileList->roll()
                                    if rollReturn then
                                        tempITPair = *cast(imageTilePair_t ptr ptr, rollReturn)
                                        if equalImages(tempITPair->image, mergeStack(j).image) then
                                        
                                            layers(mergeStack(j).layer).layer_data[q] = tempITPair->tilenum
                                            tilesets(tempTable->set_num).used = 1
                                            canMerge = 0
                                            exit do
                                            
                                        end if
                                    else
                                        exit do
                                    end if
                                loop
                            end if
                        else
                            exit do
                        end if
                    loop while canMerge = 1
                end if
                
                
                if canMerge = 1 then
                    if curListHash.exists(imgTag) then
                        tempTileList = *cast(List ptr ptr, curListHash.retrieve(imgTag))
                        tempTileList->rollReset()
                        do
                            rollReturn = tempTileList->roll()
                            if rollReturn then
                                tempITPair = *cast(imageTilePair_t ptr ptr, rollReturn)
                                
                                if equalImages(tempITPair->image, mergeStack(j).image) then
                                    
                                    layers(mergeStack(j).layer).layer_data[q] = highTileValue + tempITPair->tilenum
                                    exit do
                                    
                                end if
                            else
                                put mergedTiles, ((N_merges mod 20) * 16, (N_merges \ 20) * 16), mergeStack(j).image, PSET
                                put mergedTiles_norm, ((N_merges mod 20) * 16, (N_merges \ 20) * 16), mergeStack(j).image_norm, PSET                                
                                
                                N_merges += 1
                                
                                tempITPair = new imageTilePair_t
                                tempITPair->image = imagecreate(16,16)
                                tempITPair->image_norm = imagecreate(16,16)
                                put tempITPair->image, (0,0), mergeStack(j).image, PSET
                                put tempITPair->image_norm, (0,0), mergeStack(j).image_norm, PSET                                
                                tempITPair->tilenum = N_merges - 1
                                tempTileList->push_back(@tempITPair)
                                
                                layers(mergeStack(j).layer).layer_data[q] = highTileValue + tempITPair->tilenum
    
                                exit do
                            end if
                        loop
                    else
                        put mergedTiles, ((N_merges mod 20) * 16, (N_merges \ 20) * 16), mergeStack(j).image, PSET
                        put mergedTiles_norm, ((N_merges mod 20) * 16, (N_merges \ 20) * 16), mergeStack(j).image_norm, PSET

                        N_merges += 1
                        
                        tempTileList = new List
                        tempTileList->init(sizeof(imageTilePair_t ptr))
                        
                        tempITPair = new imageTilePair_t
                        tempITPair->image = imagecreate(16,16)
                        tempITPair->image_norm = imagecreate(16,16)                        
                        put tempITPair->image, (0,0), mergeStack(j).image, PSET
                        put tempITPair->image_norm, (0,0), mergeStack(j).image_norm, PSET                        
                        tempITPair->tilenum = N_merges - 1
                        
                        tempTileList->push_back(@tempITPair)
                        curListHash.insert(imgTag, @tempTileList)
                        
                        layers(mergeStack(j).layer).layer_data[q] = highTileValue + tempITPair->tilenum
                    end if
                end if
            else
                layers(mergeStack(j).layer).layer_data[q] = mergeStack(j).tilenum
            end if
        next j
    next q
next activeLayer

tempRotatedImg = imagecreate(320, (int(N_merges / 20) + 1) * 16)
put tempRotatedImg, (0,0), mergedTiles, (0,0)-(319, (int(N_merges / 20) + 1) * 16 - 1), PSET
swap tempRotatedImg, mergedTiles
imagedestroy tempRotatedImg

tempRotatedImg = imagecreate(320, (int(N_merges / 20) + 1) * 16)
put tempRotatedImg, (0,0), mergedTiles_norm, (0,0)-(319, (int(N_merges / 20) + 1) * 16 - 1), PSET
swap tempRotatedImg, mergedTiles_norm
imagedestroy tempRotatedImg

dim as integer newOrder = 0
dim as ushort newLayersNum = 0
dim as integer deletedLayers = 0

for i = 0 to N_layers - 1
    layers(i).empty = 1
    for q = 0 to map_width*map_height - 1
        if layers(i).layer_data[q] <> 0 orElse layers(i).mergeless = 1 then 
            layers(i).empty = 0
            layers(i).order = newOrder 
            newOrder += 1
            newLayersNum += 1
            exit for
        end if
    next q 
    if layers(i).empty = 1 then deletedLayers += 1
next i

print "Deleted " & str(deletedLayers) & " of " & str(N_layers) & " layers."


dim as integer ptr tempImg, alphaImg
if N_merges > 0 then
    N_tilesets += 1
    redim preserve as set_t tilesets(N_tilesets - 1)
    with tilesets(N_tilesets - 1)
        .set_name = map_name + "_merged"
        .set_filename = map_name + "_merged.png"
        .set_width = 320
        .set_height = (int(N_merges / 20) + 1) * 16
        .set_firstID = highTileValue
        .used = 1
        .tilePropList = 0
        
             
        tempImg = imagecreate(.set_width, .set_height)
        alphaImg = imagecreate(.set_width, .set_height)
        put tempImg, (0,0), mergedTiles_norm, (0,0)-(.set_width-1,.set_height-1), PSET
        line alphaImg, (0,0)-(.set_width-1, .set_height-1), &hff000000, BF
        put tempImg, (0,0), alphaImg, OR        
        line alphaImg, (0,0)-(.set_width-1, .set_height-1), &hff008080, BF
        put alphaImg, (0,0), tempImg, TRANS 
        bsave "tilesets\" & .set_name & "_norm" & ".bmp", alphaImg
        imageDestroy(tempImg)
        imagedestroy(alphaImg)
        

        tempImg = imagecreate(.set_width, .set_height)
        put tempImg, (0,0), mergedTiles, (0,0)-(.set_width-1,.set_height-1), PSET
        alphaImg = imagecreate(.set_width, .set_height)
        line alphaImg, (0,0)-(.set_width-1, .set_height-1), &hff000000, BF
        put tempImg, (0,0), alphaImg, OR
        png_save("tilesets\" & .set_filename, tempImg)
        imageDestroy(tempImg)
        imagedestroy(alphaImg)

    end with
end if

imagedestroy(mergedTiles)
imagedestroy(mergedTiles_norm)

print "Refactoring tile instances..."
dim as integer ptr tempTilesetCopy
dim as ushort totalSets = 0

for i = 0 to N_tilesets - 1
    if ucase(left(tilesets(i).set_name, 9)) <> "COLLISION" then
        if tilesets(i).used = 0 then
            highTile = int(tilesets(i).set_width / 16) * int(tilesets(i).set_height / 16)
            for j = 0 to N_layers - 1
                if layers(j).empty = 0 andALso ucase(left(layers(j).layer_name, 9)) <> "COLLISION" then
                    for q = 0 to map_width * map_height - 1
                        if layers(j).layer_data[q] >= tilesets(i).set_firstID then
                            layers(j).layer_data[q] -= highTile
                        end if
                    next q
                end if
            next j
            for j = i + 1 to N_tilesets - 1
                if ucase(left(tilesets(j).set_name, 9)) <> "COLLISION" then
                    tilesets(j).set_firstID -= highTile
                end if
            next j
        else
            if not FileExists("tilesets\" & tilesets(i).set_filename) then
                
                if right(tilesets(i).set_filename, 3) = "bmp" then
                    tempTilesetCopy = imagecreate(tilesets(i).set_width, tilesets(i).set_height)
                    bload tilesets(i).set_filename, tempTilesetCopy
                else
                    tempTilesetCopy = png_load(tilesets(i).set_filename)
                end if
                    
                png_save("tilesets\" & tilesets(i).set_filename, tempTilesetCopy)
                imagedestroy tempTilesetCopy
            end if
            totalSets += 1
        end if
        
    end if
    tilesets(i).set_filename = "tilesets\" & tilesets(i).set_filename
next i

if hasCenter = 0 then
    pcenter_x = map_width * 0.5 * 16
    pcenter_y = map_height * 0.5 * 16
end if



Print "Using " & str(totalSets) & " tilesets..."

print "Writing file..."

f = freefile

open map_name + ".map" for binary as #f
put #f,,map_name
put #f,,map_width
put #f,,map_height
put #f,,snowfall
put #f,,aurora
put #f,,shouldLight
put #f,,objectAmbientLevel
put #f,,hiddenObjectAmbientLevel
put #f,,default_x
put #f,,default_y
put #f,,pcenter_x
put #f,,pcenter_y 
put #f,,music_file
put #f,,totalSets
for i = 0 to N_tilesets - 1
    if (ucase(left(tilesets(i).set_name, 9))) <> "COLLISION" andAlso (tilesets(i).used = 1) then
        put #f,,tilesets(i).set_name
        put #f,,tilesets(i).set_filename
        put #f,,tilesets(i).set_width
        put #f,,tilesets(i).set_height
        put #f,,tilesets(i).set_firstID
        if tilesets(i).tilePropList = 0 then
            temp = 0
            put #f,,temp
        else
            temp = tilesets(i).tilePropList->getSize()
            put #f,,temp
            tilesets(i).tilePropList->rollReset()
            do
                tempPtr = tilesets(i).tilePropList->roll()
                if tempPtr <> 0 then
                    tempEffect = *cast(tileEffect_t ptr, tempPtr)
                    put #f,,tempEffect.tilenum
                    put #f,,tempEffect.effect
                    put #f,,tempEffect.nextTile
                    put #f,,tempEffect.delay
                    put #f,,tempEffect.offset
                else
                    exit do
                end if
            loop
        end if
    end if
next i 
put #f,,newLayersNum
Print "Writing layers..."




for i = 0 to N_layers - 1
    if layers(i).empty = 0 then
        if ucase(left(layers(i).layer_name, 9)) <> "COLLISION" then
            put #f,,layers(i).layer_name
            put #f,,layers(i).order
            put #f,,layers(i).depth
            put #f,,layers(i).parallax
            put #f,,layers(i).inRangeSet
            put #f,,layers(i).isDestructible
            put #f,,layers(i).isFallout
            put #f,,layers(i).illuminated
            put #f,,layers(i).ambientLevel
            put #f,,layers(i).coverage
            put #f,,layers(i).isReceiver
            put #f,,layers(i).occluding
            put #f,,layers(i).layer_data[0],map_width*map_height
        else
            put #f,,layers(i).layer_name
            put #f,,layers(i).layer_data[0],map_width*map_height
        end if
    end if
next i 

put #f,,N_objects
for i = 0 to N_objects - 1
    with objects(i)
        put #f,,.object_name
        put #f,,.object_type
        put #f,,.object_shape
        put #f,,.inRangeSet
        put #f,,.p
        put #f,,.size
        select case .object_type
        case EFFECT
            tempObjEffect = .data_
            put #f,,tempObjEffect->effect_type
            put #f,,tempObjEffect->effect_density
            put #f,,tempObjEffect->minValue
            put #f,,tempObjEffect->maxValue
            put #f,,tempObjEffect->mode  
            put #f,,tempObjEffect->fast              
        case PORTAL
            tempObjPortal = .data_
            put #f,,tempObjPortal->portal_to_map
            put #f,,tempObjPortal->portal_to_portal
            put #f,,tempObjPortal->portal_direction
        case SPAWN
            tempObjSpawner = .data_
            put #f,,tempObjSpawner->spawn_objectName
            put #f,,tempObjSpawner->flavor            
            put #f,,tempObjSpawner->spawn_respawnType
            put #f,,tempObjSpawner->spawn_count
            put #f,,tempObjSpawner->spawn_time
        end select
    end with
next i

print "Level sucessfully converted..."

end






















