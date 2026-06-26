import os
import glob
import subprocess

HOME = os.path.expanduser("~")

ICON_DIRS = [
    # User-level icon theme dirs (Steam game icons, user-installed apps, etc.)
    # checked first since they're more likely to be the "personal" override.
    f"{HOME}/.local/share/icons/hicolor/48x48/apps",
    f"{HOME}/.local/share/icons/hicolor/32x32/apps",
    f"{HOME}/.local/share/icons/hicolor/64x64/apps",
    f"{HOME}/.local/share/icons/hicolor/128x128/apps",
    f"{HOME}/.local/share/icons/hicolor/scalable/apps",
    f"{HOME}/.local/share/pixmaps",
    # System-wide icon theme dirs
    "/usr/share/icons/hicolor/48x48/apps",
    "/usr/share/icons/hicolor/32x32/apps",
    "/usr/share/icons/hicolor/64x64/apps",
    "/usr/share/icons/hicolor/128x128/apps",
    "/usr/share/icons/hicolor/scalable/apps",
    "/usr/share/pixmaps",
]

def resolve_icon(icon_name):
    if not icon_name:
        return ""
    # Already an absolute path
    if os.path.isabs(icon_name) and os.path.isfile(icon_name):
        return icon_name
    # Search in known dirs first (fast)
    for d in ICON_DIRS:
        for ext in ("png", "svg", "xpm"):
            path = os.path.join(d, f"{icon_name}.{ext}")
            if os.path.isfile(path):
                return path
    # Fallback: broader search
    try:
        result = subprocess.run(
            ["find", f"{HOME}/.local/share/icons", f"{HOME}/.local/share/pixmaps",
             "/usr/share/icons", "/usr/share/pixmaps",
             "-name", f"{icon_name}.png",
             "-o", "-name", f"{icon_name}.svg"],
            capture_output=True, text=True, timeout=3
        )
        lines = [l for l in result.stdout.strip().split("\n") if l and "16x16" not in l]
        if lines:
            return lines[0]
    except Exception:
        pass
    return ""

def parse_desktop_file(path):
    props = {}
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            in_entry = False
            for line in f:
                line = line.strip()
                if line == "[Desktop Entry]":
                    in_entry = True
                    continue
                if line.startswith("[") and line != "[Desktop Entry]":
                    if in_entry:
                        break  # stop at next section
                if not in_entry:
                    continue
                if "=" in line and not line.startswith("#"):
                    key, _, val = line.partition("=")
                    # Only store base keys (no locale like Name[id])
                    if "[" not in key:
                        props[key.strip()] = val.strip()
    except Exception:
        return None

    if props.get("Type") != "Application":
        return None
    if props.get("NoDisplay") == "true":
        return None
    if props.get("Hidden") == "true":
        return None

    name = props.get("Name", "")
    exec_val = props.get("Exec", "")
    icon_name = props.get("Icon", "")

    if not name or not exec_val:
        return None

    return name, exec_val, icon_name

def main():
    desktop_dirs = [
        "/usr/share/applications",
        os.path.expanduser("~/.local/share/applications"),
    ]

    apps = []
    seen = set()

    for d in desktop_dirs:
        for path in glob.glob(os.path.join(d, "*.desktop")):
            result = parse_desktop_file(path)
            if result is None:
                continue
            name, exec_val, icon_name = result
            if name in seen:
                continue
            seen.add(name)
            icon_path = resolve_icon(icon_name)
            apps.append((name, exec_val, icon_path))

    apps.sort(key=lambda x: x[0].lower())

    for name, exec_val, icon_path in apps:
        # Use tab separator, strip newlines just in case
        print(f"{name}\t{exec_val}\t{icon_path}")

if __name__ == "__main__":
    main()