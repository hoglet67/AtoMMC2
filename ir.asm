;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *IR [data source address]
;
STARIR
    ldx #ZPTW               ; 0,x = target
    jsr RDADDR              ; grab hex val

ir_ok
    ldx #routine_end-routine+1

ir_loop
    lda routine,x           ; copy writer routine to RAM
    sta $2800,x
    dex
    bpl ir_loop

    jmp $2800


routine
    jsr STROUT
    .byte $0d,$0a
    .byte "ENABLE RAM,"
    .byte " PRESS KEY"
    nop

rt_waiter
    jsr $ffe3               ; check for ram being enabled.
    lda $a000
    tax
    inx
    stx $a000
    cmp $a000
    beq routine

    jsr OSCRLF

    lda #$a0
    sta RWPTR+1

    ldy #0
    sty RWPTR

    ldx #15                 ; 16 blocks

rt_filler
    lda (ZPTW),y
    sta (RWPTR),y
    iny
    bne rt_filler

    lda #46                   ;'.'
    jsr OSWRCH

    inc ZPTW+1
    inc RWPTR+1
    dex
    bpl rt_filler

    jmp $FF3F               ; reset

routine_end
