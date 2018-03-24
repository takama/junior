#define buff 32767

#include <me.h>

/* указатели на функции */
/* -------------------- */
unsigned (*send)( unsigned, unsigned );
unsigned (*receive)( unsigned );

long filesize( int handle );
void win_error(char *error);
void write_str(char *str, int atr, int x, int y);

/* передача/прием файла */
/* -------------------- */
void send_file( char *fname );
void rec_file();
void send_file_name( char *f );
void get_file_name( char *f );
void wait(unsigned com_port, char ch);
void sport(unsigned com_port, unsigned code);
unsigned rport(unsigned com_port);

/* идентификация компьютера */
/* ------------------------ */
void init_PC();

/* вывод десятичных чисел */
void write_dec( unsigned long digit, unsigned pos, int atr, int x, int y );

/* глобальные переменные */
/* --------------------- */
char buffer[buff];
unsigned port;
enum PC_type {AT386,AT286S,AT286,Iskra,None} PC;
unsigned err;
unsigned err1, err2;
int      snow;
char     error1[] = "Незарегистрированная версия!";
char     error2[] = "Ошибка открытия файла!";
char     error3[] = "Ошибка чтения даты файла!";
char     error4[] = "Ошибка чтения атрибутов файла!";
char     error5[] = "Ошибка чтения файла!";
char     error6[] = "Ошибка чтения блока данных!";
char     error7[] = "Ошибка CRC!";
char     error8[] = "Ошибка закрытия файла!";
char     error9[] = "Ошибка создания файла!";
char     error10[] = "Ошибка записи файла!";
char     error11[] = "Ошибка записи блока данных!";
char     error12[] = "Ошибка записи даты файла!";
char     error13[] = "Ошибка закрытия файла!";
char     error14[] = "Ошибка записи атрибутов файла!";
char     error15[] = "Ошибка установления связи!";
char     error16[] = "Ошибка передачи данных в последовательном порту!";
char     error17[] = "Ошибка приема данных в последовательном порту!";

/* для процедур send_file и receive_file */
/* ------------------------------------- */
unsigned handle, numread, endread, cycle, attrib;
long iter;
union {
    char c[2];
    unsigned count;
} CRCR,CRCS,dt,tm;
union {
    char c[4];
    unsigned long count;
} cnt;

int main( int argc, char *argv[] )
{
    unsigned speed;

    init_PC();
    if( argc<3 )
        write_cr();
    switch (*argv[1]) {
        case 'C':   speed = 0x0C;
                    break;
        case '6':   speed = 0x06;
                    break;
        case '3':   speed = 0x03;
                    break;
        case '2':   speed = 0x02;
                    break;
        case '1':   speed = 0x01;
                    break;
        case '0':   speed = 0x00;
                    break;
    }
    switch (PC) {
        case AT386: port = 0;
                    init_8250(port, speed);
                    send = send_8250;
                    receive = receive_8250;
                    err = 0x1E00;
                    err1 = 0x1F00;
                    err2 = 0x1E00;
                    break;
        case AT286S:port = 0;
                    init_8250(port, speed);
                    send = send_8250;
                    receive = receive_8250;
                    err = 0x1E00;
                    err1 = 0x1F00;
                    err2 = 0x1E00;
                    break;
        case AT286: port = 0;
                    init_8250(port, speed);
                    send = send_8250;
                    receive = receive_8250;
                    err = 0x1E00;
                    err1 = 0x1F00;
                    err2 = 0x1E00;
                    break;
        case Iskra: port = 1;
                    init_8251(port, 0x08);
                    send = send_8251;
                    receive = receive_8251;
                    err = 0x3800;
                    err1 = 0x3A00;
                    err2 = 0x3800;
                    break;
        case None:  write_cr();
                    exit(1);
                    break;
    }
    switch (argc) {
        case 3:   if( *argv[2] == '/' )
                      if( tolower(*(argv[2]+1)) == 'r') {
                          clear_screen();
                          rec_file();
                      }
                      else
                          write_cr();
                  break;
        case 4:   if( *argv[2] == '/' )
                      if( tolower(*(argv[2]+1)) == 's') {
                          clear_screen();
                          send_file(argv[3]);
                      }
                      else
                          write_cr();
                  break;
    }
    return 0;
}

write_cr()
{
    char copyright[] = "                                               "\
                       "                                               "\
                       "                                               "\
                       "                                               "\
                       "                                               "\
                       "                                               "\
                       "                                               "\
                       "                                               "\
                       "                                               "\
                       "+---------------------------------------------+"\
                       "|          Network files transmission         |"\
                       "+---------------------------------------------+"\
                       "|     Copyright (C) 1992 by Igor Dolzhikov    |"\
                       "+---------------------------------------------+"\
                       "| Usage:                                      }"\
                       "|   trans speed /S <file name> - send file    |"\
                       "|   trans speed /R             - receive file |"\
                       "+---------------------------------------------+";

    win(16,7,snow,1,0x1E,47,9,copyright);
    while(!key_read());
    win(16,7,snow,0,0,47,9,copyright);
    exit( 1 );
}


