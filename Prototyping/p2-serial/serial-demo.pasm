DAT
  entry
    ''  %0000_000E_DDDD_DDMM_MMMM_MMMM_PPPP_CCSS
    '' 0b0000_0001_0000_0000_0000_1001_1111_1011
    ''           E                               = "PLL on"
    ''             DDDD_DD                       = xi div:  1
    ''                    MM_MMMM_MMMM           = vco mul: 10
    ''                                 PPPP      = "VCO / 1"
    ''                                      CC   = "15pF per pin"
    ''                                        SS = clk:PLL
    '' => "CLK = XI * 20 with PLL enabled"
    hubset ##16779771 '' _clkmode = 0x10009FB = 200 MHz
    
    '' Configure Pin as UART TX
    ''     %AAAA_BBBB_FFF_MMMMMMMMMMMMM_TT_SSSSS_0
    WRPIN #%0000_0000_000_0000000000000_01_11110_0, #0

    '' Configure Pin as UART RX
    ''     %AAAA_BBBB_FFF_MMMMMMMMMMMMM_TT_SSSSS_0
    WRPIN #%0000_0000_000_0000000000000_00_11111_0, #1

    '' Configure Pin UART TX Mode
    '' X[31:16] establishes the number of clocks in a bit period, and in case X[31:26] is zero, X[15:10]
    '' establishes the number of fractional clocks in a bit period. The X bit period value can be simply computed
    '' as: (clocks * $1_0000) & $FFFFFC00. For example, 7.5 clocks would be $00078000, and 33.33 clocks
    '' would be $00215400.
    '' 115200 baud @ 200 MHz yields 1736.111… clocks
    ''          %DDDDDDDDDDDDDDDD__BBBBB
    WXPIN ##$06C8_1C07, #0 '' 115200 @ 8 bit
    WXPIN ##$06C8_1C07, #1 '' 115200 @ 8 bit

    '' enable smart pin
    DIRH #0
    DIRH #1
    DIRH #63

    WAITX ##10_000_000

    WYPIN #$21, #0 '' write '!'

  main_loop
    TESTP #1 WC
    IF_NC JMP #main_loop

    RDPIN tmp, #1 '' read received word
    SHR tmp, #32-8 '' right-justify it

    WYPIN  tmp, #0 '' echo
    OUTNOT #63 '' blink

    JMP #main_loop


  tmp
    long 0