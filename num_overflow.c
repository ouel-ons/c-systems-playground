#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main()
{
    int i = 256;
    unsigned char *p = (unsigned char *)&i;
    printf("integer ----> (%d)\n|_______\n", i);
    printf("        |%p |---> %d \n", p, *p);
    // p++;
    printf("4 bytes |%p |---> %d \n", p++, *(++p));
    printf("        |%p |---> %d\n", p, *p);
    p++;
    printf("        |%p |---> %d\n", p, *p);
}



/////// ----> attention to diff mem addresses when we increment p inside printf
