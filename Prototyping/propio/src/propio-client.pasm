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

  PROPIO_DIR_HOST_READ = 0
  PROPIO_DIR_HOST_WRITE = 1

  GP_0 = 24
  GP_1 = 25
  GP_2 = 26
  GP_3 = 27
  GP_4 = 28
  GP_5 = 29
  GP_6 = 30
  GP_7 = 31

  ' Lower BYTE of INB/OUTB/DIRB
  DBG_0 = 32
  DBG_1 = 33
  DBG_2 = 34
  DBG_3 = 35
  DBG_4 = 36
  DBG_5 = 37
  DBG_6 = 38
  DBG_7 = 39

  UART_TX = 62
  UART_RX = 63

  LED_PIN = 56

  CONTROL_CORE_CODE = $00000
  CONTROL_CORE_DATA = $00800
  SLOT_1_CODE = $01000
  SLOT_1_CONF = $01800
  SLOT_2_CODE = $02000
  SLOT_2_CONF = $02800
  SLOT_3_CODE = $03000
  SLOT_3_CONF = $03800
  SLOT_4_CODE = $04000
  SLOT_4_CONF = $04800
  SLOT_5_CODE = $05000
  SLOT_5_CONF = $05800
  SLOT_6_CODE = $06000
  SLOT_6_CONF = $06800
  SLOT_7_CODE = $07000
  SLOT_7_CONF = $07800
  
  SLOT_1_RAM = $10000
  SLOT_2_RAM = $20000
  SLOT_3_RAM = $30000
  SLOT_4_RAM = $40000
  SLOT_5_RAM = $50000
  SLOT_6_RAM = $60000
  SLOT_7_RAM = $70000

  CLK_SYS = 300_000_000 ' Hz
  PROPIO_BAUD = 50_000_000 ' Hz
  DEBUG_BAUD = 115_200 ' Hz

