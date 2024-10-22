#include "item.bi"
#include "gamespace.bi"
#include "projectilecollection.bi"
#include "dynamiccontroller.bi"
#include "tinyspace.bi"
#include "tinybody.bi"
#include "utility.bi"
#include "objectvalueset.bi"
#include "objectslotset.bi"
#include "locktoscreen.bi"
#include "constants.bi"
#include "C64Draw.bi"
#include "packedbinary.bi"
#include "constants.bi"
#include "debug.bi"

#define ifVector2D(_VTC_) iif(_VTC_.type_ = _ITEM_VALUE_VECTOR2D, 1, 0)
#define ifInteger(_VTC_) iif(_VTC_.type_ = _ITEM_VALUE_INTEGER, 1, 0)
#define ifDouble(_VTC_) iif(_VTC_.type_ = _ITEM_VALUE_DOUBLE, 1, 0)
#define ifString(_VTC_) iif(_VTC_.type_ = _ITEM_VALUE_ZSTRING, 1, 0)

#define getVector2D(_VTC_) _VTC_.data_.Vector2D_
#define getInteger(_VTC_) _VTC_.data_.integer_
#define getDouble(_VTC_) _VTC_.data_.double_
#define getString(_VTC_) *(_VTC_.data_.zstring)

#define MEDIA_PATH "objects\media\"

#define DControl link.dynamiccontroller_ptr

#macro CREATE_ANIMS(_N_)
    anims_n = _N_
    anims = new Animation[anims_n]
#endmacro
#macro PREP_LIT_ANIMATION()
    dim as integer numLights
    dim as LightPair ptr ptr lights
    if link.level_ptr->shouldLight() then
        numLights = link.level_ptr->getLightList(lights)
    else
        numLights = 0
    end if
#endmacro
#macro DRAW_LIT_ANIMATION(_ANIM_, _X_, _Y_, _FLAGS_, _FORCE_)
    if link.level_ptr->shouldLight() andAlso (DControl->overrideLightObjects() = 0) then
        anims[_ANIM_].drawAnimationLit(scnbuff, _X_, _Y_,_
                                       lights, numLights, link.level_ptr->getHiddenObjectAmbientLevel(),_
                                       link.gamespace_ptr->camera,_FLAGS_,_FORCE_,ANIM_TRANS)            
    else
        anims[_ANIM_].drawAnimation(scnbuff, _X_, _Y_, link.gamespace_ptr->camera,_FLAGS_,ANIM_TRANS)
    end if  
#endmacro
#macro DRAW_LIT_ANIMATION_BRIGHT(_ANIM_, _X_, _Y_, _FLAGS_, _FORCE_)
    if link.level_ptr->shouldLight() andAlso (DControl->overrideLightObjects() = 0) then
        anims[_ANIM_].drawAnimationLit(scnbuff, _X_, _Y_,_
                                       lights, numLights, link.level_ptr->getObjectAmbientLevel(),_
                                       link.gamespace_ptr->camera,_FLAGS_,_FORCE_,ANIM_TRANS)            
    else
        anims[_ANIM_].drawAnimation(scnbuff, _X_, _Y_, link.gamespace_ptr->camera,_FLAGS_,ANIM_TRANS)
    end if  
#endmacro
#macro PREP_LIGHTS(_DIFFFILE_, _SPECFILE_, _FAST_)
    diffuseTex_ = new Animation()
    specularTex_ = new Animation()
    diffuseTex_->load(_DIFFFILE_)
    specularTex_->load(_SPECFILE_)
    light.texture.diffuse_fbimg = diffuseTex_->getRawImage()
    light.texture.specular_fbimg = specularTex_->getRawImage()
    light.texture.x = 0
    light.texture.y = 0
    light.texture.w = diffuseTex_->getWidth()
    light.texture.h = diffuseTex_->getHeight()
    light.shaded = light.texture
    fastLight = _FAST_
    if _FAST_ then
        light.shaded.diffuse_fbimg = 0
        light.shaded.specular_fbimg = 0
        light.occlusion_fbimg = 0    
    else
        light.shaded.diffuse_fbimg = imagecreate(light.texture.w, light.texture.h)
        light.shaded.specular_fbimg = imagecreate(light.texture.w, light.texture.h)   
        light.occlusion_fbimg = imagecreate(light.texture.w, light.texture.h)
    end if
    light.last_tl_x = 0
    light.last_tl_y = 0
    light.last_br_x = light.texture.w - 1
    light.last_br_y = light.texture.h - 1
    usesLights_ = 1
