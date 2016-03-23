;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CAT ([wildcard pattern])
;
; Produce a directory listing of the files in the current working directory, optionally
; displaying only those entries matching a wildcard pattern.
;
; 2011-05-29, Now uses CMD_REG -- PHS
; 2012-05-21, converted to use macros for all writes to PIC
; 2016-03-21, removed old @[filter] code, as the PIC supports proper wildcards -- DMB
; 2015-03-22, *CAT code also used for *INFO, giving *INFO multi file / wildcard support

star_cat:

   lda   #$ff                   ; never show full info
   sta   LEXEC

generic_cat_info:

   jsr   read_optional_filename ; do we have a filter/path?

   jsr   send_name              ; put string at $140 to interface

   lda   #CMD_DIR_OPEN          ; open directory
   jsr   slow_cmd_and_check     ; invokes error handler if return code > 64

   jsr   find_directory_sep     ; parse the wildcard pattern
   sty   SEND                   ; y indicates the end of the directory part

get_next_loop:
   lda   #CMD_DIR_READ          ; get directory item
   jsr   slow_cmd_and_check     ; invokes error handler if return code > 64

   cmp   #STATUS_COMPLETE       ; all done
   beq   @return

   ldy   SEND                   ; append filename to the directory
   jsr   getasciizstringto140   ; starts at $140+y

   jsr   read_data_reg          ; get attribute byte

   tax                          ; save the attribue byte
   and   #$02                   ; hidden?
   bne   @pause                 ; yes, don't print anything

   ldy   SEND                   ; print the file name returned by the PIC
@nameloop:
   lda   NAME,y                 ; get next char of filename
   cmp   #$0d
   beq   @nameend
   jsr   OSWRCH
   iny
   bne   @nameloop

@nameend:
   txa                          ; restore the file's attribute byte
   ora   LEXEC                  ; $00 for *INFO, $ff for *CAT,
   and   #$10                   ; dir?
   bne   @newline               ; skip info if *CAT or current item is a directory

@padloop:
   jsr   SPCOUT                 ; pad filename with spaces
   lda   $e0                    ; $e0 = horizontal cursor position
   cmp   #16                    ; continue until column 16
   bcc   @padloop

   jsr   open_file_read         ; send the file name and prepare for reading

   lda   #22                    ; ATM header size
   jsr   read_block_shared

   ldy   #$ff - 16
@headerloop:
   jsr   read_data_reg          ; read next ATM header byte
   iny
   bmi   @headerloop            ; skip bytes 1..16 (ATM header file name)
   sta   LLOAD, y               ; save bytes 17..22 (ATM header load, exec, length)
   cpy   #5
   bne   @headerloop

   jsr   print_fileinfo         ; print info from LLOAD followed by newline

   lda   #$00                   ; reset the cat/info flag back to info
   sta   LEXEC                  ; as it's corrupted just above
   beq   @pause                 ; skip the newline as print_fileinfo includes one

@newline:
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


; Find the position of the directory seperator
;
; - search forward for a wild card
; - if not found, append extra / and return Y = next char
; - search backwards for a /
; - if found, return Y = next char
; - return Y = 0

find_directory_sep:
    ldy   #$ff

@wild_loop:
    iny
    lda   NAME, y
    cmp   #'?'
    beq   @slash_loop
    cmp   #'*'
    beq   @slash_loop
    cmp   #$0D
    bne   @wild_loop
    cpy   #$00                  ; handle the case where no wildcard is present
    beq   @exit
    lda   #'/'
    sta   NAME, y
    iny
@exit:
    rts

@slash_loop:
    lda   NAME, y
    cmp   #'/'
    beq   @found_slash
    dey
    bpl   @slash_loop

@found_slash:
    iny
    rts
