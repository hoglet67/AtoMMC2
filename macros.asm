;================================================================
; macro definitions for AtoMMC
; Collected macros from all files into a single file
;================================================================
;
; 2013-10-09 converted some of the macro calls to jsr calls where
; appropriate. -- PHS
;

.macro FNADDR addr
   .byte >addr, <addr
.endmacro

.macro SETRWPTR addr
   lda   #<addr
   sta   RWPTR
   lda   #>addr
   sta   RWPTR+1
.endmacro

; Subroutines for macros in util.asm
