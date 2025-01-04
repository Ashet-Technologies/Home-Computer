DAT
  entry
    hubset ##16779771 '' _clkmode
        
    bith dirb, #31 '' pin

    rep @blink_loop_end, #0
    bitnot	outb, #31 '' pin
    waitx ##100000000 '' CLK_FREQ/2
        
    blink_loop_end