#endmacro

#include "objects\headers\gen_methoddefinitions.bi"

dim as uinteger ptr Item.BOMB_COLORS = 0

constructor Item()
    construct_()
end constructor

sub Item.construct_()
	if BOMB_COLORS = 0 then
		BOMB_COLORS = new uinteger[10]
		BOMB_COLORS[0] = rgb( 58, 209,  70)
		BOMB_COLORS[1] = rgb(210,  57,  62)
		BOMB_COLORS[2] = rgb(  0, 198, 200)
		BOMB_COLORS[3] = rgb(200,  65, 203)
		BOMB_COLORS[4] = rgb(221, 200,  47)
		BOMB_COLORS[5] = rgb( 55,  47, 221)
		BOMB_COLORS[6] = rgb(255, 128,   0)
		BOMB_COLORS[7] = rgb( 35, 233, 179)
		BOMB_COLORS[8] = rgb(255, 255, 255)
		BOMB_COLORS[9] = rgb(185, 133, 115)
	end if
    parameterTable.init(sizeof(_Item_valueContainer_t))
    slotTable.init(sizeof(_Item_slotTable_t))
    valueTable.init(sizeof(_Item_valueContainer_t))
    signalTable.init(sizeof(integer))
    ILI = -1
end sub
destructor Item()
    flush()
end destructor
sub Item.setLink(link_ as objectLink)
    link = link_
end sub
function Item.getIndicatorColor(i as integer) as integer
    return BOMB_COLORS[i]
end function
sub Item.construct(itemType_ as Item_Type_e, ID_ as string = "")
    itemType = itemType_
    ID = ID_
    canExport_ = 0
    lightState = 0
    usesLights_ = 0
    
    #include "objects\headers\gen_constructcaseblock.bi"
    
end sub
sub Item.initPost(p_ as Vector2D, size_ as Vector2D, depth_ as single)
    p = p_
    depth = depth_
    size = size_
    fastLight = 1
    diffuseTex_ = 0
    specularTex_ = 0
    anims_n = 0
    light.shaded.diffuse_fbimg = 0
    light.shaded.specular_fbimg = 0
    light.occlusion_fbimg = 0
    
    #include "objects\headers\gen_initcaseblock.bi"
    
    bounds_tl = p
    bounds_br = p + size
end sub
sub Item.init(itemType_ as Item_Type_e, p_ as Vector2D, size_ as Vector2D, ID_ as string = "", depth_ as single)
    construct(itemType_, ID_)
    initPost(p_, size_, depth_)
end sub

sub Item.flush()
    dim as _Item_valueContainer_t ptr valueC_ptr
      
    #include "objects\headers\gen_flushcaseblock.bi"
    
    BEGIN_HASH(valueC_ptr, parameterTable)
        if valueC_ptr->type_ = _ITEM_VALUE_ZSTRING then
            if valueC_ptr->data_.zstring_ then
                deallocate(valueC_ptr->data_.zstring_)
            end if
        end if
    END_HASH()
    parameterTable.flush()
    BEGIN_HASH(valueC_ptr, valueTable)
        if valueC_ptr->type_ = _ITEM_VALUE_ZSTRING then
            if valueC_ptr->data_.zstring_ then
                deallocate(valueC_ptr->data_.zstring_)
            end if
        end if
    END_HASH()
    valueTable.flush()
    signalTable.flush()
    slotTable.flush()
    if usesLights_ then
        delete(diffuseTex_)
        delete(specularTex_)
    end if
    if lightState then
        if light.shaded.diffuse_fbimg then imagedestroy(light.shaded.diffuse_fbimg)
        if light.shaded.specular_fbimg then imagedestroy(light.shaded.specular_fbimg)
        if light.occlusion_fbimg then imagedestroy(light.occlusion_fbimg)
        light.shaded.diffuse_fbimg = 0
        light.shaded.specular_fbimg = 0
        light.occlusion_fbimg = 0
    end if
    ID = ""
end sub
function Item.getID() as string
    return ID
end function
function Item.canSerialize() as integer
    if canExport_ then
        if persistenceLevel_ = ITEM_PERSISTENCE_ITEM then return 1
    end if
    return 0
end function
function Item.shouldReload() as integer
    if persistenceLevel_ = ITEM_PERSISTENCE_ITEM then return 0
    return 1
end function
function Item.shouldSaveILI() as integer
    if persistenceLevel_ = ITEM_PERSISTENCE_ITEM orElse persistenceLevel_ = ITEM_PERSISTENCE_LEVEL then return 1
    return 0
end function
sub Item.serialize_in(pbin as PackedBinary)
    dim as integer tempInt
    dim as integer i
    dim as integer numRecords
    dim as integer  data_integer
    dim as double   data_double
    dim as Vector2D data_vector2d
    dim as string   data_string
    dim as _Item_valueTypes_e vType
    dim as string keyValue
    dim as string tempString
    
    pbin.retrieve(tempInt)
    itemType = tempInt
    pbin.retrieve(ID)
    construct(itemType, ID)
    pbin.retrieve(numRecords)
    for i = 0 to numRecords - 1
        pbin.retrieve(tempInt)
        vType = tempInt
        pbin.retrieve(keyValue)
        select case vType
        case _ITEM_VALUE_VECTOR2D
            pbin.retrieve(data_vector2d)
            setParameter(data_vector2D, keyValue)
        case _ITEM_VALUE_INTEGER
            pbin.retrieve(data_integer)
            setParameter(data_integer, keyValue)
        case _ITEM_VALUE_DOUBLE
            pbin.retrieve(data_double)
            setParameter(data_double, keyValue)
        case _ITEM_VALUE_ZSTRING
            pbin.retrieve(data_string)
            setParameter(data_string, keyValue)
        end select
    next i
    pbin.retrieve(numRecords)
    for i = 0 to numRecords - 1
        pbin.retrieve(tempInt)
        vType = tempInt
        pbin.retrieve(keyValue)
        select case vType
        case _ITEM_VALUE_VECTOR2D
            _initAddValue_(keyValue, _ITEM_VALUE_VECTOR2D)
            pbin.retrieve(data_vector2d)
            setValue(data_vector2D, keyValue)
        case _ITEM_VALUE_INTEGER
            _initAddValue_(keyValue, _ITEM_VALUE_INTEGER)
            pbin.retrieve(data_integer)
            setValue(data_integer, keyValue)
        case _ITEM_VALUE_DOUBLE
            _initAddValue_(keyValue, _ITEM_VALUE_DOUBLE)
            pbin.retrieve(data_double)
            setValue(data_double, keyValue)
        case _ITEM_VALUE_ZSTRING
            _initAddValue_(keyValue, _ITEM_VALUE_ZSTRING)
            pbin.retrieve(data_string)
            setValue(data_string, keyValue)
        end select
    next i
    pbin.retrieve(usesLights_)
    if usesLights_ then
        diffuseTex_ = new Animation()
        specularTex_ = new Animation()
        diffuseTex_->serialize_in(pbin)
        specularTex_->serialize_in(pbin)
        pbin.retrieve(lightState)
        pbin.retrieve(fastLight)
        light.texture.diffuse_fbimg = diffuseTex_->getRawImage()
        light.texture.specular_fbimg = specularTex_->getRawImage()
        pbin.retrieve(light.texture.x)
        pbin.retrieve(light.texture.y)
        light.texture.w = diffuseTex_->getWidth()
        light.texture.h = diffuseTex_->getHeight()
        light.shaded = light.texture
        if fastLight then
            light.shaded.diffuse_fbimg = 0
            light.shaded.specular_fbimg = 0
            light.occlusion_fbimg = 0    
        else
            light.shaded.diffuse_fbimg = imagecreate(light.texture.w, light.texture.h)
            light.shaded.specular_fbimg = imagecreate(light.texture.w, light.texture.h)   
            light.occlusion_fbimg = imagecreate(light.texture.w, light.texture.h)
        end if
        pbin.retrieve(light.last_tl_x)
        pbin.retrieve(light.last_tl_y)
        pbin.retrieve(light.last_br_x)
        pbin.retrieve(light.last_br_y)
    end if

    pbin.retrieve(anims_n)
    if anims_n > 0 then 
        CREATE_ANIMS(anims_n)
    end if
    for i = 0 to anims_n - 1
        anims[i].serialize_in(pbin)
    next i
    pbin.retrieve(size)
    pbin.retrieve(p)
    pbin.retrieve(bounds_tl)
    pbin.retrieve(bounds_br)
    pbin.retrieve(depth)
    pbin.retrieve(tempInt)    
    persistenceLevel_ = tempInt
    pbin.retrieve(ILI)
    pbin.retrieve(tempInt)    
    orderClass = tempInt
    #include "objects\headers\gen_serializeincaseblock.bi"
