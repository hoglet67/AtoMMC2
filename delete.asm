;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *DELETE [filename] ([Y])
;
; Deletes the specified file after a prompt, unless Y specified on command line
;
star_delete:
   jsr   open_filename_read     ; invokes error handler if return code > 64

   jsr   STROUT
   .byte "CONFIRM (Y):"
   nop

   jsr   confirm_or_rts         ; pops an extra address off the stack if Y not presed

   jmp   delete_file

