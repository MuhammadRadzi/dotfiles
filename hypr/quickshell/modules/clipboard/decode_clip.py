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
        with open(direct_path, "rb") as f:
            data = f.read()
        ext = os.path.splitext(direct_path)[1].lower()
        mime = "image/png"
        if ext in (".jpg", ".jpeg"):
            mime = "image/jpeg"
        elif ext == ".gif":
            mime = "image/gif"
        elif ext == ".webp":
            mime = "image/webp"
        subprocess.run(["wl-copy", "--type", mime], input=data)
    sys.exit(0)

result = subprocess.run(["cliphist", "decode", entry_id], capture_output=True)
if result.returncode != 0:
    sys.exit(1)

data = result.stdout

if data[:4] == b"\x89PNG" or data[:2] == b"\xff\xd8" or data[:4] in (b"GIF8", b"GIF9"):
    subprocess.run(["wl-copy", "--type", "image/png"], input=data)
else:
    subprocess.run(["wl-copy"], input=data)