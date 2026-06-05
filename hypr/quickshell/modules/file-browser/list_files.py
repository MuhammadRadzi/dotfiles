import os
import sys
import stat

path = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~")

try:
    entries = os.listdir(path)
except PermissionError:
    sys.exit(1)

dirs = []
files = []

for entry in entries:
    full_path = os.path.join(path, entry)
    try:
        st = os.stat(full_path)
        is_dir = stat.S_ISDIR(st.st_mode)
        size = st.st_size
        mtime = st.st_mtime
    except (PermissionError, FileNotFoundError):
        continue

    info = {
        "name": entry,
        "path": full_path,
        "is_dir": is_dir,
        "size": size,
        "mtime": mtime,
    }

    if is_dir:
        dirs.append(info)
    else:
        files.append(info)

dirs.sort(key=lambda x: x["name"].lower())
files.sort(key=lambda x: x["name"].lower())

for item in dirs + files:
    size_str = str(item["size"]) if not item["is_dir"] else ""
    print(f"{'d' if item['is_dir'] else 'f'}\t{item['name']}\t{item['path']}\t{size_str}")