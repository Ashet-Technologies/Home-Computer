/*
 * Keystone Electronics 612
 * https://www.digikey.de/de/products/detail/keystone-electronics/612/416364
 *
 * https://www.keyelco.com/userAssets/file/M65p118.pdf
 */
width = 6.4; // mm
thickness = 1.57; // mm
height = 8.7; // mm
length = 9.5; // mm
h1_dia = 3.3; // mm
h1_dist = 5.2; // mm
h2_dia = 2.845; // mm, 4-40 thread nominal diameter
h2_dist = 6.4; // mm

bend_ri = 1.0; // mm
bend_ro = 1.7; // mm

$fn = 30;

translate([-width/2,0,0]) difference()
{
    difference()
    {
        union() {
            cube([width,thickness,height], center=false);
            cube([width,length,thickness], center=false);
            translate([0,thickness,thickness]) difference()
            {
                cube([width,bend_ri,bend_ri],center=false);
                translate([0,bend_ri,bend_ri]) rotate(90, [0,1,0]) cylinder(width, r=bend_ri);
            }
        }
        difference()
        {
            cube([width,thickness,thickness],center=false);
            translate([0,bend_ro,bend_ro]) rotate(90, [0,1,0]) cylinder(width, r=bend_ro);
        }
    }
    # translate([width/2,0.5*thickness,h1_dist ]) rotate(90, [1,0,0]) cylinder(2 * thickness, d=h1_dia,center=true);
    # translate([width/2,h2_dist,0.5*thickness]) cylinder(2 * thickness, d=h2_dia,center=true);
}
