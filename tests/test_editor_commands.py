"""Run with: python3 -m unittest discover -s tests -v"""

import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1] / "wrigglekick.sh"


class EditorCommandsTest(unittest.TestCase):
    def test_editor_arguments(self):
        cases = [
            ("'fake-editor'", []),
            ("'fake-editor --xxxx --wait'", ["--xxxx", "--wait"]),
            ("'  fake-editor\t--xxxx  '", ["--xxxx"]),
            ("('fake-editor' '--name' 'editor data' '')", ["--name", "editor data", ""]),
            ("'__missing_editor__ --xxxx'", []),
            ("'fake-editor * ; $(touch marker)'", ["*", ";", "$(touch", "marker)"]),
        ]
        for action in ("e", "e2"):
            for setting, expected in cases:
                if action == "e2" and "__missing_editor__" in setting:
                    continue  # e2 does not select a fallback editor.
                with self.subTest(action=action, setting=setting):
                    self.check_editor(action, setting, expected)

    def test_executable_path_with_spaces(self):
        for action in ("e", "e2"):
            for array in (False, True):
                with self.subTest(action=action, array=array):
                    self.check_editor(action, None, ["--xxxx"] if array else [], array)

    def check_editor(self, action, setting, expected, array=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            editor = root / ("editor with spaces" if setting is None else "fake-editor")
            editor.write_text(
                '#!/bin/bash\n'
                'printf "%s\\0" "$@" > "$EDITOR_LOG"\n'
                'printf "edited\\n" >> "${!#}"\n'
            )
            editor.chmod(0o755)
            (root / "edit").symlink_to(editor)
            if setting is None:
                setting = shlex.quote(str(editor))
                if array:
                    setting = f"({setting} '--xxxx')"
            variable = "selected_editor2" if action == "e2" else "selected_editor"
            script = root / "wrigglekick.sh"
            script.write_text(SOURCE.read_text().replace(
                f"  {variable}='{variable}'", f"  {variable}={setting}", 1
            ))
            outline = root / "outline.txt"
            outline.write_text("# First [,,]\noriginal\n# Second [,,]\nuntouched\n")
            env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}", TERM="xterm",
                       COLUMNS="120", EDITOR_LOG=str(root / "args"), TMPDIR=str(root))
            result = subprocess.run(
                ["bash", script.name, outline.name, action, "1"], cwd=root,
                env=env, input="", capture_output=True, text=True, timeout=15,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            arguments = (root / "args").read_bytes().decode().split("\0")[:-1]
            self.assertEqual(arguments[:-1], expected)
            self.assertTrue(Path(arguments[-1]).is_file())
            self.assertEqual(outline.read_text(),
                             "# First [,,]\noriginal\nedited\n# Second [,,]\nuntouched\n")
            self.assertFalse((root / "marker").exists())
