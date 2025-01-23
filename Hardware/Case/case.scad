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

include <expansions.scad>

HIDE_TOP = true;

baseplate_spread = 41.4;

translate([0,0,-baseplate_spread]) mat_glass() baseplate_mount_plate();

if(!HIDE_TOP)
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
}

translate([0,169/2,0])
{
    frontpanel();

    translate([0,(slot_plate_thickness+frontpanel_thickness)/2,0]) foreach_slot()
    {
        xcon_slot_plate() xcon_expansion($i);
        
        translate([slot_pcb_offset,-slot_pcb_length/2-slot_plate_thickness/2,0])  mat_pcb() slot_pcb();

        zmirror() translate([0,slot_plate_thickness/2,slot_screw_offset]) xrotate(90) screw_m2_5_4mm(); // screw_model(slot_screw_type, slot_screw_length );
    }
}

translate([0,0,0.25]) mat_plastic() case_rm2095l(fp = false, bot = HIDE_TOP);

translate([0,0,0.25]) mat_plastic() case_rm2095l_fp();
