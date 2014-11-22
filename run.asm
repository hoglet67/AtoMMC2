;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *[arbitrary name]
;
;  Try to execute the program with the arbitrary name
;
STARARBITRARY
   ldy #0                  ; copy filename up to NAME buffer

sarb_copyname
   lda $100,y
   sta NAME,y
   iny
   cmp #$0d
   bne sarb_copyname

   jmp runname



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *RUN <filename>
;
STARRUN
    jsr read_filename       ; copy filename into $140

runname
   lda MONFLAG
   pha
   lda #$ff
   sta MONFLAG
   jsr $f844               ; set $c9\a = $140, set x = $c9
   jsr $f95b
   pla
   sta MONFLAG

   lda LEXEC               ; if this is a non-auto-running basic program
   cmp #$b2
   bne rn_go
   lda LEXEC+1
   cmp #$c2
   bne rn_go

   lda #$f2                ; then execute it with a 'run' command
   sta LEXEC
   lda #$c2
   sta LEXEC+1
   lda #<runcmd
   sta $5
   lda #>runcmd
   sta $6

rn_go
   jmp (LEXEC)

runcmd
   .byte "RUN",$0d
