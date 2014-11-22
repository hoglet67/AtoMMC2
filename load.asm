;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; STARLOAD
;
STARLOAD
    jsr read_filename       ; copy filename into $140
    jsr $f844               ; set $c9\a = $140, set x = $c9
    jmp $f95b               ; *LOAD+3



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *RLOAD <file> <addr>
;
; raw load, ignore ATM header if present, use FAT reported file length
;
STARRLOAD
   jsr   read_filename        ; copy filename into $140
   jsr   $f844                ; set $c9\a = $140, set x = $c9

   ldx   #$cb                 ; Point to the vector at #CB, #CC
   jsr   RDOPTAD              ; ..and interpret the load address to store it here
   beq   rlerr                ; ..can't interpret load address - error

   jsr   COSPOST              ; Do COS interpreter post test
   ldx   #$c9                 ; File data starts at #C9

   jsr   CHKNAME
   jsr   open_file

   SETRWPTR NAME              ; get the FAT file size - ignore any ATM headers

   lda   #128
   SLOWCMD $b403

   ldx   #13
   jsr   read_data_buffer 

   lda   NAME                 ; fat file length
   sta   LLENGTH
   lda   NAME+1
   sta   LLENGTH+1

   jmp   read_file

rlerr
   jmp   COSSYN


nomemerr
   REPERROR noramstr
      

noramstr
.byte "NO RAM"

   

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *ROMLOAD
;
; requires RAMROM board
;
;
STARROMLOAD
   lda   #0                   ; select rom bank 0
   sta   $bfff
   
   lda   $bffd                ; map $7000-$7fff to $7000
   and   #$fe
   sta   $bffe

   lda   #$55
   sta   $7000
   cmp   $7000
   bne   nomemerr
   asl   a
   sta   $7000
   cmp   $7000
   bne   nomemerr

   jsr   read_filename        ; copy filename into $140
   jsr   $f844                ; set $c9\a = $140, set x = $c9

   jsr   CHKNAME
   jsr   open_file

   lda   #0
   sta   LLOAD
   sta   LLENGTH

   lda   #$10
   sta   LLENGTH+1
   lda   #$70
   sta   LLOAD+1

   jsr   read_file

   lda   $bffd             ; map $7000 RAMROM ram into $A000
   ora   #1
   sta   $bffe

   rts
   



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; LODVEC entry point
;
; 0,x = file parameter block
;
; 0,x = file name string address
; 2,x = data dump start address
; 4,x  if bit 7 is clear, then the file's own start address is to be used
;
osloadcode
    ; transfer control block to $c9 (LFNPTR) onward and check name
    ;
    jsr CHKNAME

    jsr open_file
    jsr read_info

    bit MONFLAG             ; 0 = mon, ff = nomon
    bmi ol_noprint

    jsr print_fileinfo
    jsr OSCRLF

ol_noprint
    jmp read_file
