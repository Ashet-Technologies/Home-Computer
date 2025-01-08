#include <assert.h>
#include <hardware/dma.h>
#include <hardware/gpio.h>
#include <hardware/irq.h>
#include <pico/multicore.h>
#include <pico/sem.h>
#include <pico/stdio.h>
#include <pico/stdio_usb.h>
#include <stdio.h>

// #include "propio.pio.h"

enum {
  PROPIO_BASE = 36,
  PROPIO_D0 = PROPIO_BASE + 0,
  PROPIO_D1 = PROPIO_BASE + 1,
  PROPIO_D2 = PROPIO_BASE + 2,
  PROPIO_D3 = PROPIO_BASE + 3,
  PROPIO_CLK = PROPIO_BASE + 4,
  PROPIO_EN = PROPIO_BASE + 5,
  PROPIO_DIR = PROPIO_BASE + 6,
  PROPIO_nREQ = PROPIO_BASE + 7,
};

// void propio_init(PIO pio)
// {
//     pio_sm_config c = propio_tx_program_get_default_config(PROPIO_BASE);

//     sm_config_set_out_pins(&c, PROPIO_D0, 4);
//     // sm_config_set_in_pins(&c, pin_miso);

//     sm_config_set_sideset_pins(&c, PROPIO_CLK);
//     sm_config_set_clkdiv(&c, 1000);

//     sm_config_set_out_shift(&c, false, true, n_bits);
//     sm_config_set_in_shift(&c, false, true, n_bits);

//     pio_sm_set_pins_with_mask(pio, sm, (2u << pin_sck), (3u << pin_sck) | (1u
//     << pin_mosi)); pio_sm_set_pindirs_with_mask(pio, sm, (3u << pin_sck) |
//     (1u << pin_mosi), (3u << pin_sck) | (1u << pin_mosi) | (1u << pin_miso));

//     pio_gpio_init(pio, PROPIO_D0);
//     pio_gpio_init(pio, PROPIO_D1);
//     pio_gpio_init(pio, PROPIO_D2);
//     pio_gpio_init(pio, PROPIO_D3);
//     pio_gpio_init(pio, PROPIO_CLK);

//     hw_set_bits(&pio->input_sync_bypass, 1u << pin_miso);
//     uint entry_point = prog_offs + (cpha ? spi_cpha1_cs_offset_entry_point :
//     spi_cpha0_cs_offset_entry_point); pio_sm_init(pio, sm, entry_point, &c);
//     pio_sm_exec(pio, sm, pio_encode_set(pio_x, n_bits - 2));
//     pio_sm_exec(pio, sm, pio_encode_set(pio_y, n_bits - 2));
//     pio_sm_set_enabled(pio, sm, true);

// }

struct Driver {
  uint32_t delay_us = 100;

  void init() {
    gpio_set_function(PROPIO_D0, GPIO_FUNC_SIO);
    gpio_set_function(PROPIO_D1, GPIO_FUNC_SIO);
    gpio_set_function(PROPIO_D2, GPIO_FUNC_SIO);
    gpio_set_function(PROPIO_D3, GPIO_FUNC_SIO);
    gpio_set_function(PROPIO_CLK, GPIO_FUNC_SIO);
    gpio_set_function(PROPIO_EN, GPIO_FUNC_SIO);
    gpio_set_function(PROPIO_DIR, GPIO_FUNC_SIO);
    gpio_set_function(PROPIO_nREQ, GPIO_FUNC_SIO);

    gpio_set_dir(PROPIO_D0, GPIO_IN);
    gpio_set_dir(PROPIO_D1, GPIO_IN);
    gpio_set_dir(PROPIO_D2, GPIO_IN);
    gpio_set_dir(PROPIO_D3, GPIO_IN);
    gpio_set_dir(PROPIO_CLK, GPIO_IN);
    gpio_set_dir(PROPIO_EN, GPIO_OUT);
    gpio_set_dir(PROPIO_DIR, GPIO_OUT);
    gpio_set_dir(PROPIO_nREQ, GPIO_IN);

    gpio_put(PROPIO_EN, 0);
  }

