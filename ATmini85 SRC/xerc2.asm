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



;*******************************************************;
;
;  XERC 2
;  ------ 
;
;  A simple, but advanced, way to add support for 
;  turning on the xbox with a remote control based on
;  the Attiny45 (or attiny85 if more space is needed).
;
;  Currently supports the current protocols:
;   - Sony SIRC-12/15/20bit
;   - Philips RC-5 and RC-6 (partly, see RC-6.asm for more info)
;   - RCA
;
;  Designed and coded by: pablot (xerc@pablot.com)
;
;*******************************************************

;*******************************************************
;
; FUSE SETTINGS
; -------------
;
; The default fuse settings should be used.
;
;*******************************************************

;#define SIMULATION

#define _VERSION_ 	"1.001"			; XERC 2 Version
#define	_BLINK_VERSION_ 0			; What it should blink in Factory Reset

.INCLUDE 	"tn45def.inc"			; Contains standard definitions for 
.INCLUDE	"xerc2.inc"			; Constants to make the code easier to read

;********************************************
;
; Interrupt Vectors
;
;********************************************
.ORG	0x0000
	RJMP	INITIALIZE			; program start vector
.ORG	0x0001 
	RJMP	EXT_INT0			; external interrupt vector
.ORG	0x0004
	RJMP	TIM1_OVF			; timer1 overflow interrupt vector
.ORG	0x0005
	RJMP	TIM0_OVF			; timer0 overflow interrupt vector


.ORG	0x0020

.DB	"XERC 2 V",_VERSION_," | ",\
	"Built: ",__DATE__,0,0


;*****************************************
;
; Code Start
;
;*****************************************
.ORG	0x0040
.INCLUDE	"default_btn_map.asm"		; the default button mapping

.INCLUDE	"RCA.asm"			; the RCA protocol
.INCLUDE	"RC-5.asm"			; the Philips RC-5 protocol
.INCLUDE	"RC-6.asm"			; the Philips RC-6 protocol
.INCLUDE	"SIRC.asm"			; the Sony SIRCS 12-bit protocol

.INCLUDE	"macros.asm"			; Macros

.INCLUDE	"ledfader.asm"			; fader code
.INCLUDE	"dimled.asm"			; dim led code
.INCLUDE	"lp.asm"			; include long pause code
.INCLUDE	"ir.asm"
.INCLUDE	"config_check.asm"
.INCLUDE	"otf_config.asm"



;*********************************************
;
; INITIALATION
;
;*********************************************
INITIALIZE:
	LDI	Temp1,LOW(RAMEND)
	OUT	SPL,Temp1
	LDI	Temp1,HIGH(RAMEND)
	OUT	SPH,Temp1			; init the stackpointer
	CLR	ZERO_REG

	RCALL	INIT_SYSCLK

	RCALL	INIT_MISC			; initialize misc things
	RCALL	INIT_PORTS			; initialize I/O-port

	SEI					; Enable global interrupts	

#ifndef SIMULATION	
						; pause 1.2sec just to make sure
	LP	LP_1S2_,LP_1S2_EXT_		; that every thing is staböe and fine
#endif

	RCALL	READ_IR_CMDS

#ifndef SIMULATION
	RCALL	LONG_BLINK
	RCALL	SHORT_BLINK
#endif

	RCALL	READ_LF_STATUS

	RCALL	LF_START

	RCALL	ENABLE_EXT_INT0_FALLING
	
	RJMP	MAIN	


; setup system clock, set to 4MHz (8MHz/2)
INIT_SYSCLK:
	LDI	Temp1,(1<<CLKPCE)
	OUT	CLKPR,Temp1

	LDI	Temp1,(0<<CLKPCE | 0<<CLKPS3 | 0<<CLKPS2 | 0<<CLKPS1 | 1<<CLKPS0)
	OUT	CLKPR,Temp1

	RET


INIT_MISC:
	CLR	IR_STATUS
	CLR	BTN_COUNT
	CLR	CONF_COUNT
	CLR	XERC_STATUS

	RET


