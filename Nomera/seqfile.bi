#ifndef SEQFILE_BI
#define SEQFILE_BI

namespace SeqFile
    const STACK_MEM_INCREASE as integer = 16
    const STACK_MEM_START    as integer = 16
    const READ_STACK_MAX     as integer = 8

    enum readType
        READ_INTEGER
        READ_DOUBLE
        READ_STRING
        SET_REPEAT
        END_REPEAT
        HEADER
    end enum
      
    type actionNode_t
        as readType         action
        as integer          childSize
        as actionNode_t ptr ref_
        as integer          size
        as integer          referenceValue
        as actionNode_t ptr parent_
        as actionNode_t ptr next_
        as actionNode_t ptr lastChild_
        as actionNode_t ptr firstChild_
    end type
    
    type Reader
        public:
            declare constructor()
            declare destructor()
            declare sub push(t as readType, pNum as integer = -1)
            declare sub readFile(filename as string, byref data_ as any ptr)
        private:
            declare sub deleteActionTree(tree as actionNode_t ptr)
            as actionNode_t ptr actionTree
            as integer          numActions
            as actionNode_t ptr curNode
    end type

end namespace


#endif
