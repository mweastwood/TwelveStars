#!/usr/bin/env python3
"""
Unit tests for repository automation and release scripts.
"""

import json
import os
import re
import subprocess
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BIN_DIR = REPO_ROOT / "bin"


class TestRepositoryScripts(unittest.TestCase):
    def test_scripts_executable(self):
        scripts = ["tag.sh", "generate_icons.sh", "test_scripts.py"]
        for script_name in scripts:
            script_path = BIN_DIR / script_name
            self.assertTrue(script_path.is_file(), f"{script_name} should exist")
            self.assertTrue(
                os.access(script_path, os.X_OK),
                f"{script_name} should have executable permissions",
            )

    def test_graviton_config_valid(self):
        config_path = REPO_ROOT / ".graviton.json"
        self.assertTrue(config_path.is_file(), ".graviton.json should exist")
        with open(config_path, "r", encoding="utf-8") as f:
            cfg = json.load(f)
        self.assertIn("release", cfg)
        release = cfg["release"]
        self.assertIn("commands", release)
        self.assertEqual(release.get("branch"), "main")
        self.assertIn("allowed_users", release)
        self.assertIn("mweastwood", release["allowed_users"])
        self.assertIn("patch", release["commands"])
        self.assertIn("minor", release["commands"])
        self.assertIn("major", release["commands"])

        # Validate issue regex pattern
        pattern = release.get("issue_pattern")
        self.assertTrue(bool(pattern), "issue_pattern must be specified")
        self.assertTrue(bool(re.search(pattern, "🚀 Release Controller")))
        self.assertTrue(bool(re.search(pattern, "Release Controller")))
        self.assertTrue(bool(re.search(pattern, "release")))
        self.assertFalse(bool(re.search(pattern, "Bug report about release notes")))

    def test_tag_script_help_and_dry_run(self):
        tag_script = str(BIN_DIR / "tag.sh")

        # Test help (both flag and positional)
        res_flag = subprocess.run([tag_script, "--help"], capture_output=True, text=True)
        self.assertEqual(res_flag.returncode, 1)
        self.assertIn("Usage:", res_flag.stdout)

        res_pos = subprocess.run([tag_script, "help"], capture_output=True, text=True)
        self.assertEqual(res_pos.returncode, 1)
        self.assertIn("Usage:", res_pos.stdout)

        # Test invalid argument
        res_err = subprocess.run([tag_script, "invalid_arg"], capture_output=True, text=True)
        self.assertNotEqual(res_err.returncode, 0)
        self.assertIn("Unknown option", res_err.stderr)

        # Test missing increment type with dry-run
        res_dry_flag = subprocess.run([tag_script, "--dry-run"], capture_output=True, text=True)
        self.assertNotEqual(res_dry_flag.returncode, 0)
        self.assertIn("Increment type is required", res_dry_flag.stderr)

        res_dry_pos = subprocess.run([tag_script, "dry-run"], capture_output=True, text=True)
        self.assertNotEqual(res_dry_pos.returncode, 0)
        self.assertIn("Increment type is required", res_dry_pos.stderr)

        # Test dry-run with positional and flag commands
        for cmd in ["patch", "minor", "major", "--patch", "--minor", "--major"]:
            res = subprocess.run([tag_script, cmd, "--dry-run"], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0, f"Failed for command {cmd}: {res.stderr}")
            self.assertIn("[DRY RUN]", res.stdout)
            self.assertIn("Would create signed tag v", res.stdout)


if __name__ == "__main__":
    unittest.main()
