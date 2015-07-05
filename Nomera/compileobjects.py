import os
import re

# ----------------------------- global funcs -----------------------------

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
        
# class nameTypeEntry(object):
    # def __init__(self, name = '', type = ''):
        # self.stringName = name
        # self.stringType = type

SPACE_TAB = '    '
# -----------------------------------------------------------------
    
    
headerDir = 'objects\\headers\\'
objectDir = 'objects\\'

file_itemdefines = headerDir + 'gen_itemdefines.bi'
text_itemdefines = ''

file_namestypes = headerDir + 'gen_namestypes.bi'
text_namestypes = ''



itemFiles = getAllItemFiles()

itemPrefixes = []




# ---------------------------- main -------------------------------

freshFile(file_itemdefines)
freshFile(file_namestypes)



#duplicate all item files and strip of other stuff that isn't part of a itemdefine
for curFileName in itemFiles:
    curFile = open(curFileName, "r")
    fileText = curFile.read()
      
    #extract object name, send to names types table
    objectNameSearch = re.search(r'^[ \t]*\'\#[a-z0-9A-Z_ ]+$',fileText, flags = re.M | re.I)
    if objectNameSearch:
        objectName = objectNameSearch.group(0)[2:].upper()
        objectPrefix = ''
        for curChar in range(len(objectName)):
            if objectName[curChar] != ' ': 
                objectPrefix += objectName[curChar]
        objectPrefix = 'ITEM_' + objectPrefix
        itemPrefixes.append(objectPrefix)
        text_namestypes += '_addStringToType_(\"' + objectName + '\", ' + objectPrefix + ')\n'
        fileText = stripComments(fileText)
        
        initHeader = ''
        
        #find each signal line
        for lines in re.finditer(r'^[ \t]*signal[ \t]+.*?$', fileText, flags = re.M | re.I):
            curSignal = lines.group(0)
            curSignal = re.sub(r'[ \t]*', '', curSignal)
            curSignal = curSignal[7:].upper()
            initHeader += '_initAddSignal_(\"' + curSignal + '\")\n'
        fileText = re.sub(r'^[ \t]*signal[ \t]+.*?$', '', fileText, flags = re.M | re.I)
        
        #find each slot, add an _initAddSlot_ to the initslots text for init, add the slot enum name to the slot enum table (referenced for publishes later and for enum),
        #add a method definition to the slotdefs method definition text, convert it to method form, add the slot in method form to the slot method declaration text
        
        
        
        # for lines in re.finditer(r'^[ \t]*publish[ \t]+.*?$', fileText, flags = re.M | re.I):
            # curSignal = lines.group(0)
            # curSignal = re.sub(r'^[ \t]*publish[ \t]+', '', curSignal, flags = re.M | re.I)
            # if curSignal[:4].lower() == 'slot':
                # isSlot = 1
                # curSignal = curSignal[4:]
            # else:
                # isSlot = 0
                # curSignal = curSignal[5:]
            # curSignal = re.sub(r'^[ \t]*', '', curSignal, flags = re.M | re.I)
            # #now need to tokenize
            
            
        fileText = re.sub(r'^[ \t]*publish[ \t]+.*?$', '', fileText, flags = re.M | re.I)
        
        
        #newFileText = ''
        #for curLine in fileText.splitlines():
            
        
        
        # move all params, publishes and signal defines into init after declaration of local storage
        
        
        # # remove function blocks
        # fileText = re.sub(r'^[ \t]*function[ \t]+\w+\(.*?\).*?^[ \t]*end function[ \t]*(\'.*?$|$)', '', fileText, flags = re.M | re.S | re.I)
        # # remove comment lines
        # fileText = re.sub(r'^[ \t]*\'.*?$', '', fileText, flags = re.M | re.S | re.I)
        # # remove signal lines
        # fileText = re.sub(r'^[ \t]*signal.*?$', '', fileText, flags = re.M | re.S | re.I)
        # # remove slot blocks
        # fileText = re.sub(r'^[ \t]*slot[ \t]+\$\w+\(.*?\).*?^[ \t]*end slot[ \t]*(\'.*?$|$)', '', fileText, flags = re.M | re.S | re.I)
        # # remove publish lines
        # fileText = re.sub(r'^[ \t]*publish.*?$', '', fileText, flags = re.M | re.S | re.I)
        # # remove blank lines
        # fileText = re.sub(r'^[ \t]*\n', '', fileText, flags = re.M | re.S | re.I)  
        # # remove blank line at end of file
        # fileText = re.sub(r'\s*$', '', fileText, flags = re.S | re.I)  
    
    
text_itemdefines += '#ifndef GEN_ITEMDEFINES_BI\n#define GEN_ITEMDEFINES_BI\n'
text_itemdefines += 'enum Item_Type_e\n'
for prefix in itemPrefixes:
    text_itemdefines += SPACE_TAB + prefix + '\n'
text_itemdefines += 'end enum\n'

#
#

text_itemdefines += '#endif\n'
writeOutFile(file_itemdefines, text_itemdefines)


writeOutFile(file_namestypes, text_namestypes)
    
