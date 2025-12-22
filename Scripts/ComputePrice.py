import math
import os
import json
from pathlib import Path
from typing import Any
import kicad_sch_api as ksa
from kicad_sch_api.core.types import SchematicSymbol

from DigiKey import DigiKey

part_db_path = Path("Scripts/part-db.json")

part_db: dict[str, Any] = json.loads(part_db_path.read_text("utf-8"))

digikey = DigiKey()


def get_part_info(part_id: str) -> dict[str, Any]:
    part = part_db.get(part_id)
    if part is not None:
        return part

    part = {}

    digikey_data = digikey.product_details(part_id)
    try:
        part["distributors"] = {
            "DigiKey": digikey_data["Product"],
        }
    except KeyError:
        print(repr(part_id), json.dumps(digikey_data, indent=2))

        raise

    part_db[part_id] = part

    Path.write_text(part_db_path, json.dumps(part_db, indent=2, ensure_ascii=False))

    return part


path = Path("Hardware/Backplane/Backplane.kicad_sch")

sch = ksa.load_schematic(path)
print(sch)

tree = sch.hierarchy.build_hierarchy_tree(sch, path)

flattened = sch.hierarchy.flatten_hierarchy(prefix_references=True)
# print(flattened)


def get_prop(props: dict[str, str], key: str) -> str | None:
    value = props.get(key)
    if value is None:
        return None
    if isinstance(value, dict):
        value = value.get("value")
    assert isinstance(value, str), type(value)
    return value


missing: set[tuple[str, str]] = set()

shopping_list: dict[str, int] = dict()
seen_refs: set[str] = set()

for comp in flattened["components"]:
    sym: SchematicSymbol = comp["original_data"]
    assert isinstance(sym, SchematicSymbol)

    if not sym.in_bom:
        continue
    if sym.lib_id.startswith("power:"):
        continue

    props: dict[str, str] = sym.properties

    reference = get_prop(props, "Reference")
    value = get_prop(props, "Value")
    footprint = get_prop(props, "Footprint")
    datasheet = get_prop(props, "Datasheet")
    description = get_prop(props, "Description")
    digikey_part_no = get_prop(props, "Digikey Part No")

    if reference in seen_refs :
        continue 
    seen_refs.add(reference)

    print(reference)
    print(f" lib id:          {sym.lib_id!r}")
    print(f" value:           {value!r}")
    print(f" footprint:       {footprint!r}")
    print(f" datasheet:       {datasheet!r}")
    print(f" description:     {description!r}")
    print(f" digikey_part_no: {digikey_part_no!r}")

    if digikey_part_no is None or len(digikey_part_no) == 0:
        missing.add((sym.lib_id, value))
    else:
        if digikey_part_no == "149-P2X8C4M64P-ND":
            print("HERE")
        shopping_list[digikey_part_no] = shopping_list.get(digikey_part_no, 0) + 1

for item in sorted(missing):
    print(item)


def compute_price(product: dict[str, Any], count: int) -> tuple[int, float]:
    DIGIREEL_ID = 243

    distrs = product["distributors"]

    digikey = distrs.get("DigiKey")
    if digikey is not None:
        variations = digikey["ProductVariations"]

        def get_price(pkg: dict[str, Any], pricing: dict[str, Any]) -> tuple[int, float]:
            "Computes the price in 'numbers of break quantity items'"

            # min_quant: int = pkg["MinimumOrderQuantity"]
            mult_size: int = pkg["StandardPackage"]

            bq: int = pricing["BreakQuantity"]
            units: int = math.ceil(count / bq)

            if mult_size != 0:
                return units * bq, units * pricing["TotalPrice"]

            return count, count * pricing["UnitPrice"]

        best_pricing: tuple[int, float] | None = None
        for variant in variations:
            if variant["PackageType"]["Id"] == DIGIREEL_ID:
                continue

            pricing: list = variant["StandardPricing"]
            pricing.sort(key=lambda d: d["BreakQuantity"])

            assert len(pricing) >= 1

            selected_pricing = pricing[0]
            for option in pricing[1:]:
                if option["BreakQuantity"] < count:
                    selected_pricing = option

            current = get_price(variant, selected_pricing)
            if best_pricing is not None:
                if current[1] < best_pricing[1]:
                    best_pricing = current
            else:
                best_pricing = current

        assert best_pricing is not None
        return best_pricing

    raise ValueError("No distributor for part!")


scaling = 1000

total = 0

for partno, quant in sorted(shopping_list.items()):
    part = get_part_info(partno)

    use_count = scaling * quant

    buy_count, price = compute_price(part, use_count)

    print(f"{price:7.2f} €, {use_count:4}x, {buy_count:4}x {partno}")
    total += price

print(f"{total:7.2f} €,       -- TOTAL --")
print(f"{total / scaling:7.2f} €,       -- PER BOARD --")
