
.include "atmmc2def.asm"

.include "macros.asm"

.segment "CODE"


AtoMMC2:
   ; test ctrl - if pressed, don't initialise
   ;
   bit   $b001
   bvs   @initialise

   ; don't initialise the firmware
.ifndef EOOO
   ; - however we got an interrupt so we need to clear it
   ;
   ; lda   #30                  ; as we've had an interrupt we want to wait longer
   ; sta   CRC                  ; for the interface to respond
   jsr   irqgetcardtype
   pla
   rti
.else
   ; the E000 build
   jmp   $c2b2                  ; set #2900 text space and enter command handler
.endif

@initialise:
   tya
   pha
   txa
   pha

   ; forget VIA! - we got the interrupt so the PL8 interface is in the house!

   ; read card type
   ;
   ; lda   #7                   ; timeout value, ret when crc == -1
   ; sta   CRC
   jsr   irqgetcardtype
   ; bit   CRC
   ; bmi   @unpatched

   tay

   ldx   #0

   stx   FKIDX                  ; fake key index for OSRDCH patch, just piggybacking
   stx   TUBE_FLAG              ; @@TUBE@@ disable tube by default

   lda   #43                    ;'+'
   sta   $800b

@shorttitle:
   lda   version,x
   and   #$bf
   sta   $800d,x
   inx
   cmp   #$20
   bne   @shorttitle

   bit   $b002                  ; is REPT pressed?
   bvs   @quiet

   dex

@announce:
   and   #$bf
   sta   $800d,x
   inx

   lda   version,x
   cmp   #$0d
   bne   @announce

   ; display appropriate type
   ; none = 0, mmc = 1, sdv1 = 2, sdv2 = 4
   ;
   tya
   jsr   bittoindex
   ldy   #0

@sctloop:
   lda   cardtypes,x
   and   #$bf
   sta   $801c,y
   inx
   iny
   cpy   #4
   bne   @sctloop


@quiet:
   jsr   installhooks

;    $b40f    $b001
;      0        0    [inv. sh, sh pressed]     0
;      0        1    [inv. sh, sh not pressed] 1
;      1        0    [norm sh, sh pressed]     1
;      1        1    [norm sh, sh not pressed] 0

   FASTCMDI CMD_GET_CFG_BYTE    ; get config byte

   asl   a                      ; 'normal shift' bit is 6
   eor   $b001
   bpl   @unpatched


@patchosrdch:
   lda   #<osrdchcode
   sta   RDCVEC
   lda   #>osrdchcode
   sta   RDCVEC+1

@unpatched:
   pla
   tax
   pla
   tay

.ifdef EOOO
   jmp   $c2b2                  ; set #2900 text space and enter command handler
.endif

irqveccode:
   pla                          ; pop the accumulator as saved by the irq handler
   rti

; takes a card type in A
; 0 = no card
; bit 1 = type 1 (MMC)
; bit 2 = type 2 (SD)
; etc etc
;
bittoindex:
   ora   #8                     ; bit 3 -- 'no card available' - to ensure we stop
   sta   ZPTW

   lda   #$fc                   ; spot the bit
   clc
@add:
   adc   #4
   lsr   ZPTW
   bcc   @add
   tax
   rts

print_version:
   ldx   #0

@announce:
   lda   version,x
   jsr   OSWRCH
   inx
   dey
   bne   @announce
   rts

installhooks2:
   ldy   #(version_short - version)
   jsr   print_version

.ifndef EOOO
   jsr   ifen                   ; interface enable interrupt, if at A000
.endif

; install hooks. 6 vectors, 12 bytes
;
; !!! this is all you need to call if you're not using IRQs !!!
;
installhooks:
   ldx   #11+12

@initvectors:
   lda   fullvecdat,x
   sta   IRQVEC,x
   dex
   bpl   @initvectors
   rts

;igct_delay:
;   ldx   0
;   ldy   0
;igct_inner:
;   dey
;   bne   igct_inner
;   dex
;   bne   igct_inner
;
;   dec   CRC
;   bmi   igct_quit

irqgetcardtype:
   ; await the 0xaa,0x55,0xaa... sequence which shows that the interface
   ; is initialised and responding

   FASTCMDI CMD_GET_HEARTBEAT
   cmp   #$aa
   bne   irqgetcardtype

irqgetcardtype2:
   FASTCMDI CMD_GET_HEARTBEAT
   cmp   #$55
   bne   irqgetcardtype

   ; send read card type command - this also de-asserts the interrupt

   SLOWCMDI CMD_GET_CARD_TYPE

igct_quit:
   rts

; patched os input function
;
; streams fake keypresses to the system
; re-registers the bios' function when
; a> fake keys have all been sent or
; b> when no shift-key is detected
;
osrdchcode:
   php
   cld
   stx   $e4
   sty   $e5

   ldx   FKIDX
   lda   fakekeys,x
   cmp   #$0d
   beq   @unpatch

   inx
   stx   FKIDX

   ldx   $e4
   ldy   $e5
   plp
   rts

@unpatch:
   ; restore OSRDCH, continue on to read a char
   ;
   ; ldx   $e4
   ; ldy   $e5

