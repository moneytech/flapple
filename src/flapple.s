****************************************
* Flapple Bird                         *
*                                      *
*  Dagen Brock <dagenbrock@gmail.com>  *
*  2014-04-17                          *
****************************************
	lst off
	org $2000	; start at $2000 (all ProDOS8 system files)
	dsk f	; tell compiler what name for output file ("f", temporarily)
	typ $ff	; set P8 type ($ff = "SYS") for output file
	xc  off	; @todo force 6502?
	xc  off
MLI	equ $bf00

; Sorry, I gotta have some macros.. this is merlin format after all
; You might as well take advantage of your tools :P
CopyPtr       MAC
	lda #<]1      ; load low byte
	sta ]2	; store low byte
	lda #>]1	; load high byte
	sta ]2+1      ; store high byte
	<<<


Main	
	jsr DetectMachine	; also inits vbl
	jsr LoadHiScore
	jsr DL_SetDLRMode

Title	
	jsr VBlank
	lda #$00
	jsr DL_Clear
	ldx #3	;slight pause
	jsr VBlankX
	lda #$F6
	ldx #$27
	ldy #$77
	jsr DL_WipeIn
	jsr DrawFlogo
	jsr PlayFlappySong ;@todo throttle
	ldx #60
	ldy #2
	jsr WaitKeyXY

PreGameLoop
** INIT ALL GAME STATE ITEMS
	lda #BIRD_Y_INIT
	sta BIRD_Y
	sta BIRD_Y_OLD
	lda #0
	sta SPRITE_COLLISION
	sta PreGameTick
	sta PreGameTick+1
	sta PreGameText
	sta ScoreLo
	sta ScoreHi


	lda #0
	ldx #3
:clearPipes	sta TopPipes,x
	sta BotPipes
	dex
	bpl :clearPipes

** CLEAR SCREEN - SETUP BIRD
	jsr VBlank
	lda #$77
	jsr DL_Clear

	lda #BIRD_X
	sta SPRITE_X
	lda #5
	sta SPRITE_W	; all birds are same width

** WAIT FOR PLAYER TO HIT SOMETHING
:noKey	jsr VBlank
	jsr UndrawBird
	jsr DrawBird
	jsr UpdateGrass
	jsr FlapBird

	inc PreGameTick
	bne :noOverflow
	inc PreGameTick+1
:noOverflow	lda PreGameTick
	cmp #60
	bcc :skipText
	lda PreGameText
	bne :skipText
	inc PreGameText
	jsr DrawTap
:skipText
	lda PreGameTick+1
	cmp #2
	bne :checkKey

	jmp Title

:checkKey	lda KEY
	bpl :noKey
:key	sta STROBE
	lda #$77
	jsr DL_Clear
	jmp GameLoop

PreGameTick	dw 0

PreGameText	db 0
GSBORDER      da _GSBORDER
_GSBORDER	db 0


GameLoop	
	jsr VBlank

	jsr UndrawBird
	jsr DrawPipes
	jsr DrawScore
	jsr DrawBird
	jmp UpdatePipes
UpdatePipesDone
DONTUPDATEPIPES
	jsr FlapBird
	jsr UpdateGrass

	jmp HandleInput	; Also plays flap!
HandleInputDone
	lda SPRITE_COLLISION
	bne GAME_OVER

	lda QuitFlag
	beq GameLoop
	jmp Quit

GAME_OVER	
	jsr DrawPipes
	jsr DrawScore
	jsr DrawSplosion
	jsr SND_Static
	jsr UpdateHiScore
	jsr DrawPlaqueHi
	jsr DrawPlaqueLo
	jsr DrawYou
	jsr DrawHi

	ldx #19
	ldy #11
	jsr DrawHiScore

	ldx #19
	ldy #4
	jsr DrawYouScore

	sta STROBE	;clear errant flap hits
	ldx #60
	ldy #5
	jsr WaitKeyXY
	bcc :noKey
	jmp PreGameLoop
:noKey	
	lda #$FA
	ldx #$50
	ldy #$00
	jsr DL_WipeIn
	jmp Title


