;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CHAIN [filename]
;
; Loads specified Basic file to memory and runs it.
;
star_chain:
   jsr   star_load

   lda   $12
   sta   $71
   ldy   #0
   sty   $70
laee1:
   ldy   $3
laee3:
   lda   ($70),y
   iny
   cmp   #$0d
   bne   laee3
   dey
   clc
   tya
   adc   $70
   sta   $70
   bcc   laef5
   inc   $71
laef5:
   ldy   #1
   lda   ($70),y
   bpl   laee1
   clc
   lda   $70
   adc   #2
   sta   $70
   bcc   laf06
   inc   $71

laf06:
   lda   $70
   sta   $0d
   sta   $23
   lda   $71
   sta   $0e
   sta   $24
   jmp   $ce86
