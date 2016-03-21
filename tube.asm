;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
; Tube Handling

L0406          = $3006          ; Tube claim/transfer/release (in AtomTube host code)
L0409          = $3009          ; Tube error                  (in AtomTube host code)

TUBE_CTRL      =   $60          ; Tube control block address
TUBE_FLAG      =  $3CF          ; Tube enabled flag, set by atom tube host
TUBE_ENABLED   =   $5A          ; Tube enable magic value
TUBE_CLIENT_ID =   $DD          ; Client ID for AtoMMC2 used in tube protocol

TUBE_R3        = $BEE5          ; Tube data transfer FIFO 

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
; tube_claim_wrapper
;
; Check if tube enabled, and if so claim and setup data transfer
; X = where to read transfer address, in zero page
; Y = transfer type
;     00 = parasite to host (i.e. save)
;     01 = host to parasite (i.e. load)
;
tube_claim_wrapper:

   ; Check if the Tube has been enabled
   lda   TUBE_FLAG
   cmp   #TUBE_ENABLED
   bne   tube_disabled

   ; Claim Tube
   lda   #TUBE_CLIENT_ID
   jsr   L0406

   ; Setup Data Transfer
   lda   0, X
   sta   TUBE_CTRL
   lda   1, X
   sta   TUBE_CTRL + 1
   lda   #$00
   sta   TUBE_CTRL + 2
   sta   TUBE_CTRL + 3
   tya
   ldx   #<TUBE_CTRL
   ldy   #>TUBE_CTRL
   jmp   L0406

tube_release_wrapper:
   ; Check if the Tube has been enabled
   lda   TUBE_FLAG
   cmp   #TUBE_ENABLED
   bne   tube_disabled

   ; Release Tube
   lda   #TUBE_CLIENT_ID - $40
   jmp   L0406

tube_disabled:
   rts  

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read a block of data from file to the Tube
;
; a = number of bytes to read (0 = 256)
;
tube_read_block:
   ldx   TUBE_FLAG
   cpx   #TUBE_ENABLED
   beq   @tube_enabled
   jmp   read_block             ; Fall back to old code if tube is disabled

@tube_enabled:
   jsr   read_block_shared
@loop:
   jsr    read_data_reg         ; then read it
   sta    TUBE_R3               ; write to the tube data transfer register
   dex  
   bne    @loop
   rts  

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; write a block of data from the Tube to a file
;
; a = block length (0=256)
;
tube_write_block:
   ldx   TUBE_FLAG
   cpx   #TUBE_ENABLED
   beq   @tube_enabled
   jmp   write_block            ; Fall back to old code if tube is disabled

@tube_enabled:
   tax                          ; save away the block size
   pha  
   jsr   prepare_write_data     ; take it
@loop:
   lda   TUBE_R3                ; read data from the tube data transfer register
   jsr   write_data_reg
   dex  
   bne   @loop
   jmp   write_block_shared