void init_PC()
{
    char *date_BIOS_Iskra  = "05/22/88";
    char *date_BIOS_AT286  = "06/13/90";
    char *date_BIOS_AT286S = "04/30/89";
    char *date_BIOS_AT386  = "03/03/89";

    if(comp_str_mem(date_BIOS_AT286S,0xF000,0xFFF5)) {
        PC = AT286S;
        snow = 0;
    }
    else {
        if(comp_str_mem(date_BIOS_AT286,0xF000,0xFFF5)) {
            PC = AT286;
            snow = 0;
        }
        else {
            if(comp_str_mem(date_BIOS_Iskra,0xF000,0xFFF5)) {
                PC = Iskra;
                snow = 1;
            }
            else {
                if(comp_str_mem(date_BIOS_AT386,0xF000,0xFFF5)) {
                    PC = AT386;
                    snow = 0;
                }
                else {
                    PC = None;
                    snow = 0;
                }
            }
        }
    }
}

void win_error(char *error)
{
    int len, lw, il;
    static int count;
    char env[] = "                                                         "\
                 "                                                         "\
                 "                                                         "\
                 "                                                         "\
                 "                                                         "\
                 "                                                         ";

    len = -1;
    while(error[++len] != 0);
    count=3*(len+4);
    env[count++] = '+';
    lw = count+len+2;
    while(count<lw)
        env[count++] = '-';
    env[count++] = '+';
    env[count++] = '|';
    env[count++] = ' ';
    lw = count+len;
    il = 0;
    while(count<lw)
        env[count++] = error[il++];
    env[count++] = ' ';
    env[count++] = '|';
    env[count++] = '+';
    lw = count+len+2;
    while(count<lw)
        env[count++] = '-';
    env[count++] = '+';
    lw = (80-len-4)/2;
    win(lw,11,snow,1,0x4E,len+4,3,env);
    while(!key_read());
    win(lw,11,snow,0,0,len+4,3,env);
}

void write_str(char *str, int atr, int x, int y)
{
    int len = 0;

    while(str[len++] != 0);
    win(x,y,snow,0,atr,len-1,1,str);
}

void write_dec( unsigned long digit, unsigned pos, int atr, int x, int y )
{
    unsigned len, count;
    unsigned long decl;
    char *dec = "0000000000\0";

    decl = digit;
    bin_to_dec(&decl, dec);
    count = 0;
    while((*dec == '0') && (count != 9)) {
        count++;
        dec++;
    }
    count = 0;
    len   = 0;
    while(dec[count++] != 0)
        len++;
    if(pos < len)
        pos = len;
    x +=(pos - len);
    win(x,y,snow,0,atr,len,1,dec);
}

void send_file( char *fname )
{

    handle = open_file(fname,0);
    if(handle==(-1)) {
        win_error(error2);
        exit( 1 );
    }
    cnt.count = filesize(handle);
    if(file_time(handle, 0, &dt, &tm )) {
        win_error(error3);
        exit(1);
    }
    attrib = file_attrib( fname, 0, attrib);
    if(attrib ==(-1)) {
        win_error(error4);
        exit(1);
    }
    send_file_name( fname );
    wait(port,'.');
    sport( port, cnt.c[0] );
    wait(port,cnt.c[0]);
    sport( port, cnt.c[1] );
    wait(port,cnt.c[1]);
    sport( port, cnt.c[2] );
    wait(port,cnt.c[2]);
    sport( port, cnt.c[3] );
    wait(port,cnt.c[3]);
    sport( port, dt.c[0] );
    wait(port,dt.c[0]);
    sport( port, dt.c[1] );
    wait(port,dt.c[1]);
    sport( port, tm.c[0] );
    wait(port,tm.c[0]);
    sport( port, tm.c[1] );
    wait(port,tm.c[1]);
    sport( port, (char)attrib );
    wait(port, (char)attrib );
    write_str("Длина файла :",0x07,0,2);
    write_dec(cnt.count,0,0x07,14,2);
    write_str("байт",0x07,25,2);
    iter = 0;
    do {
        CRCS.count = 0;
        if( (cnt.count - (buff*iter)) <= buff )
            endread = (int)(cnt.count - (buff*iter));
        else
            endread = buff;
        numread = read_file(handle,buffer,endread);
        if(numread==(-1)) {
            win_error(error5);
            break;
        }
        if( numread != endread ) {
            win_error(error6);
            break;
        }
        wait(port,'.');
        for(cycle=0; cycle<endread; cycle++) {
            CRCS.count+=buffer[cycle];
            sport( port, buffer[cycle] );
        }
        CRCR.c[0] = rport(port);
        CRCR.c[1] = rport(port);
        if( CRCR.count != CRCS.count ) {
            sport(port,'?');
            win_error(error7);
            exit(1);
        }
        else
            sport(port,'.');
        iter++;
    } while(endread==buff);
    wait(port,'.');
    if(close_file(handle)==(-1)) {
        win_error(error8);
        exit(1);
    }
}

