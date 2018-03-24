.model small
.code
page 80,132

                org     100h
start:
                jmp     install
;*****************************************************************************
;-------------- ДАННЫЕ INS 6450 (National Semiconductor)
;*****************************************************************************
ACEBASE         =       02F8H                   ;базовый адрес порта COM2
RBR             =       ACEBASE                 ;регистр хранения передатчика
THR             =       ACEBASE                 ;регитр данных приемника

IER             =       ACEBASE + 1             ;регистр рахрешения прерывания
IIR             =       ACEBASE + 2             ;регистр идентификации
                                                ;прерывания
DLL             =       ACEBASE                 ;мл. регистр скорости обмена
DLM             =       ACEBASE + 1             ;ст. регистр скорости обмена

LCR             =       ACEBASE + 3             ;регистр управления линии
MCR             =       ACEBASE + 4             ;регистр управления модемом
LSR             =       ACEBASE + 5             ;регитр статуса линии

MODE            =       03H                     ;режим обмена
DIVISOR         =       80H                     ;маска на 7 бит

RRDY            =       01H                     ;готовность приемника
TRDY            =       20H                     ;готовность передатчика

ENBRI           =       01H                     ;разрешение прерываний по приему
ENBTI           =       02H                     ; - // - по передаче
DISI            =       00H                     ;запрет прерываний

ENBIGEN         =       08H                     ;использование прерываний
                                                ;в упралении модемом
BDL             =       0CH                     ;младший байт делителя скорости
BDM             =       00H                     ;старший байт делителя скорости

ERROR           =       1EH                     ;сумма кодов ошибок
;*****************************************************************************
;-------------- ДАННЫЕ PPI 8259 (Intel)
;*****************************************************************************
PICBASE         =       20H                     ;командный регистр прерываний
IMR             =       PICBASE + 1             ;регистр маски прерываний

IRQ3            =       0BH                     ;номер прерывания на IRQ3

ENB3            =       0F7H                    ;маска разрешения прерываний

DIS3            =       08H                     ;маска запрета прерываний

EOI             =       20H                     ;разрешение прерываний
;*****************************************************************************
;-------------- ДАННЫЕ ТАЙМЕРА 8254 (Intel)
;*****************************************************************************
IRQ0            =       08H                     ;номер прерывания по IRQ0
WFT             =       90H                     ;время ожидания ответа
WFR             =       10H
;*****************************************************************************
;-------------- КОНСТАНТЫ ПРОТОКОЛА СЕТИ
;*****************************************************************************
PRE             =       00H                     ;преамбула - начало передачи
EOT             =       04H                     ;конец передачи
CR              =       0DH                     ;возврат каретки
LF              =       0AH                     ;перевод строки
MAXID           =       48H
MINID           =       40H
;*****************************************************************************
;-------------- COPYRIGHT
;*****************************************************************************
_copyright      db      CR,LF
                db      '+--------------------------------------+',CR,LF
                db      '|    Network Terminal. Version: 0.8    |',CR,LF
                db      '| Copyright (C) 1992 by Igor Dolzhikov |',CR,LF
                db      '+--------------------------------------+',CR,LF,0
