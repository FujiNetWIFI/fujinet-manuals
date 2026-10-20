/**
 * @brief   Create character set based on charset.dat
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE
 */

#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

void write_header(FILE *dfp)
{
    fprintf(dfp,"/**\n");
    fprintf(dfp,"  * @brief   Character set\n");
    fprintf(dfp,"  * @verbose Arranged as 256 entries of 16 bytes\n");
    fprintf(dfp," */\n\n");
    fprintf(dfp,"unsigned char charset[256][16] = \n");
    fprintf(dfp,"{\n");
}

void write_body(FILE *sfp, FILE *dfp)
{
    for (int i=0;i<256;i++)
    {
        unsigned char c[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
        unsigned char l = fread(&c[0],sizeof(unsigned char),sizeof(c),sfp);

        if (l<sizeof(c))
        {
            fprintf(stderr,"Short read of %u bytes. Aborting.\n",l);
            return;
        }

        fprintf(dfp, "    // %02x\n",i);
        fprintf(dfp,
                "    { 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X },\n\n",
                c[0], c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12], c[13], c[14], c[15]);
    }
}

void write_footer(FILE *dfp)
{
    fprintf(dfp,"};\n");
}

int main(void)
{
    FILE *sfp = fopen("charset.dat","rb");
    FILE *dfp = fopen("../../src/msdos/charset.c","wb");

    if (!sfp)
    {
        perror("error opening charset.dat");
        goto bye;
    }

    if (!dfp)
    {
        perror("error opening charset.c");
        goto bye;
    }

    write_header(dfp);
    write_body(sfp,dfp);
    write_footer(dfp);

 bye:
    if (sfp)
        fclose(sfp);

    if (dfp)
        fclose(dfp);

    return errno;
}
