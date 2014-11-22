;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CAT [filter]
;
;  produce a directory listing of the files in the root folder of the card
;
STARCAT
    lda #0
    sta FILTER

    jsr SKIPSPC                 ; do we have a filter?
    cmp #$0d
    beq sct_nofiltset

    sta FILTER                  ; FILTER = 0 if we want all entries shown

sct_nofiltset
    lda #0                      ;  get first directory item
    SLOWCMD $b402
    jsr expect64orless

    cmp #64                     ; nothing to do
    bne sct_loop

sct_done
    rts

sct_loop
    lda #1                      ; get directory item
    SLOWCMD $b402
    jsr  expect64orless

    cmp #64                     ; all done
    beq sct_done

    jsr getasciizstringto140    ; a = 0 on exit

    lda $b406                   ; get attribute byte
    and #2                      ; hidden?
    bne sct_pause

    lda NAME                    ; pre-load 1st char of name
    ldy #0

    ldx FILTER                  ; if filter set...
    beq sct_nofilter

    cpx NAME                    ; and 1st char doesn't match the filter, then get next.
    bne sct_loop

sct_nofilter
    jsr OSWRCH

    iny
    lda NAME,y                  ; get next char of filename
    bne sct_nofilter

    jsr OSCRLF

sct_pause
    bit $b002                   ; stick here while REPT/shift/ctrl pressed
    bvc sct_pause
    lda $b001
    rol a                       ; shift/rept pressed?
    bcc sct_pause
    rol a
    bcc sct_pause
    rol a                       ; esc pressed?
    bcs sct_loop

    jmp OSCRLF
