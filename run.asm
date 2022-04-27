;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *[file name]
;
; As for *RUN, except the /LIB/ directory is also searched
;
star_arbitrary:

   jsr   read_filename          ; copy filename into $140

   txa                          ; save X, length of the filename
   pha
   tya                          ; save Y, the command line index
   pha
   lda   #CMD_FILE_OPEN_READ    ; try to open the file, to see if it exists
   jsr   open_file
   cmp   #STATUS_COMPLETE+1     ; a status of 64 or less indicates no error
   bcs   skip_close
   jsr   closefile
   clc
skip_close:
   pla
   tay                          ; restore Y, the command line index
   pla
   tax                          ; restore X, the length of the filename
   bcc   initparams

make_space_loop:                ; move the filename up to make space for the lib path
   lda   NAME, x
   sta   NAME+libpath_end-libpath, x
   dex
   bpl   make_space_loop

   ldx   #libpath_end-libpath-1
copy_libpath_loop:
   lda   libpath, X
   sta   NAME, X
   dex
   bpl   copy_libpath_loop
   bmi   initparams

libpath:
   .byte "/LIB/"
libpath_end:

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *RUN [filename]
;
; Try to execute the program with the specified name. If it's a BASIC program
; with an execution address of C2B2 then execute a 'RUN' command at return.
;
star_run:
   jsr   read_filename          ; copy filename into $140

initparams:
   jsr   SKIPSPC
   ldx   #0

copyparams:
   lda   $100,y
   sta   $100,x
   inx
   iny
   cmp   #$0d
   bne   copyparams
   dey

   lda   MONFLAG
   pha
   lda   #$ff
   sta   MONFLAG
   jsr   $f844                  ; set $c9\a = $140, set x = $c9
   jsr   $f95b
   pla
   sta   MONFLAG

checkbasic:
   lda   LEXEC                  ; if this is a non-auto-running basic program
   cmp   #$b2
   bne   @runit
   lda   LEXEC+1
   cmp   #$c2
   bne   @runit

   lda   #<@runcmd
   sta   $5
   lda   #>@runcmd
   sta   $6
   jmp   $c2f2

@runit:
   ; @@TUBE@@
   ; Issue a transfer type 4, which is set the execution address
   ldx   #LEXEC                 ; block containing transfer address
   ldy   #4                     ; transfer type
   jsr   tube_claim_wrapper
   ; If the tube is enabled, it will eventually jump to TubeIdleStartup and not return
   ; If the tube is disabled, it will fall through to here
   jmp   (LEXEC)

@runcmd:
   .byte "RUN",$0d