INIT_PORTS:
	LDI	Temp1,(1<<SL_PIN)
	OUT	DDRB,Temp1			; set outputs
			
	LDI	Temp1,(1<<SL_PIN)
	OUT	PORTB,Temp1			; set all the pins to LOW/HIGH-Z

	RET


READ_LF_STATUS:
	LDI	Temp1,EEPROM_DISABLE_LF
	RCALL	READ_EEPROM

	CPI	Temp1,0x5A
	BREQ	NO_LF

	RET


NO_LF:
	SBR	XERC_STATUS,(1<<LF_DISABLE)

	RET


;*********************************************
;
; MAIN LOOP
; ---------
;
; Here the program waits for ir-commands.
;
;*********************************************
MAIN:
	SBRC	XERC_STATUS,NEW_IR_CMD	; checks if a new command has been recieved
	RJMP	CHECK_SCAN_CODE		; else it just keeps looping

	SBIC	PINB,PO_PIN
	RJMP	ON_TASKS


OFF_TASKS:
	SBRS	XERC_STATUS,IN_CONFIG
	RCALL	LF_START

	RJMP	MAIN

ON_TASKS:
	RCALL	LF_STOP
	SBI	PORTB,SL_PIN			; make sure the status led is off

	SBRC	XERC_STATUS,IN_CONFIG		; if configurating then abort
	RJMP	ABORT_CONF			; (since xbox has been turned on)

	SBIS	PINB,PB_PIN			; is the power button beeing pressed?
	RJMP	CHECK_IF_CONFIG

	RJMP	MAIN


;**************************************
;
; CHECK COMMANDS
;
;**************************************

CHECK_SCAN_CODE:
	SBRC	XERC_STATUS,IN_CONFIG
	RJMP	CONFIG_CHECK			; only if we are "in config"

DISCRETE_OFF_CHECK:
	LDI	ZL,LOW(SRAM_IRCMD_DISC_PWR_)	; check if it was the discrete off	
	RCALL	IR_COMPARE			; button that was pressed

	SBIC	PINB,PO_PIN			; only off!
	BRTS	SIM_PWR_BTN			; if T is set then the compare was true

	SBIC	PINB,PO_PIN
	RJMP	SAFE_CMD_CHECK			; check for safe cmd press if xbox is on


;**************************************
;
; CHECK OFF COMMANDS
;
;**************************************
PWR_BTN_CHECK:
	LDI	ZL,LOW(SRAM_IRCMD_PWR_)
	RCALL	IR_COMPARE			; check if short power was pressed

	BRTS	SIM_PWR_BTN_JMP			; if T is set the compare was true

LONG_PWR_BTN_CHECK:
	LDI	ZL,LOW(SRAM_IRCMD_LONG_PWR_)
	RCALL	IR_COMPARE

	BRTS	SIM_LONG_PWR_BTN_JMP

DVD_BTN_CHECK:
	LDI	ZL,LOW(SRAM_IRCMD_DVD_)
	RCALL	IR_COMPARE

	BRTS	SIM_EJECT_BTN_JMP

SMARTXX_OS_CHECK:
	LDI	ZL,LOW(SRAM_IRCMD_SMARTXX_)
	RCALL	IR_COMPARE

	BRTS	SIM_SMARTXX_OS_JMP

SKIP_SCAN_CODE:
	CBR	XERC_STATUS,(1<<NEW_IR_CMD)	; command read so we change the status

	RCALL	ENABLE_EXT_INT0_FALLING		; enable external interrupts so that we
						; can recieve new commands
	
	RJMP	MAIN


SIM_PWR_BTN_JMP:
	RJMP	SIM_PWR_BTN

SIM_LONG_PWR_BTN_JMP:
	RJMP	SIM_LONG_PWR_BTN

SIM_EJECT_BTN_JMP:
	RJMP	SIM_EJECT_BTN

SIM_SMARTXX_OS_JMP:
	RJMP	SIM_SMARTXX_OS

