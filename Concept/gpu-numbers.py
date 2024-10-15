#

import io
import re
import subprocess
import math

from dataclasses import dataclass
from collections import namedtuple
from pathlib import Path
from contextlib import contextmanager

###############################################################################
# Support
###############################################################################


MODELINE_PATTERN = re.compile(
    r'Modeline "(?P<name>.*)"\s+(?P<pclk_mhz>\d+\.?\d*)\s+(?P<hdisp>\d+)\s+(?P<hsyncstart>\d+)\s+(?P<hsyncend>\d+)\s*(?P<htotal>\d+)\s+(?P<vdisp>\d+)\s*(?P<vsyncstart>\d+)\s+(?P<vsyncend>\d+)\s+(?P<vtotal>\d+)',
    # re.MULTILINE,
)


@dataclass
class CVT:
    name: str

    pclk_mhz: float
    hdisp: int
    hsyncstart: int
    hsyncend: int
    htotal: int

    vdisp: int
    vsyncstart: int
    vsyncend: int
    vtotal: int

    @property
    def hfrontporch(self) -> int:
        return self.hsyncstart - self.hdisp

    @property
    def hsync(self) -> int:
        return self.hsyncend - self.hsyncstart

    @property
    def hbackporch(self) -> int:
        return self.htotal - self.hsyncend

    @property
    def hblank(self) -> int:
        return self.htotal - self.hdisp

    @property
    def vfrontporch(self) -> int:
        return self.vsyncstart - self.vdisp

    @property
    def vsync(self) -> int:
        return self.vsyncend - self.vsyncstart

    @property
    def vbackporch(self) -> int:
        return self.vtotal - self.vsyncend

    @property
    def vblank(self) -> int:
        return self.vtotal - self.vdisp

    def __post_init__(self):
        self.pclk_mhz = float(self.pclk_mhz)
        self.hdisp = int(self.hdisp)
        self.hsyncstart = int(self.hsyncstart)
        self.hsyncend = int(self.hsyncend)
        self.htotal = int(self.htotal)
        self.vdisp = int(self.vdisp)
        self.vsyncstart = int(self.vsyncstart)
        self.vsyncend = int(self.vsyncend)
        self.vtotal = int(self.vtotal)

    @staticmethod
    def get(w: int, h: int, f: float) -> "CVT":
        res = subprocess.run(
            args=["cvt", str(w), str(h), str(f)],
            capture_output=True,
            check=True,
            encoding="utf-8",
        )

        lines = [line for line in res.stdout.splitlines() if not line.startswith("#")]

        match = MODELINE_PATTERN.match(lines[0])

        return CVT(**match.groupdict())


class Svg:
    stream: io.TextIOBase
    padding: int

    def __init__(self, stream: io.TextIOBase, padding: int):
        self.stream = stream
        self.padding = padding

    def _attrs(self, **kwargs) -> str:
        s = ""

        if "fill" in kwargs:
            fill = kwargs["fill"]
            del kwargs["fill"]
            if fill is not None:
                s += f' fill="{fill}"'
            else:
                s += ' fill="none"'

        if "stroke" in kwargs:
            stroke = kwargs["stroke"]
            del kwargs["stroke"]
            if stroke is not None:
                s += f' stroke="{stroke}"'
            else:
                s += ' stroke="none"'

        for key, value in kwargs.items():
            s += f' {key.replace("_","-")}="'
            s += str(value)
            s += '"'

        return s

    def rect(
        self,
        pos: tuple[int, int],
        size: tuple[int, int],
        label: str | None = None,
        stroke: str | None = "black",
        fill: str | None = None,
        **kwargs,
    ):
        x, y = pos
        width, height = size

        x += self.padding
        y += self.padding

        self.stream.write(f'<rect x="{x}" y="{y}" width="{width}" height="{height}"')

        self.stream.write(self._attrs(stroke=stroke, fill=fill, **kwargs))

        self.stream.write(" />\n")

        label = (label or "").strip()
        if label != "":
            self.stream.write(
                f'<text x="{x+width//2}" y="{y+height/2}" dominant-baseline="middle" text-anchor="middle">{label}</text>\n'
            )

    def line(
        self,
        p1: tuple[int, int],
        p2: tuple[int, int],
        stroke: str | None = "black",
        **kwargs,
    ):
        x1, y1 = p1
        x2, y2 = p2

        x1 += self.padding
        y1 += self.padding
        x2 += self.padding
        y2 += self.padding

        self.stream.write(
            f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" {self._attrs(stroke=stroke,**kwargs)} />',
        )


@contextmanager
def svg_file(path: Path, width: int, height: int, padding: int | None = None):
    padding = padding or 0.1 * max(width, height)

    width += 2 * padding
    height += 2 * padding

    path = Path(path)
    with path.open("w", encoding="utf-8") as stream:
        svg = Svg(stream, padding)

        stream.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        stream.write(
            '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n'
        )
        stream.write(
            f'<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="{width}" height="{height}">\n'
        )
        yield svg

        stream.write("</svg>\n")


Unit = namedtuple(
    typename="Unit",
    field_names=("display", "numerator", "denumerator"),
)


results: list[tuple[str, str, int | float, str | None]] = list()


def set_result(scope: str, name: str, value: int | float, unit: str | Unit | None):
    if isinstance(unit, Unit):
        if unit.numerator != 1:
            value /= unit.numerator
        if unit.denumerator != 1:
            value *= unit.denumerator
        unit = unit.display
    results.append((scope + ":", name, value, unit))


def print_results():
    # results.sort(key=lambda tup: tup[0:2])

    col_sizes = [0, 0, 0, 0]
    col_just = [str.ljust, str.ljust, str.rjust, str.ljust]

    def merge(scope: str, name: str, value: int | float, unit: str | None):
        return f"{scope} {name} = {value} {unit}"

    def tostr(val):
        if isinstance(val, str):
            return val
        if isinstance(val, int):
            return f"{val}    "
        if isinstance(val, float):
            return f"{val:.3f}"
        assert False, str(type(val))

    for tup in results:
        for i, val in enumerate(tup):
            col_sizes[i] = max(col_sizes[i], len(tostr(val or "")))

    last_key = None
    for tup in results:
        if tup[0] != last_key:
            print()
            last_key = tup[0]
        print(
            merge(
                *(
                    just(tostr(val or ""), width)
                    for val, just, width in zip(tup, col_just, col_sizes)
                )
            )
        )
    print()


###############################################################################
# Units
###############################################################################


Mbps = Unit("Mbps", 1_000_000, 1)

Hz = Unit("Hz", 1, 1)
kHz = Unit("kHz", 1_000, 1)
MHz = Unit("MHz", 1_000_000, 1)

ms = Unit("ms", 1, 1_000)
µs = Unit("µs", 1, 1_000_000)
ns = Unit("ns", 1, 1_000_000_000)

bit = Unit("bit", 1, 1)
kb = Unit("kb", 1_000, 1)
Mb = Unit("Mb", 1_000_000, 1)

byte = Unit("byte", 1, 1)
kB = Unit("kB", 1_000, 1)
MB = Unit("MB", 1_000_000, 1)

###############################################################################
# Parameters
###############################################################################

# logical output
img_width = 800
img_height = 480
img_freq = 30  # Hz

pal_size = 256

# video output
vid_width = img_width
vid_height = img_height
vid_target_freq = 60  # Hz

# psram

psram_clk = 150_000_000  # Hz
psram_burst_overhead = 2 + 6 + 6  # clocks
psram_burstsize = 64  # byte ( 16 32 64 128)
psram_wordsize = 4  # bit

psram_count = 4

###############################################################################
# Computations
###############################################################################

img_time = 1 / img_freq

psram_bandwidth = psram_clk * psram_wordsize  # Mbps
psram_byteclks = 8 // psram_wordsize  # clk/byte
psram_burstclks = psram_burst_overhead + psram_burstsize * psram_byteclks  # clks
psram_burst_throughput = psram_clk / psram_burstclks
psram_burst_time = psram_burstclks / psram_clk
psram_bit_throughput = 8 * psram_burst_throughput * psram_burstsize

cvt = CVT.get(vid_width, vid_height, vid_target_freq)

vid_pixelclk = cvt.pclk_mhz * 1_000_000  # Hz
vid_line_freq = vid_pixelclk / cvt.htotal

vid_hline_total_time = cvt.htotal / vid_pixelclk
vid_hline_scanout_time = cvt.hdisp / vid_pixelclk

vid_freq = vid_line_freq / cvt.vtotal

vid_vimg_total_time = (cvt.vtotal * cvt.htotal) / vid_pixelclk
vid_vimg_scanout_time = vid_vimg_total_time * (cvt.vdisp / cvt.vtotal)
vid_vblank_time = vid_vimg_total_time - vid_vimg_scanout_time

pal_bits = int(math.ceil(math.log2(pal_size)))

img_pixels = img_width * img_height
img_byte_size = img_pixels * int(math.ceil(pal_bits / 8))
img_bit_size = img_pixels * pal_bits
img_hline_size = img_width * pal_bits


# we don't need to consider CVT here, we're just working on memory for any "img_"
img_hline_time = img_time / img_height


psram_img_transfer_time = img_bit_size / psram_bit_throughput
psram_hline_transfer_time = img_hline_size / psram_bit_throughput
psram_hline_burst_cnt = int(math.ceil(psram_hline_transfer_time / psram_burst_time))


def shared_compute(tag_name: str, hline_time, vscan_time):
    psram_bursts_per_hline = int(hline_time // psram_burst_time)
    psram_bursts_per_img = int(vscan_time // psram_burst_time)

    psram_hline_burst_leeway = psram_bursts_per_hline - psram_hline_burst_cnt
    psram_hline_mem_leeway = psram_burstsize * psram_hline_burst_leeway

    psram_vscan_burst_leeway = img_height * psram_hline_burst_leeway
    psram_vscan_mem_leeway = psram_burstsize * psram_vscan_burst_leeway
    psram_vscan_img_leeway = int(psram_vscan_mem_leeway // img_byte_size)

    psram_raw_burst_leeway = psram_bursts_per_img
    psram_raw_mem_leeway = psram_burstsize * psram_raw_burst_leeway
    psram_raw_img_leeway = int(psram_raw_mem_leeway // img_byte_size)

    assert psram_count >= 1
    rawc = psram_count - 1

    vram_vscan_burst_leeway = psram_vscan_burst_leeway + psram_raw_burst_leeway * rawc
    vram_vscan_mem_leeway = psram_burstsize * vram_vscan_burst_leeway
    vram_vscan_img_leeway = int(vram_vscan_mem_leeway // img_byte_size)

    tag = f"PSRAM {tag_name} VRAM"
    set_result(tag, "Burst / H-Line Time", psram_bursts_per_hline, None)
    set_result(tag, "Burst Leeway / H-Line", psram_hline_burst_leeway, None)
    set_result(tag, "Available Mem / H-Line", psram_hline_mem_leeway, byte)
    set_result(tag, "Burst / Video out", psram_vscan_burst_leeway, None)
    set_result(tag, "Mem / Video out", psram_vscan_mem_leeway, MB)
    set_result(tag, "Image Transfers / Video out", psram_vscan_img_leeway, None)

    tag = f"PSRAM {tag_name} User"
    set_result(tag, "Bursts / Video Out", psram_raw_burst_leeway, None)
    set_result(tag, "Mem / Video Out", psram_raw_mem_leeway, MB)
    set_result(tag, "Image Transfers / Video Out", psram_raw_img_leeway, None)

    tag = f"VRAM {tag_name}"
    set_result(tag, "Bursts / Video Out", vram_vscan_burst_leeway, None)
    set_result(tag, "Mem / H-Line", vram_vscan_burst_leeway, kB)
    set_result(tag, "Mem / Video Out", vram_vscan_mem_leeway, MB)
    set_result(tag, "Image Transfers / Video Out", vram_vscan_img_leeway, None)


shared_compute(
    "Video",
    hline_time=vid_hline_total_time,
    vscan_time=vid_vimg_total_time,
)

shared_compute(
    "Image",
    hline_time=img_hline_time,
    vscan_time=img_time,
)

###############################################################################
# Statistics
###############################################################################

set_result("CVT", "Pixel Clock", vid_pixelclk, MHz)

set_result("CVT", "H Total", cvt.htotal, None)
set_result("CVT", "H Active", cvt.hdisp, None)
set_result("CVT", "H Blank", cvt.hblank, None)
set_result("CVT", "H Frontporch", cvt.hfrontporch, None)
set_result("CVT", "H Sync", cvt.hsync, None)
set_result("CVT", "H Backporch", cvt.hbackporch, None)

set_result("CVT", "H Frequency", vid_line_freq, kHz)
set_result("CVT", "H Period", vid_hline_total_time, µs)

set_result("CVT", "V Total", cvt.vtotal, None)
set_result("CVT", "V Active", cvt.vdisp, None)
set_result("CVT", "V Blank", cvt.vblank, None)
set_result("CVT", "V Frontporch", cvt.vfrontporch, None)
set_result("CVT", "V Sync", cvt.vsync, None)
set_result("CVT", "V Backporch", cvt.vbackporch, None)

set_result("CVT", "V Frequency", vid_freq, Hz)
set_result("CVT", "V Period", vid_vimg_total_time, ms)
set_result("CVT", "V Active Time", vid_vimg_scanout_time, ms)
set_result("CVT", "V Blank Time", vid_vblank_time, ms)

set_result("PSRAM", "Bandwidth", psram_bandwidth, Mbps)
set_result("PSRAM", "Throughput", psram_bit_throughput, Mbps)
set_result("PSRAM", "Burst Time", psram_burst_time, µs)
set_result("PSRAM", "Byte Clocks", psram_byteclks, None)
set_result("PSRAM", "Burst Size", psram_burstsize, byte)
set_result("PSRAM", "Burst Clocks", psram_burstclks, None)

set_result("Image", "Width", img_width, None)
set_result("Image", "Height", img_height, None)
set_result("Image", "Pixel Count", img_pixels, None)
set_result("Image", "Memory Size", img_bit_size, Mb)
set_result("Image", "Frame Time", img_time, ms)
set_result("Image", "Scanline Time", img_hline_time, µs)

set_result("PSRAM", "Image Transfer", psram_img_transfer_time, ms)
set_result("PSRAM", "H-Line Burst Count", psram_hline_burst_cnt, None)


print_results()

scale = 100_000

with svg_file("timing.svg", scale * vid_vimg_total_time, 400, 50) as svg:
    # baseline
    svg.line(
        (0, 400),
        (scale * vid_vimg_total_time, 400),
    )
    svg.line((0, 0), (0, 400))
    svg.line((scale * vid_vimg_total_time, 0), (scale * vid_vimg_total_time, 400))

    block_start = 350

    def block(x: int, w: int, **kwargs):
        svg.rect(
            (scale * x, block_start),
            (scale * w, 40),
            **kwargs,
        )

    block(0, vid_vimg_scanout_time, label="Active")
    block(vid_vimg_scanout_time, vid_vblank_time, label="V-Blank")

    block_start -= 50

    t = 0
    for i in range(0, img_height):
        block(
            t,
            vid_hline_scanout_time,
            stroke_width=0.1,
        )

        t += vid_hline_total_time

    block_start -= 50
    block(
        t,
        vid_hline_scanout_time,
        stroke_width=0.1,
    )

    block_start -= 50
    t = 0
    for i in range(0, img_height):
        block(
            t,
            psram_hline_transfer_time,
            stroke_width=0.1,
        )

        t += vid_hline_total_time
