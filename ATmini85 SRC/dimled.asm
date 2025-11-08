; XERC 2 (C) pablot 2006, xerc@pablot.com
; For more info and support forums vist http://xerc.pablot.com
;
; This file is part of XERC 2.
; 
; XERC 2 free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; any later version.
; 
; XERC 2 is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with XERC 2; if not, write to the Free Software
; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA



;******************************************
;
; The dim led for config
;
;******************************************


DIM_LED_ON:
	PUSH	Temp1

	RCALL	DIM_LED_DIM

	LDI	Temp1,(LF_IN_MODE_ | 1<<WGM01 | 1<<WGM00)
	OUT	TCCR0A,Temp1

	LDI	Temp1,(LF_PRESCALER_)
	OUT	TCCR0B,Temp1		; configure the prescaler

	POP	Temp1
	RET

DIM_LED_OFF:
	PUSH	Temp1

	CLR	Temp1
	OUT	TCCR0A,Temp1			; stop the fade

	POP	Temp1
	RET

DIM_LED_CLEAR:
	PUSH	Temp1

	LDI	Temp1,CLEAR_LED_VALUE_
	OUT	OCR0B,Temp1		; set compare value

	POP	Temp1
	RET

DIM_LED_DIM:
	PUSH	Temp1

	LDI	Temp1,DIM_LED_VALUE_
	OUT	OCR0B,Temp1		; set compare value

	POP	Temp1
	RET
	
DIM_LED_FULL:
	PUSH	Temp1

	LDI	Temp1,0xFF
	OUT	OCR0B,Temp1		; set compare value

	POP	Temp1
	RET
