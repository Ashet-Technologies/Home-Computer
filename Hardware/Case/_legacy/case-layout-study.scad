//

pcb_width = 100;  // mm
pcb_length = 160; // mm

pcb_thick = 1.6;  // mm
case_thick = 1.0; // mm

slot_width = pcb_width + 2 * case_thick; // mm
slot_length = pcb_length + 6;            // mm
slot_height = 30;                        // mm
slot_pcb_voffset = 5;                    // mm
slot_slider_width = 3;                   // mm
slot_slider_height = 3;                  // mm
slot_slider_margin = 0.05;               // mm
slot_strut_count = 4;
slot_strut_width = 2; // mm

slot_conn_cx = 20;
slot_conn_cy = 2;
slot_conn_spc = 2.54; // mm
slot_conn_height = 5; // mm

slot_padding = 2; // mm
slot_count = 8;

case_backplane_space = 5; // mm
case_base_height = 5;     // mm
case_base_dia = 10;       // mm
case_base_margin = 10;    // mm

mod_cover_padding = 0.5; // mm

inside_slice_perc = 100;
mod_extrusion = 0;
total_height = 265;

module mat_metal()
{
    color("#CCCCCC") children();
}

module mat_gold()
{
    color("#F4C75E") children();
}

module mat_pcb()
{
    color("#008000") children();
}

module mat_component()
{
    color("#404040") children();
}

module mat_plastic()
{
    color("#BDA897") children();
}

module expansion_slot()
{
    // Side Walls
    mat_plastic()
    {

        cube([ case_thick, slot_length, slot_height ]);
        translate([ slot_width - case_thick, 0, 0 ]) cube([ case_thick, slot_length, slot_height ]);

        for (i = [0:slot_strut_count - 1])
        {
            dy = (slot_length - slot_strut_width) * i / (slot_strut_count - 1);
            translate([ 0, dy, 0 ]) cube([ slot_width, slot_strut_width, case_thick ]);
            translate([ 0, dy, slot_height - case_thick ]) cube([ slot_width, slot_strut_width, case_thick ]);
        }

        // PCB Sockets
        translate([ 0, 0, slot_pcb_voffset ])
        {
            difference()
            {
                union()
                {
                    translate([ 0, 0, -slot_slider_height / 2 ]) cube(
                        [ slot_slider_width, pcb_length + (slot_slider_height - pcb_thick) / 2, slot_slider_height ]);
                    translate([ slot_width - case_thick - slot_slider_width, 0, -slot_slider_height / 2 ]) cube(
                        [ slot_slider_width, pcb_length + (slot_slider_height - pcb_thick) / 2, slot_slider_height ]);
                }
                translate([ slot_width / 2 - slot_slider_margin / 2, pcb_length / 2 - slot_slider_margin / 2, 0 ]) cube(
                    [ pcb_width + slot_slider_margin, pcb_length + slot_slider_margin, pcb_thick + slot_slider_margin ],
                    center = true);
            }
        }
    }
}

module slot_interface()
{
    cw = (slot_conn_cx + 0.5) * slot_conn_spc;
    ch = (slot_conn_cy + 0.5) * slot_conn_spc;
    mat_component() translate([ (slot_width - cw) / 2, -slot_conn_height, slot_pcb_voffset - ch / 2 ])
        cube([ cw, slot_conn_height, ch ]);
}

module backplane()
{
    h = slot_height * slot_count + slot_padding * (slot_count - 1);

    mat_pcb() cube([ slot_width, pcb_thick, h ]);

    for (i = [0:slot_count - 1])
    {
        translate([ 0, 0, i * (slot_height + slot_padding) ]) slot_interface();
    }
}

module casing()
{
    h = slot_height * slot_count + slot_padding * (slot_count - 1);
    l = slot_length + case_backplane_space;

    mat_metal() translate([ -case_thick, -case_thick, -case_thick ]) difference()
    {
        cube([ slot_width + 2 * case_thick, l + 2 * case_thick, h + 2 * case_thick ]);
        translate([ case_thick, -1, case_thick ]) cube([ slot_width, l + 1, h ]);
    }
}

