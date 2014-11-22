;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CWD [path]
;
; Sets the current working directory
;
STARCWD:
   jsr   SKIPSPC
   bne   @setcwd

   jmp   COSSYN

@setcwd:
   jsr   read_filename        ; copy filename into $140

   jsr   COSPOST              ; Do COS interpreter post test
   ldx   #$c9                 ; File data starts at #C9

   jsr   CHKNAME
   jsr   send_name            ; put string at $140 to interface

	lda	#$10						; set CWD
   SLOWCMD $b402
   jmp   expect64orless

   rts