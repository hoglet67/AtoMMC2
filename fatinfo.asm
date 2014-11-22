
;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *FATINFO [filename]
;
; Shows fat filesystem file info - size on disk, sector, fptr and attrib.
;
STARFATINFO:
    jsr  read_filename
    jsr  open_file

    SETRWPTR NAME          ; get the FAT file size - text files won't have ATM headers

    lda  #128
    SLOWCMD $b403

    ldx  #13
    jsr  read_data_buffer 

    bit  MONFLAG             ; 0 = mon, ff = nomon
    bpl  @printit

    ; maybe caller just wants the info in the buffer

    rts

@printit:
    ldx  #3
    jsr  hexdword
    ldx  #7
    jsr  hexdword
    ldx  #11
    jsr  hexdword
    lda  NAME+12
    jsr  HEXOUT
    jmp  OSCRLF


hexdword:
    lda  NAME,x
    jsr  HEXOUT
    dex
    lda  NAME,x
    jsr  HEXOUT
    dex
    lda  NAME,x
    jsr  HEXOUT
    dex
    lda  NAME,x
    jmp  HEXOUTS
