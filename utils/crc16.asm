;=============================================================================
;               This programm calculates CRC 16 bits for any small file
;		        Copyright (C) 1993 by Igor Dolzhikov
;=============================================================================

_text           segment byte public 'code'
                assume  CS:_text, DS:_text

;=============================================================================
;               CONSTANTS
;-----------------------------------------------------------------------------
@start_program  equ     0100h
@cr_lf          equ     0FFh
@zero           equ     0
@cmd_line_ptr   equ     80h
@cr             equ     0Dh
@lf             equ     0Ah
@dos            equ     21h
@block_size     equ     8000h
@open_file      equ     3D00h
@read_file      equ     3Fh
@close_file     equ     3Eh
;-----------------------------------------------------------------------------

                org     @start_program

;=============================================================================
;               CRC 16 PRIMARY PROCEDURE
;-----------------------------------------------------------------------------
                public  crc_16
crc_16          proc    near
                mov     SI, offset _copyright
                call    print
                mov     SI, @cmd_line_ptr
                lodsb
                or      AL, AL
                jnz     read_cmd
                mov     SI, offset _help
                jmp     exit
read_cmd:
                lodsb
                cmp     AL, ' '
                jz      read_cmd
                cmp     AL, @cr
                jnz     no_CR
                jmp     exit
no_CR:
                dec     SI
                mov     DI, offset _name
next_char:
                lodsb
                cmp     AL, @cr
                jz      end_cmd
                stosb
                jmp     short next_char
end_cmd:
                mov     AX, @open_file
                mov     DX, offset _name
                int     @dos
                mov     SI, offset _open_error
                jnc     open_ok
                jmp     exit
open_ok:
                mov     _handle, AX
                call    make_crc_table
                mov     CX, @block_size
next_block:
                mov     AH, @read_file
                mov     BX, _handle
                mov     DX, offset _crc_table+512
                int     21h
                mov     SI, offset _read_error
                jnc     read_ok
                jmp     exit
read_ok:
                mov     CX, AX
                call    make_crc
                cmp     CX, @block_size
                je      next_block
                mov     AH, @close_file
                mov     BX, _handle
                int     @dos
                mov     CX, 4
                mov     AX, _crc
                call    convert
                mov     _crc_ascii+3, BL
                shr     AX, CL
                call    convert
                mov     _crc_ascii+2, BL
                shr     AX, CL
                call    convert
                mov     _crc_ascii+1, BL
                shr     AX, CL
                call    convert
                mov     _crc_ascii, BL
                mov     SI, offset _file_name
                call    print
                mov     SI, offset _name
                call    print
                mov     SI, offset _file_crc
exit:
                call    print
                xor     AX, AX
                push    AX
                ret
crc_16          endp
;=============================================================================
;               DATA
;-----------------------------------------------------------------------------
_name           db      80 dup(0)
_handle         dw      0
_polynom        db      0Fh,0Dh,00h,0C8h
_crc            dw      0
_poly_table     dw      8 dup(0)
;=============================================================================
;               MESSAGES
;-----------------------------------------------------------------------------
_copyright      db      @cr_lf
                db      'CRC16 1.02 Copyright (C) 1993 by Igor Dolzhikov'
                db      @cr_lf, @zero
_help           db      'Print CRC information for a file', @cr_lf, @cr_lf
                db      '  Usage:      crc16  <file_name>', @cr_lf
                db      '  Examples:   crc16  crc16.com', @cr_lf, @cr_lf, @zero
_open_error     db      '  Sorry, error opening file', @cr_lf, @zero
_read_error     db      '  Sorry, read failed', @cr_lf, @zero
_file_name      db      @cr_lf
                db      '  File name:  ', @zero
_file_crc       db      @cr_lf
                db      '  CRC 16 hex: '
_crc_ascii      db      '    ', @cr_lf, @zero
;=============================================================================
;               MAKE CRC TABLE
;-----------------------------------------------------------------------------
make_crc_table  proc    near
                mov     SI, offset _polynom
                xor     BX, BX
                xor     CX, CX
                lodsb
read_poly:
                mov     CL, AL
                mov     AX, 1
                shl     AX, CL
                or      BX, AX
                lodsb
                cmp     AL, 0C8h
                jb      read_poly
                mov     CL, 8
                mov     DI, offset _poly_table
                mov     AX, BX
store:
                stosw
                shr     AX, 1
                jnc     no_xor
                xor     AX, BX
no_xor:
                dec     CL
                jnz     store
                mov     SI, offset _poly_table
                mov     DI, offset _crc_table
                xor     DX, DX
prepare_word:
                mov     CX, DX
                mov     BX, SI
                xor     AX, AX
shift:
                shl     CL, 1
                jnc     no_carry
                xor     AX, [BX]
no_carry:
                add     BX, 2
                or      CL, CL
                jnz     shift
                stosw
                inc     DL
                jnz     prepare_word
                ret
make_crc_table  endp
;=============================================================================
;               MAKE CRC
;-----------------------------------------------------------------------------
make_crc        proc    near
                push    CX
                mov     DI, offset _crc_table
                mov     SI, offset _crc_table+512
                mov     DX, AX
                mov     CX, _crc
load_byte:
                lodsb
                mov     BL, CL
                xor     BL, AL
                xor     BH, BH
                mov     CL, CH
                mov     CH, 0
                add     BX, BX
                xor     CX, [BX+DI]
                dec     DX
                jnz     load_byte
                mov     _crc, CX
                pop     CX
                ret
make_crc        endp
;=============================================================================
;               HEX CONVERTER
;-----------------------------------------------------------------------------
convert         proc    near
                mov     BL, AL
                and     BL, 0Fh
                cmp     BL, 9
                jbe     digit
                add     BL, 7
digit:
                add     BL, 30h
                ret
convert         endp
;=============================================================================
;               PRINT STRING
;-----------------------------------------------------------------------------
;               Entering parameter:
;               DS:SI - pointer to string (terminated zero)
;-----------------------------------------------------------------------------
@video          equ     10h
@get_mode       equ     0Fh
@teletype       equ     0Eh
;-----------------------------------------------------------------------------
                public  print
print           proc    near
                push    AX
                push    BX
                push    CX
                push    SI
                mov     AH, @get_mode
                int     @video
load_char:
                lodsb
                or      AL, AL
                jz      end_string
                cmp     AL, @cr_lf
                jne     not_crlf
                mov     AL, @cr
                mov     AH, @teletype
                int     @video
                mov     AL, @lf
not_crlf:
                mov     AH, @teletype
                int     @video
                jmp     load_char
end_string:
                pop     SI
                pop     CX
                pop     BX
                pop     AX
                ret
print           endp
;=============================================================================
;               CRC TABLE
;-----------------------------------------------------------------------------
_crc_table      label   word
;-----------------------------------------------------------------------------
_text           ends

                end     crc_16
