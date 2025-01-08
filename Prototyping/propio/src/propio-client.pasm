CON

  CLK = 200_000_000

  PROPIO_D0 = 0
  PROPIO_D1 = 1
  PROPIO_D2 = 2
  PROPIO_D3 = 3
  PROPIO_CLK = 4
  PROPIO_EN = 5
  PROPIO_DIR = 6
  PROPIO_nREQ = 7

  UART_TX = 62
  UART_RX = 63

  LED_PIN = 56

DAT
  _start
    HUBSET  #$F0
            ' %0000000_E_DDDDDD_MMMMMMMMMM_PPPP_CC_SS
    HUBSET  ##%0000000_1_000000_0000001001_1111_10_00 ' enable crystal+PLL, stay in RCFAST mode
    WAITX   ##20_000_000/100                  ' wait ~10ms for crystal+PLL to stabilize
    HUBSET  ##%0000000_1_000000_0000001001_1111_10_11 ' now switch to PLL running at 200.0 MHz

    ' Debug LED
    DIRH #LED_PIN
    OUTH #LED_PIN

    ' Configure UART RX/TX:
    WRPIN #%0000_0000_000_0000000000000_01_11110_0, #UART_TX
    WRPIN #%0000_0000_000_0000000000000_00_11111_0, #UART_RX

    ' 115200 @ 8 bit
    WXPIN ##$06C8_1C07, #UART_TX
    WXPIN ##$06C8_1C07, #UART_RX

    ' Enable debug UART
    DIRH #UART_TX
    DIRH #UART_RX


    WAITX #3

    WYPIN #$21, #UART_TX

  main_loop
    REP @main_loop_end, #0
    TESTP #UART_RX WC
    IF_C JMP #recv_char
  main_loop_end

  recv_char
    OUTNOT #LED_PIN

    RDPIN tmp, #UART_RX   ' read received word
    SHR tmp, #32-8        ' right-justify it

    WYPIN  tmp, #UART_TX  ' echo

    JMP #main_loop

  tmp
    LONG 0