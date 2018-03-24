PAGE 80,132

_text           segment word public 'code'
                assume  CS:_text, DS:_text, ES:_text, SS:_text

;=============================================================================
;               CONSTANT
;-----------------------------------------------------------------------------
@video          equ     10h
@identifier     equ     'R'
@question       equ     '?'
@confirmation   equ     '+'
@jump_far_code  equ     0EAh
@call_far_code  equ     9Ah
@zero           equ     0
@start_program  equ     0100h
@cr_lf          equ     0FFh
@key_size       equ     00D4h
@cga_size       equ     0800h
@ega_size       equ     0E00h
@vga_size       equ     1000h
;-----------------------------------------------------------------------------

                org     @start_program

;=============================================================================
;               RUSSIAN PROCEDURE
;-----------------------------------------------------------------------------
                public  russian
russian         proc    near
                dec     BP
                jp      not_label
not_label:
                mov     BX, @start_program
                xor     SI, SI
                and     [BX+SI], AL
                add     [SI], AL
                cld
                cld
                or      AL, @zero
                db      @zero, 40h, @zero
                add     [BX+SI], AH
                add     [BX+SI], AL
                db      @zero, 40h, @zero
                add     [BX+SI], AL
                inc     BP
                mov     AX, offset install
                mov     BL, 97h
                db      30  dup(0)
                push    AX
                db      @zero, 40h, @zero
                db      81h, @zero, 40h, @zero
                ret
                db      @zero, 40h, @zero
                db      436 dup(0)
russian         endp
;=============================================================================
;               COPYRIGHT
;-----------------------------------------------------------------------------
                public  _identification
_identification db      @zero, 'Universal RTL (C) Blues 1993', @zero
;=============================================================================
;               SWITCH CONSTANT
;-----------------------------------------------------------------------------
;               DRIVER TYPE
;-----------------------------------------------------------------------------
@display        equ     'd'
@keyboard       equ     'k'
@both           equ     'b'
;-----------------------------------------------------------------------------
;               MEMORY TYPE
;-----------------------------------------------------------------------------
@high           equ     'h'
@conventional   equ     'c'
;-----------------------------------------------------------------------------
;               ACTIVE KEY
;-----------------------------------------------------------------------------
@alt            equ     38h
@ctrl           equ     1Dh
@rshift         equ     36h
@lshift         equ     2Ah
;-----------------------------------------------------------------------------
;               EXTENDED KEYBOARD
;-----------------------------------------------------------------------------
@right          equ     'r'
@left           equ     'l'
;-----------------------------------------------------------------------------
;               INDICATION TYPE
;-----------------------------------------------------------------------------
@sound          equ     's'
@border         equ     'b'
;-----------------------------------------------------------------------------
;               BORDER COLOR
;-----------------------------------------------------------------------------
@black          equ     00h
@blue           equ     01h
@green          equ     02h
@cyan           equ     03h
@red            equ     04h
@magenta        equ     05h
@brown          equ     06h
@light_gray     equ     07h
@dark_gray      equ     08h
@light_blue     equ     09h
@light_green    equ     0Ah
@light_cyan     equ     0Bh
@light_red      equ     0Ch
@light_magenta  equ     0Dh
@yellow         equ     0Eh
@white          equ     0Fh
;=============================================================================
;               SWITCH DATA
;-----------------------------------------------------------------------------
                public  _driver, _memory, _active,
                public  _extended, _indication, _color
@_driver        equ     $ - _identification
_driver         db      @display
@_memory        equ     $ - _identification
_memory         db      @conventional
@_active        equ     $ - _identification
_active         db      @Ctrl
@_extended      equ     $ - _identification
_extended       db      @right
@_indication    equ     $ - _identification
_indication     db      @border
@_color         equ     $ - _identification
_color          db      @yellow
;=============================================================================
;               HMA TYPE
;-----------------------------------------------------------------------------
@code           equ     1
@fonts          equ     2
@code_fonts     equ     3
;-----------------------------------------------------------------------------
                public  _hma_type
@_hma_type      equ     $ - _identification
_hma_type       db      @zero
;=============================================================================
;               VIDEO DATA
;-----------------------------------------------------------------------------
@unknown_video  equ     0
@ega_adapter    equ     1
@vga_adapter    equ     2
@mcga_adapter   equ     3
;-----------------------------------------------------------------------------
                public  _adapter, _function, _fonts_ptr_ofs, _fonts_ptr_seg
@_adapter       equ     $ - _identification
_adapter        db      @zero
@_function      equ     $ - _identification
_function       dw      @zero
@_fonts_ptr_ofs equ     $ - _identification
_fonts_ptr_ofs  dw      @zero
@_fonts_ptr_seg equ     $ - _identification
_fonts_ptr_seg  dw      @zero
;=============================================================================
;               RUSSIAN INTERRUPT
;-----------------------------------------------------------------------------
;               Entering parameter:
;                 AH - identification code
;                 AL - function:
;                   '?' - if need recognize driver seting
;               Return:
;                 AL - confirmation if function supported
;-----------------------------------------------------------------------------
                public  int_2F, _old_2F
int_2F          proc    far
                cmp     AH, @identifier
                jne     not_our
                cmp     AL, @question
                jne     not_our
                mov     AL, @confirmation
                iret
not_our:
                db      @jump_far_code
_old_2F         dd      0
int_2F          endp
;=============================================================================
;               KEYBOARD INTERRUPT
;-----------------------------------------------------------------------------
                public  int_09, _old_09
int_09          proc    far
                call    bios_09
                iret
int_09          endp
;=============================================================================
;               CALL OLD KEYBOARD INTERRUPT
;-----------------------------------------------------------------------------
                public  bios_09
bios_09         proc    near
                pushf
                db      @call_far_code
_old_09         dd      0
                ret
bios_09         endp
;=============================================================================
;               KEYBOARD DATA
;-----------------------------------------------------------------------------
                public  _keyboard_data
_keyboard_data  label   word
                db      @key_size dup(?)
