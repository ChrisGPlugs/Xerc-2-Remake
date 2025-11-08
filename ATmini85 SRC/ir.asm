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


;***********************************************
;
; IR related stuff
;
;***********************************************

IR_EXT_INT0:
	SBRC	IR_STATUS,IR_START	; if startbit
	RJMP	IR_START_BIT_END

	SBRC	IR_STATUS,RECIEVING_IR
	RJMP	IR_SYNCH_TIMER		; if resynch

	RCALL	IR_INIT_NEW

; now lets synch to the start pulse. So set the timer prescaler and start the timer. Then when
; the whole start pulse is recieved we measure the lenght of it and synch to it.		
	LDI	Temp1,(IR_PRESCALER_)
	OUT	TCCR1,Temp1			; configure the prescaler

	IN	Temp1,GTCCR
	ORI	Temp1,(1<<PSR1)
	OUT	GTCCR,Temp1			; reset the prescaler
			
	CLR	Temp1				; 
	OUT	TCNT1,Temp1			; clear the timer

	RCALL	ENABLE_TIM1_OVF_INT		; enable overflow interrupt to catch
						; problems caused by very short disturbance
						; pulses

	SBR	IR_STATUS,(1<<IR_START)		; We are now recieving the start bit (pulse)
	SBR	IR_STATUS,(1<<RECIEVING_IR)

	RCALL	ENABLE_EXT_INT0_RISING		; enable ext int on rising edge

	RJMP	RET_INT0



IR_TIM1_OVF:
	SBRC	IR_STATUS,IR_START		; if waiting for the startbit and getting an
	RJMP	IR_FAULTY_SIGNAL		; overflow then something has gone wrong

	SBRC	IR_PROTOCOL,RC6_PROTOCOL_BIT_
	RJMP	IR_RC6_TIM1_OVF

	SBRC	IR_PROTOCOL,RCA_PROTOCOL_BIT_
	RJMP	IR_RCA_TIM1_OVF

	SBRC	IR_PROTOCOL,SIRCS_PROTOCOL_BIT_
	RJMP	IR_SIRCS_TIM1_OVF

	RJMP	IR_RC5_TIM1_OVF

IR_SYNCH_TIMER:
	SBRC	IR_PROTOCOL,RC6_PROTOCOL_BIT_
	RJMP	IR_RC6_SYNCH_TIMER
	
	SBRC	IR_PROTOCOL,RCA_PROTOCOL_BIT_
	RJMP	IR_RCA_SYNCH_TIMER

	SBRC	IR_PROTOCOL,SIRCS_PROTOCOL_BIT_
	RJMP	IR_SIRCS_SYNCH_TIMER

	RJMP	IR_RC5_SYNCH_TIMER


IR_START_BIT_END:
	IN	Temp1,TCNT1

	RCALL	DISABLE_TIM1_OVF_INT		; we recieved the rising edge so we dont
						; want this on any more

	SBRC	XERC_STATUS,IN_CONFIG
	RCALL	DIM_LED_CLEAR			; flicker led if in config

	CPI	Temp1,RCA_START_LENGTH_
	BRSH	IR_RCA_START_BIT_END_JMP

	CPI	Temp1,RC6_START_LENGTH_
	BRSH	IR_RC6_START_BIT_END_JMP

	CPI	Temp1,SIRCS_START_LENGTH_
	BRSH	IR_SIRCS_START_BIT_END_JMP

	RJMP	IR_RC5_START_BIT_END

IR_RC6_START_BIT_END_JMP:
	RJMP	IR_RC6_START_BIT_END

IR_RCA_START_BIT_END_JMP:
	RJMP	IR_RCA_START_BIT_END

IR_SIRCS_START_BIT_END_JMP:
	RJMP	IR_SIRCS_START_BIT_END

IR_INIT_NEW:
	CLR	IR_BIT_COUNT
	CLR	IR_RBUF
	CLR	IR_STATUS			; clears the registers

	LDI	Temp1,0x04			; The first four bits in the first
	MOV	IR_RBUF_COUNT,Temp1		; byte i the protocol identifier

	CLR	ZH
	LDI	ZL,LOW(SRAM_IRCMD_CURRENT_)
	CLR	Temp1
	ST	Z+,Temp1
	ST	Z+,Temp1
	ST	Z+,Temp1			; clear destination
	ST	Z+,Temp1
	ST	Z+,Temp1
	ST	Z+,Temp1			; clear inv destination

	RET



IR_STORE_ZERO:
	SBRC	IR_STATUS,RECIEVING_INV
	RJMP	IR_STORE_ONE_PASS