SND_Flap	jmp SND_Flap2
SND_Flap1
*	lda #5
*	sta $c034
	ldx #$1c	;LENGTH OF NOISE BURST
:spkLoop	lda SPEAKER	;TOGGLE SPEAKER
	txa
	asl
	asl
	tay

:waitLoop	dey	;DELAY LOOP FOR PULSE WIDTH
	bne :waitLoop
	dex	;GET NEXT PULSE OF THIS NOISE BURST
	bne :spkLoop
*	ldx #$0	;LENGTH OF NOISE BURST
*	stx $c034
	rts

SND_Flap2
*	lda #5
*	sta $c034
	ldx #$16	;LENGTH OF NOISE BURST
:spkLoop	sta SPEAKER	;TOGGLE SPEAKER
	txa
	clc 
	adc #$30
	tay

:waitLoop	dey	;DELAY LOOP FOR PULSE WIDTH
	bne :waitLoop
	dex	;GET NEXT PULSE OF THIS NOISE BURST
	bne :spkLoop
*	ldx #$0	;LENGTH OF NOISE BURST
*	stx $c034
	rts


SND_Static
	ldx #$80	;LENGTH OF NOISE BURST
:spkLoop	lda SPEAKER	;TOGGLE SPEAKER
	jsr GetRand
	and #%1000000
	tay
*	ldy $BA00,X	;GET PULSE WIDTH PSEUDO-RANDOMLY
:waitLoop	dey	;DELAY LOOP FOR PULSE WIDTH
	bne :waitLoop
	dex	;GET NEXT PULSE OF THIS NOISE BURST
	bne :spkLoop
	
	ldx #$60	;LENGTH OF NOISE BURST
:spkLoop2	lda SPEAKER	;TOGGLE SPEAKER
	jsr GetRand
	tay
*	ldy $BA00,X	;GET PULSE WIDTH PSEUDO-RANDOMLY
:waitLoop2	dey	;DELAY LOOP FOR PULSE WIDTH
	bne :waitLoop2
	dex	;GET NEXT PULSE OF THIS NOISE BURST
	bne :spkLoop2

	ldx #$80	;LENGTH OF NOISE BURST
:spkLoop3	lda SPEAKER	;TOGGLE SPEAKER
	jsr GetRand
	lsr
	tay
:waitLoop3	dey	;DELAY LOOP FOR PULSE WIDTH
	bne :waitLoop3
	dex	;GET NEXT PULSE OF THIS NOISE BURST
	bne :spkLoop3

	rts

HandleInput
	lda BIRD_Y
	sta BIRD_Y_OLD
		;Update bird and velocity in here
:kloop	lda KEY
	bpl :noFlap
:key	sta STROBE
	cmp #"Q"
	bne :noQuit
	lda #1
	sta QuitFlag
	bne :keyDone
:noQuit
	cmp #"Z"
	beq :noFlap
:flap	lda #40
	sta BIRD_VELOCITY
	bne :handleBird
:noFlap	dec BIRD_VELOCITY
	lda BIRD_VELOCITY
	bpl :handleBird
	lda #3 
	sta BIRD_VELOCITY
:handleBird
	lda BIRD_VELOCITY
	cmp #37
	bcc :notTop
	dec BIRD_Y	; +2
	jsr SND_Flap
	clc
	bcc :boundsCheck
:notTop	cmp #34
	bcs :boundsCheck
	cmp #2
	bcc :DOWN
	asl 
	asl 
	bcc :boundsCheck
:DOWN	inc BIRD_Y

:boundsCheck
	lda BIRD_Y
	bpl :notUnder
	lda #0 
	sta BIRD_Y
	beq :keyDone
:notUnder	cmp #38	; Life, the Universe, and Everything
	bcc :keyDone
	lda #38
	sta BIRD_Y
:keyDone	jmp HandleInputDone


BIRD_VELOCITY	db 0	; in two's compliment {-3,3} 
BIRD_VELOCITY_MAX equ #20
BIRD_VELOCITY_MIN equ #%111111111	; -1
LoadHiScore	jsr CreateHiScoreFile
	bcs :error
	jsr OpenHiScoreFile
	bcs :error
	jsr ReadHiScoreFile
	jsr CloseHiScoreFile
