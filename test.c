#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main()
{
    int i = 255;
    unsigned char *p = (unsigned char *)(&i);
    printf("%d\n", *p);
    printf("%d\n", *(p++));
    printf("%d\n", i);
}
