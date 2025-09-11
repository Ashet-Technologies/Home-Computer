use <lib/ISOThreadUM2.scad>
use <lib/ScrewsMetric/ScrewsMetric/ScrewsMetric.scad>
use <lib/common.scad>
use <models/models.scad>

include <parts/parameters.scad>

include <parts/baseplate.scad>
include <parts/backplane.scad>
include <parts/frontpanel.scad>
include <parts/slot_plate.scad>
include <parts/slot_pcb.scad>
include <parts/pcb_slider.scad>

include <expansions.scad>

HIDE_TOP = true;


translate([0,0,-baseplate_spread]) mat_glass() baseplate_mount_plate();

if(HIDE_TOP)
{
    translate([0,0,baseplate_spread]) mat_glass() baseplate_mount_plate();
}

translate([0,backplane_offset,0]) {
   mat_pcb() xrotate(90) backplane();

    foreach_slot()
    {
        zadjust = 5;
        translate([slot_pcb_offset,0,-slot_pcb_conn_offset+zadjust]) xrotate(-90) conn_pcie_x4();
    }
    translate([0,-0.8,0]) yrotate(180) xrotate(-90) import("../Mechanical Prototype/Backplane/Backplane.stl");
}

translate([0,169/2,0])
{
    frontpanel();

    translate([0,(slot_plate_thickness+frontpanel_thickness)/2,0]) foreach_slot()
    {
        translate([slot_pcb_offset-slot_pcb_thickness/2,-slot_plate_thickness/2,0]) color("green") zrotate(-90) xrotate(-90) import("../Mechanical Prototype/Expansion Board/Expansion Board.stl");
        
        // translate([slot_pcb_offset,-slot_pcb_length/2-slot_plate_thickness/2,0]) mat_pcb() slot_pcb();
        
        xcon_slot_plate() xcon_expansion_dummy($i);
        

        color("gray") zmirror() translate([slot_pcb_offset,-slot_pcb_length/2-slot_plate_thickness/2,-baseplate_spread + baseplate_thickness/2]) pcb_slider();
        

        zmirror() translate([0,slot_plate_thickness/2,slot_screw_offset]) xrotate(90) screw_m2_5_4mm();
    }
}

translate([0,0,0.25]) mat_plastic() case_rm2095l(fp = false, bot = HIDE_TOP);

translate([0,0,0.25]) mat_plastic() case_rm2095l_fp();
