#include <pico/stdio.h>
#include <pico/stdlib.h>
#include <pico.h>
#include <hardware/regs/qmi.h>
#include <stdio.h>

uint32_t read_byte(uint32_t offset)
{
    uint32_t * volatile reg = (uint32_t * volatile)( XIP_QMI_BASE + offset);

    return *reg;
}

void print_reg(char const * prefix, uint32_t offset, uint32_t mask, uint32_t lsb)
{
    uint32_t value = read_byte(offset);

    if(mask != 0) {
        uint32_t field = (value & mask) >> lsb;
        printf("%s = %u\n", prefix, field);
    }
    else {
        printf("%s = 0x%08X = 0b%032b\n", prefix, value, value);
    }
}

int main() {
    stdio_init_all();
    printf("Hello, world!\n");
    
    while(stdio_getchar() != '!') {
        // 
    }

#include "printers.h"

    while(true)
    {
        sleep_ms(100);
        printf(".");
    }

    return 0;
}
