import re

PAT = re.compile(r"^#define QMI_(?P<reg>\w+)_(?P<suffix>[A-Z]+)\s+_u\((?P<val>\S+)\)$")

regs = {
    "DIRECT_CSR",
    "DIRECT_TX",
    "DIRECT_RX",
    "M0_TIMING",
    "M0_RCMD",
    "M0_WFMT",
    "M0_RFMT",
    "M0_WCMD",
    "M1_TIMING",
    "M1_RCMD",
    "M1_WFMT",
    "M1_RFMT",
    "M1_WCMD",
    "ATRANS0",
    "ATRANS1",
    "ATRANS2",
    "ATRANS3",
    "ATRANS4",
    "ATRANS5",
    "ATRANS6",
    "ATRANS7",
}

with open(
    "vendor/pico-sdk/src/rp2350/hardware_regs/include/hardware/regs/qmi.h"
) as file:
    prevreg = None
    for line in file:
        match = PAT.match(line)
        if match is not None:
            regname = match.group("reg")
            suffix = match.group("suffix")
            vals = match.group("val")
            if vals.startswith("0x"):
                val = int(vals[2:], 16)
            else:
                val = int(vals)

            reg: str = None
            field: str = None
            for x in regs:
                if regname == x:
                    reg = x
                    field = None
                if regname.startswith(x + "_"):
                    reg = x
                    field = regname[len(reg) + 1 :]
                    break
            assert reg is not None, regname

            # print(repr(reg), repr(suffix), val)
            if suffix == "LSB":
                if prevreg != reg:
                    print(f'print_reg("{reg}", QMI_{reg}_OFFSET, 0, 0);')
                    prevreg = reg

                if field is not None:
                    print(
                        f'print_reg("{re.sub(r".", " ",reg)}.{field}", QMI_{reg}_OFFSET, QMI_{regname}_BITS, QMI_{regname}_LSB);'
                    )
