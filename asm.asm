; Get screen address
; B = Y pixel position
; C = X pixel position
; Returns address in HL and pixel position within character in A
;
Get_Pixel_Address:
	    LD A,B				; Calculate Y2,Y1,Y0
			AND %00000111			; Mask out unwanted bits
			OR %01000000			; Set base address of screen
			LD H,A				; Store in H
			LD A,B				; Calculate Y7,Y6
			RRA				; Shift to position
			RRA
			RRA
			AND %00011000			; Mask out unwanted bits
			OR H				; OR with Y2,Y1,Y0
			LD H,A				; Store in H
			LD A,B				; Calculate Y5,Y4,Y3
			RLA				; Shift to position
			RLA
			AND %11100000			; Mask out unwanted bits
			LD L,A				; Store in L
			LD A,C				; Calculate X4,X3,X2,X1,X0
			RRA				; Shift into position
			RRA
			RRA
			AND %00011111			; Mask out unwanted bits
			OR L				; OR with Y5,Y4,Y3
			LD L,A				; Store in L
			LD A,C
			AND 7
			RET

; Move HL down one pixel line
; HL - address {должен указывать в память пикселей}
;
Pixel_Address_Down:
	    INC H				; Go down onto the next pixel line
			LD A,H				; Check if we have gone onto next character boundary
			AND 7	; CF=0
			RET NZ				; No, so skip the next bit / перешло на след.треть
			LD A,L				; Go onto the next character line
			ADD A,32
			LD L,A
			RET C				; Check if we have gone onto next third of screen
			LD A,H				; Yes, so go onto next third
			SUB 8
			LD H,A
			RET
.out_of_screen:
	    dec h ; ??? но надо бы типа set carry
	    ret
;(*) если HL не указывает в экранно-пиксельную область, проверка не сработает

; Move HL up one pixel line
; HL - address
;
Pixel_Address_Up:
	    DEC H				; Go up onto the next pixel line
			LD A,H				; Check if we have gone onto the next character boundary
			AND 7
			CP 7
			RET NZ
			LD A,L
			SUB 32
			LD L,A
			RET C
			LD A,H
			ADD A,8
			LD H,A
			RET
