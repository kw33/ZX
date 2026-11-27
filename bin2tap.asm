; делаем SAVE "" SCREEN$

    device ZXSPECTRUM48
 
    org    #4000
start
    ; ТУТ bin-файл экрана
    incbin 'TeeRay - Elite (1985).scr'
end

    display    "START-END: ",/d,start," (",/h,start,") - ",/d,end," (",/h,end,")"
    display    "LENGTH:    ",/d,end-start," (",/h,end-start,")"
 
    define     tape    screen.tap
    emptytap   tape
    savetap    tape , CODE, "screen" , start , end-start