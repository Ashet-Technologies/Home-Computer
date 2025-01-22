include <parameters.scad>
use <../lib/common.scad>

module slot_plate_2d()
{
    size = [ slot_plate_width, slot_plate_height ];


    difference()
    {
        square(size, true);

        ymirror() translate([0,slot_screw_offset,0]) screw_hole_2d(slot_screw_type);
    }
}

module slot_plate()
{
    xrotate(90) linear_extrude(height = slot_plate_thickness, center = true) slot_plate_2d();
}

if (RENDER_PART_2D)
{
    slot_plate_2d();
}

if (RENDER_PART_3D)
{
    slot_plate();
}