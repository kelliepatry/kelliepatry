"""Run from repository root: python -m unittest discover -s tests -p "test_*.py"."""
import csv
import importlib.util
import subprocess
import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKER = ROOT / "examples/first-worker/worker.py"
spec = importlib.util.spec_from_file_location("worker", WORKER)
worker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worker)


class PunchListTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.source = Path(self.temp.name) / "list.csv"
        with (ROOT / "examples/first-worker/punch-list.csv").open(encoding="utf-8") as f:
            self.rows = list(csv.DictReader(f))
        self.write()

    def write(self, headers=None):
        with self.source.open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=headers or worker.REQUIRED, extrasaction="ignore")
            writer.writeheader()
            writer.writerows(self.rows)

    def packet(self):
        return worker.make_packet(self.source, date(2026, 11, 16))

    def test_known_counts_and_due_boundary(self):
        packet = self.packet()
        for expected in ("Items on the list: 6", "Open: 4", "Overdue: 3",
                         "Source SHA-256:", "Whether a later revision"):
            self.assertIn(expected, packet)
        self.rows[0]["due"] = "2026-11-16"
        self.write()
        self.assertIn("Overdue: 2", self.packet())

    def test_invalid_status_is_not_counted_as_open(self):
        self.rows[2]["status"] = "cancelled"
        self.write()
        with self.assertRaisesRegex(ValueError, "row 4: unsupported status"):
            self.packet()

    def test_blank_owner_fails(self):
        self.rows[0]["owner"] = " "
        self.write()
        with self.assertRaisesRegex(ValueError, "owner is blank"):
            self.packet()

    def test_duplicate_id_fails(self):
        self.rows[1]["id"] = self.rows[0]["id"]
        self.write()
        with self.assertRaisesRegex(ValueError, "duplicate id"):
            self.packet()

    def test_invalid_dates_fail(self):
        for key, value in (("due", "2026-02-30"), ("updated", "yesterday"),
                           ("due", "20261110")):
            with self.subTest(key=key, value=value):
                original = self.rows[0][key]
                self.rows[0][key] = value
                self.write()
                with self.assertRaisesRegex(ValueError, "valid YYYY-MM-DD"):
                    self.packet()
                self.rows[0][key] = original

    def test_missing_and_duplicate_columns_fail(self):
        self.write(headers=worker.REQUIRED[:-1])
        with self.assertRaisesRegex(ValueError, "Header"):
            self.packet()
        self.source.write_text("id,id\n1,1\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Header"):
            self.packet()

    def test_wrong_number_of_fields_fails(self):
        with self.source.open("a", encoding="utf-8") as f:
            f.write("7,too,few\n")
        with self.assertRaisesRegex(ValueError, "wrong number of fields"):
            self.packet()

    def test_status_normalization_and_empty_list(self):
        self.rows[0]["status"] = " OPEN "
        self.write()
        self.assertIn("Open: 4", self.packet())
        self.rows = []
        self.write()
        self.assertIn("Items on the list: 0", self.packet())

    def test_changed_source_affects_packet_even_if_counts_do_not(self):
        before = self.packet()
        self.rows[2]["item"] = "An updated description on a closed item"
        self.write()
        self.assertNotEqual(before, self.packet())

    def test_failed_cli_preserves_old_packet_and_returns_failure(self):
        target = Path(self.temp.name) / "packet.md"
        target.write_text("OLDER PACKET", encoding="utf-8")
        self.rows[0]["owner"] = ""
        self.write()
        result = subprocess.run([sys.executable, str(WORKER), str(self.source), str(target)],
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no new packet written", result.stderr)
        self.assertEqual(target.read_text(encoding="utf-8"), "OLDER PACKET")


if __name__ == "__main__":
    unittest.main()
