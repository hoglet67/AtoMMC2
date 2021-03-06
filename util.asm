;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
; "Init" commands that are used in several places
; TODO: Check these really don't need any delay / handshaking....

prepare_read_data:
   lda   #CMD_INIT_READ
   bne   write_cmd_reg

prepare_write_data:
   lda   #CMD_INIT_WRITE
   ; fall through to write_cmd_reg

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
; Write command + wait

write_cmd_reg:
   sta   ACMD_REG
.ifdef AVR
   jmp   WaitUntilRead
.else
   jmp   inter_write_delay
.endif

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
; Write latch + wait

write_latch_reg:
   sta   ALATCH_REG
.ifdef AVR
   jmp   WaitUntilRead
.else
   jmp   inter_write_delay
.endif

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
; Write data + wait

write_data_reg:
   sta   AWRITE_DATA_REG
.ifdef AVR
   jmp   WaitUntilRead
.else
   jmp   data_write_delay
.endif

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
; Wait + Read data

read_data_reg:
.ifdef AVR
   jsr   WaitUntilWritten
.else
   jsr   data_read_delay
.endif
   lda   AREAD_DATA_REG
   rts

.ifndef AVR
;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Short delay
;
; Enough to intersperse 2 writes to the FATPIC.
;
inter_write_delay:
   pha
   lda   #16
   bne   write_delay
data_write_delay:
   pha
   lda   #4
write_delay:
   sec
@loop:
   sbc   #1
   bne   @loop
   pla
data_read_delay:
   rts
.endif

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Fast command
; - On the PIC, command port write followed by interwrite delay
; - On the AVR, this is the same as slow_cmd

fast_cmd:
.ifndef AVR
   jsr   write_cmd_reg
   lda   ACMD_REG
   rts
.else
   ; fall through to slow_cmd
.endif


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Fast command, command port write followed by interwrite delay on PIC,
; Simply an alias for "jsr slow_cmd" on AVR.

slow_cmd:
   jsr   write_cmd_reg

.ifndef AVR
slow_cmd_loop:
   lda   #0
   sec
slow_cmd_delay_loop:
   sbc   #1
   bne   slow_cmd_delay_loop

   lda   ACMD_REG
   bmi   slow_cmd_loop       ; loop until command done bit (bit 7) is cleared
   jmp   inter_write_delay   ; seems necessary at 4MHz if slow_cmd immediately
                             ; followed by prepare_read_data (e.g. as in osrdar)
.else
   jsr   WaitWhileBusy       ; Keep waiting until not busy
   lda   ACMD_REG            ; get status for client
   rts
.endif

.ifdef AVR
WaitUntilRead:
   lda   ASTATUS_REG         ; Read status reg
   and   #MMC_MCU_READ       ; Been read yet ?
   bne   WaitUntilRead       ; nope keep waiting
   rts

WaitUntilWritten:
   lda   ASTATUS_REG         ; Read status reg
   and   #MMC_MCU_WROTE      ; Been written yet ?
   beq   WaitUntilWritten    ; nope keep waiting
   rts

WaitWhileBusy:
   lda   ASTATUS_REG         ; Read status reg
   and   #MMC_MCU_BUSY       ; MCU still busy ?
   bne   WaitWhileBusy       ; yes keep waiting
   rts
.endif


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read an asciiz string to name buffer at $140 + y
;
; on exit y = character count not including terminating 0
;
;  bug: this will keep reading until it hits a 0, if there is not one, it will
;      keep going forever......
getasciizstringto140:
   jsr   prepare_read_data

   dey
@loop:
   iny
   jsr   read_data_reg
   sta   NAME,y
   bne   @loop

   lda   #$0d                   ; replace the terminator by <cr>
   sta   NAME,y                 ; so the filename can be reused by the pic
   rts

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Disable/Enable interface IRQ
;
.ifndef EOOO
ifdi:
   jsr   getcb
   and   #$DF                   ; remove bit 5
   jmp   putcb

ifen:
   jsr   getcb
   ora   #$20                   ; set bit 5
   jmp   putcb

getcb:
   lda   #CMD_GET_CFG_BYTE      ; retreive config byte
   jmp   fast_cmd

putcb:
   jsr   write_latch_reg
   lda   #CMD_SET_CFG_BYTE      ; write latched val as config byte. irqs are now off
   jmp   write_cmd_reg