;=============================================================================
;               VIDEO INTERRUPT
;-----------------------------------------------------------------------------
@reset_bit_7    equ     01111111b
@reset_bit_4    equ     11101111b
@char_generator equ     11h
@set_text_ega   equ     1
@set_text_cga   equ     2
@set_text_vga   equ     4
@set_graph_ega  equ     22h
@set_graph_cga  equ     23h
@set_graph_vga  equ     24h
@scan_lines     equ     485h
@cga_lines      equ     08h
@ega_lines      equ     0Eh
@vga_lines      equ     10h
;-----------------------------------------------------------------------------
                public  int_10, _old_10
int_10          proc    far
                push    DS
                push    CS
                pop     DS
                push    AX
                call    bios_10

;               pop     _function
                db      8Fh, 06h
_init_001       dw      @_function

                push    AX

;               mov     AX, _function
                db      0A1h
_init_002       dw      @_function

                or      AH, AH
                je      change_mode
                cmp     AH, @char_generator
                jne     end_int_10
                mov     AH, AL
                and     AL, @reset_bit_4
                cmp     AL, @set_text_ega
                je      set_text
                cmp     AL, @set_text_cga
                je      set_text
                cmp     AL, @set_text_vga
                je      set_text
                cmp     AH, @set_graph_cga
                je      set_graph
                cmp     AH, @set_graph_ega
                je      set_graph
                cmp     AH, @set_graph_vga
                je      set_graph
                jmp     short end_int_10
change_mode:
                and     AL, @reset_bit_7
                cmp     AL, 3
                jbe     set_text
                cmp     AL, 7
                je      set_text
                cmp     AL, 13h
                ja      end_int_10
set_graph:
                call    graph_load
                jmp     short end_int_10
set_text:
                call    text_load
end_int_10:
                pop     AX
                pop     DS
                iret
int_10          endp
;=============================================================================
;               CALL OLD VIDEO INTERRUPT
;-----------------------------------------------------------------------------
                public  bios_10
bios_10         proc    near
                pushf
                db      @call_far_code
_old_10         dd      0
                ret
bios_10         endp
;=============================================================================
;               TEXT LOAD
;-----------------------------------------------------------------------------
@table_size     equ     100h
@set_block      equ     03h
;-----------------------------------------------------------------------------
                public  text_load
text_load       proc    near
                irp     reg, <BX,CX,DX,BP,ES>
                push    reg
                endm
                xor     CX, CX
                mov     ES, CX
                push    AX
                and     AH, @reset_bit_4
                mov     AL, byte ptr ES:@scan_lines

;               les     BP, dword ptr DS:_fonts_ptr_ofs
                db      0C4h, 2Eh
_init_003       dw      @_fonts_ptr_ofs

                mov     BH, @cga_lines
                cmp     AH, @set_text_cga
                je      load_block
                cmp     AL, BH
                je      load_block_0
                add     BP, @cga_size
                mov     BH, @ega_lines
                cmp     AH, @set_text_ega
                je      load_block
                cmp     AL, BH
                je      load_block_0
                add     BP, @ega_size
                mov     BH, @vga_lines
                cmp     AH, @set_text_vga
                je      load_block
                cmp     AL, BH
                je      load_block_0
                pop     AX
                jmp     short end_text_load
load_block_0:
                xor     BL, BL
load_block:
                pop     AX
                mov     AL, AH
                mov     CX, @table_size
                xor     DX, DX
                mov     AH, @char_generator
                and     AL, NOT @reset_bit_4
                call    bios_10
                mov     AH, @char_generator
                mov     AL, @set_block
                call    bios_10
end_text_load:
                irp     reg, <ES,BP,DX,CX,BX>
                pop     reg
                endm
                ret
text_load       endp
;=============================================================================
;               GRAPH LOAD
;-----------------------------------------------------------------------------
@int_43_ptr     equ     43h * 4
@int_1F_ptr     equ     1Fh * 4
@half_cga       equ     400h
;-----------------------------------------------------------------------------
                public  graph_load
graph_load      proc    near
                push    BP
                push    ES
                xor     BP, BP
                mov     ES, BP
                mov     AL, byte ptr ES:@scan_lines

;               mov     BP, _fonts_ptr_ofs
                db      8Bh, 2Eh
_init_004       dw      @_fonts_ptr_ofs

                cmp     AL, @cga_lines
                je      set_int_43
                add     BP, @cga_size
                cmp     AL, @ega_lines
                je      set_int_43
                add     BP, @ega_size
                cmp     AL, @vga_lines
                jne     end_graph_load
set_int_43:

;               mov     AX, _fonts_ptr_seg
                db      0A1h
_init_005       dw      @_fonts_ptr_seg

                cli
                mov     word ptr ES:@int_43_ptr, BP
                mov     word ptr ES:@int_43_ptr+2, AX
                sti

;               mov     BP, _fonts_ptr_ofs
                db      8Bh, 2Eh
_init_006       dw      @_fonts_ptr_ofs

                add     BP, @half_cga
                cli
                mov     word ptr ES:@int_1F_ptr, BP
                mov     word ptr ES:@int_1F_ptr+2, AX
                sti
end_graph_load:
                pop     ES
                pop     BP
                ret
graph_load      endp
;=============================================================================
;               FONTS
;-----------------------------------------------------------------------------
                public  _cga_font, _ega_font, _vga_font
_cga_font       label   word
                db      @cga_size dup(?)
_ega_font       label   word
                db      @ega_size dup(?)
_vga_font       label   word
                db      @vga_size dup(?)
;=============================================================================
;               MESSAGE
;-----------------------------------------------------------------------------
                public  _copyright
_copyright      db      @cr_lf
                db      'Russian 1.00 Copyright (C) 1993 by Igor Dolzhikov', @cr_lf
                db      'Display and keyboard drivers', @cr_lf, @cr_lf, @zero
;-----------------------------------------------------------------------------
                public  _help
