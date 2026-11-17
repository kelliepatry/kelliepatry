"""Validate a punch list, then write a dated packet of sourced counts.

Input columns: id,item,area,owner,status,due,updated
Allowed statuses: open, done (case-insensitive).
Invalid input fails the run and writes no new packet. An older packet may remain.
"""
import csv
import hashlib
import sys
from datetime import date
from pathlib import Path

REQUIRED = ("id", "item", "area", "owner", "status", "due", "updated")


def read_rows(source):
    with open(source, newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream)
        headers = reader.fieldnames or []
        if len(headers) != len(set(headers)) or set(headers) != set(REQUIRED):
            raise ValueError("Header must contain each required column exactly once: "
                             + ",".join(REQUIRED))
        rows, seen, errors = [], set(), []
        for number, raw in enumerate(reader, start=2):
            if None in raw or any(value is None for value in raw.values()):
                errors.append(f"row {number}: wrong number of fields")
                continue
            row = {key: value.strip() for key, value in raw.items()}
            for key in REQUIRED:
                if not row[key]:
                    errors.append(f"row {number}: {key} is blank")
            if row["id"] in seen:
                errors.append(f"row {number}: duplicate id {row['id']!r}")
            seen.add(row["id"])
            row["status"] = row["status"].lower()
            if row["status"] not in {"open", "done"}:
                errors.append(f"row {number}: unsupported status {row['status']!r}")
            for key in ("due", "updated"):
                try:
                    parsed = date.fromisoformat(row[key])
                    if parsed.isoformat() != row[key]:
                        raise ValueError()
                except ValueError:
                    errors.append(f"row {number}: {key} must be a valid YYYY-MM-DD date")
            rows.append(row)
        if errors:
            raise ValueError("\n".join(errors))
        return rows


def make_packet(source, today):
    rows = read_rows(source)
    open_items = [row for row in rows if row["status"] == "open"]
    overdue = [row for row in open_items if date.fromisoformat(row["due"]) < today]
    by_owner = {}
    for row in open_items:
        by_owner[row["owner"]] = by_owner.get(row["owner"], 0) + 1

    # Include a content digest so a change outside the summary remains visible.
    digest = hashlib.sha256(Path(source).read_bytes()).hexdigest()
    lines = [
        "# Punch-list packet", "",
        f"Prepared by the punch-list worker on {today.isoformat()} from `{source}`.",
        f"Source SHA-256: `{digest}`.",
        "Validated list data. No recommendations.", "",
        f"- Items on the list: {len(rows)}",
        f"- Open: {len(open_items)}",
        f"- Overdue: {len(overdue)}", "", "## Overdue", "",
    ]
    lines += [
        f"- #{r['id']} {r['item']} ({r['area']}, {r['owner']}), due {r['due']}"
        for r in overdue
    ] or ["- None"]
    lines += ["", "## Open items by owner", ""]
    lines += [f"- {owner}: {count}" for owner, count in sorted(by_owner.items())] or ["- None"]
    lines += ["", "## What this packet does not know", "",
              "- Whether an item is really finished on site. It only reads the status column.",
              "- Anything not written in the list.",
              "- Whether a later revision has changed this list.", ""]
    return "\n".join(lines)


def main():
    source = sys.argv[1] if len(sys.argv) > 1 else "punch-list.csv"
    target = Path(sys.argv[2] if len(sys.argv) > 2 else "packet.md")
    try:
        packet = make_packet(source, date.today())
    except (ValueError, OSError, csv.Error) as error:
        print(f"Invalid punch list; no new packet written:\n{error}", file=sys.stderr)
        return 1
    temporary = target.with_suffix(target.suffix + ".tmp")
    temporary.write_text(packet, encoding="utf-8", newline="\n")
    temporary.replace(target)
    print(f"Wrote {target} from validated input")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
