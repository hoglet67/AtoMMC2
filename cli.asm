;
; TODO
;
; when it's all working investigate the use of an irq handler for slow command completion
; *BANNER?

; OS overrides
;
TOP         =$0d
PAGE        =$12
ARITHWK     =$23

; these need to be in ZP
;
RWPTR       =$ac         ; W - data target vector
ZPTW        =$ae         ; [3] - general use temp vector, used by vechexs, RS, WS

LFNPTR      =$c9         ; W -pointer to filename (usually $140)
LLOAD       =$cb         ; W - load address
LEXEC       =$cd         ; W - execution address
LLENGTH     =$cf         ; W - byte length

SFNPTR      =$c9         ; W -pointer to filename (usually $140)
SLOAD       =$cb         ; W - reload address
SEXEC       =$cd         ; W - execute
SSTART      =$cf         ; W - data start
SEND        =$d1         ; W - data end + 1

CRC         =$c9         ; 3 bytes in ZP - should be ok as this addr only used for load/save??

RDCCNT      =$c9         ; B - bytes in pool - ie ready to be read from file
RDCLEN      =$ca         ; W - length of file supplying characters

tmp_ptr3    =$D5
tmp_ptr5    =$D6
tmp_ptr6    =$D7

MONFLAG     =$ea         ; 0 = messages on, ff = off

NAME       =$140         ; sits astride the BASIC input buffer and string processing area.

IRQVEC     =$204         ; we patch these (maybe more ;l)
COMVEC     =$206
RDCVEC     =$20a
LODVEC     =$20c
SAVVEC     =$20e

; DOS scratch RAM 3CA-3FC. As the AtoMMC interface effectively precludes the use of DOS..
;
FKIDX      =$3ca         ; B - fake key index
RWLEN      =$3cb         ; W - count of bytes to write
FILTER     =$3cd         ; B - dir walk filter 


; FN      ADDR        REGS PRESERVED
;
OSWRCH     =$fff4
OSRDCH     =$ffe3
OSCRLF     =$ffed
COSSYN     =$fa7d
COSPOST    =$fa76
RDADDR     =$fa65
CHKNAME    =$f84f
SKIPSPC    =$f876
RDOPTAD    =$f893
BADNAME    =$f86c
WSXFER2    =$f85C
COPYNAME   =$f818
HEXOUT     =$f802       ; x,y
HEXOUTS    =$f7fa       ; x,y
STROUT     =$f7d1       ; x



.macro FNADDR
   .byte >%1, <%1
   .endm

.macro REPERROR
   lda #<%1
   sta $d5
   lda #>%1
   sta $d6
   jmp reportFailure
   .endm

.macro SLOWCMD
   sta %1
   lda #0
   sec 
   sbc #1
   bne *-2
   lda %1
   bmi *-10
   .endm

.macro PREPPUTTOB407
   lda #$ff
   sta $b403
   jsr interwritedelay
.endm

.macro SENDBYTE
   lda %1 
   sta $b407
   jsr interwritedelay
.endm

.macro PREPGETFRB406
   lda #$3f
   sta $b406
   jsr interwritedelay
.endm

.macro SETRWPTR
   lda #<%1
   sta RWPTR
   lda #>%1
   sta RWPTR+1
.endm



firstcode = $a000



   *=firstcode

   ; test ctrl - if pressed, don't initialise
   ;
   
   jsr	show_irq
   bit $b001
   bvs irq_initialise

   ; don't initialise the firmware
   ; - however we got an interrupt so we need to clear it
   ;
   jsr irqgetcardtype
   pla
   rti


irq_initialise
   tya
   pha
   txa
   pha

   ; forget VIA! - we got the interrupt so the PL8 interface is in the house!

   ; read card type
   ;
   jsr irqgetcardtype
   tay

   ldx #0

   stx FKIDX            ; fake key index for OSRDCH patch, just piggybacking

   lda #43              ;'+'
   sta $800b

irq_shorttitle
   lda version,x
   and #$bf
   sta $800d,x
   inx
   cmp #$20
   bne irq_shorttitle

   bit $b002            ; is REPT pressed?
   bvs irq_quiet

   dex

