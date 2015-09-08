import os
import re

# ----------------------------- global funcs -----------------------------
SPACE_TAB = '    '

def freshFile(filename):
    if os.path.exists(filename): os.remove(filename)
    open(filename, 'w').close()
    return filename
    
def writeOutFile(filename, text):
    f = open(filename, 'w')
    f.write(text)
    f.close()

def getAllItemFiles():
    files = []
    for fn in os.listdir(objectDir):
        fn_fullPath = objectDir + fn
        if os.path.isfile(fn_fullPath) and not(fn.startswith("SAMPLE")):   
            files.append(fn_fullPath)
    return files
    
    
def hSplit(s):
    parts = []
    bracket_level = 0
    in_quote = 0
    current = []
    # trick to remove special-case of trailing chars
    for c in (s + ","):
        if c == "," and bracket_level == 0 and in_quote == 0:
            parts.append("".join(current))
            current = []
        else:
            if (c == "{") or (c == "[") or (c == "("):
                bracket_level += 1
            elif (c == "}") or (c == "]") or (c == ")"):
                bracket_level -= 1
            elif (c == '\"'):
                in_quote = 1 - in_quote
            current.append(c)
    return parts

    
def stripComments(text):
    outText = ''
    curChar = ''
    buffer = ['', '']
    inQuote = 0
    inlineComment = 0
    blockComment = 0
    for curIndex in range(len(text)):
        if curIndex < len(text): curChar = text[curIndex]     
        buffer[1] = buffer[0]
        buffer[0] = curChar
        if curIndex >= 1:
            if blockComment == 1:
                if (buffer[1] == '\'') and (buffer[0] == '/'): blockComment = 0
            elif (inlineComment == 0) and (inQuote == 0):
                if (buffer[0] == '\''): 
                    if (buffer[1] == '/'):
                        blockComment = 1
                        outText = outText[:-1]
                    else:
                        inlineComment = 1
                else:
                    if (buffer[0] == '\"'):
                        inQuote = 1
                    elif (buffer[0] == '\n'):
                        inQuote = 0
                    outText += buffer[0]
            elif inlineComment == 1:
                if (buffer[0] == '\n'):
                    inlineComment = 0
                    outText += '\n'
            elif inQuote == 1:
                if (buffer[0] == '\"'): inQuote = 0
                outText += buffer[0]
        else:
            if (buffer[0] == '\''): 
                inlineComment = 1
            else:
                if (buffer[0] == '\"'): inQuote = 1
                outText += buffer[0]
    return outText
    
   
def catFiles(fileList, output):
    with open(output, 'w') as outfile:
        for fn in fileList:
            with open(fn) as infile:
                outfile.write(infile.read())   
                infile.close()
        outfile.close()
  
NO_QUOTE_SEARCHFOR = r''
NO_QUOTE_REPLACEWITH = ''  
def replaceNoQuoteFunc(X):
    if not X.group().startswith('\"'):
        return re.sub(NO_QUOTE_SEARCHFOR, NO_QUOTE_REPLACEWITH, X.group(), flags = re.I | re.M)
    return X.group()
    
def subNotInQuotes(trep, searchFor, replaceWith):
    global NO_QUOTE_SEARCHFOR
    global NO_QUOTE_REPLACEWITH
    NO_QUOTE_SEARCHFOR = searchFor
    NO_QUOTE_REPLACEWITH = replaceWith
    return re.sub(r"\"[^\"]*\"|[^\"]+", replaceNoQuoteFunc, trep, flags = re.I | re.M)

def fixPolygon2DInit(functionBlock):
    numReplacement = 0
    for poly2dgroup in re.finditer(r'\"[^\"\n]*Polygon2D[ \t]*\([ \t]*\{.*?\}[ \t]*\)[^\"\n]*\"|(?:[ \t=+,\(](Polygon2D[ \t]*\([ \t]*\{.*?\}[ \t]*\))(?:[ \t,\)]|$))', functionBlock, flags = re.I | re.M):
        poly2dtext = poly2dgroup.group(1)
        if poly2dtext:
            declaration = poly2dtext.strip()
            interior = declaration[9:-1].strip()[1:].strip()[1:-1].strip()
            numValues = re.sub(r'\(.*?\)', '', interior).count(',') + 1
            variableName = 'POLYGON2D_REP_' + str(numReplacement)
            newFunctionCall = 'Polygon2D(@(' + variableName + '(0)), ' + str(numValues) + ')' 
            functionBlockLines = functionBlock.splitlines()
            functionBlockLines.insert(1, SPACE_TAB + 'static as Vector2D ' + variableName + '(0 to ' + str(numValues - 1) + ')' + ' = {' + interior + '}')
            functionBlock = '\n'.join(functionBlockLines) + '\n'                
            functionBlock = subNotInQuotes(functionBlock, re.escape(declaration), newFunctionCall)
            numReplacement += 1
    return functionBlock

