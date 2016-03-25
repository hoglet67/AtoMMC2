;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CAT  ([directory path]/)... ([file path])
; or
; *CAT  ([directory path]/)... ([wildcard pattern])
;
; Produce a directory listing of the specified directory, optionally
; displaying only those entries matching a wildcard pattern.
;
; The directory path is optional, if omitted the current directory is used.
;
; The wildcard pattern is optional, if omitted * is used.
;
; 2011-05-29, Now uses CMD_REG -- PHS
; 2012-05-21, converted to use macros for all writes to PIC
; 2016-03-21, removed old @[filter] code, as the PIC supports proper wildcards -- DMB
; 2016-03-22, *CAT code also used for *INFO, giving *INFO multi file / wildcard support
; 2016-03-23, Reworked *CAT and *INFO so code is more readable
; 2016-03-25, Rewrote using iterator pattern

star_cat:
   jsr   iterator               ; invoke the directory iterator
;
; The directory iterator calls back to this handler for each matching child
;
; On Entry:
;     $140 contains the full path to the child
;     Y is the offset in the $140 buffer to the child name
;     C=0 if the child is a file, C=1 if the child is a directory
;
   jsr   print_filename         ; print just the filename without opening the file
   jmp   OSCRLF                 ; followed by a newline