DAT
  orgh CONTROL_CORE_CODE
  org 0
  _start
    HUBSET  #$F0
            ' %0000000_E_DDDDDD_MMMMMMMMMM_PPPP_CC_SS
    HUBSET  ##%0000000_1_000000_0000001001_1111_10_00 ' enable crystal+PLL, stay in RCFAST mode
    WAITX   ##20_000_000/100                  ' wait ~10ms for crystal+PLL to stabilize
    ' HUBSET  ##%0000000_1_000000_0000001001_1111_10_11 ' now switch to PLL running at 200.0 MHz
    HUBSET  ##%0000000_1_000000_0000001110_1111_10_11 ' now switch to PLL running at 300.0 MHz

    ' Setup Debug Port
    OR DIRB, #$FF
    OR OUTB, #$FF

    ' Debug LED
    DRVH #LED_PIN

    ' Configure UART RX/TX:
    WRPIN #%0000_0000_000_0000000000000_01_11110_0, #UART_TX
    WRPIN #%0000_0000_000_0000000000000_00_11111_0, #UART_RX

    ' 115200 @ 8 bit
    WXPIN ##(((CLK_SYS / DEBUG_BAUD * $1_0000) & $FFFFFC00) | (8-1)), #UART_TX
    WXPIN ##(((CLK_SYS / DEBUG_BAUD * $1_0000) & $FFFFFC00) | (8-1)), #UART_RX

    ' Enable debug UART
    DIRH #UART_TX
    DIRH #UART_RX

    WAITX #3

    WRPIN #%0000_0000_000_0000000000000_00_11111_0, #GP_0 ' GP0 = UART RX
    WXPIN ##(((CLK_SYS / PROPIO_BAUD * $1_0000) & $FFFFFC00) | (8-1)), #GP_0 
    DIRH #GP_0 ' turn on smart pin

    WYPIN #$21, #UART_TX

    SETSE1 #(%001_000000 | GP_0)  ' SE1 = rising edge on GP_0 => Data Ready

  highspeed_loop
    WAITSE1
    RDPIN tmp, #GP_0
    SHR tmp, #32-8 ' left-align data
    SETBYTE OUTB, tmp, #0 ' write to debug output
    WYPIN tmp, #UART_TX
    JMP #highspeed_loop
    

    SETSE1 #(%001_000000 | PROPIO_EN)  ' SE1 = rising edge on EN
    SETSE2 #(%010_000000 | PROPIO_CLK)  ' SE2 = falling edge on CLK

    MOV IJMP1, #propio_start_transaction
    MOV IJMP2, #propio_rcv_nibble_hi

    SETINT1 #4 ' SE1
    SETINT2 #0 ' disabled
    SETINT3 #0 ' disabled

    SETBYTE OUTB, #$00, #0

    ALLOWI

  main_loop
    SETBYTE OUTB, #$00, #0 ' marks the running of the main loop
    JMP #main_loop

  propio_start_transaction
    SETBYTE OUTB, #$01, #0
    TESTP #PROPIO_DIR WC
    IF_NC JMP #propio_start_read_transaction
    ' this is a write transaction, prepare to receive

    ' Setup INT1 to handle falling EN edges
    SETSE1 #(%010_000000 | PROPIO_EN)    ' SE1 = falling edge on EN
    MOV IJMP1, #propio_stop_transaction ' install stop handler

    ' Setup INT2 to handle falling CLK edges:
    MOV IJMP2, #propio_rcv_nibble_hi
    SETINT2 #5 ' SE2
    

    SETBYTE OUTB, #$02, #0
    RETI1
  
  propio_stop_transaction
    SETBYTE OUTB, #$80, #0
    SETSE1 #(%001_000000 | PROPIO_EN)    ' SE1 = rising edge on EN
    SETINT2 #0                           ' disable clock interrupt
    MOV IJMP1, #propio_start_transaction ' install start handler again
    
    RETI1
  
  propio_start_read_transaction
    ' this is a read transaction, prepare to send
    SETBYTE OUTB, #$40, #0
    RETI1
  
  propio_rcv_nibble_hi
    SETBYTE OUTB, #$02, #0
    GETNIB tmp, INA, #0                   ' fetch data from i/o port
    SETNIB propio_byte_buffer, tmp, #1    ' store upper nibble
    ' RESI1 ' continue with next line
    MOV IJMP2, #propio_rcv_nibble_lo
    RETI2

  propio_rcv_nibble_lo
    SETBYTE OUTB, #$04, #0
    GETNIB tmp, INA, #0                   ' fetch data from i/o port
    SETNIB propio_byte_buffer, tmp, #0    ' store lower nibble
    SETBYTE OUTB, propio_byte_buffer, #0  ' debug out
    WYPIN propio_byte_buffer, #UART_TX
    MOV IJMP2, #propio_rcv_nibble_hi
    RETI2

  propio_byte_buffer
    LONG 0

  ' main_loop
  '   REP @main_loop_end, #0
  '   TESTP #UART_RX WC
  '   IF_C JMP #recv_char
  '   TESTP #PROPIO_EN WC
  '   IF_C JMP #init_propio
  ' main_loop_end

  ' init_propio
  '   TESTP #PROPIO_DIR WC

  '   IF_C JMP #perform_receive

  ' perform_send
  '   WYPIN #"S", #UART_TX

  '   JMP #wait_complete

  ' wait_complete 
  '   TESTP #PROPIO_EN WC
  '   IF_C JMP #wait_complete
  ' propio_done
  '   WYPIN #"]", #UART_TX 
  '   JMP #main_loop

  ' perform_receive
  '   ' SE1 = falling edge on CLK
  '   SETSE1 %010_000000 | PROPIO_CLK
  '   ' SE2 = falling edge on EN
  '   SETSE2 %010_000000 | PROPIO_EN
  '   WYPIN #"[", #UART_TX

  ' rcv_next_byte
  '   MODZ _CLR WZ
  '   MOV databyte, #0

  ' rcv_next_nibble

  ' ' wait for the clock to go low, then sample the pins
  ' rcv_wait_clk_low
  '   JSE2 #propio_done
  '   JNSE1 #rcv_wait_clk_low
  ' .end

  '   ' clk had a falling edge, let's sample the data:
  '   GETNIB tmp, INA, #0
  '   IF_NZ SETNIB databyte, tmp, #1 ' first transfer is upper nibble
  '   IF_Z  SETNIB databyte, tmp, #0 ' second transfer is lower nibble

  '   ' clk had a rising edge, switch to next nibble or process data:
  '   IF_Z JMP #rcv_process_byte
  '   MODZ _SET WZ
  '   JMP #rcv_next_nibble

  ' rcv_process_byte
  '   ' send response over UART for now
  '   WYPIN databyte, #UART_TX

  '   JMP #rcv_next_byte

  ' databyte
  '   LONG 0
  
  ' recv_char
  '   OUTNOT #LED_PIN

  '   RDPIN tmp, #UART_RX   ' read received word
  '   SHR tmp, #32-8        ' right-justify it

  '   WYPIN  tmp, #UART_TX  ' echo

  '   JMP #main_loop

  tmp
    LONG 0

