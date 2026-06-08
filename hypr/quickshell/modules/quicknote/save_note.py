#!/usr/bin/env python3
import sys
import os

note_path = sys.argv[1]
content = sys.stdin.read()

os.makedirs(os.path.dirname(note_path), exist_ok=True)
with open(note_path, 'w') as f:
    f.write(content)