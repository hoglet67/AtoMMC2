;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CAT  ([directory path]/)... ([wildcard pattern])
;
; Produce a directory listing of the specified directory, optionally
; displaying only those entries matching a wildcard pattern.
;
; The directory path is optional, if omitted the current directory is used.
;
; The wildcard pattern is optional, if omitted * is used.
;
; 2011-05-29, Now uses CMD_REG -- PHS
; 2012-05-21, converted to use macros for all writes to PIC
; 2016-03-21, removed old @[filter] code, as the PIC supports proper wildcards -- DMB
; 2016-03-22, *CAT code also used for *INFO, giving *INFO multi file / wildcard support
; 2016-03-23, Reworked *CAT and *INFO so code is more readable

MODE = SEND                     ; MODE is $00 for *INFO, $ff for *CAT
TMPY = SEND + 1                 ; place to save/restore Y (the file name offset in $140)

star_cat:

   jsr   read_optional_filename ; do we have a filter/path?

   ldy   #$ff                   ; force *CAT mode

directory_cat_info:
   sty   MODE

   jsr   send_name              ; put string at $140 to interface

   lda   #CMD_DIR_OPEN          ; open directory
   jsr   slow_cmd_and_check     ; invokes error handler if return code > 64

   jsr   find_directory_sep     ; parse the wildcard pattern
   sty   TMPY                   ; y contains the offset to the end of the directory in $140

get_next_loop:
   lda   #CMD_DIR_READ          ; get directory item
   jsr   slow_cmd_and_check     ; invokes error handler if return code > 64

   cmp   #STATUS_COMPLETE       ; all done?
   beq   return

   ldy   TMPY                   ; TMPY contains the offset to the end of the directory in $140
   jsr   getasciizstringto140   ; append the filename to the directory
   ldy   TMPY                   ; TMPY contains the offset to the start of the filenamne

   jsr   read_data_reg          ; get the file's attribute byte: bit 4 = dir/file, bit 1 = hidden
   ror   a
   ror   a                      ; now bit 2 = dir/file; carry = hidden,
   bcs   @pause                 ; hidden?, don't print anything
   ora   MODE                   ; MODE is $00 for *INFO, $ff for *CAT
   and   #$04                   ; dir?
   beq   @info_mode             ; skip info if *CAT or current item is a directory

@cat_mode:
   jsr   print_filename         ; print just the filename without opening the file
   jsr   OSCRLF                 ; followed by a newline
   bne   @pause                 ; branch always

@info_mode:
   jsr   open_file_read         ; open the file for reading
   jsr   print_filename_and_info; read the ATM header, and print full file info

@pause:
   bit   $b002                  ; test the rept key
   bvc   @pause                 ; stick here if rept pressed

   lda   #$20                   ; bit 5 is the mask for the escape key
   bit   $b001                  ; test the ctrl/shift/esc keys
   bpl   @pause                 ; stick here if shift pressed
   bvc   @pause                 ; stick here if ctrl pressed
   bne   get_next_loop          ; loop back if escape not pressed

return:
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