_help           db      'Usage:    russian <command> [{/|-}<switch> [{/|-}<switch>... ]]', @cr_lf
                db      'Examples: russian r -c3 -f?ga*.fnt -is -db', @cr_lf
                db      '          russian s /ac /er /mh /kkeyb.kbd', @cr_lf
                db      @cr_lf
                db      '<Commands>', @cr_lf
                db      '  r: installing driver to resident          g: get current configuration', @cr_lf
                db      '  s: save configuration assigned switches   u: update current configuration', @cr_lf
                db      @cr_lf
                db      '<Switches>', @cr_lf
                db      '  d: set driver type                        e: use if extended keyboard', @cr_lf
                db      '     dd: display driver                        er: right key (Alt or Ctrl)', @cr_lf
                db      '     dk: keyboard driver                       el: left  key (Alt or Ctrl)', @cr_lf
                db      '     db: both drivers                       i: set indication type', @cr_lf
                db      '  m: use memory type                           is: sound indication   ', @cr_lf
                db      '     mh: high DOS memory                       ib: border indication', @cr_lf
                db      '         use if set himem.sys               c: set border color', @cr_lf
                db      '     mc: conventional memory                   use hex number (0 - F)', @cr_lf
                db      '  a: set active key                            cE: yellow color', @cr_lf
                db      '     aa: Alt                                f: load font file(s)', @cr_lf
                db      '     ac: Ctrl                                  f*.fnt: load all *.fnt files', @cr_lf
                db      '     ar: Right Shift                        k: load keyboard file', @cr_lf
                db      '     al: Left  Shift                           ktest.kbd: load file test.kbd', @cr_lf
                db      @zero
;-----------------------------------------------------------------------------
                public  _installed, _saved, _updated
                public  _config_file, _config_memory
                public  _set_number, _number
                public  _use_display, _use_keyboard, _use_both
                public  _memory_high, _memory_cnv
                public  _pseudo_key, _active_key
_installed      db      'Driver installed', @cr_lf, @zero
_saved          db      'Switches saved:', @cr_lf, @zero
_updated        db      'Switches updated:', @cr_lf, @zero
_config_file    db      'Current configuration into file:', @cr_lf, @zero
_config_memory  db      'Current configuration into memory:', @cr_lf, @zero
_set_number     db      '  ('
_number         db      '1'
                db      ') ', @zero
_use_display    db      'Used only display driver', @cr_lf, @zero
_use_keyboard   db      'Used only keyboard driver', @cr_lf, @zero
_use_both       db      'Used display and keyboard drivers', @cr_lf, @zero
_memory_high    db      'Loading in High DOS memory', @cr_lf, @zero
_memory_cnv     db      'Loading in conventional memory', @cr_lf, @zero
_pseudo_key     db      '> key to pseudographics', @cr_lf, @zero
_active_key     db      '> key to activate', @cr_lf, @zero
;-----------------------------------------------------------------------------
                public  _key_name, _alt_key, _ctrl_key
_key_name       label   word
                db      @alt
_alt_key        db      '<Alt', @zero
                db      @ctrl
_ctrl_key       db      '<Ctrl', @zero
                db      @rshift
                db      '<Right Shift', @zero
                db      @lshift
                db      '<Left Shift', @zero
;-----------------------------------------------------------------------------
                public  _right_key, _left_key, _sound_ind
                public  _border_ind, _border_color
_right_key      db      'Right key to extended keyboard', @cr_lf, @zero
_left_key       db      'Left key to extended keyboard', @cr_lf, @zero
_sound_ind      db      'Sound indication', @cr_lf, @zero
_border_ind     db      'Border indication', @cr_lf, @zero
_border_color   db      ' border color', @cr_lf, @cr_lf, @zero
;-----------------------------------------------------------------------------
                public  _color_name
_color_name     label   word
                db      @black
                db      'Black', @zero
                db      @blue
                db      'Blue', @zero
                db      @green
                db      'Green', @zero
                db      @cyan
                db      'Cyan', @zero
                db      @red
                db      'Red', @zero
                db      @magenta
                db      'Magenta', @zero
                db      @brown
                db      'Brown', @zero
                db      @light_gray
                db      'Light Gray', @zero
                db      @dark_gray
                db      'Dark Gray', @zero
                db      @light_blue
                db      'Light Blue', @zero
                db      @light_green
                db      'Light Green', @zero
                db      @light_cyan
                db      'Light Cyan', @zero
                db      @light_red
                db      'Light Red', @zero
                db      @light_magenta
                db      'Light Magenta', @zero
                db      @yellow
                db      'Yellow', @zero
                db      @white
                db      'White', @zero
;-----------------------------------------------------------------------------
;               ERROR MESSAGE
;-----------------------------------------------------------------------------
                public  _already, _sorry, _file_name, _old_name, _not_found
                public  _error_opening, _error_creating, _invalid_size
                public  _read_failed, _write_failed, _incorrect_cmd
                public  _command, _incorrect_sw, _switch, _corrupt
                public  _russian_name
_already        db      'Sorry, driver already loaded', @cr_lf, @zero
_sorry          db      'Sorry, file ', @zero
_file_name      db      80 dup(0)
_old_name       db      80 dup(0)
_not_found      db      ' not found ', @cr_lf, @zero
_error_opening  db      ' error opening', @cr_lf, @zero
_error_creating db      ' error creating', @cr_lf, @zero
_invalid_size   db      ' invalid size', @cr_lf, @zero
_read_failed    db      ' read failed', @cr_lf, @zero
_write_failed   db      ' write failed', @cr_lf, @zero
_incorrect_cmd  db      'Incorrect command: '
_command        db      ' ', @cr_lf, @zero
_incorrect_sw   db      'Incorrect switch: '
_switch         db      '  ', @cr_lf, @zero
_not_adapter    db      'Not found adapter EGA/VGA/MCGA', @cr_lf, @zero
_not_hma        db      "Can't using high DOS memory", @cr_lf, @zero
_corrupt        db      'Packed file is corrupt', @cr_lf, @zero
_russian_name   db      'RUSSIAN.COM'
;=============================================================================
;               INSTALLATION
;-----------------------------------------------------------------------------
@dos            equ     21h
@driver         equ     2Fh
@command_line   equ     80h
@exit_function  equ     4Ch
;-----------------------------------------------------------------------------
                public  install