RETURN_FROM_CMD_JMP:
	RJMP	RETURN_FROM_CMD


;*******************************************
;
; Safe Command
;
;*******************************************
SAFE_CMD_CHECK:
;address
	LDI	ZL,LOW(SRAM_IRCMD_OLD_)
	RCALL	IR_COMPARE			; check if same button as last time is pressed	
	BRTC	CLEAR_SAFE_COUNT		; if not then clear the counter
	
	INC	BTN_COUNT			; increse number of times button has been
						; pressed
	
	CPI	BTN_COUNT,SAFE_COUNT_		; check if recieved enough times
	BRNE	RETURN_FROM_CMD_JMP		; if not then return from this command

	CLR	BTN_COUNT			; clear the counter (comand has been recieved)

	RJMP	SAFE_CMDS


CLEAR_SAFE_COUNT:
	CLR	BTN_COUNT
	RJMP	RETURN_FROM_CMD


;********************************************
;
; Valid Safe Commands
;
;********************************************
SAFE_CMDS:
SAFE_PWR_BTN_CHECK:
	LDI	ZL,LOW(SRAM_IRCMD_PWR_)	
	RCALL	IR_COMPARE			; check for short pwr

	BRTS	SIM_PWR_BTN_JMP			; if T is set then the compare was true


SAFE_LONG_PWR_BTN_CHECK:
	LDI	ZL,LOW(SRAM_IRCMD_LONG_PWR_)
	RCALL	IR_COMPARE

	BRTS	SIM_PWR_BTN_JMP


SAFE_DVD_BTN_CHECK:
	LDI	ZL,LOW(SRAM_IRCMD_DVD_)
	RCALL	IR_COMPARE

	BRTS	SIM_EJECT_BTN_JMP

; No more valid safe buttons
	RJMP	RETURN_FROM_CMD


;********************************************
;
; Button press simulations
;
;********************************************
SIM_PWR_BTN:
	SBI	DDRB,PB_PIN			; drive the pwr button low and then
	LP	LP_BTN_,LP_BTN_EXT_		; wait a standard short button press time

	CBI	DDRB,PB_PIN			; return to HIGH-Z again
	LP	LP_CMD_,LP_CMD_EXT_		; wait a standard command time

	RJMP	RETURN_FROM_CMD


SIM_EJECT_BTN:
	SBI	DDRB,EB_PIN			; drive the DVD button low and then
	LP	LP_BTN_,LP_BTN_EXT_		; wait a standard short button press time
	
	CBI	DDRB,EB_PIN			; return to HIGH-Z again
	LP	LP_CMD_,LP_CMD_EXT_		; wait a standard command time

	RJMP	RETURN_FROM_CMD


SIM_SMARTXX_OS:
	SBI	DDRB,PB_PIN			; drive the pwr button low and then
	LP	LP_BTN_,LP_BTN_EXT_		; wait a standard short button press time
	
	CBI	DDRB,PB_PIN			; return to HIGH-Z again
	LP	LP_SMARTXX_,LP_SMARTXX_EXT_	; wait 0.8s

	SBI	DDRB,EB_PIN			; drive the DVD button low and then
	LP	LP_BTN_,LP_BTN_EXT_		; wait a standard short button press time
	
	CBI	DDRB,EB_PIN			; return to HIGH-Z again
	LP	LP_CMD_,LP_CMD_EXT_		; wait a standard command time

	RJMP	RETURN_FROM_CMD


SIM_LONG_PWR_BTN:
	SBI	DDRB,PB_PIN			; drive the pwr button low and then
	LP	LP_1S2_,LP_1S2_EXT_		; wait 1.2s
	
	CBI	DDRB,PB_PIN			; return to HIGH-Z again
	LP	LP_CMD_,LP_CMD_EXT_		; wait a standard command time

	RJMP	RETURN_FROM_CMD


