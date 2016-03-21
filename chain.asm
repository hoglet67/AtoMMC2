;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CHAIN [filename]
;
; Loads specified Basic file to memory and runs it.
;
star_chain:
   jsr   star_load

   lda   $12
   sta   $0e
   ldy   #0
   sty   $0d
laee1:
   ldy   $3
laee3:
   lda   ($0d),y
   iny
   cmp   #$0d
   bne   laee3
   dey
   clc
   tya
   adc   $0d
   sta   $0d
   bcc   laef5
   inc   $0e
laef5:
   ldy   #1
   lda   ($0d),y
   bpl   laee1

   clc
   lda   $0d
   adc   #2
   sta   $0d
   sta   $23
   lda   $0e
   adc   #0
   sta   $0e
   sta   $24

   jmp   $ce86