end sub
sub Item.serialize_out(pbin as PackedBinary)
    dim as _Item_valueContainer_t ptr valueC_ptr
    dim as Vector2D tempV
    dim as integer i
    
    pbin.store(cint(itemType))
    pbin.store(ID)

    pbin.store(parameterTable.getSize())
    BEGIN_HASH(valueC_ptr, parameterTable)
        pbin.store(cint(valueC_ptr->type_))
        pbin.store(parameterTable.rollGetKeyString())
        select case valueC_ptr->type_
        case _ITEM_VALUE_VECTOR2D
            tempV = valueC_ptr->data_.Vector2D_
            pbin.store(tempV)
        case _ITEM_VALUE_INTEGER
            pbin.store(valueC_ptr->data_.integer_)
        case _ITEM_VALUE_DOUBLE
            pbin.store(valueC_ptr->data_.double_)
        case _ITEM_VALUE_ZSTRING
            pbin.store(*(valueC_ptr->data_.zstring_))
        end select
    END_HASH()
    pbin.store(valueTable.getSize())
    BEGIN_HASH(valueC_ptr, valueTable)
        pbin.store(cint(valueC_ptr->type_))
        pbin.store(valueTable.rollGetKeyString())
        select case valueC_ptr->type_
        case _ITEM_VALUE_VECTOR2D
            tempV = valueC_ptr->data_.Vector2D_
            pbin.store(tempV)
        case _ITEM_VALUE_INTEGER
            pbin.store(valueC_ptr->data_.integer_)
        case _ITEM_VALUE_DOUBLE
            pbin.store(valueC_ptr->data_.double_)
        case _ITEM_VALUE_ZSTRING
            pbin.store(*(valueC_ptr->data_.zstring_))
        end select
    END_HASH()    
    pbin.store(usesLights_)
    if usesLights_ then
        diffuseTex_->serialize_out(pbin)
        specularTex_->serialize_out(pbin)
        pbin.store(lightState)
        pbin.store(fastLight)
        pbin.store(light.texture.x)
        pbin.store(light.texture.y)
        pbin.store(light.last_tl_x)
        pbin.store(light.last_tl_y)
        pbin.store(light.last_br_x)
        pbin.store(light.last_br_y)
    end if
    pbin.store(anims_n)
    for i = 0 to anims_n - 1
        anims[i].serialize_out(pbin)
    next i
    pbin.store(size)
    pbin.store(p)
    pbin.store(bounds_tl)
    pbin.store(bounds_br)
    pbin.store(depth)
    pbin.store(cint(persistenceLevel_))
    pbin.store(ILI)
    pbin.store(cint(orderClass))
 
    #include "objects\headers\gen_serializeoutcaseblock.bi"
    
end sub

function Item.process(t as double) as integer
    
    #include "objects\headers\gen_runcaseblock.bi"

    return 0
end function

sub Item.drawItem(scnbuff as integer ptr)

    #include "objects\headers\gen_drawcaseblock.bi"

end sub

sub Item.drawItemOverlay(scnbuff as integer ptr)
    
    #include "objects\headers\gen_drawoverlaycaseblock.bi"

end sub

function Item.drawX() as double
    return p.x + (link.gamespace_ptr->camera.x - link.level_ptr->getLevelCenterX()) * (1.0 - depth)
end function
function Item.drawY() as double
    return p.y + (link.gamespace_ptr->camera.y - link.level_ptr->getLevelCenterY()) * (1.0 - depth)
end function

sub Item._initAddParameter_(param_tag as string, param_type as _Item_valueTypes_e)
    dim as _Item_valueContainer_t valueC
    valueC.type_ = param_type
    select case param_type
    case _ITEM_VALUE_VECTOR2D
        valueC.data_.Vector2D_ = Vector2D(0, 0)
    case _ITEM_VALUE_INTEGER
        valueC.data_.integer_ = 0 
    case _ITEM_VALUE_DOUBLE
        valueC.data_.double_ = 0.0
    case _ITEM_VALUE_ZSTRING
        valueC.data_.zstring_ = 0   
    end select
    param_tag = ucase(param_tag)
    parameterTable.insert(param_tag, @valueC)
