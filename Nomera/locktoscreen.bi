#ifndef LOCKTOSCREEN_BI
#define LOCKTOSCREEN_BI

#macro LOCK_TO_SCREEN()
	window screen (0,0)-(SCRX-1,SCRY-1)
#endmacro

#macro UNLOCK_TO_SCREEN()
    window screen (link.gamespace_ptr->camera.x() - SCRX * 0.5, link.gamespace_ptr->camera.y() - SCRY * 0.5)-_
                  (link.gamespace_ptr->camera.x() + SCRX * 0.5, link.gamespace_ptr->camera.y() + SCRY * 0.5)
#endmacro

#endif