#!/usr/bin/python3

import sys
import json

from argparse import ArgumentParser
from pathlib import Path
from dataclasses import dataclass
from typing import Any, Callable, Generic, TypeVar

T = TypeVar("T")

ROOT = Path(__file__).absolute().parents[1]


def main() -> int:
    parser = ArgumentParser()
    parser.add_argument(
        "--vendor-db", type=Path, default=ROOT / "Specs" / "Expansion Vendors.md"
    )
    parser.add_argument(
        "--card-db", type=Path, default=ROOT / "Specs" / "Expansion Cards.md"
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=False,
    )

    parser.add_argument("vendor", type=int)
    parser.add_argument("product", type=int)
    parser.add_argument("serial", type=str)

    args = parser.parse_args()

    vendor_db_path: Path = args.vendor_db
    card_db_path: Path = args.card_db
    output_path: Path|None  = args.output
    vendor_id: int = args.vendor
    product_id: int = args.product
    serial_no: str = args.serial

    if not vendor_db_path.is_file():
        print(f"{vendor_db_path} does not exist")
        return 1
    if not card_db_path.is_file():
        print(f"{card_db_path} does not exist")
        return 1

    vendor_db = load_table_file(vendor_db_path, Vendor)
    card_db = load_table_file(card_db_path, Product)

    for card in card_db:
        _ = vendor_db.get_by_pk(card.vendor_id)

    vendor = vendor_db.get_by_pk(vendor_id)
    product = card_db.get_by_pk(product_id)

    descriptor: dict[str, Any] = {
        "Vendor ID": vendor_id,
        "Product ID": product_id,
        "Vendor Name": vendor.name,
        "Product Name": product.name,
        "Serial Number": serial_no,
        "Properties": {
            "Requires Audio": product.requires_audio,
            "Requires Video": product.requires_video,
            "Requires USB": product.requires_usb,
        },
        "Driver Interface": "none",  # TODO: Implement this?
    }

    json_text: str = json.dumps(
        obj=descriptor,
        ensure_ascii=False,
        indent=2,
    ) + "\n"

    if output_path is None:
        sys.stdout.write(json_text)
    else:
        with output_path.open("w", encoding='utf-8') as stream:
            stream.write(json_text)

    return 0


def parse_bool(val: str) -> bool:
    match val.lower():
        case "yes" | "on" | "true":
            return True
        case "no" | "off" | "false":
            return False
        case _:
            raise TypeError(f"Expected boolean value, but got {val!r}")


@dataclass
class TableCell:
    name: str
    type: type | Callable[[str], str | int | bool]


@dataclass
class Vendor:
    __cells__ = (
        TableCell("Vendor ID", int),
        TableCell("Vendor Name", str),
        TableCell("Contact", str),
    )

    id: int
    name: str
    contact: str


@dataclass
class Product:
    __cells__ = (
        TableCell("Vendor ID", int),
        TableCell("Product ID", int),
        TableCell("Product Name", str),
        TableCell("Requires Audio", parse_bool),
        TableCell("Requires Video", parse_bool),
        TableCell("Requires USB", parse_bool),
    )

    vendor_id: int
    id: int
    name: str
    requires_audio: bool
    requires_video: bool
    requires_usb: bool


class Table(Generic[T], list[T]):
    _pk_lut: dict[int, T]

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)
        self._pk_lut = dict()

    def get_by_pk(self, pk: int) -> T:
        return self._pk_lut[pk]

    def append(self, item: T) -> None:
        assert item.id not in self._pk_lut
        self._pk_lut[item.id] = item
        super().append(item)


def load_table_file(path: Path, ItemType: type[T]) -> Table[T]:
    assert hasattr(ItemType, "__cells__")

    fields: dict[str, int] = dict()
    for index, cell in enumerate(ItemType.__cells__):
        fields[cell.name] = index

    with path.open("r", encoding="utf-8") as fp:
        headline: tuple[TableCell, ...] | None = None
        skip_next = False

        rows: Table[T] = Table()

        for line in fp:
            line = line.strip()
            assert line.startswith("|") and line.endswith("|"), repr(line)

            cells = tuple(part.strip() for part in line[1:-1].split("|"))

            if skip_next:
                skip_next = False
                continue

            if headline is None:
                headline = tuple(ItemType.__cells__[fields[cell]] for cell in cells)
                skip_next = True
                continue

            assert len(cells) == len(headline), (
                f"{len(cells)} != {len(headline)}: {cells!r}"
            )

            fields: dict[str, int | str | bool] = dict()

            for field, value in zip(headline, cells):
                fields[field.name] = field.type(value)

            row = ItemType(*(fields[field.name] for field in ItemType.__cells__))

            rows.append(row)

        return rows


if __name__ == "__main__":
    sys.exit(main())
