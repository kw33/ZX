    device ZXSPECTRUM48
 
    org    55000 ; d6d8
start
   ; include printkw.asm
   ; include hamming.asm
    include loadkw.asm
end

    display    "START-END: ",/d,start," (",/h,start,") - ",/d,end," (",/h,end,")"
    display    "LENGTH:    ",/d,end-start," (",/h,end-start,")"
    display "block-lenght:",/d,end_of_block-begin_of_block
 
    define     tape    binary.tap
    emptytap   tape
    savetap    tape , CODE, "binary" , start , end-start