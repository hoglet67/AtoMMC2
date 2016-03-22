;================================================================
; macro definitions for AtoMMC
; Collected macros from all files into a single file
;================================================================
;
; 2013-10-09 converted some of the macro calls to jsr calls where
; appropriate. -- PHS
; 2016-03-22 did this more aggressively to reduce code size and
; make other tail optimizations easier. -- DMB
;

.macro FNADDR addr
   .byte >addr, <addr
.endmacro

; Subroutines for macros in util.asm