end sub
sub Item._initAddSlot_(slot_tag as string, slot_num as Item_slotEnum_e)
    dim as _Item_slotTable_t slotEntry
    slotEntry.slotE = slot_num
    slotTable.insert(ucase(slot_tag), @slotEntry)
end sub
sub Item._initAddValue_(value_tag as string, value_type as _Item_valueTypes_e)
    dim as _Item_valueContainer_t valueC
    valueC.type_ = value_type
    select case value_type
    case _ITEM_VALUE_VECTOR2D
        valueC.data_.Vector2D_ = Vector2D(0, 0)
    case _ITEM_VALUE_INTEGER
        valueC.data_.integer_ = 0 
    case _ITEM_VALUE_DOUBLE
        valueC.data_.double_ = 0.0
    case _ITEM_VALUE_ZSTRING
        valueC.data_.zstring_ = 0   
    end select
    value_tag = ucase(value_tag)
    valueTable.insert(value_tag, @valueC)
end sub
sub Item._initAddSignal_(signal_tag as string)
    dim as integer fillerData
    fillerData = not 0
    signalTable.insert(ucase(signal_tag), @fillerData)
end sub
sub Item.setTargetValueOffset(value_tag as string, offset as Vector2D)        
    link.dynamiccontroller_ptr->setTargetValueOffset(ID, ucase(value_tag), offset)
end sub
sub Item.setTargetSlotOffset(slot_tag as string, offset as Vector2D)
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, ucase(slot_tag), offset)
end sub
function Item.isSignal(signal_tag as string) as integer
    return signalTable.exists(ucase(signal_tag))
end function
function Item.isSlot(slot_tag as string) as integer
    return signalTable.exists(ucase(slot_tag))
end function
sub Item.setPos(v as Vector2D)
    p = v
end sub

sub Item.setSize(s as Vector2D)
    size = s
end sub

function Item.getPos() as Vector2D
    return p
end function

function Item.getSize() as Vector2D
    return size
end function

sub Item.getBounds(byref a as Vector2D, byref b as Vector2D) 
    a = bounds_tl
    b = bounds_br
end sub

function Item.getType() as Item_Type_e
    return itemType
end function

function Item.hasLight() as integer
    return lightState
end function

function Item.getLightingData() as LightPair ptr
    return @light
end function


#macro _setParameter_(_TYPE_, _VALUE_TYPE_)
    dim as _Item_valueContainer_t ptr parameter_ptr
    param_tag = ucase(param_tag)
    parameter_ptr = parameterTable.retrieve(param_tag)
    if parameter_ptr then
        if parameter_ptr->type_ = _VALUE_TYPE_ then
            parameter_ptr->data_._TYPE_ = param_
        end if
    end if
#endmacro
sub Item.setParameter(param_ as Vector2D, param_tag as string)
    _setParameter_(Vector2D_, _ITEM_VALUE_VECTOR2D)
end sub
sub Item.setParameter(param_ as integer, param_tag as string)
    _setParameter_(integer_, _ITEM_VALUE_INTEGER)
end sub
sub Item.setParameter(param_ as double, param_tag as string)
    _setParameter_(double_, _ITEM_VALUE_DOUBLE)
end sub
sub Item.setParameter(param_ as string, param_tag as string)
    dim as _Item_valueContainer_t ptr parameter_ptr
    param_tag = ucase(param_tag)
    parameter_ptr = parameterTable.retrieve(param_tag)
    if parameter_ptr then
        if parameter_ptr->type_ = _ITEM_VALUE_ZSTRING then
            if parameter_ptr->data_.zstring_ = 0 then 
                parameter_ptr->data_.zstring_ = allocate(len(param_) + 1)
            elseif len(param_) > len(*(parameter_ptr->data_.zstring_)) then
                parameter_ptr->data_.zstring_ = reallocate(parameter_ptr->data_.zstring_, len(param_) + 1)
            end if
            *(parameter_ptr->data_.zstring_) = param_
        end if
    end if
end sub



