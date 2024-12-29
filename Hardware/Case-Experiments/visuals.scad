use <common.scad>
use <lib/ISOThreadUM2.scad>
use <lib/ScrewsMetric/ScrewsMetric/ScrewsMetric.scad>
use <models/models.scad>

$fn = 20;

fp_thick = 2;
fp_gap = 0.25;

// distance between slot edge and pcb bottom
mod_pcb_gap = 4; 

// dimensions of pcb
mod_pcb_width = 80;
mod_pcb_length = 100;
mod_pcb_height = 1.6;

// distance between slot edge and pcb top
mod_pcb_offset = mod_pcb_gap + mod_pcb_height;

// margins left/right of the pcb to the front panel
mod_fp_margin = 5;

// total size of a module
mod_width = mod_pcb_width + 2 * mod_fp_margin;
mod_height = 30;
mod_length = 100;

mod_count = 8;

backplane_height = 30;

// distance between the module frontplate and the case border
case_fp_margin = 5;

// total size of the case
case_width = 2 * mod_fp_margin + mod_width;
case_height = 2 * mod_fp_margin + mod_height * mod_count;
case_length = mod_length + backplane_height;

module case()
{
    mat_metal() cube([
        case_length,
        case_height,
        case_width,
    ]);

    color("#333") for(x = [0:1])
    {
        for(y = [0:1])
        {
            translate([
                20 + x * (case_length - 40),
                20 + y * (case_height - 40),
                -9
            ]) cylinder(
                h = 9,
                r1 = 5,
                r2 = 7,
                center = false
            );
        }
    }
}



module select_child(i)
{
    children(i);
}

module component(cutout)
{
    if(cutout) {
        minkowski() {
            hull() intersection() {
                children();
                translate([-10,0,-50]) cube([
                    100,
                    fp_thick,
                    100,
                ]);
            }
            // sphere(1);
            cube([1,1,1],true);
        }
    }
    else {
        children();
    }
}

module frontplate_item(i, cutout)
{
    xrotate(-90) zrotate(-90) translate([mod_fp_margin,0,mod_pcb_offset]) select_child(i) 
    {
        union() { // pin header
            component(cutout) translate([mod_pcb_width/2,0,0]) conn_pinheader_12x2_90deg_border();
        }
        union() { // empty

        }
        union() { // c64 serial
            component(cutout) translate([mod_pcb_width/2-18,0,0]) conn_din_6pin_45322_fem();
            component(cutout) translate([mod_pcb_width/2+18,0,0]) conn_din_6pin_45322_fem();
        }
        union() { // dual rs232
            component(cutout) translate([mod_pcb_width/2-18,0,0]) conn_sub_de_9_male();
            component(cutout) translate([mod_pcb_width/2+18,0,0]) conn_sub_de_9_male();
        }
        union() { // 4-port usb
            component(cutout) translate([mod_pcb_width/2-27,0,0]) conn_usb_a_2_0_fem();
            component(cutout) translate([mod_pcb_width/2-9,0,0]) conn_usb_a_2_0_fem();
            component(cutout) translate([mod_pcb_width/2+9,0,0]) conn_usb_a_2_0_fem();
            component(cutout) translate([mod_pcb_width/2+27,0,0]) conn_usb_a_2_0_fem();
        }
        union() { // dual stereo audio
            // TODO: 4 * RCA
            component(cutout) translate([mod_pcb_width/2-30,fp_thick + 0.5,0]) conn_cinch_female();
            component(cutout) translate([mod_pcb_width/2-15,fp_thick + 0.5,0]) conn_cinch_female();
            component(cutout) translate([mod_pcb_width/2+15,fp_thick + 0.5,0]) conn_cinch_female();
            component(cutout) translate([mod_pcb_width/2+30,fp_thick + 0.5,0]) conn_cinch_female();
        }
        union() { // ulta video card
            component(cutout) translate([12,0,0]) conn_hdmi_fem();
            component(cutout) translate([mod_pcb_width/2,0,0]) conn_sub_de_15_fem();
            component(cutout) translate([mod_pcb_width-12,fp_thick + 0.5,0]) conn_cinch_female();
        }
        union() { // main board

            component(cutout) translate([7,0,0]) conn_usb_c_fem();
            component(cutout) translate([48,0,0]) conn_usb_a_2_0_vert_fem();
            component(cutout) translate([30,0,0]) conn_rj45();
            component(cutout) translate([17,2.5,0]) conn_microswitch_2x_vert();
            component(cutout) translate([mod_pcb_width-16,1.4,-4]) display_oled_128x64_0_96_in();
        }
    }
}

module mod_fp(i)
{
    mat_brass() difference() {
        translate([0,fp_gap,fp_gap]) cube([
            fp_thick,
            mod_height - 2 * fp_gap,
            mod_width - 2 * fp_gap,
        ]);
        frontplate_item(i, true);
    }

    mat_metal() translate([-0.25,mod_height/2,mod_fp_margin/2]) yrotate(-90) AllenBolt(2.5,7); // hex_bolt(2.5,4);
    mat_metal() translate([-0.25,mod_height/2,mod_width - mod_fp_margin/2]) yrotate(-90) AllenBolt(2.5,7); // hex_bolt(2.5,4);

    mat_pcb() translate([fp_thick,mod_pcb_offset - mod_pcb_height,(mod_width - mod_pcb_width)/2]) cube([
        mod_pcb_length,
        mod_pcb_height,
        mod_pcb_width,
    ]);

    frontplate_item(i, false);
}

// ground
color("#d5b07c") translate([ 0, 0, -5 ]) cube([500,800,10], true); 

translate([ 40, 210, 0 ]) zrotate(30) ikea_coffee_mug();

translate([case_length,-case_height/2,0])  yrotate(5) translate([-case_length,0,0])
{
    case();

    for(i = [0:mod_count-1])
    {
        translate([ -fp_thick, case_fp_margin + mod_height * i, case_fp_margin ]) {
            mod_fp(i);
        }
    }
}