;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *MKDIR [path]
;
; Creates a new child directory
;

star_mkdir:
   jsr   read_filename          ; copy filename into $140

   jsr   send_name              ; put string at $140 to interface

   lda   #CMD_DIR_MKDIR         ; create the directory
   jmp   slow_cmd_and_check     ; invokes error handler if return code > 64
