#!/usr/bin/env python3

import sys
import yaml

from dataclasses import dataclass, field

from typing import Any

VAT = 1.19


def main():
    bom_data: dict[str, Any]
    with open("bom.yml") as fp:
        bom_data = yaml.safe_load(fp)

    batchsizes: list[int] = bom_data["batchsizes"]
    assembly_raw: dict[str, int] = bom_data["assembly"]
    boards_raw: dict[str, dict[str, int]] = bom_data["boards"]
    parts_raw: dict[str, dict[str, Any]] = bom_data["parts"]

    parts: dict[str, Part] = {
        name: Part.from_yaml(name, value) for name, value in parts_raw.items()
    }

    boards: dict[str, Board] = {
        name: Board.from_yaml(name, value, parts) for name, value in boards_raw.items()
    }

    assembly: list[(Board, int)] = [
        (boards[name], quant) for name, quant in assembly_raw.items()
    ]

    stream = sys.stdout

    stream.write("Board,Count")
    for j, batch_quant in enumerate(batchsizes):
        stream.write(f",{batch_quant}")
    stream.write("\n")

    stream.write("-------------,------")
    for j, batch_quant in enumerate(batchsizes):
        stream.write(",------")
    stream.write("\n")

    total_part_quant: dict[Part, int] = {}
    for board, brd_quant in assembly:
        for part, part_quant in board.parts.items():
            total_part_quant[part] = (
                total_part_quant.get(part, 0) + brd_quant * part_quant
            )

    # print("\n".join(f"{brd.name}: {cnt}" for brd, cnt in sorted(total_part_quant.items())))

    total_cost = [0] * len(batchsizes)

    for board, brd_quant in assembly:
        stream.write(f"{board.name},{brd_quant}")

        for j, batch_quant in enumerate(batchsizes):
            cost = 0

            for part, part_quant in board.parts.items():
                cost_for_one = part.get_cost(batch_quant * total_part_quant[part])

                # print("[",board.name, part.name, batch_quant, part_quant, cost_for_one,"]")

                cost += batch_quant * part_quant * cost_for_one

            total_cost[j] += brd_quant * cost
            stream.write(f",{cost / batch_quant:.2f}")

        stream.write("\n")

    stream.write("-------------,------")
    for j, batch_quant in enumerate(batchsizes):
        stream.write(",------")
    stream.write("\n")

    stream.write("Netto,")
    for j, batch_quant in enumerate(batchsizes):
        stream.write(f",{total_cost[j] / batch_quant:.2f}")
    stream.write("\n")

    stream.write("Brutto,")
    for j, batch_quant in enumerate(batchsizes):
        stream.write(f",{VAT * total_cost[j] / batch_quant:.2f}")
    stream.write("\n")

    stream.write("Price Level,")
    for j, batch_quant in enumerate(batchsizes):
        stream.write(
            f",{100*(total_cost[j] / batchsizes[j]) / (total_cost[0] / batchsizes[0]):.2f}%"
        )
    stream.write("\n")


@dataclass(frozen=True)
class Part:
    name: str
    desc: str
    cost: list[tuple[int, float]]

    @classmethod
    def from_yaml(cls, name: str, data: dict[str, Any]) -> "Part":
        summed = data["cost"].get("summed", False)
        part = Part(
            name=name,
            desc=data["desc"],
            cost=sorted(
                (quant, price / quant if summed else price)
                for quant, price in data["cost"].items()
                if isinstance(quant, int)
            ),
        )
        if part.cost[0][0] != 1:
            # monkey-patch the smallest batch size
            part.cost.insert(0, (1, part.cost[0][1]))
        return part

    def get_cost(self, quant: int) -> float:
        assert self.cost[0][0] == 1
        for minq, cost in reversed(self.cost):
            if minq <= quant:
                return cost

        return self.cost[-1][1]

    def __hash__(self) -> int:
        return id(self)

    def __lt__(self, other: "Part") -> bool:
        return self.name < other.name


@dataclass(frozen=True)
class Board:
    name: str
    parts: dict[Part, int]

    @classmethod
    def from_yaml(
        cls, name: str, data: dict[str, Any], parts: dict[str, Part]
    ) -> "Board":
        return Board(
            name=name, parts={parts[name]: quant for name, quant in data.items()}
        )

    def __hash__(self) -> int:
        return id(self)

    def __lt__(self, other: "Board") -> int:
        a = self.name.startswith("E_")
        b = other.startswith("E_")
        if a != b:
            return a < b
        return self.name < other.name


if __name__ == "__main__":
    sys.exit(main() or 0)
