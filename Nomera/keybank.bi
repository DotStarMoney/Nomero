#ifndef KEYBANK_BI
#define KEYBANK_BI

#include "hashtable.bi"

type KeyBank_node_t
    as string key
    as any ptr memAddr
end type

type KeyBank
    public:
        declare constructor()
        declare destructor()
        declare function acquire() as string
        declare sub relinquish(key as string)
        declare sub flush()
    private:
        as Hashtable keys
end type




#endif