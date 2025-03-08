// Metadata

M2_5     = [2.5,   2.7, 5.0, 2.0]; // screw thickness, hole diameter, nut dia, nut height
M3       = [3.0,   3.2, 5.5, 2.4]; // screw thickness, hole diameter, nut dia, nut height
UNC_4_40 = [2.845, 3.0, 4.0, 2.0]; // screw thickness, hole diameter, nut dia, nut height

// Configuration

SLOTS = 8;

// Slot Configuration

slot_separation = 28; // distance between slot centers

// size of the slot panel
slot_plate_width = 27;
slot_plate_height = 85;
slot_plate_thickness = 1.0;

// slot panel screw
slot_screw_type = M2_5;
slot_screw_inset = 3.0;
slot_screw_length = 4.5;

assert(slot_plate_width < slot_separation);

// size of the slot cutout
slot_hole_width = 24;
slot_hole_height = 73;

assert(slot_hole_width < slot_plate_width);
assert(slot_hole_height < slot_plate_height);

// size of the slot pcb
slot_pcb_height = 70;
slot_pcb_thickness = 1.6;
slot_pcb_length = 100;
slot_pcb_conn_offset = -15;

// offset of PCB to plate center
slot_pcb_offset = -9;

assert(slot_pcb_offset + slot_pcb_thickness / 2 < slot_hole_width/2)
assert(slot_pcb_height < slot_hole_height);

// Distance between the two mounting screw points on the PCB
slot_mount_screw_dist = 60; // mm
slot_mount_screw_pcb_dist = 6.4; // mm distance from the PCB top
slow_mount_screw_type = UNC_4_40;

// Baseplate
baseplate_thickness = 2.0;

// Backplane

// Offset from center
backplane_offset = -26.5;
backplane_thickness = 1.6;
backplane_width = 240;
backplane_height = 87;
backplane_inset_width = 200;
backplane_inset_height = 80.5;

// Frontpanel
frontpanel_thickness = 2.0;

// Automation Variables:
RENDER_PART_2D = false;
RENDER_PART_3D = false;

// Derived parameters

slot_screw_offset = slot_plate_height/2-slot_screw_inset;

// Utility modules

/* Invokes children() once for each slot, offsetted on the X axis, slot center. */
module foreach_slot()
{
    for ($i = [0:SLOTS - 1])
    {
        dx = slot_separation * ($i - (SLOTS - 1) / 2);
        translate([ dx, 0, 0 ]) children();
    }
}

module screw_shaft_2d(screw)
{
    circle(d=screw[0], $fn=20);
}

module screw_hole_2d(screw)
{
    circle(d=screw[1], $fn=20);
}

module screw_nut_2d(screw)
{
    circle(d=screw[2], $fn=6);
}

module screw_nut(screw)
{
    linear_extrude(screw[3]) screw_nut_2d(screw); 
}

module screw_model(screw, length)
{
    translate([0,0,-screw[3]]) screw_nut(screw);
    linear_extrude(length) screw_shaft_2d(screw); 
}