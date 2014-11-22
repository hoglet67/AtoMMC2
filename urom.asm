;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *UROM [val]
;
; Set the current utility ROM, disable interface interrupts and await break..!
; Requires extension ROM board with latch at #BFFF.
;
STARUROM:
   ldx   #$cb             ; scan parameter fail if none
   jsr   RDOPTAD
   bne   selectrom

   jmp   COSSYN

; entry point for 3rd party usage such as ROMLOAD

selectrom:
   lda   $bffd             ; cache interface option bits
   sta   $cc

   jsr   ifdi              ; interface disable interrupt
   
   ldx   #@rtn_end-@rtn

@movefn:
   lda   @rtn,x
   sta   $8200,x
   dex
   bpl   @movefn

   jmp   $8200


@rtn:
   lda   $cb               ; change the ROM
   sta   $bfff

   lda   $cc               ; set the option bits to control the $7000/$a000 page mapping
   sta   $bffe

   jsr   STROUT
   .byte "<PRESS BREAK>"
   nop

   lda   #0

@infinite:
   beq   @infinite

@rtn_end:
