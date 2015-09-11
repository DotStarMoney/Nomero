#ifndef KEYBANK_BI
#define KEYBANK_BI

#include "hashtable.bi"
#include "packedbinary.bi"

type KeyBank_node_t
    as zstring ptr key
end type

type KeyBank
    public:
        declare constructor()
        declare destructor()
        declare function acquire() as string
        declare sub relinquish(key as string)
        declare sub flush()
        declare sub serialize_out(pbin as PackedBinary)
        declare sub serialize_in(pbin as PackedBinary)
    private:
        as unsigned long curVal
        as Hashtable keys
end type




#endif