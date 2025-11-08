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
; XERC 2 Definitions
;
;***********************************************

.EQU	BTN_COUNT_		= 12

.EQU	SAFE_COUNT_		= 50

.EQU	IR_PRESCALER_		= 0x08

.EQU	SRAM_START_		= 0x60

.EQU	DIM_LED_VALUE_		= 0x18
.EQU	CLEAR_LED_VALUE_	= 0x04


;----- REGISTER definitions ----------------------------------------------
.UNDEF	XL
.UNDEF	XH
.UNDEF	YL
.UNDEF	YH

.DEF	ZERO_REG	= R3
.DEF	IR_EXTRA	= R6
.DEF	BLINK_COUNT	= R7
.DEF	IR_T		= R8
.DEF	IR_RBUF_COUNT	= R9
.DEF	IR_RBUF		= R10

.DEF	LF_COUNT	= R12
.DEF	LF_HOLD_COUNT	= R13
.DEF	LF_TOP		= R14
.DEF	LF_HOLD		= R15

.DEF	IR_STATUS	= R16
.DEF	IR_BIT_COUNT	= R17
.DEF	IR_PROTOCOL	= R18
.DEF	LP_REG		= R19
.DEF	CONF_COUNT	= R20
.DEF	BTN_COUNT	= R21
.DEF	Temp1		= R22
.DEF	Temp2		= R23
.DEF	Temp3		= R24
.DEF	Temp4		= R25
.DEF	XERC_STATUS	= R26

.DEF	EEPROM_ADDR	= R28
.DEF	EEPROM_DATA	= R29

;----- PortB Bits ----------------------------------------------------------
.EQU	PO_PIN		= 0
.EQU	SL_PIN		= 1
.EQU	IRD_PIN		= 2
.EQU	EB_PIN		= 3
.EQU	PB_PIN		= 4

;----- IR STATUS Bits ---------------------------------------------------------
.EQU	RECIEVING_INV	= 6
.EQU	IR_ONE_CTRL_BIT	= 5
.EQU	IR_HEAD_RECIEVED= 5
.EQU	IR_T_BIT	= 5
.EQU	IR_CTRL_BIT	= 4
.EQU	RECIEVING_IR	= 3
.EQU	IR_ERROR	= 2
.EQU	IR_START	= 1
.EQU	READ_IR_BIT	= 0

;---- IR PROTOCOL DEFINITIONS ----------------------------------------------
.EQU	RCA_PROTOCOL_		= 0x01
.EQU	RCA_PROTOCOL_BIT_	= 0
.EQU	SIRCS_PROTOCOL_		= 0x02
.EQU	SIRCS_PROTOCOL_BIT_	= 1
.EQU	RC5_PROTOCOL_		= 0x04
.EQU	RC5_PROTOCOL_BIT_	= 2
.EQU	RC6_PROTOCOL_		= 0x08
.EQU	RC6_PROTOCOL_BIT_	= 3

;---- IR PROTOCOL STARTBIT LENGTHS  (MAX) ----------------------------------
.EQU	RCA_START_LENGTH_	= 0x70
.EQU	RC6_START_LENGTH_	= 0x50
.EQU	SIRCS_START_LENGTH_	= 0x40
.EQU	RC5_START_LENGTH_	= 0x00

;----- XERC STATUS Bits ----------------------------------------------------
.EQU	LF_DISABLE		= 7
.EQU	LF_OUT			= 6
.EQU	NEW_IR_CMD		= 5
.EQU	CHECK_CONFIG		= 4
.EQU	IN_CONFIG		= 3
.EQU	EXTENDED_LP1		= 2
.EQU	EXTENDED_LP0		= 1
.EQU	IN_LONG_PAUSE		= 0

.EQU	EXTENDED_LP_MASK_	= 0x06	; mask to mask out the extended LP bits
.EQU	EXTENDED_LP_BIT_	= 0x02	; this is the lsb of the extended LP

;----- PAUSE Constants -----------------------------------------------------
;256 = 1.048576s
.EQU	LP_1S2_			= 37	; 1200ms
.EQU	LP_1S2_EXT_		= 1	; the extension
.EQU	LP_BTN_			= 24	;  100ms
.EQU	LP_BTN_EXT_		= 0
.EQU	LP_CMD_			= 250	; 1000ms
.EQU	LP_CMD_EXT_		= 0
.EQU	LP_SMARTXX_		= 200	; 800ms
.EQU	LP_SMARTXX_EXT_		= 0
.EQU	LP_BLINK_SHORT_		= 44	;  180ms
.EQU	LP_BLINK_SHORT_EXT_	= 0
.EQU	LP_BLINK_LONG_		= 141	;  580ms
.EQU	LP_BLINK_LONG_EXT_	= 0
.EQU	LP_BLINK_PAUSE_		= 63	;  260ms
.EQU	LP_BLINK_PAUSE_EXT_	= 0
.EQU	LP_ENTER_CONFIG_	= 255
.EQU	LP_ENTER_CONFIG_EXT_	= 3
.EQU	LP_FR_PAUSE_		= 200	; 800ms
.EQU	LP_FR_PAUSE_EXT_	= 0


;----- CONFIG Command ------------------------------------------------------
.EQU	SKIP_BTN_	= 0
.EQU	PWR_BTN_	= 1
.EQU	LONG_PWR_BTN_	= 2
.EQU	DVD_BTN_	= 3
.EQU	SMARTXX_BTN_	= 4
.EQU	DISC_PWR_	= 5
.EQU	DISABLE_LF_	= 6
.EQU	LAST_BUTTON_	= 6
.EQU	NUMBER_OF_CMDS_	= 5


;----- LED Fader Stuff ----------------------------------------------------
.EQU	LF_TOP_IN_ 	= 0xB0		; Length of fade in
.EQU	LF_TOP_OUT_	= 0xFF		; Length of fade out

.EQU	LF_TOP_HOLD_	= 0x00		; How long to hold at top
.EQU	LF_BOTTOM_HOLD_	= 0x50		; How long to hold at bottom

.EQU	LF_OUT_MODE_	= 0x20
.EQU	LF_IN_MODE_	= 0x30		; mode set for TCCR0A

.EQU	LF_PRESCALER_	= 0x04


;----- SRAM/EEPROM Addresses ----------------------------------------------
.EQU	SRAM_IRCMD_PWR_		= 0x0060
.EQU	SRAM_IRCMD_LONG_PWR_	= 0x0063
.EQU	SRAM_IRCMD_DVD_		= 0x0066
.EQU	SRAM_IRCMD_SMARTXX_	= 0x0069
.EQU	SRAM_IRCMD_DISC_PWR_	= 0x006C

.EQU	EEPROM_DISABLE_LF	= 0x0020	; if this is 5A then lf is disabled

;---- SRAM Addresses ------------------------------------------------------
.EQU	SRAM_IRCMD_CURRENT_	= 0x0090
.EQU	SRAM_IRCMD_INV_		= 0x0093
.EQU	SRAM_IRCMD_OLD_		= 0x0096
.EQU	SRAM_IRCMD_SKIP_	= 0x0099
