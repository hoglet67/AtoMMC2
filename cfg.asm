;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *PBD ([val])
;
; *PBD      - Print the current port B direction register in hex.
; *PBD 7F   - Set the direction register.
;
; Port B is 8 bits wide and each bit's direction is independently controllable.
; A set bit in the direction register indicates an 1nput and a clear bit represents
; an 0utput.
;
STARPBD:
   lda   #$a0
   sta   $ce
   jmp   do_cfg_cmd


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *PBV ([val])
;
; *PBV      - Print the state of port B in hex.
; *PBV 7F   - Write value to port B.
;
; If a port B bit is set as an input, you will read the value present on the port.
; If it is an output you will see the last value written to it.
;
STARPBV:
   lda   #$a2
   sta   $ce
   jmp   do_cfg_cmd



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CFG ([val])
;
; *CFG      - Print the current port B direction register in hex.
; *CFG NN   - Set the config byte to the specified hex value.
;
; Bit 7 controls whether the boot loader is entered. 1 = enter, 0 = don't enter.
;     6 controls the action of the SHIFT key on boot. 1 = SHIFT+BREAK runs menu, 0 = menu runs unless SHIFT-BREAK pressed.
;     5 controls whether the interface generates an IRQ on reset. 1 = generate, 0 = don't.
;
STARCFG:
   lda   #$f0
   sta   $ce

   ; fall into ...

do_cfg_cmd:
   ldx   #$cb             ; scan parameter - print existing val if none
   jsr   RDOPTAD
   bne   @param1valid

   lda   $ce              ; read config register
   sta   $b40f
   jsr   interwritedelay
   lda   $b40f
   jsr   HEXOUT
   jmp   OSCRLF

@param1valid:
   lda   $cb
   sta   $b40e            ; latch the value
   jsr   interwritedelay
   ldx   $ce              ; jeff the value into the appropriate register
   inx
   stx   $b40f
   rts
