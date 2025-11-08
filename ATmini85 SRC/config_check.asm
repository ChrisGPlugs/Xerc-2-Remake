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



;**************************************
;
; Enter Config Check
;
;**************************************
CHECK_IF_CONFIG:
	IN	Temp1,GIMSK
	ANDI	Temp1,~(1<<INT0)
	OUT	GIMSK,Temp1			; dissable external interrupts

	SBR	XERC_STATUS,(1<<CHECK_CONFIG)	; set flag
	LP	LP_ENTER_CONFIG_,LP_ENTER_CONFIG_EXT_	; start the pause timer


CHECK_IF_CONFIG_LOOP:
	SBIC	PINB,PB_PIN			; is the power button beeing pressed?
	RJMP	END_CHECK_IF_CONFIG

	SBRC	XERC_STATUS,CHECK_CONFIG	; if still waiting for timer to run out
	RJMP	CHECK_IF_CONFIG_LOOP		; then continue looping


MAGIC_PRESS:
	SBIC	PINB,PO_PIN			; If xbox is still on it was just a long
	RJMP	END_CHECK_IF_CONFIG		; power on press, not power off

	RCALL	LONG_BLINK			; blink

	SBRC	XERC_STATUS,IN_CONFIG		; if its the second time we enter then
	RJMP	FACTORY_RESET_XERC		; do a "factory reset"

	SBR	XERC_STATUS,(1<<IN_CONFIG)	; set it to "in config" allready to indicate
						; that we have allready passed the first
						; 5s to enter config

	RJMP	CHECK_IF_CONFIG	



END_CHECK_IF_CONFIG:
	CBR	XERC_STATUS,(1<<CHECK_CONFIG)	; not checking config anymore

	RCALL	DISABLE_TIM1_OVF_INT		; Clear timer1 ovf interupt

	ANDI	XERC_STATUS,~EXTENDED_LP_MASK_

	RCALL	ENABLE_EXT_INT0_FALLING

	SBRC	XERC_STATUS,IN_CONFIG
	RCALL	ENTER_CONFIG

	RJMP	MAIN
