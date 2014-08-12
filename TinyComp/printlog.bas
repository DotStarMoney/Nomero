#include "printlog.bi"
#include "debug.bi"

#ifdef DEBUG
    PRINT_LOG_ON = 1
    
    PRINT_LOG = freefile
    kill "debug.txt"
    open "debug.txt" for append as PRINT_LOG
#endif


sub PRINTLOG(s as string = "", nextline as integer = 0)
    if PRINT_LOG_ON = 1 then
        if nextline = 1 then
            print #PRINT_LOG, s;
        else
            print #PRINT_LOG, s
        end if
    end if
    if nextline = 1 then
        print s;
    else
        print s
    end if
end sub
