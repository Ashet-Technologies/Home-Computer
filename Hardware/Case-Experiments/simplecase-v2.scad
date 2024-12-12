use <common.scad>

model_mode="default";
metrics = false;

show_case_top = true;
show_case_bot = true;
show_case_left = true;
show_case_right = true;
show_case_back = true;

active_modules = 5; // [0:8]

// Slot Configuration:

slot_count = 8;        // how many slots does the design have?
slot_height = 30;      // mm, how much vertical space does a slot use?
slot_pcb_voffset = 10; // mm, vertical offset from bottom to pcb

// Module Connector Configuration:
conn_insert_depth = 7.5;   // mm, how deep can the PCB enter the connector?
conn_insert_width = 78.74; // mm, how wide is the pcb part of the connector
conn_total_height = 15.49; // mm, how long/tall is the connector from the pcb top

// Module PCB Configuration:

pcb_width = 100;  // mm, total width
pcb_length = 160; // mm, total length
pcb_thick = 1.6;  // mm, pcb material thickness

pcb_conn_width = 78.5; // s mm, width of the edge connector
pcb_conn_cutout = 9.0; // mm, length of the edge connector

// PCB Slider Configuration:

bar_slider_size = 5;              // mm, what's the square edge width?
bar_slider_sep = 1.1 * pcb_thick; // mm, how wide is the inset?
bar_slider_inset = 2.5;           // mm, how deep does the pcb insert into the slider?
bar_slider_screw_count = 4; 

// Backplane Configuration:

backplane_width = 100;                            // mm, width of backplane PCB
backplane_height = slot_height * slot_count - 10; // mm, height of backplace PCB

// Case Configuration:
panel_thick = 1.6; // mm, panel material thickness
strut_edge = 5;    // mm, what's the square edge width of a structural strut?

// Derived Values:

backplane_padding = 30;

backplane_pos = pcb_length + conn_total_height - conn_insert_depth + pcb_thick / 2;

case_height = slot_count * slot_height;                         // mm, inner height of the case
case_width = pcb_width- 2 * bar_slider_inset + 2 * strut_edge; // mm, inner width of the case
case_length = pcb_length + backplane_padding;

strut_width = pcb_width - 2 * bar_slider_inset; // length of a hstrut
strut_height = case_height;                     // length of a vstrut

/**
 * Debug
 */
module baseCube(tag, v)
{
    if(metrics)
    {
        echo(tag, v);
    }
    cube(v);
}

/**
 * Parts
 */

module conn_module_socket()
{
    import("c-5530843-7-f-3d.stl");
}

/**
 * Components
 */

//!
//! The component that will hold all PCBs in place.
//!
module pcb_guide()
{
    length = case_length - 2 * strut_edge;
    mat_brass() translate([ -bar_slider_size / 2, 0, 0 ]) difference()
    {
        baseCube("pcb_guide", [ bar_slider_size, length, bar_slider_size ]);

        // horizontal cut
        translate([ (bar_slider_size - bar_slider_sep) / 2, -bar_slider_sep, bar_slider_size - bar_slider_inset ])
            cube([ bar_slider_sep, pcb_length + 2 * bar_slider_sep, bar_slider_size ]);

        // vertical cut
        translate([ -bar_slider_size, backplane_pos - strut_edge - bar_slider_sep/2, bar_slider_size - bar_slider_inset ])
            cube([ 3*bar_slider_size, bar_slider_sep, bar_slider_size ]);

        hole_off = 10; // bar_slider_size / 2;
        hole_dist = (length - 2 * hole_off) / (bar_slider_screw_count - 1);
        for (i = [0:bar_slider_screw_count - 1])
        {
            $fs = 0.1;
            translate([ bar_slider_size / 2, hole_off + i * hole_dist, -1 ])
                cylinder(h = bar_slider_size - bar_slider_inset + 1, d = 2.5);
        }
    }
}

//!
//! The component that will provide vertical frame stability.
//!
module vstrut()
{
    mat_brass() difference()
    {
        baseCube("vstrut", [
            strut_edge,
            strut_edge,
            strut_height,
        ]);
        for (i = [0:slot_count - 1])
        {
            translate([
                bar_slider_size - bar_slider_inset, -strut_edge, slot_height * i - bar_slider_sep / 2 +
                slot_pcb_voffset
            ]) cube([ strut_edge + bar_slider_sep, 3 * strut_edge, bar_slider_sep ]);
        }
    }
}

//!
//! The component that will provide horizontal frame stability.
//!
module hstrut()
{
    mat_brass() baseCube("hstrut", [ strut_width, strut_edge, strut_edge ]);
}

