#include "list.bi"
#include "hashtable.bi"
#include "vector2d.bi"
' -exx list.bas hashtable.bas vector2d.bas

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
    ACTIVE
    BACKGROUND
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
    as List ptr tilePropList
end type

type layer_t
    as zstring * 128 layer_name
    as uinteger ptr layer_data
    as ushort parallax
    as single depth
    as ushort inRangeSet
    as ushort isDestructible
    as ushort isFallout
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
    as ushort spawn_respawnType
end type


type objectPortal_t
    as zstring * 128 portal_to_map
    as zstring * 128 portal_to_portal
    as ushort        portal_direction
end type

enum ObjectEffectType_t
    RADAR_PULSE = 0
    SHIMMER     = 1
    SMOKE       = 2
    DRIP        = 3
end enum

type objectEffect_t
    as ushort effect_type
    as ushort effect_density
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
dim as ushort snowfall
dim as ushort map_width, map_height
dim as ushort N_tilesets, N_layers, N_objects

N_tilesets = 0
N_layers = 0
N_objects = 0

redim as set_t tilesets(0)
redim as layer_t layers(0)
redim as object_t objects(0)
redim as integer ptr setImages(0)
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
dim as integer f, itemNestLevel, itemIndex, curPos, curTile
dim as integer dataline, curChar, row, col, colIndex, propertyline = 0
dim as integer propertyType = 0, isObject, readObjects, curObjDepth
dim as tileEffect_t tempEffect
dim as string ls, rs


screenres 640,480,32


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
                                layers(N_layers - 1).inRangeSet = ACTIVE
                                layers(N_layers - 1).isDestructible = 65535
                                layers(N_layers - 1).isFallout = 65535
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
                                readObjects = 1
                                ti_pair.tag = "objects"
                                ti_pair.index = itemIndex
                                PUSH()
                                itemIndex = 1
                                itemNestLevel += 1
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
                                        tempObjEffect->effect_density = 65536 * 0.5
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
                        layers(N_layers - 1).parallax = val(item_content)
                    elseif left(lcase(item_tag), 10) = "foreground" then
                        layers(N_layers - 1).inRangeSet = FOREGROUND
                    elseif left(lcase(item_tag), 10) = "background" then
                        layers(N_layers - 1).inRangeSet = BACKGROUND
                    elseif left(lcase(item_tag), 12) = "destructible" then
                        layers(N_layers - 1).isDestructible = 1
                    elseif left(lcase(item_tag), 7) = "fallout" then
                        layers(N_layers - 1).isFallout = 1
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
                        if left(lcase(item_content), 2) = "on" then
                            snowfall = 1
                        end if
                    elseif left(lcase(item_tag), 13) = "default start" then
                        split item_content,,,pieces()
                        default_x = val(pieces(0))
                        default_y = val(pieces(1))
                    elseif left(lcase(item_tag), 5) = "music" then
                        music_file = item_content
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
                            end if
                        elseif left(lcase(item_tag), 7) = "density" then
                            tempObjEffect->effect_density = val(item_content) * 65535.0
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
                        end if
                    end select  
                elseif propertyType = 4 then
                    if left(lcase(item_tag), 10) = "foreground" then 
                        curObjDepth = FOREGROUND
                    elseif left(lcase(item_tag), 10) = "background" then 
                        curObjDepth = BACKGROUND
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
'251x21

/'
for q = 0 to map_width*map_height - 1
    if layers(0).layer_data[q] >= tilesets(4).set_firstID then 
        if layers(0).layer_data[q] < tilesets(5).set_firstID then
            print tilesets(4).set_name, tilesets(4).set_firstID
            print tilesets(5).set_name, tilesets(5).set_firstID
            print layers(0).layer_data[q] - tilesets(4).set_firstID
            print layers(0).layer_data[q]
            sleep
            exit for
        end if
    end if
next q
'/

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
next i

print
print "Layers: "; N_layers

