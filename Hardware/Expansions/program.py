#!/usr/bin/env python3

import sys 

from os import stat_result

from argparse import ArgumentParser
from pathlib import Path 

LEGAL_DISK_SIZES: frozenset[int] = frozenset((4096, 8192, 16384))

def main() -> int:

    parser = ArgumentParser()
    parser.add_argument("image", type=Path)
    parser.add_argument("--disk", type=Path, default=Path("/dev/sda"), required=False)

    args = parser.parse_args()

    image_path: Path = args.image
    disk_path :Path = args.disk

    image: bytes = image_path.read_bytes()

    sys_dir: Path = Path("/sys/class/block/") / disk_path.name
    assert sys_dir.is_dir(), f"{sys_dir.as_posix()!r} is not a directory"

    def get_sysfs(key: str) -> str:
        return (sys_dir / key).read_text('utf-8').strip()

    dev_type = get_sysfs("device/model")
    if dev_type != "EEPROM2FS":
        print(f"Unexpected disk type. Expected {'EEPROM2FS'!r}, but found {dev_type!r}", file=sys.stderr)
        return 1

    block_count = int(get_sysfs("size"))
    disk_size = 512 * block_count

    if disk_size not in LEGAL_DISK_SIZES:
        print(f"Unexpected disk size {disk_size}. Expected one of {sorted(LEGAL_DISK_SIZES)}", file=sys.stderr)
        return 1
    
    print("Writing image file...")
    with disk_path.open("rb+") as disk:
        disk.write(image)
        disk.flush()

    print("Validating image file...")
    with disk_path.open("rb") as disk:
        check = disk.read(len(image))
        if image != check:
            print("Failed to write image!.", file=sys.stderr)
            return 1
        
    print("Success!")

    return 0


if __name__ == "__main__":
    sys.exit(main())