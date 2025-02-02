#include <pico/stdio.h>
#include <pico/stdlib.h>
#include <pico.h>
#include <hardware/clocks.h>
#include <hardware/regs/qmi.h>

#include <hardware/address_mapped.h>
#include <hardware/clocks.h>
#include <hardware/gpio.h>
#include <hardware/regs/addressmap.h>
// #include <hardware/spi.h>
#include <hardware/structs/qmi.h>
#include <hardware/structs/xip_ctrl.h>
#include <pico/runtime_init.h>
#include <hardware/sync.h>

#include <pico/time.h>

#include <stdio.h>

#define RP2350_PSRAM_CS 8 


#define PICO_RUNTIME_INIT_PSRAM "11001" // Towards the end, after alarms

#ifndef RP2350_PSRAM_MAX_SELECT_FS64
#define RP2350_PSRAM_MAX_SELECT_FS64 (125000000ULL)
#endif

#ifndef RP2350_PSRAM_MIN_DESELECT_FS
#define RP2350_PSRAM_MIN_DESELECT_FS (50000000ULL)
#endif

#ifndef RP2350_PSRAM_MAX_SCK_HZ
#define RP2350_PSRAM_MAX_SCK_HZ (109000000ULL)
#endif

#ifndef RP2350_PSRAM_ID
#define RP2350_PSRAM_ID (0x5D)
#endif


// DETAILS/
//
// SparkFun RP2350 boards use the following PSRAM IC:
//
//      apmemory APS6404L-3SQR-ZR
//      https://www.mouser.com/ProductDetail/AP-Memory/APS6404L-3SQR-ZR?qs=IS%252B4QmGtzzpDOdsCIglviw%3D%3D
//
// The origin of this logic is from the Circuit Python code that was downloaded from:
//     https://github.com/raspberrypi/pico-sdk-rp2350/issues/12#issuecomment-2055274428
//

// Details on the PSRAM IC that are used during setup/configuration of PSRAM on SparkFun RP2350 boards.

// For PSRAM timing calculations - to use int math, we work in femto seconds (fs) (1e-15),
// NOTE: This idea is from micro python work on psram..

#define SFE_SEC_TO_FS 1000000000000000ll

// max select pulse width = 8us => 8e6 ns => 8000 ns => 8000 * 1e6 fs => 8000e6 fs
// Additionally, the MAX select is in units of 64 clock cycles - will use a constant that
// takes this into account - so 8000e6 fs / 64 = 125e6 fs

const uint32_t SFE_PSRAM_MAX_SELECT_FS64 = RP2350_PSRAM_MAX_SELECT_FS64;

// min deselect pulse width = 50ns => 50 * 1e6 fs => 50e7 fs
const uint32_t SFE_PSRAM_MIN_DESELECT_FS = RP2350_PSRAM_MIN_DESELECT_FS;

// from psram datasheet - max Freq with VDDat 3.3v - SparkFun RP2350 boards run at 3.3v.
// If VDD = 3.0 Max Freq is 133 Mhz
const uint32_t SFE_PSRAM_MAX_SCK_HZ = RP2350_PSRAM_MAX_SCK_HZ;

// PSRAM SPI command codes
const uint8_t PSRAM_CMD_QUAD_END = 0xF5;
const uint8_t PSRAM_CMD_QUAD_ENABLE = 0x35;
const uint8_t PSRAM_CMD_READ_ID = 0x9F;
const uint8_t PSRAM_CMD_RSTEN = 0x66;
const uint8_t PSRAM_CMD_RST = 0x99;
const uint8_t PSRAM_CMD_QUAD_READ = 0xEB;
const uint8_t PSRAM_CMD_QUAD_WRITE = 0x38;
const uint8_t PSRAM_CMD_NOOP = 0xFF;

const uint8_t PSRAM_ID = RP2350_PSRAM_ID;


uint32_t read_byte(uint32_t offset)
{
    uint32_t * volatile reg = (uint32_t * volatile)( XIP_QMI_BASE + offset);

    return *reg;
}

