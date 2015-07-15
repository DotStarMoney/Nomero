function Item.BIGOSCILLOSCOPE_FUNCTION_bogus(d as integer) as integer
    return d + 4

end function
sub Item.BIGOSCILLOSCOPE_SLOT_PLAYSOUNDTEST(pvPair() as _Item_slotValuePair_t)
    dim as integer playtimes
    matchParameter(playtimes, "PLAYTIMES", pvPair())
    dim as integer i
    print playTimes
    beep
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
    
    print "draw2Params"
    beep
    data_.BIGOSCILLOSCOPE_DATA->shouldDraw = 1
    someText = param1
    *(data_.BIGOSCILLOSCOPE_DATA->someText2) = someText
    data_.BIGOSCILLOSCOPE_DATA->vec = param2
   
end sub
sub Item.BIGOSCILLOSCOPE_PROC_INIT()
    data_.BIGOSCILLOSCOPE_DATA = new ITEM_BIGOSCILLOSCOPE_TYPE_DATA
    dim as integer flavor
    data_.BIGOSCILLOSCOPE_DATA->someText2 = 0
    data_.BIGOSCILLOSCOPE_DATA->shouldDraw = 0
    data_.BIGOSCILLOSCOPE_DATA->CountDown = 60
    data_.BIGOSCILLOSCOPE_DATA->safeText = ""
    getParameter(flavor, "flavor")
    setValue(Vector2D(-1, flavor), "myvalue7")
    link.dynamiccontroller_ptr->setTargetValueOffset(ID, "MYVALUE7", p)
end sub
sub Item.BIGOSCILLOSCOPE_PROC_FLUSH()

    if data_.BIGOSCILLOSCOPE_DATA->someText2 then deallocate(data_.BIGOSCILLOSCOPE_DATA->someText2)
    data_.BIGOSCILLOSCOPE_DATA->safeText = ""
        
        
    
    
    
    
    if anims_n then delete(anims)
    if data_.BIGOSCILLOSCOPE_DATA then delete(data_.BIGOSCILLOSCOPE_DATA)
    data_.BIGOSCILLOSCOPE_DATA = 0
end sub
function Item.BIGOSCILLOSCOPE_PROC_RUN(t as double) as integer
    dim as ObjectValueSet vset1, vset2 
    dim as ObjectSlotSet sset
    dim as string tempVal
    dim as double cv
    if data_.BIGOSCILLOSCOPE_DATA->countDown = 0 then 
        throw("GODEEP", "thisParameterDoesntExist = 'hi ho', paramA = 23, paramB = 'cheeze', paramC = (12.2, 11)")
    end if
    
    queryValues(vset1, "testValue")
    
   
    vset1.getValue(data_.BIGOSCILLOSCOPE_DATA->safeText, 0)
    
    queryValues(vset2, "circleAngle")
    vset2.getValue(cv, 0)
    
    data_.BIGOSCILLOSCOPE_DATA->tPos = p + Vector2D(0, sin(cv)) * 100
    
    setTargetValueOffset("myValue7", data_.BIGOSCILLOSCOPE_DATA->tpos)
    
    
    
    data_.BIGOSCILLOSCOPE_DATA->CountDown -= 1
    
    data_.BIGOSCILLOSCOPE_DATA->thetime = 3

    return 0
end function
sub Item.BIGOSCILLOSCOPE_PROC_DRAW(scnbuff as integer ptr)
    dim as integer flavor
    if data_.BIGOSCILLOSCOPE_DATA->shouldDraw then
        getParameter(flavor, "flavor")

        line scnbuff, (p.x, p.y)-(p.x+size.x, p.y+size.y), iif(flavor, &hff0000, &h0000ff), B
        draw string scnbuff, (p.x, p.y), str(data_.BIGOSCILLOSCOPE_DATA->thetime) + ", " + str(BIGOSCILLOSCOPE_FUNCTION_bogus(2)) + ", " + data_.BIGOSCILLOSCOPE_DATA->safeText, &hff7f00
    
    end if
    
    line scnbuff, (data_.BIGOSCILLOSCOPE_DATA->tpos.x, data_.BIGOSCILLOSCOPE_DATA->tpos.y)-(data_.BIGOSCILLOSCOPE_DATA->tpos.x + 64, data_.BIGOSCILLOSCOPE_DATA->tpos.y + 32), &h7fff00, B
