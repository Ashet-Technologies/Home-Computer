use <common.scad>

show_case_top = true;
show_case_bot = true;
show_case_left = true;
show_case_right = true;
show_case_back = true;

active_modules = 5; // [0:8]

slot_count = 8;
slot_height = 30; // mm

pcb_width = 100;  // mm
pcb_length = 160; // mm

pcb_thick = 1.6;  // mm
case_thick = 1.0; // mm

case_width = pcb_width + 2 * case_thick;
case_length = pcb_length + 20 + 2 * case_thick;
case_height = slot_height * slot_count + 2 * case_thick;

bar_corner_size = 8;               // mm
bar_slider_size = 5;               // mm
bar_slider_sep = pcb_thick + 0.25; // mm

conn_insert_depth = 7.5;   // mm
conn_insert_width = 78.74; // mm
conn_total_height = 15.49; // mm
pcb_len_cutoff = 10.0;     // mm

backplane_margin = 2; // mm

module con_video()
{
    import("c-5-5530843-0-f-3d.stl");
}

module con_audio()
{
    import("c-7-5530843-5-f-3d.stl");
}

module con_standard()
{
    import("c-5530843-4-f-3d.stl");
}

module con_unified()
{
    // import("c-5530843-6-f-3d.stl");
    import("c-5530843-7-f-3d.stl");
}

module bar_corner()
{
    mat_gold() cube([ bar_corner_size, case_length - 2 * case_thick, bar_corner_size ]);
}

module bar_vcorner()
{
    mat_gold() cube([ bar_corner_size, bar_corner_size, slot_height * slot_count - 2 * bar_corner_size ]);
}

module bar_slider()
{
    mat_gold() cube([ bar_slider_size, pcb_length - pcb_len_cutoff, bar_slider_size ]);
}

module pcb_eurocard()
{
    mat_pcb() translate([ 0, 0, -pcb_thick / 2 ]) cube([ pcb_width, pcb_length, pcb_thick ]);
}

translate([ -80, 80, 0 ]) ikea_coffee_mug();

module case()
{
    // sides
    if(show_case_left) mat_metal() cube([ case_thick, case_length, case_height ]);
    if(show_case_right) mat_metal() translate([ case_width - case_thick, 0, 0 ]) cube([ case_thick, case_length, case_height ]);
    
    // back
    if(show_case_back) mat_metal() translate([ case_thick, case_length - case_thick, 0 ]) cube([ case_width - 2 * case_thick, case_thick, case_height ]);

    // bottom
    if(show_case_bot) mat_metal() translate([ case_thick, case_thick, 0 ]) cube([ case_width - 2 * case_thick, case_length - 2 * case_thick, case_thick ]);
    
    // top
    if(show_case_top) mat_metal() translate([ case_thick, case_thick, case_height - case_thick ]) cube([ case_width - 2 * case_thick, case_length - 2 * case_thick, case_thick ]);
}


module interior()
{
    bar_corner();
    translate([ case_width - 2 * case_thick - bar_corner_size, 0, 0 ]) bar_corner();

    translate([ 0, 0, case_height - 2 * case_thick - bar_corner_size ])
    {
        bar_corner();
        translate([ case_width - 2 * case_thick - bar_corner_size, 0, 0 ]) bar_corner();
        ;
    }

    for (i = [0:slot_count - 1])
{
    translate([ 0, 0, bar_corner_size - bar_slider_size + slot_height * i ])
    {
        bar_slider();
        translate([ case_width - 2 * case_thick - bar_slider_size, 0, 0 ]) bar_slider();
    }
    translate([ 0, 0, bar_corner_size + bar_slider_sep + slot_height * i ])
    {
        bar_slider();
        translate([ case_width - 2 * case_thick - bar_slider_size, 0, 0 ]) bar_slider();
    }
}

// vertical backplane mount bars:
translate([ 0, pcb_length - conn_insert_depth + conn_total_height - bar_corner_size, bar_corner_size ]) bar_vcorner();
translate([
    case_width - 2 * case_thick - bar_corner_size, pcb_length - conn_insert_depth + conn_total_height - bar_corner_size,
    bar_corner_size
]) bar_vcorner();
}

module slot()
{
    // lift to pcb center level
    translate([ 0, 0, bar_corner_size + bar_slider_sep / 2 ])
    {
        difference()
        {
            pcb_eurocard();

            esize = (pcb_width - conn_insert_width) / 2;
            translate([ -esize, pcb_length - pcb_len_cutoff, -pcb_thick ])
                cube([ 2 * esize, 2 * conn_insert_depth, 2 * pcb_thick ]);
            translate([ pcb_width - esize, pcb_length - pcb_len_cutoff, -pcb_thick ])
                cube([ 2 * esize, 2 * conn_insert_depth, 2 * pcb_thick ]);
        }
    }
}

module backplane()
{
    mat_pcb() difference()
    {
        cube([ pcb_width - 2 * backplane_margin, pcb_thick, slot_height * slot_count - 2 * backplane_margin ]);
        // TODO: Cut out corners
        // cube([bar_corner_size+backplane_margin,bar_corner_size+backplane_margin,pcb_thick * 2]);
    }

    for (i = [0:slot_count - 1])
    {
        translate([ 0, 0, slot_height * i ]) translate([
            pcb_width / 2 - backplane_margin, -conn_total_height, bar_corner_size + bar_slider_sep / 2 -
            backplane_margin
        ]) rotate(90, [ 1, 0, 0 ]) con_unified();
    }
}

translate([ -case_thick, -case_thick, -case_thick ]) case();

interior();

for (i = [0:active_modules - 1])
{
    translate([ 0, 0, slot_height * i ]) slot();
}

// backplane
translate([ backplane_margin, pcb_length - conn_insert_depth + conn_total_height, backplane_margin ]) backplane();