install         proc    near
                mov     SI, offset _copyright
                call    print
                mov     SI, @command_line
                lodsb
                or      AL, AL
                jnz     analyse
                mov     SI, offset _help
                mov     AH, @exit_function
                jmp     short exit
analyse:
                mov     DI, offset _end_of_file
                cbw
                mov     CX, AX
                rep     movsb
                mov     CX, AX
                mov     SI, offset _end_of_file
                call    analyse_cmdline
                jc      exit
                call    check_integrity
                jc      exit
                mov     AH, @identifier
                mov     AL, @question
                int     @driver
                call    BX
exit:
                call    print
                int     @dos
install         endp
;=============================================================================
;               CHECK INTEGRITY FILE
;-----------------------------------------------------------------------------
@env_adr        equ     2Ch
@name_length    equ     0Bh
;-----------------------------------------------------------------------------
                public  check_integrity
check_integrity proc    near
                mov     AX, DS:@env_adr
                mov     DS, AX
                xor     SI, SI
                xor     AX, AX
check_zero:
                lodsb
                or      AL, AL
                jnz     check_zero
                lodsb
                or      AL, AL
                jnz     check_zero
                lodsw
                mov     DI, offset _file_name
                mov     CX, @name_length
                mov     DX, DI
move_exec_name:
                lodsb
                stosb
                cmp     AL, '\'
                jne     not_found_slash
                mov     DX, DI
not_found_slash:
                or      AL, AL
                jne     move_exec_name
                push    CS
                pop     DS
                mov     SI, DX
                mov     DI, offset _russian_name
                mov     CX, @name_length
check_file_name:
                cmpsb
                je      check_next_byte
                mov     SI, offset _corrupt
                jmp     short not_integrity
check_next_byte:
                loop    check_file_name
                clc
                ret
not_integrity:
                stc
                ret
check_integrity endp
;=============================================================================
;               RESIDENT
;-----------------------------------------------------------------------------
                public  resident
resident        proc    near
                mov     SI, offset _already
                cmp     AL, @confirmation
                je      not_resident
                call    check_video
                mov     _adapter, AL
                cmp     _driver, @keyboard
                je      not_check
                mov     SI, offset _not_adapter
                or      AL, AL
                jz      not_resident
not_check:
                call    set_resident
not_resident:
                mov     AH, @exit_function
                ret
resident        endp
;=============================================================================
;               CHECK VIDEO
;-----------------------------------------------------------------------------
;               Return:
;                 AL - 0 if unknown adapter type
;                      1 if EGA adapter
;                      2 if VGA adapter
;                      3 of MCGA adapter
;-----------------------------------------------------------------------------
@alternate      equ     12h
@check_e_v_m    equ     10h
@check_v_m      equ     32h
@check_v        equ     36h
@cipher_byte    equ     55h
@supported_code equ     12h
@unknown_video  equ     0
@ega_adapter    equ     1
@vga_adapter    equ     2
@mcga_adapter   equ     3
;-----------------------------------------------------------------------------
                public  check_video
check_video     proc    near
                push    BX
                mov     AH, @alternate
                mov     BL, @check_e_v_m
                mov     BH, @cipher_byte
                int     @video
                cmp     BX, @alternate SHL 8 OR @cipher_byte
                mov     AL, @unknown_video
                je      definite_video
                mov     AH, @alternate
                mov     BL, @check_v_m
                xor     AL, AL
                int     @video
                mov     BL, AL
                mov     AL, @ega_adapter
                cmp     BL, @supported_code
                jne     definite_video
                mov     AH, @alternate
                mov     BL, @check_v
                xor     AL, AL
                int     @video
                mov     BL, AL
                mov     AL, @vga_adapter
                cmp     BL, @supported_code
                je      definite_video
                mov     AL, @mcga_adapter
definite_video:
                pop     BX
                ret
check_video     endp
;=============================================================================
;               SET RESIDENT
;-----------------------------------------------------------------------------
@get_int_2F     equ     352Fh
@get_int_09     equ     3509h
@get_int_10     equ     3510h
@get_mode       equ     0Fh
@set_mode       equ     00h
;-----------------------------------------------------------------------------
                public  set_resident
set_resident    proc    near
                mov     AX, @get_int_2F
                int     @dos
                mov     word ptr DS:_old_2F, BX
                mov     word ptr DS:_old_2F+2, ES
                mov     AX, @get_int_09
                int     @dos
                mov     word ptr DS:_old_09, BX
                mov     word ptr DS:_old_09+2, ES
                mov     AX, @get_int_10
                int     @dos
                mov     word ptr DS:_old_10, BX
                mov     word ptr DS:_old_10+2, ES
                mov     _hma_type, @zero
                cmp     _memory, @high
                jne     set_cnv
                call    allocate_memory
                jc      not_set
set_cnv:
                push    CS
                pop     ES
                cmp     _hma_type, @code_fonts
                je      not_tsr
                mov     DI, @start_program
                call    move_to_cnv
not_tsr:
                mov     AH, @get_mode
                int     @video
                mov     AH, @set_mode
                int     @video
                mov     SI, offset _copyright
                call    print
                mov     SI, offset _installed
not_set:
                ret
set_resident    endp
;=============================================================================
;               ALLOCATE MEMORY
;-----------------------------------------------------------------------------
@query_free_hma equ     4A01h
@allocate_hma   equ     4A02h
;-----------------------------------------------------------------------------
                public  allocate_memory
