#ifndef FBGDTRIGGERDISPATCH_BI
#define FBGDTRIGGERDISPATCH_BI

#include "objectlink.bi"

type FBGDTriggerDispatch
	public:
		declare constructor()
		declare sub setLink(link_ as objectLink)
		declare sub process(t as double)
		declare sub draw_(scnbuff as integer ptr)
			
	private:
		as objectLink link
		as integer oxygen
		as integer setOnceOxy
		as integer phase
		as integer dPoints(5)
		as integer completed
end type










#endif
