



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Short delay
;
; Enough to intersperse 2 writes to the FATPIC.
;
interwritedelay:
   lda  #4
   sec

@loop:
   sbc  #1
   bne  @loop
   rts

; subroutines for macros in macro.inc

SLOWCMD_DELAY:
	lda #0
	sec 
SLOWCMD_DELAY_LOOP:
	sbc #1
	bne SLOWCMD_DELAY_LOOP
	rts

PREPGETFRB406_SUB:
   lda #CMD_INIT_READ
   writeportFAST ACMD_REG				
   jmp interwritedelay

PREPPUTTOB407_SUB: 
   lda #CMD_INIT_WRITE
   writeportFAST ACMD_REG 			
   jmp interwritedelay
  
OPEN_READ_SUB:
   lda #CMD_FILE_OPEN_READ
   jsr open_file
   jmp expect64orless
	

DELETE_FILE_SUB:
   lda   #CMD_FILE_DELETE
   SLOWCMD ACMD_REG			
   jmp   expect64orless



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read an asciiz string to name buffer at $140
;
; on exit y = character count not including terminating 0
;
getasciizstringto140:
   PREPGETFRB406

   ldy  #$ff

@loop:
   iny
   lda  AREAD_DATA_REG	; $b406
   sta  NAME,y
   bne  @loop

   rts






;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read data to memory from the pic's buffer
;
; data may be from another source other than file, ie getfileinfo
; x = number of bytes to read (0 = 256)
; (RWPTR) points to store
;
read_data_buffer:
   PREPGETFRB406

   ldy  #0

@loop:
   lda  AREAD_DATA_REG	; $b406
   sta  (RWPTR),y
   iny
   dex
   bne @loop

   rts







;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Perform slow command initialisation and expect a return code <= 64
;
expect64orless:
   cmp  #STATUS_COMPLETE+1
   bcs  reportDiskFailure
   rts







;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Disable/Enable interface IRQ
;
ifdi:
   jsr   getcb
   and   #$DF              ; remove bit 6
   jmp   putcb   

ifen:
   jsr   getcb
   ora   #$20              ; set bit 6
   jmp   putcb   




getcb:
   lda   			#CMD_GET_CFG_BYTE      ; retreive config byte
   writeportFAST   	ACMD_REG	
   jsr   			interwritedelay
   lda   			ACMD_REG	
   rts

   
putcb:
   writeportFAST	ALATCH_REG		; $b40e  ; latch the value
   jsr   			interwritedelay

   lda   			#CMD_SET_CFG_BYTE      ; write latched val as config byte. irqs are now off
   writeportFAST	ACMD_REG	
   rts




;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; report a file system error
;
reportDiskFailure:
   and   #ERROR_MASK
   tax                     ; error code into x
   ldy   #$ff                ; string indexer

@findstring:
   iny                     ; do this here because we need the z flag below
   lda   diskerrortab,y
   cmp   #$0d
   bne   @findstring       ; zip along the string till we find a zero

   dex                     ; when this bottoms we've found our error
   bne   @findstring

   iny                     ; store index for basic BRK-alike hander
   tya
   clc
   adc   #<diskerrortab
   sta   $d5
   lda   #>diskerrortab
   adc   #0
   sta   $d6

   ; fall into ...


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Error printer
;
; Enter with $d5,6 -> Error string.
;
reportFailure:
   lda   #<errorhandler
   sta   $5
   lda   #>errorhandler
   sta   $6
   jmp   $c2f2






;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Display the filename at $140
;
;   renders 16 chars, pads with spaces
;
print_filename:
   ldx   #0
   beq   @test

@showit:
   jsr   OSWRCH
   inx

@test:
   lda   NAME,x
   cmp   #32              ; end string print if we find char < 32
   bcc   @test2

   cpx   #16              ; or x == 16
   bne   @showit

   rts

@showit2:
   lda   #32
   jsr   OSWRCH
   inx

@test2:
   cpx   #16
   bne   @showit2

   rts







;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Display file info
;
; Shows load, exec, length
;
print_fileinfo:
   lda   LLOAD+1
   jsr   HEXOUT
   lda   LLOAD
   jsr   HEXOUTS

   lda   LEXEC+1
   jsr   HEXOUT
   lda   LEXEC
   jsr   HEXOUTS

   lda   LLENGTH+1
   jsr   HEXOUT
   lda   LLENGTH
   jmp   HEXOUTS







;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read filename from $100 to $140
;
; Input  $9A = pointer just after command
;
; Output $140 contains filename
;
read_filename:
   ldx   #0
   ldy   $9a

@filename1:
   jsr   SKIPSPC
   cmp   #$22
   beq   @filename5

@filename2:
   cmp   #$0d
   beq   @filename3

   sta   NAME,x
   inx
   iny
   lda   $100,y
   cmp   #$20
   bne   @filename2

@filename3:
   lda   #$0d
   sta   NAME,x

   cpx   #0
   beq   @filename6

   rts

@filename5:
   iny
   lda   $100,y
   cmp   #$0d
   beq   @filename6

   sta   NAME,x
   inx
   cmp   #$22
   bne   @filename5

   dex
   iny
   lda   $100,y
   cmp   #$22
   bne   @filename3

   inx
   bcs   @filename5

@filename6:
   jmp   COSSYN










;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; getnexthexval
;
; parse a 1 or 2 digit hex value from $100,y leaving result in A and $cb. 
; C set if error
;
getnexthexval:
   jsr   $f876       ; get next non-space char from input buffer
   jsr   $f87e       ; convert to hex nybble
   bcs   @error

   sta   $cb

   iny
   lda   $100,y

   jsr   $f87e       ; convert to hex nybble
   bcs   @nomore

   iny
   asl   $cb
   asl   $cb
   asl   $cb
   asl   $cb
   ora   $cb
   sta   $cb

@nomore:
   lda   $cb
   clc

@error:
   rts





;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; more
;
; prompt for a key, return it in A
;
more:
   jsr   STROUT
   .byte "<PRESS A KEY>"
   nop
   jsr   OSRDCH
   pha

   lda   #0                  ; cheesy x-pos reset
   sta   $e0
   jsr   STROUT
   .byte "             "
   nop
   lda   #0
   sta   $e0

   pla
   rts





;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; tab_space
;
; tabs across until horizontal cursor pos is = to val in x
;
tab_loop:
   lda   #$20
   jsr   OSWRCH

tab_space:
   cpx   $e0
   bcs   tab_loop
   rts

tab_space10:
   ldx   #10
   jmp   tab_space

tab_space16:
   ldx   #16
   jmp   tab_space
