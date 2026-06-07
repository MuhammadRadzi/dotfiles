#!/usr/bin/env python3
import sys
import os

rules_path = os.path.expanduser("~/.config/hypr/rules.conf")

if not os.path.exists(rules_path):
    sys.exit(0)

with open(rules_path) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("windowrule"):
            # Format: windowrule = match:filter, rule
            parts = line.split("=", 1)
            if len(parts) < 2:
                continue
            value = parts[1].strip()
            # Split by first comma: "match:filter, rule1, rule2..."
            comma = value.find(",")
            if comma == -1:
                continue
            matcher = value[:comma].strip()   # e.g. match:class ^(kitty)$
            rules_part = value[comma+1:].strip()  # e.g. float on
            # Strip "match:" prefix for display
            fltr = matcher.replace("match:", "", 1)
            print(f"{rules_part}\t{fltr}")