;*****************************************************************************
;-------------- СЧЕТЧИК ТАЙМЕРА, АКТИВНОСТЬ, СЧЕТЧИК ПОДАВЛЕНИЯ
;*****************************************************************************
_count          db      0
_active         db      0
_jam_number     dw      8
;*****************************************************************************
;-------------- МЕСТО ХРАНЕНИЯ ШТАТНОГО ОБРАБОТЧИКА ПРЕРЫВАНИЙ
;*****************************************************************************
_save_irq3o     dw      0
_save_irq3s     dw      0
_save_irq0o     dw      0
_save_irq0s     dw      0
;*****************************************************************************
;-------------- ПЕРЕМЕННЫЕ ПРОТОКОЛА СЕТИ
;*****************************************************************************
;-------------- буферы кадров
_rbuf           db      512 dup(0)
_tbuf           db      512 dup(0)
_tfbuf          db      3   dup(0)
;-------------- идентификаторы узлов
_mid            db      0
_did            db      0
_nid            db      0
;-------------- буферы однобайтовых портов
_nbyte          db      0
_tbyte          db      0
;-------------- флаги запроса сервиса
_sp             db      0
_dp             db      0
_sf             db      0
_df             db      0
_dnn            db      0
_dnid           db      0
_dtl            db      0
;-------------- флаги кодирования состояния ввода/вывода
_byi            db      0
_byd            db      0
;-------------- флаги кодирования состояния приема/передачи и переменные
_byr            db      0
_bys            db      0
_tl             db      0
_tr             db      0
_state          db      0
_rstate         db      0
_bst            db      0
;-------------- флаги состояния буферов
_rbf            db      0
_tbf            db      0
;-------------- указатели буферов
_tborg          dw      offset _tbuf
_rborg          dw      offset _rbuf
_tforg          dw      offset _tfbuf
_tbnxt          dw      0
_rbnxt          dw      0
_tfnxt          dw      0
_tbend          dw      0
_rbend          dw      0
_tfend          dw      0
_frnxt          dw      offset _tfbuf
_frend          dw      0
;-------------- указатель сообщений
_txtptr         dw      0
;-------------- интерфейсные сообщения
_inpmid         db      'Input identifier main node: ',0
_tlost          db      'Token Lost!',0
_newnid         db      'New identifier next node: ',0
_nonodes        db      'No other nodes on network!',0
;*****************************************************************************
;-------------- ИНИЦИАЛИЗАЦИЯ INS 6250
;*****************************************************************************
init_ace        proc    near
                push    AX
                push    DX
                mov     DX, LCR                 ;регистр контроля линии
                mov     AL, DIVISOR             ;устанавливаем бит 7
                jmp     short $+2               ;пауза
                jmp     short $+2
                out     DX, AL
                mov     DX, DLM                 ;старший байт делителя
                mov     AL, BDM                 ;скорости
                jmp     short $+2               ;пауза
                jmp     short $+2
                out     DX, AL
                mov     DX, DLL                 ;младший байт делителя
                mov     AL, BDL                 ;скорости
                jmp     short $+2               ;пауза
                jmp     short $+2
                out     DX, AL
                mov     DX, LCR                 ;задание режима 8 бит,
                mov     AL, MODE                ;2 стоп бита, без контроля четн.
                jmp     short $+2               ;пауза
                jmp     short $+2
                out     DX, AL
                mov     DX, IER                 ;регистр разрешения прерываний
                mov     AL, DISI                ;запрет прерываний
                jmp     short $+2               ;пауза
                jmp     short $+2
                out     DX, AL
                pop     DX
                pop     AX
                ret
init_ace        endp
;*****************************************************************************
;-------------- РАЗРЕШЕНИЕ И ЗАПРЕТ ПРЕРЫВАНИЙ ПО ПРИЕМУ-ПЕРЕДАЧЕ
;--------------   передаваемые параметры :
;--------------     AL - содержит аргумент разрешения или запрета прерываний
;*****************************************************************************
set_ace_irqs    proc    near
                push    AX
                push    DX
                push    AX                      ;сохранение аргумента
                mov     DX, MCR                 ;регистр управления модемом
                mov     AL, ENBIGEN             ;использование прерываний
                jmp     short $+2               ;пауза
                jmp     short $+2
                out     DX, AL
                pop     AX                      ;восстановление аргумента
                mov     DX, IER                 ;регистр разрешения прерываний
                jmp     short $+2               ;пауза
                jmp     short $+2
                out     DX, AL                  ;посылка аргумента
                pop     DX
                pop     AX
                ret
set_ace_irqs    endp
;*****************************************************************************
;-------------- ПОЛУЧЕНИЕ ДАННЫХ ИЗ СЕТИ
;--------------   возвращаемые параметры :
;--------------     AL - содержит принятый байт
;*****************************************************************************
getc_ace        proc    near
                push    DX
                mov     DX, LSR                 ;регистр статуса линии
retry_getc:
                jmp     short $+2               ;пауза
                jmp     short $+2
                in      AL, DX
                test    AL, RRDY                ;получены ли данные
                jz      retry_getc              ;если нет, повторить
                mov     DX, RBR                 ;регистр хранения передатчика
                jmp     short $+2               ;пауза
                jmp     short $+2
                in      AL, DX                  ;получение данных
                pop     DX
                ret
getc_ace        endp
;*****************************************************************************
;-------------- СБРОС ДАННЫХ ИЗ СЕТИ
;*****************************************************************************
clear_ace       proc    near
                push    AX
                push    DX
                mov     DX, LSR                 ;регистр статуса линии
                jmp     short $+2               ;пауза
                jmp     short $+2
                in      AL, DX
                test    AL, RRDY                ;получены ли данные?
                jz      no_clear                ;если нет, выйти
                mov     DX, RBR                 ;регистр хранения передатчика
                jmp     short $+2               ;пауза
                jmp     short $+2
                in      AL, DX                  ;получение данных
no_clear:
                pop     DX
                pop     AX
                ret
clear_ace       endp
;*****************************************************************************
;-------------- ПОСЫЛКА ДАННЫХ В ШИНУ
;--------------   передаваемые параметры :
;--------------     AL - содержит посылаемый байт
;*****************************************************************************
putc_ace        proc    near
                push    AX
                push    DX
                push    AX
                mov     DX, LSR                 ;регистр статуса линии
