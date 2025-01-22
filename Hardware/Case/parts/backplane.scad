use <../lib/common.scad>
include <parameters.scad>


// 
// 
// backplane_inset_width
// backplane_inset_height

module backplane_2d()
{
    size = [ backplane_width, backplane_height ];
    x_inset = backplane_inset_width / 2;
    y_inset = backplane_inset_height / 2;

    difference()
    {
        square(size, true);

        // Cutouts to fit the case, symmetric on x and y axis:
        xymirror2d()
        {
            // inset cutouts:
            translate([ x_inset, y_inset ]) square([100,100]);
        }
    }
}

module backplane()
{
    linear_extrude(height=backplane_thickness, center=true) backplane_2d();
}

if (RENDER_PART_2D)
{
    backplane_2d();
}

if (RENDER_PART_3D)
{
    backplane();
}
