use <lib/ISOThreadUM2.scad>
use <lib/ScrewsMetric/ScrewsMetric/ScrewsMetric.scad>
use <lib/common.scad>
use <lib/xcon.scad>
use <models/models.scad>

include <parts/parameters.scad>

include <parts/baseplate.scad>
include <parts/backplane.scad>
include <parts/frontpanel.scad>
include <parts/slot_plate.scad>
include <parts/slot_pcb.scad>

// xcon_slot_plate()
// {
//     // xcon_rs232();
//     // xcon_vga();
//     // xcon_cinch();
//     // xcon_usb_c();
//     // xcon_usb_a();
//     // xcon_usb_av();
//     // xcon_pinheader_12x2();
//     // xcon_din6();
//     // xcon_ms_x2();
//     // xcon_pi4();
//     // xcon_rj45();
//     // xcon_hdmi();
// }

pcb_slider();
// difference() {
//     pcb_slider_body_2d();

//     # pcb_slider_notch_2d();
// }
