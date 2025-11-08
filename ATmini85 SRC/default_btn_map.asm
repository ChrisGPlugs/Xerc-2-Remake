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



; The deafault button map that is loaded into the eeprom if
; a factory reset is performed
DEFAULT_BTN_MAP:
.DB	0x15,0x2A,0x00,\
	0x15,0x1D,0x00,\
	0x15,0x15,0x00,\
	0x00,0x00,0x00,\
	0x00,0x00,0x00,0	; extra zero to avoid padding warning message