retry_putc:
                jmp     short $+2               ;пауза
                jmp     short $+2
                in      AL, DX
                test    AL, TRDY                ;готов ли передатчик
                jz      retry_putc              ;если нет, повторить
                pop     AX
                mov     DX, THR                 ;регистр данных приемника
                jmp     short $+2               ;пауза
                jmp     short $+2
                out     DX, AL                  ;посылка данных
                pop     DX
                pop     AX
                ret
putc_ace        endp
;*****************************************************************************
;-------------- ПРОВЕРКА НА ОШИБКУ В СЕТИ
;--------------   возвращаемые параметры :
;--------------     AL = 0, при отсутствии ошибки
;--------------     AL = code - код ошибки
;*****************************************************************************
error_ace       proc    near
                push    DX
                mov     DX, LSR                 ;регистр статуса линии
                jmp     short $+2               ;пауза
                jmp     short $+2
                in      AL, DX                  ;чтение статуса
                test    AL, ERROR               ;присутсвует ли ошибка
                jnz     save_error              ;если да, то сохранение ее
                xor     AX, AX                  ;ошибки отсутсвуют AL = 0
save_error:
                pop     DX
                ret
error_ace       endp
;*****************************************************************************
;-------------- РАЗРЕШЕНИЕ ПРЕРЫВАНИЙ ПО IRQ3
;*****************************************************************************
enable_irq3     proc    near
                push    AX
                push    DX
                mov     DX, IMR                 ;регистр маски прерываний
                in      AL, DX
                and     AL, ENB3                ;наложение маски
                jmp     short $+2               ;пауза
                jmp     short $+2
                out     DX, AL
                pop     DX
                pop     AX
                ret
enable_irq3     endp
;*****************************************************************************
;-------------- ЗАПРЕТ ПРЕРЫВАНИЙ ПО IRQ3
;*****************************************************************************
disable_irq3    proc    near
                push    AX
                push    DX
                mov     DX, IMR                 ;регистр маски прерываний
                in      AL, DX
                or      AL, DIS3                ;наложение маски
                jmp     short $+2               ;пауза
                jmp     short $+2
                out     DX, AL
                pop     DX
                pop     AX
                ret
disable_irq3    endp
;*****************************************************************************
;-------------- ОКОНЧАНИЕ ПРЕРЫВАНИЯ
;*****************************************************************************
clr_ints        proc    near
                push    AX
                push    DX
                mov     DX, PICBASE             ;командный регистр прерываний
                mov     AL, EOI
                out     DX, AL
                pop     DX
                pop     AX
                ret
clr_ints        endp
;*****************************************************************************
;-------------- ВОЗВРАТ АДРЕСА ПРЕРЫВАНИЯ
;--------------   передаваемые параметры :
;--------------     AL - номер прерывания
;--------------   возвращаемые параметры : DX:CX
;--------------     CX - младший байт адреса вектора прерывания
;--------------     DX - старший байт адреса вектора прерывания
;*****************************************************************************
interrupt_get   proc    near
                push    AX
                push    BX
                push    DS
                mov     AH, 0
                shl     AX, 1                   ;адрес вектора AX * 4
                shl     AX, 1
                mov     BX, AX                  ;BX - адрес вектора
                xor     AX, AX                  ;AX = 0
                mov     DS, AX                  ;DS = 0
                cli
                mov     CX, [BX]                ;CX - смещение вектора
                mov     DX, [BX+2]              ;DX - сегмент вектора
                sti
                pop     DS
                pop     BX
                pop     AX
                ret
interrupt_get   endp
;*****************************************************************************
;-------------- УСТАНОВКА НОВОГО ОБРАБОТЧИКА ПРЕРЫВАНИЯ
;--------------   передаваемые параметры : DX:CX
;--------------     AL - номер прерывания
;--------------     CX - младший байт адреса вектора прерывания
;--------------     DX - старший байт адреса вектора прерывания
;*****************************************************************************
interrupt_set   proc    near
                push    AX
                push    BX
                push    DS
                mov     AH, 0
                shl     AX, 1                   ;адрес вектора AX * 4
                shl     AX, 1
                mov     BX, AX                  ;BX - адрес вектора
                xor     AX, AX                  ;AX = 0
                mov     DS, AX                  ;DS = 0
                cli
                mov     [BX], CX                ;[BX]   - смещение вектора
                mov     [BX+2], DX              ;[BX+2] - сегмент вектора
                sti
                pop     DS
                pop     BX
                pop     AX
                ret