sub Item.matchParameter(byref value_ as Vector2D, parameter_tag as string, pvPair() as _Item_slotValuePair_t) 
    dim as integer i
    parameter_tag = ucase(parameter_tag)
    for i = 0 to ubound(pvPair)
        if pvPair(i).parameter_tag = parameter_tag then
            if pvPair(i).value_.type_ = _ITEM_VALUE_VECTOR2D then
                value_ = pvPair(i).value_.data_.Vector2D_
                exit sub
            end if
        end if
    next i
    value_ = Vector2D(0, 0)
end sub

sub Item.matchParameter(byref value_ as integer, parameter_tag as string, pvPair() as _Item_slotValuePair_t)
    dim as integer i
    parameter_tag = ucase(parameter_tag)
    for i = 0 to ubound(pvPair)
        if pvPair(i).parameter_tag = parameter_tag then
            if pvPair(i).value_.type_ = _ITEM_VALUE_INTEGER then
                value_ = pvPair(i).value_.data_.integer_
                exit sub
            end if
        end if
    next i
    value_ = 0
end sub

sub Item.matchParameter(byref value_ as double, parameter_tag as string, pvPair() as _Item_slotValuePair_t)
    dim as integer i
    parameter_tag = ucase(parameter_tag)
    for i = 0 to ubound(pvPair)
        if pvPair(i).parameter_tag = parameter_tag then
            if pvPair(i).value_.type_ = _ITEM_VALUE_DOUBLE then
                value_ = pvPair(i).value_.data_.double_
                exit sub
            end if
        end if
    next i
    value_ = 0.0
end sub

sub Item.matchParameter(byref value_ as string, parameter_tag as string, pvPair() as _Item_slotValuePair_t)
    dim as integer i
    parameter_tag = ucase(parameter_tag)
    for i = 0 to ubound(pvPair)
        if pvPair(i).parameter_tag = parameter_tag then
            if pvPair(i).value_.type_ = _ITEM_VALUE_ZSTRING then
                value_ = *(pvPair(i).value_.data_.zstring_)
                exit sub
            end if
        end if
    next i
    value_ = ""
end sub

sub Item.valueFormToContainer(value_form as string, byref valueC as _Item_valueContainer_t)
    dim as integer cpos
    dim as string lstr, rstr
    if left(value_form, 1) = "(" then
        'read as vector2d
        'remove parenthesis
        value_form = right(left(value_form, len(value_form) - 1), len(value_form) - 2)
        cpos = instr(value_form, ",")
        lstr = left(value_form, cpos - 1)
        rstr = right(value_form, len(value_form) - cpos)
        if ucase(right(lstr, 1)) = "F" then lstr = left(lstr, len(lstr) - 1)
        if ucase(right(rstr, 1)) = "F" then rstr = left(rstr, len(rstr) - 1)
        valueC.type_ = _ITEM_VALUE_VECTOR2D
        valueC.data_.Vector2D_ = Vector2D(val(lstr), val(rstr))
    elseif left(value_form, 1) = "'" then
        'read as string
        'remove quotes
        value_form = right(left(value_form, len(value_form) - 1), len(value_form) - 2)
        valueC.type_ = _ITEM_VALUE_ZSTRING
        valueC.data_.zstring_ = allocate(len(value_form) + 1)
        *(valueC.data_.zstring_) = value_form
    elseif ucase(right(value_form, 1)) = "F" then
        'read as double
        'remove f
        value_form = left(value_form, len(value_form) - 1)
        valueC.type_ = _ITEM_VALUE_DOUBLE
        valueC.data_.double_ = val(value_form)
    else
        'read as integer
        valueC.type_ = _ITEM_VALUE_INTEGER
        valueC.data_.integer_ = val(value_form)
    end if
end sub

