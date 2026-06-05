import subprocess
import sys
import os

if len(sys.argv) < 2:
    sys.exit(1)

entry_id = sys.argv[1]

# image-uri: direct file path passed as second arg
if len(sys.argv) >= 3:
    direct_path = sys.argv[2]
    if os.path.isfile(direct_path):
        print(direct_path)
    sys.exit(0)

out_dir = "/tmp/qs-clip-previews"
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, f"{entry_id}.png")

if os.path.isfile(out_path):
    print(out_path)
    sys.exit(0)

result = subprocess.run(["cliphist", "decode", entry_id], capture_output=True)
if result.returncode != 0:
    sys.exit(1)

data = result.stdout

if data[:4] == b"\x89PNG":
    with open(out_path, "wb") as f:
        f.write(data)
    print(out_path)
elif data[:2] == b"\xff\xd8":
    conv = subprocess.run(["convert", "jpeg:-", out_path], input=data, capture_output=True)
    if conv.returncode == 0:
        print(out_path)
    else:
        sys.exit(1)
elif data[:4] in (b"GIF8", b"GIF9"):
    conv = subprocess.run(["convert", "gif:-", out_path], input=data, capture_output=True)
    if conv.returncode == 0:
        print(out_path)
    else:
        sys.exit(1)
else:
    conv = subprocess.run(["convert", "-", out_path], input=data, capture_output=True)
    if conv.returncode == 0:
        print(out_path)
    else:
        sys.exit(1)