;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *DELETE  ([directory path]/)... ([file path])
; or
; *DELETE  ([directory path]/)... ([wildcard pattern])
;
; Delete's one or more files.
;
; 2016-03-25, Rewrote using iterator pattern

star_delete:
   jsr   iterator               ; invoke the directory iterator
;
; The directory iterator calls back to this handler for each matching child
;
; On Entry:
;     $140 contains the full path to the child
;     Y is the offset in the $140 buffer to the child name
;     C=0 if the child is a file, C=1 if the child is a directory
;
   bcs   return                 ; skip directories

   jsr   print_filename

   jsr   STROUT
   .byte "; CONFIRM (Y):"
   nop

   jsr   confirm_or_rts         ; pops an extra address off the stack if Y not presed

   jsr   open_file_read         ; to delete a file it must be open for read
   jmp   delete_file