sub Item.fireSlot(slot_tag as string, parameter_string as string)
    dim as _Item_slotTable_t ptr slotE_ptr
    dim as Item_slotEnum_e slotNumber
    dim as integer i, divPos, pvPair_l
    dim as string paramName, valueString
    redim as string paramSplit(0)
    redim as _Item_slotValuePair_t pvPair(0)
    slot_tag = ucase(slot_tag)
    slotE_ptr = slotTable.retrieve(slot_tag)
    if slotE_ptr then
        slotNumber = slotE_ptr->slotE
        if parameter_string <> "" then
            parameter_string = trimwhite(parameter_string)
            tokenize(parameter_string, paramSplit(), ",",, "()")
            pvPair_l = 0
            for i = 0 to ubound(paramSplit)
                paramSplit(i) = trimwhite(paramSplit(i))
                divPos = instr(paramSplit(i), "=")
                paramName = ucase(left(paramSplit(i), divPos - 1))
                paramName = trimwhite(paramName)
                valueString = stripwhite(right(paramSplit(i), len(paramSplit(i)) - divPos))             
                if pvPair_l > 0 then redim preserve as _Item_slotValuePair_t pvPair(pvPair_l)
                valueFormToContainer(valueString, pvPair(pvPair_l).value_)
                pvPair(pvPair_l).parameter_tag = paramName
                pvPair_l += 1
            next i
        else
            pvPair(0).parameter_tag = ""
            pvPair(0).value_.type_ = _ITEM_VALUE_INTEGER
            pvPair(i).value_.data_.integer_ = -1
        end if
        
        
        #include "objects\headers\gen_slotcaseblock.bi"
    
    
        for i = 0 to ubound(pvPair)
            if pvPair(i).value_.type_ = _ITEM_VALUE_ZSTRING then
                if pvPair(i).value_.data_.zstring_ then deallocate(pvPair(i).value_.data_.zstring_)
            end if
        next i        
    end if
end sub
sub Item.fireExternalSlot(ID as string, slot_tag as string, parameter_string as string = "")
    link.dynamiccontroller_ptr->fireSlot(ID, slot_tag, parameter_string)
end sub
function Item.getValueContainer(value_tag as string) as _Item_valueContainer_t ptr
    dim as _Item_valueContainer_t value_ptr
    value_tag = ucase(value_tag)
    return valueTable.retrieve(value_tag)
end function
sub Item.getValue(byref value_ as Vector2D, value_tag as string) 
    dim as _Item_valueContainer_t ptr value_ptr
    value_tag = ucase(value_tag)
    value_ptr = valueTable.retrieve(value_tag)
    if value_ptr then
        if value_ptr->type_ = _ITEM_VALUE_VECTOR2D then
            value_ = value_ptr->data_.Vector2D_
            exit sub
        end if
    end if
    value_ = Vector2D(0, 0)
end sub
sub Item.getValue(byref value_ as integer, value_tag as string) 
    dim as _Item_valueContainer_t ptr value_ptr
    value_tag = ucase(value_tag)
    value_ptr = valueTable.retrieve(value_tag)
    if value_ptr then
        if value_ptr->type_ = _ITEM_VALUE_INTEGER then
            value_ = value_ptr->data_.integer_
            exit sub
        end if
    end if
    value_ = 0
end sub
sub Item.getValue(byref value_ as double, value_tag as string) 
    dim as _Item_valueContainer_t ptr value_ptr
    value_tag = ucase(value_tag)
    value_ptr = valueTable.retrieve(value_tag)
    if value_ptr then
        if value_ptr->type_ = _ITEM_VALUE_DOUBLE then
            value_ = value_ptr->data_.double_
            exit sub
        end if
    end if
    value_ = 0.0
end sub
sub Item.getValue(byref value_ as string, value_tag as string) 
    dim as _Item_valueContainer_t ptr value_ptr
    value_tag = ucase(value_tag)
    value_ptr = valueTable.retrieve(value_tag)
    if value_ptr then
        if value_ptr->type_ = _ITEM_VALUE_ZSTRING then
            value_ = *(value_ptr->data_.zstring_)
            exit sub
        end if
    end if
    value_ = ""
end sub

sub Item.getOtherValue(byref value_ as Vector2D, ID_ as string, value_tag as string)
    link.dynamiccontroller_ptr->getValue(value_, ID_, value_tag)
end sub                
sub Item.getOtherValue(byref value_ as integer, ID_ as string, value_tag as string)
    link.dynamiccontroller_ptr->getValue(value_, ID_, value_tag)                       
end sub                
sub Item.getOtherValue(byref value_ as double, ID_ as string, value_tag as string)
    link.dynamiccontroller_ptr->getValue(value_, ID_, value_tag)
end sub                
sub Item.getOtherValue(byref value_ as string, ID_ as string, value_tag as string)
    link.dynamiccontroller_ptr->getValue(value_, ID_, value_tag)
end sub

sub Item.getParameter(byref param_ as Vector2D, param_tag as string)  
    dim as _Item_valueContainer_t ptr param_ptr
    param_tag = ucase(param_tag)
    param_ptr = parameterTable.retrieve(param_tag)
    if param_ptr then
        if param_ptr->type_ = _ITEM_VALUE_VECTOR2D then            
            param_ = param_ptr->data_.Vector2D_
            exit sub
        end if
    end if
    param_ = Vector2D(0, 0)    
end sub               
sub Item.getParameter(byref param_ as integer, param_tag as string) 
    dim as _Item_valueContainer_t ptr param_ptr
    param_tag = ucase(param_tag)
    param_ptr = parameterTable.retrieve(param_tag)
    if param_ptr then
        if param_ptr->type_ = _ITEM_VALUE_INTEGER then
            param_ = param_ptr->data_.integer_
            exit sub
        end if
    end if
    param_ = 0                        
end sub               
sub Item.getParameter(byref param_ as double, param_tag as string) 
    dim as _Item_valueContainer_t ptr param_ptr
    param_tag = ucase(param_tag)
    param_ptr = parameterTable.retrieve(param_tag)
    if param_ptr then
        if param_ptr->type_ = _ITEM_VALUE_DOUBLE then
            param_ = param_ptr->data_.double_
            exit sub
        end if
    end if
    param_ = 0                           
end sub               
sub Item.getParameter(byref param_ as string, param_tag as string) 
    dim as _Item_valueContainer_t ptr param_ptr
    param_tag = ucase(param_tag)
    param_ptr = parameterTable.retrieve(param_tag)
    if param_ptr then
        if param_ptr->type_ = _ITEM_VALUE_ZSTRING then
            param_ = *(param_ptr->data_.zstring_)
            exit sub
        end if
    end if
    param_ = ""
end sub

sub Item.setValue(value_ as Vector2D, value_tag as string)
    dim as _Item_valueContainer_t ptr value_ptr
    value_tag = ucase(value_tag)
    value_ptr = valueTable.retrieve(value_tag)
    if value_ptr then
        if value_ptr->type_ = _ITEM_VALUE_VECTOR2D then
            value_ptr->data_.Vector2D_ = value_
        end if
    end if
end sub
sub Item.setValue(value_ as integer, value_tag as string)
    dim as _Item_valueContainer_t ptr value_ptr
    value_tag = ucase(value_tag)
    value_ptr = valueTable.retrieve(value_tag)
    if value_ptr then
        if value_ptr->type_ = _ITEM_VALUE_INTEGER then
            value_ptr->data_.integer_ = value_
        end if
    end if
end sub
sub Item.setValue(value_ as double, value_tag as string)
    dim as _Item_valueContainer_t ptr value_ptr
    value_tag = ucase(value_tag)
    value_ptr = valueTable.retrieve(value_tag)
    if value_ptr then
        if value_ptr->type_ = _ITEM_VALUE_DOUBLE then
            value_ptr->data_.double_ = value_
        end if
    end if
end sub
sub Item.setValue(value_ as string, value_tag as string)
    dim as _Item_valueContainer_t ptr value_ptr
    value_tag = ucase(value_tag)
    value_ptr = valueTable.retrieve(value_tag)
    if value_ptr then
        if value_ptr->type_ = _ITEM_VALUE_ZSTRING then
            if value_ptr->data_.zstring_ = 0 then 
                value_ptr->data_.zstring_ = allocate(len(value_) + 1)
            elseif len(value_) > len(*(value_ptr->data_.zstring_)) then
                value_ptr->data_.zstring_ = reallocate(value_ptr->data_.zstring_, len(value_) + 1)
            end if
            *(value_ptr->data_.zstring_) = value_
        end if
    end if
end sub

sub Item.throw(signal_tag as string, parameter_string as string)
    link.dynamiccontroller_ptr->throw(ucase(ID), ucase(signal_tag), parameter_string)
end sub

sub Item.queryValues(byref value_set as ObjectValueSet, value_tag as string, queryShape as Shape2D ptr)
    link.dynamiccontroller_ptr->queryValues(value_set, ucase(value_tag), queryShape)
end sub

sub Item.querySlots(slot_set as ObjectSlotSet, slot_tag as string, queryShape as Shape2D ptr)
    link.dynamiccontroller_ptr->querySlots(slot_set, ucase(slot_tag), queryShape)
end sub