interrupt_set   endp
;*****************************************************************************
;-------------- ЧТЕНИЕ КЛАВИШИ
;--------------   возвращаемые параметры :
;--------------     AL - содержит код знака
;--------------     AH - скэн код клавиши
;--------------     AX = 0 клавиша не нажата
;*****************************************************************************
kbdhit          proc    near
                mov     AH, 1                   ;функция опроса клавиатуры
                int     16H                     ;без ожидания
                jz      no_key
                mov     AH, 0                   ;чтение скэн-кода
                int     16H
                jmp     short yes
no_key:
                xor     AX, AX
yes:
                ret
kbdhit          endp
;*****************************************************************************
;-------------- ВЫВОД БАЙТА НА ЭКРАН
;--------------   передаваемые параметры :
;--------------     AL - выводимый байт
;*****************************************************************************
putch           proc    near
                push    AX
                push    BX
                mov     AH, 0EH                 ;функция вывода в режиме
                xor     BX, BX                  ;телетайпа
                int     10H
                pop     BX
                pop     AX
                ret
putch           endp
;*****************************************************************************
;-------------- ВЫВОД СТРОКИ НА ЭКРАН
;--------------   передаваемые параметры :
;--------------     _txtptr - смещение выводимой строки (последний элемент 0)
;*****************************************************************************
display_txt     proc    near
                push    AX
                push    BX
                push    SI
                mov     SI, _txtptr             ;SI - указатель сообщения
write:
                lodsb
                or      AL, AL
                jz      end_write
                mov     AH, 0EH                 ;функция вывода в режиме
                xor     BX, BX                  ;телетайпа
                int     10H
                jmp     short write
end_write:
                pop     SI
                pop     BX
                pop     AX
                ret
display_txt     endp
;*****************************************************************************
;-------------- УСТАНОВКА НОВОГО ОБРАБОТЧИКА ПРЕРЫВАНИЙ ПО IRQ0
;*****************************************************************************
setup_irq0      proc    near
                push    AX
                push    CX
                push    DX
                mov     AL, IRQ0                ;установка прерывания на IRQ0
                call    interrupt_get
                mov     _save_irq0o, CX         ;записать смещение
                mov     _save_irq0s, DX         ;записать сегмент
                mov     CX, offset timer_isr    ;установить новое смещение
                mov     DX, CS                  ;установить новый сегмент
                call    interrupt_set
                pop     DX
                pop     CX
                pop     AX
                ret
setup_irq0      endp
;*****************************************************************************
;-------------- ВОСТАНОВЛЕНИЕ ШТАТНОГО ОБРАБОТЧИКА ПРЕРЫВАНИЙ ПО IRQ0
;*****************************************************************************
restore_irq0    proc    near
                push    AX
                push    CX
                push    DX
                mov     AL, IRQ0                ;прерывание на IRQ0
                mov     CX, _save_irq0o         ;востановить штатное смещение
                mov     DX, _save_irq0s         ;востановить штатное сегмент
                call    interrupt_set
                pop     DX
                pop     CX
                pop     AX
                ret
restore_irq0    endp
;*****************************************************************************
;-------------- ОБРАБОТЧИК ПРЕРЫВАНИЯ ПО IRQ0
;*****************************************************************************
timer_isr       proc    far
                sti
                push    AX
                push    CX
                push    DS
                push    CS
                pop     DS
                cmp     _active, 0
                jz      no_active
                dec     _count                  ;увеличить счетчик
                jnz     no_active
                mov     _active, 0
                cmp     _state,3
                jz      inquiry
                cmp     _state, 0
                jnz     test_lost
inquiry:
                mov     _state, 1
                call    poll
                jmp     short no_active
test_lost:
                cmp     _state, 4
                jnz     no_active
                mov     _state, 0
                mov     _dtl, 1
                mov     AL, _mid
                sub     AL, 40h
                call    timer_to_wait
                mov     AL, _mid
                mov     _nid, AL
no_active:
                pop     DS
                pop     CX
                pop     AX
                jmp     dword ptr CS:_save_irq0o
timer_isr       endp
;*****************************************************************************
;-------------- УСТАНОВКА НОВОГО ОБРАБОТЧИКА ПРЕРЫВАНИЙ ПО IRQ3
;*****************************************************************************
setup_irq3      proc    near
                push    AX
                push    CX
                push    DX
                mov     AL, IRQ3                ;установка прерывания на IRQ3
                call    interrupt_get
                mov     _save_irq3o, CX         ;записать смещение
                mov     _save_irq3s, DX         ;записать сегмент
                mov     CX, offset nisr         ;установить новое смещение
                mov     DX, CS                  ;установить новый сегмент
                call    interrupt_set
                pop     DX
                pop     CX
                pop     AX
                ret
