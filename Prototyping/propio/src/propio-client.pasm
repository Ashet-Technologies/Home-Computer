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
    TESTP #PROPIO_EN WC
    IF_C JMP #init_propio
  main_loop_end

  init_propio
    TESTP #PROPIO_DIR WC

    IF_C JMP #perform_receive

  perform_send
    WYPIN #"S", #UART_TX

    JMP #wait_complete

  wait_complete 
    TESTP #PROPIO_EN WC
    IF_C JMP #wait_complete
  propio_done
    WYPIN #"]", #UART_TX 
    JMP #main_loop

  perform_receive
    WYPIN #"[", #UART_TX

  rcv_next_byte
    MODZ _CLR WZ
    MOV databyte, #0

  rcv_next_nibble

  ' wait for the clock to go low, then sample the pins
  rcv_wait_clk_low
    TESTP #PROPIO_EN WC
    IF_NC JMP #propio_done
    TESTP #PROPIO_CLK WC
    IF_C JMP #rcv_wait_clk_low

    ' clk had a falling edge, let's sample the data:
    GETNIB tmp, INA, #0
    IF_NZ SETNIB databyte, tmp, #1 ' first transfer is upper nibble
    IF_Z  SETNIB databyte, tmp, #0 ' second transfer is lower nibble

  rcv_wait_clk_high
    TESTP #PROPIO_EN WC
    IF_NC JMP #propio_done
    TESTP #PROPIO_CLK WC
    IF_NC JMP #rcv_wait_clk_high

    ' clk had a rising edge, switch to next nibble or process data:
    IF_Z JMP #rcv_process_byte
    MODZ _SET WZ
    JMP #rcv_next_nibble

  rcv_process_byte
    ' send response over UART for now
    WYPIN databyte, #UART_TX

    JMP #rcv_next_byte

  databyte
    LONG 0
  
  recv_char
    OUTNOT #LED_PIN

    RDPIN tmp, #UART_RX   ' read received word
    SHR tmp, #32-8        ' right-justify it

    WYPIN  tmp, #UART_TX  ' echo

    JMP #main_loop

  tmp
    LONG 0
    