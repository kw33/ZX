;*******************************************************************************
;*******                                                                 *******
;*******              загрузка с кассеты loadkw.asm v.0.0.e              *******
;*******                      (c) Master-Lux Ltd.                        *******
;*******                                                                 *******
;*******************************************************************************

; CLEAR 29999  #752F

BORDCR equ 23624

    ld ix,30032
    ld hl,30000 ; #7530
nulling:
    ld (hl),0
    inc hl
    ld a,h
    cp #90
    jr nz,nulling

load:
    di
    ld hl,30000

.waitpilot:
    ld e,255 ; периодов пилота
    ld a,(BORDCR)
    rrca
    rrca
    rrca
    ld (B1color),a
    ld (B0color),a
.cnt:
    ld a,(B1color)
    ld b,%00100000
    call mea0
    jr nc,.nc1
    ld a,(B0color)
    ld b,0
    call mea0 ; будем контролировать только нулевые
    jr nc,.nc1

    ld a,c
    sub 49;105
    cp 14
    jr nc,.waitpilot

    dec e
    jr nz,.cnt
    ; считаны все начальные пилоты
.waitsynchro:
    ; идет пилот-тон, ждем синхру
    ld a,1	   ; цвет пилот-тона 1
    ld b,%00100000
    call mea0
    jr nc,.nc1
    ld a,5	   ; цвет пилот-тона 0
    ld b,0
    call mea
    jr nc,.nc1

    ld a,c
    sub 73
    cp 10
    jr nc,.waitsynchro
    ; синхронизировано, далее получаем байты  /////////////////////////////////

.qq:
    ld a,0	  ; ц1
    out (254),a
    ld b,%00100000
    call mea0
    jr nc,.err

      ld (hl),c     ; 1111
      inc hl
    ; преобразовать длительность в 4 бита
    call tra

      ;ld (ix+0),a     ; 1111 -> число
      ;inc ix

    ld a,7	  ; ц2
    out (254),a
    ld b,0
    call mea0
    jr nc,.err ; ??

      ld (hl),c     ; 0000
      inc hl

    call tra

      ;ld (ix+0),a     ; 1111 -> число
      ;inc ix


    ; /////////////////////////////////////////////////////////////////////////
    jr .qq ;;;;;;;

    ;---------------------------------------
.nc1:
    jr z,.waitpilot ; over
    ; break
.break:
    ei	   ;;; EI
    ld a,(BORDCR)
    rrca
    rrca
    rrca
    out (254),a
    ret

.err:
    jr nz,.break
    ld a,2
    out (254),a 	 ; ? ? ?
    ei
    ret


B1color defb 0
B0color defb 0

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
; переводим длительность в число     устарело
; с - длительность импульса
; b - номер периода (0..5) на выходе (единичного или нулевого)
tra:
    ld a,c
    cp 15 ; П0, 1й
    jr c,.period0
    cp 20 ; П1, 2й
    jr c,.period1
    ; для П2 П3 П4 П5
    sub 3
    and %111000 ; шесть периодов
    rrca
    rrca
    rrca
    ret
.period0:
    xor a
    ret
.period1:
    ld a,1
    ret
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    22 bytes
; измерять продолжительность
; b = 0 - измеряем нулевой импульс (ear уже в нуле)
; b = %00100000 - измеряем единичный импульс (ear уже в единице)
; a - цвет поребрика
; выход:
; с - длительность импульса
; CF, ZF
mea0:					   ; ПЕРВЫЙ ВОРЕАНТ
    ld c,0
mea:
    out (254),a 			   ; ?? проверять минимальный  ??
