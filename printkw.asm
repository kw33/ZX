; стартуeм тут

    ;ld hl,FontKW
    ;call printkw_font
  ;  ld h,189
  ;  ld l,252
  ;  call printkw_at
    ld a,253
    ld (PosX),a

    ld a,33
    call printkw_char ; оконный вывод ))


  ;  ld hl,stroka
  ;  call printkw_str_a


    ld bc,32
lup1:
    push bc
    ld a,c
    call printkw_char_a
    pop bc
    inc c
    ld a,0 ; до 255
    or c
    jr nz,lup1

    ld bc,32
lup3:
    push bc
    ld a,c
    call printkw_char_a
    pop bc
    inc c
    ld a,0 ; до 255
    or c
    jr nz,lup3

    ld bc,32
lup4:
    push bc
    ld a,c
    call printkw_char_a
    pop bc
    inc c
    ld a,0 ; до 255
    or c
    jr nz,lup4

    ld bc,32
lup5:
    push bc
    ld a,c
    call printkw_char_a
    pop bc
    inc c
    ld a,0 ; до 255
    or c
    jr nz,lup5

    ld bc,32
lup6:
    push bc
    ld a,c
    call printkw_char_a
    pop bc
    inc c
    ld a,105
    xor c
    jr nz,lup6

  ret

;=========================
    ld bc,1000;32
lup2:
    push bc
    ld a,155;c
    call printkw_char_a
    pop bc
    dec bc
    ld a,b
    or c
    jr nz,lup2

    ret

stroka db 'Тестовая строчка ZX-Spectrum',128,0

;--------------------------------------------------
; printkw_at
; printkw_draw
; printkw_setfont
; printkw_char_a
; printkw_str_a
; printkw_str

; 1-й, плохой вариант:
;  printkw_char_a выводит от ~1200 симв/с до 380 симв/с) зависит от кода символа
;  тэст вывода всех кодов 32..255: 570 симв/с
; Изменил ф-цию на работу только с 8-байтовыми символами:
;  примерно 1100 любых симв/с. (~3200 тактов на символ)
; 3-й вариант, для любой высоты фонта:
;  0,94 с на 1000 симв. (1064 симв/с)  ;-)
; ZX из Бэйсика выводит свои символы около 2000 симв/с.
;--------------------------------------------------
; Переменные для printkw

FontAddr defw FontKW7
ScrAddr  defw 4000h
Shift defb 0 ; 0..7
Mask  defw 0000h
Mask0 defb 0
PosX  defb 0
PosY  defb 0
PosXnew defb 0
ScrAddrTmp defw 0
RectPrint
.X1 defb 0
.Y1 defb 0
.X2 defb 255
.Y2 defb 191

;--------------------------------------------------
; Установить позицию вывода в пикселях (левый верхний угол символа)
; H - Y
; L - X
; используется весь экран

printkw_at
    ld (PosX),hl ; ???
    ; Получить адрес экранной памяти
    ld a,h ; Y
    cp 192 ; C0h
    ret nc ; за пределами экрана!

    and %11000000 ; оставим NN для Y    C0h
    rrca ; круговорот А вправо
    rrca
    rrca
    or #40
    ld d,a   ; старший байт: 40 и NN
    ld a,h   ; Y
    and %111 ; оставим SSS для Y   7h
    or d 
    ld d,a ; старший байт готов
    ld a,h ; Y
    and %111000 ; ZZZ     38h
    rlca ; круговорот А влево
    rlca
    ld e,a ; младший байт адреса загружен ZZZ
    ld a,l ; X 
    and %11111000 ; оставим 0..31 (из пискелей в байты)
    rrca ; круговорот А вправо
    rrca
    rrca
    or e
    ld e,a ; младший байт готов
    ld (ScrAddr),de
    ld a,l
    and %111 ; смещение в пикселях 0..7
    ld (Shift),a
    ret

;--------------------------------------------------
; A - код 32..255
; рисует на всём экране

printkw_draw
    ld hl,(ScrAddr)
    ld (ScrAddrTmp),hl
    ; ищем символ
    ld hl,(FontAddr) ; адрес фонта
    ld c,(hl) ; высота символов
    inc hl
    sub 32
    ret c ; если A < 32, выход
    jr z,.no_srch ; если A=32

    ; умножение в цикле. A * C+1 (используем DE)
    ; HL - адрес, C=высота
    ld d,0
    ld e,a ; DE-код
    ld b,c
    add hl,de;байт маски (+1)
.lp_mul:
    add hl,de
    djnz .lp_mul
.no_srch:

    ; HL=адрес маски символа, C=высота
    ld a,(Shift)
    ld b,a
    ld d,#FF  ; D=маска, 2й байт
    ld a,(hl) ; A=маска
    inc hl    ; адр. битов символа
    ld (Mask0),a
    ; делаем маску
    ; CF=0 при правильных параметрах
    scf
    inc b ; чтоб зайти в конец цикла из-за b=0
    jr .lp_cond_mask