# -----------------------------------------------------------------
    
    
headerDir = 'objects\\headers\\'
objectDir = 'objects\\'

file_itemdefines = headerDir + 'gen_itemdefines.bi'
text_itemdefines = ''
file_namestypes = headerDir + 'gen_namestypes.bi'
text_namestypes = ''
file_methodprototypes = headerDir + 'gen_methodprototypes.bi'
text_methodprototypes = ''
file_methoddefinitions = headerDir + 'gen_methoddefinitions.bi'
text_methoddefinitions = ''
file_initcaseblock = headerDir + 'gen_initcaseblock.bi'
text_initcaseblock = ''
file_flushcaseblock = headerDir + 'gen_flushcaseblock.bi'
text_flushcaseblock = ''
file_runcaseblock = headerDir + 'gen_runcaseblock.bi'
text_runcaseblock = ''
file_drawcaseblock = headerDir + 'gen_drawcaseblock.bi'
text_drawcaseblock = ''
file_drawoverlaycaseblock = headerDir + 'gen_drawoverlaycaseblock.bi'
text_drawoverlaycaseblock = ''
file_slotcaseblock = headerDir + 'gen_slotcaseblock.bi'
text_slotcaseblock = ''
file_constructcaseblock = headerDir + 'gen_constructcaseblock.bi'
text_constructcaseblock = ''
file_serializeincaseblock = headerDir + 'gen_serializeincaseblock.bi'
text_serializeincaseblock = ''
file_serializeoutcaseblock = headerDir + 'gen_serializeoutcaseblock.bi'
text_serializeoutcaseblock = ''

itemFiles = getAllItemFiles()

itemPrefixes = []
slotPrefixes = []

itemUData = []


# ---------------------------- main -------------------------------

freshFile(file_itemdefines)
freshFile(file_namestypes)
freshFile(file_methodprototypes)
freshFile(file_methoddefinitions)
freshFile(file_initcaseblock)
freshFile(file_flushcaseblock)
freshFile(file_runcaseblock)
freshFile(file_drawcaseblock)
freshFile(file_drawoverlaycaseblock)
freshFile(file_slotcaseblock)
freshFile(file_constructcaseblock)
freshFile(file_serializeincaseblock)
freshFile(file_serializeoutcaseblock)

