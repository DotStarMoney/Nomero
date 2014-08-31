#include "seqfile.bi"

using SeqFile

constructor Reader
    numActions = 0
    actionTree = allocate(sizeof(actionNode_t))
    actionTree->action = HEADER
    actionTree->childSize = 0
    actionTree->ref_ = 0 
    actionTree->size = 0
    actionTree->next_ = 0
    actionTree->parent_ = 0
    actionTree->lastChild_ = 0
    actionTree->referenceValue = 0
    actionTree->firstChild_ = 0
    curNode = actionTree
end constructor

destructor Reader
    deleteActionTree(actionTree)
end destructor

sub SeqFile.Reader.deleteActionTree(tree as actionNode_t ptr)
    if tree->firstChild_ <> 0 then deleteActionTree(tree->firstChild_)
    if tree->next_ <> 0 then deleteActionTree(tree->next_)
    deallocate tree
end sub

sub SeqFile.Reader.push(t as readType, pNum as integer = -1)
    dim as actionNode_t ptr node
    dim as actionNode_t ptr nodeFollowCount
     
    if t <> END_REPEAT then
    
        numActions += 1
        node = allocate(sizeof(actionNode_t))
        node->action = t
        node->childSize = 0
        node->referenceValue = 0
        node->lastChild_ = 0
        node->firstChild_ = 0
        node->parent_ = curNode
        
        if node->parent_->lastChild_ = 0 then
            node->parent_->lastChild_ = node
            node->parent_->firstChild_ = node
        else
            node->parent_->lastChild_->next_ = node
            node->parent_->lastChild_ = node
        end if
        
        node->next_ = 0
        select case t
        case READ_INTEGER
            node->size = sizeof(integer)
        case READ_DOUBLE
            node->size = sizeof(double)
        case READ_STRING
            node->size = sizeof(zstring ptr)
        case SET_REPEAT
            node->size = sizeof(any ptr)
            nodeFollowCount = node->parent_->firstChild_
            while nodeFollowCount <> 0
                pNum -= 1
                if pNum = 0 then exit while
                nodeFollowCount = nodeFollowCount->next_
            wend
            if nodeFollowCount <> 0 then node->ref_ = nodeFollowCount
            curNode = node
        end select   
        node->parent_->childSize += node->size
    else
        curNode = curNode->parent_
    end if
end sub

sub SeqFile.Reader.readFile(filename as string, _
                    byref data_ as any ptr)
    dim as integer f
    dim as string lne, text
    dim as actionNode_t ptr node, lastNode
    dim as integer charPos    
    dim as any ptr data_depth(READ_STACK_MAX - 1)
    dim as integer repetitions(READ_STACK_MAX - 1)
    dim as integer depth = 1
    dim as integer i, abort = 0
    dim as integer recycle = 0
    dim as integer numPieces
    redim as string pieces(0)
    dim as integer curChar, lastStop
    
    dim as integer ptr     int_ptr
    dim as double ptr      dbl_ptr
    dim as zstring ptr ptr zstr_ptr
    dim as any ptr ptr     any_ptr
    
    node = actionTree->firstChild_
    data_ = allocate(actionTree->childSize)
    data_depth(depth) = data_
    repetitions(depth) = 0
    
    f = freefile
    open filename for input as #f
        
    line input #f, lne
    while eof(f) = 0
        if recycle = 0 then
            charPos = instr(lne, "#")
            if charPos > 0 then lne = left(lne, charPos - 1)
            while left(lne, 1) = " " orElse left(lne, 1) = "\t"
                lne = right(lne, len(lne)-1)
            wend
            while right(lne, 1) = " " orElse right(lne, 1) = "\t"
                lne = left(lne, len(lne)-1)
            wend
        end if
        if lne <> "" then
            if instr(lne, ",") <> 0 then 
                curChar = 1
                numPieces = 0
                lastStop = 1
                while curChar <= len(lne)
                    if mid(lne, curChar, 1) = "," then
                        redim preserve as string pieces(numPieces)
                        pieces(numPieces) = mid(lne, lastStop, curChar - lastStop)
                        lastStop = curChar + 1
                        numPieces += 1
                    end if
                    curChar += 1
                wend
                redim preserve as string pieces(numPieces)
                pieces(numPieces) = mid(lne, lastStop, curChar - lastStop)
                numPieces += 1
            else
                redim as string pieces(0)
                pieces(0) = lne
                numPieces = 1
            end if
            recycle = 0
            for i = 0 to numPieces - 1
                text = pieces(i)
                lastNode = node
                select case node->action
                case READ_INTEGER
                    int_ptr = data_depth(depth)
                    *int_ptr = val(text)
                    data_depth(depth) += sizeof(integer)
                    node->referenceValue = *int_ptr
                    node = node->next_
                case READ_DOUBLE
                    dbl_ptr = data_depth(depth)
                    *dbl_ptr = val(text)
                    data_depth(depth) += sizeof(double)
                    node = node->next_
                case READ_STRING
                    text = mid(text, 2, len(text) - 2)
                    zstr_ptr = data_depth(depth)
                    *zstr_ptr = allocate(len(text) + 1)
                    **zstr_ptr = text
                    data_depth(depth) += sizeof(zstring ptr)
                    node = node->next_
                case SET_REPEAT
                    any_ptr = data_depth(depth)
                    if node->ref_->referenceValue <> 0 then
                        *any_ptr = allocate(node->childSize * node->ref_->referenceValue)
                        data_depth(depth) += sizeof(any ptr)
                        depth += 1
                        data_depth(depth) = *any_ptr
                        repetitions(depth) = node->ref_->referenceValue - 1
                        node = node->firstChild_
                    else
                        data_depth(depth) += sizeof(any ptr)
                        node = node->next_
                    end if
                    recycle = 1
                end select
                if node = 0 then
                    if repetitions(depth) = 0 then
                        do
                            node = lastNode->parent_
                            lastNode = node
                            depth -= 1
                        loop while node->next_ = 0 andAlso _
                                   repetitions(depth) = 0 andAlso _
                                   depth > 1
                        if node->next_ = 0 then
                            if depth < 2 then 
                                abort = 1 
                                exit for
                            end if
                            repetitions(depth) -= 1
                            node = node->parent_->firstChild_
                        else
                            node = node->next_
                        end if
                    else
                        repetitions(depth) -= 1
                        node = lastNode->parent_->firstChild_
                    end if
                end if
            next i
        end if
        if recycle = 0 then line input #f, lne
        if abort = 1 then exit while
    wend 
end sub