.lp_shift_mask:
    rra  ; вправо через CF
    rr d ; CF на выходе = 1
.lp_cond_mask:
    djnz .lp_shift_mask
    ld e,a
    ld (Mask),de

    ; HL - адр.симв.
    ; С - кол-во строк символа
.lp_line:  ; вывод строк символа  HL С
    ld a,(Shift)
    ld b,a
    ld d,0
    ld a,(hl) ; биты симв 1й байт
    inc hl
    or a ; CF=0
    inc b  ; чтоб зайти в конец цикла из-за b=0
    jr .lp_cond
.lp_shift: ; сдвиг строки символа
    rra    ; вправо через CF
    rr d   ; CF на выходе = 0
.lp_cond:
    djnz .lp_shift
    ld e,a ; E D - символ

    push hl
    ld hl,(ScrAddrTmp)
    ld a,(Mask)
    and (hl)
    or e ; 1й байт символа
    ld (hl),a
    ; тут второй байт оброботываим
    inc l
    ld a,l ; мл.байт адр.
    and %11111 ; 0..31
    jr z,.cross_edge ; перешло на след.строку
    ld a,(Mask+1)
    and (hl)
    or d ; 2й
    ld (hl),a
.cross_edge:
    dec l
	    ; на 1 пиксель ниже -----------------
	    INC H
	    LD A,H   ; для проверки выхода за знакоместо
	  ;  cp #58   ; также может увеличиться номер трети экрана (*)
	  ;  jr z,.out_of_screen
	    AND 7    ; CF=0
	    jr NZ,.cont ; внутри знакоместа остались
	    LD A,L	; переход на след. знакоместо
	    ADD A,32
	    LD L,A
	    jr C,.next_third	; перешли на следующую треть
	    LD A,H	  ; остались в трети
	    SUB 8
	    LD H,A
.cont:
    ld (ScrAddrTmp),hl
    pop hl ; адр.битов символа
    dec c
    jr nz,.lp_line
    ret

.next_third:
    ld a,#58
    cp h
    jr nz,.cont
    pop hl
    ret

;--------------------------------------------------
; HL - адрес знакогенератора

printkw_setfont
    ld (FontAddr),HL ; установить адрес фонта
    ret

;--------------------------------------------------
; A - код. Вывод на весь экран

printkw_char_a
    call printkw_draw
    ; вычислим ширину символа
    ld a,(Mask0)
    ld b,8
    or a ; A = 0 ?
    jr z,.continue ; ширина = 8
    rlca ; пропускаем первый бит (т.к. один бит есть по-любому)
    ld b,0
.count:
    inc b
    rlca ; влево
    jr nc,.count
.continue:
    ld hl,(PosX)
    ld a,l ; X
    add b
    jr c,.new_line
    ld l,a
.at_save_hl:
    ld (PosX),hl
    jp printkw_at ;             возможна возможность ! ! !

.new_line:
    ld de,(FontAddr)
    ld a,(de)
    add h
    cp 192 ; X < 192 ?
    jr nc,.out_of_scr
    ld h,a
    ld l,0
    jr .at_save_hl
.out_of_scr:
    ld hl,0
    jr .at_save_hl

;--------------------------------------------------
; Вывод ASCIIZ-строки (используя printkw_char_a)
; HL - адрес

printkw_str_a
    ld a,(hl)
    or 0
    ret z
    push hl
    call printkw_char_a
    pop hl
    inc hl
    jr printkw_str_a

;--------------------------------------------------       ?????
; вывод cтроки внутри прямоугольника RectPrint
; символы выводятся только целиком
; HL - адрес ASCIIZ-строки

printkw_str
    ld a,(hl)
    or 0
    ret z
    cp 13 ; CR
    jr .cr
    push hl
    ;----------------------*********
    ; узнаем, поместится ли символ
      ; получим адрес символа и ширину
      ld hl,(ScrAddr)
      ld (ScrAddrTmp),hl
      ; ищем символ
      ld hl,(FontAddr) ; адрес фонта
      ld c,(hl) ; высота символов
      inc hl
      sub 32
      ret c ; если A < 32, выход
      jr z,.no_srch ; если A=32

      ; умножение в цикле. A * C+1 (используем DE)
      ; HL - адрес, выход: C=высота
      ld d,0
      ld e,a ; DE-код
      ld b,c
      add hl,de;байт маски (+1)
.lp_mul:
      add hl,de
      djnz .lp_mul



    ;----------------------*********
    pop hl
    inc hl
    jr printkw_str_a

.no_srch:
.cr:

    ret ;                               ? ? ?