irq_announcelp
   and #$bf
   sta $800d,x
   inx

   lda version,x
   cmp #$0d
   bne irq_announcelp

   ; display appropriate type
   ; none = 0, mmc = 1, sdv1 = 2, sdv2 = 4
   ;
   tya
   beq irq_showcardtype   ; 0 = no card

   lsr a               ; 1,2,4 -> 0,1,2
   and #3              ; just in case
   clc
   adc #1              ; -> 1,2,3
   asl a
   asl a               ; -> 4, 8, 12

irq_showcardtype
   tax
   ldy #3

irq_sctloop
   lda cardtypes,x
   and #$bf
   sta $801c,y
   inx
   dey
   bpl irq_sctloop


irq_quiet
   jsr installhooks

   lda #$f0             ; get config byte
   sta $b40f
   jsr interwritedelay

;   lda $b40f            ; bit 6 = 'shift needed' bit
;   and #$40             ; always patch if it's 0
;   beq irq_patchosrdch
;
;   bit $b001            ; is shift pressed? 
;   bmi irq_unpatched    ; nope

; b40f6  $b0017
;      0        0    [inv. sh, sh pressed]     0
;      0        1    [inv. sh, sh not pressed] 1
;      1        0    [norm sh, sh pressed]     1
;      1        1    [norm sh, sh not pressed] 0

   lda $b40f             ; 'normal shift' bit is 6
   asl a                 ;
   eor $b001             ;
   bpl irq_unpatched     ;
   

irq_patchosrdch
   lda #<osrdchcode
   sta RDCVEC
   lda #>osrdchcode
   sta RDCVEC+1

irq_unpatched
   pla
   tax
   pla
   tay

irqveccode
   pla                 ; pop the accumulator as saved by the irq handler
   rti




installhooks2
   ldx #0
ih2_ann
   lda version,x
   jsr OSWRCH
   inx
   cpx #16
   bne ih2_ann

   
; install hooks. 6 vectors, 12 bytes
;
; !!! this is all you need to call if you're not using IRQs !!!
;
installhooks
   ldx #11

irq_initvectors
   lda fullvecdat,x
   sta IRQVEC,x
   dex
   bpl irq_initvectors

   rts



irqgetcardtype
   ; await the 0xaa,0x55,0xaa... sequence which shows that the interface
   ; is initialised and responding
   ;   
   lda #$fe
   
   jsr	out_byte
   
   sta $b40f
   jsr interwritedelay
   lda $b40f
   
   jsr	in_byte
   
   cmp #$aa
   bne irqgetcardtype

   lda #$fe

   jsr	out_byte

   sta $b40f
   jsr interwritedelay
   lda $b40f

   jsr	in_byte

   cmp #$55
   bne irqgetcardtype

   ; send read card type command - this also de-asserts the interrupt

   lda #$80

   jsr	out_byte

   sta $b40f
   jsr interwritedelay
   lda $b40f

   jsr	in_byte
   rts



in_byte
	pha
	lda	#$49
io_byte
	jsr	OSWRCH
	pla
	pha
	jsr	HEXOUT
io_eol
	jsr OSCRLF
	pla
	rts
	
out_byte
	pha
	lda	#$4F
	jmp	io_byte
	
show_irq
	pha
	lda	#$21
	jsr	OSWRCH
	lda	#$21
	jsr	OSWRCH	
	lda	#$21
	jsr	OSWRCH
	jsr OSCRLF
	jsr OSCRLF
	pla
	rts
	jmp	io_eol


; patched os input function
;
; streams fake keypresses to the system
; re-registers the bios' function when
; a> fake keys have all been sent or
; b> when no shift-key is detected
;
osrdchcode
   php
   cld
   stx $e4
   sty $e5

   ldx FKIDX
   lda fakekeys,x
   beq osr_unpatch

   inx
   stx FKIDX

   ldx $e4
   ldy $e5
   plp
   rts

osr_unpatch
   ; restore OSRDCH, continue on to read a char
   ;
   ldx $e4
   ldy $e5

osr_unhook
   lda #$94
   sta RDCVEC
   lda #$fe
   sta RDCVEC+1
   
   plp
   jmp (RDCVEC)








; Kees Van Oss' version of the CLI interpreter
;
osclicode

