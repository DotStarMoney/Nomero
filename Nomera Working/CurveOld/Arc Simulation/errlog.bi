#ifndef ERRLOG_BI
#define ERRLOG_BI

#define HCF(x) hcf_(__FILE__ & " " & __FUNCTION__ & ": " & (x))

type ErrLog
    public:
        declare constructor()
        declare destructor()
        declare function errorN() as integer
        declare sub printLog(print_all as integer)
    protected:
        declare sub hcf_(err_str as const zstring)
    private:
        as integer         elog_n
        as integer         elog_cap
        as zstring ptr ptr elog
end type


#endif