RETURN_FROM_CMD:
	LDI	ZL,LOW(SRAM_IRCMD_OLD_)
	RCALL	COPY_CURRENT_BTN		; store the last pressed buttons

	CBR	XERC_STATUS,(1<<NEW_IR_CMD)	; command read so we change the status

	RCALL	ENABLE_EXT_INT0_FALLING		; get ready to accept new commands

	RJMP	MAIN


;*******************************
;
; Help functions
;
;*******************************
ENABLE_EXT_INT0_FALLING:
	PUSH	Temp1

	IN	Temp1,MCUCR
	SBR	Temp1,(1<<ISC01)
	CBR	Temp1,(1<<ISC00)
	OUT	MCUCR,Temp1			; Set external interrupt to trigger on falling edge

	SER	Temp1
	OUT	GIFR,Temp1			; clear INTF0

	LDI	Temp1,(1<<INT0)
	OUT	GIMSK,Temp1			; enable external interrupts

	POP	Temp1
	RET
	
ENABLE_EXT_INT0_RISING:
	PUSH	Temp1

	IN	Temp1,MCUCR
	SBR	Temp1,(1<<ISC01)
	SBR	Temp1,(1<<ISC00)
	OUT	MCUCR,Temp1			; Set external interrupt to trigger on rising edge

	SER	Temp1
	OUT	GIFR,Temp1			; clear INTF0

	LDI	Temp1,(1<<INT0)
	OUT	GIMSK,Temp1			; enable external interrupts

	POP	Temp1
	RET

ENABLE_TIM0_OVF_INT:
	PUSH	Temp1

	SBR	Temp1,(1<<TOV0)
	OUT	TIFR,Temp1			; clear TOV1 (interrupt flag)

	IN	Temp1,TIMSK
	SBR	Temp1,(1<<TOIE0)
	OUT	TIMSK,Temp1			; Enable TCNT1 interrupt

	POP	Temp1
	RET

DISABLE_TIM0_OVF_INT:
	PUSH	Temp1

	SBR	Temp1,(1<<TOV0)
	OUT	TIFR,Temp1			; clear TOV1 (interrupt flag)

	IN	Temp1,TIMSK
	CBR	Temp1,(1<<TOIE0)
	OUT	TIMSK,Temp1			; Disable TCNT1 interrupt

	POP	Temp1
	RET

ENABLE_TIM1_OVF_INT:
	PUSH	Temp1

	SBR	Temp1,(1<<TOV1)
	OUT	TIFR,Temp1			; clear TOV1 (interrupt flag)

	IN	Temp1,TIMSK
	SBR	Temp1,(1<<TOIE1)
	OUT	TIMSK,Temp1			; Enable TCNT1 interrupt

	POP	Temp1
	RET

DISABLE_TIM1_OVF_INT:
	PUSH	Temp1

	SBR	Temp1,(1<<TOV1)
	OUT	TIFR,Temp1			; clear TOV1 (interrupt flag)

	IN	Temp1,TIMSK
	CBR	Temp1,(1<<TOIE1)
	OUT	TIMSK,Temp1			; Disable TCNT1 interrupt

	POP	Temp1
	RET



FACTORY_RESET_XERC:
	OUT	GIMSK,ZERO_REG			; disable external interupts

	RCALL	COPY_DEFAULT_IR_CMD		; write default config to eeprom
	
	LDI	EEPROM_DATA,0x00
	LDI	EEPROM_ADDR,EEPROM_DISABLE_LF
	RCALL	WRITE_EEPROM			; LF is on by default

FR_LOOP:
	LP	LP_FR_PAUSE_,LP_FR_PAUSE_EXT_	; pause

	LDI	Temp1,_BLINK_VERSION_
	RCALL	BINARY_BLINK

	RJMP	FR_LOOP				; halt in this loop

	

BINARY_BLINK:
;first we want to turn the 3bit number around so that we display msb first
	CLR	Temp2

	LSR	Temp1				; shift lsb into C
	ROL	Temp2				; shift C into Temp2
	
	LSR	Temp1
	ROL	Temp2
	
	LSR	Temp1				; shift msb into C
	ROL	Temp2				; shift C into Temp2	
	
	LDI	Temp1,3
	MOV	BLINK_COUNT,Temp1		; loop 3 times 			

