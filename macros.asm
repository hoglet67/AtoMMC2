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

; Fast command, command port write followed by interwrite delay on PIC,
; Simply an alias for "jsr slow_cmd" on AVR.
.macro FASTCMD
.ifndef AVR
   jsr   write_cmd_reg
   lda   ACMD_REG
.else
   jsr   slow_cmd
.endif
.endmacro

; Immediate version of fastcmd
.macro FASTCMDI command
   lda   #command
   FASTCMD
.endmacro

.macro SETRWPTR addr
   lda   #<addr
   sta   RWPTR
   lda   #>addr
   sta   RWPTR+1
.endmacro

; Subroutines for macros in util.asm
