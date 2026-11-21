; Вывод спрайта 8x8 с попиксельным позиционированием
; Вход: H = Y (0-191), L = X (0-255)

VIDEO_START     equ     $4000
SPRITE_WIDTH    equ     8
SPRITE_HEIGHT   equ     8

    ld hl,00

PutSprite:
    push    af
    push    bc
    push    de
    push    hl

    ld      a, h
    ld      b, l
   
    srl     a ; shr
    srl     a
    srl     a ; поделили на 8
   
    ld      h, 0
    ld      l, a   ; HL = Y/8
    add     hl, hl
    add     hl, hl
    add     hl, hl
    add     hl, hl
    add     hl, hl
   
    ld      a, b
    srl     a
    srl     a
    srl     a
    ld      e, a
    ld      d, 0
    add     hl, de
   
    ld      de, VIDEO_START
    add     hl, de
   
    ld      a, h
    and     %00000111
    jr      z, .no_shift_y
   
.no_shift_y:
    push    hl
   
    ld      a, b
    and     %00000111
    ld      b, a
   
    ld      c, SPRITE_HEIGHT
    pop     hl
   
.line_loop:
    ld      de, SpriteData
    ld      a, SPRITE_HEIGHT
    sub     c
    ld      e, a
    ld      d, 0
    add     hl, de
    ex      de, hl
   
    ld      a, (de)
    ex      de, hl
   
    ld      d, a
    ld      a, b
    or      a
    jr      z, .no_shift
   
    ld      a, d
.shift_loop:
    srl     a
    djnz    .shift_loop
    ld      d, a
   
.no_shift:
    ld      a, (hl)
    or      d
    ld      (hl), a
   
    inc     hl
    inc     hl
    inc     hl
    inc     hl
   
    dec     c
    jr      nz, .line_loop
   
    pop     hl
    pop     de
    pop     bc
    pop     af
    ret

SpriteData:
    db  %11111111
    db  %10000001
    db  %10000001
    db  %10011001
    db  %10011001
    db  %10000001
    db  %10000001
    db  %11111111


