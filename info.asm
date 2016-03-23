;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *INFO  ([wildcard pattern])
;
; Shows metatadata associated with files in the current working directory, optionally
; displaying only those entries matching a wildcard pattern.

;
star_info:
   lda   #0                     ; load address is not set
   sta   LEXEC

   jmp   generic_cat_info       ; *INFO uses the same code now as *CAT
