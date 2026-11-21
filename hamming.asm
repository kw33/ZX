;
;

    ld d,%11010000
    ld e,6

    jr Hamming74

Hamming74cod ; coding
    ld e,0
    jr Hamming74.cod_ent
;----------------------------------------------------------+
; Данных 4 бита, корр 3 бита
; D - данные. биты 7..4, используем биты слева направо
; Е - контрольные биты (биты 0..2) (при кодировании = 0)
; выход: E

Hamming74 ; decoding
    ld a,e
    rrca
    rrca ; -->
    ld e,a
    ;--------------
.cod_ent:
    ld a,(TM+2)
    and d ; D & r2  и определяется значение PF
    jp pe,.evenparity2 ; even=0, чётно
    ; нечётная чётность
    ld a,e
    xor 1 ; изменяем мл.бит
    ld e,a
.evenparity2:
    rlc e ; влево мимо CF (старшие биты=0)

    ld a,(TM+1)
    and d ; D & r2  и определяется значение PF
    jp pe,.evenparity1 ; even=0, чётно
    ; нечётная чётность
    ld a,e
    xor 1 ; изменяем мл.бит
    ld e,a
.evenparity1:
    rlc e ; влево мимо CF (старшие биты=0)

    ld a,(TM)
    and d ; D & r2  и определяется значение PF
    jp pe,.evenparity0 ; even=0, чётно
    ; нечётная чётность
    ld a,e
    xor 1 ; изменяем мл.бит
    ld e,a
.evenparity0:
    ;rlc e ; уже не нужно

   ret

; константы
; матрица преобразования, МП (без контр.битов)
TM
  defb %11010000 ;r0  D0h
  defb %10110000 ;r1  B0h
  defb %01110000 ;r2  70h