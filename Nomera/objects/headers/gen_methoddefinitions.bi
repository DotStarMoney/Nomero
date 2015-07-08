function Item.BIGOSCILLOSCOPE_FUNCTION_bogus(d as integer) as integer
    return d + 4

end function
sub Item.BIGOSCILLOSCOPE_SLOT_PLAYSOUNDTEST(pvPair() as _Item_slotValuePair_t)
    dim as integer playtimes
    matchParameter(playtimes, "PLAYTIMES", pvPair())
    for i = 0 to playtimes - 1
        if i = 0 then
            link.soundeffects_ptr->playSound(SND_ALARM)
        elseif i = 1 then
            link.soundeffects_ptr->playSound(SND_THROW)       
        end if
    next i
end sub
sub Item.BIGOSCILLOSCOPE_SLOT_DRAW2PARAMS(pvPair() as _Item_slotValuePair_t)
    dim as Vector2D param2
    dim as string param1
    matchParameter(param2, "PARAM2", pvPair())
    matchParameter(param1, "PARAM1", pvPair())
    dim as string someText
    
    data_.BIGOSCILLOSCOPE_DATA->shouldDraw = 1
    someText = allocate(len(param1) + 1)
    *someText = param1
    data_.BIGOSCILLOSCOPE_DATA->someText2 = someText
    data_.BIGOSCILLOSCOPE_DATA->vec = param2
   
end sub
sub Item.BIGOSCILLOSCOPE_PROC_INIT()
    data_.BIGOSCILLOSCOPE_DATA = new ITEM_BIGOSCILLOSCOPE_TYPE_DATA
    _initAddSignal_("GODEEP")
    _initAddSlot_("PLAYSOUNDTEST", ITEM_BIGOSCILLOSCOPE_SLOT_PLAYSOUNDTEST_E)
    _initAddSlot_("DRAW2PARAMS", ITEM_BIGOSCILLOSCOPE_SLOT_DRAW2PARAMS_E)
    _initAddParameter_("FLAVOR", _ITEM_VALUE_INTEGER)

    data_.BIGOSCILLOSCOPE_DATA->someText2 = 0
    data_.BIGOSCILLOSCOPE_DATA->shouldDraw = 0
end sub
sub Item.BIGOSCILLOSCOPE_PROC_FLUSH()

    if data_.BIGOSCILLOSCOPE_DATA->someText2 then deallocate(data_.BIGOSCILLOSCOPE_DATA->someText2)

        
        
    
    
    
    
    if anims_n then delete(anims)
    if data_.BIGOSCILLOSCOPE_DATA then delete(data_.BIGOSCILLOSCOPE_DATA)
    data_.BIGOSCILLOSCOPE_DATA = 0
end sub
function Item.BIGOSCILLOSCOPE_PROC_RUN(t as double) as integer
    static as Vector2D POLYGON2D_REP_0(0 to 2) = {Vector2D(10, 10), Vector2D(20, 30), Vector2D(0, 30)}
    dim as ObjectValueSet vset1, vset2 
    dim as ObjectSlotSet sset1
    dim as string tempVal
    if int(rnd * 1200) = 0 then 
throw("GODEEP", "thisParameterDoesntExist = 'hi ho'")
    end if
    queryValues(vset1, "testValue", Polygon2D(@(POLYGON2D_REP_0(0)), 3))
    
    querySlots(sset, "my only slot")
    if sset.getValue_N() > 0 then 
        sset.throw("param string")
    end if
    
    
    queryValues(vset2, "testvalue")
    if vset2.getValue_N() > 0 then vset2.getValue(tempVal, 0)
   
    
    data_.BIGOSCILLOSCOPE_DATA->thetime = val(tempVal)
    return 0
end function
sub Item.BIGOSCILLOSCOPE_PROC_DRAW(scnbuff as integer ptr)
    dim as integer flavor
    if data_.BIGOSCILLOSCOPE_DATA->shouldDraw then
        getParameter(flavor, "flavor")

        line (p.x, p.y)-(p.x+size.x, p.y+size.y), iif(flavor, &hff0000, &h0000ff), B
        draw string (p.x, p.y), str(data_.BIGOSCILLOSCOPE_DATA->thetime) + ", " + str(BIGOSCILLOSCOPE_FUNCTION_bogus(2)), &hff7f00
    
    end if
end sub
sub Item.BIGOSCILLOSCOPE_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
#define ITEM_FREQUENCYCOUNTER_DEFINE_thisIsAnOddPlaceForThis 42
#macro ITEM_FREQUENCYCOUNTER_MACRO_aldi(_X_, _Y_)
    data_.FREQUENCYCOUNTER_DATA->_X_ = _Y_
    print "assigned a data variable to" + str(_Y_) + ", " + str(ITEM_FREQUENCYCOUNTER_DEFINE_thisIsAnOddPlaceForThis)
#endmacro
sub Item.FREQUENCYCOUNTER_SLOT_TESTSLOT3(pvPair() as _Item_slotValuePair_t)
    print ITEM_FREQUENCYCOUNTER_DEFINE_thisIsAnOddPlaceForThis
    beep
    beep
    beep
    
end sub
sub Item.FREQUENCYCOUNTER_SLOT_EXPLODE(pvPair() as _Item_slotValuePair_t)

    link.soundeffects_ptr->playSound(SND_EXPLODE)

