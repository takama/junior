
_text           segment byte public
                assume  CS:_text, DS:_text

;=============================================================================
;               CONSTANTS
;-----------------------------------------------------------------------------
@zero           equ     0
@video          equ     10h
@keyboard       equ     16h
@jump_far_code  equ     0EAh                    ;jump far code
;-----------------------------------------------------------------------------

                org     @zero

;=============================================================================
;               PRIMARY PROCEDURE
;-----------------------------------------------------------------------------
@load_position  equ     7C00h                   ;loading position
@vector_13      equ     004Ch                   ;interrupt vector 13h
@memory_size    equ     0413h                   ;free memory size
@length_body    equ     0100h                   ;length body in word
;-----------------------------------------------------------------------------
protect         proc    far
                cli
                xor     AX, AX
                mov     SS, AX                  ;SS = 0
                mov     SP, @load_position      ;SP = 7C00h
                mov     SI, SP                  ;SI = 7C00h
                mov     DS, AX                  ;DS = 0
                cld
;-----------------------------------------------------------------------------
;               allocate memory to upper address
;-----------------------------------------------------------------------------
                mov     AX, word ptr DS:@memory_size
                dec     AX
                mov     word ptr DS:@memory_size, AX
;-----------------------------------------------------------------------------
;               calculation segment
;-----------------------------------------------------------------------------
                mov     CL, 6
                shl     AX, CL                  ;calculation byte to Kbyte
                push    AX                      ;load in stack CS
                mov     ES, AX
;-----------------------------------------------------------------------------
;               set new interrupt 13h
;-----------------------------------------------------------------------------
                mov     word ptr DS:@vector_13, offset int_13
                mov     word ptr DS:@vector_13+2, AX
;-----------------------------------------------------------------------------
;               transmit body in allocate memory and jump
;-----------------------------------------------------------------------------
                mov     AX, offset continuation
                push    AX                      ;load in stack IP
                mov     BX, SI                  ;BX = 7C00h
                xor     DI, DI                  ;DI = 0
                mov     CX, @length_body
                rep     movsw                   ;transmit CX words
                sti
                retf                            ;jump to allocated memory
protect         endp
;=============================================================================
;               PRINT QUESTION AND PROCESSING DISK'S
;-----------------------------------------------------------------------------
@read_sector    equ     0201h                   ;read one sector
@save_sector    equ     0301h                   ;save one sector
@hard_disk      equ     80h                     ;hard disk - 1
@MBR            equ     01h                     ;master boot record
@set_page_3     equ     0503h                   ;set page 3
@set_page_0     equ     0500h                   ;set page 0
@page_3         equ     03h                     ;page 3
@question       equ     0E3Fh                   ;question
@starlet        equ     0E2Ah                   ;starlet
@length_psw     equ     8                       ;length password
@enter_key      equ     1C0Dh                   ;enter key
;-----------------------------------------------------------------------------
continuation:
                push    CS
                pop     DS
                xor     AX, AX                  ;AX = 0
                push    AX                      ;load in stack CS
                push    BX                      ;load in stack IP
                push    BX
                mov     DL, @hard_disk          ;both hard disks and floppy
                call    bios_13                 ;disks reset
                mov     CX, @MBR                ;cylinder - 0, sector - 1
                xor     DH, DH
                mov     AX, @read_sector        ;read one sector
                mov     BX, AX
                dec     BX                      ;BX = 0200h
                call    bios_13                 ;read MBR
                call    compare_sectors         ;compare MBR and body
                je      coincide                ;jump if coincide
                mov     AX, @save_sector        ;save one sector
                xor     BX, BX                  ;BX = 0
                call    bios_13                 ;save body
coincide:
                mov     AX, @set_page_3
                int     @video
                mov     AX, @question
                mov     BH, @page_3
                int     @video
                xor     DX, DX
                mov     CX, @length_psw
repeat:
                xor     AX, AX
                int     @keyboard
                cmp     AX, @enter_key
                je      read_MBR
                xor     DX, AX
                mov     AX, @starlet
                mov     BH, @page_3
                int     @video
                loop    repeat
read_MBR:
                xor     AX, AX
                mov     ES, AX
                pop     BX
                xor     _cyl_sec, DX
                xor     _head_disk, DX
                mov     CX, _cyl_sec
                mov     DX, _head_disk
                mov     AX, @read_sector        ;read one sector
                call    bios_13                 ;read hide MBR
                jc      new_load
                mov     AX, @set_page_0
                int     @video
                retf
new_load:       db      @jump_far_code
                dw      0FFF0h
                dw      0F000h
;=============================================================================
;               INTERRUPT 13H
;-----------------------------------------------------------------------------
int_13          proc    far
                cmp     DL, @hard_disk          ;check hard disk
                jne     end_13                  ;jump if not hard disk
                cmp     CH, @zero               ;control cylinder 0
                jnz     end_13                  ;if not zero - jump
                cmp     DH, @zero               ;control head 0
                jnz     end_13                  ;if not zero - jump
                cmp     CL, @MBR                ;control sector MBR
                jne     end_13                  ;if not MBR - jump
                mov     CX, CS:_cyl_sec
                mov     DX, CS:_head_disk
end_13:
                db      @jump_far_code          ;jump to procedure (vector 13h)
_ROM_13         dd      0F000A1EBh              ;address ROM BIOS 13h
_cyl_sec        dw      0FDA8h
_head_disk      dw      02DE9h
int_13          endp
;=============================================================================
;               CALL ROM BIOS INTERRUPT 13H
;-----------------------------------------------------------------------------
bios_13         proc    near
                pushf                           ;save flags
                call    _ROM_13
                ret                             ;return
bios_13         endp
;=============================================================================
;               COMPARE SECTORS (two words)
;-----------------------------------------------------------------------------
compare_sectors proc    near
                mov     DI, offset _cyl_sec
                mov     SI, offset _cyl_sec + 200h
                cmpsw                           ;compare word
                jne     different               ;if different - jump
                cmpsw                           ;compare word
different:
                ret
compare_sectors endp
;=============================================================================
;               SYSTEM MESSAGE
;-----------------------------------------------------------------------------
                db      'Missing operating system', 0
                db      'Error loading operating system', 0
                db      'Invalid partition table', 0, 'BK'
;=============================================================================
;               PARTITION TABLE
;-----------------------------------------------------------------------------
@start_part     equ     01BEh
@boot           equ     80h
@start_side     equ     1
@start_sector   equ     1
@start_cylinder equ     0
@system_type    equ     6
@end_side       equ     4
@end_sector     equ     17
@end_cylinder   equ     3
@first_sector   equ     17
@sector_number  equ     340
;-----------------------------------------------------------------------------
                org     @start_part
                db      @boot
                db      @start_side
                db      @start_sector
                db      @start_cylinder
                db      @system_type
                db      @end_side
                db      @end_sector
                db      @end_cylinder
                dd      @first_sector
                dd      @sector_number
;=============================================================================
;               END OF PROGRAMM
;-----------------------------------------------------------------------------
@key_position   equ     01FEh                   ;position word extended BIOS
@key            equ     0AA55h                  ;word check extended BIOS
;-----------------------------------------------------------------------------
                org     @key_position
                dw      @key
;-----------------------------------------------------------------------------
_text           ends

                end     protect
