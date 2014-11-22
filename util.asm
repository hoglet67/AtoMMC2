



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Short delay
;
; Enough to intersperse 2 writes to the FATPIC.
;
interwritedelay
    lda #4
    sec

iwd_loop
    sbc #1
    bne iwd_loop
    rts






;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read an asciiz string to name buffer at $140
;
; on exit y = character count not including terminating 0
;
getasciizstringto140
    PREPGETFRB406

    ldy #$ff

gas_loop    
    iny
    lda $b406
    sta NAME,y
    bne gas_loop

    rts






;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read data to memory from the pic's buffer
;
; data may be from another source other than file, ie getfileinfo
; x = number of bytes to read (0 = 256)
; (RWPTR) points to store
;
read_data_buffer
    PREPGETFRB406

    ldy #0

rdr_loop
    lda $b406
    sta (RWPTR),y
    iny
    dex
    bne rdr_loop

    rts







;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Perform slow command initialisation and expect a 63 return code.
;
expect63
    cmp #63
    bne reportDiskFailure
    rts


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Perform slow command initialisation and expect a return code <= 64
;
expect64orless
    cmp #65
    bcs reportDiskFailure
    rts







;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; report a file system error
;
reportDiskFailure
    and #$3f
    tax                     ; error code into x
    ldy #$ff                ; string indexer

repf_findstring
    iny                     ; do this here because we need the z flag below
    lda diskerrortab,y
    cmp #$0d
    bne repf_findstring       ; zip along the string till we find a zero

    dex                     ; when this bottoms we've found our error
    bne repf_findstring

    iny                     ; store index for basic BRK-alike hander
    tya
    clc
    adc #<diskerrortab
    sta $d5
    lda #>diskerrortab
    adc #0
    sta $d6

    ; fall into ...



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Error printer
;
; Enter with $d5,6 -> Error string.
;
reportFailure
    lda #<errorhandler
    sta $5
    lda #>errorhandler
    sta $6
    jmp $c2f2






;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Display the filename at $140
;
;   renders 16 chars, pads with spaces
;
print_filename
   ldx #0
   beq pf_test

pf_showit
   jsr OSWRCH
   inx

pf_test
   lda NAME,x
   cmp #32              ; end string print if we find char < 32
   bcc pf_test2

   cpx #16              ; or x == 16
   bne pf_showit

   rts
   
pf_showit2
   lda #32
   jsr OSWRCH
   inx

pf_test2
   cpx #16
   bne pf_showit2

   rts







;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Display file info
;
; Shows load, exec, length
;
print_fileinfo
   lda LLOAD+1
   jsr HEXOUT
   lda LLOAD
   jsr HEXOUTS

   lda LEXEC+1
   jsr HEXOUT
   lda LEXEC
   jsr HEXOUTS

   lda LLENGTH+1
   jsr HEXOUT
   lda LLENGTH
   jmp HEXOUTS







;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read filename from $100 to $140
;
; Input  $9A = pointer just after command
;
; Output $140 contains filename
;
read_filename
    ldx #0
    ldy $9a

read_filename1
    jsr SKIPSPC
    cmp #$22
    beq read_filename5

read_filename2
    cmp #$0d
    beq read_filename3

    sta NAME,x
    inx
    iny
    lda $100,y
    cmp #$20
    bne read_filename2

read_filename3
    lda #$0d
    sta NAME,x

    cpx #0
    beq read_filename6

    rts

read_filename5
    iny
    lda $100,y
    cmp #$0d
    beq read_filename6

    sta NAME,x
    inx
    cmp #$22
    bne read_filename5

    dex
    iny
    lda $100,y
    cmp #$22
    bne read_filename3

    inx
    bcs read_filename5

read_filename6
    jmp COSSYN










;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; getnexthexval
;
; parse a 1 or 2 digit hex value from $100,y leaving result in A and $cb. 
; C set if error
;
getnexthexval
    jsr $f876       ; get next non-space char from input buffer
    jsr $f87e       ; convert to hex nybble
    bcs gnhv_error

    sta $cb

    iny
    lda $100,y

    jsr $f87e       ; convert to hex nybble
    bcs gnhv_nomore

    iny
    asl $cb
    asl $cb
    asl $cb
    asl $cb
    ora $cb
    sta $cb

gnhv_nomore
    lda $cb
    clc

gnhv_error
    rts





;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; more
;
; prompt for a key, return it in A
;
more
   jsr STROUT
   .byte "<PRESS A KEY>"
   nop
   jsr OSRDCH
   pha

   lda #0                  ; cheesy x-pos reset
   sta $e0
   jsr STROUT
   .byte "             "
   nop
   lda #0
   sta $e0

   pla
   rts





;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; tab_space
;
; tabs across until horizontal cursor pos is = to val in x
;
tab_loop
   lda #$20
   jsr OSWRCH

tab_space
   cpx $e0
   bcs tab_loop
   rts

tab_space10
   ldx #10
   jmp tab_space

tab_space16
   ldx #16
   jmp tab_space

