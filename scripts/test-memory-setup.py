#!/usr/bin/env python3
"""Exercise memory setup with simulated machines; never change host swap/boot files."""

import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parent.parent


class MemorySetupTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotrobot-memory-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.write("meminfo", "MemTotal: 16000000 kB\n")
        self.write("swaps", "Filename Type Size Used Priority\n")
        self.write("cmdline", "root=UUID=abcd rw\n")
        self.write("zram/comp_algorithm", "lzo lz4 [zstd]\n")
        self.write("actions", "")
        self.paths = {
            "MEMINFO": "meminfo", "SWAPS": "swaps", "CMDLINE": "cmdline",
            "ZRAM_SYS": "zram", "ZRAM_MODULE": "missing-module",
            "ZRAM_CONF": "installed/zram-generator.conf",
            "SYSCTL_CONF": "installed/99-zram.conf", "ACTIONS": "actions",
        }

    def write(self, name, value):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value)

    def run_script(self, script, body, overrides="", success=True):
        assignments = "\n".join(f"{key}={shlex.quote(str(self.root / value))}" for key, value in self.paths.items())
        mocks = """
require_arch() { :; }
systemd-detect-virt() { return 1; }
modinfo() { return 0; }
systemctl() { return 1; }
sudo() { echo "Unexpected privileged call: $*" >&2; exit 88; }
"""
        command = f"source {shlex.quote(str(REPO / 'scripts' / script))}\n{assignments}\n{mocks}\n{overrides}\n{body}"
        env = dict(os.environ, XDG_STATE_HOME=str(self.root / "state"))
        result = subprocess.run(["bash", "-c", command], text=True, capture_output=True, env=env)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        return result.stdout + result.stderr

    def test_zram_scales_with_ram_and_caps_capacity(self):
        for ram_gib, expected_mib in [(2, 1024), (4, 2048), (8, 4096), (16, 8192), (64, 8192)]:
            with self.subTest(ram_gib=ram_gib):
                self.write("meminfo", f"MemTotal: {ram_gib * 1024**2} kB\n")
                output = self.run_script("setup-zram.sh", "main --check")
                self.assertIn(f"about {expected_mib} MiB", output)
                self.assertFalse((self.root / "installed").exists())

    @unittest.skipUnless(Path('/usr/lib/systemd/system-generators/zram-generator').is_file(), 'zram-generator is not installed')
    def test_installed_generator_accepts_template_on_different_ram_sizes(self):
        if subprocess.run(['systemd-detect-virt', '--container', '--quiet']).returncode == 0:
            self.skipTest('the real generator intentionally skips containers')
        self.write("proc/cmdline", "root=UUID=abcd\n")
        self.write("etc/systemd/zram-generator.conf", (REPO / 'packages/arch/zram-generator.conf').read_text())
        for ram_gib in [2, 4, 8, 16, 64]:
            with self.subTest(ram_gib=ram_gib):
                out = self.root / f"units-{ram_gib}"
                out.mkdir()
                self.write("proc/meminfo", f"MemTotal: {ram_gib * 1024**2} kB\n")
                result = subprocess.run(
                    ['/usr/lib/systemd/system-generators/zram-generator', str(out), str(out), str(out)],
                    env=dict(os.environ, ZRAM_GENERATOR_ROOT=str(self.root)), capture_output=True, text=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("Priority=100", (out / 'dev-zram0.swap').read_text())

    def test_zram_skips_containers_and_missing_driver(self):
        output = self.run_script("setup-zram.sh", "preflight", "systemd-detect-virt() { return 0; }", False)
        self.assertIn("containers", output)
        output = self.run_script("setup-zram.sh", "preflight", "modinfo() { return 1; }", False)
        self.assertIn("no available zram driver", output)

    def test_zram_preserves_command_line_opt_out_and_other_managers(self):
        self.write("cmdline", "root=UUID=abcd systemd.zram=0\n")
        self.assertIn("disabled", self.run_script("setup-zram.sh", "preflight", success=False))
        self.write("cmdline", "root=UUID=abcd\n")
        self.write("swaps", "Filename Type Size Used Priority\n/dev/zram1 partition 1024 100 100\n")
        self.assertIn("outside zram-generator", self.run_script("setup-zram.sh", "preflight", success=False))

    def test_active_zram_is_never_restarted(self):
        self.write("swaps", "Filename Type Size Used Priority\n/dev/zram0 partition 8388604 1000000 100\n")
        self.configure_zram()
        actions = (self.root / "actions").read_text()
        self.assertNotIn("restart", actions)
        self.assertNotIn("swapoff", actions)
        self.assertNotIn("start dev-zram0.swap", actions)
        self.assertNotIn("--system", actions)
        self.assertIn("compression-algorithm = zstd", (self.root / "installed/zram-generator.conf").read_text())

    def configure_zram(self):
        return self.run_script("setup-zram.sh", "configure_zram", """
sudo() {
  printf '%s\\n' "$*" >> "${ACTIONS}"
  case "$1" in
    install) "$@" ;;
    modprobe|systemctl|sysctl) return 0 ;;
    *) exit 88 ;;
  esac
}
""")

    def test_new_zram_uses_supported_compression_and_starts_swap(self):
        self.write("zram/comp_algorithm", "[lzo] lz4\n")
        self.configure_zram()
        config = (self.root / "installed/zram-generator.conf").read_text()
        self.assertNotIn("\ncompression-algorithm", config)
        self.assertIn("swap-priority = 100", config)
        self.assertIn("start dev-zram0.swap", (self.root / "actions").read_text())


if __name__ == "__main__":
    unittest.main()