for curFileName in itemFiles:
    curFile = open(curFileName, "r")
    fileText = curFile.read()
    
      
    objectNameSearch = re.search(r'^[ \t]*\'\#[a-z0-9A-Z_ ]+$',fileText, flags = re.M | re.I)
    if objectNameSearch:
        objectName = objectNameSearch.group(0)[2:].upper()
        objectPrefix = ''
        for curChar in range(len(objectName)):
            if objectName[curChar] != ' ': 
                objectPrefix += objectName[curChar]
        objectShortPrefix = objectPrefix
        objectPrefix = 'ITEM_' + objectPrefix
        itemPrefixes.append(objectPrefix)
        text_namestypes += '_addStringToType_(\"' + objectName + '\", ' + objectPrefix + ')\n'
        fileText = stripComments(fileText)
          
        initHeader = ''
        initFooter = ''
        
        
        #prefix any consts, remove them and add them to itemprototypes, finally prefix any references to them in the code
        for lines in re.finditer(r'^[ \t]*const[ \t]+.*?$', fileText, flags = re.M | re.I):
            constLine = lines.group(0)
            constLine = re.sub(r'^[ \t]*const[ \t]+as[ \t]+', '', constLine, flags = re.I)
            constType = re.search(r'^[a-z0-9A-Z_]+', constLine, flags = re.I).group(0)
            constLine = re.sub(r'^[a-z0-9A-Z_]+', '', constLine, flags = re.I).strip()
            constLineMembers = constLine.split('=')
            constName = constLineMembers[0].strip()
            constValue = constLineMembers[1].strip()
            constPrefixName = objectShortPrefix + '_CONST_' + constName
            fileText = subNotInQuotes(fileText, r'(^|[\=\+\-/\*\t \(\[,])'+constName+r'($|[\=\+\-/\*\t \)\],])', r'\1'+constPrefixName+r'\2')     
      
        #prefix any types (that aren't item_data), remove them and add them to itemdefines, and prefix any references to them in the code
        hasItemData = 0
        for typeBlocksGroup in re.finditer(r'^[ \t]*type[ \t]+[a-z0-9A-Z_]+[ \t]*$.*?^[ \t]*end[ \t]+type[ \t]*$', fileText, flags = re.M | re.I | re.S):
            typeBlock = typeBlocksGroup.group(0)
            typeBlockLines = typeBlock.splitlines()
            typeFirstLine = typeBlockLines[0].strip()
            typeName = re.search(r'[a-z0-9A-Z_]+[ \t]*$', typeFirstLine, re.I).group(0)            
            if typeName.upper() != 'ITEM_DATA':
                typePrefixName = objectPrefix + '_TYPE_' + typeName
            else:
                typePrefixName = objectPrefix + '_TYPE_DATA'
                itemDataPtr = objectShortPrefix + '_DATA'
                itemUData.append('as ' + typePrefixName + ' ptr ' + itemDataPtr)
                hasItemData = 1
                dataTypePrefixName = typePrefixName
            fileText = subNotInQuotes(fileText, r'([ \t])'+typeName+r'([\.\(\[ \t]|$)', r'\1'+typePrefixName+r'\2') 

        #prefix any defines, remove them and add them to itemdefinitions, prefix any references to them in the code
        for lines in re.finditer(r'^[ \t]*#define[ \t]+.*?$', fileText, flags = re.M | re.I):
            defineLine = lines.group(0)
            defineLine = re.sub(r'^[ \t]*#define[ \t]+', '', defineLine, flags = re.I)
            defineName = re.search(r'^[a-z0-9A-Z_]+[ \t]+', defineLine).group(0).strip()
            definePrefixName = objectPrefix + '_DEFINE_' + defineName
            fileText = subNotInQuotes(fileText, r'(^|[\=\+\-/\*\t \(\[,\.])'+defineName+r'($|[\=\+\-/\*\t \)\],\.])(?!\")', r'\1'+definePrefixName+r'\2')             
        
        #prefix any non_critical functions, prefix any references to them in the code
        for functionsBlocksGroup in re.finditer(r'^[ \t]*function[ \t]+\w+[ \t]*\(.*?\).*?^[ \t]*end[ \t]+function[ \t]*$', fileText, flags = re.M | re.S | re.I):
            functionBlock = functionsBlocksGroup.group(0)
            functionBlockLines = functionBlock.splitlines()
            functionFirstLine = functionBlockLines[0].strip()[9:].strip()
            functionArgs = re.sub(r'^[^\(]*', '', functionFirstLine)
            functionName = re.sub(r'\(.*$', '', functionFirstLine)
            if (functionName.upper() != '_INIT') and \
               (functionName.upper() != '_FLUSH') and \
               (functionName.upper() != '_DRAW') and \
               (functionName.upper() != '_DRAWOVERLAY') and \
               (functionName.upper() != '_RUN'):
               
                if functionFirstLine[-1:] != ')':
                    functionPrefixName = objectShortPrefix + '_FUNCTION_' + functionName
                    functionHeader = 'function ' + functionPrefixName + functionArgs
                    functionBlockLines[0] = functionHeader
                    functionBlockLines[-1] = 'end function'             
                else:
                    functionPrefixName = objectShortPrefix + '_SUB_' + functionName
                    functionHeader = 'sub ' + functionPrefixName + functionArgs
                    functionBlockLines[0] = functionHeader
                    functionBlockLines[-1] = 'end sub'                     
                functionBlock = '\n'.join(functionBlockLines) + '\n'                
                fileText = re.sub(r'^[ \t]*function[ \t]+' + functionName + r'[ \t]*\(.*?\).*?^[ \t]*end[ \t]+function[ \t]*$', functionBlock, fileText, flags = re.M | re.S | re.I)
                fileText = subNotInQuotes(fileText, r'(^|[\=\+\-/\*\t \(\[,])'+functionName+r'($|[\=\+\-/\*\t \)\],\(\[])', r'\1'+functionPrefixName+r'\2') 
        
        for macroBlockGroup in re.finditer(r'^[ \t]*#macro[ \t]+\w+\(.*?\).*?^[ \t]*#endmacro[ \t]*$', fileText, flags = re.M | re.S | re.I):
            macroBlock = macroBlockGroup.group(0)
            macroBlockLines = macroBlock.splitlines()
            macroFirstLine = macroBlockLines[0].strip()
            macroName = re.sub(r'\(.*$', '', macroFirstLine[7:])
            macroArgs = re.sub(r'^[^\(]+', '', macroFirstLine[7:])
            macroPrefixName = objectPrefix + '_MACRO_' + macroName
            fileText = subNotInQuotes(fileText, r'(^|[\=\+\-/\*\t \(\[,\.\(\[])'+macroName+r'($|[\=\+\-/\*\t \)\],\.\(\[])', r'\1'+macroPrefixName+r'\2')             

        if hasItemData == 1:
            fileText = subNotInQuotes(fileText, r'(^|[ \t\,\-\*\+/\=\[\(])data\.', r'\1data_.' + itemDataPtr + r'->')          
           
        for throwBlockGroup in re.finditer(r'(?:\"[^\"\n]*throw[ \t]*\(.*\)[^\"\n]*\")|((?:[^a-z0-9A-Z_]|^)throw[ \t]*\(.*?\))', fileText, flags = re.I | re.M):
            if throwBlockGroup.group(0):
                throwLine = throwBlockGroup.group(0).strip()
                if not throwLine.upper().startswith('T'): 
                    throwLine = throwLine[1:]
                throwLineP = throwLine[6:-1]
                if throwLineP.startswith('$'):
                    signalEscape = re.search(r'throw[ \t]*\([ \t]*\$[a-z0-9A-Z_]+', throwLine, flags = re.I).group(0)
                    signalName = re.search(r'\$([a-z0-9A-Z_]+)', throwLineP, flags = re.I).group(1).upper()
                    fileText = subNotInQuotes(fileText, re.escape(signalEscape), 'throw(\"'+signalName+'\"')
        
        fileText = subNotInQuotes(fileText, r'([ \t])valueset([ \t\[\(])', r'\1ObjectValueSet\2')
        fileText = subNotInQuotes(fileText, r'([ \t])slotset([ \t\[\(])', r'\1ObjectSlotSet\2')
        
        fileText = subNotInQuotes(fileText, r'fireSlot[ \t]*\([ \t]*\$([a-z0-9A-Z_]+)', r'fireSlot("\1"')

                
        for lines in re.finditer(r'^[ \t]*const[ \t]+.*?$', fileText, flags = re.M | re.I):
            constLine = lines.group(0)
            text_methodprototypes += constLine + '\n'
        fileText = re.sub(r'^[ \t]*const[ \t]+.*?$', '', fileText, flags = re.M | re.I)
        for typeBlocksGroup in re.finditer(r'^[ \t]*type[ \t]+[a-z0-9A-Z_]+[ \t]*$.*?^[ \t]*end[ \t]+type[ \t]*$', fileText, flags = re.M | re.I | re.S):
            typeBlock = typeBlocksGroup.group(0)
            text_itemdefines += typeBlock + '\n'     
        fileText = re.sub(r'^[ \t]*type[ \t]+[a-z0-9A-Z_]+[ \t]*$.*?^[ \t]*end[ \t]+type[ \t]*$', '', fileText, flags = re.M | re.I | re.S)        
        for lines in re.finditer(r'^[ \t]*#define[ \t]+.*?$', fileText, flags = re.M | re.I):
            defineLine = lines.group(0).strip()
            text_methoddefinitions += defineLine + '\n'
        fileText = re.sub(r'^[ \t]*#define[ \t]+.*?$', '', fileText, flags = re.M | re.I)
        for functionsBlocksGroup in re.finditer(r'^[ \t]*function[ \t]+\w+[ \t]*\(.*?\).*?^[ \t]*end[ \t]+function[ \t]*$', fileText, flags = re.M | re.S | re.I):
            functionBlock = functionsBlocksGroup.group(0)
            functionBlockLines = functionBlock.splitlines()
            functionFirstLine = functionBlockLines[0].strip()
            functionArgs = re.sub(r'^[^\(]*', '', functionFirstLine)
            functionName = re.sub(r'\(.*$', '', functionFirstLine[9:])
            if (functionName.upper() != '_INIT') and \
               (functionName.upper() != '_FLUSH') and \
               (functionName.upper() != '_DRAW') and \
               (functionName.upper() != '_DRAWOVERLAY') and \
               (functionName.upper() != '_RUN'):
                functionBlockLines[0] = 'function Item.' + objectShortPrefix + functionName + functionArgs
                functionBlock = '\n'.join(functionBlockLines) + '\n'                
                text_methodprototypes += 'declare ' + functionBlockLines[0] + '\n'
                text_methoddefinitions += fixPolygon2DInit(functionBlock)
				
				
                fileText = re.sub(r'^[ \t]*function[ \t]+' + functionName + r'[ \t]*\(.*?\).*?^[ \t]*end[ \t]+function[ \t]*$', '', fileText, flags = re.M | re.S | re.I)
        for functionsBlocksGroup in re.finditer(r'^[ \t]*sub[ \t]+\w+\(.*?\).*?^[ \t]*end[ \t]+sub[ \t]*$', fileText, flags = re.M | re.S | re.I):
            functionBlock = functionsBlocksGroup.group(0)
            functionBlockLines = functionBlock.splitlines()
            functionFirstLine = functionBlockLines[0].strip()
            functionArgs = re.sub(r'^[^\(]*', '', functionFirstLine)
            functionName = re.sub(r'\(.*$', '', functionFirstLine[4:])
            functionBlockLines[0] = 'sub Item.' + functionName + functionArgs
            functionBlock = '\n'.join(functionBlockLines) + '\n'                
            text_methodprototypes += 'declare ' + functionFirstLine + '\n'
            text_methoddefinitions += fixPolygon2DInit(functionBlock)
            fileText = re.sub(r'^[ \t]*sub[ \t]+' + functionName + r'[ \t]*\(.*?\).*?^[ \t]*end[ \t]+sub[ \t]*$', '', fileText, flags = re.M | re.S | re.I)
        for macroBlockGroup in re.finditer(r'^[ \t]*#macro[ \t]+\w+\(.*?\).*?^[ \t]*#endmacro[ \t]*$', fileText, flags = re.M | re.S | re.I):
            macroBlock = macroBlockGroup.group(0)
            text_methoddefinitions += fixPolygon2DInit(macroBlock) + '\n'
        fileText = re.sub(r'^[ \t]*#macro[ \t]+\w+[ \t]*\(.*?\).*?^[ \t]*#endmacro[ \t]*$', '', fileText, flags = re.M | re.I | re.S)
             
              
        for lines in re.finditer(r'^[ \t]*signal[ \t]+.*?$', fileText, flags = re.M | re.I):
            curSignal = lines.group(0)
            curSignal = re.sub(r'[ \t]*', '', curSignal)
            curSignal = curSignal[7:].upper()
            initHeader += SPACE_TAB+'_initAddSignal_(\"' + curSignal + '\")\n'
        fileText = re.sub(r'^[ \t]*signal[ \t]+.*?$', '', fileText, flags = re.M | re.I)
        
        for slotBlockGroup in re.finditer(r'^[ \t]*slot[ \t]+\$\w+[ \t]*\(.*?\).*?^[ \t]*end[ \t]+slot[ \t]*(\'.*?$|$)', fileText, flags = re.M | re.S | re.I):
            slotBlock = slotBlockGroup.group(0)
            slotParamsTypes = []
            slotParams = []
            stringLines = slotBlock.splitlines()
            firstLine = stringLines[0][4:]
            firstLine = re.sub(r'^[ \t]*\$', '', firstLine)
            slotName = re.search(r'^[^\(]*', firstLine).group(0).upper() #firstThing
            slotNameEnum = objectPrefix + '_SLOT_' + slotName + '_E'
            slotNameSub = objectShortPrefix + '_SLOT_' + slotName
            slotPrefixes.append(slotNameEnum)
            firstLine = re.sub(r'^[^\(]*\(', '', firstLine).strip()[:-1]
            if firstLine != '':
                parameters = hSplit(firstLine)
                for curParam in parameters:
                    curParam = curParam.strip()
                    curPTypeGroup = re.search(r'[a-z0-9A-Z_]+$', curParam, flags = re.I)
                    if curPTypeGroup:
                        slotParamsTypes.append(curPTypeGroup.group(0))
                    curPNameGroup = re.search(r'^[a-z0-9A-Z_]+', curParam, flags = re.I)
                    if curPNameGroup:
                        slotParams.append(curPNameGroup.group(0))                    
            initHeader += SPACE_TAB+'_initAddSlot_(\"' + slotName + '\", ' + slotNameEnum + ')\n'
            text_methodprototypes += 'declare sub ' + slotNameSub + '(pvPair() as _Item_slotValuePair_t)\n'
            text_slotcaseblock += 'case ' + slotNameEnum + '\n'
            text_slotcaseblock += SPACE_TAB + slotNameSub + '(pvPair())\n'
            del stringLines[0]
            stringLines.insert(0, 'sub Item.' + slotNameSub + '(pvPair() as _Item_slotValuePair_t)') 
            del stringLines[len(stringLines) - 1]
            stringLines.append('end sub')
            for index in range(len(slotParams)):
                stringLines.insert(1, SPACE_TAB + 'matchParameter(' + slotParams[index] + ', \"' + slotParams[index].upper() + '\", pvPair())')
            for index in range(len(slotParams)):
                stringLines.insert(1, SPACE_TAB + 'dim as ' + slotParamsTypes[index] + ' ' + slotParams[index])
            slotText = '\n'.join(stringLines) + '\n'
            text_methoddefinitions += fixPolygon2DInit(slotText)
        fileText = re.sub(r'^[ \t]*slot[ \t]+\$\w+[ \t]*\(.*?\).*?^[ \t]*end[ \t]+slot[ \t]*(\'.*?$|$)', '', fileText, flags = re.I | re.M | re.S)        
        
        for lines in re.finditer(r'^[ \t]*parameter[ \t]+.*?$', fileText, flags = re.M | re.I):
            curParam = lines.group(0).strip()
            curParam = re.sub(r'^parameter[ \t]*', '', curParam, flags = re.I)
            curParamParts = curParam.split(',')
            paramTag = curParamParts[0].strip().upper()
            curParamParts[1] = curParamParts[1].strip().upper()
            if curParamParts[1] == 'VECTOR2D':
                paramType = '_ITEM_VALUE_VECTOR2D'
            elif curParamParts[1] == 'DOUBLE':
                paramType = '_ITEM_VALUE_DOUBLE'
            elif curParamParts[1] == 'STRING':   
                paramType = '_ITEM_VALUE_ZSTRING'
            else:
                paramType = '_ITEM_VALUE_INTEGER'
            initHeader += SPACE_TAB+'_initAddParameter_(' + paramTag + ', ' + paramType + ')\n'
        fileText = re.sub(r'^[ \t]*parameter[ \t]+.*?$', '', fileText, flags = re.M | re.I)

        for lines in re.finditer(r'^[ \t]*publish[ \t]+(?:(?:value)|(?:slot))[ \t]*.*$', fileText, flags = re.M | re.I):
            curPublish = lines.group(0).strip()
            curPublish = re.sub(r'^publish[ \t]+', '', curPublish, flags = re.I)
            if curPublish.startswith('slot'):
                curPublish = re.sub(r'^slot[ \t]+', '', curPublish, flags = re.I)
                curPublishItems = hSplit(curPublish)
                publishSlotTag = curPublishItems[0].strip().upper()
                publishSlotName = curPublishItems[1].strip().upper()[1:]
                if len(curPublishItems) > 2:
                    publishSlotShape = curPublishItems[2].strip()
                    initFooter += SPACE_TAB+'link.dynamiccontroller_ptr->addPublishedSlot(ID, ' + publishSlotTag + ', \"' + publishSlotName + '\", new ' + publishSlotShape + ')\n'
                    initFooter += SPACE_TAB+'link.dynamiccontroller_ptr->setTargetSlotOffset(ID, ' + publishSlotTag + ', p)\n'
                else:
                    initFooter += SPACE_TAB+'link.dynamiccontroller_ptr->addPublishedSlot(ID, ' + publishSlotTag + ', \"' + publishSlotName + '\")\n'                
            else:
                curPublish = re.sub(r'^value[ \t]+', '', curPublish, flags = re.I)
                curPublishItems = hSplit(curPublish)
                publishValueTag = curPublishItems[0].strip().upper()
                publishValueType = curPublishItems[1].strip().upper()
                if publishValueType == 'VECTOR2D':
                    publishValueType = '_ITEM_VALUE_VECTOR2D'
                elif publishValueType == 'DOUBLE':
                    publishValueType = '_ITEM_VALUE_DOUBLE'
                elif publishValueType == 'STRING':   
                    publishValueType = '_ITEM_VALUE_ZSTRING'
                else:
                    publishValueType = '_ITEM_VALUE_INTEGER'                
                if len(curPublishItems) > 2:
                    publishValueShape = curPublishItems[2].strip()
                    initFooter += SPACE_TAB+'_initAddValue_(' + publishValueTag + ', ' + publishValueType + ')\n'
                    initFooter += SPACE_TAB+'link.dynamiccontroller_ptr->addPublishedValue(ID, ' + publishValueTag + ', new ' + publishValueShape + ')\n'
                    initFooter += SPACE_TAB+'link.dynamiccontroller_ptr->setTargetValueOffset(ID, ' + publishValueTag + ', p)\n'
                else:
                    initFooter += SPACE_TAB+'_initAddValue_(' + publishValueTag + ', ' + publishValueType + ')\n'
                    initFooter += SPACE_TAB+'link.dynamiccontroller_ptr->addPublishedValue(ID, ' + publishValueTag + ')\n'
            fileText = re.sub(r'^[ \t]*publish[ \t]+(?:(?:value)|(?:slot))[ \t]*.*$', '', fileText, flags = re.M | re.I)

        
        
        #init
        fInitGroup = re.search(r'^[ \t]*function[ \t]+_init[ \t]*\(.*?\).*?^[ \t]*end[ \t]+function[ \t]*(\'.*?$|$)', fileText, flags = re.M | re.I | re.S)
        if fInitGroup:
            fInit = fInitGroup.group(0)
            fInitLines = fInit.splitlines()
            fInitProto = objectShortPrefix + '_PROC_INIT()'
            fInitLines[0] = 'sub Item.' + fInitProto
            if hasItemData == 1: fInitLines.insert(1, SPACE_TAB + 'data_.' + itemDataPtr + ' = new ' + dataTypePrefixName)
            fInitLines.pop(-1)
            fInit = fixPolygon2DInit('\n'.join(fInitLines) + '\n') + initFooter + 'end sub\n'
            text_methoddefinitions += fInit
            text_methodprototypes += 'declare sub ' + fInitProto + '\n'
            text_initcaseblock += 'case ' + objectPrefix + '\n' + SPACE_TAB + fInitProto + '\n'
        
        
        #flush
        fFlushGroup = re.search(r'^[ \t]*function[ \t]+_flush[ \t]*\(.*?\).*?^[ \t]*end[ \t]+function[ \t]*(\'.*?$|$)', fileText, flags = re.M | re.I | re.S)
        if fFlushGroup:
            fFlush = fFlushGroup.group(0)
            fFlushLines = fFlush.splitlines()
            fFlushProto = objectShortPrefix + '_PROC_FLUSH()'
            fFlushLines[0] = 'sub Item.' + fFlushProto
            fFlushLines.insert(-1, SPACE_TAB + 'if anims_n then delete(anims)')
            if hasItemData == 1: 
                fFlushLines.insert(-1, SPACE_TAB + 'if data_.' + itemDataPtr + ' then delete(data_.' + itemDataPtr + ')')
                fFlushLines.insert(-1, SPACE_TAB + 'data_.' + itemDataPtr + ' = 0')                
            fFlushLines[-1] = 'end sub'
            fFlush = fixPolygon2DInit('\n'.join(fFlushLines) + '\n')
            text_methoddefinitions += fFlush
            text_methodprototypes += 'declare sub ' + fFlushProto + '\n'
            text_flushcaseblock += 'case ' + objectPrefix + '\n' + SPACE_TAB + fFlushProto + '\n'        
        
        
        
        #run
        fRunGroup = re.search(r'^[ \t]*function[ \t]+_run[ \t]*\(.*?\).*?^[ \t]*end[ \t]+function[ \t]*(\'.*?$|$)', fileText, flags = re.M | re.I | re.S)
        if fRunGroup:
            fRun = fRunGroup.group(0)
            fRunLines = fRun.splitlines()
            fRunProto = objectShortPrefix + '_PROC_RUN(t as double)'
            fRunLines[0] = 'function Item.' + fRunProto + ' as integer'
            fRunLines.insert(-1, SPACE_TAB + 'return 0')
            fRunLines[-1] = 'end function'
            fRun = fixPolygon2DInit('\n'.join(fRunLines) + '\n')
            text_methoddefinitions += fRun
            text_methodprototypes += 'declare function ' + fRunProto + ' as integer\n'
            text_runcaseblock += 'case ' + objectPrefix + '\n' + SPACE_TAB + 'return ' + objectShortPrefix + '_PROC_RUN(t)' + '\n'           
        
        
        
        
        #draw
        fDrawGroup = re.search(r'^[ \t]*function[ \t]+_draw[ \t]*\(.*?\).*?^[ \t]*end[ \t]+function[ \t]*(\'.*?$|$)', fileText, flags = re.M | re.I | re.S)
        if fDrawGroup:
            fDraw = fDrawGroup.group(0)
            fDrawLines = fDraw.splitlines()
            fDrawProto = objectShortPrefix + '_PROC_DRAW(scnbuff as integer ptr)'
            fDrawLines[0] = 'sub Item.' + fDrawProto
            fDrawLines[-1] = 'end sub'
            fDraw = fixPolygon2DInit('\n'.join(fDrawLines) + '\n')
            text_methoddefinitions += fDraw
            text_methodprototypes += 'declare sub ' + fDrawProto + '\n'
            text_drawcaseblock += 'case ' + objectPrefix + '\n' + SPACE_TAB + objectShortPrefix + '_PROC_DRAW(scnbuff)' + '\n'           
        
                
        #draw overlay
        fDrawOGroup = re.search(r'^[ \t]*function[ \t]+_drawOverlay[ \t]*\(.*?\).*?^[ \t]*end[ \t]+function[ \t]*(\'.*?$|$)', fileText, flags = re.M | re.I | re.S)
        if fFlushGroup:
            fDrawO = fDrawOGroup.group(0)
            fDrawOLines = fDrawO.splitlines()
            fDrawOProto = objectShortPrefix + '_PROC_DRAWOVERLAY(scnbuff as integer ptr)'
            fDrawOLines[0] = 'sub Item.' + fDrawOProto
            fDrawOLines[-1] = 'end sub'
            fDrawO = fixPolygon2DInit('\n'.join(fDrawOLines) + '\n')
            text_methoddefinitions += fDrawO
            text_methodprototypes += 'declare sub ' + fDrawOProto + '\n'
            text_drawoverlaycaseblock += 'case ' + objectPrefix + '\n' + SPACE_TAB + objectShortPrefix + '_PROC_DRAWOVERLAY(scnbuff)' + '\n'           
        
        #serialize_in
        fSerializeInGroup = re.search(r'^[ \t]*function[ \t]+_serialize_in[ \t]*\(.*?\).*?^[ \t]*end[ \t]+function[ \t]*(\'.*?$|$)', fileText, flags = re.M | re.I | re.S)
        if fSerializeInGroup:
            fSerializeIn = fSerializeInGroup.group(0)
            fSerializeInLines = fSerializeIn.splitlines()
            fSerializeInProto = objectShortPrefix + '_PROC_SERIALIZEIN(bindata as byte ptr)'
            fSerializeInLines[0] = 'sub Item.' + fSerializeInProto
			fSerializeInLines.insert(1, SPACE_TAB + 'dim as integer SERIALIZEIN_currentByte')
			fSerializeInLines.insert(2, SPACE_TAB + 'SERIALIZEIN_currentByte = 0')
            fSerializeInLines[-1] = 'end sub'
            fSerializeIn = fixPolygon2DInit('\n'.join(fSerializeInLines) + '\n')
			fSerializeIn = subNotInQuotes(fSerializeIn, r'([ \t])valueset([ \t\[\(])', r'\1ObjectValueSet\2')
			
            text_methoddefinitions += fSerializeIn
            text_methodprototypes += 'declare sub ' + fSerializeInProto + '\n'
            text_serializeincaseblock += 'case ' + objectPrefix + '\n' + SPACE_TAB + objectShortPrefix + '_PROC_SERIALIZEIN((bindata as byte ptr)' + '\n'       		
		
		
        constructProto = objectShortPrefix + '_PROC_CONSTRUCT()'
        initHeader = 'sub Item.' + constructProto + '\n' + initHeader + 'end sub\n'
        initHeader = fixPolygon2DInit(initHeader)
        text_methoddefinitions += initHeader
        text_methodprototypes += 'declare sub ' + constructProto + '\n'
        text_constructcaseblock += 'case ' + objectPrefix + '\n' + SPACE_TAB + objectShortPrefix + '_PROC_CONSTRUCT()\n'

        
        
   
     