;=================================================================
; STAR-COMMAND INTERPRETER
;=================================================================
star_com    LDX #$ff             ; Set up pointers
            CLD
star_com1   LDY #0
            JSR SKIPSPC
            DEY
star_com2   INY
            INX

star_com3   LDA com_tab,X        ; Look up star-command
            BMI star_com5
            CMP $100,Y
            BEQ star_com2
            DEX
star_com4   INX
            LDA com_tab,X
            BPL star_com4
            INX
            LDA $100,Y
            CMP #46                 ; '.'
            BNE star_com1
            INY
            DEX
            BCS star_com3

star_com5      STY $9a

            LDY $3             ; Save command pointers
            STY tmp_ptr3
            LDY $5
            STY tmp_ptr5
            LDY $6
            STY tmp_ptr6
            LDY #<$100
            STY $5
            LDY #>$100
            STY $6
            LDY $9a
            STY $3

            STA $53            ; Execute star command
            LDA com_tab+1,X
            STA $52
            ldx #0
            JSR comint6

            LDY tmp_ptr5         ; Restore command pointers
            STY $5
            LDY tmp_ptr6
            STY $6
            LDY tmp_ptr3
            STY $3

            LDA #$0D
            STA ($5),Y

            RTS 

comint6       JMP ($0052)








.include "cat.asm"
.include "cfgcmd.asm"
.include "crc.asm"
.include "exec.asm"
.include "fatinfo.asm"
.include "help.asm"
.include "info.asm"
.include "load.asm"
.include "run.asm"
.include "save.asm"

.include "file.asm"
.include "util.asm"






cardtypes
   .byte "--- CMM DS  CHDS"

fullvecdat
   .word irqveccode, osclicode, $fe52, $fe94, osloadcode, ossavecode

fakekeys
   .byte "*MENU"
   .byte $0d,0

com_tab
   .byte "CAT"
   FNADDR STARCAT

   .byte "EXEC"
   FNADDR STAREXEC

   .byte "RUN"         ; in exec.asm
   FNADDR STARRUN

   .byte "HELP"
   FNADDR STARHELP

   .byte "INFO"
   FNADDR STARINFO

   .byte "LOAD"
   FNADDR STARLOAD

   .byte "RLOAD"        ; in load.asm
   FNADDR STARRLOAD

   .byte "ROMLOAD"        ; in load.asm
   FNADDR STARROMLOAD

   .byte "MON"
   FNADDR $fa1a

   .byte "NOMON"
   FNADDR $fa19

   .byte "CFG"         ; in cfgcmd.asm
   FNADDR STARCFG

   .byte "PBD"         ; in cfgcmd.asm
   FNADDR STARPBD

   .byte "PBV"         ; in cfgcmd.asm
   FNADDR STARPBV

   .byte "SAVE"
   FNADDR STARSAVE

   .byte "FATINFO"
   FNADDR STARFATINFO

   .byte "CRC"
   FNADDR STARCRC
   
   .byte "VER"
   FNADDR STARVER

   FNADDR STARARBITRARY

lastcode

SQ=34   ; "

   *=(firstcode+4096)-256

diskerrortab
   .byte $0d
   .byte "DISK FAULT",$0d
   .byte "NOT READY",$0d
   .byte "NOT FOUND",$0d
   .byte "NO PATH",$0d
   .byte "NOT OPEN",$0d
   .byte "NO CARD",$0d
   .byte "NO FILESYSTEM",$0d
   .byte "EEPROM ERROR",$0d
   .byte "FAILED",$0d
   .byte "NOT NOW",$0d
   .byte "SILLY",$0d

errorhandler
   .byte "@=8;P.$6$7'"
   .byte SQ
   .byte "ERROR - "
   .byte SQ
   .byte "$!#D5&#FFFF;"
   .byte "IF?1|?2P."
   .byte SQ
   .byte " - LINE "
   .byte SQ
   .byte "!1& #FFFF"
   .byte $0d,0,0
   .byte "P.';E."
   .byte $0d



   *=(firstcode+4096)-52
   jmp installhooks2


   *=(firstcode+4096)-48
version
   .byte "ATOMMC2 - V1.7"
   .byte $0d,$0a
   .byte " (C) 2008-2010  "
   .byte "CHARLIE ROBSON. "


   .end