BINARY_BLINK_LOOP:
	LSR	Temp2				; shift bit into C
	
	BRCS	BINARY_BLINK_LONG		; If a one then blink long, else blink short

	RCALL	SHORT_BLINK
	RJMP	BINARY_BLINK_CHECK_END
	
BINARY_BLINK_LONG:
	RCALL	LONG_BLINK

BINARY_BLINK_CHECK_END:
	DEC	BLINK_COUNT
	BRNE	BINARY_BLINK_LOOP

	RET



LONG_BLINK:
	PUSH	Temp1
	
	LP	LP_BLINK_PAUSE_,LP_BLINK_PAUSE_EXT_	; pause

	CBI	PORTB,SL_PIN			; turn on diode
	RCALL	DIM_LED_FULL			; do it for dim too

	LP	LP_BLINK_LONG_,LP_BLINK_LONG_EXT_	; pause

	SBI	PORTB,SL_PIN			; turn off diode 
	RCALL	DIM_LED_DIM			; do it for dim too

	POP	Temp1
	RET

SHORT_BLINK:
	PUSH	Temp1

	LP	LP_BLINK_PAUSE_,LP_BLINK_PAUSE_EXT_	; pause

	CBI	PORTB,SL_PIN			; turn on diode
	RCALL	DIM_LED_FULL			; do it for dim too

	LP	LP_BLINK_SHORT_,LP_BLINK_SHORT_EXT_	; pause

	SBI	PORTB,SL_PIN			; turn off diode
	RCALL	DIM_LED_DIM			; do it for dim too

	POP	Temp1
	RET




; compare a stored command to the lates recieved one
IR_COMPARE:
	LD	Temp1,Z+
	LD	Temp2,Z+
	LD	Temp3,Z+

	CLR	ZH
	LDI	ZL,LOW(SRAM_IRCMD_CURRENT_)

	LD	Temp4,Z+
	CP	Temp1,Temp4
	BRNE	IR_NOT_EQUAL
	
	LD	Temp4,Z+
	CP	Temp2,Temp4
	BRNE	IR_NOT_EQUAL

	LD	Temp4,Z+
	CP	Temp3,Temp4
	BRNE	IR_NOT_EQUAL
	
	SET					; set T flag
	RET

IR_NOT_EQUAL:
	CLT					; clear T flag
	RET




;preload Z with destination
COPY_CURRENT_BTN:
	PUSH	ZL
	
	CLR	ZH
	LDI	ZL,LOW(SRAM_IRCMD_CURRENT_)

	LD	Temp1,Z+
	LD	Temp2,Z+
	LD	Temp3,Z+

	POP	ZL

	ST	Z+,Temp1
	ST	Z+,Temp2
	ST	Z+,Temp3

	RET



READ_IR_CMDS:
	CLR	ZH
	LDI	ZL,SRAM_START_

READ_IR_CMDS_LOOP:
	MOV	Temp1,ZL			; set eeprom address
	SUBI	Temp1,SRAM_START_		; remove the displacement in the address
	RCALL	READ_EEPROM			; read data
	ST	Z+,Temp1			; store data in sram and inc pointer

	CPI	ZL,(SRAM_START + 3 * NUMBER_OF_CMDS_)
						; compare pointer to number of commands
	BRNE	READ_IR_CMDS_LOOP 		; if not finnished, then read another one
	
	RET

STORE_IR_CMDS:
	CLR	ZH
	LDI	ZL,SRAM_START_

STORE_IR_CMDS_LOOP:
	MOV	EEPROM_ADDR,ZL			; set eeprom address
	SUBI	EEPROM_ADDR,SRAM_START_		; remove the displacement in the address
	LD	EEPROM_DATA,Z+			; read data from sram and inc pointer
	RCALL	WRITE_EEPROM			; store data in eeprom

	CPI	ZL,(SRAM_START_ + 3 * NUMBER_OF_CMDS_)
						; compare pointer to number of commands
	BRNE	STORE_IR_CMDS_LOOP 		; if not finnished, then read another one
	
	RET