:error	rts

SaveHiScore	jsr CreateHiScoreFile
	jsr OpenHiScoreFile
	bcc :noError
	rts
:noError	jsr WriteHiScoreFile
	jsr CloseHiScoreFile
	rts

CreateHiScoreFile
	jsr MLI
	dfb $C0
	da CreateHiScoreParam
	bcs :error
	rts
:error	cmp #$47	; dup filename - already created?
	bne :bail
	clc	; this is ok, clear error state
:bail	rts	; oh well... just carry on in session 

OpenHiScoreFile
	jsr MLI
	dfb $C8	; OPEN P8 request ($C8)
	da OpenHiScoreParam
	bcc :noError
	brk $10
	cmp $46	; "$46 - File not found"
	beq CreateHiScoreFile ; let's create it if we can and try again
	rts	; return with error state
:noError	rts


ReadHiScoreFile
	lda #0
	sta IOBuffer
	sta IOBuffer+1	;zero load area, just in case
	lda OpenRefNum
	sta ReadRefNum
	jsr MLI
	dfb $CA	; READ P8 request ($CA)
	da ReadHiScoreParam
	bcs :readFail

	lda ReadResult
	lda IOBuffer
	sta HiScoreHi
	lda IOBuffer+1
	sta HiScoreLo
	rts

:readFail	cmp #$4C	;eof - ok on new file
	beq :giveUp	

	brk $99	; uhm
:giveUp	rts	; return with error state


CloseHiScoreFile
	lda OpenRefNum
	sta CloseRefNum
	jsr MLI
	dfb $CC	; CLOSE P8 request ($CC)
	da CloseHiScoreParam
	bcc :ret
:ret	rts	; return with error state - not checked!

WriteHiScoreFile
	lda HiScoreHi
	sta IOBuffer
	lda HiScoreLo
	sta IOBuffer+1
	lda OpenRefNum
	sta WriteRefNum
	jsr MLI
	dfb $CB	; READ P8 request ($CB)
	da WriteHiScoreParam
	bcs :writeFail
	lda WriteResult
:writeFail	
	rts


OpenHiScoreParam
	dfb #$03	; number of parameters 
	dw HiScoreFile
              dw $900 
OpenRefNum db 0	; assigned by open call
HiScoreFile	str 'flaphi'


CloseHiScoreParam
	dfb #$01	; number of parameters 
CloseRefNum	db 0


CreateHiScoreParam
	dfb  7	; number of parameters
	dw   HiScoreFile	; pointer to filename
	dfb  $C3      ; normal (full) file access permitted
	dfb  $06      ; make it a $06 (bin) file
	dfb  $00,$00  ; AUX_TYPE, not used
	dfb  $01      ; standard file
	dfb  $00,$00  ; creation date (unused)
	dfb  $00,$00  ; creation time (unused)


ReadHiScoreParam
	dfb  4        ; number of parameters
ReadRefNum	db 0	; set by open subroutine above
	da IOBuffer
	dw #2	; request count (length)
ReadResult	dw 0	; result count (amount actually read before EOF)


WriteHiScoreParam
	dfb  4        ; number of parameters
WriteRefNum	db 0	; set by open subroutine above
	da IOBuffer
	dw #2	; request count (length)
WriteResult	dw 0	; result count (amount transferred)


Quit	jsr MLI	; first actual command, call ProDOS vector
	dfb $65	; QUIT P8 request ($65)
	da QuitParm
	bcs Error
	brk $00	; shouldn't ever  here!
Error	brk $00	; shouldn't be here either

QuitParm	dfb 4	; number of parameters
	dfb 0	; standard quit type
	da $0000	; not needed when using standard quit
	dfb 0	; not used
	da $0000	; not used


QuitFlag	db 0	; set to 1 to quit

	ds \
IOBuffer	ds 512



HandleInputTest
	lda BIRD_Y
	sta BIRD_Y_OLD
:kloop	lda KEY
	bpl :noKey
:key	sta STROBE
	cmp #"A"
	beq :up
	cmp #"B"
	beq :dn
	lda #1
	sta QuitFlag
