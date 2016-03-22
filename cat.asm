;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CAT ([wildcard pattern])
;
; Produce a directory listing of the files in the root folder of the card, optionally
; displaying only those entries matching a wildcard pattern.
;
; 2011-05-29, Now uses CMD_REG -- PHS
; 2012-05-21, converted to use macros for all writes to PIC
; 2016-03-21, removed old @[filter] code, as the PIC supports proper wildcards -- DMB

star_cat:

   jsr   read_optional_filename ; do we have a filter/path?

   jsr   send_name

   lda   #CMD_DIR_OPEN          ; open directory
   jsr   slow_cmd_and_check     ; invokes error handler if return code > 64

get_next_loop:
   lda   #CMD_DIR_READ          ; get directory item
   jsr   slow_cmd_and_check     ; invokes error handler if return code > 64

   cmp   #STATUS_COMPLETE       ; all done
   beq   @return

   jsr   getasciizstringto140   ; a = 0 on exit

   jsr   read_data_reg          ; get attribute byte
   and   #2                     ; hidden?
   bne   @pause

   ldy   #$ff

@printloop:
   iny
   lda   NAME,y                 ; get next char of filename
   jsr   OSWRCH                 ; Z flags is preserved by OSWRCH, and printing 0 is harmless
   bne   @printloop

   jsr   OSCRLF

@pause:
   bit   $b002                  ; test the rept key
   bvc   @pause                 ; stick here if rept pressed

   lda   #$20                   ; bit 5 is the mask for the escape key
   bit   $b001                  ; test the ctrl/shift/esc keys
   bpl   @pause                 ; stick here if shift pressed
   bvc   @pause                 ; stick here if ctrl pressed
   bne   get_next_loop          ; loop back if escape not pressed

@return:
   rts
