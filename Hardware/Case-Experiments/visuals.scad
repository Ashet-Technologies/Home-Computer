use <common.scad>
use <lib/ISOThreadUM2.scad>
use <lib/ScrewsMetric/ScrewsMetric/ScrewsMetric.scad>
use <models/models.scad>

// Variants:

USE_PI_VARIANT = false;
USE_SCENE = false;

WITH_COMPONENTS = true;
WITH_MODULES = true;
WITH_BACKFACE = true;
WITH_BACKPLANE =true;

WITH_MAIN_CASE = true;
WITH_ONLY_BOTTOM = true;

MOD_EXTRUSTION = false;


// Parameters:

$fn = 20;

fp_thick = 2;
fp_gap = 0.25;



// distance between slot edge and pcb bottom
mod_pcb_gap = 4; 

// dimensions of pcb
mod_pcb_width = 70;
mod_pcb_length = 145;
mod_pcb_height = 1.6;

// distance between slot edge and pcb top
mod_pcb_offset = mod_pcb_gap + mod_pcb_height;

// margins left/right of the pcb to the front panel
mod_fp_margin = 5;

// distance between case and pcb
mod_pcb_margin = 1;

// how far is the module screw center inset from the fp border?
mod_fp_screw_inset = 3.5;

// total size of a module
mod_width = 87;
mod_height = 28;

mod_count = 8;

backplane_pcb_dist = 3;
backplane_width = 240;
backplane_length = 83;

// total size of the case
case_width = 250; // 2 * mod_fp_margin + mod_width;
case_height = 101; // 2 * mod_fp_margin + mod_height * mod_count;
case_length = 180; //  // mod_length + backplane_height;
case_height_delta = -0.7;

// distance between the module frontplate and the case border
case_fp_margin = 5;

// Design

module case()
{
    mat_metal() cube([
        case_length,
        case_height,
        case_width,
    ]);

    // Feet:
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
    else if(WITH_COMPONENTS) {
        children();
    }
}

module frontplate_item(i, cutout)
{
    xrotate(-90) zrotate(-90) translate([(mod_width-mod_pcb_width)/2,0,mod_pcb_offset]) select_child(i) 
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
            d=17.5;
            component(cutout) translate([mod_pcb_width/2-3*d/2,0,0]) conn_usb_a_2_0_fem();
            component(cutout) translate([mod_pcb_width/2-d/2,0,0]) conn_usb_a_2_0_fem();
            component(cutout) translate([mod_pcb_width/2+d/2,0,0]) conn_usb_a_2_0_fem();
            component(cutout) translate([mod_pcb_width/2+3*d/2,0,0]) conn_usb_a_2_0_fem();
        }
        union() { // dual stereo audio
            // TODO: 4 * RCA
            component(cutout) translate([mod_pcb_width/2-25,fp_thick + 0.5,0]) conn_cinch_female();
            component(cutout) translate([mod_pcb_width/2-12,fp_thick + 0.5,0]) conn_cinch_female();
            component(cutout) translate([mod_pcb_width/2+12,fp_thick + 0.5,0]) conn_cinch_female();
            component(cutout) translate([mod_pcb_width/2+25,fp_thick + 0.5,0]) conn_cinch_female();
        }
        union() { // ulta video card
            component(cutout) translate([10,0,0]) conn_hdmi_fem();
            component(cutout) translate([39,0,0]) conn_sub_de_15_fem();
            component(cutout) translate([64,fp_thick + 0.5,0]) conn_cinch_female();
        }
        union() { // main board
            if(USE_PI_VARIANT)
            {
                component(cutout) translate([mod_pcb_width/2,0,-mod_pcb_height])  dev_rpi_4b();
            }
            else
            {
                component(cutout) translate([7,0,0]) conn_usb_c_fem();
                component(cutout) translate([48,0,0]) conn_usb_a_2_0_vert_fem();
                component(cutout) translate([30,0,0]) conn_rj45();
                component(cutout) translate([17,2.5,0]) conn_microswitch_2x_vert();
                // component(cutout) translate([mod_pcb_width-16,1.4,-4]) display_oled_128x64_0_96_in();
            }
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

    mat_metal() translate([-0.25,mod_height/2,mod_fp_screw_inset]) yrotate(-90) AllenBolt(2.5,7); // hex_bolt(2.5,4);
    mat_metal() translate([-0.25,mod_height/2,mod_width - mod_fp_screw_inset]) yrotate(-90) AllenBolt(2.5,7); // hex_bolt(2.5,4);

    mat_pcb() translate([fp_thick,mod_pcb_offset - mod_pcb_height,(mod_width - mod_pcb_width)/2]) cube([
        mod_pcb_length,
        mod_pcb_height,
        mod_pcb_width,
    ]);

    frontplate_item(i, false);
}

function mod_pos(i,f=0.0) = [ -fp_thick - i * f, (case_width - mod_height * mod_count) / 2 + mod_height * i, (case_height - mod_width) / 2 + case_height_delta ];

module ashet_home_computer()
{
    color("#d7d7d7") translate([83.75 + fp_thick,125,50]) zrotate(90) {
        if(WITH_MAIN_CASE) case_rm2095l(fp=false,bot=WITH_ONLY_BOTTOM);

        if(WITH_BACKFACE) case_rm2095l_fp();
    }

    color("#d7d7d7")
    // union() {
    difference() {
        translate([83.75 + fp_thick,125,50]) zrotate(270) case_rm2095l_fp();
        union()
        {
            for(i = [0:mod_count-1])
            {
                translate(mod_pos(i)+[-1,0,0]) {
                    translate([15,mod_height/2,mod_width/2]) cube([30,mod_height - 2 * mod_pcb_margin, mod_pcb_width + 2 * mod_pcb_margin], true);

                    translate([0,mod_height/2,0]) {
                        translate([0,0,mod_fp_screw_inset]) yrotate(-90) AllenBoltHole(2.5, 30,1); //  cylinder(h=30, r=2.5);
                        translate([0,0,mod_width-mod_fp_screw_inset]) yrotate(-90) AllenBoltHole(2.5, 30,1); //  cylinder(h=30, r=2.5);
                    }
                }
            }
        }
    }

    if(WITH_MODULES) for(i = [0:mod_count-1])
    {
        translate(mod_pos(i, MOD_EXTRUSTION ? 1.2 * mod_pcb_length / mod_count : 0.0)) {
            mod_fp(i);
        }
    }

    if(WITH_BACKPLANE)
    {
        translate([mod_pcb_length + backplane_pcb_dist + mod_pcb_height/2,case_width/2,case_height/2+case_height_delta]) {
            mat_pcb() cube([mod_pcb_height,backplane_width,backplane_length],true);

            translate([0,-(mod_height * mod_count)/2,0]) {

                if(WITH_MODULES) for(i = [0:mod_count-1])
                {
                    color("#222") translate([0,mod_height*i+mod_pcb_gap+mod_pcb_height/2,0]) zrotate(-90) xrotate(90) conn_pcie_x4();
                }
            }
        }
    }
}

if(USE_SCENE)
{

    // ground
    color("#d5b07c") translate([ 0, 0, -5 ]) cube([500,800,10], true); 

    // device:
    translate([case_length,-case_width/2,0]) yrotate(5) translate([-case_length,0,0])
    {
        ashet_home_computer();
    }


    // size references:
    translate([ -40, -45, 0 ]) dev_rpi_4b();
    translate([ 40, 210, 0 ]) zrotate(30) dev_ikea_vaerdera();


}
else
{
    translate([-case_length/2,-case_width/2,0]) ashet_home_computer();
}
