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

enum : uint {
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

enum : uint {
  GP_0 = 24,
  GP_1 = 25,
  GP_2 = 35,
  GP_3 = 34,
  GP_4 = 33,
  GP_5 = 32,
  GP_6 = 30,
  GP_7 = 31,
};

struct GeneralIO {
  static constexpr uint pins[] = {
      GP_0, GP_1, GP_2, GP_3, GP_4, GP_5, GP_6, GP_7,
  };

  void init() {
    for (uint pin : pins) {
      gpio_set_function(pin, GPIO_FUNC_SIO);
    }

    for (uint pin : pins) {
      gpio_set_dir(pin, GPIO_IN);
    }
  }

  void set_dir(uint p, gpio_dir out) { gpio_set_dir(pins[p], GPIO_IN); }

  void set(uint p, bool level) { gpio_put(pins[p], level); }

  bool get(uint p) { return gpio_get(pins[p]); }
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

  void deinit() {
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

struct VirtualMachine {
  Driver *driver;
  GeneralIO *io;

  uint stackPtr = 0;
  uint8_t stack[256];
  bool literal_mode = false;

  VirtualMachine(Driver *driver, GeneralIO *io) : driver{driver}, io{io} {
    //
  }

  void exec(uint8_t cmd) {
    if (cmd == 0)
      return;

    if (this->literal_mode) {
      printf("%c", cmd);
      if (cmd == '"') {
        this->literal_mode = false;
        printf("\n");
      } else {
        this->push(cmd);
      }
      return;
    }

    switch (cmd) {

    case '"':
      this->literal_mode = true;
      printf("\"");
      break;

    case '0' ... '9':
      this->push(cmd - '0');
      break;

    case 'a' ... 'f':
      this->push(cmd - 'a' + 10);
      break;

    case 'A' ... 'F':
      this->push(cmd - 'a' + 10);
      break;

    case 's': {
      printf("sending[");
      this->driver->start_write_transaction();

      uint8_t byte;
      while (this->pop(byte)) {
        printf("%c", byte);
        this->driver->write_byte(byte);
      }

      this->driver->end_transaction();
      printf("]\n");

      break;
    }

    case '?': {
      if (this->stackPtr == 0) {
        printf("Stack: empty\n");
        break;
      }
      printf("Stack:\n");
      for (uint i = 0; i < this->stackPtr; i++) {
        printf("  [%u] %u\n", i, this->stack[i]);
      }
      break;
    }

    case 'i': {
      uint8_t pin;
      if (!this->pop(pin)) {
        printf("stack empty\n");
        break;
      }

      printf("GP%u = IN\n", pin);
      this->io->set_dir(pin, GPIO_IN);

      break;
    }

    case 'w': {
      uint8_t level;
      if (!this->pop(level)) {
        printf("stack empty\n");
        break;
      }

      uint8_t pin;
      if (!this->pop(pin)) {
        printf("stack empty\n");
        break;
      }

      printf("GP%u = OUT:%u\n", pin, level);
      this->io->set_dir(pin, GPIO_OUT);
      this->io->set(pin, level);
      break;
    }

    case 'h': {

      uint8_t pin;
      if (!this->pop(pin)) {
        printf("stack empty\n");
        break;
      }

      printf("GP%u = OUT:1\n", pin);
      this->io->set_dir(pin, GPIO_OUT);
      this->io->set(pin, 1);
      break;
    }

    case 'l': {

      uint8_t pin;
      if (!this->pop(pin)) {
        printf("stack empty\n");
        break;
      }

      printf("GP%u = OUT:0\n", pin);
      this->io->set_dir(pin, GPIO_OUT);
      this->io->set(pin, 0);
      break;
    }

    case 'r': {
      printf("IO:\n");
      for (uint i = 0; i < 8; i++) {
        printf("  GP%u = %u\n", i, this->io->get(i));
      }
      break;
    }

    case 't': {
      uint8_t delay;
      if (!this->pop(delay)) {
        printf("stack empty\n");
        break;
      }

      this->driver->delay_us = 10 * delay;
      printf("set delay to %lu us\n", this->driver->delay_us);
      break;
    };
    }
  }

  void push(uint8_t value) {
    hard_assert(this->stackPtr < sizeof this->stack);
    this->stack[this->stackPtr] = value;
    this->stackPtr++;
  }

  bool pop(uint8_t &value) {
    if (this->stackPtr == 0)
      return false;
    this->stackPtr -= 1;
    value = this->stack[this->stackPtr];
    return true;
  }
};

int main(void) {

  stdio_init_all();

  Driver dri;
  GeneralIO gio;

  dri.init();
  gio.init();

  while (true) {
    while (!stdio_usb_connected()) {
      __wfi();
    }

    printf("ready.\n");

    VirtualMachine vm{&dri, &gio};

    while (stdio_usb_connected()) {
      int cmd = stdio_getchar();
      vm.exec(cmd);
    }
  }
}
