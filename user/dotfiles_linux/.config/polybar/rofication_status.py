#!/usr/bin/python3
import sys
from rofication import RoficationClient

client = RoficationClient()

if len(sys.argv) == 2 and sys.argv[1] == 'clear':
    for notif in client.list():
        client.delete(notif.id)
    sys.exit()

num, crit = client.count()

colors = dict(
    empty=sys.argv[1] if len(sys.argv) >= 2 else "",
    not_empty=sys.argv[2] if len(sys.argv) >= 3 else "",
    critical=sys.argv[3] if len(sys.argv) >= 4 else "",
)

icon = ""
text = "none" if num == 0 else f" {num}"
if num == 0:
    color = colors['empty']
elif crit == 0:
    color = colors['not_empty']
else:
    color = colors['critical']
    text += f", {crit}!" if crit != num else "!"

print(f"%{{F{color}}}{icon}%{{F-}} {text}" if color != "" else f"{icon}{text}")

