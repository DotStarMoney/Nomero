#include "tree2d.bi"
#include "utility.bi"
#include "vector2d.bi"

#macro REQUEST_NODE(X)
    X = nodePool + nodePool_usage
    nodePool_usage += 1
#endmacro

#define GET_AREA(A) (A.br.x - A.tl.x)*(A.br.y - A.tl.y)

sub Tree2DDebugPrint(node as Tree2D_node ptr, isLeft as integer, level as integer)
    dim as integer i
    if node = 0 then
        '
    else
        Tree2DDebugPrint(node->right_, 0, level + 1)
        'for i = 0 to level-1
        '    print "-";
        'next i    
        'if level > 0 then
        '    if isLeft = 0 then
        '        print "/";
        '    else
        '        print "\";
        '    end if
        'end if
        'print str(node->area)
        if node->right_ = 0 andAlso node->left_ = 0 then
            line (450+ node->square.tl.x * 0.5+1, node->square.tl.y * 0.5+1)-(450+ node->square.br.x * 0.5-1, node->square.br.y * 0.5-1), rgb(level*8972347, level*2348970, level*7233), BF       
        else
            line (450+ node->square.tl.x * 0.5, node->square.tl.y * 0.5)-(450 + node->square.br.x * 0.5, node->square.br.y * 0.5), rgb(level*8972347, level*2348970, level*7233), B
        end if
        Tree2DDebugPrint(node->left_, 1, level + 1)
    end if
end sub

constructor Tree2D_Square()
    ''
end constructor

constructor Tree2D_Square(tl_p as Vector2D, br_p as Vector2D, x0_p as integer, y0_p as integer, x1_p as integer, y1_p as integer)
    tl = tl_p
    br = br_p
    x0 = x0_p
    y0 = y0_p
    x1 = x1_p
    y1 = y1_p
end constructor

constructor Tree2d(maxNodes as integer)
    nodePool = allocate(maxNodes * sizeof(Tree2D_Node))
    nodePool_capacity = maxNodes
    nodePool_usage = 0
    root_ = 0
end constructor

destructor Tree2d()
    deallocate(nodePool)
end destructor
  
function Tree2d.getRoot() as Tree2D_Node ptr
    return root_
end function
  
function Tree2d.insert(newSquare as Tree2D_Square) as Tree2D_Node ptr

    #macro GET_MINMAX_SQUARE(A, B, C)
        min_x = B.tl.x
        C.x0 = B.x0
        if A.tl.x < B.tl.x then 
            min_x = A.tl.x
            C.x0 = A.x0
        end if
        min_y = B.tl.y
        C.y0 = B.y0
        if A.tl.y < B.tl.y then 
            min_y = A.tl.y        
            C.y0 = A.y0
        end if
        max_x = B.br.x
        C.x1 = B.x1
        if A.br.x > B.br.x then 
            max_x = A.br.x      
            C.x1 = A.x1
        end if
        max_y = B.br.y
        C.y1 = B.y1
        if A.br.y > B.br.y then 
            max_y = A.br.y
            C.y1 = A.y1
        end if
        C.tl = Vector2D(min_x, min_y)
        C.br = Vector2D(max_x, max_y)
    #endmacro
    
    dim as Tree2D_node ptr curNode
    dim as Tree2D_Square ptr squareNodeL, squareNodeR
    dim as integer termCond
    dim as Tree2D_Square squareL, squareR
    dim as Tree2D_Square ptr lastSquare
    dim as double sizeL, sizeR, lastArea
    dim as double max_x, max_y, min_x, min_y

    if root_ = 0 then
        REQUEST_NODE(root_)
        root_->left_ = 0
        root_->right_ = 0
        root_->square = newSquare
        root_->area = GET_AREA(newSquare)
        root_->parent_ = 0
        return root_
    else
        curNode = root_

        GET_MINMAX_SQUARE(curNode->square, newSquare, squareL)
        
        lastArea = GET_AREA(squareL)
        lastSquare = @squareL
        
        while (cint(curNode->left_) or cint(curNode->right_))        
            curNode->square = *lastSquare
            squareNodeL = @(curNode->left_->square)
            squareNodeR = @(curNode->right_->square)
                       
            GET_MINMAX_SQUARE((*squareNodeL), newSquare, squareL)
            GET_MINMAX_SQUARE((*squareNodeR), newSquare, squareR)
            
            sizeL = GET_AREA(squareL)
            sizeR = GET_AREA(squareR)
           
            if (sizeL - curNode->left_->area) > (sizeR - curNode->right_->area) then
                curNode = curNode->right_
                lastSquare = @squareR
                lastArea = sizeR
            else
                curNode = curNode->left_
                lastSquare = @squareL
                lastArea = sizeL
            end if
        wend 
        
        REQUEST_NODE(curNode->left_)
        REQUEST_NODE(curNode->right_)
        
        curNode->left_->left_ = 0
        curNode->left_->right_ = 0
        curNode->left_->parent_ = curNode
        curNode->left_->area = curNode->area
        curNode->left_->square = curNode->square
 
        curNode->right_->left_ = 0
        curNode->right_->right_ = 0
        curNode->right_->parent_ = curNode
        curNode->right_->area = GET_AREA(newSquare)
        curNode->right_->square = newSquare
 
        curNode->square = *lastSquare
        curNode->area = lastArea
        
        return curNode->right_
    end if
