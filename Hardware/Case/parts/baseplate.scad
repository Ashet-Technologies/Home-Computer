use <../lib/common.scad>
include <parameters.scad>
include <pcb_slider.scad>

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

        // Cutouts for the pcb_slider mounting points:

        translate([0,169/2])
        {
            foreach_slot()
            {
                translate([slot_pcb_offset,-slot_pcb_length/2+1]) // TODO: Figure out this "1" here!
                {
                    tdist = pcb_slider_length - 2 * pcb_slider_hole_margin;
                    hdist = tdist / (pcb_slider_holes-1);
                    for($i = [0: pcb_slider_holes-1]) {
                            off = hdist * $i -(pcb_slider_length/2 - pcb_slider_hole_margin);

                            translate([0,off]) screw_hole_2d(pcb_slider_hole_screw);
                    }   
                }
            }
        }

        // Cutouts to fit the case, symmetric on x and y axis:
        xymirror2d()
        {
            // mounting holes:
            translate(hole1_dist) circle(d = hole_size, $fn=20);
            translate(hole2_dist) circle(d = hole_size, $fn=20);

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

// baseplate_mount_plate_2d();