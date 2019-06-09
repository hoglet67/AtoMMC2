;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read filename, then fall through to open_file_read

open_filename_read:
   jsr   read_filename          ; copy filename from $100 to $140
   ; fall through to open_file_read

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Open file for read or write
;
; $140 = name
; a = read/write $01 = read, $11 = write
;

open_file_read:
   lda   #CMD_FILE_OPEN_READ
   jsr   open_file
   jmp   expect64orless

open_file_write:
   lda   #CMD_FILE_OPEN_WRITE

; Falls through to
open_file:
   pha
   jsr   send_name
   pla
   jmp   slow_cmd

send_name:
   jsr   prepare_write_data

send_additional_name:
   ldx   #0
   beq   @pumpname

@nextchar:
   jsr   write_data_reg
   inx

@pumpname:
   lda   NAME,x                 ; write filename to filename buffer
   cmp   #$0d
   bne   @nextchar

   lda   #0                     ; terminate the string
   jmp   write_data_reg


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read the file's info from the ATM header to LLOAD
;
; If LEXEC bit 7 = 0 then reads load, exec and length to LLOAD, LEXEC and LLENGTH
; If LEXEC bit 7 = 1 then reads       exec and length to        LEXEC and LLENGTH (LOAD is preserved)
;
; 2016/03/25: Rewrite to not use intermediate storage at $140
read_info:
   lda   #22                    ; ATM header size
   jsr   read_block_shared

   ldy   #$ff-16                ; skip bytes 1..16 (ATM header file name)
@loop:
   jsr   read_data_reg          ; read next ATM header byte
   iny
   bmi   @loop
   cpy   #2                     ; are we past the load byte?
   bcs   @store                 ; branch if >= 2
   bit   LEXEC                  ; if bit 7 is set on entry we don't overwrite load
   bmi   @skip_store
@store:
   sta   LLOAD,y
@skip_store:
   cpy   #5
   bcc   @loop                  ; branch if < 5
   rts


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
;  Read file
;
; (LLOAD) = memory target
; LLENGTH = bytes to read
;

read_file_read:
   lda   #0
   jsr   read_file_adapter

   inc   LLOAD+1
   dec   LLENGTH+1

read_file:
   lda   LLENGTH+1              ; any pages left?
   bne   read_file_read

   lda   LLENGTH                ; any stragglers?
   beq   @alldone

   jsr   read_file_adapter

   lda   LLOAD                  ; final adjustment to write pointer
   clc
   adc   LLENGTH
   sta   LLOAD
   bcc   @zerolen

   inc   LLOAD+1

@zerolen:
   stx   LLENGTH                ; zero out the length

@alldone:
   jmp   closefile


read_file_adapter:

   pha                          ; enter with a = bytes to read (0=256)

   lda   LLOAD
   sta   RWPTR
   lda   LLOAD+1
   sta   RWPTR+1

   pla

   ; @@TUBE@@
   JMP tube_read_block


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read data to memory
;
; a = number of bytes to read (0 = 256)
; (RWPTR) points to target
;
; @@TUBE@@ Refactored to allow code sharing with tube_read_block
read_block:
   jsr   read_block_shared
   ldy   #0
@loop:
   jsr   read_data_reg          ; then read it
   sta   (RWPTR),y
   iny
   dex
   bne   @loop
   rts

read_block_shared:
   tax
   ; ask PIC for (A) bytes of data (0=256)
   jsr   write_latch_reg        ; set amount to read
   lda   #CMD_READ_BYTES        ; set command
   jsr   slow_cmd_and_check     ; invokes error handler if return code > 64
   jmp   prepare_read_data      ; tell pic to release the data we just read


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; put 1st 22 bytes of data to open file
;
; file needs to be open at this point
;
write_info:
   jsr   set_rwptr_to_name
   lda   #22
   jmp   write_block


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Write data to open file
;
; SSTART = address to write from
; SEND   = final address + 1
;
write_file_fullpageloop:
   lda   #0                     ; 1 page
   jsr   write_file_adapter

   inc   SSTART+1

write_file:
   lda   SSTART+1
   cmp   SEND+1
   bne   write_file_fullpageloop

   lda   SEND                   ; any stragglers to write?
   cmp   SSTART
   beq   closefile

   sec                          ; calc remaining bytes
   sbc   SSTART
   jsr   write_file_adapter

closefile:
   lda   #CMD_FILE_CLOSE        ; close the file
   jmp   slow_cmd_and_check     ; invokes error handler if return code > 64


; adapter - falls through to write_block
;
write_file_adapter:
   ldy   SSTART
   sty   RWPTR
   ldy   SSTART+1
   sty   RWPTR+1

   ; @@TUBE@@
   JMP   tube_write_block


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; write a block of data
;
; a = block length (0=256)
; (RWPTR) = source
;
; @@TUBE@@ Refactored to allow code sharing with tube_write_block
write_block:
   tax                          ; save away the block size
   pha

   jsr   prepare_write_data     ; take it

   ldy   #0

@loop:
   lda   (RWPTR),y              ; upload data
   jsr   write_data_reg
   iny
   dex
   bne   @loop

write_block_shared:
   pla                          ; write block command
   jsr   write_latch_reg        ; amount to write
   lda   #CMD_WRITE_BYTES       ; give command to write
   jmp   slow_cmd_and_check     ; invokes error handler if return code > 64


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; delete a file
;
; file to be deleted must be opened with open_read
;
delete_file:
   lda   #CMD_FILE_DELETE
   jmp   slow_cmd_and_check     ; invokes error handler if return code > 64
