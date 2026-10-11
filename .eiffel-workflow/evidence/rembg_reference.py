"""Evidence tool (not product code): rembg's own u2net_human_seg mask for a photo, the reference
the Eiffel IMG_CUTOUT is measured against. Usage: rembg_reference.py <photo> <mask_out.png>"""
import sys
from PIL import Image
from rembg import new_session

photo, out = sys.argv[1], sys.argv[2]
session = new_session("u2net_human_seg")
mask = session.predict(Image.open(photo).convert("RGB"))[0]
mask.save(out)
print("reference mask", mask.size, mask.mode, "->", out)