  void deinit()
  {
    gpio_set_dir(PROPIO_D0, GPIO_IN);
    gpio_set_dir(PROPIO_D1, GPIO_IN);
    gpio_set_dir(PROPIO_D2, GPIO_IN);
    gpio_set_dir(PROPIO_D3, GPIO_IN);
    gpio_set_dir(PROPIO_CLK, GPIO_IN);
    gpio_set_dir(PROPIO_EN, GPIO_IN);
    gpio_set_dir(PROPIO_nREQ, GPIO_IN);

    gpio_set_function(PROPIO_D0, GPIO_FUNC_NULL);
    gpio_set_function(PROPIO_D1, GPIO_FUNC_NULL);
    gpio_set_function(PROPIO_D2, GPIO_FUNC_NULL);
    gpio_set_function(PROPIO_D3, GPIO_FUNC_NULL);
    gpio_set_function(PROPIO_CLK, GPIO_FUNC_NULL);
    gpio_set_function(PROPIO_EN, GPIO_FUNC_NULL);
    gpio_set_function(PROPIO_nREQ, GPIO_FUNC_NULL);

  }

  void start_write_transaction() {
    this->set_dir(GPIO_OUT);
    gpio_put(PROPIO_CLK, 1);
    gpio_put(PROPIO_EN, 1);
  }

  void start_read_transaction() {
    this->set_dir(GPIO_IN);
    gpio_put(PROPIO_EN, 1);
  }

  void end_transaction() {
    gpio_put(PROPIO_EN, 0);
    this->set_dir(GPIO_IN);
  }

  void write_byte(uint8_t data) {
    uint8_t lo = ((data >> 0) & 0x0F);
    uint8_t hi = ((data >> 4) & 0x0F);

    this->write_nibble(hi);
    this->write_nibble(lo);
  }

private:
  void set_dir(int dir) {
    gpio_set_dir(PROPIO_D0, dir);
    gpio_set_dir(PROPIO_D1, dir);
    gpio_set_dir(PROPIO_D2, dir);
    gpio_set_dir(PROPIO_D3, dir);
    gpio_set_dir(PROPIO_CLK, dir);
    gpio_put(PROPIO_DIR, dir); // 1 == write, 0 == read
  }

  void write_nibble(uint8_t data) {
    gpio_put(PROPIO_D0, !!(data & 1));
    gpio_put(PROPIO_D1, !!(data & 2));
    gpio_put(PROPIO_D2, !!(data & 4));
    gpio_put(PROPIO_D3, !!(data & 8));

    gpio_put(PROPIO_CLK, 0);
    sleep_us(this->delay_us);
    gpio_put(PROPIO_CLK, 1);
    sleep_us(this->delay_us);
  }
};

int main(void) {

  stdio_init_all();

  Driver dri;

  while (true) {
    while (!stdio_usb_connected()) {
      __wfi();
    }

    printf("connected.\n");

    while (stdio_usb_connected()) {
      int cmd = stdio_getchar();
      switch (cmd) {
      case 0x00:
        break;

      case 'i':
        printf("initializing...\n");
        dri.init();
        printf("ok.\n");
        break;

      case 'I':
        printf("deinitializing...\n");
        dri.deinit();
        printf("ok.\n");
        break;

      case 's':
        printf("send.\n");
        dri.start_write_transaction();
        
        dri.write_byte('H');
        dri.write_byte('i');
        dri.write_byte('!');

        {
          char const *str = "Hello, World!";
          while (*str) {
            dri.write_byte(*str);
            str++;
          }
        }

        dri.end_transaction();
        printf("ok.\n");
        break;

      case '0' ... '9':
        dri.delay_us = 10 * (cmd - '0');
        printf("set delay to %lu us\n", dri.delay_us);
        break;

      default:
        printf("unknown command: 0x%02X\n", cmd);
        break;
      }
    }
  }
}
