use <common.scad>
use <lib/ISOThreadUM2.scad>
use <lib/ScrewsMetric/ScrewsMetric/ScrewsMetric.scad>

$fn = 20;

fp_thick = 2;
fp_gap = 0.25;

mod_pcb_width = 80;
mod_pcb_length = 100;

mod_fp_margin = 5;

mod_width = mod_pcb_width + mod_fp_margin;
mod_height = 30;
mod_length = 100;

mod_count = 8;

backplane_height = 30;

case_fp_margin = 5;

case_width = 2 * mod_fp_margin + mod_width;
case_height = 2 * mod_fp_margin + mod_height * mod_count;
case_length = mod_length + backplane_height;

module case()
{
    cube([
        case_length,
        case_height,
        case_width,
    ]);
}

module mod_fp()
{
    mat_brass() translate([0,fp_gap,fp_gap]) cube([
        fp_thick,
        mod_height - 2 * fp_gap,
        mod_width - 2 * fp_gap,
    ]);

    mat_metal() translate([-0.25,mod_height/2,mod_fp_margin/2]) yrotate(-90) AllenBolt(2.5,7); // hex_bolt(2.5,4);
    mat_metal() translate([-0.25,mod_height/2,mod_width - mod_fp_margin/2]) yrotate(-90) AllenBolt(2.5,7); // hex_bolt(2.5,4);
}

mat_metal() case();

for(i = [0:mod_count-1])
{
    translate([ -fp_thick, case_fp_margin + mod_height * i, case_fp_margin ]) mod_fp();
}



