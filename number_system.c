#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <limits.h>


int main()
{
    unsigned char i = 255;
    printf("%d\n", i);
    char c = 0b11111111;
    printf("%d\n", c);           //-5
    printf("%d\n", 0b11111111);  //251

    printf("--------------------\n");
    unsigned char u = 256;
    signed char j = -1;
    char k = -128;
    char p = 127;
    char f = -256;
    printf("%d\n", u);
    printf("%d\n", j);
    printf("%d\n", k);
    printf("%d\n", p);
    printf("%d\n", f);

}
