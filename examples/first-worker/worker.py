"""Punch-list worker: one plain job, done the same way every time.

Input:  punch-list.csv  (columns: id,item,area,owner,status,due,updated)
Output: packet.md       (a short research packet a person or a model can read)

It counts, lists and flags. It never decides, edits the list or contacts anyone.
"""
import csv
import sys
from datetime import date

SOURCE = sys.argv[1] if len(sys.argv) > 1 else "punch-list.csv"
PACKET = sys.argv[2] if len(sys.argv) > 2 else "packet.md"
today = date.today()

with open(SOURCE, newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

open_items = [r for r in rows if r["status"].strip().lower() != "done"]
overdue = [r for r in open_items if date.fromisoformat(r["due"]) < today]

by_owner = {}
for r in open_items:
    by_owner[r["owner"]] = by_owner.get(r["owner"], 0) + 1

lines = [
    "# Punch-list packet",
    "",
    f"Prepared by the punch-list worker on {today.isoformat()} from `{SOURCE}`.",
    "Facts only. No recommendations.",
    "",
    f"- Items on the list: {len(rows)}",
    f"- Open: {len(open_items)}",
    f"- Overdue: {len(overdue)}",
    "",
    "## Overdue",
    "",
]
lines += [f"- #{r['id']} {r['item']} ({r['area']}, {r['owner']}), due {r['due']}" for r in overdue] or ["- None"]
lines += ["", "## Open items by owner", ""]
lines += [f"- {owner}: {n}" for owner, n in sorted(by_owner.items())] or ["- None"]
lines += ["", "## What this packet does not know", "",
          "- Whether an item is really finished on site. It only reads the status column.",
          "- Anything not written in the list.", ""]

with open(PACKET, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"Wrote {PACKET}: {len(open_items)} open, {len(overdue)} overdue")
