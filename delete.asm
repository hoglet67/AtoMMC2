;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *DELETE [filename] ([Y])
;
; Deletes the specified file after a prompt, unless Y specified on command line
;
star_delete:
   jsr   read_filename
   jsr   open_file_read

   jsr   confirm

   pha
   jsr   OSCRLF
   pla
   cmp   #'Y'
   bne   @return

   jsr   delete_file

@return:
   rts

confirm:
   jsr   STROUT
   .byte "CONFIRM (Y):"
   nop

   jsr   OSRDCH
   jmp   OSWRCH
