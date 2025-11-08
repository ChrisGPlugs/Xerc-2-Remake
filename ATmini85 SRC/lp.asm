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
; LONG PAUSE
;
; Long pause uses timer1, so it can only
; be used when NOT recieving a IR-Signal
; We are using the full 14 bit prescaler
; so that gives that it takes the timer
; 0.25 * 16384 * 256 = 1.048576s to fill.
; This is not quite enough so by seting
; the EXTENDED_LP0,1 flags it waits the 
; full 1.04876 seconds times the 2-bit 
; binary number stored in XERC_STATUS 
; seconds plus the value  specified in 
; the LP_REG register
;**************************************
LONG_PAUSE:
	SER	Temp1
	SUB	Temp1,LP_REG
	OUT	TCNT1,Temp1

	LDI	Temp1,0b00001111
	OUT	TCCR1,Temp1			; Start TCNT1 ith a full 14bit prescaler

	IN	Temp1,GTCCR
	ORI	Temp1,(1<<PSR1)
	OUT	GTCCR,Temp1	
		
	RCALL	ENABLE_TIM1_OVF_INT

	SBRC	XERC_STATUS,CHECK_CONFIG	; If checking for config then its not the
	RET					; normal LP!
	
	SBR	XERC_STATUS,(1<<IN_LONG_PAUSE)	; LP pause in progress!

PAUSE_HOLD:
	SBRC	XERC_STATUS,IN_LONG_PAUSE	; Pause while LP is in progress
	RJMP	PAUSE_HOLD

	RET
LONG_PAUSE_INT:
	MOV	Temp1,XERC_STATUS
	ANDI	Temp1,EXTENDED_LP_MASK_
	BREQ	END_LONG_PAUSE

	SUBI	XERC_STATUS,EXTENDED_LP_BIT_
	
	CLR	Temp1
	OUT	TCNT1,Temp1

	IN	Temp1,TIFR
	SBR	Temp1,(1<<TOV1)
	OUT	TIFR,Temp1			; clear TOV1 (by writing 1 to it) (interrupt flag)

	RJMP	RETURN_FROM_LP

END_LONG_PAUSE:
	CBR	XERC_STATUS,(1<<IN_LONG_PAUSE)	; LP not in progress anymore
	CBR	XERC_STATUS,(1<<CHECK_CONFIG)

	RCALL	DISABLE_TIM1_OVF_INT

	RJMP	RETURN_FROM_LP


RETURN_FROM_LP:
	POP	Temp1
	OUT	SREG,Temp1
	POP	Temp4
	POP	Temp3
	POP	Temp2
	POP	Temp1

	RETI