setup_irq3      endp
;*****************************************************************************
;-------------- ВОСТАНОВЛЕНИЕ ШТАТНОГО ОБРАБОТЧИКА ПРЕРЫВАНИЙ ПО IRQ3
;*****************************************************************************
restore_irq3    proc    near
                push    AX
                push    CX
                push    DX
                mov     AL, IRQ3                ;прерывание на IRQ3
                mov     CX, _save_irq3o         ;востановить штатное смещение
                mov     DX, _save_irq3s         ;востановить штатное сегмент
                call    interrupt_set
                pop     DX
                pop     CX
                pop     AX
                ret
restore_irq3    endp
;*****************************************************************************
;-------------- ОБРАБОТЧИК ПРЕРЫВАНИЯ ПО IRQ3
;*****************************************************************************
nisr            proc    far
                sti                             ;разрешение немаскируемых
                cld                             ;прерываний и сброс флага
                push    AX
                push    CX
                push    DS                      ;направления
                push    ES
                push    CS                      ;установка сегмента данных
                pop     DS                      ;и дополнительного сегмента
                push    CS
                pop     ES
                cmp     _state, 0
                jz      start_rec
                cmp     _state, 3
                jz      start_rec
                cmp     _state, 4
                jnz     cmp_jam
start_rec:
                call    receive                 ;если есть сигнал, то прием
                jmp     short end_nisr
cmp_jam:
                cmp     _state, 2
                jnz     sd
                mov     _state, 0
                mov     AL, _mid
                sub     AL, 40h
                call    timer_to_wait
                jmp     short end_nisr
sd:
                call    send
end_nisr:
                pop     ES
                pop     DS
                pop     CX
                pop     AX
                cli
                call    clr_ints                ;сообщить об окончании
                iret                            ;прерывания
nisr            endp
;*****************************************************************************
;--------------  ПРИЕМ БАЙТА
;*****************************************************************************
receive         proc    near
                push    AX
                call    getc_ace                ;принять символ
                mov     _nbyte, AL              ;запомнить его
                call    error_ace               ;проверить на ошибку
                cmp     AL, 0
                jnz     end_receive             ;если ошибка, то выход
                cmp     _nbyte, PRE             ;если это не PRE
                jnz     next_receive1           ;продолжить дальше
                call    PRE_received            ;отметить получение PRE
                cmp     _state, 3
                jnz     end_receive
                mov     _state, 4
                mov     _dnid, 1
                mov     AL, WFT
                call    timer_to_wait
                jmp     short end_receive
next_receive1:
                cmp     _rstate, 1              ;если не получен 2-ой байт
                jnz     next_receive2           ;пакета продолжить дальше
                call    DID_received            ;проверить адрес сообщения
                jmp     short end_receive
next_receive2:
                cmp     _rstate, 2              ;если не прием пакета
                jnz     wait_pre                ;продолжить дальше
                cmp     _nbyte, EOT             ;прием маркера
                jnz     wait_pre
                call    END_received
                jmp     short end_receive
wait_pre:
                mov     _rstate, 0
end_receive:
                pop     AX
                ret
receive         endp
;******************************************************************************
;
;******************************************************************************
END_received    proc    near
                push    DI
                cmp     _state, 0
                jnz     no_sleep
                mov     _state, 1
                mov     AL, _mid
                mov     _nid, AL
                call    poll
                jmp     short s_t
no_sleep:
                cmp     _state, 4
                jnz     s_t
                mov     _state, 5
s_t:
                mov     _active, 0
                mov     DI, _tforg
                mov     _frnxt, DI
                inc     DI
                mov     AL, _nid
                stosb
                mov     _rstate, 0
                mov     AL, ENBTI
                call    set_ace_irqs
                pop     DI
                ret
END_received    endp
;*****************************************************************************
;-------------- ПОЛУЧЕНИЕ ПРЕАМБУЛЫ
;*****************************************************************************
PRE_received    proc    near
                mov     _rstate, 1              ;начать ожидание байта _did
                ret
PRE_received    endp
;*****************************************************************************
;-------------- ПОЛУЧЕНИЕ АДРЕСА СООБЩЕНИЯ
;*****************************************************************************
DID_received    proc    near
                push    AX
                mov     AL, _mid
                cmp     _nbyte, AL              ;если получен _mid и буфер _rbuf
                jnz     init_rstate             ;свободен начать прием пакета
                mov     _rstate, 2
                jmp     short beg_rec
init_rstate:
                mov     _rstate, 0              ;начать ожидание байта PRE
beg_rec:
                pop     AX
                ret
DID_received    endp
;*****************************************************************************
;-------------- ПОЛУЧЕНИЕ МАРКЕРА
;*****************************************************************************
token_received  proc    near
                push    AX
                cmp     _nbyte, EOT             ;если получен пакет
                jnz     next_rstate             ;начать прием пакета
                mov     _rstate, 0              ;сбросить состояние сет. уровня
                mov     _active, 0              ;остановить счетчик
                call    start_transmit          ;подготовить возможную передачу
                jmp     short end_trec          ;пакета
