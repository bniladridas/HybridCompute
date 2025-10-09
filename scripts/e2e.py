import os
import subprocess
import sys
import cv2
import shutil
import glob

runner_os = os.environ.get('RUNNER_OS', '')

# Create dirs
os.makedirs('test_images/tiles', exist_ok=True)
os.makedirs('test_images/upscaled', exist_ok=True)

# Create test image
subprocess.run([sys.executable, 'create_test_image.py'])

# Preprocess
if runner_os == 'Windows':
    subprocess.run(['./build/Release/preprocess.exe', 'test_images', 'test_images/tiles'])
else:
    subprocess.run(['./build/preprocess', 'test_images', 'test_images/tiles'])

print("Preprocess done")

# Copy tiles
for tile in glob.glob('test_images/tiles/*.jpg'):
    shutil.copy(tile, 'test_images/upscaled/')
print("Cp done")

# Rename tiles
for i in range(16):
    src = f'test_images/upscaled/test_tile_{i}.jpg'
    dst = f'test_images/upscaled/tile_{i}.jpg'
    if os.path.exists(src):
        os.replace(src, dst)
print("Mv done")

# Mock upscale tiles (simulate 2x CUDA upscale using CPU)
for i in range(16):
    tile_path = f'test_images/upscaled/tile_{i}.jpg'
    if os.path.exists(tile_path):
        img = cv2.imread(tile_path)
        if img is not None:
            upscaled = cv2.resize(img, (img.shape[1] * 2, img.shape[0] * 2), interpolation=cv2.INTER_CUBIC)
            cv2.imwrite(tile_path, upscaled)
print("Mock upscale done")

# Stitch
if runner_os == 'Windows':
    subprocess.run([sys.executable, 'scripts/stitch.py', 'test_images/upscaled', 'test_images/final_output.jpg'])
else:
    subprocess.run([sys.executable, '-m', 'coverage', 'run', '--source=scripts', 'scripts/stitch.py', 'test_images/upscaled', 'test_images/final_output.jpg'])

print("Stitch done")

# Verify
if os.path.exists('test_images/final_output.jpg'):
    print("E2E test passed")
else:
    sys.exit(1)