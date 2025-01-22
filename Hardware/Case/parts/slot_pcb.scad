include <parameters.scad>
use <../lib/common.scad>

module slot_pcb_2d()
{
    size = [ slot_pcb_height, slot_pcb_length ];


    square(size, true);

// PCIe x4 PCB Edge:
    w1 = 11.2;
    g1 = 1.9;
    w2 = 21.2;

    h1 = -7.9;
    h2 = -8.4;

    wtot = w1 + g1 + w2;

    translate([slot_pcb_conn_offset - wtot/2,-slot_pcb_length/2]) {
        polygon([
            [0,0],
            [0,h1],
            [0.5,h2],
            [w1-0.5,h2],
            [w1,h1],
            [w1,0]
        ]);

        translate([w1+g1,0]) polygon([
            [0,0],
            [0,h1],
            [0.5,h2],
            [w2-0.5,h2],
            [w2,h1],
            [w2,0]
        ]);
    }
}

module slot_pcb()
{
    yrotate(90) linear_extrude(height = slot_pcb_thickness, center = true) slot_pcb_2d();
}

if (RENDER_PART_2D)
{
    slot_pcb_2d();
}

if (RENDER_PART_3D)
{
    slot_pcb();
}