allocate_memory proc    near
                mov     AX, @query_free_hma
                xor     BX, BX
                int     @driver
                or      BX, BX
                jz      not_allocate
                mov     AX, ES
                cmp     AX, NOT @zero
                jne     not_allocate
                cmp     DI, NOT @zero
                je      not_allocate
                call    check_size
                mov     AX, CX
                add     AX, DX
                mov     _hma_type, @code_fonts
                cmp     BX, AX
                ja      allocation
                or      DX, DX
                je      not_used_fonts
                mov     AX, DX
                mov     _hma_type, @fonts
                cmp     BX, AX
                ja      allocation
not_used_fonts:
                mov     AX, CX
                mov     _hma_type, @code
                cmp     BX, AX
                jb      not_allocate
allocation:
                mov     BX, AX
                mov     AX, @allocate_hma
                int     @driver
                call    move_to_hma
                clc
                ret
not_allocate:
                mov     SI, offset _not_hma
                stc
allocate_memory endp
;=============================================================================
;               CHECK SIZE
;-----------------------------------------------------------------------------
;               Return:
;                 CX - code size
;                 DX - type size
;-----------------------------------------------------------------------------
                public  check_size
check_size      proc    near
                mov     CX, _cga_font - _identification
                cmp     _driver, @both
                je      test_fonts_size
                mov     CX, _cga_font - int_10 + int_09 - _identification
                cmp     _driver, @display
                je      test_fonts_size
                mov     CX, int_10 - _identification
test_fonts_size:
                mov     AL, _adapter
                mov     DX, @cga_size + @ega_size + @vga_size
                cmp     AL, @vga_adapter
                je      set_size
                mov     DX, @cga_size + @vga_size
                cmp     AL, @mcga_adapter
                je      set_size
                mov     DX, @cga_size + @ega_size
                cmp     AL, @ega_adapter
                je      set_size
                xor     DX, DX
set_size:
                ret
check_size      endp
;=============================================================================
;               MOVE PROGRAM TO HIGH DOS MEMORY
;-----------------------------------------------------------------------------
;               Entering parameter:
;                 ES:DI - pointer to high DOS memory
;-----------------------------------------------------------------------------
@set_int        equ     25h
@int_number_2F  equ     2Fh
@int_number_09  equ     09h
@int_number_10  equ     10h
;-----------------------------------------------------------------------------
                public  move_to_hma
move_to_hma     proc    near
                cmp     _hma_type, @fonts
                je      not_code
                mov     _fonts_ptr_ofs, @start_program
                mov     _fonts_ptr_seg, DS
                mov     BX, DI
                mov     AX, DI
                call    init_table
                mov     SI, offset _identification
                mov     CX, int_09 - _identification
                mov     AL, @int_number_2F
                mov     AH, @set_int
                mov     DX, DI
                add     DX, int_2F - _identification
                rep     movsb
                push    DS
                push    ES
                pop     DS
                int     @dos
                pop     DS
                mov     AL, @int_number_10
                mov     SI, offset int_10
                mov     CX, _cga_font - int_10
                cmp     _driver, @display
                je      move_code
                mov     AL, @int_number_09
                mov     SI, offset int_09
                mov     CX, int_10 - int_09
                cmp     _driver, @keyboard
                je      move_code
                mov     AH, @set_int
                mov     DX, DI
                rep     movsb
                push    DS
                push    ES
                pop     DS
                int     @dos
                pop     DS
                mov     AL, @int_number_10
                mov     CX, _cga_font - int_10
move_code:
                mov     AH, @set_int
                mov     DX, DI
                rep     movsb
                push    DS
                push    ES
                pop     DS
                int     @dos
                pop     DS
                cmp     _hma_type, @code
                je      not_fonts
not_code:
                mov     _fonts_ptr_ofs, DI
                mov     _fonts_ptr_seg, ES
                cmp     _hma_type, @fonts
                je      set_fonts
                mov     ES:[BX+@_fonts_ptr_ofs], DI
                mov     ES:[BX+@_fonts_ptr_seg], ES
set_fonts:
                mov     SI, offset _cga_font
                mov     CX, @cga_size
                rep     movsb
                mov     CX, @ega_size
                cmp     _adapter, @ega_adapter
                je      move_fonts
                add     CX, @vga_size
                cmp     _adapter, @vga_adapter
                je      move_fonts
                mov     SI, offset _vga_font
                mov     CX, @vga_size
move_fonts:
                rep     movsb
not_fonts:
                ret
move_to_hma     endp
;=============================================================================
;               MOVE PROGRAM TO CONVENTIONAL MEMORY
;-----------------------------------------------------------------------------
;               Entering parameter:
;                 ES:DI - pointer to conentional memory
;-----------------------------------------------------------------------------
@set_int        equ     25h
@int_number_2F  equ     2Fh
@int_number_09  equ     09h
@int_number_10  equ     10h
@get_mode       equ     0Fh
@set_mode       equ     00h
@tsr            equ     27h
;-----------------------------------------------------------------------------
                public  move_to_cnv
move_to_cnv     proc    near
                cmp     _hma_type, @code
                je      check_fonts
                mov     BX, DI
                mov     AX, DI
                call    init_table
                mov     SI, offset _identification
                mov     CX, int_09 - _identification
                mov     AL, @int_number_2F
                mov     AH, @set_int
                mov     DX, DI
                add     DX, int_2F - _identification
                rep     movsb
                int     @dos
                mov     AL, @int_number_10
                mov     SI, offset int_10
                mov     CX, _cga_font - int_10
                cmp     byte ptr DS:[BX+@_driver], @display
                je      load_code
                mov     AL, @int_number_09
                mov     SI, offset int_09
                mov     CX, int_10 - int_09
                cmp     byte ptr DS:[BX+@_driver], @keyboard
                je      load_code
                mov     AH, @set_int
                mov     DX, DI
                rep     movsb
                int     @dos
                mov     AL, @int_number_10
                mov     CX, _cga_font - int_10
load_code:
                mov     AH, @set_int
                mov     DX, DI
                rep     movsb
                int     @dos
                cmp     byte ptr DS:[BX+@_hma_type], @fonts
                je      no_fonts
                mov     [BX+@_fonts_ptr_ofs], DI
                mov     [BX+@_fonts_ptr_seg], DS