osrdchcode_unhook:
   lda   #$94
   sta   RDCVEC
   lda   #$fe
   sta   RDCVEC+1

   ; plp
   lda   #$0d
   pha
   jmp   $fe5c
   ; jmp   (RDCVEC)

; Kees Van Oss' version of the CLI interpreter
;
osclicode:

;=================================================================
; STAR-COMMAND INTERPRETER
;=================================================================
star_com:
   ldx   #$ff                   ; set up pointers
   cld
star_com1:
   ldy   #0
   jsr   SKIPSPC
   dey
star_com2:
   iny
   inx

star_com3:
   lda   com_tab,x              ; look up star-command
   bmi   star_com5
   cmp   $100,y
   beq   star_com2
   dex
star_com4:
   inx
   lda   com_tab,x
   bpl   star_com4
   inx
   lda   $100,y
   cmp   #46                    ; '.'
   bne   star_com1
   iny
   dex
   bcs   star_com3

star_com5:
   sty   $9a

   ldy   $3                     ; save command pointers
   sty   tmp_ptr3
   ldy   $5
   sty   tmp_ptr5
   ldy   $6
   sty   tmp_ptr6
   ldy   #<$100
   sty   $5
   ldy   #>$100
   sty   $6
   ldy   $9a
   sty   $3

   sta   $53                    ; execute star command
   lda   com_tab+1,x
   sta   $52
   ldx   #0
   jsr   comint6

   ldy   tmp_ptr5               ; restore command pointers
   sty   $5
   ldy   tmp_ptr6
   sty   $6
   ldy   tmp_ptr3
   sty   $3

   lda   #$0d
   sta   ($5),y

   rts

comint6:
   jmp   ($0052)

.include "cat.asm"
.include "cwd.asm"
.include "cfg.asm"
.include "crc.asm"
.include "delete.asm"
.include "exec.asm"
.include "fatinfo.asm"
.include "help.asm"
.include "info.asm"
.include "load.asm"
.include "run.asm"
.include "save.asm"
.include "file.asm"
.include "util.asm"
.include "chain.asm"
.include "raf.asm"
.include "tube.asm"
        
;.include "urom.asm"

cardtypes:
   .byte " MMC  SDSDHC N/A"
   ;      1111222244448888

fullvecdat:
   .word irqveccode             ; 204 IRQVEC
   .word osclicode              ; 206 COMVEC
   .word $fe52                  ; 208 WRCVEC
   .word $fe94                  ; 20A RDCVEC
   .word osloadcode             ; 20C LODVEC
   .word ossavecode             ; 20E SAVVEC

rafvecdat:
   .word osrdarcode             ; 210 RDRVEC
   .word osstarcode             ; 212 STRVEC
   .word osbgetcode             ; 214 BGTVEC
   .word osbputcode             ; 216 BPTVEC
   .word osfindcode             ; 218 FNDVEC
   .word osshutcode             ; 21A SHTVEC

fakekeys:
   .byte "*MENU"
   .byte $0d,0

com_tab:
   .byte "CAT"                  ; in cat.asm
   FNADDR star_cat

   .byte "CWD"                  ; in cwd.asm
   FNADDR star_cwd

   .byte "DELETE"               ; in delete.asm
   FNADDR star_delete

   .byte "EXEC"                 ; in exec.asm
   FNADDR star_exec

   .byte "RUN"                  ; in exec.asm
   FNADDR star_run

   .byte "HELP"                 ; in help.asm
   FNADDR star_help

   .byte "INFO"                 ; in info.asm
   FNADDR star_info

   .byte "LOAD"                 ; in load.asm
   FNADDR star_load

;  .byte "RLOAD"                ; in load.asm
;  FNADDR star_rload

;  .byte "ROMLOAD"              ; in load.asm
;  FNADDR star_romload

;  .byte "UROM"                 ; in urom.asm
;  FNADDR star_urom

   .byte "MON"
   FNADDR $fa1a

   .byte "NOMON"
   FNADDR $fa19

   .byte "CFG"                  ; in cfg.asm
   FNADDR star_cfg

   .byte "PBD"                  ; in cfg.asm
   FNADDR star_pbd

   .byte "PBV"                  ; in cfg.asm
   FNADDR star_pbv

   .byte "SAVE"                 ; in save.asm
   FNADDR star_save

   .byte "FATINFO"              ; in fatinfo.asm
   FNADDR star_fatinfo

   .byte "CRC"                  ; in crc.asm
   FNADDR star_crc

   .byte "CHAIN"                ; in chain.asm
   FNADDR star_chain

   FNADDR star_arbitrary


.ifdef EOOO
.include "BRAN.asm"
.endif

.SEGMENT "WRMSTRT"

warmstart:
   jmp   installhooks2


.SEGMENT "VSN"

version:
   .byte "ATOMMC2 V3.??"
.ifndef EOOO
   .byte "A"
.else
   .byte "E"
.endif
   .byte $0d,$0a
version_short:
   .byte " (C) 2008-2016  "
   .byte "CHARLIE ROBSON. "
version_long:
        
   .end
