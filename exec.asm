;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *EXEC
;
; install a keyboard hook and feed bytes from a file to the system as if
; they were typed.
;
STAREXEC
   jsr read_filename ; open the supplied filename
   jsr open_file

   SETRWPTR NAME     ; get the FAT file size - text files won't have ATM headers

   lda #128
   SLOWCMD $b403

   ldx #13
   jsr read_data_buffer 

   lda NAME
   sta RDCLEN
   lda NAME+1
   sta RDCLEN+1

   lda #0         ; indicate there are no bytes in the pipe
   sta RDCCNT

   lda #<execrdch     ; point OSRDCH at our routine
   sta RDCVEC
   lda #>execrdch
   sta RDCVEC+1
   rts


;
; pull characters from the file and return these to the OS
; until none left at which point unhook ourselves
;
; ---== no X or Y reg used ) ==---
;
execrdch
   php
   cld

ewc_sinkchar
   lda RDCCNT         ; exhausted our little pool?
   bne ewc_plentyleft

   lda RDCLEN+1       ; are there pages left in the file?
   bne ewc_nextread16

   lda RDCLEN         ; less than 16 left in the file?
   cmp #17
   bcc ewc_fillpool

ewc_nextread16
   lda #16           ; 16 or more left in the file

ewc_fillpool
   sta RDCCNT         ; pool count

   lda RDCLEN         ; file length remaining -= pool count
   sec
   sbc RDCCNT
   sta RDCLEN
   bcs ewc_refillpool

   dec RDCLEN+1

ewc_refillpool
   lda RDCCNT         ; recover count
   SLOWCMD $b404
   cmp #63          ; error - bail
   beq ewc_allok

   jmp osr_unhook    ; eek

ewc_allok
   PREPGETFRB406         ; get data from pic

ewc_plentyleft
   dec RDCCNT         ; one less in the pool
   bne ewc_finally


   lda RDCLEN        ; all done completely?
   ora RDCLEN+1
   bne ewc_finally


   lda #$94          ; unhook and avoid trailing 'A' gotcha
   sta RDCVEC
   lda #$fe
   sta RDCVEC+1

   lda $b406         ; get char from PIC
   plp
   rts


ewc_finally
   lda $b406         ; get char from PIC

   cmp #$0a            ; lose LFs - god this is so ghetto i can't believe i've done it
   beq ewc_sinkchar     ; this will fubar if the last char in a file is A. which is likely. BEWARE!

   plp
   rts
