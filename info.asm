;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *INFO  ([directory path]/)... ([file path])
; or
; *INFO  ([directory path]/)... ([wildcard pattern])
;
; Shows metatadata associated with one or more files.
;
; If the path resolved to a single file, then info for just this file is displayed.
;
; Otherwise the path is assumed to identify a directory and a wildcard pattern
; filters the files in this directory.
;
; The directory path is optional, if omitted the current directory is used.
;
; The wildcard pattern is optional, if omitted * is used.
;
; 2016-03-22, *CAT code also used for *INFO, giving *INFO multi file / wildcard support
; 2016-03-23, Added back support for *INFO on a single file
; 2016-03-23, Reworked *CAT and *INFO so code is more readable
; 2016-03-25, Rewrote using iterator pattern
;
star_info:
   jsr   iterator               ; invoke the directory iterator
;
; The directory iterator calls back to this handler for each matching child
;
; On Entry:
;     $140 contains the full path to the child
;     Y is the offset in the $140 buffer to the child name
;     C=0 if the child is a file, C=1 if the child is a directory
;
   php                          ; save C flag
   jsr   print_filename         ; print the filename
   plp                          ; restore C flag
   bcs   newline                ; if a directory, then skip the file info bit

@padloop:
   jsr   SPCOUT                 ; pad filename with spaces
   lda   $e0                    ; $e0 = horizontal cursor position
   cmp   #16                    ; continue until column 16
   bcc   @padloop

   sta   LEXEC                  ; bit 7 = 0 forces read_info to read all info
   jsr   open_file_read         ; open the file for reading
   jsr   read_info
   ; fall through into print_fileinfo

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Display file info
;
; Prints load, exec, length
;
print_fileinfo:
   ldx   #LLOAD
   jsr   HEXOUT4                ; $f7ee print 4 bytes in hex, incrementing X
   jsr   HEXOUT2                ; $f7f1 print 2 bytes in hex, incrementing X

newline:
   jmp   OSCRLF

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Display file name
;
; Prints name
;
print_filename:
   lda   NAME,y                 ; get next char of filename
   cmp   #$0d
   beq   return
   jsr   OSWRCH
   iny
   bne   print_filename         ; branch always