end function

sub Tree2d.flush()
    nodePool_usage = 0
    root_ = 0
end sub

sub Tree2d.splitNode(splitSquare as Tree2D_Square, node_ as Tree2D_Node ptr)
          
    #macro GET_MINMAX_SQUARE(A, B, C)
        min_x = B.tl.x
        C.x0 = B.x0
        if A.tl.x < B.tl.x then 
            min_x = A.tl.x
            C.x0 = A.x0
        end if
        min_y = B.tl.y
        C.y0 = B.y0
        if A.tl.y < B.tl.y then 
            min_y = A.tl.y        
            C.y0 = A.y0
        end if
        max_x = B.br.x
        C.x1 = B.x1
        if A.br.x > B.br.x then 
            max_x = A.br.x      
            C.x1 = A.x1
        end if
        max_y = B.br.y
        C.y1 = B.y1
        if A.br.y > B.br.y then 
            max_y = A.br.y
            C.y1 = A.y1
        end if
        C.tl = Vector2D(min_x, min_y)
        C.br = Vector2D(max_x, max_y)
    #endmacro
     
    #macro PUSH_SPLIT(A_PTR)
        splitStack(splitStackPointer) = A_PTR
        splitStackPointer += 1
    #endmacro
    
    #macro POP_SPLIT(A_PTR)
        splitStackPointer -= 1
        A_PTR = splitStack(splitStackPointer)
    #endmacro
    
    #macro INIT_NODE(A_PTR)
        A_PTR->left_ = 0
        A_PTR->right_ = 0
        A_PTR->area = GET_AREA(A_PTR->square)
    #endmacro
    
    #macro FIX_NODE()
        print "fixing nodes up to node_ starting with node "; fixNode
        sleep
        while (fixNode <> 0) andAlso (fixNode <> node_)
            'print "", fixNode->left_;","; fixNode->right_
            'sleep
            GET_MINMAX_SQUARE(fixNode->left_->square, fixNode->right_->square, tempSquare)
            if (tempSquare.tl.x = fixNode->square.tl.x) andAlso (tempSquare.tl.y = fixNode->square.tl.y) andAlso _
               (tempSquare.br.x = fixNode->square.br.x) andAlso (tempSquare.br.y = fixNode->square.br.y) then
                fixNode = 0
            else
                fixNode->square = tempSquare
                fixNode->area = GET_AREA(fixNode->square)
                fixNode = fixNode->parent_
            end if
        wend
        fixNode = 0    
        print "fix sucessful."
        sleep
    #endmacro
    
    #macro EAT_NODE(X)
        tempParent_ = curNode->parent_
        if tempParent_ = 0 then
            root_ = X
            curNode = root_
        else
            if tempParent_->left_ = curNode then
                tempParent_->left_ = X
            else
                tempParent_->right_ = X     
            end if
            curNode = X
            curNode->parent_ = tempParent_
        end if
    #endmacro
    
    #define INTERSECT(A, B) ((A.br.x >= B.tl.x) andAlso (A.tl.x <= B.br.x) andAlso (A.br.y >= B.tl.y) andALso (A.tl.y <= B.br.y))
    #define OVERLAP(B, A) ((A.tl.x >= B.tl.x) andAlso (A.br.x <= B.br.x) andAlso (A.tl.y >= B.tl.y) andALso (A.br.y <= B.br.y))
    #define NO_INTERSECT(A, B) ((A.br.x < B.tl.x) orElse (A.tl.x > B.br.x) orElse (A.br.y < B.tl.y) orElse (A.tl.y > B.br.y))
    
    dim as Tree2D_Node ptr curNode, nodeA, nodeB, nodeC, nodeD, nodeE, nodeF
    dim as Tree2D_Node ptr tempParent_, fixNode
    dim as Tree2D_Square tempSquare
    dim as integer isTouching, skipCycle
    dim as integer searchUp, cutStyle
    dim as double max_x, max_y, min_x, min_y

    splitStackPointer = 0
    
    'eat node = replace its parent with its sibling

    if OVERLAP(splitSquare, root_->square) then
        root_ = 0
        nodePool_usage = 0
        exit sub
    end if
    
    curNode = node_
    fixNode = 0
    do
        print "on node: "; curNode->square.tl; ", "; curNode->square.br
        print "searching down left side of tree"
        sleep
        
        searchUp = 0
        while curNode->left_
            print "examining left traversal node: "; curNode->left_->square.tl; ", "; curNode->left_->square.br
            if NO_INTERSECT(curNode->left_->square, splitSquare) then
                print "exiting because left traversal square does not touch split square"
                sleep
                exit while
            elseif OVERLAP(splitSquare, curNode->left_->square) then
                print "consuming left node and restructuring"
                sleep
                EAT_NODE(curNode->right_)
             
                fixNode = curNode->parent_
                FIX_NODE()
            else
                PUSH_SPLIT(curNode)
                curNode = curNode->left_
            end if 
        wend
        print "finished searching left side"
        sleep
        if curNode->right_ = 0 then
            'we definitely do not overlap curNode, if we did we would have eaten it already in left walk
            
            print "there is no node to the right, this is a leaf"            
            line (450 + curNode->square.tl.x * 0.5+1, curNode->square.tl.y * 0.5+1)-(450 + curNode->square.br.x * 0.5-1, curNode->square.br.y * 0.5-1), rgb(255,0,0), BF
            sleep
                        
            with curNode->square
                if .tl.x < splitSquare.tl.x then
                    if .tl.y < splitSquare.tl.y then
                        if .br.y <= splitSquare.br.y then
                            if .br.x <= splitSquare.br.x then
                                cutStyle = 1
                            else 
                                cutStyle = 2
                            end if
                        else
                             if .br.x <= splitSquare.br.x then
                                cutStyle = 3
                            else 
                                cutStyle = 15
                            end if
                        end if
                    else
                        if .br.y <= splitSquare.br.y then
                            if .br.x <= splitSquare.br.x then
                                cutStyle = 4
                            else
                                cutStyle = 5
                            end if
                        else
                            if .br.x <= splitSquare.br.x then
                                cutStyle = 6
                            else
                                cutStyle = 7
                            end if  
                        end if
                    end if
                else
                    if .tl.y < splitSquare.tl.y then
                        if .br.y <= splitSquare.br.y then
                            if .br.x <= splitSquare.br.x then
                                cutStyle = 10
                            else
                                cutStyle = 8
                            end if
                        else
                            if .br.x <= splitSquare.br.x then
                                cutStyle = 9
                            else
                                cutStyle = 11
                            end if
                        end if
                    else
                        if .br.y <= splitSquare.br.y then
                            cutStyle = 12
                        else
                            if .br.x <= splitSquare.br.x then
                                cutStyle = 13
                            else
                                cutStyle = 14
                            end if
                        end if
                    end if
                end if
            end with
            select case cutStyle
            case 1
                REQUEST_NODE(nodeA)
                nodeA->square = curNode->square
                nodeA->square.br.setX(splitSquare.tl.x)
                nodeA->square.x1 = (splitSquare.tl.x - 1) / 16.0
                INIT_NODE(nodeA)
                REQUEST_NODE(nodeB)
                nodeB->square = curNode->square
                nodeB->square.tl.setX(splitSquare.tl.x)
                nodeB->square.x0 = nodeA->square.x1 + 1
                nodeB->square.br.setY(splitSquare.tl.y)
                nodeB->square.y1 = (splitSquare.tl.y - 1) / 16.0
                INIT_NODE(nodeB)
                nodeA->parent_  = curNode
                nodeB->parent_  = curNode
                curNode->left_  = nodeA
                curNode->right_ = nodeB
            case 2
                REQUEST_NODE(nodeA)
                nodeA->square = curNode->square
                nodeA->square.br.setX(splitSquare.tl.x)
                nodeA->square.x1 = (splitSquare.tl.x - 1) / 16.0
                INIT_NODE(nodeA)
                REQUEST_NODE(nodeB)
                nodeB->square = curNode->square
                nodeB->square.tl.setX(splitSquare.tl.x)
                nodeB->square.x0 = nodeA->square.x1
                nodeB->square.br.setY(splitSquare.tl.y)
                nodeB->square.y1 = (splitSquare.tl.y - 1) / 16.0
                INIT_NODE(nodeB)
                REQUEST_NODE(nodeC)
                nodeC->square = curNode->square
                nodeC->square.tl.setX(splitSquare.br.x)
                nodeC->square.x0 = (splitSquare.br.x + 1) / 16.0
                nodeC->square.tl.setY(splitSquare.tl.y)
                nodeC->square.y0 = nodeB->square.y1 + 1
                INIT_NODE(nodeC)
                
                REQUEST_NODE(nodeD)
                nodeD->square = curNode->square
                nodeD->square.tl.setX(splitSquare.tl.x)
                nodeD->area = GET_AREA(nodeD->square)
                
                nodeD->left_    = nodeB
                nodeD->right_   = nodeC
                nodeD->parent_  = curNode
                nodeB->parent_  = nodeD
                nodeC->parent_  = nodeD
                nodeA->parent_  = curNode
                curNode->left_  = nodeD
                curNode->right_ = nodeA
            case 3
                REQUEST_NODE(nodeA)
                nodeA->square = curNode->square
                nodeA->square.br.setY(splitSquare.tl.Y)
                nodeA->square.y1 = (splitSquare.tl.y - 1) / 16.0
                INIT_NODE(nodeA)
                REQUEST_NODE(nodeB)
                nodeB->square = curNode->square
                nodeB->square.tl.setY(splitSquare.tl.y)
                nodeB->square.y0 = nodeA->square.y1 + 1
                nodeB->square.br.setX(splitSquare.tl.x)
                nodeB->square.x1 = (splitSquare.tl.x - 1) / 16.0
                INIT_NODE(nodeB)
                REQUEST_NODE(nodeC)
                nodeC->square = curNode->square
                nodeC->square.tl.setX(splitSquare.tl.x)
                nodeC->square.x0 = nodeB->square.x1 + 1
                nodeC->square.tl.setY(splitSquare.br.y)
                nodeC->square.y0 = (splitSquare.br.y + 1) / 16.0
                INIT_NODE(nodeC)
                
                REQUEST_NODE(nodeD)
                nodeD->square = curNode->square
                nodeD->square.tl.setY(splitSquare.tl.y)
                nodeD->area = GET_AREA(nodeD->square)
                
                nodeD->left_    = nodeB
                nodeD->right_   = nodeC
                nodeD->parent_  = curNode
                nodeB->parent_  = nodeD
                nodeC->parent_  = nodeD
                nodeA->parent_  = curNode
                curNode->left_  = nodeD
                curNode->right_ = nodeA             
            case 4
                curNode->square.br.setX(splitSquare.tl.x)
                curNode->square.x1 = (splitSquare.tl.x - 1) / 16.0
                curNode->area = GET_AREA(curNode->square)
                fixNode = curNode->parent_
            case 5
                REQUEST_NODE(nodeA)
                nodeA->square = curNode->square
                nodeA->square.br.setX(splitSquare.tl.x)
                nodeA->square.x1 = (splitSquare.tl.x - 1) / 16.0
                INIT_NODE(nodeA)
                REQUEST_NODE(nodeB)
                nodeB->square = curNode->square
                nodeB->square.tl.setX(splitSquare.br.x)
                nodeB->square.x0 = (splitSquare.br.x + 1) / 16.0
                INIT_NODE(nodeB)
                nodeA->parent_  = curNode
                nodeB->parent_  = curNode
                curNode->left_  = nodeA
                curNode->right_ = nodeB
            case 6
                REQUEST_NODE(nodeA)
                nodeA->square = curNode->square
                nodeA->square.br.setX(splitSquare.tl.x)
                nodeA->square.x1 = (splitSquare.tl.x - 1) / 16.0
                INIT_NODE(nodeA)
                REQUEST_NODE(nodeB)
                nodeB->square = curNode->square
                nodeB->square.tl.setX(splitSquare.tl.x)
                nodeB->square.x0 = nodeA->square.x1 + 1
                nodeB->square.tl.setY(splitSquare.br.y)
                nodeB->square.y0 = (splitSquare.br.y + 1) / 16.0
                INIT_NODE(nodeB)
                nodeA->parent_  = curNode
                nodeB->parent_  = curNode
                curNode->left_  = nodeA
                curNode->right_ = nodeB
            case 7
                REQUEST_NODE(nodeA)
                nodeA->square = curNode->square
                nodeA->square.br.setX(splitSquare.tl.x)
                nodeA->square.x1 = (splitSquare.tl.x - 1) / 16.0
                INIT_NODE(nodeA)
                REQUEST_NODE(nodeB)
                nodeB->square = curNode->square
                nodeB->square.tl.setX(splitSquare.tl.x)
                nodeB->square.x0 = nodeA->square.x1 + 1
                nodeB->square.tl.setY(splitSquare.br.y)
                nodeB->square.y0 = (splitSquare.br.y + 1) / 16.0
                INIT_NODE(nodeB)
                REQUEST_NODE(nodeC)
                nodeC->square = curNode->square
                nodeC->square.tl.setX(splitSquare.br.x)
                nodeC->square.x0 = (splitSquare.br.x + 1) / 16.0
                nodeC->square.br.setY(splitSquare.br.y)
                nodeC->square.y1 = nodeB->square.y0 - 1
                INIT_NODE(nodeC)
                
                REQUEST_NODE(nodeD)
                nodeD->square = curNode->square
                nodeD->square.tl.setX(splitSquare.tl.x)
                nodeD->area = GET_AREA(nodeD->square)
                
                nodeD->left_    = nodeB
                nodeD->right_   = nodeC
                nodeD->parent_  = curNode
                nodeB->parent_  = nodeD
                nodeC->parent_  = nodeD
                nodeA->parent_  = curNode
                curNode->left_  = nodeD
                curNode->right_ = nodeA 
            case 8
                REQUEST_NODE(nodeA)
                nodeA->square = curNode->square
                nodeA->square.br.setY(splitSquare.tl.y)
                nodeA->square.y1 = (splitSquare.tl.y - 1) / 16.0
                INIT_NODE(nodeA)
                REQUEST_NODE(nodeB)
                nodeB->square = curNode->square
                nodeB->square.tl.setX(splitSquare.br.x)
                nodeB->square.x0 = (splitSquare.br.x + 1) / 16.0
                nodeB->square.tl.setY(splitSquare.tl.y)
                nodeB->square.y0 = nodeA->square.y1 + 1
                INIT_NODE(nodeB)
                nodeA->parent_  = curNode
                nodeB->parent_  = curNode
                curNode->left_  = nodeA
                curNode->right_ = nodeB
            case 9
                REQUEST_NODE(nodeA)
                nodeA->square = curNode->square
                nodeA->square.br.setY(splitSquare.tl.y)
                nodeA->square.y1 = (splitSquare.tl.y - 1) / 16.0
                INIT_NODE(nodeA)
                REQUEST_NODE(nodeB)
                nodeB->square = curNode->square
                nodeB->square.tl.setY(splitSquare.br.y)
                nodeB->square.y0 = (splitSquare.br.y + 1) / 16.0
                INIT_NODE(nodeB)
                nodeA->parent_  = curNode
                nodeB->parent_  = curNode
                curNode->left_  = nodeA
                curNode->right_ = nodeB
            case 10
                curNode->square.br.setY(splitSquare.tl.y)
                curNode->square.y1 = (splitSquare.tl.y - 1) / 16.0
                curNode->area = GET_AREA(curNode->square)
                fixNode = curNode->parent_
            case 11
                REQUEST_NODE(nodeA)
                nodeA->square = curNode->square
                nodeA->square.br.setY(splitSquare.tl.y)
                nodeA->square.y1 = (splitSquare.tl.y - 1) / 16.0
                INIT_NODE(nodeA)
                REQUEST_NODE(nodeB)
                nodeB->square = curNode->square
                nodeB->square.tl.setX(splitSquare.br.x)
                nodeB->square.x0 = (splitSquare.br.x + 1) / 16.0
                nodeB->square.tl.setY(splitSquare.tl.y)
                nodeB->square.y0 = nodeA->square.y1 + 1
                INIT_NODE(nodeB)
                REQUEST_NODE(nodeC)
                nodeC->square = curNode->square
                nodeC->square.tl.setY(splitSquare.br.y)
                nodeC->square.y0 = (splitSquare.br.y + 1) / 16.0
                nodeC->square.br.setX(splitSquare.br.x)
                nodeC->square.x1 = nodeB->square.x0 - 1
                INIT_NODE(nodeC)
                
                REQUEST_NODE(nodeD)
                nodeD->square = curNode->square
                nodeD->square.tl.setY(splitSquare.tl.y)
                nodeD->area = GET_AREA(nodeD->square)
                
                nodeD->left_    = nodeB
                nodeD->right_   = nodeC
                nodeD->parent_  = curNode
                nodeB->parent_  = nodeD
                nodeC->parent_  = nodeD
                nodeA->parent_  = curNode
                curNode->left_  = nodeD
                curNode->right_ = nodeA  
            case 12
                curNode->square.tl.setX(splitSquare.br.x)
                curNode->square.x0 = (splitSquare.br.x + 1) / 16.0
                curNode->area = GET_AREA(curNode->square)
                fixNode = curNode->parent_
            case 13
                curNode->square.tl.setY(splitSquare.br.y)
                curNode->square.y0 = (splitSquare.br.y + 1) / 16.0
                curNode->area = GET_AREA(curNode->square)
                fixNode = curNode->parent_
            case 14
                REQUEST_NODE(nodeA)
                nodeA->square = curNode->square
                nodeA->square.tl.setX(splitSquare.br.x)
                nodeA->square.x0 = (splitSquare.br.x + 1) / 16.0
                INIT_NODE(nodeA)
                REQUEST_NODE(nodeB)
                nodeB->square = curNode->square
                nodeB->square.tl.setY(splitSquare.br.y)
                nodeB->square.y0 = (splitSquare.br.y + 1) / 16.0
                nodeB->square.br.setX(splitSquare.br.x)
                nodeB->square.x1 = nodeA->square.x0 - 1
                INIT_NODE(nodeB)
                nodeA->parent_  = curNode
                nodeB->parent_  = curNode
                curNode->left_  = nodeA
                curNode->right_ = nodeB
            case 15
                REQUEST_NODE(nodeA)
                nodeA->square = curNode->square
                nodeA->square.br.setY(splitSquare.tl.y)
                nodeA->square.y1 = (splitSquare.tl.y - 1) / 16.0
                INIT_NODE(nodeA)
                REQUEST_NODE(nodeD)
                nodeD->square = curNode->square
                nodeD->square.tl.setY(splitSquare.br.y)
                nodeD->square.y0 = (splitSquare.br.y + 1) / 16.0
                INIT_NODE(nodeD)
                
                REQUEST_NODE(nodeB)
                nodeB->square = curNode->square
                nodeB->square.tl.setY(splitSquare.tl.y)
                nodeB->square.y0 = nodeA->square.y1 + 1
                nodeB->square.br.setX(splitSquare.tl.x)
                nodeB->square.x1 = (splitSquare.tl.x - 1) / 16.0
                nodeB->square.br.setY(splitSquare.br.y)
                nodeB->square.y1 = nodeD->square.y0 - 1
                INIT_NODE(nodeB)
                REQUEST_NODE(nodeC)
                nodeC->square = curNode->square
                nodeC->square.tl.setY(splitSquare.tl.y)
                nodeC->square.y0 = nodeA->square.y1 + 1
                nodeC->square.tl.setX(splitSquare.br.x)
                nodeC->square.x0 = (splitSquare.br.x + 1) / 16.0                    
                nodeC->square.br.setY(splitSquare.br.y)
                nodeC->square.y1 = nodeD->square.y0 - 1
                INIT_NODE(nodeC)
                          
                REQUEST_NODE(nodeE)
                nodeE->square = curNode->square
                nodeE->square.br.setY(splitSquare.br.y)
                nodeE->area = GET_AREA(nodeE->square)
                REQUEST_NODE(nodeF)
                nodeF->square = curNode->square
                nodeF->square.tl.setY(splitSquare.tl.y)
                nodeF->area = GET_AREA(nodeF->square)
                
                nodeE->left_    = nodeA
                nodeE->right_   = nodeB
                nodeE->parent_  = curNode
                nodeA->parent_  = nodeE
                nodeB->parent_  = nodeE
                nodeF->left_    = nodeC
                nodeF->right_   = nodeD
                nodeF->parent_  = curNode
                nodeC->parent_  = nodeF
                nodeD->parent_  = nodeF
                curNode->left_  = nodeE
                curNode->right_ = nodeF  
            end select               
            FIX_NODE()
            searchUp = 1
        
            print "performed split with style: "; cutStyle
            print "drawing sub-tree"
            Tree2DDebugPrint(node_, 0, 0)
            sleep
        elseif NO_INTERSECT(curNode->right_->square, splitSquare) then 
            searchUp = 1
            print "there is a node to the right, but it is not one we intersect"
            sleep
        elseif OVERLAP(splitSquare, curNode->right_->square) then
            EAT_NODE(curNode->left_)
            
            
            print "there is a node to the right, we consume it"
            sleep
            fixNode = curNode->parent_
            FIX_NODE()
            searchUp = 1
        end if
        
        if searchUp = 1 then 
            print "heading back up the tree..."
            sleep
            skipCycle = 0
            do
                if splitStackPointer = 0 then
                    print "search is over, stack is empty when heading back up."
                    sleep
                    skipCycle = 1
                    exit do
                end if
                POP_SPLIT(curNode)
                               
                if INTERSECT(curNode->right_->square, splitSquare) then
                    if OVERLAP(splitSquare, curNode->right_->square) then
                        EAT_NODE(curNode->left_)
                        
                        print "there is a node to the right which we'll eat and then resume going back up"
                        sleep
                        
                        'keep going back up/quit in next iteration
                        fixNode = curNode->parent_
                        FIX_NODE() 
                    else                    
                        print "we intersect the right square, stop upward traversal."
                        sleep
                        exit do
                    end if
                end if
            loop
        end if
        if skipCycle = 0 then curNode = curNode->right_
    loop until skipCycle = 1
    print "performing final repair..."
    sleep
    if node_ <> root_ then
        fixNode = node_->parent_
        while (fixNode <> 0)
            GET_MINMAX_SQUARE(fixNode->left_->square, fixNode->right_->square, tempSquare)
            if (tempSquare.tl.x = fixNode->square.tl.x) andAlso (tempSquare.tl.y = fixNode->square.tl.y) andAlso _
               (tempSquare.br.x = fixNode->square.br.x) andAlso (tempSquare.br.y = fixNode->square.br.y) then
                fixNode = 0
            else
                fixNode->square = tempSquare
                fixNode->area = GET_AREA(fixNode->square)
                fixNode = fixNode->parent_
            end if
        wend
    end if
  
end sub

sub Tree2d.setSearch(searchSquare as Tree2D_Square)

end sub

function Tree2d.getSearch() as Tree2D_Square ptr

end function

sub Tree2d.resetRoll()

end sub

function Tree2d.roll() as Tree2D_Square ptr

end function
        