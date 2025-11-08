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



;*****************************************
;
; Sony SIRC 12/15/20-bit protocol
;
;*****************************************


IR_SIRCS_START_BIT_END:
	IN	Temp1,TCNT1			; we now have 4T here
	LSR	Temp1				; so we divide it by 2 to get 2T
	MOV	IR_T,Temp1			; store it in its register

	RCALL	LOAD_1T5_IN_TIMER

	LDI	IR_PROTOCOL,SIRCS_PROTOCOL_
	MOV	IR_RBUF,IR_PROTOCOL		; store the protocol bits in the recieve buffer

	RCALL	ENABLE_EXT_INT0_FALLING		; enable ext int on rising edge

	SBR	IR_STATUS,(1<<IR_CTRL_BIT)	; next bit is control
	CBR	IR_STATUS,(1<<IR_START)		; next bit is control

	RJMP	RET_INT0

IR_SIRCS_SYNCH_TIMER:
	RCALL	LOAD_0T5_IN_TIMER
	
	RJMP	RET_INT0	


IR_SIRCS_TIM1_OVF:	
	RCALL	LOAD_T_IN_TIMER	

	SBRC	IR_STATUS,IR_ONE_CTRL_BIT	; Skip if it is not a ctrl
	RJMP	IR_SIRCS_ONE_CTRL_CHECK

	SBRC	IR_STATUS,IR_CTRL_BIT		; Skip if it is not a ctrl
	RJMP	IR_SIRCS_CTRL_CHECK

	RJMP	IR_SIRCS_READ_BIT		; else it's a command bit


IR_SIRCS_CTRL_CHECK:
	CBR	IR_STATUS,(1<<IR_CTRL_BIT)	; done

	SBIC	PINB,IRD_PIN
	RJMP	IR_SIRCS_CHECK_IF_CORRECT_END	; If we don't have a zero here, 
						; then there is a error in the signal
						; check if it is the end of the transmision
						; or a real error	

	RJMP	RET_TIM1


IR_SIRCS_ONE_CTRL_CHECK:
	SBIS	PINB,IRD_PIN			
	SBR	IR_STATUS,(1<<IR_ERROR)		; If we don't have a one here, then something is wrong	

	CBR	IR_STATUS,(1<<IR_ONE_CTRL_BIT)	; done
	SBR	IR_STATUS,(1<<IR_CTRL_BIT)	; next is a normal control bit

	RJMP	RET_TIM1


IR_SIRCS_READ_BIT:
	SBIS	PINB,IRD_PIN
	RJMP	IR_SIRCS_BIT_IS_ONE			 
	
	RJMP	IR_SIRCS_BIT_IS_ZERO



IR_SIRCS_BIT_IS_ZERO:
	SBR	IR_STATUS,(1<<IR_CTRL_BIT)	; next check is just a ctrl

	RCALL	IR_STORE_ZERO

	RJMP	IR_SIRCS_INC_BIT_COUNT


IR_SIRCS_BIT_IS_ONE:
	SBR	IR_STATUS,(1<<IR_ONE_CTRL_BIT)	; next check is a "one ctrl" bit

	RCALL	IR_STORE_ONE

	RJMP	IR_SIRCS_INC_BIT_COUNT
	

IR_SIRCS_INC_BIT_COUNT:
	INC	IR_BIT_COUNT

	RJMP	RET_TIM1

; Check if the error in the signal is caused by the end of a transmission.
; If it there is a error (only normal ctrl check) on the 12, 15 or 20th bit
; then it is a correct signal (those are the three valid sircs length).
IR_SIRCS_CHECK_IF_CORRECT_END:
	CPI	IR_BIT_COUNT,12
	BREQ	IR_END_SIRCS_JMP

	CPI	IR_BIT_COUNT,15
	BREQ	IR_END_SIRCS_JMP

	CPI	IR_BIT_COUNT,20
	BREQ	IR_END_SIRCS_JMP

	SBR	IR_STATUS,(1<<IR_ERROR)	; if none of the above lenght then there
					; is an error

	RJMP	RET_TIM1


IR_END_SIRCS_JMP:
	RJMP	IR_END