.lp:					   ; ?? и максимальный импульс ??
    inc c
    jr z,.over	  ; далее ZF = 0
    ld a,#7F
    in a,(#FE)
    rra 	  ; вправо через CF (EAR bit был 6й, стал 5й)
    ret nc	  ; break (ZF=0, CF=0)
    and %00100000 ; оставили бит ear
    xor b	  ; при B=0 не меняем A (ждём приход единицы)
		  ; при B=%00100000 бит ear инвертируется (ждём приход нуля)
    jr z,.lp	  ; пока не 0 - ждём (для обоих случаев)
    scf
    ret 	  ; CF=1, ZF=0

.over:
    xor a	  ; ZF=1, CF=0
    ret

end_of_block:

;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    di
    ld hl,30000
q:
    ld b,%00100000
    call meas0
    jr nc,.nc
    ld b,0
    call meas
    jr nc,.nc

    ld a,2
    cp c
    jr nc,q
    ld (hl),c
    inc hl

    jr q
.nc:
    jr z,q ; over
    ; break
    ei	   ;;; EI
    ret

;  Гц  cчётчик   [прибавляем и убавляем единицу и 4% детон.]
; 807= 68..70
; 713= 77..79    [73..83] 10
; 501=111..113   [105..119] 14
;                  граничн.знач.:
;2047= 25..27         31
;1536= 35..37         42
;1152= 47..49         56
; 864= 63..65
; 649= 75..77
; 486=114..116
; 365=154..156
; 273=207..209

;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; измерять продолжительность
; b = 0 - измеряем нулевой импульс (ear уже в нуле)
; b = %00100000 - измеряем единичный импульс (ear уже в единице)
meas0:
    ld c,0
meas:
    inc c
    jr z,.over	  ; далее ZF = 0
    ld a,#7F
    in a,(#FE)
    rra 	  ; вправо через CF (EAR bit был 6й, стал 5й)
    ret nc	  ; break (ZF=0, CF=0)
    and %00100000 ; оставили бит ear
    xor b	  ; при B=0 не меняем A (ждём приход единицы)
		  ; при B=%00100000 бит ear инвертируется (ждём приход нуля)
    jr z,meas	  ; пока не 0 - ждём (для обоих случаев)
    scf
    ret 	  ; CF=1, ZF=0

.over:
    xor a	  ; ZF=1, CF=0
    ret

;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


;"""""""""""""""""""""""""""""""""""""""""""""""""""""
; тэстовая процедурка
; это работает. можно пользовать measure01 и measure01_
.w1: ; первично ждём 1
    ld a,#7F
    in a,(#FE)
    rra 	  ; вправо через CF (EAR bit был 6й, стал 5й)
    ret nc	  ; break
    and %00100000 ; test ear bit (rra)
    jr z,.w1	   ; пока не 1 - ждём

    di
    ld hl,#7530
.w:
    call measure01_
    jr nc,.ex
    ld (hl),c
    inc hl
    ld a,h
    xor #D6 ; D6D8 - 55000
    jr nz,.w
.ex:
    ld b,0
    ei
    ret


LeCouler defb %10010100
Dummy defb 0
; неточности измерений:
; 229..233 = 4
; 31..34 = 3
; 83..86 = 3

;#######################################################
; Измеряем период единичного и нулевого импульсов
measure01:
    ; ждём 0 на входе (1 уже)
      ld c,0	  ; c счётчик
    ld a,1	  ; ц1
    out (254),a
.w0:
      inc c
    ld a,#7F
    in a,(#FE)
    rra 	  ; вправо через CF (EAR bit был 6й, стал 5й)
    ret nc	  ; break
    and %00100000 ; test ear bit (rra)
    jr nz,.w0	  ; пока не 0 - ждём
    ; пришёл 0, ждём 1
    ld a,7	  ; ц0
    out (254),a
.w1:
      inc c
    ld a,#7F
    in a,(#FE)
    rra 	  ; вправо через CF (EAR bit был 6й, стал 5й)
    ret nc	  ; break
    and %00100000 ; test ear bit (rra)
    jr z,.w1	  ; пока не 1 - ждём
    scf
    ret
;#######################################################
;#######################################################
; Измеряем период единичного и нулевого импульсов
measure01_:
    ; ждём 0 на входе (1 уже)
      ld c,0	  ; c счётчик
    ld a,(LeCouler)	   ; ц
    rrca
    ld (LeCouler),a
    and %111
    out (254),a
.w0:
    nop ; задержка
      inc c
    ld a,#7F
    in a,(#FE)
    rra 	  ; вправо через CF (EAR bit был 6й, стал 5й)
    ret nc	  ; break
    and %00100000 ; test ear bit (rra)
    jr nz,.w0	  ; пока не 0 - ждём
    ; пришёл 0, ждём 1
    ld a,(LeCouler)	   ; ц
    rrca
    ld (LeCouler),a
    and %111
    out (254),a
.w1:
    nop ; задержка
      inc c
    ld a,#7F
    in a,(#FE)
    rra 	  ; вправо через CF (EAR bit был 6й, стал 5й)
    ret nc	  ; break
    and %00100000 ; test ear bit (rra)
    jr z,.w1	  ; пока не 1 - ждём
    scf
    ret
;#######################################################

;=================================
; не нравится эта процедурка
; b - цвет1 цвет0
; a - используется
; возврат:
; c - счётчик
; CF=0 - break
measure01__:
    ld a,#20 ; jr nz (начальная операция)
    ld (.OP),a
    ld b,%00100011 ; ц1 100  ц0 011
    ld c,0	   ; c счётчик
    ; ждём 0 на входе (1 уже есть)
.w:
    ld a,b
    and %111 ; оставим цвет
    out (254),a   ; бордюр
.w0:
    inc c	  ; счётчик++
    ld a,#7F
    in a,(#FE)
    rra 	  ; вправо через CF (EAR bit был 6й, стал 5й)
    ret nc	  ; break
    and %00100000 ; оставим бит ear
.OP:jr nz,.w0	  ; ждём    {jr z -> #28; jr nz -> #20
;...
;====================================


; проверка enter
breaknotpressed:
    ld a,#BF
    in a,(#FE)
    rra
    jr c,breaknotpressed
;------------------------

;-------------------------------
lp1:
    ld a,#7F
    in a,(#FE)
    rra        ; вправо через CF (EAR bit был 6й, стал 5й)
    ret nc     ; break
    ;and #20    ; EAR bit

    ld a,#16
    out (254),a
    call wait

    ld a,#05
    out (254),a
    call wait
    jp lp1

; проверка Break
    ld a,#7F
    in a,(#FE)
    rra
    jr nc,breakpressed

    jp lp1
breakpressed:
    ret

;===
wait
   ;ret
   ;------
    ld c,b
    ld b,16
wait_1:
    djnz wait_1 ; 13 8
    ld b,c
    ret
; 2250 tkt ??
;--------------------------------
; адрес порты вывода
; bit 0 - keyboard, magnitofon, speaker
; bit 1 - n.u.
; bit 2 - ZX-Printer
; bit 3, 4 - Interface 1, Microdrive
;--------------------------------
; вывод в порт 254
; bit 0..2 - border
; bit 3 - magnitofon out
; bit 4 - speaker's out
; ------------------------------
; ввод из порта 254
; bit 0..4 - keyboard (reg A - один из битов = 0)
; bit 5 ?
; bit 6 - magnitofon in