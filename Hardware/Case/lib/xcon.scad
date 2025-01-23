
use <common.scad>
use <../models/models.scad>

module xcon_cutout()
{
    let($cutout_mode=true) children();
}
module xcon_model()
{
    let($cutout_mode=false) children();
} 

module xcon_rs232()
{
    if($cutout_mode) {
        wb=8.5;
        wt=10.5;
        b=1;
        t=12;
        polygon([
            [-wb,b],
            [-wt,t],
            [wt,t],
            [wb,b],
        ]);
        xmirror() translate([12.5,6.4]) circle(d=4,$fn=20);
    }
    else {
        translate([0,0.6,0]) conn_sub_de_9_male();
    }
}

module xcon_vga()
{
    if($cutout_mode) {
        wb=8.5;
        wt=10.5;
        b=1;
        t=12;
        polygon([
            [-wb,b],
            [-wt,t],
            [wt,t],
            [wb,b],
        ]);
        xmirror() translate([12.6,6.4]) circle(d=3,$fn=20);
    }
    else {
        translate([0,0.6,0]) conn_sub_de_15_fem();
    }
}

module xcon_cinch()
{
    if($cutout_mode) {
        translate([0,6.6]) circle(d=10);
    }
    else {
        translate([0,2,0]) conn_cinch_female();
    }
}

module xcon_usb_c()
{
    if($cutout_mode) {
        hull() {
            xmirror() translate([3,1.9]) circle(d=3.5,$fn=20);
        }
    }
    else {
        translate([-0.1,0.5,0]) conn_usb_c_fem();
    }
}

module xcon_usb_a()
{
    if($cutout_mode) {
        translate([0,3.5])  square([13.5,6],true);
    }
    else {
        translate([0,-0.3,0])conn_usb_a_2_0_fem();
    }
}


module xcon_usb_av()
{
    if($cutout_mode) {
        translate([0,7.5])  square([6,13.5],true);
    }
    else {
        translate([3.5,-0.5,0]) conn_usb_a_2_0_vert_fem();
    }
}




module xcon_pinheader_12x2()
{
    if($cutout_mode) {
        translate([0,4.5]) square([38.5,9],true);
    }
    else {
        translate([0,-0.5,0]) conn_pinheader_12x2_90deg_border();
    }
}

module xcon_din6()
{
    if($cutout_mode) {
        translate([0,10.5]) square([21.5,21.5],true);
    }
    else {
        translate([0,-0.5,0]) conn_din_6pin_45322_fem();
    }
}



module xcon_ms_x2()
{
    if($cutout_mode) {
        translate([0,6.9]) circle(d=3.5,$fn=20);
        translate([0,2.9]) circle(d=3.5,$fn=20);
    }
    else {
        translate([0,1.5,0]) conn_microswitch_2x_vert();
    }
}

module xcon_pi4()
{
    if($cutout_mode) {
        translate([-1,10]) square([14,15],true);
        translate([-19,10]) square([14,15],true);
        translate([17.7,8.5]) square([16.5,14],true);
    }
    else {
        translate([0,2.5,0]) dev_rpi_4b();
    }
}


module xcon_rj45()
{
    if($cutout_mode) {
        translate([0,6.5]) square([17,14],true);
    }
    else {
        conn_rj45();
    }
}

module xcon_hdmi()
{
    
    if($cutout_mode) {
        w1 = 6;
        w2 = 7.6;
        b0 = 0.4;
        b1 = 2;
        b2 = 6.2;
        polygon([
            [-w1, b0],
            [-w2, b1],
            [-w2, b2],
            [w2, b2],
            [w2, b1],
            [w1, b0],
        ]);
    }
    else {
        translate([0.2,-0.5,0]) conn_hdmi_fem();
    }
}


