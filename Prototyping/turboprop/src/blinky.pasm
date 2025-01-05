DAT
  entry
    hubset ##16779771 '' external quarz + pll * 10
    
    DIRH #63

  rep @main_loop_end, #0
    OUTNOT #63
    WAITX ##100_000_000

  main_loop_end

  tmp
    long 0