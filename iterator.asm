;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Directory iterator pattern
;
; Used by *CAT, *INFO and *DELETE, e.g.
;
; *INFO  ([directory path]/)... ([file path])
; or
; *INFO  ([directory path]/)... ([wildcard pattern])
;
; The directory iterator calls back to the caller's handler for each matching child
;
; The handler code is expected to immediately follow the "jsr iterator"
;
; On Entry to the handler:
;     $140 contains the full path to the child
;     Y is the offset in the $140 buffer to the child name
;     C=0 if the child is a file, C=1 if the child is a directory

iterator:
   pla                          ; save the caller's handler function, which is
   sta   HANDLER+1              ; the code the immediately follows "jsr iterator"
   pla
   sta   HANDLER

   jsr   read_optional_filename ; read the command's argument

   lda   #CMD_FILE_OPEN_READ    ; open it as if it were a file for reading
   jsr   open_file              ; in FatFS this can be done multiple times without a problem

   cmp   #STATUS_COMPLETE+1     ; check for an error opening the file for read
   bcs   @directory_mode        ; if so, assume directory mode

   ldy   #0                     ; filename starts at offset 0 in $140
   ; fall through to invoke the handler on an individual file (C = 0 at this point)

@child_handler:
   lda   HANDLER
   pha
   lda   HANDLER+1
   pha
   rts                          ; call the command's handler

@directory_mode:
   jsr   send_name              ; send string at $140 to the AtoMMC interface

   lda   #CMD_DIR_OPEN          ; open directory
   jsr   slow_cmd_and_check     ; invokes error handler if return code > 64

   jsr   @find_directory_sep    ; parse the wildcard pattern in $140 to find the last directory seperator
   sty   TMPY                   ; save y, which is the offset at which the child name will be written

@get_next_loop:
   lda   #CMD_DIR_READ          ; get directory item
   jsr   slow_cmd_and_check     ; invokes error handler if return code > 64

   cmp   #STATUS_COMPLETE       ; all done?
   beq   @return

   ldy   TMPY                   ; save y, which is the offset at which the child name will be written
   jsr   getasciizstringto140   ; append the child's name to the path

   jsr   read_data_reg          ; read the child's attribute byte: bit 4 = dir/file, bit 1 = hidden
   ror   a
   ror   a                      ; now bit 2 = dir/file; carry = hidden,
   bcs   @pause                 ; hidden?, don't invoke the handler

   and   #$04                   ; mask dir/file bit
   cmp   #$04                   ; C=0 for file; C=1 for directory
   ldy   TMPY                   ; restore y, the offset to the childs's name
   jsr   @child_handler

@pause:
   bit   $b002                  ; test the rept key
   bvc   @pause                 ; stick here if rept pressed

   lda   #$20                   ; bit 5 is the mask for the escape key
   bit   $b001                  ; test the ctrl/shift/esc keys
   bpl   @pause                 ; stick here if shift pressed
   bvc   @pause                 ; stick here if ctrl pressed
   bne   @get_next_loop         ; loop back if escape not pressed
@return:
   rts

; Find the position of the directory seperator
;
; - search forward for a wild card
; - if not found, append extra / and return Y = next char
; - search backwards for a /
; - if found, return Y = next char
; - return Y = 0

@find_directory_sep:
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

return:
    rts                         ; a convenient rts for following code to branch to
