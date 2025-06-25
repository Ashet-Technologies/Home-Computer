include <parameters.scad>
use <../lib/common.scad>

module pcb_slider_body_2d() {
  size = [slot_pcb_height, slot_pcb_length];

  h = pcb_slider_height;
  hi = pcb_slider_depth; // TODO
  wot = pcb_slider_width_top / 2;
  wob = pcb_slider_width_bot / 2;
  wit = pcb_slider_notch_width_top / 2;
  wib = pcb_slider_notch_width_bot / 2;

  polygon(
    points=[
      [-wob, 0],
      [-wot, h],
      [wot, h],
      [wob, 0],
    ]
  );
}

module pcb_slider_notch_2d() {
  size = [slot_pcb_height, slot_pcb_length];

  h = pcb_slider_height;
  hi = pcb_slider_depth; // TODO
  wot = pcb_slider_width_top / 2;
  wob = pcb_slider_width_bot / 2;
  wit = pcb_slider_notch_width_top / 2;
  wib = pcb_slider_notch_width_bot / 2;

  polygon(
    points=[
      [-2 * wit, 2 * h],
      [-wib, hi],
      [wib, hi],
      [2 * wit, 2 * h],
    ]
  );
}

module pcb_slider() {
  tdist = pcb_slider_length - 2 * pcb_slider_hole_margin;
  hdist = tdist / (pcb_slider_holes - 1);

  render() difference() {
      xrotate(90) linear_extrude(height=pcb_slider_length, center=true) pcb_slider_body_2d();

      union() {
        xrotate(90) linear_extrude(height=2 * pcb_slider_length, center=true) pcb_slider_notch_2d();

        for ($i = [0:pcb_slider_holes - 1]) {
          off = hdist * $i - (pcb_slider_length / 2 - pcb_slider_hole_margin);

          translate([0, off, -1]) linear_extrude(height=pcb_slider_depth) screw_shaft_2d(pcb_slider_hole_screw);
        }

        ymirror() {
          translate([0, pcb_slider_length / 2 - pcb_slider_bevel_len, 0]) xrotate(-pcb_slider_bevel_angle)
              xrotate(90) yrotate(180) linear_extrude(height=3 * pcb_slider_bevel_len, center=true) pcb_slider_notch_2d();
        }
      }
    }
}

if (RENDER_PART_2D) {
    difference() {
        pcb_slider_body_2d();
        pcb_slider_notch_2d();
    }
}

if (RENDER_PART_3D) {
  pcb_slider();
}