:dn	inc BIRD_Y
	bpl :keyDone
:up	dec BIRD_Y
:noKey
:keyDone	jmp HandleInputDone

******************************
* Score Routines
*********************
ScoreLo       db 0          ; 0-99
ScoreHi       db 0          ; hundreds, not shown on screen
HiScoreLo	db 0 
HiScoreHi	db 0
** Draw the Score - @todo - handle > 99
DrawScore	lda ScoreLo
	and #$0F
	ldy #21
	jsr DrawNum
	lda ScoreLo
	lsr
	lsr
	lsr
	lsr
	tax
	ldy #19
	jsr DrawNum
	lda #$FF
	sta TXTPAGE1
	sta Lo01+18
	sta Lo02+18
	rts

** HANDLE HIGH SCORE	
UpdateHiScore
	lda HiScoreHi
	cmp ScoreHi
	bcc :newHighScore
	bne :noHighScore
	lda HiScoreLo	;high byte equal so compare base byte
	cmp ScoreLo
	bcc :newHighScore
	bcs :noHighScore


:newHighScore	lda ScoreHi
	sta HiScoreHi
	lda ScoreLo
	sta HiScoreLo
	jsr SaveHiScore
:noHighScore	rts


	

**************************************************
* Grass 
**************************************************
UpdateGrass	inc GrassState
	lda GrassState
	cmp #4
	bne :noReset
	lda #0
	sta GrassState
:noReset	
	sta TXTPAGE2	
	ldx GrassState
	lda GrassTop,x	; top[0]
	tax
	lda MainAuxMap,x
	sta Lo23
	sta Lo23+2
	sta Lo23+4
	sta Lo23+6
	sta Lo23+8
	sta Lo23+10
	sta Lo23+12
	sta Lo23+14
	sta Lo23+16
	sta Lo23+18
	sta Lo23+20
	sta Lo23+22
	sta Lo23+24
	sta Lo23+26
	sta Lo23+28
	sta Lo23+30
	sta Lo23+32
	sta Lo23+34
	sta Lo23+36
	sta Lo23+38
	ldx GrassState
	lda GrassBot,x	; Bot[0]
	tax
	lda MainAuxMap,x
	sta Lo24
	sta Lo24+2
	sta Lo24+4
	sta Lo24+6
	sta Lo24+8
	sta Lo24+10
	sta Lo24+12
	sta Lo24+14
	sta Lo24+16
	sta Lo24+18
	sta Lo24+20
	sta Lo24+22
	sta Lo24+24
	sta Lo24+26
	sta Lo24+28
	sta Lo24+30
	sta Lo24+32
	sta Lo24+34
	sta Lo24+36
	sta Lo24+38
	ldx GrassState
	lda GrassTop+2,x	; top[2]
	tax
	lda MainAuxMap,x
	sta Lo23+1
	sta Lo23+3
	sta Lo23+5
	sta Lo23+7
	sta Lo23+9
	sta Lo23+11
	sta Lo23+13
	sta Lo23+15
	sta Lo23+17
	sta Lo23+19
	sta Lo23+21
	sta Lo23+23
	sta Lo23+25
	sta Lo23+27
	sta Lo23+29
	sta Lo23+31
	sta Lo23+33
	sta Lo23+35
	sta Lo23+37
	sta Lo23+39
	ldx GrassState
	lda GrassBot+2,x	; Bot[2]
	tax
	lda MainAuxMap,x
	sta Lo24+1
	sta Lo24+3
	sta Lo24+5
	sta Lo24+7
	sta Lo24+9
	sta Lo24+11
	sta Lo24+13
	sta Lo24+15
	sta Lo24+17
	sta Lo24+19
	sta Lo24+21
	sta Lo24+23
	sta Lo24+25
	sta Lo24+27
	sta Lo24+29
	sta Lo24+31
	sta Lo24+33
	sta Lo24+35
	sta Lo24+37
	sta Lo24+39

	sta TXTPAGE1
	ldx GrassState
	lda GrassTop+1,x	; top[1]
	sta Lo23
	sta Lo23+2
	sta Lo23+4
	sta Lo23+6
	sta Lo23+8
	sta Lo23+10
	sta Lo23+12
	sta Lo23+14
	sta Lo23+16
	sta Lo23+18
	sta Lo23+20
	sta Lo23+22
	sta Lo23+24
	sta Lo23+26
	sta Lo23+28
	sta Lo23+30
	sta Lo23+32
	sta Lo23+34
	sta Lo23+36
	sta Lo23+38
	lda GrassBot+1,x	; Bot[1]
	sta Lo24
	sta Lo24+2
	sta Lo24+4
	sta Lo24+6
	sta Lo24+8
	sta Lo24+10
	sta Lo24+12
	sta Lo24+14
	sta Lo24+16
	sta Lo24+18
	sta Lo24+20
	sta Lo24+22
	sta Lo24+24
	sta Lo24+26
	sta Lo24+28
	sta Lo24+30
	sta Lo24+32
	sta Lo24+34
	sta Lo24+36
	sta Lo24+38
	lda GrassTop+3,x	; top[3]
	sta Lo23+1
	sta Lo23+3
	sta Lo23+5
	sta Lo23+7
	sta Lo23+9
	sta Lo23+11
	sta Lo23+13
	sta Lo23+15
	sta Lo23+17
	sta Lo23+19
	sta Lo23+21
	sta Lo23+23
	sta Lo23+25
	sta Lo23+27
	sta Lo23+29
	sta Lo23+31
	sta Lo23+33
	sta Lo23+35
	sta Lo23+37
	sta Lo23+39
	lda GrassBot+3,x	; bot[3]
	sta Lo24+1
	sta Lo24+3
	sta Lo24+5
	sta Lo24+7
	sta Lo24+9
	sta Lo24+11
	sta Lo24+13
	sta Lo24+15
	sta Lo24+17
	sta Lo24+19
	sta Lo24+21
	sta Lo24+23
	sta Lo24+25
	sta Lo24+27
	sta Lo24+29
	sta Lo24+31
	sta Lo24+33
	sta Lo24+35
	sta Lo24+37
	sta Lo24+39
	rts