end sub
sub Item.BIGOSCILLOSCOPE_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.BIGOSCILLOSCOPE_PROC_CONSTRUCT()
    _initAddSignal_("GODEEP")
    _initAddSlot_("PLAYSOUNDTEST", ITEM_BIGOSCILLOSCOPE_SLOT_PLAYSOUNDTEST_E)
    _initAddSlot_("DRAW2PARAMS", ITEM_BIGOSCILLOSCOPE_SLOT_DRAW2PARAMS_E)
    _initAddParameter_("FLAVOR", _ITEM_VALUE_INTEGER)
    _initAddValue_("MYVALUE7", _ITEM_VALUE_VECTOR2D)
    link.dynamiccontroller_ptr->addPublishedValue(ID, "MYVALUE7", new Rectangle2D(Vector2D(0,0), Vector2D(64, 32)))
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
    data_.FREQUENCYCOUNTER_DATA->someText2 = 0
    data_.FREQUENCYCOUNTER_DATA->shouldDraw = 1
    
    data_.FREQUENCYCOUNTER_DATA->circleAngle = rnd * _PI_ * 2
    
end sub
sub Item.FREQUENCYCOUNTER_PROC_FLUSH()

    if data_.FREQUENCYCOUNTER_DATA->someText2 then deallocate(data_.FREQUENCYCOUNTER_DATA->someText2)
    if anims_n then delete(anims)
    if data_.FREQUENCYCOUNTER_DATA then delete(data_.FREQUENCYCOUNTER_DATA)
    data_.FREQUENCYCOUNTER_DATA = 0
end sub
function Item.FREQUENCYCOUNTER_PROC_RUN(t as double) as integer
    dim as ObjectSlotSet slotz
    
    if int(rnd * 1000) = 0 then throw("TESTSIGNAL1")
    if int(rnd * 1000) = 0 then throw("TESTSIGNAL2")
    data_.FREQUENCYCOUNTER_DATA->circleAngle += 0.01
    data_.FREQUENCYCOUNTER_DATA->vec = p + Vector2D(cos(data_.FREQUENCYCOUNTER_DATA->circleAngle), sin(data_.FREQUENCYCOUNTER_DATA->circleAngle))*200
    
    querySlots(slotz, "my only slot", @Circle2D(data_.FREQUENCYCOUNTER_DATA->vec, 30))
    setValue(data_.FREQUENCYCOUNTER_DATA->circleAngle, "circleAngle")
    
    slotz.throw()
    
    return 0
end function
sub Item.FREQUENCYCOUNTER_PROC_DRAW(scnbuff as integer ptr)
    dim as integer flavor
    if data_.FREQUENCYCOUNTER_DATA->shouldDraw then
        getParameter(flavor, "flavor")

        line scnbuff, (p.x, p.y)-(p.x+size.x, p.y+size.y), iif(flavor, &hff00ff, &h00ffff), Bf
        circle scnbuff, (data_.FREQUENCYCOUNTER_DATA->vec.x, data_.FREQUENCYCOUNTER_DATA->vec.y), 30, &h00FFFF

    end if
end sub
sub Item.FREQUENCYCOUNTER_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.FREQUENCYCOUNTER_PROC_CONSTRUCT()
    _initAddSignal_("TESTSIGNAL1")
    _initAddSignal_("TESTSIGNAL2")
    _initAddSlot_("TESTSLOT3", ITEM_FREQUENCYCOUNTER_SLOT_TESTSLOT3_E)
    _initAddSlot_("EXPLODE", ITEM_FREQUENCYCOUNTER_SLOT_EXPLODE_E)
    _initAddParameter_("FLAVOR", _ITEM_VALUE_INTEGER)
    _initAddValue_("CIRCLEANGLE", _ITEM_VALUE_DOUBLE)
    link.dynamiccontroller_ptr->addPublishedValue(ID, "CIRCLEANGLE")