next_rstate:
                cmp     _rbf, 0                 ;если _rbuf не пуст
                jnz     clr_rstate              ;сбросить состояние
                push    DI
                mov     DI, _rbnxt
                mov     AL, _nbyte
                stosb                           ;запомнить байт в _rbuf
                mov     _rbnxt, DI
                mov     _rstate, 3              ;перейти в следующее состояние
                pop     DI
                jmp     short end_trec
clr_rstate:
                mov     _rstate, 0              ;начать ожидание байта PRE
end_trec:
                pop     AX
                ret
token_received  endp
;*****************************************************************************
;-------------- ОБРАБОТКА БАЙТА, ПОЛУЧЕННОГО ИЗ СЕТИ
;*****************************************************************************
accept          proc    near
                push    AX
                push    DI
                mov     DI, _rbnxt              ;загрузить адрес след. байта
                cmp     _nbyte, EOT             ;если не конец приема,
                jnz     no_end                  ;то, переход
                mov     _dp, 1                  ;установить _dp = 1
                mov     _rbf, 1                 ;установить _rbf = 1
                mov     _rstate, 0              ;установить _rstate = 0
                mov     _rbend, DI              ;установить _rbend = _rbnxt
                mov     AX, _rborg
                mov     _rbnxt, AX              ;установить _rbnxt = _rborg
                jmp     short end_accept        ;перейти на конец приема
no_end:
                mov     AL, _nbyte              ;загрузить байт
                stosb
                mov     _rbnxt, DI              ;запомнить указатель на сл. байт
end_accept:
                pop     DI
                pop     AX
                ret
accept          endp
;*****************************************************************************
;--------------  ПЕРЕДАЧА БАЙТА
;*****************************************************************************
send            proc    near
                push    AX
                push    SI
                mov     SI, _frnxt              ;загрузить адрес след. байта
                cmp     SI, _frend              ;если это не конец передачи
                jnz     next_send               ;перейти дальше
                cmp     _state, 1
                jnz     n_s
                mov     _state, 3
                mov     AL, WFR
                call    timer_to_wait
                jmp     short e_r
n_s:
                cmp     _state, 5
                jnz     e_r
                mov     _state, 4
                mov     AL, WFT
                call    timer_to_wait
e_r:
                call    enable_receive
                jmp     short end_send          ;перейти на конец передачи
next_send:
                lodsb                           ;загрузить след. байт
                call    putc_ace                ;передать его в сеть
                mov     _frnxt, SI              ;установить указатель на
end_send:                                       ;следующий байт
                pop     SI
                pop     AX
                ret
send            endp
;*****************************************************************************
;--------------  ПЕРЕДАЧА МАРКЕРА
;*****************************************************************************
send_token      proc    near
                push    AX
                push    SI
                mov     SI, _tfnxt              ;загрузить адрес след. байта
                cmp     SI, _tfend              ;если это не конец передачи
                jnz     next_st                 ;перейти дальше
                mov     _bst, 0                 ;окончание передачи маркера
                mov     AX, _tforg
                mov     _tfnxt, AX              ;установить _tfnxt = _tforg
                call    timer_to_wait           ;ждать возвращения маркера
                call    enable_receive          ;разрешить прерывния приема
                jmp     short end_st            ;перейти на конец передачи
next_st:
                lodsb                           ;загрузить след. байт
                call    putc_ace                ;передать его в сеть
                mov     _tfnxt, SI              ;установить указатель на
end_st:                                         ;следующий байт
                pop     SI
                pop     AX
                ret
send_token      endp
;*****************************************************************************
;-------------- РАЗРЕШЕНИЕ ПРИЕМА
;*****************************************************************************
enable_receive  proc    near
                push    AX
                call    clear_ace               ;освободить буфер ACE
                call    clear_ace
                call    clear_ace
                mov     AL, ENBRI
                call    set_ace_irqs            ;разрешить прерывания приема
                pop     AX
                ret
enable_receive  endp
;*****************************************************************************
;-------------- ЗАПУСК ТАЙМЕРА И ОЖИДАНИЕ ОТВЕТА
;*****************************************************************************
timer_to_wait   proc    near
                mov     _count, AL              ;инициализировать счетчик
                mov     _active, 1              ;начать счет
                ret
