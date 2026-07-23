#include <stdio.h>
#include <string.h>

// int main()
// {
//     char buffer[10];

//     int len = -1;
//     char *data = "dd";
//     if (len < sizeof(buffer))
//     {
//         memcpy(buffer, data, len);
//     }
// }

int main()
{
    size_t i = 10;
    while (i >= 0)
    {
        printf("%zu\n", i);
        sleep(1);
        i--;
    }
}