end sub
sub Item.FREQUENCYCOUNTER_PROC_INIT()
    data_.FREQUENCYCOUNTER_DATA = new ITEM_FREQUENCYCOUNTER_TYPE_DATA
    _initAddSignal_("TESTSIGNAL1")
    _initAddSignal_("TESTSIGNAL2")
    _initAddSlot_("TESTSLOT3", ITEM_FREQUENCYCOUNTER_SLOT_TESTSLOT3_E)
    _initAddSlot_("EXPLODE", ITEM_FREQUENCYCOUNTER_SLOT_EXPLODE_E)
    _initAddParameter_("FLAVOR", _ITEM_VALUE_INTEGER)

    dim as Shape2D randomShape
    data_.FREQUENCYCOUNTER_DATA->someText2 = 0
    data_.FREQUENCYCOUNTER_DATA->shouldDraw = 0

end sub
sub Item.FREQUENCYCOUNTER_PROC_FLUSH()

    if data_.FREQUENCYCOUNTER_DATA->someText2 then deallocate(data_.FREQUENCYCOUNTER_DATA->someText2)
    if anims_n then delete(anims)
    if data_.FREQUENCYCOUNTER_DATA then delete(data_.FREQUENCYCOUNTER_DATA)
    data_.FREQUENCYCOUNTER_DATA = 0
end sub
function Item.FREQUENCYCOUNTER_PROC_RUN(t as double) as integer

    if int(rnd * 1000) = 0 then throw("TESTSIGNAL1")
    if int(rnd * 1000) = 0 then throw("TESTSIGNAL2")

    return 0
end function
sub Item.FREQUENCYCOUNTER_PROC_DRAW(scnbuff as integer ptr)
    dim as integer flavor
    if data_.FREQUENCYCOUNTER_DATA->shouldDraw then
        getParameter(flavor, "flavor")

        line (p.x, p.y)-(p.x+size.x, p.y+size.y), iif(flavor, &hff00ff, &h00ffff), Bf

    end if
end sub
sub Item.FREQUENCYCOUNTER_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.TANDY2000_SUB_idontdonothin()
    static as Vector2D POLYGON2D_REP_0(0 to 2) = {Vector2D(0,10), Vector2D(40, 40), Vector2D(-10, 50)}
    dim as integer t
    dim as Shape2D randomShape
    t = 3
    randomShape = Polygon2D(@(POLYGON2D_REP_0(0)), 3)

end sub
sub Item.TANDY2000_SLOT_MYONLYSLOT(pvPair() as _Item_slotValuePair_t)
    dim as integer aValue
    matchParameter(aValue, "AVALUE", pvPair())
    dim as integer localVariable

    data_.TANDY2000_DATA->checkIt = 1
    

end sub
sub Item.TANDY2000_PROC_INIT()
    static as Vector2D POLYGON2D_REP_0(0 to 2) = {Vector2D(3,10), Vector2D(43, 40), Vector2D(-10, 30)}
    data_.TANDY2000_DATA = new ITEM_TANDY2000_TYPE_DATA
    _initAddSignal_("JUSTTREES")
    _initAddSignal_("NOTIMPORTANT")
    _initAddSlot_("MYONLYSLOT", ITEM_TANDY2000_SLOT_MYONLYSLOT_E)
    _initAddParameter_("TEST VECTOR2D", _ITEM_VALUE_VECTOR2D)
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "MY ONLY SLOT", "MYONLYSLOT", Polygon2D(@(POLYGON2D_REP_0(0)), 3))
    _initAddValue_("TESTVALUE", _ITEM_VALUE_STRING)
    link.dynamiccontroller_ptr->addPublishedValue(ID, "TESTVALUE")

    dim as integer rightoh
    
    data_.TANDY2000_DATA->testSng = 4.2
    
    data_.TANDY2000_DATA->cheese.test2 = 0
    data_.TANDY2000_DATA->cheese.temp = 2
    data_.TANDY2000_DATA->checkIt = 0
    
    rightOh = TANDY2000_CONST_buhnz

    setValue("its me", "TESTVALUE")
    print rightOh
    sleep
    
end sub
sub Item.TANDY2000_PROC_FLUSH()
    
    print "nothing here but us trees!"
    beep
    sleep

    if anims_n then delete(anims)
    if data_.TANDY2000_DATA then delete(data_.TANDY2000_DATA)
    data_.TANDY2000_DATA = 0
end sub
function Item.TANDY2000_PROC_RUN(t as double) as integer
   
    
    getParameter(data_.TANDY2000_DATA->alright, "test vector2D")
    
    setValue(str(timer), "testvalue")
    
    return 0
end function
sub Item.TANDY2000_PROC_DRAW(scnbuff as integer ptr)
    
    line (p.x, p.y)-(p.x+size.x, p.y+size.y), &hffff00, BF

end sub
sub Item.TANDY2000_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
    LOCK_SCREEN()
        circle scnbuff, (10, 10), 10, &h00ff00
        draw string scnbuff, (10, 10), str(data_.TANDY2000_DATA->alright)
        if data_.TANDY2000_DATA->checkIt = 4 then draw string (10, 18), "EUREKA"
    UNLOCK_SCREEN()

end sub