COPY_DEFAULT_IR_CMD:
	LDI	ZH,HIGH(DEFAULT_BTN_MAP*2)
	LDI	ZL,LOW(DEFAULT_BTN_MAP*2)
	CLR	EEPROM_ADDR

COPY_DEFAULT_IR_CMDS_LOOP:
	LPM	EEPROM_DATA,Z+
	RCALL	WRITE_EEPROM

	INC	EEPROM_ADDR

	CPI	EEPROM_ADDR,(NUMBER_OF_CMDS_*3)	; 3 bytes per cmd
	BRNE	COPY_DEFAULT_IR_CMDS_LOOP
	
	RET



CLR_OLD_IR_CMDS:
	CLR	Temp1
	CLR	ZH
	LDI	ZL,SRAM_START_

CLR_OLD_IR_CMDS_LOOP:
	ST	Z+,Temp1

	CPI	ZL,(SRAM_START_ + 2 * NUMBER_OF_CMDS_)
						; compare pointer to number of commands
	BRNE	CLR_OLD_IR_CMDS_LOOP 		; if not finnished, then clear another one

	RET
	

WRITE_EEPROM:
EEPROM_WRITE_WAIT:
	CLI

	SBIC	EECR,EEPE
	RJMP	EEPROM_WRITE_WAIT		; wait for write enable

	LDI	Temp1, (0<<EEPM1)|(0<<EEPM0)
	OUT	EECR, Temp1			; Set Programming mode (erase and write)

;	OUT	EEARH,EEPROM_ADDRH		; load address (high)
	CLR	Temp1
	OUT	EEARH,Temp1			; only use the lower 256 eeprom bytes

	OUT	EEARL,EEPROM_ADDR		; load address (low)
	OUT	EEDR,EEPROM_DATA		; load data

	SBI	EECR,EEMPE			; master write enable
	SBI	EECR,EEPE			; write enable

	SEI
	RET

; address in Temp1, read data is returned in temp1
READ_EEPROM:
EEPROM_READ_WRITE_WAIT:
	CLI

	SBIC	EECR,EEPE
	RJMP	EEPROM_READ_WRITE_WAIT		; wait for possible write write operation to finish
	
	CLR	Temp2
	OUT	EEARH,Temp2			; only use lower 256 bytes of the eeprom
	OUT	EEARL,Temp1			; load address

	SBI	EECR,EERE			; read enable

	IN	Temp1,EEDR			; store the data

	SEI
	RET



;************************************************
;
; EXT_INT0
;
;************************************************

EXT_INT0:
	PUSH	Temp1
	PUSH	Temp2
	PUSH	Temp3
	PUSH	Temp4
	IN	Temp1,SREG
	PUSH	Temp1

	RJMP	IR_EXT_INT0


RET_INT0:
	SER	Temp1
	OUT	GIFR,Temp1			; clear INTF0

	POP	Temp1
	OUT	SREG,Temp1
	POP	Temp4
	POP	Temp3
	POP	Temp2
	POP	Temp1
	RETI


;************************************************
;
; TIM1_OVF
;
;************************************************

TIM1_OVF:	
	PUSH	Temp1
	PUSH	Temp2
	PUSH	Temp3
	PUSH	Temp4
	IN	Temp1,SREG
	PUSH	Temp1

;LONGPAUSE******
	SBRC	XERC_STATUS,IN_LONG_PAUSE
	RJMP	LONG_PAUSE_INT

	SBRC	XERC_STATUS,CHECK_CONFIG
	RJMP	LONG_PAUSE_INT
;***************
	
	RJMP	IR_TIM1_OVF


RET_TIM1:
	SBR	Temp1,(1<<TOV1)
	OUT	TIFR,Temp1			; clear TOV1

	POP	Temp1
	OUT	SREG,Temp1
	POP	Temp4
	POP	Temp3
	POP	Temp2
	POP	Temp1
	RETI

