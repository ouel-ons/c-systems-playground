#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>


int f(int x)
{
    int p = x + 1;
    printf("%d\n", p);
    printf("%d\n", x);

    printf("%d\n", p > x);
    printf("%d\n", x + 1 > x);
    return x;
}

int main()
{
    printf("%d\n", f(2147483647));
}


// ╰─❯ gcc -O0 signed_overflow.c && ./a.out
// -2147483648
// 2147483647
// 0
// 1
// 2147483647

// ╭─ ouel-ons@ouel-ons in ~/c-systems-playground [main]
// ╰─❯ gcc -O2 signed_overflow.c && ./a.out
// -2147483648
// 2147483647
// 1
// 1
// 2147483647
