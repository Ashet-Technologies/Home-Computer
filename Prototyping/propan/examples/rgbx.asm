.org       0x0000

pix_driver:     setq      10-1                                  # get 10 longs from hub
                rdlong    *connect, ptra

                mov       *t1, 0
                wrlong    *t1, ptra                             # tell hub we're connected

rgbx_main:      rdlong    *connect, ptra                wz      # check for new connection
    if_nz       jmp       &pix_driver

                mov       *addr, *p_hub                         # point to rgbbuf[0]
                mov       *npix, *pixcount                      # set # active pixels

frame_loop:     rdlong    *colorbits, *addr                     # read a channel
                add       *addr, 4                              # point to next
                tjz       *swapflag, &shift_out                 # skip fix if swap = 0

# Correct placement of rg color bytes
# -- $RR_GG_BB_WW --> $GG_RR_BB_WW

                mov       *t1, *colorbits                       # copy
                shr       *t1, 16                               # isolate r & g
                setbyte   *colorbits, *t1, 3                    # colorbits.byte[3] = g
                shr       *t1, 8
                setbyte   *colorbits, *t1, 2                    # colorbits.byte[2] = r

shift_out:      getct     *bittimer                             # start timing frame

                rep       rel(.bitz), *pixelbits                # loop through all bits
                rol       *colorbits, 1                 wc      # get MSB
                drvh      *tx                                   # pin on
    if_nc       waitx     *bit0hi                               # hold for bit timing
    if_c        waitx     *bit1hi
                drvl      *tx                                   # pin off
                addct1    *bittimer, *cycletix                  # update cycle timer
                waitct1                                         # let cycle finish
.bitz:

next_pixel:     djnz      *npix, &frame_loop                    # done with all leds?

reset_delay:    getct     *bittimer                             # reset delay
                addct1    *bittimer, *resettix
                waitct1

                jmp       &rgbx_main                            # back to top

# --------------------------------------------------------------------------------------------------

connect:         .res       1                                     # new connection flag
p_hub:           .res       1                                     # pointer to pixel buffer in use
pixcount:        .res       1                                     # # pixels in buffer
tx:              .res       1                                     # output pin
pixelbits:       .res       1                                     # bits per pixel
resettix:        .res       1                                     # frame reset timing
swapflag:        .res       1                                     # if !0, swap R & G
bit0hi:          .res       1                                     # bit0 high timing
bit1hi:          .res       1                                     # bit1 high timing
cycletix:        .res       1                                     # 1.25us cycle ticks

addr:            .res       1                                     # address of current rgbw pixel
npix:            .res       1                                     # no of pixels to process
colorbits:       .res       1                                     # rgbw for current pixel

bittimer:        .res       1                                     # timer for reset/bit

t1:              .res       1                                     # work vars
t2:              .res       1
t3:              .res       1

.fit                496