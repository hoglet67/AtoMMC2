


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Open file
;
; $140 = name
;
open_file
    PREPPUTTOB407

    ldx #0
    beq opn_pumpname

opn_nextchar
    sta $b407
    inx

opn_pumpname
    lda NAME,x              ; write filename to filename buffer
    cmp #$0d
    bne opn_nextchar

    lda #0                  ; terminate the string
    sta $b407
    jsr interwritedelay

    lda #1
    SLOWCMD $b403
    jmp expect63





;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Get 1st 22 bytes of file to $140
;
; leave the LOAD address in RAM alone if LEXEC is FF.
;
read_info
    ; read the file header to $140

    SETRWPTR NAME

    lda #22
    jsr read_block

    ldy #5                  ; index of msb of length
    ldx #3                  ; set up to copy 4 bytes - exec & length

    bit LEXEC               ; if bit 7 is set on entry we don't overwrite
    bmi rin_copyfileinfo    ; the load address

    ldx #5                  ; otherwise copy 6 bytes including load

rin_copyfileinfo
    lda $150,y
    sta LLOAD,y
    dey
    dex
    bpl rin_copyfileinfo

    rts






;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
;  Read file
;
; (LLOAD) = memory target
; LLENGTH = bytes to read
;

rf_read
    lda #0
    jsr rfi_adapter

    inc LLOAD+1
    dec LLENGTH+1

read_file
    lda LLENGTH+1           ; any pages left?
    bne rf_read

    lda LLENGTH             ; any stragglers?
    beq rf_alldone

    jsr rfi_adapter

    lda LLOAD               ; final adjustment to write pointer
    clc
    adc LLENGTH
    sta LLOAD
    bcc rf_zerolen

    inc LLOAD+1

rf_zerolen
    stx LLENGTH             ; zero out the length

rf_alldone
    rts





rfi_adapter
    ; enter with a = bytes to read (0=256)

    pha

    lda LLOAD
    sta RWPTR
    lda LLOAD+1
    sta RWPTR+1

    pla

    ; falls through to


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read data to memory
;
; a = number of bytes to read (0 = 256)
; (RWPTR) points to target
;
read_block
    tax

    SLOWCMD $b404          ; ask PIC for (A) bytes of data (0=256)
    jsr expect63

    PREPGETFRB406           ; tell pic to release the data we just read

    ldy #0

rdt_loop
    lda $b406               ; then read it
    sta (RWPTR),y
    iny
    dex
    bne rdt_loop

    rts






;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; put 1st 22 bytes of data to open file
;
; file needs to be open at this point
;
write_info
   SETRWPTR NAME
    lda #22
    jmp write_block



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Write data to open file
;
; SSTART = address to write from
; SEND   = final address + 1
;
wfi_fullpageloop
    lda #0                  ; 1 page
    jsr wfi_adapter

    inc SSTART+1

write_file
    lda SSTART+1
    cmp SEND+1
    bne wfi_fullpageloop

    lda SEND                ; any stragglers to write?
    cmp SSTART
    beq wfi_closefile

    sec                     ; calc remaining bytes
    sbc SSTART
    jsr wfi_adapter

wfi_closefile
    lda #0                  ; close the file
    SLOWCMD $b402
    jmp expect63


; adapter - falls through to write_block
;
wfi_adapter
    ldy SSTART
    sty RWPTR
    ldy SSTART+1
    sty RWPTR+1

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; write a block of data
;
; a = block length (0=256)
; (RWPTR) = source
;
write_block
    tax                     ; save away the block size
    pha

    PREPPUTTOB407           ; take it

    ldy #0

wbl_loop
    lda (RWPTR),y           ; upload data
    sta $b407
    iny
    dex
    bne wbl_loop

    pla                     ; write block command
    SLOWCMD $b405
    jmp expect63
