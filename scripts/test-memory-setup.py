#!/usr/bin/env python3
"""Exercise memory setup with simulated machines; never change host swap/boot files."""

import os
from pathlib import Path
import re
import shlex
import shutil
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
        self.write("power-state", "freeze mem disk\n")
        self.write("lockdown", "[none] integrity confidentiality\n")
        self.write("mkinitcpio.conf", "HOOKS=(base udev block filesystems fsck)\n")
        self.write("presets/linux.preset", "default_uki='/boot/EFI/Linux/arch.efi'\n")
        self.write("zram/comp_algorithm", "lzo lz4 [zstd]\n")
        self.write("fstab", "# fixture\n")
        self.write("actions", "")
        self.paths = {
            "MEMINFO": "meminfo", "SWAPS": "swaps", "CMDLINE": "cmdline",
            "ZRAM_SYS": "zram", "ZRAM_MODULE": "missing-module",
            "ZRAM_CONF": "installed/zram-generator.conf",
            "SYSCTL_CONF": "installed/99-zram.conf", "SWAPFILE": "swapfile",
            "FSTAB": "fstab", "POWER_STATE": "power-state", "LOCKDOWN": "lockdown",
            "POWER_SUPPLIES": "power-supplies", "MKINITCPIO_CONF": "mkinitcpio.conf",
            "MKINITCPIO_DROPINS": "mkinitcpio.conf.d", "PRESET_DIR": "presets",
            "KERNEL_CMDLINE": "cmdline", "GRUB_DEFAULT": "grub-default",
            "GRUB_CONFIG": "grub.cfg", "LOGIND_DROPIN": "installed/lid.conf",
            "SLEEP_DROPIN": "installed/sleep.conf", "ACTIONS": "actions",
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
findmnt() { if [[ $* == *FSTYPE* ]]; then echo ext4; else echo abcd-1234; fi; }
df() { printf 'Avail\\n137438953472\\n'; }
mkinitcpio() { :; }
grub-mkconfig() { :; }
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

    def test_hibernate_check_sizes_swap_without_creating_it(self):
        output = self.run_script("setup-hibernate.sh", "main --check")
        self.assertIn("16 GiB of swap", output)
        self.assertFalse((self.root / "swapfile").exists())
        self.assertFalse((self.root / "installed").exists())

    def test_hibernate_skips_low_space_and_unsupported_filesystems(self):
        output = self.run_script("setup-hibernate.sh", "preflight", "df() { printf 'Avail\\n17179869184\\n'; }", False)
        self.assertIn("less than 2 GiB", output)
        output = self.run_script("setup-hibernate.sh", "preflight", "findmnt() { echo btrfs; }", False)
        self.assertIn("filesystem-specific", output)

    def test_hibernate_skips_unsupported_kernel_and_lockdown(self):
        self.write("power-state", "freeze mem\n")
        self.assertIn("does not expose", self.run_script("setup-hibernate.sh", "preflight", success=False))
        self.write("power-state", "freeze mem disk\n")
        self.write("lockdown", "none [integrity] confidentiality\n")
        self.assertIn("lockdown", self.run_script("setup-hibernate.sh", "preflight", success=False))

    def test_hibernate_preserves_existing_small_swapfile(self):
        self.write("swapfile", "do not overwrite")
        self.assertIn("will not be resized", self.run_script("setup-hibernate.sh", "preflight", success=False))
        self.assertEqual((self.root / "swapfile").read_text(), "do not overwrite")

    def test_hibernate_preserves_other_disk_swap(self):
        self.write("swaps", "Filename Type Size Used Priority\n/dev/nvme0n1p3 partition 8388604 0 -2\n")
        self.assertIn("another disk swap", self.run_script("setup-hibernate.sh", "preflight", success=False))
        self.write("swaps", "Filename Type Size Used Priority\n")
        self.write("fstab", "UUID=abcd none swap defaults 0 0\n")
        self.assertIn("even if inactive", self.run_script("setup-hibernate.sh", "preflight", success=False))

    def test_resume_offset_uses_hardware_page_size(self):
        output = self.run_script("setup-hibernate.sh", 'find_resume_args; echo "${RESUME_ARGS}"', """
getconf() { echo 65536; }
sudo() {
  [[ $1 == filefrag && $2 == -b65536 && $3 == -v ]] || exit 88
  echo '0: 0.. 99: 1234.. 1333: 100: last,eof'
}
""")
        self.assertIn("resume=UUID=abcd-1234 resume_offset=1234", output)

    @unittest.skipUnless(shutil.which('filefrag'), 'filefrag is not installed')
    def test_resume_offset_with_real_filefrag(self):
        filesystem = subprocess.check_output(['findmnt', '-no', 'FSTYPE', '-T', str(REPO)], text=True).strip()
        if filesystem != 'ext4':
            self.skipTest('actual swap-file mapping currently supports ext4')
        # /tmp may be tmpfs: use an allocated, synced file on the repo's ext4 FS.
        with tempfile.TemporaryDirectory(prefix='.memory-filefrag-test-', dir=REPO) as directory:
            file = Path(directory) / 'mapping-fixture'
            with file.open('wb') as stream:
                stream.write(b'x' * 131072)
                stream.flush()
                os.fsync(stream.fileno())
            baseline = subprocess.run(['filefrag', '-b1', '-v', str(file)], text=True, capture_output=True, check=True)
            mapping = re.search(r'^\s*0:\s+\S+\s+\S+\s+(\d+)\.\.', baseline.stdout, re.MULTILINE)
            self.assertIsNotNone(mapping, baseline.stdout)
            byte_offset = int(mapping.group(1))
            for page_size in [4096, 65536]:
                with self.subTest(page_size=page_size):
                    output = self.run_script('setup-hibernate.sh', 'find_resume_args; echo "${RESUME_ARGS}"', f'''
SWAPFILE={shlex.quote(str(file))}
getconf() {{ echo {page_size}; }}
sudo() {{ [[ $1 == filefrag ]] || exit 88; "$@"; }}
''')
                    self.assertIn(f'resume_offset={byte_offset // page_size}', output)
                    self.assertNotIn('No such file', output)
                    self.assertNotIn('assuming 1024', output)

    def test_filefrag_failure_rejects_even_partial_mapping_output(self):
        output = self.run_script('setup-hibernate.sh', 'if find_resume_args; then echo UNSAFE_SUCCESS; fi', '''
sudo() {
  [[ $1 == filefrag ]] || exit 88
  echo '0: 0.. 99: 1234.. 1333: 100: last,eof'
  return 1
}
''', False)
        self.assertIn('Cannot map', output)
        self.assertNotIn('UNSAFE_SUCCESS', output)

    def test_swap_activation_failure_does_not_add_fstab_entry(self):
        self.write("swapfile", "existing swap placeholder")
        output = self.run_script("setup-hibernate.sh", 'setup_swapfile', """
swapon() { :; }
sudo() {
  case "$1" in
    blkid) echo swap ;;
    swapon) return 1 ;;
    *) echo 'Unexpected write' >&2; exit 88 ;;
  esac
}
""", False)
        self.assertNotIn("Unexpected write", output)
        self.assertEqual((self.root / "fstab").read_text(), "# fixture\n")

    def test_hibernate_skips_unknown_boot_and_custom_hooks(self):
        self.write("presets/linux.preset", "default_image='/boot/initramfs-linux.img'\n")
        self.assertIn("no supported GRUB", self.run_script("setup-hibernate.sh", "preflight", success=False))
        self.write("mkinitcpio.conf.d/custom.conf", "HOOKS=(base systemd)\n")
        self.assertIn("overrides HOOKS", self.run_script("setup-hibernate.sh", "preflight", success=False))

    def test_hibernate_skips_appended_or_reassigned_hooks(self):
        for extra in ["HOOKS+=(custom)\n", "HOOKS=(\nbase systemd filesystems\n)\n"]:
            with self.subTest(extra=extra):
                text = "HOOKS=(base udev block filesystems fsck)\n" + extra
                self.write("mkinitcpio.conf", text)
                self.assertIn("custom mkinitcpio HOOKS", self.run_script("setup-hibernate.sh", "preflight", success=False))
                self.assertEqual((self.root / "mkinitcpio.conf").read_text(), text)

    def test_hibernate_accepts_grub_and_systemd_initramfs(self):
        self.write("presets/linux.preset", "default_image='/boot/initramfs-linux.img'\n")
        self.write("grub.cfg", "# generated\n")
        self.write("grub-default", 'GRUB_CMDLINE_LINUX_DEFAULT="quiet"\n')
        self.write("mkinitcpio.conf", "HOOKS=(base systemd block sd-encrypt filesystems fsck)\n")
        output = self.run_script("setup-hibernate.sh", "preflight; setup_resume_hook")
        self.assertIn("UKI=0, GRUB=1", output)
        self.assertNotIn("resume", (self.root / "mkinitcpio.conf").read_text())

    def test_resume_hook_follows_unlock_and_precedes_mount(self):
        self.write("mkinitcpio.conf", "HOOKS=(base udev block encrypt filesystems resume fsck)\n")
        self.run_script("setup-hibernate.sh", "preflight; setup_resume_hook", 'sudo() { [[ $1 == sed ]] || exit 88; "$@"; }')
        self.assertEqual((self.root / "mkinitcpio.conf").read_text(), "HOOKS=(base udev block encrypt resume filesystems fsck)\n")

    def test_resume_rewrites_preserve_comments_and_other_boot_arguments(self):
        self.write("cmdline", "# keep this comment\nroot=UUID=abcd resume=UUID=old quiet resume_offset=1\n")
        self.write("grub-default", '# resume=UUID=abcd-1234 resume_offset=42\nGRUB_CMDLINE_LINUX_DEFAULT="resume=UUID=old quiet resume_offset=1"  \n')
        body = 'UPDATE_UKI=1; UPDATE_GRUB=1; RESUME_ARGS="resume=UUID=abcd-1234 resume_offset=42"; setup_uki_cmdline; setup_grub'
        sudo = 'sudo() { case "$1" in sed) "$@";; grub-mkconfig) :;; *) exit 88;; esac; }'
        self.run_script("setup-hibernate.sh", body, sudo)
        cmdline = (self.root / "cmdline").read_text()
        grub = (self.root / "grub-default").read_text()
        self.assertTrue(cmdline.startswith("# keep this comment\nroot=UUID=abcd"))
        self.assertIn("quiet", cmdline)
        self.assertNotIn("UUID=old", cmdline + grub)
        self.assertIn('quiet resume=UUID=abcd-1234 resume_offset=42"', grub)
        self.run_script("setup-hibernate.sh", body, sudo)
        self.assertEqual((self.root / "cmdline").read_text(), cmdline)
        self.assertEqual((self.root / "grub-default").read_text(), grub)

    def test_desktop_keeps_sleep_policy_and_laptop_is_detected(self):
        self.run_script("setup-hibernate.sh", "preflight; setup_logind")
        self.assertFalse((self.root / "installed").exists())
        self.write("power-supplies/BAT0/type", "Battery\n")
        self.assertIn("battery=1", self.run_script("setup-hibernate.sh", "preflight"))


if __name__ == "__main__":
    unittest.main()