check_fonts:
                mov     SI, offset _cga_font
                mov     CX, @cga_size
                rep     movsb
                mov     CX, @ega_size
                cmp     byte ptr DS:[BX+@_adapter], @ega_adapter
                je      load_fonts
                add     CX, @vga_size
                cmp     byte ptr DS:[BX+@_adapter], @vga_adapter
                je      load_fonts
                mov     SI, offset _vga_font
                mov     CX, @vga_size
load_fonts:
                rep     movsb
no_fonts:
                mov     AH, @get_mode
                int     @video
                mov     AH, @set_mode
                int     @video
                mov     SI, offset _copyright
                call    print
                mov     SI, offset _installed
                call    print
                mov     DX, DI
                int     @tsr
move_to_cnv     endp
;=============================================================================
;               RELOCATION TABLE
;-----------------------------------------------------------------------------
                public  _reloc_table
_reloc_table    label   word
                dw      _init_001
                dw      _init_002
                dw      _init_003
                dw      _init_004
                dw      _init_005
                dw      _init_006
                dw      @zero
;=============================================================================
;               INIT RELOCATION TABLE
;-----------------------------------------------------------------------------
;               Entering parameter:
;                 AX - pointer to data segment
;-----------------------------------------------------------------------------
                public  init_table
init_table      proc    near
                push    BX
                push    CX
                push    SI
                mov     CX, AX
                mov     SI, offset _reloc_table
load_pointer:
                lodsw
                or      AX, AX
                je      end_init
                mov     BX, AX
                add     [BX], CX
                jmp     short load_pointer
end_init:
                pop     SI
                pop     CX
                pop     BX
                ret
init_table      endp
;=============================================================================
;               SAVE
;-----------------------------------------------------------------------------
@unlink         equ     41h
@rename         equ     56h
@create_file    equ     3Ch
@atribute       equ     20h
@save_file      equ     40h
@close_file     equ     3Eh
;-----------------------------------------------------------------------------
                public  save
save            proc    near
                mov     SI, offset _file_name
                mov     DI, offset _old_name
find_point:
                lodsb
                stosb
                cmp     AL, '.'
                jne     find_point
                mov     AL, 'O'
                stosb
                mov     AL, 'L'
                stosb
                mov     AL, 'D'
                stosb
                xor     AX, AX
                stosb
                mov     AH, @unlink
                mov     DX, offset _old_name
                int     @dos
                mov     DI, DX
                mov     DX, offset _file_name
                mov     AH, @rename
                int     @dos
                mov     AH, @create_file
                mov     CX, @atribute
                int     @dos
                mov     DI, offset _error_creating
                jc      save_error
                mov     BX, AX
                mov     CX, offset _end_of_file - @start_program
                mov     DX, @start_program
                mov     AH, @save_file
                int     @dos
                mov     DI, offset _write_failed
                jc      save_error
                cmp     CX, AX
                jne     save_error
                mov     AH, @close_file
                int     @dos
                mov     SI, offset _saved
                call    print
                call    get_config
                xor     AL, AL
                mov     AH, @exit_function
                ret
save_error:
                mov     SI, offset _sorry
                call    print
                mov     SI, offset _file_name
                call    print
                mov     SI, DI
                mov     AH, @exit_function
                ret
save            endp
;=============================================================================
;               GET
;-----------------------------------------------------------------------------
                public  get
get             proc    near
                push    AX
                mov     SI, offset _config_file
                call    print
                call    get_config
                pop     AX
                cmp     AL, @confirmation
                jne     not_use_memory
                call    print
                mov     SI, offset _config_memory
                call    print
                call    get_config
                xor     AL, AL
not_use_memory:
                mov     AH, @exit_function
                ret
get             endp
;=============================================================================
;               update
;-----------------------------------------------------------------------------
                public  update
update          proc    near
                mov     SI, offset _updated
                call    print
                call    get_config
                xor     AL, AL
                mov     AH, @exit_function
                ret
update          endp
;=============================================================================
;               GET CONFIG
;-----------------------------------------------------------------------------
@start_number   equ     31h
;-----------------------------------------------------------------------------
                public  get_config
get_config      proc    near
                mov     SI, offset _set_number
                mov     DX, SI
                mov     _number, @start_number
                call    print
                mov     AL, _driver
                mov     SI, offset _use_display
                cmp     AL, @display
                je      print_driver
                mov     SI, offset _use_keyboard
                cmp     AL, @keyboard
                je      print_driver
                mov     SI, offset _use_both
print_driver:
                call    print
                mov     SI, DX
                inc     _number
                call    print
                mov     AL, _memory
                mov     SI, offset _memory_high
                cmp     AL, @high
                je      print_volume
                mov     SI, offset _memory_cnv
print_volume:
                call    print
                mov     SI, DX
                inc     _number
                call    print
                mov     SI, offset _alt_key
                mov     AL, _active
                mov     DI, offset _key_name
test_active:
                scasb
                je      is_active
                push    AX
                xor     AX, AX
                repne   scasb
                pop     AX
                jmp     short test_active
is_active:
                cmp     SI, DI
                jne     not_collision
                mov     SI, offset _ctrl_key
not_collision:
                call    print
                mov     SI, offset _pseudo_key
                call    print
                mov     SI, DX
                inc     _number
                call    print
                mov     SI, DI
                call    print
                mov     SI, offset _active_key
                call    print
                mov     SI, DX
                inc     _number
                call    print
                mov     AL, _extended
                mov     SI, offset _right_key
                cmp     AL, @right
                je      is_right
                mov     SI, offset _left_key
is_right:
                call    print
                mov     SI, DX
                inc     _number
                call    print
                mov     SI, offset _sound_ind
                mov     AL, _indication
                cmp     AL, @sound
                je      is_sound
                mov     SI, offset _border_ind
is_sound:
                call    print
                mov     SI, DX
                inc     _number
                call    print
                mov     AL, _color
                mov     DI, offset _color_name
