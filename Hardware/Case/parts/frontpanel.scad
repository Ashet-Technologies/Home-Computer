include <parameters.scad>
use <../lib/common.scad>

module frontpanel_2d()
{
    size = [ 242.25, 94.25 ] / 2;

    corner_radius = 3;

    difference()
    {
        hull()
        {
            xymirror2d()
            {
                translate(size - [ corner_radius, corner_radius ]) circle(corner_radius);
            }
        }

        foreach_slot()
        {
            square([slot_hole_width, slot_hole_height], true);


            ymirror() translate([0,slot_plate_height/2-slot_screw_inset,0]) screw_hole_2d(slot_screw_type);
        }
    }
}

module frontpanel()
{
    xrotate(90) linear_extrude(height = frontpanel_thickness, center = true) frontpanel_2d();
}

if (RENDER_PART_2D)
{
    frontpanel_2d();
}

if (RENDER_PART_3D)
{
    frontpanel();
}