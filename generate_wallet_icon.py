#!/usr/bin/env python3
"""Generate a 1024x1024 wallet icon PNG with purple color"""

from PIL import Image, ImageDraw

# Create a 1024x1024 white background image
size = 1024
img = Image.new('RGB', (size, size), color='white')
draw = ImageDraw.Draw(img)

# Purple color (Bexly purple700)
purple = '#731FE0'

# Draw a simplified wallet icon
# This is a basic geometric representation
padding = int(size * 0.2)  # 20% padding
icon_size = size - (2 * padding)
x1, y1 = padding, padding
x2, y2 = size - padding, size - padding

# Outer wallet rectangle with rounded corners
wallet_rect = [x1 + 40, y1 + 80, x2 - 40, y2 - 80]
draw.rounded_rectangle(wallet_rect, radius=40, fill=purple, outline=purple, width=0)

# Inner pocket/flap
flap_rect = [x1 + 120, y1 + 200, x2 - 120, y2 - 200]
draw.rounded_rectangle(flap_rect, radius=30, fill='white', outline='white', width=0)

# Button/clasp circle
center_x = size // 2 + 80
center_y = size // 2
radius = 60
draw.ellipse([center_x - radius, center_y - radius,
              center_x + radius, center_y + radius],
             fill=purple, outline=purple)

# Save the image
output_path = 'assets/icon/wallet-icon-1024.png'
img.save(output_path, 'PNG')
print(f'✓ Icon saved to {output_path}')
