#include <assert.h>
#include <hardware/dma.h>
#include <hardware/gpio.h>
#include <hardware/irq.h>
#include <pico/multicore.h>
#include <pico/sem.h>
#include <pico/stdio.h>
#include <pico/stdio_usb.h>
#include <stdio.h>
#include <string.h>

#include "propio.pio.h"
#include "uart.pio.h"

enum PropioPort : uint {
  PROPIO_BASE = 36,
  PROPIO_D0 = PROPIO_BASE + 0,
  PROPIO_D1 = PROPIO_BASE + 1,
  PROPIO_D2 = PROPIO_BASE + 2,
  PROPIO_D3 = PROPIO_BASE + 3,
  PROPIO_CLK = PROPIO_BASE + 4,
  PROPIO_EN = PROPIO_BASE + 5,
  PROPIO_DIR = PROPIO_BASE + 6,
  PROPIO_nREQ = PROPIO_BASE + 7,

  PROPIO_TX0 = PROPIO_BASE + 0,
  PROPIO_TX1 = PROPIO_BASE + 1,
  PROPIO_RX0 = PROPIO_BASE + 2,
  PROPIO_RX1 = PROPIO_BASE + 3,
};

enum DebugPort : uint {
  DGB_0 = 0,
  DGB_1 = 1,
  DGB_2 = 2,
  DGB_3 = 3,
  DGB_4 = 4,
  DGB_5 = 5,
  DGB_6 = 6,
  DGB_7 = 7,
};

enum GeneralPurposePort : uint {
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
  virtual void init() = 0;

  virtual void start_write_transaction() = 0;
  virtual void start_read_transaction() = 0;
  virtual void end_transaction() = 0;

  virtual void write_byte(uint8_t data) = 0;
};

struct ParallelDriver : Driver {
  uint32_t delay_us = 100;

