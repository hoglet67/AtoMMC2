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
star_info:
   lda   #0                     ; load address is not set
   sta   LEXEC

   jsr   read_filename          ; copy filename from $100 to $140

   lda   #CMD_FILE_OPEN_READ
   jsr   open_file              ; open the filename for reading

   cmp   #STATUS_COMPLETE+1     ; check for an error
   bcs   directory_cat_info     ; if so, then assume the second for of *INFO

   ldx   #0                     ; attribute byte for a normal file
   ldy   #0                     ; filename starts at offset 0 in the buffer

   ; fall through into read_file_info
        
; read an open file's ATM header and print's the appropriate info
;
; On entry:
;     X: file attribue byte (bit 4 used to determine file / directory)
;     Y: start position of the filename in the buffer
; LEXEC: $00 for *INFO, $ff for *CAT
;
read_file_info:

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
   rts

@newline:
   jmp   OSCRLF
