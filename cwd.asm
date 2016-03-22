;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CWD [path]
;
; Sets the current working directory
;
; 2011-05-29, Now uses CMD_REG -- PHS

star_cwd:
   jsr   read_filename          ; copy filename into $140

   jsr   send_name              ; put string at $140 to interface

   lda   #CMD_DIR_CWD           ; set CWD
   jmp   slow_cmd_and_check     ; invokes error handler if return code > 64
