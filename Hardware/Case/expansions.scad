
include <parts/slot_plate.scad>



module xcon_expansion_dummy(i)
{
    if($cutout_mode) {
        union() {
            xmirror() translate([slot_mount_screw_dist/2,slot_pcb_thickness/2+slot_mount_screw_pcb_dist]) circle(d=slow_mount_screw_type[1],$fn=20);
        }
    }
}

module xcon_expansion(i)
{
    select_child(i)
    {
        union() // GPIO 8
        {
            xcon_pinheader_12x2();
        }
        union() // Empty
        {
            
        }
        union() // C64 Serial
        {
            xdist(34,2)  xcon_din6();
        }
        union() // RS232
        {
            xdist(34,2)  xcon_rs232();
        }
        union() // USBx4
        {
            xdist(17,4) xcon_usb_a();
        }
        union() // Stereo InOut
        {
            xdist(35,2) xdist(13,2) xcon_cinch();
        }
        union() // Video Card
        {
            xdist(26)
            {
                xcon_hdmi();
                xcon_vga();
                xcon_cinch();
            }
        }
        union() // Mainboard
        {
            xdist(15)
            {
                xcon_usb_c();
                xcon_ms_x2();
                xcon_usb_av();
                xcon_rj45();
            }
        }
    }
}