
H_SLOTS_CNT = 4;
V_SLOTS_CNT = 2;

MOD_WIDTH = 100; // mm
MOD_LENGTH = 160; // mm
MOD_HEIGHT = 20; // mm
MOD_VOFFSET = 5; // mm
MOD_BACK_HEIGHT = 10; // mm

SLOT_WIDTH = 110; // mm, total width of a slot
SLOT_MARGIN = 1; // mm, overlap over the PCB
SLOT_LENGTH = 170; // mm
SLOT_HEIGHT = 30; // mm
SLOT_VOFFSET = 13; // mm
SLOT_FRAME_PADDING = 1.5; // mm
SLOT_FRAME_THICK = 1; // mm
SLOT_FLAP_SIZE = 10; // mm
SLOT_FLAP_THICK = 1; // mm
SLOT_FLAP_MARGIN = 10; // mm
SLOT_MOUNT_PADDING = 4; // mm
SLOT_BACKFRAME_HEIGHT = 10; // mm
SLOT_PADDING = 2; // mm

BACKPLANE_WIDTH = H_SLOTS_CNT * SLOT_WIDTH + (H_SLOTS_CNT - 1) * SLOT_PADDING;
BACKPLANE_HEIGHT = V_SLOTS_CNT * SLOT_HEIGHT + (V_SLOTS_CNT - 1) * SLOT_PADDING;

CASE_PADDING = 0.5; // mm

PCB_HEIGHT = 0.9; // mm
METAL_THICK = 0.5; // mm

M3_THD = 3.4; // mm, through hole for M6
M4_THD = 4.5; // mm, through hole for M6
M5_THD = 5.5; // mm, through hole for M6

GAP = 0.1; // mm

MOD_SLIDE = 0; // mm


module expansion()
{
    color("#008000") translate([-MOD_WIDTH/2, -GAP ,-PCB_HEIGHT/2]) cube([MOD_WIDTH,MOD_LENGTH,PCB_HEIGHT]);
    color("#cccccc") translate([-MOD_WIDTH/2,-METAL_THICK - GAP,-MOD_VOFFSET]) cube([MOD_WIDTH,METAL_THICK,MOD_HEIGHT]);
}

module half_slot()
{
    union()
    {
        // Slider
        translate([ -SLOT_WIDTH / 2, 0, -(2*SLOT_MARGIN + PCB_HEIGHT) / 2 ]) cube([
            (SLOT_WIDTH - MOD_WIDTH) / 2 + SLOT_MARGIN, 
            SLOT_LENGTH,
            2 * SLOT_MARGIN + PCB_HEIGHT
        ]);
    }
}

module slot()
{
    difference()
    {
        union() {
            half_slot();
            mirror(v=[1,0,0]) half_slot();
            
            difference()
            {
                union()
                {
                    // front plate
                    translate([-SLOT_WIDTH / 2, 0, -SLOT_VOFFSET ]) cube([SLOT_WIDTH, SLOT_FRAME_THICK, SLOT_HEIGHT]);
                    
                    // back plate
                    translate([-SLOT_WIDTH / 2, SLOT_LENGTH - SLOT_FRAME_THICK, -SLOT_VOFFSET ]) cube([SLOT_WIDTH, SLOT_FRAME_THICK, SLOT_VOFFSET + SLOT_BACKFRAME_HEIGHT]);
                }
                // module plate hole
                translate([-MOD_WIDTH / 2 + SLOT_FRAME_PADDING, -SLOT_FRAME_THICK, -MOD_VOFFSET + SLOT_FRAME_PADDING]) cube([MOD_WIDTH - 2 * SLOT_FRAME_PADDING, 3 * SLOT_FRAME_THICK, MOD_HEIGHT - 2 * SLOT_FRAME_PADDING]);
                
                // module back slot
                translate([-MOD_WIDTH / 2 + SLOT_FRAME_PADDING, SLOT_LENGTH - 2*SLOT_FRAME_THICK, -MOD_BACK_HEIGHT/2 + SLOT_FRAME_PADDING]) cube([MOD_WIDTH - 2 * SLOT_FRAME_PADDING, 3 * SLOT_FRAME_THICK, MOD_BACK_HEIGHT - 2 * SLOT_FRAME_PADDING]);
                
                // mounting holes:
                translate([SLOT_WIDTH/2 - SLOT_MOUNT_PADDING,-SLOT_FRAME_THICK,SLOT_MOUNT_PADDING-SLOT_VOFFSET]) rotate(90,[-1,0,0]) cylinder(h=SLOT_LENGTH + 3*SLOT_FLAP_THICK,d=M3_THD,$fs=0.5);
                translate([-SLOT_WIDTH/2 + SLOT_MOUNT_PADDING,-SLOT_FRAME_THICK,SLOT_MOUNT_PADDING-SLOT_VOFFSET]) rotate(90,[-1,0,0]) cylinder(h=SLOT_LENGTH + 3*SLOT_FRAME_THICK,d=M3_THD,$fs=0.5);
            }
        }
        translate([-MOD_WIDTH/2, -GAP ,-PCB_HEIGHT/2]) cube([MOD_WIDTH,SLOT_LENGTH - SLOT_FRAME_THICK + GAP,PCB_HEIGHT]);
    }
}

module all_slots()
{    
    for(ix = [0:H_SLOTS_CNT-1])
    {
        for(iy = [0:V_SLOTS_CNT-1])
        {
            if (ix != 0 || iy != 0) {
                translate([ix*(SLOT_WIDTH + SLOT_PADDING ) + SLOT_WIDTH / 2,0,iy*(SLOT_HEIGHT + SLOT_PADDING) + SLOT_VOFFSET]) children();
            }
        }
    }
}

// backplane:

color("#008000") translate([0,SLOT_LENGTH,0]) cube([BACKPLANE_WIDTH, PCB_HEIGHT, BACKPLANE_HEIGHT]);

// module slots:
all_slots() {
    slot();
    translate([0,-MOD_SLIDE,0]) expansion();
    translate([-2.54 * 10, SLOT_LENGTH - 5, -2.54 * 1]) color("#000000") cube([2.54 * 20, 5, 2.54 * 2]);
    
};


// bottom case:

difference()
{
    color("#cccccc") translate([-1,-1,-1]) cube( [ BACKPLANE_WIDTH + 2, SLOT_LENGTH + PCB_HEIGHT + 5 + 2, BACKPLANE_HEIGHT + 2]  );
    color("#cccccc") cube( [ BACKPLANE_WIDTH, SLOT_LENGTH + PCB_HEIGHT + 5, BACKPLANE_HEIGHT+ 8]  );
    all_slots() {
        translate([-MOD_WIDTH/2 - CASE_PADDING, -20 * METAL_THICK ,-MOD_VOFFSET - CASE_PADDING]) cube([MOD_WIDTH+2*CASE_PADDING,40*METAL_THICK,MOD_HEIGHT+2*CASE_PADDING]);
    }
}