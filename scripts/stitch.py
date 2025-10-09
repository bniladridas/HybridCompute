import cv2
import os
import numpy as np
import sys

print("Starting stitch")
sys.stdout.flush()

def stitch_tiles(input_dir, output_path):
    tiles = []
    tile_files = sorted([f for f in os.listdir(input_dir) if f.startswith("tile_") and f.endswith(".jpg")])
    if not tile_files:
        raise ValueError("No tile files found in input directory")
    for tile_file in tile_files:
        img = cv2.imread(os.path.join(input_dir, tile_file))
        if img is None:
            raise ValueError(f"Could not load {tile_file}")
        tiles.append(img)
    tile_count = len(tiles)
    tiles = np.array(tiles)
    grid_size = int(np.sqrt(tile_count))
    if grid_size * grid_size != tile_count:
        raise ValueError(f"Tile count {tile_count} is not a perfect square")
    stitched = cv2.vconcat([cv2.hconcat(list(tiles_row)) for tiles_row in np.array_split(tiles, grid_size)])
    print("Stitched shape:", stitched.shape)
    print("About to write to", output_path)
    sys.stdout.flush()
    success = cv2.imwrite(output_path, stitched)
    if success:
        print("Stitch completed successfully")
    else:
        print("Failed to write output image")
    sys.stdout.flush()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 stitch.py <input_dir> <output_path>")
        sys.exit(1)
    input_dir = sys.argv[1]
    output_path = sys.argv[2]
    stitch_tiles(input_dir, output_path)