void rec_file()
{
    char fname[40];

    get_file_name( fname );
    write_str("Получен файл ",0x07,0,1);
    write_str(fname,0x07,14,1);
    handle = creat_file(fname);
    if(handle==(-1)) {
        win_error(error9);
        exit( 1 );
    }
    sport( port, '.' );
    cnt.c[0] = rport(port);
    sport( port, cnt.c[0] );
    cnt.c[1] = rport(port);
    sport( port, cnt.c[1] );
    cnt.c[2] = rport(port);
    sport( port, cnt.c[2] );
    cnt.c[3] = rport(port);
    sport( port, cnt.c[3] );
    dt.c[0]  = rport(port);
    sport( port, dt.c[0] );
    dt.c[1]  = rport(port);
    sport( port, dt.c[1] );
    tm.c[0]  = rport(port);
    sport( port, tm.c[0] );
    tm.c[1]  = rport(port);
    sport( port, tm.c[1] );
    attrib   = rport(port);
    sport( port, (char)attrib );
    write_str("Длина файла :",0x07,0,2);
    write_dec(cnt.count,0,0x07,14,2);
    write_str("байт",0x07,25,2);
    iter = 0;
    do {
        CRCR.count = 0;
        if( (cnt.count - (buff*iter)) <= buff )
            endread = (int)(cnt.count - (buff*iter));
        else
            endread = buff;
        sport(port,'.');
        for(cycle=0; cycle<endread; cycle++) {
            buffer[cycle] = (char)rport(port);
            CRCR.count+=buffer[cycle];
        }
        sport(port,CRCR.c[0]);
        sport(port,CRCR.c[1]);
        wait(port,'.');
        numread = write_file(handle,buffer,endread);
        if(numread==(-1)) {
            win_error(error10);
            break;
        }
        if( numread != endread ) {
            win_error(error11);
            break;
        }
        iter++;
    } while(endread==buff);
    sport(port,'.');
    if(file_time(handle, 1, &dt, &tm )) {
        win_error(error12);
        exit(1);
    }
    if(close_file(handle)==(-1)) {
        win_error(error13);
        exit(1);
    }
    attrib = file_attrib( fname, 1, attrib);
    if(attrib == -1) {
        win_error(error14);
        exit(1);
    }
}

void send_file_name( char *f )
{
	char ch;

    write_str("Ожидание передачи... ",0x07,0,0);
    receive(port);
    sport(port,'?');
    do {
        ch = rport(port);
    } while((ch!='?')&&(ch!='.'));
    if(ch=='?')
        sport(port,'.');
    write_str("Передано ",0x07,0,1);
    write_str(f,0x07,10,1);
    while( *f ) {
        sport( port, *f );
        wait(port,*f++);
    }
    sport( port, '\0' );
    wait(port, '\0');
}

void get_file_name( char *f )
{
	char ch;

    write_str("Ожидание получения...",0x07,0,0);
    receive(port);
	sport(port,'?');
	do {
		ch = rport(port);
	} while((ch!='?')&&(ch!='.'));
	if(ch=='?')
		sport(port,'.');
	do {	
        *f = rport(port);
        sport( port, *f );
    } while( *f++ );
}

long filesize(int handle)
{
	long pos,size;

	pos = seek_file(handle,0L,1);
	if(pos==(-1))
		return (pos);
	size = seek_file(handle,0L,2);
	seek_file(handle,pos,0);
	return (size);
}

void wait(unsigned com_port, char ch)
{
    if( rport(com_port) != ch ) {
        win_error(error15);
        exit( 1 );
    }
}

void sport(unsigned com_port, unsigned code)
{
    unsigned status, key = 0x011B;

    status = send(com_port, code);
    while( (key != key_read()) && status ) {
        if( status & err ) {
            win_error(error16);
            exit(1);
        }
        status = send(com_port, code);
    }
    if( status ) {
        exit(1);
    }
}

unsigned rport(unsigned com_port)
{
    unsigned data, key = 0x011B;

    data = receive(com_port);
    while( (key != key_read()) && (data & err1) ) {
        if( data & err2 ) {
            win_error(error17);
            exit(1);
        }
        data = receive(com_port);
    }
    if( (data & err1) ) {
        exit(1);
    }
    return data;
}
