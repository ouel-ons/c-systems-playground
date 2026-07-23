#include <stdio.h>

int main()
{
    unsigned char p = 0b11111111;
    signed char j = 0b11111111;
    printf("%d\n", p);
    printf("%d\n", j);
    printf("%d\n", j == p);
    printf("%d\n", j < p);     // integer promotion


    unsigned int i = 1;
    int k = -1;
    printf("%d  ---- %d     ==== %d\n", i, k, i > k); //0 whyyyy?
}