test_color:
                scasb
                je      is_color
                push    AX
                xor     AX, AX
                repne   scasb
                pop     AX
                jmp     short test_color
is_color:
                mov     SI, DI
                call    print
                mov     SI, offset _border_color
                ret
get_config      endp
;=============================================================================
;               ANALYSE COMMAND LINE
;-----------------------------------------------------------------------------
;               Entering parameter:
;                 DS:SI - command line
;                 CX - length command line
;               Return:
;                 CF clear if successful
;                   BX - pointer to procedure
;                 CF set on error
;                   DS:SI - error message
;-----------------------------------------------------------------------------
@get_command    equ     'g'
;-----------------------------------------------------------------------------
;               COMMAND DATA
;-----------------------------------------------------------------------------
                public  _command_data
_command_data   label   word
                db      'r'
                dw      resident
                db      's'
                dw      save
                db      'g'
                dw      get
                db      'u'
                dw      update
                db      @zero
;-----------------------------------------------------------------------------
;               SWITCH DATA
;-----------------------------------------------------------------------------
                public  _switch_data
_switch_data    label   word
                db      'd'
                dw      check_driver
                db      'm'
                dw      check_memory
                db      'a'
                dw      check_active
                db      'e'
                dw      check_extended
                db      'i'
                dw      check_ind
                db      'c'
                dw      check_color
                db      'f'
                dw      check_file
                db      'k'
                dw      check_file
                db      @zero
;-----------------------------------------------------------------------------
;               KEY DATA
;-----------------------------------------------------------------------------
                public  _key_data
_key_data       label   word
                db      'a', @alt
                db      'c', @ctrl
                db      'r', @rshift
                db      'l', @lshift
                db      @zero
;-----------------------------------------------------------------------------
                public  analyse_cmdline
analyse_cmdline proc    near
                lodsb
                cmp     AL, ' '
                loope   analyse_cmdline
                je      not_command
                call    analyse_letter
                jc      not_command
                mov     BX, offset _command_data
next_command:
                cmp     AL, [BX]
                je      found_command
                add     BX, 3
                cmp     byte ptr DS:[BX], @zero
                je      not_command
                jmp     short next_command
found_command:
                mov     BX, [BX+1]
                jmp     short analyse_get
not_command:
                mov     _command, AL
                mov     SI, offset _incorrect_cmd
                stc
                ret
analyse_get:
                cmp     AL, @get_command
                je      analyse_end
analyse_switch:
                jcxz    analyse_end
                mov     DI, offset _switch
check_space:
                lodsb
                cmp     AL, ' '
                loope   check_space
                je      analyse_end
                jcxz    not_switch
                cmp     AL, '-'
                je      check_switch
                cmp     AL, '/'
                jne     not_switch
check_switch:
                lodsb
                dec     CX
                jcxz    not_switch
                call    analyse_letter
                jc      not_switch
                mov     BP, offset _switch_data
next_switch:
                cmp     AL, DS:[BP]
                je      found_switch
                add     BP, 3
                cmp     byte ptr DS:[BP], @zero
                je      not_switch
                jmp     short next_switch
found_switch:
                stosb
                lodsb
                dec     CX
                call    DS:[BP+1]
                jnc     analyse_switch
                jmp     short not_switch
analyse_end:
                clc
                ret
not_switch:
                stosb
                mov     SI, offset _incorrect_sw
analyse_exit:
                stc
                ret
analyse_cmdline endp
;=============================================================================
;               CHECK DRIVER TYPE
;-----------------------------------------------------------------------------
                public  check_driver
check_driver    proc    near
                call    analyse_letter
                jc      not_driver
                cmp     AL, @display
                je      driver_ok
                cmp     AL, @keyboard
                je      driver_ok
                cmp     AL, @both
                je      driver_ok
not_driver:
                stc
                ret
driver_ok:
                mov     _driver, AL
                clc
                ret
check_driver    endp
;=============================================================================
;               CHECK VOLUME FONT
;-----------------------------------------------------------------------------
                public  check_memory
check_memory    proc    near
                call    analyse_letter
                jc      not_memory
                cmp     AL, @high
                je      memory_ok
                cmp     AL, @conventional
                je      memory_ok
not_memory:
                stc
                ret
memory_ok:
                mov     _memory, AL
                clc
                ret
check_memory    endp
;=============================================================================
;               CHECK ACTIVE KEY
;-----------------------------------------------------------------------------
                public  check_active
check_active    proc    near
                push    DI
                call    analyse_letter
                jc      not_active
                mov     DI, offset _key_data
next_active:
                cmp     AL, [DI]
                je      found_active
                add     DI, 2
                cmp     byte ptr DS:[DI], @zero
                je      not_active
                jmp     short next_active
not_active:
                pop     DI
                stc
                ret
found_active:
                mov     AL, [DI+1]
                mov     _active, AL
                pop     DI
                clc
                ret
check_active    endp
;=============================================================================
;               CHECK EXTENDED KEY TYPE
;-----------------------------------------------------------------------------
                public  check_extended
check_extended  proc    near
                call    analyse_letter
                jc      not_extended
                cmp     AL, @right
                je      extended_ok
                cmp     AL, @left
                je      extended_ok
not_extended:
                stc
                ret
extended_ok:
                mov     _extended, AL
                clc
                ret
check_extended  endp
;=============================================================================
;               CHECK INDICATION TYPE
;-----------------------------------------------------------------------------
                public  check_ind
check_ind       proc    near
                call    analyse_letter
                jc      not_indication
                cmp     AL, @sound
                je      indication_ok
                cmp     AL, @border
                je      indication_ok
not_indication:
                stc
                ret
indication_ok:
                mov     _indication, AL
                clc
                ret
check_ind       endp
;=============================================================================
;               CHECK BORDER COLOR
;-----------------------------------------------------------------------------
                public  check_color
check_color     proc    near
                cmp     AL, '0'
                jb      not_color
                cmp     AL, '9'
                ja      check_hex_up
                sub     AL, 30h
                jmp     short color_ok