text_itemdefines = '#ifndef GEN_ITEMDEFINES_BI\n#define GEN_ITEMDEFINES_BI\n' + text_itemdefines
text_itemdefines += 'enum Item_Type_e\n'
text_itemdefines += SPACE_TAB + 'ITEM_NONE\n'
for prefix in itemPrefixes:
    text_itemdefines += SPACE_TAB + prefix + '\n'
text_itemdefines += 'end enum\n'
text_itemdefines += 'enum Item_slotEnum_e\n'
for prefix in slotPrefixes:
    text_itemdefines += SPACE_TAB + prefix + '\n'
text_itemdefines += 'end enum\n'
text_itemdefines += 'union Item_objectData_u\n'
for prefix in itemUData:
    text_itemdefines += SPACE_TAB + prefix + '\n'
text_itemdefines += 'end union\n'
text_itemdefines += '#endif\n'

text_initcaseblock = 'select case itemType\n' + text_initcaseblock + 'end select\n'
text_flushcaseblock = 'select case itemType\n' + text_flushcaseblock + 'end select\n'
text_runcaseblock = 'select case itemType\n' + text_runcaseblock + 'end select\n'
text_drawcaseblock = 'select case itemType\n' + text_drawcaseblock + 'end select\n'
text_drawoverlaycaseblock = 'select case itemType\n' + text_drawoverlaycaseblock + 'end select\n'
text_slotcaseblock = 'select case slotNumber\n' + text_slotcaseblock + 'end select\n'
text_constructcaseblock = 'select case itemType\n' + text_constructcaseblock + 'end select\n'

writeOutFile(file_itemdefines, text_itemdefines)
writeOutFile(file_namestypes, text_namestypes)
writeOutFile(file_methodprototypes, text_methodprototypes)
writeOutFile(file_methoddefinitions, text_methoddefinitions)
writeOutFile(file_initcaseblock, text_initcaseblock)
writeOutFile(file_flushcaseblock, text_flushcaseblock)
writeOutFile(file_runcaseblock, text_runcaseblock)
writeOutFile(file_drawcaseblock, text_drawcaseblock)
writeOutFile(file_drawoverlaycaseblock, text_drawoverlaycaseblock)
writeOutFile(file_slotcaseblock, text_slotcaseblock)
writeOutFile(file_constructcaseblock, text_constructcaseblock)

       