GrassState	db  00
GrassTop	hex CE,CE,4E,4E,CE,CE,4E,4E
GrassBot	hex 4C,44,44,4C,4C,44,44,4C

WaitKey
:kloop	lda KEY
	bpl :kloop
	sta STROBE
	rts

WaitKeyXY	
	stx ]_waitX
:kloop	jsr VBlank
	lda KEY
	bmi :kpress
	dex
	bne :kloop
	ldx ]_waitX
	dey
	bne :kloop
	clc
	rts

:kpress	sta STROBE
	sec
	rts
]_waitX	db	0

**************************************************
* See if we're running on a IIgs
* From Apple II Technote: 
*   Miscellaneous #7
*   Apple II Family Identification
**************************************************
DetectMachine
	sec	;Set carry bit (flag)
	jsr $FE1F	;Call to the monitor
	bcs :oldmachine    ;If carry is still set, then old machine
*	bcc :newmachine    ;If carry is clear, then new machine
:newmachine   asl _compType	;multiply vblank detection val $7E * 2
	lda #1
	sta GMachineIIgs
	rts
:oldmachine	lda #0
	sta GMachineIIgs
	rts

GMachineIIgs  dw 0


**************************************************
* Wait for vertical blanking interval - IIe/IIgs
**************************************************
VBlankX	lda _compType
:vblActive	cmp RDVBLBAR	; make sure we wait for the current one to stop
	bpl :vblActive ; in case it got launched in rapid succession
:screenActive cmp RDVBLBAR
	bmi :screenActive
	dex
	bne :vblActive
	rts

VBlank	lda _compType
:vblActive	cmp RDVBLBAR	; make sure we wait for the current one to stop
	bpl :vblActive ; in case it got launched in rapid succession
:screenActive cmp RDVBLBAR
	bmi :screenActive
	rts

_compType	db #$7e	; $7e - IIe ; $FE - IIgs 





	use util
	use applerom
	use dlrlib
	use pipes
	use numbers
	use soundengine
	use bird
