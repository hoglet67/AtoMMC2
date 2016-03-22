;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *FATINFO [filename]
;
; Shows fat filesystem file info - size on disk, sector, fptr and attrib.
;
star_fatinfo:
   jsr   open_filename_getinfo  ; opens the filename for reading, and calls getinfo

   bit   MONFLAG                ; 0 = mon, ff = nomon
   bpl   @printit

   ; maybe caller just wants the info in the buffer

   rts

@printit:
   ldx   #3
   jsr   hexdword
   ldx   #7
   jsr   hexdword
   ldx   #11
   jsr   hexdword
   lda   NAME+12
   jsr   HEXOUT
   jmp   OSCRLF


hexdword:
   lda   NAME,x
   jsr   HEXOUT
   dex
   lda   NAME,x
   jsr   HEXOUT
   dex
   lda   NAME,x
   jsr   HEXOUT
   dex
   lda   NAME,x
   jmp   HEXOUTS