timer_to_wait   endp
;*****************************************************************************
;-------------- ИНИЦИАЛИЗАЦИЯ
;*****************************************************************************
initialize      proc    near
                push    AX
                push    DI
                mov     DI, _tforg
                mov     AL, PRE
                stosb                           ;загрузить PRE в 1 байт _tfbuf
                mov     AL, _mid
                mov     _nid, AL
                stosb                           ;загрузить _mid в 2 байт _tfbuf
                mov     AL, EOT
                stosb                           ;загрузить EOT в 1 байт _tfbuf
                mov     _tfend, DI              ;инициализировать _tbend
                mov     _frend, DI
                mov     DI, _tforg
                mov     _frnxt, DI              ;инициализация указателя _frnxt
                call    init_ace                ;инициализация Intel 8250
                call    setup_irq3              ;установить новый обработчик
                call    setup_irq0              ;установить новый обработчик
                call    clr_ints                ;сбросить прерывания
                call    enable_irq3             ;разрешить прерывания по IRQ3
                pop     DI
                pop     AX
                ret
initialize      endp
;*****************************************************************************
;-------------- ПЛАНИРОВЩИК
;--------------   возвращаемые параметры :
;--------------     AL - код выхода
;--------------     AL = 0 - продолжение работы
;--------------     AL = 1 - конец работы
;*****************************************************************************
schedule        proc    near
                cmp     _dnid, 1                ;пров. установку нового _nid
                jnz     next_test_1             ;если запрос отсутсвует, переход
                mov     _dnid, 0
                mov     _txtptr, offset _newnid
                call    display_txt
next_test_1:
                cmp     _dtl, 1                 ;пров. потерю маркера
                jnz     next_test_2             ;если маркер не потерян, переход
                mov     _dtl, 0
                mov     _txtptr, offset _tlost
                call    display_txt
next_test_2:
                cmp     _dnn, 1
                jnz     test_key
                mov     _dnn, 0
                mov     _txtptr, offset _nonodes
                call    display_txt
test_key:
                call    kbdhit                  ;проверка наличия введенного
                or      AX, AX                  ;байта
                jz      end_schedule            ;если отсутсвует, то переход
                cmp     AX, 011BH               ;проверить на ESC
                jz      end_schedule            ;выход из процедуры, если ESC
                xor     AL, AL                  ;установка кода возврата
end_schedule:
                ret
schedule        endp
;*****************************************************************************
;               ПРОГРАММА ОПРОСА
;*****************************************************************************
poll            proc    near
                push    AX
                push    DI
                push    ES
                push    CS
                pop     ES
                inc     _nid
                cmp     _nid, MAXID
                jbe     no_last
                mov     _nid, MINID
no_last:
                mov     AL, _nid
                cmp     AL, _mid
                jnz     next_nid
                mov     _dnn, 1
                mov     _state, 2
                jmp     short end_poll
next_nid:
                mov     DI, _tforg
                mov     _frnxt, DI
                inc     DI
                mov     AL, _nid
                stosb
                mov     AL, ENBTI
                call    set_ace_irqs
end_poll:
                pop     ES
                pop     DI
                pop     AX
                ret
poll            endp
;*****************************************************************************
;-------------- ВОССТАНОВЛЕНИЕ РЕЖИМА РАБОТЫ
;*****************************************************************************
restore         proc    near
                call    disable_irq3            ;маска запрета прерываний
                call    restore_irq3            ;восстановление вектора
                call    restore_irq0            ;восстановление вектора
                ret
restore         endp
;*****************************************************************************
;-------------- НАЧАЛО ПЕРЕДАЧИ ПАКЕТА
;*****************************************************************************
start_transmit  proc    near
                push    AX
                cmp     _sp, 1
                jnz     set_bst
                mov     _bys, 1                 ;сигнал о занятости передачи
                mov     _sp, 0                  ;запрос на посылку пакета
                jmp     short beg_trans
set_bst:
                mov     _bst, 1                 ;сигнал о посылке маркера
beg_trans:
                mov     AL, ENBTI
                call    set_ace_irqs            ;разрешение прерываний
                pop     AX                      ;по передаче
                ret
start_transmit  endp
;*****************************************************************************
;-------------- ВВОД ПАКЕТА
;*****************************************************************************
input           proc    near
                push    AX
                push    DI
                cmp     _tbf, 0                 ;пров. заполнен ли буфер перед.
                jnz     end_input               ;если заполнен, то выход
                cmp     _byi, 0                 ;пров. сигнал занятости ввода
                jnz     active                  ;если занято, не устанавливать
                mov     _byi, 1                 ;установить сигнал
                mov     AL, _tbyte              ;подготовить байт для ввода
                call    putch                   ;отобразить его
                mov     DI, _tbnxt              ;загрузить did в буфер
                stosb
                mov     _tbnxt, DI              ;возвратить инкремент адреса
                mov     AL, _mid
                stosb                           ;загрузить _mid
                mov     _tbnxt, DI              ;возвратить инкремент адреса
                jmp     short end_input
