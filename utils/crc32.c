/***************************************************************************** 
 This program calculates CRC 32 bits for any small file
 Copyright (C) 1993 by Igor Dolzhikov 
 *****************************************************************************/

#include <limits.h>
#include <alloc.h>
#include <fcntl.h>
#include <stat.h>

#define  uint        unsigned int
#define  ulong       unsigned long
#define  uchar       unsigned char
#define  CRCPOLY     0xEDB88320UL
#define  CRCMASK     0xFFFFFFFFUL

#if CHAR_BIT == 8
#define  UPDATE_CRC(crc, c)  \
	 crc = crctable[(uchar)crc ^ (uchar)(c)] ^ (crc >> CHAR_BIT)
#else
#define  UPDATE_CRC(crc, c)  \
	 crc = crctable[((uchar)(crc) ^ (uchar)(c)) & 0xFF] ^ (crc >> CHAR_BIT)
#endif

void make_crc_table();

char *buffer;
ulong crc = CRCMASK;
ulong crctable[UCHAR_MAX + 1];

int main(int argc, char *argv[])
{
    int handle;
    uint len, bytes = 32768;

    printf("\nCRC32 1.01 Copyright (C) 1993 by Igor Dolzhikov\n");
    if (argc < 2) {
        printf("Print CRC information for a file\n\n");
        printf("  Usage:      crc32  <file_name> \n");
        printf("  Examples:   crc32  crc32.exe\n\n");
        exit(1);
    }
    buffer = malloc(32768);
    make_crc_table();
    printf("\n  File name:  %s\n",argv[1]);
    if ((handle =
    open(argv[1], O_RDONLY | O_BINARY, S_IWRITE | S_IREAD)) == -1) {
        printf("\n  Sorry, error opening file\n");
        exit(1);
    }
    while (bytes == 32768) {
        if ((bytes = read(handle, buffer, bytes)) == -1) {
            printf("\n  Sorry, read failed.\n");
            exit(1);
        }
        len = bytes;
        while (len--)
        UPDATE_CRC(crc, *buffer++);
    }
    printf("  CRC 32 hex: %lX\n",crc^CRCMASK);
    return 0;
}

void make_crc_table()
{
    uint i, j;
    ulong r;

    for (i = 0; i <= UCHAR_MAX; i++) {
        r = i;
        for (j = 0; j < CHAR_BIT; j++) {
            if (r & 1)
                r = (r >> 1) ^ (CRCPOLY);
            else
                r >>= 1;
        }
        crctable[i] = r;
    }
}

