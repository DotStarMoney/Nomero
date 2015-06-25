import os
import re

# ----------------------------- global funcs -----------------------------

def freshFile(filename):
    if os.path.exists(filename): os.remove(filename)
    open(filename, 'w').close()
    return filename

def getAllItemFiles():
    files = []
    for fn in os.listdir(objectDir):
        fn_fullPath = objectDir + fn
        if os.path.isfile(fn_fullPath) and not(fn.startswith("SAMPLE")):   
            files.append(fn_fullPath)
    return files
    
def catFiles(fileList, output):
    with open(output, 'w') as outfile:
        for fn in fileList:
            with open(fn) as infile:
                outfile.write(infile.read())   
                infile.close()
        outfile.close()
# -----------------------------------------------------------------
    
    
headerDir = 'objects\\headers\\'
objectDir = 'objects\\'

file_itemdefines = headerDir + 'gen_itemdefines.bi'

itemFiles = getAllItemFiles()
itemNames = []
itemPrefixes = []

# ---------------------------- main -------------------------------

freshFile(file_itemdefines)

#duplicate all item files and strip of other stuff that isn't part of a itemdefine
for curFileName in itemFiles:
    curFile = open(curFileName, "r")
    fileText = curFile.read()
      
    #extract object name, send to names types table
    objectNameSearch = re.search(r'^[ \t]*\'\#\w+[ \t]*$',fileText, flags = re.M | re.I)
    if objectNameSearch:
        objectName = objectNameSearch.group(0)[2:].upper()
        itemNames.append(objectName)
        itemPrefixes.append('ITEM_' + objectName + '_')
        
     
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
    
    
    
    