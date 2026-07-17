#include <stdio.h>
#include <unistd.h>


int main()
{
    int i = 1;

    if (i)
    {
        write(1, "hello world!\n", 13);
        return 0;
    }
    else{
        write(1, "ooops!", 6);
        return 1;
    }
}
