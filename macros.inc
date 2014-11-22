;=================================================================
; macro definitions for AtoMMC
; Collected macros from all files into a single file
;=================================================================

.macro FNADDR addr
   .byte >addr, <addr
.endmacro

.macro writeportFAST port
    sta port
.endmacro

.macro REPERROR addr
   lda #<addr
   sta $d5
   lda #>addr
   sta $d6
   jmp reportFailure
.endmacro

.macro SLOWCMD port
   writeportFAST port
   jsr	SLOWCMD_DELAY
   lda port
   bmi *-5
.endmacro

.macro PREPPUTTOB407
   jsr	PREPPUTTOB407_SUB
.endmacro

; never used
;.macro SENDBYTE val
;   lda #val
;   writeportFAST AWRITE_DATA_REG		
;   jsr interwritedelay
;.endmacro

.macro PREPGETFRB406
   jsr	PREPGETFRB406_SUB
.endmacro

.macro SETRWPTR addr
   lda #<addr
   sta RWPTR
   lda #>addr
   sta RWPTR+1
.endmacro

.macro OPEN_READ
	jsr	OPEN_READ_SUB
.endmacro

.macro OPEN_WRITE
   lda #CMD_FILE_OPEN_WRITE
   jsr open_file
.endmacro

; never used !
;.macro CLOSE_FILE
;   lda #CMD_FILE_CLOSE
;   SLOWCMD ACMD_REG			
;   jsr   expect64orless
;.endmacro

.macro DELETE_FILE
   jsr   DELETE_FILE_SUB
.endmacro

; Subroutines for macros in util.asm
	