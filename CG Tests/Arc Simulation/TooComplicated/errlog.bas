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
    if print_all = -1 then
        if elog <> 0 then
            for i = 0 to elog_n - 1
                print *(elog[i])
            next i
        end if
    else
        if elog <> 0 then
            if (print_all >= 0) andAlso (print_all < elog_n) then
                print *(elog[print_all])
            end if
        end if
    end if
end sub
sub ErrLog.hcf_(err_str as const zstring)
    dim as integer i
    if elog_n < 64 then
        if elog_n = elog_cap then
            elog_cap += ERRLOG_DYN_ARRAY_COARSE
            elog = reallocate(elog, sizeof(zstring ptr) * elog_cap)
        end if
        elog_n += 1
        elog[elog_n - 1] = allocate(len(err_str) + 1)
    else
        for i = 0 to 62
            elog[i] = elog[i + 1]
        next i
    end if
    *(elog[elog_n - 1]) = err_str
end sub
