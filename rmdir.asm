;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *RMDIR [path]
;
; Removes an existing child directory that must be empty
;

star_rmdir:
   jsr   read_filename          ; copy filename into $140

   jsr   send_name              ; put string at $140 to interface

   lda   #CMD_DIR_RMDIR         ; delete the directory
   jmp   slow_cmd_and_check     ; invokes error handler if return code > 64
