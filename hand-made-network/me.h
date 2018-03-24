/* me.h */

/* работа с последовательным адаптором */
/* ----------------------------------- */
void init_8250(unsigned _port, unsigned _speed);
unsigned send_8250(unsigned _port, unsigned _byte);
unsigned receive_8250(unsigned _port);
void init_8251(unsigned _port, unsigned _speed);
unsigned send_8251(unsigned _port, unsigned _byte);
unsigned receive_8251(unsigned _port);

/* работа с файлами */
/* ---------------- */
int creat_file( char *_path );
int open_file( char *_path, int _mode );
int close_file( int _handle );
int read_file(int _handle, void *_buffer, int _num);
int write_file(int _handle, void *_buffer, int _num);
long seek_file(int _handle, long _offset, int _where);
int file_time(int _handle, int _mode, unsigned *_date, unsigned *_time);
int file_attrib(char *_path, int _mode, int _attribute);

/* утилиты */
/* ------- */
void play_lpt1( unsigned _length, void *_buffer, unsigned _pause );
unsigned comp_str_mem( char *str, unsigned seg, unsigned ofs );
void clear_screen();
void write_string( char *str, unsigned atr, unsigned xy );
void bin_to_dec( unsigned long *bin, char *dec );
int key_read();
void win( int x,   int y,    int snow, int mode,
          int atr, int lenx, int leny, void *buffer);
int print(int _ch, int mode);