//!
//! The side panel for left/right side.
//!
module sidepanel()
{
    mat_pcb() baseCube("sidepanel", [ panel_thick, case_length, case_height ]);
}

//!
//! The panel for top/bottom of the case.
//!
module toppanel()
{
    mat_pcb() baseCube("toppanel", [ case_width + 2 * panel_thick, case_length, panel_thick ]);
}

//!
//! The panel for back of the case.
//!
module backpanel()
{
    mat_pcb() baseCube("backpanel", [ case_width + 2 * panel_thick, panel_thick, case_height + 2 * panel_thick ]);
}

//!
//! The PCB which forms the backplane, including parts.
//!
module backplane()
{
    translate([ 0, -pcb_thick / 2, 0 ])
    {
        mat_pcb() baseCube("backplane", [ backplane_width, pcb_thick, backplane_height ]);

        for (i = [0:slot_count - 1])
        {
            translate([ backplane_width / 2, -conn_total_height, i * slot_height + slot_pcb_voffset ]) xrotate(90)
                conn_module_socket();
        }
    }
}

//!
//! Dummy PCB for a module.
//! TODO: Replace with export from KiCad
//!
module mod_pcb_dummy()
{
    cutout_width = (pcb_width - pcb_conn_width) / 2;
    mat_pcb() difference()
    {
        translate([ 0, 0, -pcb_thick / 2 ]) cube([ pcb_width, pcb_length, pcb_thick ]);

        translate([ -cutout_width, pcb_length - pcb_conn_cutout, -pcb_thick ])
            cube([ 2 * cutout_width, 2 * pcb_conn_cutout, 2 * pcb_thick ]);
        translate([ pcb_width - cutout_width, pcb_length - pcb_conn_cutout, -pcb_thick ])
            cube([ 2 * cutout_width, 2 * pcb_conn_cutout, 2 * pcb_thick ]);
    }
}

/**
 * Assemblies
 */

module case_assembly()
{
    // front frame
    translate([ 0, 0, 0 ]) vstrut();
    translate([ 2 * strut_edge + strut_width, strut_edge, 0 ]) zrotate(180) vstrut();

    translate([ strut_edge, 0, 0 ]) hstrut();
    translate([ strut_edge, 0, case_height - strut_edge ]) hstrut();

    // back frame
    translate([ 0, case_length - strut_edge, 0 ]) vstrut();
    translate([ 2 * strut_edge + strut_width, case_length, 0 ]) zrotate(180) vstrut();

    translate([ strut_edge, case_length - strut_edge, 0 ]) hstrut();
    translate([ strut_edge, case_length - strut_edge, case_height - strut_edge ]) hstrut();

    // pcb guides:
    for (i = [0:slot_count - 1])
    {
        // left slider
        translate([ 0, strut_edge, slot_height * i + slot_pcb_voffset ]) yrotate(90) pcb_guide();

        // right slider
        translate([ case_width, strut_edge, slot_height * i + slot_pcb_voffset ]) yrotate(-90) pcb_guide();
    }

    // backplane:
    translate([ (case_width - backplane_width) / 2, backplane_pos, 0 ]) backplane();

    // panels:
    translate([-panel_thick, 0, 0]) sidepanel();
    translate([case_width, 0, 0]) sidepanel();

    translate([ -panel_thick, 0, -panel_thick ]) toppanel();
    translate([ -panel_thick, 0, case_height ]) toppanel();

    translate([-panel_thick, case_length, -panel_thick]) backpanel();
}

module mod_assembly()
{
    translate([ 0, 0, 0 ]) mod_pcb_dummy();
}

module assembly()
{
    case_assembly();

    for (i = [0:slot_count - 1])
    {
        translate([ bar_slider_size - bar_slider_inset, 0, slot_height * i + slot_pcb_voffset ]) mod_assembly();
    }
}

if(model_mode == "vstrut")
{
    yrotate(-90) vstrut();
}
else if(model_mode == "hstrut")
{
    hstrut();
}
else if(model_mode == "pcb_guide")
{
    pcb_guide();
}
else if(model_mode == "sidepanel")
{
    sidepanel();
}
else if(model_mode == "toppanel")
{
    toppanel();
}
else if(model_mode == "backpanel")
{
    backpanel();
}
else if(model_mode == "backplane")
{
    backplane();
}
else 
{
    if(model_mode != "default") {
        echo(str("unknown mode: '", model_mode, "'"));
    }
    assembly();
}

// mod_pcb_dummy();
//  pcb_guide();

// struts:

// vstrut();
// hstrut();
// pcb_guide();

// panels:
// sidepanel();
// toppanel();
// backpanel();

