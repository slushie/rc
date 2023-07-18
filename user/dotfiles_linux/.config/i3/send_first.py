#!/usr/bin/python3

import os
import sys
from ewmh import EWMH

def find(match: str) -> int:
    wm = EWMH()
    for c in wm.getClientList():
        for t in c.get_wm_class():
            if t == match:
                return c.id
    return None

if len(sys.argv) <= 1 or sys.argv[1] in ('-h', '--help'):
    print(f"""
    Usage:
          {sys.argv[0]} {{ --list | <class> [command...] }}
    Where:
        CLASS       is the X window class name to match exactly
        COMMAND     is the i3 command to send to the window
    Or,
        --list      to list all window classes and their IDs

    If COMMAND is not specified, the window ID is printed to stdout.
    """, file=sys.stderr)
    sys.exit(1)

match = sys.argv[1]
if match in ('-l', '--list'):
    wm = EWMH()
    for c in wm.getClientList():
        print(f"{c.id} {c.get_wm_class()}")
    sys.exit(0)


win = find(match)
if win is None:
    print(f"ERROR no window with class matching {match}", file=sys.stderr)
    sys.exit(1)

command = sys.argv[2:]
if len(command) == 0:
    print(win)
    sys.exit(0)

os.system(f"i3-msg [id=\"{win}\"] {' '.join(command)}")
