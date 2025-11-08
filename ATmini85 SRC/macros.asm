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
; Macros for XERC
;
;**************************************

.MACRO LP
	ANDI	XERC_STATUS,~EXTENDED_LP_MASK_			; mask out bits
	ORI	XERC_STATUS,(@1 * EXTENDED_LP_BIT_)		; or in bits
	LDI	LP_REG,@0					; load pause
	RCALL	LONG_PAUSE					; pause
.ENDMACRO

