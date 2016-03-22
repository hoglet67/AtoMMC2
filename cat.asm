;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CAT (@[filter])
;
; Produce a directory listing of the files in the root folder of the card, optionally
; displaying only those entries starting with the character specified as the filter.
;
; 2011-05-29, Now uses CMD_REG -- PHS
; 2012-05-21, converted to use macros for all writes to PIC

star_cat:
   lda   #0                     ; FILTER = 0 if we want all entries shown
   sta   FILTER

   lda   #$0d
   sta   NAME

@next:
   jsr   SKIPSPC                ; do we have a filter/path?

   cmp   #$0d
   beq   @continue

   cmp   #'@'
   beq   @setfilt

   ldx   #0

@copyname:
   sta   NAME,x
   cmp   #$0d
   beq   @continue
   cmp   #$20
   beq   @terminate

   iny
   lda   $100,y
   inx
   bne   @copyname              ; branch always

@terminate:
   lda   #$0d
   sta   NAME,x
   bne   @next                  ; branch always


@setfilt:
   iny
   lda   $100,y
   cmp   #$0d
   beq   @continue

   sta   FILTER                 ; yaay! filter!
   iny
   bne   @next                  ; branch always




@continue:
   jsr   send_name

   lda   #CMD_DIR_OPEN          ; open directory
   jsr   slow_cmd_and_check     ; invokes error handler if return code > 64

get_next_loop:
   lda   #CMD_DIR_READ          ; get directory item
   jsr   slow_cmd_and_check     ; invokes error handler if return code > 64

   cmp   #STATUS_COMPLETE       ; all done
   bne   @printit

   rts

@printit:
   jsr   getasciizstringto140   ; a = 0 on exit

   jsr   read_data_reg          ; get attribute byte
   and   #2                     ; hidden?
   bne   @pause

   lda   NAME                   ; pre-load 1st char of name
   ldy   #0

   ldx   FILTER                 ; if filter set...
   beq   @nofilter

   cpx   NAME                   ; and 1st char doesn't match the filter, then get next.
   bne   get_next_loop

@nofilter:
   jsr   OSWRCH

   iny
   lda   NAME,y                 ; get next char of filename
   bne   @nofilter

   jsr   OSCRLF

@pause:
   bit   $b002                  ; test the rept key
   bvc   @pause                 ; stick here if rept pressed

   lda   #$20                   ; bit 5 is the mask for the escape key
   bit   $b001                  ; test the ctrl/shift/esc keys
   bpl   @pause                 ; stick here if shift pressed
   bvc   @pause                 ; stick here if ctrl pressed
   bne   get_next_loop          ; loop back if escape not pressed

   jmp   OSCRLF