for i = 0 to N_layers - 1
    print "   ";layers(i).layer_name
    print "   ";layers(i).order
    print "  ";layers(i).depth
    print "   ";layers(i).parallax
    print "   ";layers(i).inRangeSet
    print "   ";layers(i).isDestructible
    print "   ";layers(i).isFallout
next i

Print "Press a key to process and write file..."
sleep

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
        highCheck = tilesets(i).set_firstID + (tilesets(i).set_width/16) * (tilesets(i).set_height/16)
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

dim as integer curLayer, nextLayer, minID, N_merges, tempData
dim as integer tilesetA, tilesetB, canMerge, mustMerge, highTile
dim as tileEffect_t ptr animA, animB, effectPtr
dim as integer j, tileA, tileB, foundMergeLayer, didMerge, fullCover
dim as string searchKey
dim as integer ptr mergedTiles = imagecreate(320, 2048)
redim as integer ptr setImages(N_tilesets - 1)

dim as uinteger tilesToMerge_tile(N_layers - 1)
dim as uinteger tilesToMerge_set(N_layers - 1)
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


dim as HashTable combinedTiles
combinedTiles.init(sizeof(integer))
for i = 0 to N_tilesets - 1
    setImages(i) = imagecreate(tilesets(i).set_width, tilesets(i).set_height)
    bload tilesets(i).set_filename, setImages(i)
next i

