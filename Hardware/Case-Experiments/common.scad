
module mat_metal()
{
    color("#CCCCCC") children();
}

module mat_gold()
{
    color("#F4C75E") children();
}

module mat_brass()
{
    color("#B5A642") children();
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

module xrotate(a)
{
    rotate(a, v=[1,0,0]) children();
}

module yrotate(a)
{
    rotate(a, v=[0,1,0]) children();
}

module zrotate(a)
{
    rotate(a, v=[0,0,1]) children();
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