module case_assembly()
{
    casing();

    translate([ 0, slot_length + 1, 0 ]) backplane();

    for (i = [0:slot_count - 1])
    {
        translate([ 0, 0, i * (slot_height + slot_padding) ]) expansion_slot();
    }
}

module expansion_mod()
{
    dx = (slot_width - pcb_width) / 2;
    translate([ dx, 0, 0 ])
    {
        mat_pcb() translate([ pcb_width / 2, pcb_length / 2, 0 ])
            cube([ pcb_width, pcb_length, pcb_thick ], center = true);
        mat_metal() translate([ -dx + mod_cover_padding, -case_thick, -slot_pcb_voffset + mod_cover_padding ])
            cube([ slot_width - 2 * mod_cover_padding, case_thick, slot_height - 2 * mod_cover_padding ]);
    };

    cw = (slot_conn_cx - 1) * slot_conn_spc;
    ch = (slot_conn_cy - 1) * slot_conn_spc;

    mat_gold() translate([ (slot_width - cw) / 2, pcb_length - 2, -ch / 2 ])
    {
        for (ix = [0:slot_conn_cx - 1])
        {
            for (iy = [0:slot_conn_cy - 1])
            {
                translate([ slot_conn_spc * ix, 0, slot_conn_spc * iy ]) rotate(-90, [ 1, 0, 0 ])
                    cylinder(h = 5, d = 0.5);
            }
        }
    }
}

module full_assembly()
{
    translate([ 0, 0, case_base_height + case_thick ])
    {
        case_assembly();
        for (i = [0:slot_count - 1])
        {
            translate([ 0, -mod_extrusion, i * (slot_height + slot_padding) + slot_pcb_voffset ]) expansion_mod();
        }
    }

    mat_component()
    {
        translate([ case_base_margin, case_base_margin, 0 ]) cylinder(h = case_base_height, d = case_base_dia);
        translate([ slot_width - case_base_margin, case_base_margin, 0 ])
            cylinder(h = case_base_height, d = case_base_dia);

        translate([ case_base_margin, slot_length + case_backplane_space - case_base_margin, 0 ])
            cylinder(h = case_base_height, d = case_base_dia);
        translate([ slot_width - case_base_margin, slot_length + case_backplane_space - case_base_margin, 0 ])
            cylinder(h = case_base_height, d = case_base_dia);
    }
}

module ikea_coffee_mug()
{
    $fs = 0.1;
    $fa = 10;
    hs1 = 30;
    hs2 = 75;
    db = 50;
    ds = 65;
    dt = 80;
    t = 2;

    hw = 15;
    hd = 60;
    ht = 5;
    hvo = 35;

    difference()
    {
        union()
        {
            cylinder(h = hs1, d1 = db, d2 = ds);
            translate([ 0, 0, hs1 ]) cylinder(h = hs2, d1 = ds, d2 = dt);

            // handle:
            translate([ -hw / 2, -40, hvo + hd / 2 ]) rotate(5, [ 1, 0, 0 ]) rotate(90, [ 0, 1, 0 ])
                scale([ 1, 0.5, 1 ]) difference()
            {
                cylinder(h = hw, d = hd);
                translate([ 0, 0, -hw ]) cylinder(h = 3 * hw, d = hd - 2 * ht);
            }
        }
        translate([ 0, 0, t ]) cylinder(h = hs1 - t + 0.01, d1 = db - 2 * t, d2 = ds - 2 * t);
        translate([ 0, 0, hs1 - 0.001 ]) cylinder(h = hs2 + t + 0.01, d1 = ds - 2 * t, d2 = dt - 2 * t);
    }
}

// expansion_slot();
//  expansion_mod();

difference()
{
    full_assembly();

    translate([ -50, -50, inside_slice_perc * total_height / 100 ]) cube([ 400, 400, 400 ]);
}

translate([ -80, 80, 0 ]) ikea_coffee_mug();