  void init() override {
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

  void start_write_transaction() override {
    this->set_dir(GPIO_OUT);
    gpio_put(PROPIO_CLK, 1);
    gpio_put(PROPIO_EN, 1);
  }

  void start_read_transaction() override {
    this->set_dir(GPIO_IN);
    gpio_put(PROPIO_EN, 1);
  }

  void end_transaction() override {
    gpio_put(PROPIO_EN, 0);
    this->set_dir(GPIO_IN);
  }

  void write_byte(uint8_t data) override {
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

struct UartDriver : Driver {
  PIO pio = pio0;
  uint sm_tx_id = 0;
  uint pin_tx0 = GP_0;

  void init() override {
    pio_sm_set_enabled(pio, sm_tx_id, false);

    pio_add_program_at_offset(pio, &propio_program, 0);

    printf("initialize pin %u\n", pin_tx0);
    propio_program_init(pio,
                        sm_tx_id, // sm
                        0,        // offset
                        pin_tx0);
    gpio_set_slew_rate(pin_tx0, GPIO_SLEW_RATE_FAST);
    gpio_set_drive_strength(pin_tx0, GPIO_DRIVE_STRENGTH_12MA);
  }

  void start_write_transaction() override {
    //
  }

  void start_read_transaction() override {
    //
  }

  void end_transaction() override {
    //
  }

  void write_byte(uint8_t data) override {
    uart_tx_program_putc(pio, sm_tx_id, data);
  }
};

enum ProtocolMessage : uint8_t {
  MSG_WRITE_MEM = 0,
  MSG_READ_MEM = 1,
  MSG_START_SLOT = 2,
  MSG_STOP_SLOT = 3,
  MSG_WRITE_FIFO = 4,
  MSG_READ_FIFO = 5,
  MSG_CONFIGURE_FIFO = 6,
  MSG_ACK_IRQ = 7,
};

struct ProtocolHandler {
  Driver *driver;

  ProtocolHandler(Driver *driver) : driver(driver) {}

  void start_slot(uint8_t slot)
  {
    this->send(MSG_START_SLOT, &slot, 1);
  }

  void stop_slot(uint8_t slot)
  {
    this->send(MSG_START_SLOT, &slot, 1);
  }

  void write_mem(uint32_t address, uint8_t * const data, uint32_t length) {
    uint8_t *blocks[2] = {(uint8_t *)&address, data};
    size_t lengths[2] = {4, length};
    this->sendv(MSG_WRITE_MEM, blocks, lengths, 2);
  }

  void read_mem(uint32_t address, uint32_t length) {
    uint8_t *blocks[2] = {(uint8_t *)&address, (uint8_t *)&length};
    size_t lengths[2] = {4, 4};
    this->sendv(MSG_READ_MEM, blocks, lengths, 2);
  }

  void send(ProtocolMessage type, char const *message) {
    this->send(type, (uint8_t *)message, strlen(message));
  }

  void send(ProtocolMessage type, uint8_t const *data, size_t length) {
    this->sendv(type, &data, &length, 1);
  }

  void sendv(ProtocolMessage type, uint8_t const *const *data,
             size_t const *lengths, size_t vec_count) {
    size_t length = 0;
    for (size_t i = 0; i < vec_count; i++) {
      length += lengths[i];
    }

    hard_assert(length < 256);

    this->driver->start_write_transaction();

    this->driver->write_byte(type);
    this->driver->write_byte(length);

    for (size_t v = 0; v < vec_count; v++) {
      uint8_t const *v_data = data[v];
      size_t v_len = lengths[v];
      for (size_t i = 0; i < v_len; i++) {
        this->driver->write_byte(v_data[i]);
      }
    }

    this->driver->write_byte(0xAA); // Dummy CRC
    this->driver->write_byte(0x55); // Dummy CRC

    this->driver->end_transaction();
  }
};

struct VirtualMachine {
  Driver *driver;
  GeneralIO *io;

  uint stackPtr = 0;
  uint8_t stack[256];
  bool literal_mode = false;

  ProtocolHandler protocol;

  VirtualMachine(Driver *driver, GeneralIO *io) : driver{driver}, io{io}, protocol{driver} {
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

    case '.':
      printf("stack cleared\n");
      this->stackPtr = 0;
      break;

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

    case 'I':
      printf("re-initialize driver\n");
      this->driver->init();
      break;

    case 's': {
      printf("sending[");
      this->driver->start_write_transaction();

      uint8_t byte;
      for (size_t i = 0; i < this->stackPtr; i++) {
        printf("%c", this->stack[i]);
        this->driver->write_byte(this->stack[i]);
      }

      this->driver->end_transaction();
      printf("]\n");

      break;
    }

    case 'w':
    {
      this->protocol.write_mem(0x0000'0000, (uint8_t*)"hello, world!", 13);
      break;
    }

    // case 'i': {
    //   uint8_t pin;
    //   if (!this->pop(pin)) {
    //     printf("stack empty\n");
    //     break;
    //   }

    //   printf("GP%u = IN\n", pin);
    //   this->io->set_dir(pin, GPIO_IN);

    //   break;
    // }

    // case 'w': {
    //   uint8_t level;
    //   if (!this->pop(level)) {
    //     printf("stack empty\n");
    //     break;
    //   }

    //   uint8_t pin;
    //   if (!this->pop(pin)) {
    //     printf("stack empty\n");
    //     break;
    //   }

    //   printf("GP%u = OUT:%u\n", pin, level);
    //   this->io->set_dir(pin, GPIO_OUT);
    //   this->io->set(pin, level);
    //   break;
    // }

    // case 'h': {

    //   uint8_t pin;
    //   if (!this->pop(pin)) {
    //     printf("stack empty\n");
    //     break;
    //   }

    //   printf("GP%u = OUT:1\n", pin);
    //   this->io->set_dir(pin, GPIO_OUT);
    //   this->io->set(pin, 1);
    //   break;
    // }

    // case 'l': {

    //   uint8_t pin;
    //   if (!this->pop(pin)) {
    //     printf("stack empty\n");
    //     break;
    //   }

    //   printf("GP%u = OUT:0\n", pin);
    //   this->io->set_dir(pin, GPIO_OUT);
    //   this->io->set(pin, 0);
    //   break;
    // }

    // case 'r': {
    //   printf("IO:\n");
    //   for (uint i = 0; i < 8; i++) {
    //     printf("  GP%u = %u\n", i, this->io->get(i));
    //   }
    //   break;
    // }

      // case 't': {
      //   uint8_t delay;
      //   if (!this->pop(delay)) {
      //     printf("stack empty\n");
      //     break;
      //   }

      //   this->driver->delay_us = 10 * delay;
      //   printf("set delay to %lu us\n", this->driver->delay_us);
      //   break;
      // }

      // case 'U': {
      //   printf("init uart\n");

      //   pio_sm_set_enabled(pio0, 0, false);

      //   pio_add_program_at_offset(pio0, &uart_tx_program, 0);

      //   uart_tx_program_init(pio0,
      //                        0, // sm
      //                        0, // offset
      //                        DGB_0, 115'200);
      //   break;
      // }

      // case 'S': {
      //   printf("uart_tx[");

      //   uint8_t byte;
      //   while (this->pop(byte)) {
      //     // printf("%c", byte);
      //     uart_tx_program_putc(pio0, 0, byte);
      //   }
      //   printf("]\n");

      //   break;
      // }
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

  stdio_usb_init();

  // ParallelDriver dri;
  UartDriver dri;
  GeneralIO gio;

  dri.init();
  // gio.init();

  while (true) {
    while (!stdio_usb_connected()) {
      __wfi();
    }

    printf("clk_sys  = %lu Hz\n", clock_get_hz(clk_sys));
    printf("clk_peri = %lu Hz\n", clock_get_hz(clk_peri));
    printf("clk_usb  = %lu Hz\n", clock_get_hz(clk_usb));

    dri.init();
    // gio.init();

    printf("ready.\n");

    VirtualMachine vm{&dri, &gio};

    while (stdio_usb_connected()) {
      int cmd = stdio_getchar();
      vm.exec(cmd);
    }
  }
}
