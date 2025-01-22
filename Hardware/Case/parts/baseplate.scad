use <../lib/common.scad>
include <parameters.scad>

module baseplate_mount_plate_2d()
{
    size = [ 240, 164 ];
    hole1_dist = [ 200, 110 ] / 2;
    hole2_dist = [ 160, 140 ] / 2;
    r_inset = 7;
    x_inset = 214 / 2;
    y_inset = 126 / 2;
    hole_size = 3.50;
    backplane_padding = 0.3; 

    difference()
    {
        square(size, true);

        // Cutout for the backplane:

        translate([0,backplane_offset]) square([backplane_inset_width + backplane_padding, backplane_thickness + backplane_padding], true);

        // Cutouts to fit the case, symmetric on x and y axis:
        xymirror2d()
        {
            // mounting holes:
            translate(hole1_dist) circle(d = hole_size);
            translate(hole2_dist) circle(d = hole_size);

            // corner cutouts:
            translate([ x_inset + r_inset, y_inset + r_inset ]) circle(r = r_inset);
            translate([ x_inset + r_inset, y_inset ]) square([ 100, 100 ]);
            translate([x_inset, y_inset + r_inset]) square([100,100]);
        }
    }
}

module baseplate_mount_plate()
{
    linear_extrude(height=baseplate_thickness, center=true) baseplate_mount_plate_2d();
}

if (RENDER_PART_2D)
{
    baseplate_mount_plate_2d();
}

if (RENDER_PART_3D)
{
    baseplate_mount_plate();
}
