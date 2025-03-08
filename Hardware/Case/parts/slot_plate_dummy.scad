use <slot_plate.scad>
use <../expansions.scad>
use <../lib/common.scad>
use <../lib/xcon.scad>

if (RENDER_PART_2D)
{
    xcon_slot_plate_2d() xcon_expansion_dummy(0);
}

if (RENDER_PART_3D)
{
    xcon_slot_plate() xcon_expansion_dummy(0);
}