N_merges = 0
'merge layers
for i = 0 to (N_layers - 1)
    curLayer = i
    if curLayer = collisionLayer then curLayer += 1
    if curLayer >= (N_layers - 1) then exit for
    for q = 0 to map_width*map_height - 1
        numMerged = 0
        tileA = layers(curLayer).layer_data[q] and &h1fffffff
        minID = -1
        if tileA <> 0 then
            for j = 0 to N_tilesets - 1
                if ucase(left(tilesets(j).set_name, 9)) <> "COLLISION" then
                    if tileA >= tilesets(j).set_firstID then
                        if (minID = -1) orElse (tilesets(j).set_firstID >= minID) then
                            minID = tilesets(j).set_firstID
                            tilesetA = j
                        end if
                    end if
                end if
            next j
        end if
        animA = 0
        if tilesets(tilesetA).tilePropList <> 0 then
            
            tilesets(tilesetA).tilePropList->rollReset()
            do
                tempPtr = tilesets(tilesetA).tilePropList->roll()
                if tempPtr <> 0 then
                    effectPtr = cast(tileEffect_t ptr, tempPtr)
                    tempEffect = *effectPtr
                    if tempEffect.tilenum = (tileA - tilesets(tilesetA).set_firstID) then
                        animA = effectPtr
                        exit do
                    end if
                else
                    exit do
                end if 
            loop
        end if
        
        if animA = 0 then
            
            foundMergeLayer = -1
            if tileA = 0 then
                numMerged = 0
                mustMerge = 0
                searchKey = ""
            else
                numMerged = 1
                mustMerge = 1
                searchKey = "(" + str(tilesetA) + ", " + str(layers(curLayer).layer_data[q]) + ")"
                tilesToMerge_tile(numMerged - 1) = layers(curLayer).layer_data[q] - tilesets(tilesetA).set_firstID
                tilesToMerge_set(numMerged - 1) = tilesetA
            end if
            
            for nextLayer = (curLayer + 1) to (N_layers-1) 
                if nextLayer <> collisionLayer then
                    if layers(nextLayer).depth <> layers(curLayer).depth then
                        ' as soon as we hit a layer with different parallax, we cannot merge any further into our layer
                        exit for
                    end if
                    didMerge = 0
                    tileB = layers(nextLayer).layer_data[q] and &h1fffffff
                    minID = -1
                    if tileB <> 0 then
                        for j = 0 to N_tilesets - 1
                            if ucase(left(tilesets(j).set_name, 9)) <> "COLLISION" then
                                if tileB >= tilesets(j).set_firstID then
                                    if (minID = -1) orElse (tilesets(j).set_firstID >= minID) then
                                        minID = tilesets(j).set_firstID
                                        tilesetB = j
                                    end if
                                end if
                            end if
                        next j
                    end if
                    animB = 0
                    if tilesets(tilesetB).tilePropList <> 0 then
                        tilesets(tilesetB).tilePropList->rollReset()
                        do
                            tempPtr = tilesets(tilesetB).tilePropList->roll()
                            if tempPtr <> 0 then
                                effectPtr = cast(tileEffect_t ptr, tempPtr)
                                tempEffect = *effectPtr
                                if tempEffect.tilenum = (tileB - tilesets(tilesetB).set_firstID) then
                                    animB = effectPtr
                                    exit do
                                end if
                            else
                                exit do
                            end if 
                        loop
                    end if  
                    
                    
                    ''''''''''
                    if tileB <> 0 then
                        'there is a tile in this layer above us
                        if layers(curLayer).inRangeSet = layers(nextLayer).inRangeSet then
                            'if tileA and tileB would be drawn in the same order plane
                            if (layers(curLayer).isDestructible = layers(nextLayer).isDestructible) andAlso _
                               (layers(curLayer).isFallout = layers(nextLayer).isFallout) then
                                'if the two layers have the same destruction properties
                                if animB = 0 andAlso animA = 0 then
                                    'if we are not merging animated tiles
                                    'tiles can be merged!
                                    didMerge = 1
    
                                    if mustMerge = 0 then
                                        layers(curLayer).layer_data[q] = layers(nextLayer).layer_data[q]
                                        numMerged += 1
                                        searchKey += "("+str(tilesetB)+","+str(layers(nextLayer).layer_data[q])+")"
                                        tilesToMerge_tile(numMerged - 1) = layers(curLayer).layer_data[q] - tilesets(tilesetB).set_firstID
                                        tilesToMerge_set(numMerged - 1) = tilesetB
                                        mustMerge = 1
                                    else
                                        searchKey += "("+str(tilesetB)+","+str(layers(nextLayer).layer_data[q])+")"
                                        numMerged += 1
                                        tilesToMerge_tile(numMerged - 1) = layers(nextLayer).layer_data[q] - tilesets(tilesetB).set_firstID
                                        tilesToMerge_set(numMerged - 1) = tilesetB
                                    end if
                                    layers(nextLayer).layer_data[q] = 0'remove tile from old layer
                                    '251 x 22  
                                end if
                            end if
                            
                        end if
                        if didMerge = 0 then
                            'if we hit a tile above us that we could not merge in,
                            'do not attempt to merge any further
                            exit for
                        end if
                    end if
                    '''''''''''''''''''
                    
                    
                end if
            next nextLayer
            
            if numMerged > 1 then 
                'if numMerged > 1 then we need to actually combine some tiles 
                'together. If its = 1, we either just moved a tile into a lower
                'layer or had a single tile, unaffected, in the layer already
                if combinedTiles.exists(searchKey) = 0 then
                    newTileNum = N_merges + highTileValue
                    N_merges += 1
                    combinedTiles.insert(searchKey, @newTileNum)
                    for j = 0 to numMerged - 1
                        tn = (tilesToMerge_tile(j) and &h1fffffff) 
                        rt = tilesToMerge_tile(j) shr 29
                        xtn = (tn mod 20) * 16
                        ytn = int(tn / 20) * 16
                        xpn = ((N_merges-1) mod 20) * 16
                        ypn = int((N_merges-1) / 20) * 16
                        if rt = 0 then
                            put mergedTiles, (xpn, ypn), setImages(tilesToMerge_set(j)), (xtn, ytn)-(xtn+15, ytn+15), TRANS
                        else
                            ptile(X_) = @xtn
                            ptile(Y_) = @ytn
                            ppos(X_) = xpn
                            ppos(Y_) = ypn
                            pdes(X_) = xpn
                            pdes(Y_) = ypn
                            select case rt
                            case 1
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
                            case 7
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
                            while ppos(byRow) <> pdes(byRow)
                                ppos(byCol) = oldCol
                                xpos = xtn
                                while ppos(byCol) <> pdes(byCol)
                                    
                                    col = setImages(tilesToMerge_set(j))[8 + xpos + ypos*tilesets(tilesToMerge_set(j)).set_width]
                                    if col <> &hffff00ff then 
                                        mergedTiles[8 + ppos(X_) + ppos(Y_) * 320] = col ' &hFF6495ED'
                                    end if
                                    ppos(byCol) += pdir(byCol)
                                    xpos += 1
                                wend
                                ppos(byRow) += pdir(byRow)
                                ypos += 1
                            wend
                        end if  
                                                   
                                                  

                        /'
                        if ((q mod map_width) = 251) andAlso ((q \ map_width) = 22) then
                            cls
                            put (0,0), setImages(tilesToMerge_set(j)), (xtn, ytn)-(xtn+15, ytn+15), TRANS
                            print
                            print
                            print
                            print xtn, ytn, tilesets(tilesToMerge_set(j)).set_firstID
                            sleep
                    
                        end if
                        '/
                    next j
                else
                    newTileNum = *cast(integer ptr, combinedTiles.retrieve(searchKey))
                    'get merged tile
                end if
                'assign merged tile
                layers(curLayer).layer_data[q] = newTileNum
                if N_merges > 2000 then goto IQUIT
            end if
        end if
    next q
next i
IQUIT:
print "Found"; N_merges; " unique merged tiles."

for i = 0 to N_tilesets - 1
    
    imagedestroy(setImages(i))
    
next i

dim as integer newOrder = 0
dim as ushort newLayersNum = 0

for i = 0 to N_layers - 1
    
    layers(i).empty = 1
    for q = 0 to map_width*map_height - 1
        if layers(i).layer_data[q] <> 0 then 
            layers(i).empty = 0
            layers(i).order = newOrder 
            newOrder += 1
            newLayersNum += 1
            exit for
        end if
    next q
next i



print "Creating merged tileset..."

dim as integer ptr tempImg
if N_merges > 0 then
    N_tilesets += 1
    redim preserve as set_t tilesets(N_tilesets - 1)
    with tilesets(N_tilesets - 1)
        .set_name = map_name + "_merged"
        .set_filename = map_name + "_merged.bmp"
        .set_width = 320
        .set_height = (int(N_merges / 20) + 1) * 16
        .set_firstID = highTileValue
        .tilePropList = 0
        tempImg = imagecreate(.set_width, .set_height)
        put tempImg, (0,0), mergedTiles, (0,0)-(.set_width-1,.set_height-1), PSET
        bsave .set_filename, tempImg
        imageDestroy(tempImg)
        
    end with
end if

imagedestroy(mergedTiles)

print "Writing file..."

f = freefile

open map_name + ".map" for binary as #f
put #f,,map_name
put #f,,map_width
put #f,,map_height
put #f,,snowfall
put #f,,default_x
put #f,,default_y
put #f,,music_file
N_tilesets -= 1
put #f,,N_tilesets
N_tilesets += 1
for i = 0 to N_tilesets - 1
    if ucase(left(tilesets(i).set_name, 9)) <> "COLLISION" then
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
for i = 0 to N_layers - 1
    if layers(i).empty = 0 then
        Print "Writing layer: " & str(layers(i).order)
        if ucase(left(layers(i).layer_name, 9)) <> "COLLISION" then
            put #f,,layers(i).layer_name
            put #f,,layers(i).order
            put #f,,layers(i).depth
            put #f,,layers(i).parallax
            put #f,,layers(i).inRangeSet
            put #f,,layers(i).isDestructible
            put #f,,layers(i).isFallout
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
        case PORTAL
            tempObjPortal = .data_
            put #f,,tempObjPortal->portal_to_map
            put #f,,tempObjPortal->portal_to_portal
            put #f,,tempObjPortal->portal_direction
        case SPAWN
            tempObjSpawner = .data_
            put #f,,tempObjSpawner->spawn_objectName
            put #f,,tempObjSpawner->spawn_respawnType
            put #f,,tempObjSpawner->spawn_count
            put #f,,tempObjSpawner->spawn_time
        end select
    end with
next i

print "Level sucessfully converted..."
sleep
end






















