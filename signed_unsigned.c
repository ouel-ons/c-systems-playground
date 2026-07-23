#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main()
{
    int i = 255;
    char *p = (char *)(&i);
    printf("%d\n", *p);
    p++;
    printf("%d\n", *(p));
    printf("int ---> %d\n", i);
    unsigned char *j = p;
    printf("%d\n", *(--j));
}
