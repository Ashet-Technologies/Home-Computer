
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

