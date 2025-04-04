include <parameters.scad>
use <../lib/common.scad>

module pcb_slider_2d()
{
    size = [ slot_pcb_height, slot_pcb_length ];

    h = pcb_slider_height;
    hi = pcb_slider_depth; // TODO
    wot = pcb_slider_width_top / 2;
    wob = pcb_slider_width_bot / 2;
    wit = pcb_slider_notch_width_top / 2;
    wib = pcb_slider_notch_width_bot / 2;

    polygon(points=[
        [-wob,0],
        [-wot,h],
        [-wit,h],
        [-wib,hi],
        [wib,hi],
        [wit,h],
        [wot,h],
        [wob,0],
    ]);
}

module pcb_slider()
{   
    tdist = pcb_slider_length - 2 * pcb_slider_hole_margin;
    hdist = tdist / (pcb_slider_holes-1);
    
    render() difference() 
    {
        xrotate(90) linear_extrude(height = pcb_slider_length, center=true) pcb_slider_2d();
        union() for($i = [0: pcb_slider_holes-1]) {
            off = hdist * $i -(pcb_slider_length/2 - pcb_slider_hole_margin);

            translate([0,off,-1]) linear_extrude(height=pcb_slider_depth) screw_shaft_2d(pcb_slider_hole_screw);
        }   

    }
}

if (RENDER_PART_2D)
{
    pcb_slider_2d();
}

if (RENDER_PART_3D)
{
    pcb_slider();
}