active:
                mov     AL, _tbyte              ;подготовить байт для ввода
                call    putch                   ;отобразить его
                mov     DI, _tbnxt              ;загрузить его в буфер
                stosb
                mov     _tbnxt, DI              ;возвратить инкремент адреса
                cmp     AL, CR                  ;проверить на CR
                jnz     end_input               ;если не CR, то переход
                mov     AL, LF                  ;отобразить LF
                call    putch
                stosb                           ;загрузить LF
                mov     AL, EOT
                mov     _tbend, DI              ;установить _tbend = _tbnxt
                stosb                           ;загрузить EOT
                mov     _sp, 1                  ;установить _sp = 1
                mov     _tbf, 1                 ;установить _tbf = 1
                mov     _byi, 0                 ;установить _byi = 0
                mov     AX, _tborg
                mov     _tbnxt, AX              ;установить _tbnxt = _tborg
end_input:
                pop     DI
                pop     AX
                ret
input           endp
;*****************************************************************************
;-------------- ВЫВОД ПАКЕТА
;*****************************************************************************
output          proc    near
                push    AX
                push    SI
                mov     _dp, 0                  ;сбросить запрос на отображение
                mov     SI, _rbnxt              ;загрузить адрес буфера приема
retry_output:
                cmp     SI, _rbend              ;сравнить с указателем конца
                jae     end_output              ;если конец, то переход
                lodsb                           ;загрузить байт
                call    putch                   ;отобразить его
                jmp     short retry_output      ;повторить сначала
end_output:
                mov     _rbf, 0                 ;буфер приема теперь свободен
                mov     AX, _rborg              ;установить _rbnxt = _rborg
                mov     _rbnxt, AX
                pop     SI
                pop     AX
                ret
output          endp
;*****************************************************************************
;-------------- ВЫВОД СООБЩЕНИЯ О ПОТЕРЕ МАРКЕРА
;*****************************************************************************
disp_token_lost proc    near
                push    AX
                mov     AX, offset _tlost       ;присвоить указателю сообщение
                mov     _txtptr, AX             ;_txtptr^ = _tlost
                call    display_txt             ;отобразить сообщение
                pop     AX                      ;следующей строки
                ret
disp_token_lost endp
;*****************************************************************************
;-------------- ВВОД ИДЕНТИФИКАТОРА УЗЛА MID
;*****************************************************************************
input_MID       proc    near
                push    AX
                mov     AX, offset _inpmid      ;присвоить указателю сообщение
                mov     _txtptr, AX             ;_txtptr^ = _inpmid
                call    display_txt             ;отобразить сообщение
                call    input_byte              ;считать _mid
                mov     AL, _tbyte              ;установить идентификатор узла
                mov     _mid, AL                ;_mid = _tbyte
                call    end_display             ;перевести курсор в начало
                pop     AX                      ;следующей строки
                ret
input_MID       endp
;*****************************************************************************
;-------------- ВВОД БАЙТА
;--------------   возвращаемые параметры:
;--------------     _tbyte - введенный байт
;*****************************************************************************
input_byte      proc    near
                push    AX
wait_key:
                call    kbdhit                  ;ждать нажатия клавиши
                cmp     AX, 0
                jz      wait_key
                mov     _tbyte, AL              ;запомнить введенный байт
                pop     AX
                ret
input_byte      endp
;*****************************************************************************
;-------------- ОКНЧАНИЕ ОТОБРАЖЕНИЯ
;*****************************************************************************
end_display     proc    near
                push    AX
                mov     AL, _tbyte              ;отобразить введенный байт
                call    putch
                mov     AL, CR                  ;отобразить CR
                call    putch
                mov     AL, LF                  ;отобразить LF
                call    putch
                pop     AX
                ret
end_display     endp
;*****************************************************************************
;-------------- НАЧАЛО ПРОГРАММЫ
;*****************************************************************************
install:
                mov     AX, offset _copyright   ;присвоить указателю сообщение
                mov     _txtptr, AX             ;_txtptr^ = _copyright
                call    display_txt             ;отобразить сообщение
                call    input_MID               ;ввести _mid
                call    initialize              ;инициализация
                mov     CX, _jam_number
jamming:
                mov     AL, PRE
                call    putc_ace
                loop    jamming
                call    enable_receive
                mov     AL, _mid
                sub     AL, 40h
                call    timer_to_wait
retry:
                call    schedule                ;запуск планировщика
                cmp     AL, 0
                jz      retry
                call    restore                 ;восстановить режим работы
;*****************************************************************************
;-------------- ВЫХОД ИЗ ПРОГРАММЫ
;*****************************************************************************
                int     20H
                end     start
