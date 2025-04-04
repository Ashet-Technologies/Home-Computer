include <parameters.scad>
use <../lib/common.scad>
use <../lib/xcon.scad>

module slot_plate_2d()
{
    size = [ slot_plate_width, slot_plate_height ];

    difference()
    {
        square(size, true);

        ymirror() translate([ 0, slot_screw_offset, 0 ]) screw_hole_2d(slot_screw_type);
    }
}

module slot_plate()
{
    xrotate(90) linear_extrude(height = slot_plate_thickness, center = true) slot_plate_2d();
}

module xcon_slot_plate_2d()
{
    difference()
    {
        zrotate(90) slot_plate_2d();
        translate([ 0, slot_pcb_offset ]) xcon_cutout() children();
    }
}

module xcon_slot_plate(with_models = true, with_plate = true)
{
    zrotate(180) yrotate(-90)
    {
        if (with_plate)
        {
            mat_metal() xrotate(90) linear_extrude(height = slot_plate_thickness, center = true)
            {
                xcon_slot_plate_2d() children();
            }
        }
        if (with_models)
        {
            translate([ 0, 0, slot_pcb_offset ]) xcon_model() children();
        }
    }
}

if (RENDER_PART_2D)
{
    slot_plate_2d();
}

if (RENDER_PART_3D)
{
    slot_plate();
}