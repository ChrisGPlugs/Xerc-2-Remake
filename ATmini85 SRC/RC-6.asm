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
; Philips RC-6 protocol
;
; The first bit (after the nibble ident byte)
; indicates if it is mode 0 (bit is zero) or
; mode 6 (bit is one). Header is first stored
; in an extra space and once the whole header
; is read we identify the mode and start
; reading the actual data. In the case it is
; mode 6 then the whole customer code is
; read and verified that all the bits are 
; correct but it is ignored. So we take
; NO respect of the customer code. (other than
; that the bimodal coding is correct)
;
; Use the IR_HEAD_RECIEVED flag to indicate
; weather the header has been recieved or not.
; Use IR_RC6_MODE to indicated mode
; (0 = mode 0, 1 = mode 6)
;
; We ignore the first bit in the information
; field on mode6A since MS uses that bit as
; a toggle bit (why not use the toggle bit
; in the header?)
;*****************************************



IR_RC6_START_BIT_END:
	CBR	IR_STATUS,(1<<IR_START)	

	LDI	IR_PROTOCOL,RC6_PROTOCOL_
	MOV	IR_RBUF,IR_PROTOCOL		; store the protocol bits in the recieve buffer

	RCALL	ENABLE_EXT_INT0_FALLING		; enable ext int on falling edge

	RCALL	ENABLE_TIM1_OVF_INT		; enable overflow interrupt to catch
						; problems caused by a single disturbance
						; pulse

	RJMP	RET_INT0


IR_RC6_START_BIT2_END:
	; we start with 8T, so shift twice right to get 2T
	IN	Temp1,TCNT1
	LSR	Temp1
	LSR	Temp1				; we now have 2T here
	MOV	IR_T,Temp1			; store it in its register

	RCALL	LOAD_0T5_IN_TIMER

	CBR	IR_STATUS,(1<<IR_HEAD_RECIEVED)	; the header has not been recieved

	INC	IR_BIT_COUNT			; not the second startbit anymore

	RJMP	RET_INT0

IR_RC6_SYNCH_TIMER:
	CPI	IR_BIT_COUNT,0			; If the bit count is 0 then its
	BREQ	IR_RC6_START_BIT2_END		; the second startbit	

	RCALL	LOAD_0T5_IN_TIMER

	RJMP	RET_INT0


IR_RC6_TIM1_OVF:		
	RCALL	LOAD_T_IN_TIMER

	SBRC	IR_STATUS,IR_CTRL_BIT		; check if it is a "ctrl-bit"
	RJMP	IR_RC6_CTRL_CHECK		; check if the ctrl-bit is OK

	SBR	IR_STATUS,(1<<IR_CTRL_BIT)	; if this bit was not a ctrl bit then
						; the next bit is.
	
IR_RC6_READ_BIT:
	SBIS	PINB,IRD_PIN			 
	RJMP	IR_RC6_BIT_IS_ONE
		 
IR_RC6_BIT_IS_ZERO:
	CBR	IR_STATUS,(1<<READ_IR_BIT)
	
	SBRC	IR_STATUS,IR_HEAD_RECIEVED
	RCALL	IR_STORE_ZERO
	
	SBRS	IR_STATUS,IR_HEAD_RECIEVED
	RCALL	IR_RC6_HEAD_STORE_ZERO
	
	RJMP	RET_TIM1

IR_RC6_BIT_IS_ONE:
	SBR	IR_STATUS,(1<<READ_IR_BIT)
	
	SBRC	IR_STATUS,IR_HEAD_RECIEVED
	RCALL	IR_STORE_ONE
	
	SBRS	IR_STATUS,IR_HEAD_RECIEVED
	RCALL	IR_RC6_HEAD_STORE_ONE
	
	RJMP	RET_TIM1


IR_RC6_CTRL_CHECK:
	CBR	IR_STATUS,(1<<IR_CTRL_BIT)	; next bit is NOT a ctrl bit, since this one was!

	SBRS	IR_STATUS,IR_HEAD_RECIEVED	; to simplify the reading of the longer
	RJMP	IR_RC6_HEAD_CHK_END		; trailer bits we ignore the control check
						; on the header bits (that includes the trailers)

	SBRS	IR_STATUS,READ_IR_BIT
	RJMP	IR_RC6_CTRL_TEST_1

IR_RC6_CTRL_TEST_0:
	SBIS	PINB,IRD_PIN
	SBR	IR_STATUS,(1<<IR_ERROR)

	RJMP	IR_RC6_CHK_END

IR_RC6_CTRL_TEST_1:
	SBIC	PINB,IRD_PIN
	SBR	IR_STATUS,(1<<IR_ERROR)

	RJMP	IR_RC6_CHK_END


IR_RC6_HEAD_STORE_ZERO:
	LDI	Temp2,0x00	; store a zero in the or mask
	RJMP	IR_RC6_HEAD_STORE

IR_RC6_HEAD_STORE_ONE:
	LDI	Temp2,0x01	; store a one in the or mask
	RJMP	IR_RC6_HEAD_STORE


IR_RC6_HEAD_STORE:
	LSL	IR_EXTRA	; shift left
	OR	IR_EXTRA,Temp2	; insert the new bit

	RET


IR_RC6_HEAD_CHK_END:
	INC	IR_BIT_COUNT	

	CPI	IR_BIT_COUNT,7			; check if startbit + mode bits + trailer bits
	BREQ	IR_RC6_HEAD_END

	CPI	IR_BIT_COUNT,8
	BREQ	IR_RC6_CHECK_ADR_EXT

	CPI	IR_BIT_COUNT,24
	BREQ	IR_RC6_HEAD_RECIEVED

	RJMP	RET_TIM1

IR_RC6_HEAD_RECIEVED:
	SBR	IR_STATUS,(1<<IR_HEAD_RECIEVED)
	
	RJMP	RET_TIM1

IR_RC6_HEAD_END:
	; läs av huvet och kolla mode, tänk på att ändra status så att head
	; är läst samt att göra förberedelser för eventuell customer code.
	; måste även lägga till en extra flagga för att indikera vilken mode
	; det är vi arbetar i.	


	MOV	Temp1,IR_EXTRA
	ANDI	Temp1,0x1C
	BRNE	IR_RC6_SET_MODE6	; if not zero then assume mode6

	SBR	IR_STATUS,(1<<IR_HEAD_RECIEVED)	; head is recieved

	RCALL	IR_STORE_ZERO			; write the zero for mode 0

	SUBI	IR_BIT_COUNT,(-16)		; add the non exsisting customer code
						; to the counter

	RJMP	RET_TIM1


IR_RC6_SET_MODE6:
	RCALL	IR_STORE_ONE			; write the one for mode one

	RJMP	RET_TIM1			; thats it for now, we now have to revieve
						; the customer code

IR_RC6_CHECK_ADR_EXT:
	SBRC	IR_STATUS,READ_IR_BIT
	RJMP	RET_TIM1			; if long address do nothing

	SUBI	IR_BIT_COUNT,(-7)		; fake that we have read 7 bits
						; when short addr
	RJMP	RET_TIM1



IR_RC6_CHK_END:
	CPI	IR_BIT_COUNT,38			; If the bit count is 12 then the whole scancode has been	
	BREQ	IR_END_RC6_JMP			; read. Else it's just the end of this bit!

	INC	IR_BIT_COUNT			; increase bit count
	
	RJMP	RET_TIM1


IR_END_RC6_JMP:
	RJMP	IR_END