;***
; узнать адрес битов символа
; вычислить ширину
; проверить, влезет ли
;    если нет, вычислить новые координаты и адрес со смещением
; (адрес битов символа, высота симв.,

;--------------------------------------------------
; вывод символа в прямоугольнике RectPrint
; A - код

printkw_char
  ; узнаем адрес битов символа
    ld hl,(ScrAddr)		      ; ? ? ?
    ld (ScrAddrTmp),hl		      ; ? ? ?
    ; ищем символ
    ld hl,(FontAddr) ; адрес фонта
    ld c,(hl) ; высота символов
    inc hl    ; пропускаем высоту
    sub 32
    ret c ; если A < 32, выход
    jr z,.no_srch ; если A=32

    ; умножение в цикле. A * C+1 (используем DE)
    ; HL=FontAddr+1, C=высота
    ld d,0
    ld e,a ; DE-код, уменьшеный на 32
    ld b,c
    add hl,de ; байт маски (+1)
.lp_mul:
    add hl,de
    djnz .lp_mul
.no_srch:
    ; HL=адрес маски символа, C=высота

  ; вычислим ширину символа
    ld a,(hl)
    ld b,8 ; на случай, если ширина=8
    or a ; A = 0 ?
    jr z,.continue ; ширина = 8
    rlca ; пропускаем первый бит (т.к. один бит есть по-любому)
    ld b,0
.count:
    inc b
    rlca ; влево
    jr nc,.count
.continue:
    ; HL=адрес маски символа, C=высота, B=ширина

  ; проверим, влезет ли по X
    ld a,(PosX)
    ld e,b
    dec e      ; уменьшена
    add a,e
    jr c,.over ; через 0 перешло - не влезло
    ld e,a
    ld a,(RectPrint.X2) ; cp X2,PosX+dX-1
    cp e ; если X2 меньше PosX+dX-1, то не влазит
    jr c,.doesntfit
    ; вошло)
    ld a,e
    inc a ; новая позиция Х, может стать 0
    jr z,.zero
.savex:
    ld (PosXnew),a
  ;================== вычисляем адрес и смещение







.over:

.zero:
.doesntfit:	 ; перевод строки
    ; HL=адрес маски символа, C=высота
    ld a,(PosY)
    ; проверим, влазит ли по Y
    add a,c ; переполнения не будет (Y2 = 1..191)
    ld e,a
    ld a,(RectPrint.Y2)
    ld d,e  ; новая координата PosYnew
    cp e    ; cp Y2,PosY+dY
    jr c,.doesntfeety ; верх новой строки уже не влазит
    ld a,e
    dec a
    add a,c ; низ новой строки
    ld e,a
    ld a,(RectPrint.Y2)
    cp e    ; cp Y2,PosY+dY +dY-1
    jr c,.doesntfeety ; низ новой строки не влазит

    ld (RectPrint.Y1),a
    ld a,(RectPrint.X1)
    jr .savex



    ret
  nop
  nop
  nop
  nop
  nop
  nop
  nop

;--------------------------------------------------
;-------------------
  include fontkw7.inc

;-----------
   ; ld a,(NNNNN) - 3B 13t
   ; ld r,(IX+n)  - 3B 19t


;----------умножение

    ; умножаем DE = A*8 (тут CF=0)
;    rla         ; 4
;    rl d        ; 8
;    rla         ; 4
;    rl d        ; 8
;    rla         ; 4
;    rl d        ; 8
;    ld e,a      ; 4
;    add hl,de   ; 11
		; = 51
			   ; умножить А * 7: (A*8)-1
    ; умножить А на 7      ld d,0         ;7
;    ld e,a      ; 4        ld e,a         ;4
;    rla         ; 4        sub hl,de CF=0 ;11
;    rl d ; *2   ; 8        rla         ; 4
;    rla         ; 4        rl d        ; 8       //?  A*7-> HL=A*2 + A*4 +A
;    rl d ; *4   ; 8        rla         ; 4
;    add a,e ;*5 ; 4        rl d        ; 8
;    adc d,0     ; 7        rla         ; 4
;    add a,e ;*6 ; 4        rl d        ; 8
;    adc d,0     ; 7        ld e,a      ; 4
;    add a,e ;*7 ; 4        add hl,de   ; 11
;    adc d,0     ; 7                    ;  = 73
		; = 61

    ; умножение в цикле. A * C+1 (используем DE)
    ; HL - адрес, выход: C=высота
;    ld d,0          ;7
;    ld e,a          ;4
;    ld b,c          ;4
;    add hl,de;байт маски+1;11
;.lp_mul:
;    add hl,de       ;11
;    djnz .lp_mul    ;8/13
		    ; для 7+1: = 189 ваще-то


  ; НЕ рабочее
    ; умножение, HL += A * C+1 (используем DE и раскpутку)
;    ld d,0
;    ld e,a ; DE=код
;    ld a,c
;    sub 5 ; тут5!
;    jr z,.no_srch
;    ld b,a
;.lp_add:
;    add hl,de
;    djnz .lp_add ; прибавили высоту, превышающую 5
    ; DA пара
    ; CF=0
;    ld b,a ; сохр
;    rla
;    rl d ; *2
;    add hl,de ;+*2
    ; CF=0
;    rla
;    rl d ; *4
;    add hl,de ;+*4   (*6)
;.no_srch: