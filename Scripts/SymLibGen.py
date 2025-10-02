#!/usr/bin/env python
"""
This script consumes a YAML file and generates a uniformly looking and
well attributed KiCAD symbol library.

We use this to be portable between different versions as well as allowing
a really nice uniform look and feel to our schematics.
"""

from pathlib import Path
import sys
import textwrap
from dataclasses import dataclass, field
from argparse import ArgumentParser, Namespace
from enum import Enum
from typing import Any, ClassVar, Iterable, Optional, TextIO
import re

import yaml


class Edge(Enum):
    TOP = "T"
    BOTTOM = "B"
    LEFT = "L"
    RIGHT = "R"


class Position:
    """
    Represents a pin position on a symbol, like T1, B3, L5, R2.
    Validates that the position string matches the format [TBLR]\\d+.
    """

    _pattern: ClassVar[re.Pattern] = re.compile(r"^(?P<position>[TBLR])(?P<index>\d+)$")

    _edge: Edge
    _offset: int

    def __init__(self, value):
        if not isinstance(value, str):
            raise ValueError(
                f"Invalid position format: '{value}'. Must match '[TBLR]\\d+'."
            )
        params = self._pattern.match(value)
        if not params:
            raise ValueError(
                f"Invalid position format: '{value}'. Must match '[TBLR]\\d+'."
            )

        self._edge = Edge(params.group("position"))
        self._offset = int(params.group("index"))
        if self._offset == 0:
            raise ValueError("A position must start at 1")

    @property
    def edge(self) -> Edge:
        return self._edge

    @property
    def offset(self) -> int:
        return self._offset

    @property
    def is_horizontal(self) -> bool:
        match self.edge:
            case Edge.LEFT | Edge.RIGHT:
                return False
            case Edge.TOP | Edge.BOTTOM:
                return True

    @property
    def is_vertical(self) -> bool:
        match self.edge:
            case Edge.LEFT | Edge.RIGHT:
                return True
            case Edge.TOP | Edge.BOTTOM:
                return False

    def __repr__(self) -> str:
        return f"{self._edge.value}{self._offset}"


class PinType(Enum):
    """Enumeration for the different types of pins."""

    LOGIC_INPUT = "logic-input"
    LOGIC_OUTPUT = "logic-output"
    LOGIC_INOUT = "logic-inout"
    LOGIC_TRISTATE = "logic-tristate"
    POWER_INPUT = "power-input"
    POWER_OUTPUT = "power-output"
    PASSIVE = "passive"
    FREE = "free"
    UNSPECIFIED = "unspecified"
    OPEN_COLLECTOR = "open-collector"
    OPEN_EMITTER = "open-emitter"
    UNCONNECTED = "unconnected"


class PinStyle(Enum):
    LINE = "regular"
    INVERTED = "inverted"
    CLOCK = "clock"
    INVERTED_CLOCK = "inverted-clock"
    EDGE_CLOCK_HIGH = "edge-clock-high"
    INPUT_LOW = "input-low"
    OUTPUT_LOW = "output-low"
    NON_LOGIC = "non-logic"


@dataclass
class Pin:
    """Represents a single pin on a symbol's abstract representation."""

    name: str
    type: PinType
    position: Position
    style: PinStyle = field(default=PinStyle.LINE)

    def __repr__(self) -> str:
        return f"Pin({self.name!r}, {self.type.value!r}, {self.position})"


@dataclass
class DistributorInfo:
    """Contains information about a part from a specific distributor."""

    url: str
    partno: str


@dataclass
class Footprint:
    "Represents a single footprint which can be used by multiple symbols"


@dataclass
class Graphic:
    name: str
    pins: frozenset[str]
    code: str


@dataclass
class Variant:
    """Represents a specific variant of a symbol, e.g., a particular package."""

    name: str
    pinout: dict[str, Pin | None]
    distributors: dict[str, DistributorInfo]
    footprint: Optional[Footprint | str] = None  # The value is a comment in the YAML
    graphic: Optional[Graphic] = None


@dataclass
class Symbol:
    """Represents a single schematic symbol with its pins and variants."""

    name: str
    description: str
    pinout: dict[str, Pin]
    variants: dict[str, Variant]
    width: Optional[int] = field(default=None)
    height: Optional[int] = field(default=None)
    ref: str = field(default="U")


@dataclass
class SymbolLibrary:
    """Represents the entire symbol library file."""

    symbols: dict[str, Symbol] = field(default_factory=dict)
    footprints: dict[str, Footprint] = field(default_factory=dict)
    graphics: dict[str, Graphic] = field(default_factory=dict)


def main() -> int:
    args = _parse_cli_args()

    # print("library_path", args.library_path)
    # print("output", args.output)

    symbol_lib = _load_symbol_lib(args.library_path)

    # print("symbol_lib", symbol_lib)

    if args.output is not None:
        with open(args.output, "w", encoding="utf-8") as fp:
            _render_symbol_lib(fp, symbol_lib.symbols.values())
    else:
        _render_symbol_lib(sys.stdout, symbol_lib.symbols.values())

    return 0


def _parse_cli_args() -> Namespace:
    parser = ArgumentParser()

    parser.add_argument("--output", "-o", type=Path)

    parser.add_argument("library_path", type=Path)

    return parser.parse_args()


def _load_symbol_lib(lib_path: Path) -> SymbolLibrary:
    data: dict[str, Any]
    with open(lib_path, "r") as fp:
        data = yaml.safe_load(fp)

    graphics: dict[str, Graphic] = dict()
    symbols: dict[str, Symbol] = dict()
    footprints: dict[str, Footprint] = dict()

    for gr_key, gr_val in data.get("graphics", dict()).items():
        assert gr_key not in graphics

        graphics[gr_key] = Graphic(
            name=gr_key,
            code=gr_val["code"],
            pins=frozenset(str(x) for x in gr_val["pins"]),
        )

    for fp_key, fp_val in data.get("footprints", dict()).items():
        pass

    for sym_key, sym_val in data.get("symbols", dict()).items():
        assert sym_key not in symbols

        pinout = {
            pin_id: Pin(
                name=pin_id,
                type=PinType(pin_val["type"]),
                position=Position(
                    pin_val["position"],
                ),
                style=PinStyle(pin_val.get("style", PinStyle.LINE.value)),
            )
            for pin_id, pin_val in sym_val["pinout"].items()
        }

        variants = {
            name: Variant(
                name=name,
                footprint=v["footprint"],
                pinout={
                    str(pin_id): pinout[pin_val] if pin_val is not None else None
                    for pin_id, pin_val in v["pinout"].items()
                },
                distributors={
                    dist_id: DistributorInfo(**dist_val)
                    for dist_id, dist_val in v["distributors"].items()
                },
                graphic=graphics[ref]
                if (ref := v.get("graphic", None)) is not None
                else None,
            )
            for name, v in sym_val["variants"].items()
        }

        symbols[sym_key] = Symbol(
            name=sym_key,
            description=sym_val["description"],
            ref=sym_val.get("ref", "U"),
            pinout=pinout,
            variants=variants,
            width=sym_val.get("width", None),
            height=sym_val.get("height", None),
        )

    return SymbolLibrary(
        symbols=symbols,
        footprints=footprints,
    )


_PIN_TYPE_TO_KICAD: dict[PinType, str] = {
    PinType.LOGIC_INPUT: "input",
    PinType.LOGIC_OUTPUT: "output",
    PinType.LOGIC_INOUT: "bidirectional",
    PinType.LOGIC_TRISTATE: "tri_state",
    PinType.POWER_INPUT: "power_in",
    PinType.POWER_OUTPUT: "power_out",
    PinType.PASSIVE: "passive",
    PinType.FREE: "free",
    PinType.UNSPECIFIED: "unspecified",
    PinType.OPEN_COLLECTOR: "open_collector",
    PinType.OPEN_EMITTER: "open_emitter",
    PinType.UNCONNECTED: "no_connect",
}

_PIN_STYLE_TO_KICAD: dict[PinStyle, str] = {
    PinStyle.CLOCK: "clock",
    PinStyle.EDGE_CLOCK_HIGH: "edge_clock_high",
    PinStyle.INPUT_LOW: "input_low",
    PinStyle.INVERTED: "inverted",
    PinStyle.INVERTED_CLOCK: "inverted_clock",
    PinStyle.LINE: "line",
    PinStyle.NON_LOGIC: "non_logic",
    PinStyle.OUTPUT_LOW: "output_low",
}


def _render_symbol_lib(stream: TextIO, symbols: Iterable[Symbol]) -> None:
    def add_property(
        name: str,
        value: str,
        x: float = 0.0,
        y: float = 0.0,
        halign: str = "center",
        valign: str = "center",
    ) -> None:
        stream.write(f'\t\t(property "{name}" "{value}"\n')
        stream.write(f"\t\t\t(at {x} {y} 0)\n")
        stream.write("\t\t\t(effects\n")
        stream.write("\t\t\t\t(font\n")
        stream.write("\t\t\t\t\t(size 1.27 1.27)\n")
        stream.write("\t\t\t\t)\n")
        if halign != "center" or valign != "center":
            stream.write(f"\t\t\t\t(justify {halign} {valign})\n")
        stream.write("\t\t\t)\n")

        stream.write("\t\t)\n")

    grid_size = 2.54
    pin_length = 2.54

    stream.write("(kicad_symbol_lib\n")
    stream.write("\t(version 20241209)\n")
    stream.write('\t(generator "SymLibGen.py")\n')
    stream.write('\t(generator_version "1.0")\n')
    for symbol in symbols:
        slot_w = 1
        slot_h = 1
        for pin in symbol.pinout.values():
            if pin.position.is_horizontal:
                slot_w = max(slot_w, pin.position.offset)
            else:
                slot_h = max(slot_h, pin.position.offset)

        if symbol.width is not None:
            slot_w = symbol.width
        if symbol.height is not None:
            slot_h = symbol.height

        def x(pos: int) -> float:
            return grid_size * (pos - (slot_w + 1) / 2)

        def y(pos: int) -> float:
            return -grid_size * (pos - (slot_h + 1) / 2)

        def pos(p: Position) -> tuple[float, float, int]:
            match p.edge:
                case Edge.LEFT:
                    return x(0) - pin_length, y(p.offset), 0
                case Edge.RIGHT:
                    return x(slot_w + 1) + pin_length, y(p.offset), 180
                case Edge.TOP:
                    return x(p.offset), y(0) + pin_length, 270
                case Edge.BOTTOM:
                    return x(p.offset), y(slot_h + 1) - pin_length, 90

        for variant in sorted(symbol.variants.values(), key=lambda v: v.name):
            stream.write(f'\t(symbol "{variant.name}"\n')
            stream.write("\t\t(exclude_from_sim no)\n")
            stream.write("\t\t(in_bom yes)\n")
            stream.write("\t\t(on_board yes)\n")

            add_property(
                "Reference",
                symbol.ref,
                x(slot_w + 1),
                x(slot_h + 1),
                halign="right",
                valign="bottom",
            )
            add_property("Value", variant.name)
            add_property("Footprint", "")
            add_property("Datasheet", "")
            add_property("Description", "")

            stream.write(f'\t\t(symbol "{variant.name}_1_1"\n')

            if variant.graphic is not None:
                stream.write(textwrap.indent(variant.graphic.code, "\t\t"))
            else:
                stream.write("\t\t\t(rectangle\n")
                stream.write(f"\t\t\t\t(start {x(0)} {y(0)})\n")
                stream.write(f"\t\t\t\t(end {x(slot_w + 1)} {y(slot_h + 1)})\n")
                stream.write("\t\t\t\t(stroke\n")
                stream.write("\t\t\t\t\t(width 0)\n")
                stream.write("\t\t\t\t\t(type solid)\n")
                stream.write("\t\t\t\t)\n")
                stream.write("\t\t\t\t(fill\n")
                stream.write("\t\t\t\t\t(type background)\n")
                stream.write("\t\t\t\t)\n")
                stream.write("\t\t\t)\n")

                for pin_number, pin in variant.pinout.items():
                    if pin is None:
                        continue

                    px, py, rot = pos(pin.position)
                    ptype = _PIN_TYPE_TO_KICAD[pin.type]
                    pstyle = _PIN_STYLE_TO_KICAD[pin.style]

                    stream.write(f"\t\t\t(pin {ptype} {pstyle}\n")
                    stream.write(f"\t\t\t\t(at {px} {py} {rot})\n")
                    stream.write(f"\t\t\t\t(length {pin_length})\n")
                    stream.write(f'\t\t\t\t(name "{pin.name}"\n')
                    stream.write("\t\t\t\t\t(effects\n")
                    stream.write("\t\t\t\t\t\t(font\n")
                    stream.write("\t\t\t\t\t\t\t(size 0.762 0.762)\n")
                    stream.write("\t\t\t\t\t\t)\n")
                    stream.write("\t\t\t\t\t)\n")
                    stream.write("\t\t\t\t)\n")
                    stream.write(f'\t\t\t\t(number "{pin_number}"\n')
                    stream.write("\t\t\t\t\t(effects\n")
                    stream.write("\t\t\t\t\t\t(font\n")
                    stream.write("\t\t\t\t\t\t\t(size 1.016 1.016)\n")
                    stream.write("\t\t\t\t\t\t)\n")
                    stream.write("\t\t\t\t\t)\n")
                    stream.write("\t\t\t\t)\n")
                    stream.write("\t\t\t)\n")

                    # break

            stream.write("\t\t)\n")

            stream.write("\t\t(embedded_fonts no)\n")
            stream.write("\t)\n")

    stream.write(")\n")


if __name__ == "__main__":
    sys.exit(main())
