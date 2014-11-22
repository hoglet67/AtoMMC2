;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CAT [filter]
;
; Produce a directory listing of the files in the root folder of the card, optionally
; displaying only those entries starting with the character specified as the filter.
;
STARCAT:
    lda  #0
    sta  FILTER

    jsr  SKIPSPC                 ; do we have a filter?
    cmp  #$0d
    beq  @nofiltset

    sta  FILTER                  ; FILTER = 0 if we want all entries shown

@nofiltset:
    lda  #0                      ;  get first directory item
    SLOWCMD $b402
    jsr  expect64orless

    cmp  #64                     ; nothing to do
    bne  @loop

@done:
    rts

@loop:
    lda #1                      ; get directory item
    SLOWCMD $b402
    jsr  expect64orless

    cmp  #64                     ; all done
    beq  @done

    jsr  getasciizstringto140    ; a = 0 on exit

    lda  $b406                   ; get attribute byte
    and  #2                      ; hidden?
    bne  @pause

    lda  NAME                    ; pre-load 1st char of name
    ldy  #0

    ldx  FILTER                  ; if filter set...
    beq  @nofilter

    cpx  NAME                    ; and 1st char doesn't match the filter, then get next.
    bne  @loop

@nofilter:
    jsr  OSWRCH

    iny
    lda  NAME,y                  ; get next char of filename
    bne  @nofilter

    jsr  OSCRLF

@pause:
    bit  $b002                   ; stick here while REPT/shift/ctrl pressed
    bvc  @pause
    lda  $b001
    rol  a                       ; shift/rept pressed?
    bcc  @pause
    rol   a
    bcc  @pause
    rol  a                       ; esc pressed?
    bcs  @loop

    jmp  OSCRLF
