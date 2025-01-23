



include <../expansions.scad>
include <../parts/slot_pcb.scad>
use <../lib/common.scad>
use <../models/models.scad>

RENDER_SLOT_2D = false;
RENDER_SLOT_3D = false;

SLOT_ID = 3;
KIND = "none";

if (RENDER_SLOT_2D)
{
    xcon_slot_plate_2d() xcon_expansion(SLOT_ID);
}

if (RENDER_SLOT_3D)
{
    if (KIND == "full")
    {
        xcon_slot_plate() xcon_expansion(SLOT_ID);

        translate([slot_pcb_offset,-slot_pcb_length/2-slot_plate_thickness/2,0])  mat_pcb() slot_pcb();

        zmirror() translate([0,slot_plate_thickness/2,slot_screw_offset]) xrotate(90) screw_m2_5_4mm(); // screw_model(slot_screw_type, slot_screw_length );>
    }
    else if (KIND == "frontplate")
    {
        xcon_slot_plate(with_models=false) xcon_expansion(SLOT_ID);
    }
    else if (KIND == "connectorss")
    {
        xcon_slot_plate(with_plate=false) xcon_expansion(SLOT_ID);
    }
    else
    {
        echo("unknown kind: " + KIND);
    }
}