#include <stdio.h>
#include "pico/stdlib.h"

int main() {
    stdio_init_all();
    printf("Hello, world!\n");

    while(true)
    {
        sleep_ms(100);
        printf(".");
    }

    return 0;
}
