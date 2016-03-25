;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *REN [from path] [to path]
;
; Renames a file/directory
;
; Can also be used to move a file/directory to a different directory
;
star_ren:
   jsr   read_filename          ; copy "from" path into $140
   jsr   send_name              ; put string at $140 to interface

   jsr   read_filename          ; copy "to" path  into $140
   jsr   send_additional_name   ; put string at $140 to interface (without resetting write pointer)
        
   lda   #CMD_RENAME            ; set RENAME
   jmp   slow_cmd_and_check     ; invokes error handler if return code > 64
