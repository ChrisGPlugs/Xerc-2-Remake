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


;*******************************
;
; XERC-On-the-fly configuration
;
;*******************************
CONFIG_CHECK:
	LDI	ZL,LOW(SRAM_IRCMD_OLD_)
	RCALL	IR_COMPARE

	BRTS	CONFIG_CMD_OK		; if T is set then the compare was true

	RJMP	CONFIG_NEW_BTN

	
CONFIG_NEW_BTN:
	CLR	BTN_COUNT			; clear the number of times the button has been recieved
	
	RJMP	RETURN_FROM_CMD


CONFIG_CMD_OK:
	INC	BTN_COUNT

	CPI	BTN_COUNT,BTN_COUNT_		; check if the button has been recieved
	BREQ	NEW_BTN_ACCEPTED		; enough times in a row

	RJMP	RETURN_FROM_CMD


NEW_BTN_ACCEPTED:
	CPI	CONF_COUNT,SKIP_BTN_
	BREQ	STORE_SKIP_BTN
	
	CPI	CONF_COUNT,DISABLE_LF_
	BREQ	CHECK_DISABLE_LF				

STORE_NEW_BUTTON:
	LDI	ZL,LOW(SRAM_IRCMD_SKIP_)
	RCALL	IR_COMPARE

	BRTS	SKIP_IRCMD			; if ignore then ignore this button
SKIP_RETURN:
	
	CLR	ZH
	MOV	ZL,CONF_COUNT			; we use CONF_COUNT to calculate the
	SUBI	ZL,1				; sram address. Since each command
	MOV	Temp1,ZL
	LSL	ZL				; needs three bytes in the sram we multiply
	ADD	ZL,Temp1
	LDI	Temp1,SRAM_START_		; by three (shift left = mult by 2)
	ADD	ZL,Temp1			; and then add the sram ofset
						
	RCALL	COPY_CURRENT_BTN

	MOV	Temp1,CONF_COUNT
	RCALL	BINARY_BLINK			; blink the led

	RJMP	RETURN_FROM_NEW_BTN


ENTER_CONFIG:	
	RCALL	CLR_OLD_IR_CMDS
	
	RCALL	DIM_LED_ON

	RET

STORE_SKIP_BTN:
	LDI	ZL,LOW(SRAM_IRCMD_SKIP_)
	RCALL	COPY_CURRENT_BTN
		
	MOV	Temp1,CONF_COUNT		
	RCALL	BINARY_BLINK			; blink the led
	
	RJMP	RETURN_FROM_NEW_BTN

CHECK_DISABLE_LF:
	LDI	ZL,LOW(SRAM_IRCMD_SKIP_)
	RCALL	IR_COMPARE			; if it is the skip button then dissable
	BRTS	DISABLE_LF			; the fader

ENABLE_LF:
	CBR	XERC_STATUS,(1<<LF_DISABLE)

	LDI	EEPROM_ADDR,EEPROM_DISABLE_LF
	LDI	EEPROM_DATA,0x00
	RCALL	WRITE_EEPROM

	RJMP	RETURN_FROM_NEW_BTN


DISABLE_LF:
	SBR	XERC_STATUS,(1<<LF_DISABLE)

	LDI	EEPROM_ADDR,EEPROM_DISABLE_LF
	LDI	EEPROM_DATA,0x5A
	RCALL	WRITE_EEPROM

	RJMP	RETURN_FROM_NEW_BTN


ABORT_CONF:
	RCALL	READ_IR_CMDS

	RJMP	END_OF_CONF_ABORT

END_OF_CONF:
	LDI	Temp1,0x0F
	RCALL	BINARY_BLINK

END_OF_CONF_ABORT:
	CLR	BTN_COUNT
	CLR	CONF_COUNT
	CBR	XERC_STATUS,(1<<IN_CONFIG)

	RCALL	STORE_IR_CMDS

	RCALL	DIM_LED_OFF
	RCALL	LF_START

	RJMP	RETURN_FROM_CMD


SKIP_IRCMD:
	CLR	ZH
	LDI	ZL,LOW(SRAM_IRCMD_CURRENT_)
	CLR	Temp1
	ST	Z+,Temp1
	ST	Z+,Temp1
	ST	Z+,Temp1
	
	RJMP	SKIP_RETURN



RETURN_FROM_NEW_BTN:
	CPI	CONF_COUNT,LAST_BUTTON_
	BREQ	END_OF_CONF
	
	CLR	ZH
	LDI	ZL,LOW(SRAM_IRCMD_CURRENT_)
	CLR	Temp1
	ST	Z+,Temp1
	ST	Z+,Temp1
	ST	Z+,Temp1

	CLR	BTN_COUNT

	INC	CONF_COUNT
	
	RJMP	RETURN_FROM_CMD