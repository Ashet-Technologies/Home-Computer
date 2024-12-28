import PIL
from PIL import Image
from pathlib import Path
import itertools

file_path = Path(__file__).parent / "mountains_800x480_rgb332.png"

blob = file_path.with_suffix(".bin").read_bytes()

for i in range(480):
    print(f'  "{"".join(f"\\x{b:02X}" for b in blob[800 * i :][:800])}"')

# blob = bytes()

# with Image.open(file_path) as image:
#     assert image.size == (800, 480)

#     for y in range(480):
#         for x in range(800):
#             r, g, b, a = image.getpixel((x, y))

#             r3 = (r >> 5) & 0x7
#             g3 = (g >> 5) & 0x7
#             b2 = (b >> 6) & 0x3

#             rgb332 = (r3 << 5) | (g3 << 2) | (b2 << 0)

#             blob += rgb332.to_bytes(1)

# file_path.with_suffix(".bin").write_bytes(blob)

# print(len(blob))
