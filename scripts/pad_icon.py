"""
Create a padded version of app_icon.png for Android adaptive icon foreground.
Android adaptive icons use a 108dp canvas with a 72dp safe zone (inner 66.7%).
The logo must fit within that safe zone to avoid cropping.
"""
from PIL import Image
import os

base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = os.path.join(base_dir, "assets", "logo", "app_icon.png")
dst = os.path.join(base_dir, "assets", "logo", "app_icon_foreground.png")

img = Image.open(src).convert("RGBA")

# Create a 1024x1024 transparent canvas (standard adaptive icon size)
canvas_size = 1024
# The safe zone is the inner 66.7%, so the icon should be ~683px centered
safe_zone = int(canvas_size * 0.60)  # slightly smaller for extra safety margin

# Resize the original icon to fit in the safe zone
img_resized = img.resize((safe_zone, safe_zone), Image.LANCZOS)

# Create transparent canvas
canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

# Paste centered
offset = (canvas_size - safe_zone) // 2
canvas.paste(img_resized, (offset, offset), img_resized)

canvas.save(dst, "PNG")
print(f"Created padded foreground icon: {dst}")
print(f"Canvas: {canvas_size}x{canvas_size}, Logo: {safe_zone}x{safe_zone}, Offset: {offset}")
