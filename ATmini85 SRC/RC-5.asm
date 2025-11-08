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
; Philips RC-5 protocol
;
;*****************************************



IR_RC5_START_BIT_END:
	CBR	IR_STATUS,(1<<IR_START)	

	LDI	IR_PROTOCOL,RC5_PROTOCOL_
	MOV	IR_RBUF,IR_PROTOCOL		; store the protocol bits in the recieve buffer

	RCALL	ENABLE_EXT_INT0_FALLING		; enable ext int on rising edge

	RCALL	ENABLE_TIM1_OVF_INT		; enable overflow interrupt to catch
						; problems caused by a single disturbance
						; pulse

	RJMP	RET_INT0


IR_RC5_START_BIT2_END:
	IN	Temp1,TCNT1			; we now have 2T here
	MOV	IR_T,Temp1			; store it in its register

	RCALL	LOAD_1T5_IN_TIMER

	SBR	IR_STATUS,(1<<IR_T_BIT)

	INC	IR_BIT_COUNT			; not the second startbit anymore

	RJMP	RET_INT0

IR_RC5_SYNCH_TIMER:
	CPI	IR_BIT_COUNT,0			; If the bit count is 0 then its
	BREQ	IR_RC5_START_BIT2_END		; the second startbit	

	RCALL	LOAD_0T5_IN_TIMER

	RJMP	RET_INT0


IR_RC5_TIM1_OVF:		
	RCALL	LOAD_T_IN_TIMER

	SBRC	IR_STATUS,IR_CTRL_BIT		; check if it is a "ctrl-bit"
	RJMP	IR_RC5_CTRL_CHECK		; check if the ctrl-bit is OK

	SBR	IR_STATUS,(1<<IR_CTRL_BIT)	; if this bit was not a ctrl bit then
						; the next bit is.

	SBRC	IR_STATUS,IR_T_BIT
	RJMP	IR_RC5_TOGGLE_BIT


IR_RC5_READ_BIT:
	SBIC	PINB,IRD_PIN			 
	RJMP	IR_RC5_BIT_IS_ONE
		 
IR_RC5_BIT_IS_ZERO:
	CBR	IR_STATUS,(1<<READ_IR_BIT)
	
	RCALL	IR_STORE_ZERO
	
	RJMP	RET_TIM1

IR_RC5_BIT_IS_ONE:
	SBR	IR_STATUS,(1<<READ_IR_BIT)
	
	RCALL	IR_STORE_ONE
	
	RJMP	RET_TIM1


IR_RC5_CTRL_CHECK:
	CBR	IR_STATUS,(1<<IR_CTRL_BIT)	; next bit is NOT a ctrl bit, since this one was!

	SBRC	IR_STATUS,READ_IR_BIT
	RJMP	IR_RC5_CTRL_TEST_1

IR_RC5_CTRL_TEST_0:
	SBIS	PINB,IRD_PIN
	SBR	IR_STATUS,(1<<IR_ERROR)
	RJMP	IR_RC5_CHK_END

IR_RC5_CTRL_TEST_1:
	SBIC	PINB,IRD_PIN
	SBR	IR_STATUS,(1<<IR_ERROR)
	RJMP	IR_RC5_CHK_END


IR_RC5_TOGGLE_BIT:
	CBR	IR_STATUS,(1<<IR_T_BIT)

	CBR	IR_STATUS,(1<<READ_IR_BIT)	
	SBIC	PINB,IRD_PIN			; sets the read bit value in the statusregister by assuming
	SBR	IR_STATUS,(1<<READ_IR_BIT)	; the bit is zero and if its not it sets it to one

	RCALL	ENABLE_EXT_INT0_FALLING

	RJMP	RET_TIM1


IR_RC5_CHK_END:
	CPI	IR_BIT_COUNT,12			; If the bit count is 12 then the whole scancode has been	
	BREQ	IR_END_RC5_JMP			; read. Else it's just the end of this bit!

	INC	IR_BIT_COUNT			; increase bit count
	
	RJMP	RET_TIM1


IR_END_RC5_JMP:
	RJMP	IR_END
