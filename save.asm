;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *SAVE
;
; Parses filename then resumes execution of the BIOS' save routine.
;
star_save:
   jsr   read_filename          ; copy filename into $140
   jsr   $f844                  ; set $c9\a = $140, set x = $c9
   jmp   $fabe                  ; scan parameters and jmp through SAVVEC

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; SAVVEC
;
; 0,x = file parameter block
;
; 0,x = file name string address
; 2,x = data reload address
; 4,x = data execution address
; 6,x = data start address
; 8,x = data end address + 1
;

ossavecode:
   jsr   copy_name              ; copy data block at $00,x to COS workspace at $c9
                                ; also checks filename is < 14 chars, PIC additionally checks < 8 chars
                                ; copy filename from ($c9) to $140

@retry_write:
   jsr   open_file_write        ; returns with any error in A

   cmp   #$48                   ; test for FILE EXISTS
   bne   @continue              ; no, then skip forwards

   jsr   STROUT                 ; prompt to the file
   .byte "OVERWRITE (Y):"
   nop
   jsr   confirm_or_rts         ; pops an extra address off the stack if Y not presed
   jsr   delete_file
   jmp   @retry_write

@continue:

   jsr   expect64orless         ; other kind of error

   ; @@TUBE@@
   ; Test if the tube is enabled, then claim and initiate transfer
   ldx   #SSTART                ; block containing transfer address
   ldy   #0                     ; transfer type
   jsr   tube_claim_wrapper

   lda   SLOAD                  ; tag the file info onto the end of the filename data
   sta   $150
   lda   SLOAD+1
   sta   $151
   lda   SEXEC
   sta   $152
   lda   SEXEC+1
   sta   $153
   sec
   lda   SEND
   sbc   SSTART
   sta   $154
   lda   SEND+1
   sbc   SSTART+1
   sta   $155

   ldx   #$ff                   ; zero out any data after the name at $140

@mungename:
   inx
   lda   NAME,x
   cmp   #$0d
   bne   @mungename

   lda   #0

@munge2:
   sta   NAME,x
   inx
   cpx   #16
   bne   @munge2

   jsr   write_info             ; write the ATM header

   jsr   write_file             ; save the main body of data

   ; @@TUBE@@
   ; Test if the tube is enabled, then release
   jsr   tube_release_wrapper

   ; Don't need to call CLOSE_FILE here as write_file calls it.
   ; CLOSE_FILE

   bit   MONFLAG                ; 0 = mon, ff = nomon
   bmi   @noprint

   ldx   #5

@cpydata:
   lda   $150,x
   sta   LLOAD,x
   dex
   bpl   @cpydata

   jmp   print_fileinfo

@noprint:
   rts
