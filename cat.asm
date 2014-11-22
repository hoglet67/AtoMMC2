;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CAT (@[filter])
;
; Produce a directory listing of the files in the root folder of the card, optionally
; displaying only those entries starting with the character specified as the filter.
;
STARCAT:
   lda   #0                      ; FILTER = 0 if we want all entries shown
   sta   FILTER

   lda   #$0d
   sta   NAME

@next:
   jsr   SKIPSPC                 ; do we have a filter/path?

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
   bne   @copyname               ; branch always

@terminate:
   lda   #$0d
   sta   NAME,x
   bne   @next


@setfilt:
   iny
   lda   $100,y
   cmp   #$0d
   beq   @continue

   sta   FILTER                  ; yaay! filter!
   iny
   bne   @next




@continue:
   jsr   $f844
   jsr   send_name

   lda   #0                      ;  open directory
   SLOWCMD $b402
   jsr   expect64orless

@loop:
   lda   #1                      ; get directory item
   SLOWCMD $b402
   jsr   expect64orless

   cmp   #$40                   ; all done
   bne   @printit

   rts

@printit:
   jsr   getasciizstringto140    ; a = 0 on exit

   lda   $b406                   ; get attribute byte
   and   #2                      ; hidden?
   bne   @pause

   lda   NAME                    ; pre-load 1st char of name
   ldy   #0

   ldx   FILTER                  ; if filter set...
   beq   @nofilter

   cpx   NAME                    ; and 1st char doesn't match the filter, then get next.
   bne   @loop

@nofilter:
   jsr   OSWRCH

   iny
   lda   NAME,y                  ; get next char of filename
   bne   @nofilter

   jsr   OSCRLF

@pause:
   bit   $b002                   ; stick here while REPT/shift/ctrl pressed
   bvc   @pause
   lda   $b001
   rol   a                       ; shift/rept pressed?
   bcc   @pause
   rol   a
   bcc   @pause
   rol   a                       ; esc pressed?
   bcs   @loop

   jmp   OSCRLF

@done:
   rts

