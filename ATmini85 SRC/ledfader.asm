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
; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

;******************************************
;
; The Led Fader part of the XERC2
;
;******************************************

LF_START:
	SBRC	XERC_STATUS,LF_DISABLE
	RET					; if disabled then don't start

	IN	Temp1,TIMSK
	SBRC	Temp1,TOIE0			; if allready running then don't
	RET					; restart it

#ifndef SIMULATION
	LP	LP_1S2_,LP_1S2_EXT_		; make a pause coz it looks better
#endif

	CBR	XERC_STATUS,(1<<LF_OUT)		; start with a fade in

	LDI	Temp1,LF_TOP_IN_
	OUT	OCR0A,Temp1			; set counter top value

	CBR	XERC_STATUS,(1<<LF_OUT)		; fading in
	LDI	Temp1,LF_TOP_IN_
	MOV	LF_TOP,Temp1
	LDI	Temp1,LF_BOTTOM_HOLD_
	MOV	LF_HOLD,Temp1
	CLR	LF_HOLD_COUNT

	LDI	Temp1,0x02
	MOV	LF_COUNT,Temp1			; start on 0x02 to aviod start glitch
	OUT	OCR0B,LF_COUNT			; set compare value

	LDI	Temp1,(LF_IN_MODE_ | 1<<WGM01 | 1<<WGM00)
	OUT	TCCR0A,Temp1

	LDI	Temp1,(1<<WGM02 | LF_PRESCALER_); configure the prescaler
	OUT	TCCR0B,Temp1			; and set last WGM bit

	RCALL	ENABLE_TIM0_OVF_INT		; enable overflow interrupt

	RET


LF_STOP:
	RCALL	DISABLE_TIM0_OVF_INT		; dissable interrupt

	CLR	Temp1
	OUT	TCCR0A,Temp1			; stop the fade

	RET


TIM0_OVF:
	PUSH	Temp1
	IN	Temp1,SREG
	PUSH	Temp1

	CP	LF_COUNT,LF_TOP
	BREQ	LF_TOP_REACHED			; check if we have reached top of fade

	INC	LF_COUNT
	OUT	OCR0B,LF_COUNT			; update pwm reg

RET_TIM0_OVF:
	POP	Temp1
	OUT	SREG,Temp1
	POP	Temp1

	RETI

LF_TOP_REACHED:
	CP	LF_HOLD_COUNT,LF_HOLD
	BREQ	LF_SWITCH_DIR			; if held finished then switch down

	INC	LF_HOLD_COUNT			; increase the hold counter

	RJMP	RET_TIM0_OVF

LF_SWITCH_DIR:
	SBRC	XERC_STATUS,LF_OUT
	RJMP	LF_SWITCH_UP

LF_SWITCH_DOWN:
	SBR	XERC_STATUS,(1<<LF_OUT)		; fading out

	CLR	LF_HOLD_COUNT

	LDI	Temp1,LF_TOP_OUT_
	MOV	LF_TOP,Temp1

	LDI	Temp1,LF_BOTTOM_HOLD_
	MOV	LF_HOLD,Temp1

	CLR	LF_COUNT
	OUT	OCR0B,LF_COUNT			; Clear counter and start over
	
	IN	Temp1,TCCR0A
	ANDI	Temp1,~0x30
	ORI	Temp1,LF_OUT_MODE_
	OUT	TCCR0A,Temp1			; set fade out mode

	RJMP	RET_TIM0_OVF

LF_SWITCH_UP:
	CBR	XERC_STATUS,(1<<LF_OUT)		; fading in

	CLR	LF_HOLD_COUNT

	LDI	Temp1,LF_TOP_IN_
	MOV	LF_TOP,Temp1

	LDI	Temp1,LF_TOP_HOLD_
	MOV	LF_HOLD,Temp1

	CLR	LF_COUNT
	OUT	OCR0B,LF_COUNT			; Clear counter and start over
	
	IN	Temp1,TCCR0A
	ANDI	Temp1,~0x30
	ORI	Temp1,LF_IN_MODE_
	OUT	TCCR0A,Temp1			; set fade out mode

	RJMP	RET_TIM0_OVF
