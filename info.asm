;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *INFO  ([directory path]/)... ([file path])
; or
; *INFO  ([directory path]/)... ([wildcard pattern])
;
; Shows metatadata associated with one or more files.
;
; If the path resolved to a single file, then info for just this file is displayed.
;
; Otherwise the path is assumed to identify a directory and a wildcard pattern
; filters the files in this directory.
;
; The directory path is optional, if omitted the current directory is used.
;
; The wildcard pattern is optional, if omitted * is used.
;
; 2016-03-22, *CAT code also used for *INFO, giving *INFO multi file / wildcard support
; 2016-03-23, Added back support for *INFO on a single file
; 2016-03-23, Reworked *CAT and *INFO so code is more readable
;
star_info:
   jsr   read_optional_filename ; copy filename from $100 to $140

   lda   #CMD_FILE_OPEN_READ
   jsr   open_file              ; open the filename for reading

   ldy   #0                     ; filename starts at offset 0 in the buffer

   cmp   #STATUS_COMPLETE+1     ; check for an error, and if so assume directory mode
   bcs   directory_cat_info     ; y=0 forces *INFO mode
   ; fall through into print_filename_and_info with y=0

; read an open file's ATM header and print's the appropriate info
;
; On entry:
;     Y: start position of the filename in the buffer
;
print_filename_and_info:
   jsr   print_filename

@padloop:
   jsr   SPCOUT                 ; pad filename with spaces
   lda   $e0                    ; $e0 = horizontal cursor position
   cmp   #16                    ; continue until column 16
   bcc   @padloop

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
   ; fall through into print_fileinfo

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Display file info
;
; Prints load, exec, length
;
print_fileinfo:
   ldx   #LLOAD
   jsr   HEXOUT4                ; $f7ee print 4 bytes in hex, incrementing X
   jsr   HEXOUT2                ; $f7f1 print 2 bytes in hex, incrementing X
   jmp   OSCRLF

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Display file name
;
; Prints name
;
print_filename:
   lda   NAME,y                 ; get next char of filename
   cmp   #$0d
   beq   return                 ; save a byte by using an RTS in *CAT
   jsr   OSWRCH
   iny
   bne   print_filename