void write_reg(uint32_t offset, uint32_t value )
{
    uint32_t * volatile reg = (uint32_t * volatile)( XIP_QMI_BASE + offset);
    *reg = value;
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

static uint8_t * const psram_mem = (uint8_t*)0x11000000UL; 

//-----------------------------------------------------------------------------
/// @brief Communicate directly with the PSRAM IC - validate it is present and return the size
///
/// @return size_t The size of the PSRAM
///
/// @note This function expects the CS pin set
static size_t __no_inline_not_in_flash_func(get_psram_size)(void) {
    size_t psram_size = 0;
    uint32_t intr_stash = save_and_disable_interrupts();

    // Try and read the PSRAM ID via direct_csr.
    qmi_hw->direct_csr = 30 << QMI_DIRECT_CSR_CLKDIV_LSB | QMI_DIRECT_CSR_EN_BITS;

    // Need to poll for the cooldown on the last XIP transfer to expire
    // (via direct-mode BUSY flag) before it is safe to perform the first
    // direct-mode operation
    while ((qmi_hw->direct_csr & QMI_DIRECT_CSR_BUSY_BITS) != 0) {
    }

    // Exit out of QMI in case we've inited already
    qmi_hw->direct_csr |= QMI_DIRECT_CSR_ASSERT_CS1N_BITS;

    // Transmit the command to exit QPI quad mode - read ID as standard SPI
    qmi_hw->direct_tx =
        QMI_DIRECT_TX_OE_BITS | QMI_DIRECT_TX_IWIDTH_VALUE_Q << QMI_DIRECT_TX_IWIDTH_LSB | PSRAM_CMD_QUAD_END;

    while ((qmi_hw->direct_csr & QMI_DIRECT_CSR_BUSY_BITS) != 0) {
    }

    (void)qmi_hw->direct_rx;
    qmi_hw->direct_csr &= ~(QMI_DIRECT_CSR_ASSERT_CS1N_BITS);

    // Read the id
    qmi_hw->direct_csr |= QMI_DIRECT_CSR_ASSERT_CS1N_BITS;
    uint8_t kgd = 0;
    uint8_t eid = 0;
    for (size_t i = 0; i < 7; i++) {
        qmi_hw->direct_tx = (i == 0 ? PSRAM_CMD_READ_ID : PSRAM_CMD_NOOP);

        while ((qmi_hw->direct_csr & QMI_DIRECT_CSR_TXEMPTY_BITS) == 0) {
        }
        while ((qmi_hw->direct_csr & QMI_DIRECT_CSR_BUSY_BITS) != 0) {
        }
        if (i == 5) {
            kgd = qmi_hw->direct_rx;
        } else if (i == 6) {
            eid = qmi_hw->direct_rx;
        } else {
            (void)qmi_hw->direct_rx;    // just read and discard
        }
    }

    // Disable direct csr.
    qmi_hw->direct_csr &= ~(QMI_DIRECT_CSR_ASSERT_CS1N_BITS | QMI_DIRECT_CSR_EN_BITS);

    // is this the PSRAM we're looking for obi-wan?
    if (kgd == PSRAM_ID) {
        // PSRAM size
        psram_size = 1024 * 1024; // 1 MiB
        uint8_t size_id = eid >> 5;
        if (eid == 0x26 || size_id == 2) {
            psram_size *= 8;
        } else if (size_id == 0) {
            psram_size *= 2;
        } else if (size_id == 1) {
            psram_size *= 4;
        }
    }
    restore_interrupts(intr_stash);
    return psram_size;
}
//-----------------------------------------------------------------------------
/// @brief Update the PSRAM timing configuration based on system clock
///
/// @note This function expects interrupts to be enabled on entry

static uint32_t __no_inline_not_in_flash_func(set_psram_timing)(void) {
    // Get secs / cycle for the system clock - get before disabling interrupts.
    uint32_t sysHz = (uint32_t)clock_get_hz(clk_sys);

    // Calculate the clock divider - goal to get clock used for PSRAM <= what
    // the PSRAM IC can handle - which is defined in SFE_PSRAM_MAX_SCK_HZ
    volatile uint8_t clockDivider = (sysHz + SFE_PSRAM_MAX_SCK_HZ - 1) / SFE_PSRAM_MAX_SCK_HZ;

    uint32_t intr_stash = save_and_disable_interrupts();

    // Get the clock femto seconds per cycle.

    uint32_t fsPerCycle = SFE_SEC_TO_FS / sysHz;

    // the maxSelect value is defined in units of 64 clock cycles
    // So maxFS / (64 * fsPerCycle) = maxSelect = SFE_PSRAM_MAX_SELECT_FS64/fsPerCycle
    volatile uint8_t maxSelect = SFE_PSRAM_MAX_SELECT_FS64 / fsPerCycle;

    //  minDeselect time - in system clock cycle
    // Must be higher than 50ns (min deselect time for PSRAM) so add a fsPerCycle - 1 to round up
    // So minFS/fsPerCycle = minDeselect = SFE_PSRAM_MIN_DESELECT_FS/fsPerCycle

    volatile uint8_t minDeselect = (SFE_PSRAM_MIN_DESELECT_FS + fsPerCycle - 1) / fsPerCycle;

    // printf("Max Select: %d, Min Deselect: %d, clock divider: %d\n", maxSelect, minDeselect, clockDivider);

    qmi_hw->m[1].timing = QMI_M1_TIMING_PAGEBREAK_VALUE_1024 << QMI_M1_TIMING_PAGEBREAK_LSB | // Break between pages.
                          3 << QMI_M1_TIMING_SELECT_HOLD_LSB | // Delay releasing CS for 3 extra system cycles.
                          1 << QMI_M1_TIMING_COOLDOWN_LSB | 1 << QMI_M1_TIMING_RXDELAY_LSB |
                          maxSelect << QMI_M1_TIMING_MAX_SELECT_LSB | minDeselect << QMI_M1_TIMING_MIN_DESELECT_LSB |
                          clockDivider << QMI_M1_TIMING_CLKDIV_LSB;

    restore_interrupts(intr_stash);
}


//-----------------------------------------------------------------------------
/// @brief The setup_psram function - note that this is not in flash
///
///
static uint32_t __no_inline_not_in_flash_func(runtime_init_setup_psram)(/*uint32_t psram_cs_pin*/) {
    // Set the PSRAM CS pin in the SDK
    gpio_set_function(RP2350_PSRAM_CS, GPIO_FUNC_XIP_CS1);

    // start with zero size
    size_t psram_size = get_psram_size();

    // No PSRAM - no dice
    if (psram_size == 0) {
        printf("no sram attached\n");
        return 0;
    }

    printf("sram size is %lu\n", psram_size);

    uint32_t intr_stash = save_and_disable_interrupts();
    // Enable quad mode.
    qmi_hw->direct_csr = 30 << QMI_DIRECT_CSR_CLKDIV_LSB | QMI_DIRECT_CSR_EN_BITS;

    // Need to poll for the cooldown on the last XIP transfer to expire
    // (via direct-mode BUSY flag) before it is safe to perform the first
    // direct-mode operation
    while ((qmi_hw->direct_csr & QMI_DIRECT_CSR_BUSY_BITS) != 0) {
    }

    // RESETEN, RESET and quad enable
    for (uint8_t i = 0; i < 3; i++) {
        qmi_hw->direct_csr |= QMI_DIRECT_CSR_ASSERT_CS1N_BITS;
        if (i == 0) {
            qmi_hw->direct_tx = PSRAM_CMD_RSTEN;
        } else if (i == 1) {
            qmi_hw->direct_tx = PSRAM_CMD_RST;
        } else {
            qmi_hw->direct_tx = PSRAM_CMD_QUAD_ENABLE;
        }

        while ((qmi_hw->direct_csr & QMI_DIRECT_CSR_BUSY_BITS) != 0) {
        }
        qmi_hw->direct_csr &= ~(QMI_DIRECT_CSR_ASSERT_CS1N_BITS);
        for (size_t j = 0; j < 20; j++) {
            asm("nop");
        }

        (void)qmi_hw->direct_rx;
    }

    // Disable direct csr.
    qmi_hw->direct_csr &= ~(QMI_DIRECT_CSR_ASSERT_CS1N_BITS | QMI_DIRECT_CSR_EN_BITS);

    // check our interrupts and setup the timing
    restore_interrupts(intr_stash);
    set_psram_timing();

    // and now stash interrupts again
    intr_stash = save_and_disable_interrupts();

    qmi_hw->m[1].rfmt = (QMI_M1_RFMT_PREFIX_WIDTH_VALUE_Q << QMI_M1_RFMT_PREFIX_WIDTH_LSB |
                         QMI_M1_RFMT_ADDR_WIDTH_VALUE_Q << QMI_M1_RFMT_ADDR_WIDTH_LSB |
                         QMI_M1_RFMT_SUFFIX_WIDTH_VALUE_Q << QMI_M1_RFMT_SUFFIX_WIDTH_LSB |
                         QMI_M1_RFMT_DUMMY_WIDTH_VALUE_Q << QMI_M1_RFMT_DUMMY_WIDTH_LSB |
                         QMI_M1_RFMT_DUMMY_LEN_VALUE_24 << QMI_M1_RFMT_DUMMY_LEN_LSB |
                         QMI_M1_RFMT_DATA_WIDTH_VALUE_Q << QMI_M1_RFMT_DATA_WIDTH_LSB |
                         QMI_M1_RFMT_PREFIX_LEN_VALUE_8 << QMI_M1_RFMT_PREFIX_LEN_LSB |
                         QMI_M1_RFMT_SUFFIX_LEN_VALUE_NONE << QMI_M1_RFMT_SUFFIX_LEN_LSB);

    qmi_hw->m[1].rcmd = PSRAM_CMD_QUAD_READ << QMI_M1_RCMD_PREFIX_LSB | 0 << QMI_M1_RCMD_SUFFIX_LSB;

    qmi_hw->m[1].wfmt = (QMI_M1_WFMT_PREFIX_WIDTH_VALUE_Q << QMI_M1_WFMT_PREFIX_WIDTH_LSB |
                         QMI_M1_WFMT_ADDR_WIDTH_VALUE_Q << QMI_M1_WFMT_ADDR_WIDTH_LSB |
                         QMI_M1_WFMT_SUFFIX_WIDTH_VALUE_Q << QMI_M1_WFMT_SUFFIX_WIDTH_LSB |
                         QMI_M1_WFMT_DUMMY_WIDTH_VALUE_Q << QMI_M1_WFMT_DUMMY_WIDTH_LSB |
                         QMI_M1_WFMT_DUMMY_LEN_VALUE_NONE << QMI_M1_WFMT_DUMMY_LEN_LSB |
                         QMI_M1_WFMT_DATA_WIDTH_VALUE_Q << QMI_M1_WFMT_DATA_WIDTH_LSB |
                         QMI_M1_WFMT_PREFIX_LEN_VALUE_8 << QMI_M1_WFMT_PREFIX_LEN_LSB |
                         QMI_M1_WFMT_SUFFIX_LEN_VALUE_NONE << QMI_M1_WFMT_SUFFIX_LEN_LSB);

    qmi_hw->m[1].wcmd = PSRAM_CMD_QUAD_WRITE << QMI_M1_WCMD_PREFIX_LSB | 0 << QMI_M1_WCMD_SUFFIX_LSB;

    // Mark that we can write to PSRAM.
    xip_ctrl_hw->ctrl |= XIP_CTRL_WRITABLE_M1_BITS;

    restore_interrupts(intr_stash);

    return psram_size;
}
// PICO_RUNTIME_INIT_FUNC_RUNTIME(runtime_init_setup_psram, PICO_RUNTIME_INIT_PSRAM);

// update timing -- used if the system clock/timing was changed.
void psram_reinit_timing() {
    set_psram_timing();
}

uint32_t const xip_mem0_base = XIP_BASE + 0x0000000UL;
uint32_t const xip_mem1_base = XIP_BASE + 0x1000000UL;

#pragma GCC push_options
#pragma GCC optimize ("O3")

static inline uint32_t read_mem(uint32_t addr)
{
    uint32_t * volatile reg = (uint32_t * volatile)( addr);

    return *reg;
}

static inline void write_mem(uint32_t addr, uint32_t value )
{
    uint32_t * volatile reg = (uint32_t * volatile)( addr);
    *reg = value;
}

void exec_ramtest(size_t const psram_size)
{
    if(psram_size == 0) {
        printf("ramtest failed: not initialized!\n");
        return;
    }
    printf("start ramtest...\n");

    for(size_t i = 0; i < psram_size; i += 4)
    {
        uint32_t const value = ~i;
        if((i % 0x4000) == 0) {
            printf("writing 0x%06X...\n", i);
        }
        write_mem(xip_mem1_base + i, value);
    }

    for(size_t i = 0; i < psram_size; i += 4)
    {
        uint32_t const expected_value = ~i;
        if((i % 0x4000) == 0) {
            printf("reading 0x%06X...\n", i);
        }
        uint32_t const actual_value = read_mem(xip_mem1_base + i);
        if(expected_value != actual_value) {
            printf("mismatch at 0x%06X: expected 0x%08X, but found 0x%08X!\n", i, expected_value, actual_value);
        }
    }

    printf("stop ramtest...\n");
}


void exec_ramspeed(size_t const psram_size)
{
    if(psram_size == 0) {
        printf("ramspeed failed: not initialized!\n");
        return;
    }
    printf("start ramspeed...\n");

    printf("manually writing full ram...\n");
    {

        absolute_time_t const start = get_absolute_time();
        for(size_t i = 0; i < psram_size; i += 4)
        {
            write_mem(xip_mem1_base + i, i);
        }
        absolute_time_t const end = get_absolute_time();

        int64_t const delta_us = absolute_time_diff_us (start, end);

        uint64_t const memrate_mbps = (8u * psram_size) / (uint64_t)delta_us; // Bit / us == Mb / s

        printf("full ram write in %lld us, yielding a rate of %llu Mbps (%llu MB/s)\n", delta_us, memrate_mbps,  memrate_mbps/8LLU);
    }
    
    printf("manually reading full ram...\n");
    {
        absolute_time_t const start = get_absolute_time();
        for(size_t i = 0; i < psram_size; i += 4)
        {
            hard_assert(read_mem(xip_mem1_base + i) == i);
        }
        absolute_time_t const end = get_absolute_time();

        int64_t const delta_us = absolute_time_diff_us (start, end);

        uint64_t const memrate_mbps = (8u * psram_size) / (uint64_t)delta_us; // Bit / us == Mb / s

        printf("full ram read in %lld us, yielding a rate of %llu Mbps (%llu MB/s)\n", delta_us, memrate_mbps,  memrate_mbps/8LLU);
    }

    printf("stop ramtest...\n");

}
#pragma GCC pop_options

// void setup(void)
// {
//     write_reg( QMI_M1_TIMING_OFFSET, 0
//         | (2 << QMI_M1_TIMING_CLKDIV_LSB) // clk_sys / 2
//         | (0<<QMI_M1_TIMING_RXDELAY_LSB) // 
//         | (4<<QMI_M1_TIMING_MIN_DESELECT_LSB) // 18 ns
//         | (0<<QMI_M1_TIMING_MAX_SELECT_LSB) // 
//         | (1<<QMI_M1_TIMING_SELECT_HOLD_LSB) // 
//         | (1<<QMI_M1_TIMING_SELECT_SETUP_LSB) // 
//         | (QMI_M1_TIMING_PAGEBREAK_VALUE_NONE << QMI_M1_TIMING_PAGEBREAK_LSB) // 
//         | (1<<QMI_M1_TIMING_COOLDOWN_LSB) // 
//     );

//     // Use "Fast Read Quad" 0xEB, 6 wait clks
//     write_reg( QMI_M1_RFMT_OFFSET, 0
//     | (0<<QMI_M1_RFMT_DTR_LSB) // SDR
//     | (QMI_M1_RFMT_DUMMY_LEN_VALUE_24<<QMI_M1_RFMT_DUMMY_LEN_LSB) // 6 clocks
//     | (<<QMI_M1_RFMT_SUFFIX_LEN_LSB) // 
//     | (<<QMI_M1_RFMT_PREFIX_LEN_LSB) // 
//     | (<<QMI_M1_RFMT_DATA_WIDTH_LSB) // 
//     | (<<QMI_M1_RFMT_DUMMY_WIDTH_LSB) // 
//     | (<<QMI_M1_RFMT_SUFFIX_WIDTH_LSB) // 
//     | (<<QMI_M1_RFMT_ADDR_WIDTH_LSB) // 
//     | (<<QMI_M1_RFMT_PREFIX_WIDTH_LSB) // 
    
//     );
//     write_reg( QMI_M1_RCMD_OFFSET, 0);

//     // Use "Quad Write", 0x38, 0 wait clks
//     write_reg( QMI_M1_WFMT_OFFSET, 0);
//     write_reg( QMI_M1_WCMD_OFFSET, 0);
// }

int main() {
    stdio_init_all();
    printf("Hello, world!\n");
    
    size_t psram_size = 0;
    while(true)
    {
        int cmd = stdio_getchar();
        switch(cmd)
        {
            case 'i':
                #include "printers.h"
                break;

            case 's':
                printf("setup...\n");
                psram_size = runtime_init_setup_psram();
                break;

            case 'S':
                printf("reset timings...\n");
                set_psram_timing();
                break;

            case 't':
                exec_ramtest(psram_size);
                break;

            case 'T':
                exec_ramspeed(psram_size);
                break;

            case 'c':
                printf("clock rate = %u Hz\n", clock_get_hz(clk_sys));
                break;
        
            default:
                printf("unknown cmd: %d\n", cmd);
                break;
        }
    }

    return 0;
}
