#ifndef OBJECTLINK_BI
#define OBJECTLINK_BI


type gamespace_ 			as gamespace
type level_ 				as level
type tinyspace_ 			as tinyspace
type player_ 				as player
type oneshoteffects_ 		as oneshoteffects
type effectcontroller_ 		as effectcontroller
type projectilecollection_ 	as projectilecollection
type dynamiccontroller_ 	as dynamiccontroller
type soundeffects_			as soundeffects
type pathtracker_			as pathtracker_


type ObjectLink
	as pathtracker_ ptr			 pathtracker_ptr
	as gamespace_ ptr            gamespace_ptr
	as level_ ptr                level_ptr
	as tinyspace_ ptr            tinyspace_ptr
	as player_ ptr               player_ptr
	as projectilecollection_ ptr projectilecollection_ptr
	as oneshoteffects_ ptr       oneshoteffects_ptr
	as effectcontroller_ ptr     effectcontroller_ptr
	as dynamiccontroller_ ptr    dynamiccontroller_ptr
	as soundeffects_ ptr		 soundeffects_ptr
end type



#endif
