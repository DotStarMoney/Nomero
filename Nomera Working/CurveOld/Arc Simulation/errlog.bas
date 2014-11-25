#include "errlog.bi"
 
#define ERRLOG_DYN_ARRAY_COARSE 8
 
constructor ErrLog()
    elog_n = 0
    elog_cap = 0
    elog = 0
end constructor

destructor ErrLog()
    dim as integer i
    if elog <> 0 then
        for i = 0 to elog_n - 1
            deallocate elog[i]
        next i
    end if
    deallocate elog
end destructor

function ErrLog.errorN() as integer
    return elog_n
end function

sub ErrLog.printLog(print_all as integer)
    dim as integer i
    if elog <> 0 then
        for i = 0 to elog_n - 1
            print elog[i]
        next i
    end if
end sub
sub ErrLog.hcf_(err_str as const zstring)
    if elog_n = elog_cap then
        elog_cap += ERRLOG_DYN_ARRAY_COARSE
        elog = reallocate(elog, sizeof(zstring ptr) * elog_cap)
    end if
    elog_n += 1
    elog[elog_n - 1] = allocate(len(err_str) + 1)
    *(elog[elog_n - 1]) = err_str
end sub
