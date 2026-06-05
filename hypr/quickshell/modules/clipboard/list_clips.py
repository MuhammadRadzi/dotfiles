import subprocess
import sys
import os

result = subprocess.run(["cliphist", "list"], capture_output=True, text=False)
lines = result.stdout.split(b"\n")

for line in lines:
    if not line.strip():
        continue
    tab_idx = line.find(b"\t")
    if tab_idx == -1:
        continue
    entry_id = line[:tab_idx].decode("utf-8", errors="replace").strip()
    content = line[tab_idx + 1:]

    if content.startswith(b"[[ binary data"):
        print(f"{entry_id}\timage\t[image]")
    else:
        preview = content.decode("utf-8", errors="replace").strip()
        if preview.startswith("file://"):
            path = preview[7:]
            ext = os.path.splitext(path)[1].lower()
            if ext in (".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg"):
                print(f"{entry_id}\timage-uri\t{path}")
                continue
        preview = " ".join(preview.splitlines())
        print(f"{entry_id}\ttext\t{preview}")