end sub
sub Item.TANDY2000_SUB_idontdonothin()
    static as Vector2D POLYGON2D_REP_0(0 to 2) = {Vector2D(0,10), Vector2D(40, 40), Vector2D(-10, 50)}
    dim as integer t
    dim as Polygon2D randomShape
    t = 3
    randomShape = Polygon2D(@(POLYGON2D_REP_0(0)), 3)

end sub
sub Item.TANDY2000_SLOT_MYONLYSLOT(pvPair() as _Item_slotValuePair_t)
    dim as integer aValue
    matchParameter(aValue, "AVALUE", pvPair())
    dim as integer localVariable

    data_.TANDY2000_DATA->checkIt += 1
    print "myOnlySlot..."

end sub
sub Item.TANDY2000_SLOT_TESTSLOT3(pvPair() as _Item_slotValuePair_t)
    dim as Vector2D paramC
    dim as string paramB
    dim as integer paramA
    matchParameter(paramC, "PARAMC", pvPair())
    matchParameter(paramB, "PARAMB", pvPair())
    matchParameter(paramA, "PARAMA", pvPair())

    data_.TANDY2000_DATA->checkIt += 1
    print "incrementing checkIt"
    print paramA, paramB, paramC
    
end sub
sub Item.TANDY2000_PROC_INIT()
    data_.TANDY2000_DATA = new ITEM_TANDY2000_TYPE_DATA
    dim as integer rightoh
    
    data_.TANDY2000_DATA->testSng = 4.2
    
    data_.TANDY2000_DATA->cheese.test2 = 0
    data_.TANDY2000_DATA->cheese.temp = 2
    data_.TANDY2000_DATA->checkIt = 0
    data_.TANDY2000_DATA->col = &hff0000
    rightOh = TANDY2000_CONST_buhnz
    data_.TANDY2000_DATA->randOffset = int(rnd * 100)

    setValue("its me", "TESTVALUE")
    print "RIGhTOH!!!"; rightOh
    sleep
    
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "MY ONLY SLOT", p)
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
    dim as ObjectValueSet vs
    dim as integer i
    dim as Vector2D para
    dim as Vector2D playerP
    dim as Vector2D playerS
    
    getParameter(data_.TANDY2000_DATA->alright, "test vector2D")
    setValue(str(timer), "testvalue")
    
    link.player_ptr->getBounds(playerP, playerS)
    
    
    queryValues(vs, "MYVALUE7", @Rectangle2D(playerP, playerP + playerS))
    
    for i = 0 to vs.getValue_N() - 1
        
        vs.getValue(para, i)
        print para
    next i
    return 0
end function
sub Item.TANDY2000_PROC_DRAW(scnbuff as integer ptr)
    
    line scnbuff, (p.x, p.y)-(p.x+size.x, p.y+size.y), data_.TANDY2000_DATA->col, BF

end sub
sub Item.TANDY2000_PROC_DRAWOVERLAY(scnbuff as integer ptr)
   
    
    LOCK_TO_SCREEN()
        circle scnbuff, (10, 10), 10, &h00ff00
        draw string scnbuff, (10, 30+data_.TANDY2000_DATA->randOffset), str(data_.TANDY2000_DATA->alright)
        if data_.TANDY2000_DATA->checkIt > 0 then draw string scnbuff, (10, 18), "EUREKA"
    UNLOCK_TO_SCREEN()

end sub
sub Item.TANDY2000_PROC_CONSTRUCT()
    static as Vector2D POLYGON2D_REP_0(0 to 2) = {Vector2D(-10,-10), Vector2D(140, 40), Vector2D(-13, 100)}
    _initAddSignal_("JUSTTREES")
    _initAddSignal_("NOTIMPORTANT")
    _initAddSlot_("MYONLYSLOT", ITEM_TANDY2000_SLOT_MYONLYSLOT_E)
    _initAddSlot_("TESTSLOT3", ITEM_TANDY2000_SLOT_TESTSLOT3_E)
    _initAddParameter_("TEST VECTOR2D", _ITEM_VALUE_VECTOR2D)
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "MY ONLY SLOT", "MYONLYSLOT", new Polygon2D(@(POLYGON2D_REP_0(0)), 3))
    _initAddValue_("TESTVALUE", _ITEM_VALUE_ZSTRING)
    link.dynamiccontroller_ptr->addPublishedValue(ID, "TESTVALUE")
end sub
