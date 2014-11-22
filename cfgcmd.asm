;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *pbd ([val])
;
; get\set port b direction register
;
STARPBD
   lda #$a0
   sta $ce
   jmp do_cfg_cmd


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *pbv ([val])
;
; get/set port b value register
;
STARPBV
   lda #$a2
   sta $ce
   jmp do_cfg_cmd



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CFG ([val])
;
; get\set interface configuration byte
;
STARCFG
   lda #$f0
   sta $ce

   ; fall into ...

do_cfg_cmd
   ldx #$cb             ; scan parameter - print existing val if none
   jsr RDOPTAD
   bne dcc_param1valid

   lda $ce              ; read config register
   sta $b40f
   jsr interwritedelay
   lda $b40f
   jsr HEXOUT
   jmp OSCRLF

dcc_param1valid
   lda $cb
   sta $b40e            ; latch the value
   jsr interwritedelay
   ldx $ce              ; jeff the value into the appropriate register
   inx
   stx $b40f
   rts
