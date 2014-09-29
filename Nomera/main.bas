#include "gamespace.bi"

#ifdef DEBUG
    screenres SCRX*2,SCRY*2,32
#else
    screenres SCRX*2,SCRY*2,32',2
   ' screenset 1,0 
#endif

#macro sync()
	screenlock	
		scale2sync scnbuff
	screenunlock
	'flip
#endmacro

'FSOUND_Init(44100, 16, 0)

#ifdef INTRO
	#ifndef DEBUG 
		dim as uinteger ptr blipSound 
		dim as uinteger ptr introTrack
		dim as uinteger ptr scnbuff
		dim as uinteger ptr splash
		dim as uinteger ptr black
		dim as integer fadeIn = 0, flippy
		scnbuff = imagecreate(640, 480)
		black = imagecreate(640,480)
		line black,(0,0)-(SCRX-1,SCRY-1),0 ,BF
		splash = imagecreate(640,480)
		bload "splash.bmp", splash





		blipSound = FSOUND_SAMPLE_Load(FSOUND_FREE,"blip.wav",0,0,0)


		introTrack = FSOUND_Stream_Open("menu.ogg", FSOUND_LOOP_NORMAL, 0, 0) 
		FSOUND_Stream_Play 0, introTrack
		do
			if fadeIn < 255 then fadeIn += 1
			put scnbuff, (0,0), splash, PSET
			put scnbuff, (0,0), black, ALPHA, 255 - fadeIn
			
			if fadeIn > 200 then
				drawstringshadow scnbuff, SCRX*0.5 - 90, 324, "Press any key to play!", iif(flippy <= 4, &hffffff, rgb(0,128,255))
				drawstringshadow scnbuff, SCRX*0.5 - 100, 448, "A game by Christopher Brown,",&hffffff
				drawstringshadow scnbuff, SCRX*0.5 - 150, 464, "with artwork and levels by Elliott Hirsch", &hffffff
			end if
			flippy = (flippy + 1) mod 10
			sync()
			stall(10)
		loop until fadeIn > 200 andAlso (inkey<> "")
		FSOUND_PlaySound (FSOUND_FREE, blipSound)

		put scnbuff, (0,0), black, ALPHA, 190

		drawstringshadow scnbuff, 16,16, "You are Mr. Spy, an American spy sent to investigate", &hffffff
		drawstringshadow scnbuff, 16,32, "Russian Numbers Stations on the quest for the mysterious", &hffffff
		drawstringshadow scnbuff, 16,48, "UVB-76 signal.", &hffffff
		sync()
		sleep
		FSOUND_PlaySound (FSOUND_FREE, blipSound)
		drawstringshadow scnbuff, 16,88, "Armed with explosives alone, visit the Russian Numbers Stations", &hffffff
		drawstringshadow scnbuff, 16,104, "and sabotage their equiptment. If you sucessfully disable a station,", &hffffff
		drawstringshadow scnbuff, 16,120, "new paths might open up!", &hffffff

		sync()
		sleep
		FSOUND_PlaySound (FSOUND_FREE, blipSound)
		drawstringshadow scnbuff, 16,160, "Press and hold X to wind up and throw a bomb. Once you run out of bombs,", &hffffff
		drawstringshadow scnbuff, 16,176, "you cannot get them back unless you die. Press Z to jump, and use the", &hffffff
		drawstringshadow scnbuff, 16,192, "arrow keys to move and climb ladders. Press SHIFT to sprint.", &hffffff

		sync()
		sleep
		FSOUND_PlaySound (FSOUND_FREE, blipSound)
		drawstringshadow scnbuff, 16,232, "Good luck!", &hffffff


		sync()
		sleep
		FSOUND_PlaySound (FSOUND_FREE, blipSound)
		do
			if fadeIn > 0 then fadeIn -= 2
			put scnbuff, (0,0), black, ALPHA, 8
			FSOUND_SetVolumeAbsolute 0, fadeIn
			sync()
			stall(10)
		loop until fadeIn <= 0

	#endif
#endif
Dim as GameSpace gameNomero


gameNomero.go


end
