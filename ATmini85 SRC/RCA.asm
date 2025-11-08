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
; RCA protocol
;
;*****************************************


IR_RCA_START_BIT_END:
	IN	Temp1,TCNT1			; we now have 8T here
	LSR	Temp1				; so we divide it by 4 
	LSR	Temp1				; and store it as 2T
	MOV	IR_T,Temp1

	RCALL	LOAD_10T_IN_TIMER

	LDI	IR_PROTOCOL,RCA_PROTOCOL_
	MOV	IR_RBUF,IR_PROTOCOL		; store the protocol bits in the recieve buffer

	RCALL	ENABLE_EXT_INT0_FALLING		; enable ext int on falling edge

	SBR	IR_STATUS,(1<<IR_CTRL_BIT)	; next bit is control
	CBR	IR_STATUS,(1<<IR_START)		; next bit is control

	RJMP	RET_INT0

IR_RCA_SYNCH_TIMER:
	RCALL	LOAD_0T5_IN_TIMER

	RJMP	RET_INT0


IR_RCA_TIM1_OVF:
	SBRC	IR_STATUS,IR_CTRL_BIT		; Skip if it is not a ctrl
	RJMP	IR_RCA_CTRL_CHECK

	RJMP	IR_RCA_READ_BIT


IR_RCA_CTRL_CHECK:
	RCALL	LOAD_3T_IN_TIMER

	SBIC	PINB,IRD_PIN			
	SBR	IR_STATUS,(1<<IR_ERROR)		; If we don't have a zero here, then something is wrong	

	CBR	IR_STATUS,(1<<IR_CTRL_BIT)	; done

	RJMP	IR_RCA_END_OF_BIT


IR_RCA_READ_BIT:
	SBIS	PINB,IRD_PIN
	RJMP	IR_RCA_BIT_IS_ZERO			 

	RJMP	IR_RCA_BIT_IS_ONE


IR_RCA_BIT_IS_ZERO:
	RCALL	LOAD_3T_IN_TIMER

	RCALL	IR_STORE_ZERO

	RJMP	IR_RCA_INC_BIT_COUNT


IR_RCA_BIT_IS_ONE:
	RCALL	LOAD_2T_IN_TIMER

	SBR	IR_STATUS,(1<<IR_CTRL_BIT)	; next check is just a ctrl

	RCALL	IR_STORE_ONE

	RJMP	IR_RCA_INC_BIT_COUNT
	

IR_RCA_INC_BIT_COUNT:
	INC	IR_BIT_COUNT

IR_RCA_END_OF_BIT:
	SBRC	IR_STATUS,IR_CTRL_BIT
	RJMP	RET_TIM1

	CPI	IR_BIT_COUNT,24
	BREQ	IR_END_SIRC_JMP

	CPI	IR_BIT_COUNT,12
	BREQ	IR_RCA_RECIEVE_INV

	RJMP	RET_TIM1

IR_END_SIRC_JMP:
	RJMP	IR_END



IR_RCA_RECIEVE_INV:
	SBR	IR_STATUS,(1<<RECIEVING_INV)
	
	RCALL	IR_STORE_BYTE

	LDI	Temp1,RCA_PROTOCOL_
	MOV	IR_RBUF,Temp1			; store the protocol bits in the recieve buffer
	LDI	Temp1,0x34
	MOV	IR_RBUF_COUNT,Temp1

	RJMP	RET_TIM1


IR_RCA_END:
	LDI	ZL,LOW(SRAM_IRCMD_INV_)
	LDI	ZH,HIGH(SRAM_IRCMD_INV_)
	RCALL	IR_COMPARE
	BRTS	IR_RCA_END_END
	
	SBR	IR_STATUS,(1<<IR_ERROR)

IR_RCA_END_END:
	RET
		