.endif

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; opens a file for reading, then gets the file info
;
; this is used by fatinfo, exec, and rload
open_filename_getinfo:
   jsr   open_filename_read     ; invokes error handler if return code > 64

   jsr   set_rwptr_to_name      ; get the FAT file size - text files won't have ATM headers
   lda   #CMD_FILE_GETINFO
   jsr   slow_cmd

   ldx   #13
   ; jmp   read_data_buffer
   ; fall through to read_data_buffer

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read data to memory from the pic's buffer
;
; data may be from another source other than file, ie getfileinfo
; x = number of bytes to read (0 = 256)
; (RWPTR) points to store
;
read_data_buffer:
   jsr   prepare_read_data

   ldy   #0

@loop:
   jsr   read_data_reg
   sta   (RWPTR),y
   iny
   dex
   bne   @loop

return_ok:
   rts


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; set RWPTR to point to NAME  (i.e. $140)
;
; this is called 5 times, so making it a subroutine rather than a macro
; saves 4 * (8 - 3) - 9 = 11 bytes!
set_rwptr_to_name:
   lda   #<NAME
   sta   RWPTR
   lda   #>NAME
   sta   RWPTR+1
   rts


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Perform slow command initialisation and expect a return code <= 64
;
slow_cmd_and_check:
   jsr   slow_cmd

expect64orless:
   cmp   #STATUS_COMPLETE+1
   bcc   return_ok
   ; fall through to report_disk_failure


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; report a file system error
;
report_disk_failure:
   and   #ERROR_MASK
   pha                          ; save error code
   tax                          ; error code into x
   ldy   #$ff                   ; string indexer

@findstring:
   iny                          ; do this here because we need the z flag below
   lda   diskerrortab,y
   bne   @findstring            ; zip along the string till we find a zero

   dex                          ; when this bottoms we've found our error
   bne   @findstring
   pla                          ; restore error code
   tax                          ; error code in X
   lda   TUBE_FLAG
   cmp   #TUBE_ENABLED
   beq   @tubeError

@printstring:
   iny
   lda   diskerrortab,y
   jsr   OSWRCH
   bne   @printstring
   brk

@tubeError:
   iny                          ; store index for basic BRK-alike hander
   tya
   clc
   adc   #<diskerrortab
   sta   $d5
   lda   #>diskerrortab
   adc   #0
   sta   $d6
   jmp   L0409                  ; error code in X (must be non zero)

diskerrortab:
   .byte $00
   .byte "DISK FAULT",$00
   .byte "INTERNAL ERROR",$00
   .byte "NOT READY",$00
   .byte "NOT FOUND",$00
   .byte "NO PATH",$00
   .byte "INVALID NAME",$00
   .byte "ACCESS DENIED",$00
   .byte "EXISTS",$00
   .byte "INVALID OBJECT",$00
   .byte "WRITE PROTECTED",$00
   .byte "INVALID DRIVE",$00
   .byte "NOT ENABLED",$00
   .byte "NO FILESYSTEM",$00
   .byte $00                    ; mkfs error
   .byte "TIMEOUT",$00
   .byte "EEPROM ERROR",$00
   .byte "FAILED",$00
   .byte "TOO MANY",$00
   .byte "SILLY",$0d

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read filename from $100 to $140
;
; Input  $9A = pointer just after command
;
; Output $140 contains filename, terminated by $0D
;
read_filename:
   jsr   read_optional_filename

   cpx   #0                     ; chec the filename length > 0
   bne   filename_ok

syn_error:
   jmp   COSSYN                 ; generate a SYN? ERROR 135


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read Optional filename from $100 to $140
;
; Input  $9A = pointer just after command
;
; Output $140 contains filename, terminated by $0D
;
read_optional_filename:
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
   sty   $9a
   rts

@filename5:
   iny
   lda   $100,y
   cmp   #$0d
   beq   syn_error

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

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Copy filename from ($c9) to $140
;
copy_name:
   jsr   CHKNAME                ; copy data block at $00,x to COS workspace at $c9
                                ; also checks filename is < 14 chars, PIC additionally checks < 8 chars
   ldy   #0

copy_name_loop:
   lda   ($C9),y
   sta   NAME,y
   iny
   cmp   #$0d
   bne   copy_name_loop

filename_ok:
   rts

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Wait for a key press, return back two levels if not Y
;

confirm_or_rts:
   jsr   OSECHO                 ; wait for a key press and echo it

   pha                          ; save it
   jsr   OSCRLF
   pla                          ; restore it
   cmp   #'Y'
   beq   @confirm_yes           ; return to the caller

   pla                          ; pop an extra level of stack
   pla                          ; which will cancel the operation

@confirm_yes:
   rts
