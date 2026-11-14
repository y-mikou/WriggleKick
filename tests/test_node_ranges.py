"""Regression tests run against isolated copies; user documents are never edited."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1] / "wrigglekick.sh"
OUTLINE = "".join(f"## Node {i} [,,]\nbody {i}\n" for i in range(1, 8))


class NodeRangesTest(unittest.TestCase):
    def run_command(self, action, start, end=None, outline=OUTLINE):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            script = SOURCE.read_text()
            for variable in ("selected_editor", "selected_editor2"):
                script = script.replace(f"{variable}='{variable}'", f"{variable}='fake-editor'", 1)
            (root / "wrigglekick.sh").write_text(script)
            editor = root / "fake-editor"
            editor.write_text('#!/bin/bash\ntouch editor-called\n')
            editor.chmod(0o755)
            document = root / "outline.txt"
            document.write_text(outline)
            args = ["bash", "wrigglekick.sh", document.name, action, start]
            if end is not None:
                args.append(end)
            result = subprocess.run(
                args, cwd=root, input="", capture_output=True, text=True, timeout=15,
                env=dict(os.environ, PATH=f"{root}:{os.environ['PATH']}",
                         TERM="xterm", COLUMNS="120", TMPDIR=directory),
            )
            return result, document.read_text(), (root / "editor-called").exists()

    def test_invalid_ranges_preserve_document(self):
        for action in ("e", "e2", "ml", "mr"):
            for start, end in (("1", "8"), ("0", "7"), ("-1", "7"),
                               ("8", "8"), ("3", "2"), ("1", "0"),
                               ("1", "-1"), ("1", "bad"), ("1", "1+1"),
                               ("1", "18446744073709551617")):
                with self.subTest(action=action, start=start, end=end):
                    result, actual, called = self.run_command(action, start, end)
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertEqual(actual, OUTLINE)
                    self.assertFalse(called)

    def test_edit_valid_ranges(self):
        for action in ("e", "e2"):
            for start, end in (("1", "7"), ("7", "7"), ("2", "-"),
                               ("1", None), ("0001", "0007")):
                with self.subTest(action=action, start=start, end=end):
                    result, actual, called = self.run_command(action, start, end)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(actual, OUTLINE)
                    self.assertTrue(called)

    def test_invalid_insertion_and_destinations(self):
        for action in ("i", "ie", "mt", "gmt", "cp"):
            for number in ("0", "8", "18446744073709551617"):
                with self.subTest(action=action, number=number):
                    args = (number, "Title") if action in ("i", "ie") else ("1", number)
                    result, actual, called = self.run_command(action, *args)
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertEqual(actual, OUTLINE)
                    self.assertFalse(called)

    def test_adjacent_moves_preserve_all_nodes(self):
        for action in ("mt", "gmt"):
            for start, end in (("2", "1"), ("7", "6"), ("1", "2"), ("3", "3")):
                for body in (True, False):
                    outline = OUTLINE if body else "".join(f"## Node {i} [,,]\n" for i in range(1, 8))
                    with self.subTest(action=action, start=start, end=end, body=body):
                        result, actual, _ = self.run_command(action, start, end, outline)
                        expected_status = 1 if action == "gmt" and start == end else 0
                        self.assertEqual(result.returncode, expected_status, result.stderr)
                        order = list(range(1, 8))
                        if start != end:
                            order.remove(int(start))
                            order.insert(order.index(int(end)) + 1, int(start))
                        expected = "".join(f"## Node {i} [,,]\n" + (f"body {i}\n" if body else "") for i in order)
                        self.assertEqual(actual, expected)

    def test_adjacent_group_move_preserves_children(self):
        outline = "# A [,,]\n# B [,,]\n## Child [,,]\n# C [,,]\n"
        result, actual, _ = self.run_command("gmt", "2", "1", outline)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(actual, outline)
        result, actual, _ = self.run_command("gmt", "2", "3", outline)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(actual, outline)

    def test_valid_slide_ranges(self):
        for action, prefix in (("ml", "#"), ("mr", "###")):
            with self.subTest(action=action):
                result, actual, _ = self.run_command(action, "1", "7")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(actual, OUTLINE.replace("##", prefix))

    def test_leading_zeros_are_decimal(self):
        outline = OUTLINE + "## Node 8 [,,]\nbody 8\n"
        result, actual, called = self.run_command("e", "08", "0008", outline)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(called)
        self.assertEqual(actual, outline)
