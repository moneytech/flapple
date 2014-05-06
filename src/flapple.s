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
	jsr DetectIIgs
	jsr InitState	;@todo: IIc vblank code
	
	jsr VBlank
	jsr DL_SetDLRMode
	lda #$77
	jsr DL_Clear


GameLoop	
	; handle input
	; draw grass
	; wait vblank
	; undraw player
	; update pipes / draw
	; update player / draw (w/collision)
	; update score

	jmp UndrawBird
UndrawBirdDone
	jmp UpdatePipes
UpdatePipesDone
	jmp HandleInput
HandleInputDone
	jmp DrawBird
DrawBirdDone
	jmp DrawScore
DrawScoreDone
	jmp UpdateGrass
UpdateGrassDone

	jsr FlapBird
	jsr VBlank
	;jsr WaitKey
	lda QuitFlag
	beq GameLoop
	bne Quit


HandleInput
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

QuitFlag	db 0	; set to 1 to quit

Quit	jsr MLI	; first actual command, call ProDOS vector
	dfb $65	; with "quit" request ($65)
	da QuitParm
	bcs Error
	brk $00	; shouldn't ever  here!

QuitParm	dfb 4	; number of parameters
	dfb 0	; standard quit type
	da $0000	; not needed when using standard quit
	dfb 0	; not used
	da $0000	; not used


Error	brk $00	; shouldn't be here either


******************************
* Score Routines
*********************
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
	ldx #18
	sta Lo01,x
	sta Lo02,x
	jmp DrawScoreDone

ScoreUp	sed
	lda ScoreLo
	clc
	adc #1
	sta ScoreLo
	bcc :noFlip
	lda ScoreHi
	adc #0
	sta ScoreHi
:noFlip	cld
	rts

PipeXScore    equ 50
ScoreLo	db 0
ScoreHi	db 0


	

**************************************************
* Grass 
**************************************************
UpdateGrass	inc GrassState
	lda GrassState
	cmp #4
	bne :noReset
	lda #0
	sta GrassState
:noReset	sta TXTPAGE2
	ldx GrassState
	lda GrassTop,x
	tax
	lda MainAuxMap,x
	ldx #0
:lp1	sta Lo23,x
	inx
	inx
	cpx #40
	bcc :lp1
	ldx GrassState
	lda GrassTop+2,x
	tax
	lda MainAuxMap,x
	ldx #0
:lp2	sta Lo23+1,x
	inx 
	inx
	cpx #40
	bcc :lp2	

	sta TXTPAGE1
	ldx GrassState
	lda GrassTop+1,x
	ldx #0
:lp3	sta Lo23,x
	inx
	inx
	cpx #40
	bcc :lp3
	ldx GrassState
	lda GrassTop+3,x
	ldx #0
:lp4	sta Lo23+1,x
	inx 
	inx
	cpx #40
	bcc :lp4
:bottom	sta TXTPAGE2
	ldx GrassState
	lda GrassBot,x
	tax
	lda MainAuxMap,x
	ldx #0
:lp5	sta Lo24,x
	inx
	inx
	cpx #40
	bcc :lp5
	ldx GrassState
	lda GrassBot+2,x
	tax
	lda MainAuxMap,x
	ldx #0
:lp6	sta Lo24+1,x
	inx 
	inx
	cpx #40
	bcc :lp6	

	sta TXTPAGE1
	ldx GrassState
	lda GrassBot+1,x
	ldx #0
:lp7	sta Lo24,x
	inx
	inx
	cpx #40
	bcc :lp7
	ldx GrassState
	lda GrassBot+3,x
	ldx #0
:lp8	sta Lo24+1,x
	inx 
	inx
	cpx #40
	bcc :lp8
	jmp UpdateGrassDone

GrassState	db  00
GrassTop	hex CE,CE,4E,4E,CE,CE,4E,4E
GrassBot	hex 4C,44,44,4C,4C,44,44,4C

WaitKey
:kloop	lda KEY
	bpl :kloop
	sta STROBE
	rts

WaitSmart
:kloop	lda KEY
	bpl :kloop
	sta STROBE
	rts

_WaitSmartMode db 0	;0 = no pause until magickey
		;1 = always pause

**************************************************
* See if we're running on a IIgs
* From Apple II Technote: 
*   Miscellaneous #7
*   Apple II Family Identification
**************************************************
DetectIIgs	
	sec	;Set carry bit (flag)
	jsr $FE1F	;Call to the monitor
	bcs :oldmachine    ;If carry is still set, then old machine
*	bcc :newmachine    ;If carry is clear, then new machine
:newmachine   lda #1
	sta GMachineIIgs
	rts
:oldmachine	lda #0
	sta GMachineIIgs
	rts

InitState
	lda GMachineIIgs
	beq :IIe
	rts
:IIe	rts	

GMachineIIgs  dw 0

VBlankSafe	
*	pha
*	phx
*	phy
	jsr VBlank
*	ply
*	plx
*	pla
	rts

VBlank	lda _vblType
	bne :IIc
	jsr VBlankNormal
	rts
:IIc	rts

_vblType	db 0	; 0 - normal, 1 - IIc

**************************************************
* Wait for vertical blanking interval - IIe/IIgs
**************************************************
VBlankNormal
:loop1	lda RDVBLBAR
	bpl :loop1 ; not VBL
:loop	lda $c019
	bmi :loop ;wait for beginning of VBL interval
	rts





	use util
	use applerom
	use dlrlib
	use pipes
	use numbers
	use sprite	; this is getting to be a lot
	use bird
