
use <models.scad>


module preview()
{
    color("red") cube([0.25,100,0.25],true);
    children();
}

translate([-100,-50,-3]) color("#cccccc") cube([1000,100,3]); 
translate([-100,0,0]) color("blue") cube([1000,50,0.1]); 



translate([0,0,0])   preview() conn_sub_de_9_fem();
translate([40,0,0])  preview() conn_sub_de_9_male();
translate([80,0,0])  preview() conn_sub_de_15_fem();
translate([110,0,0]) preview() conn_usb_a_2_0_fem();
translate([130,0,0]) preview() conn_usb_c_fem();
translate([150,0,0]) preview() conn_hdmi_fem();
translate([180,0,0]) preview() conn_dvi_fem();
translate([210,0,0]) preview() conn_jack_3_5mm_fem();