IR_STORE_ZERO_PASS:
	LSL	IR_RBUF
	RJMP	IR_STORE_BIT

IR_STORE_ONE:
	SBRC	IR_STATUS,RECIEVING_INV
	RJMP	IR_STORE_ZERO_PASS

IR_STORE_ONE_PASS:
	LSL	IR_RBUF
	INC	IR_RBUF

IR_STORE_BIT:
	INC	IR_RBUF_COUNT
	
	MOV	Temp1,IR_RBUF_COUNT
	ANDI	Temp1,0x07
	BREQ	IR_STORE_BYTE
	
	RET

IR_STORE_BYTE:
	MOV	Temp1,IR_RBUF_COUNT
	LSR	Temp1
	LSR	Temp1
	LSR	Temp1				; shift the byte counter bit into place	
	LSR	Temp1				

	CLR	ZH
	LDI	ZL,LOW(SRAM_IRCMD_CURRENT_)
	ADD	ZL,Temp1

	ST	Z,IR_RBUF

	LDI	Temp1,0x10
	ADD	IR_RBUF_COUNT,Temp1
	LDI	Temp1,0xF0
	AND	IR_RBUF_COUNT,Temp1

	CLR	IR_RBUF

	RET


IR_STORE_REMAINING_BYTE:
	LSL	IR_RBUF
	INC	IR_RBUF_COUNT	
	MOV	Temp1,IR_RBUF_COUNT	; if the RBUF bit count > 7 then a whole
	ANDI	Temp1,0x07		; byte has been recieved. Store this into
	BRNE	IR_STORE_REMAINING_BYTE	; sram.

	RCALL	IR_STORE_BYTE

	RET


IR_RCA_END_JMP:
	RJMP	IR_RCA_END

	
IR_END:
	RCALL	IR_STORE_REMAINING_BYTE
	
	SBRC	XERC_STATUS,IN_CONFIG
	RCALL	DIM_LED_DIM			; flicker led if in config

	RCALL	DISABLE_TIM1_OVF_INT		; Disable TCNT1 interrupt

	CBR	IR_STATUS,(1<<RECIEVING_IR)

	SBRC	IR_PROTOCOL,RCA_PROTOCOL_BIT_
	RCALL	IR_RCA_END

	SBRC	IR_STATUS,IR_ERROR		; if there was an error in the signal
	RJMP	IR_ERROR_HANDLER		; then jump to the error handler	

	RCALL	IR_SUCCESS

	RJMP	RET_TIM1
		

IR_ERROR_HANDLER:
	CLR	IR_STATUS

	RCALL	ENABLE_EXT_INT0_FALLING

	RJMP	RET_TIM1


IR_SUCCESS:
	SBR	XERC_STATUS,(1<<NEW_IR_CMD)	; new command stored

	CLR	Temp1
	OUT	GIMSK,Temp1			; Dissable external interrupts
	
	RET

IR_FAULTY_SIGNAL:
	SBR	IR_STATUS,(1<<IR_ERROR)

	RJMP	IR_END

;preload temp2
RESTART_IR_TIMER:
	LDI	Temp1,0xFF
	SUB	Temp1,Temp2
	OUT	TCNT1,Temp1

	LDI	Temp1,(IR_PRESCALER_)
	OUT	TCCR1,Temp1			; configure the prescaler, and reset it

	IN	Temp1,GTCCR
	ORI	Temp1,(1<<PSR1)
	OUT	GTCCR,Temp1			; reset the prescaler

	RCALL	ENABLE_TIM1_OVF_INT

	RET


LOAD_0T5_IN_TIMER:
	MOV	Temp2,IR_T
	LSR	Temp2
	LSR	Temp2

	RJMP	RESTART_IR_TIMER


LOAD_T_IN_TIMER:
	MOV	Temp2,IR_T
	LSR	Temp2

	RJMP	RESTART_IR_TIMER


LOAD_1T5_IN_TIMER:
	MOV	Temp2,IR_T
	LSR	Temp2
	MOV	Temp3,Temp2
	LSR	Temp2
	ADD	Temp2,Temp3

	RJMP	RESTART_IR_TIMER


LOAD_2T_IN_TIMER:
	MOV	Temp2,IR_T

	RJMP	RESTART_IR_TIMER


LOAD_3T_IN_TIMER:
	MOV	Temp2,IR_T			
	LSR	Temp2
	ADD	Temp2,IR_T
	
	RJMP	RESTART_IR_TIMER

LOAD_10T_IN_TIMER:
	MOV	Temp2,IR_T			
	LSL	Temp2
	LSL	Temp2
	ADD	Temp2,IR_T
	
	RJMP	RESTART_IR_TIMER