check_hex_up:
                cmp     AL, 'A'
                jb      not_color
                cmp     AL, 'F'
                ja      check_hex_down
                sub     AL, 37h
                jmp     short color_ok
check_hex_down:
                cmp     AL, 'a'
                jb      not_color
                cmp     AL, 'f'
                ja      not_color
                sub     AL, 57h
color_ok:
                mov     _color, AL
                clc
                ret
not_color:
                stc
                ret
check_color     endp
;=============================================================================
;               CHECK FONT AND KEYBOARD FILES
;-----------------------------------------------------------------------------
@find_first     equ     4E00h
@find_next      equ     4Fh
@get_dta        equ     2Fh
@name_place     equ     1Eh
@size_place     equ     1Ah
@length_name    equ     7
;-----------------------------------------------------------------------------
                public  check_file
check_file      proc    near
                dec     SI
                inc     CX
                mov     DI, offset _file_name
                mov     BP, DI
                mov     DX, DI
test_letter:
                lodsb
                stosb
                cmp     AL, '\'
                jne     not_slash
                mov     BP, DI
not_slash:
                cmp     AL, ' '
                loopne  test_letter
                jne     end_name
                dec     DI
end_name:
                mov     AL, @zero
                stosb
                push    BX
                push    CX
                push    SI
                push    ES
                xor     CX, CX
                mov     AX, @find_first
                int     @dos
                mov     DI, offset _not_found
                jc      file_error
                mov     AH, @get_dta
                int     @dos
                mov     SI, BX
                add     SI, @name_place
next_file:
                mov     DI, BP
                mov     CX, @length_name
move_file_name:
                mov     AX, ES:[SI]
                mov     [DI], AX
                add     DI, 2
                add     SI, 2
                loop    move_file_name
                mov     DI, offset _invalid_size
                sub     SI, 12h
                mov     AX, ES:[SI]
                cmp     AX, @key_size
                je      next_compare
                cmp     AX, @cga_size
                je      next_compare
                cmp     AX, @ega_size
                je      next_compare
                cmp     AX, @vga_size
                jne     file_error
next_compare:
                mov     CX, AX
                cmp     word ptr ES:[SI+2], @zero
                jne     file_error
                call    read_file
                jc      file_error
                cmp     CX, @key_size
                je      end_read
                add     SI, 4
                mov     AH, @find_next
                int     @dos
                jnc     next_file
end_read:
                pop     ES
                pop     SI
                pop     CX
                pop     BX
                clc
                ret
file_error:
                pop     ES
                pop     SI
                pop     CX
                pop     BX
                mov     SI, offset _sorry
                call    print
                mov     SI, offset _file_name
                call    print
                mov     SI, DI
                pop     AX
                stc
                ret
check_file      endp
;=============================================================================
;               READ FILE
;-----------------------------------------------------------------------------
;               Entering parameter:
;                 CX - size block reading
;                 DS:DX - ASCIIZ string file name
;               Return:
;                 CF clear if successful
;                 CF set on error
;                   DI - pointer to error
;-----------------------------------------------------------------------------
@open_file      equ     3D00h
@read_file      equ     3Fh
@close_file     equ     3Eh
;-----------------------------------------------------------------------------
                public  read_file
read_file       proc    near
                mov     AX, @open_file
                int     @dos
                mov     DI, offset _error_opening
                jc      read_error
                mov     BX, AX
                push    DX
                mov     DX, offset _keyboard_data
                cmp     CX, @key_size
                je      size_ok
                mov     DX, offset _cga_font
                cmp     CX, @cga_size
                je      size_ok
                add     DX, @cga_size
                cmp     CX, @ega_size
                je      size_ok
                add     DX, @ega_size
size_ok:
                mov     AH, @read_file
                int     @dos
                pop     DX
                mov     DI, offset _read_failed
                jc      read_error
                cmp     CX, AX
                jne     read_error
                mov     AH, @close_file
                int     @dos
                clc
                ret
read_error:
                stc
                ret
read_file       endp
;=============================================================================
;               ANALYSE AND CONVERT LETTER
;-----------------------------------------------------------------------------
;               Entering parameter:
;                 AL - code
;               Return:
;                 CF clear if successful
;                   AL - letter
;                 CF set on error
;-----------------------------------------------------------------------------
                public  analyse_letter
analyse_letter  proc    near
                cmp     AL, 'z'
                ja      not_letter
                cmp     AL, 'a'
                jae     is_letter
                cmp     AL, 'Z'
                ja      not_letter
                cmp     AL, 'A'
                jb      not_letter
                or      AL, 20h
is_letter:
                clc
                ret
not_letter:
                stc
                ret
analyse_letter  endp
;=============================================================================
;               PRINT STRING
;-----------------------------------------------------------------------------
;               Entering parameter:
;                 DS:SI - pointer to string (terminated zero)
;               Note:
;                 ASCII(255) use for line feed and cariage return
;-----------------------------------------------------------------------------
@get_mode       equ     0Fh
@teletype       equ     0Eh
@cr             equ     0Dh
@lf             equ     0Ah
;-----------------------------------------------------------------------------
                public  print
print           proc    near
                push    AX
                push    BX
                push    SI
                mov     AH, @get_mode
                int     @video
                mov     AH, @teletype
load_char:
                lodsb
                or      AL, AL
                jz      end_string
                cmp     AL, @cr_lf
                jne     not_cr_lf
                mov     AL, @cr
                int     @video
                mov     AL, @lf
not_cr_lf:
                int     @video
                jmp     short load_char
end_string:
                pop     SI
                pop     BX
                pop     AX
                ret
print           endp
;=============================================================================
;               CYCLIC REDUNDANCY CHECK
;-----------------------------------------------------------------------------
                public  _crc
_crc            dw      ?
;=============================================================================
;               END OF FILE
;-----------------------------------------------------------------------------
                public  _end_of_file
_end_of_file    label   word
;-----------------------------------------------------------------------------
_text           ends

                end     russian
