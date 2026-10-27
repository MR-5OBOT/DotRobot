#!/usr/bin/env python3
"""
Generate the island accent from a wallpaper (or a manual hue) for Quickshell.
One histogram pass yields both the area-dominant chromatic hue (binned by hue
family so a small vivid accent never hijacks the theme) and the mean lightness.
The mean lightness picks the accent's light/dark ramp so it contrasts the pill;
the dominant hue tints it in HSL. An achromatic wallpaper drops to a neutral
accent. Surfaces and text stay fixed in Theme.qml; only the accent breathes.
"""
import colorsys
import json
import os
import re
import subprocess
import sys
from pathlib import Path

CACHE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "island"


def analyze(wallpaper):
    out = subprocess.run(
        ["magick", wallpaper, "-alpha", "off", "-resize", "200x200", "-colors", "48",
         "-format", "%c", "histogram:info:-"],
        capture_output=True, text=True).stdout
    buckets, total, lum, chroma = {}, 0, 0.0, 0
    for line in out.splitlines():
        m = re.search(r"\s*(\d+):\s*\([^)]*\)\s*#([0-9A-Fa-f]{6})", line)
        if not m:
            continue
        count, hex_str = int(m.group(1)), m.group(2)
        r, g, b = (int(hex_str[i:i + 2], 16) / 255 for i in (0, 2, 4))
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        total += count
        lum += count * l
        if s < 0.15 or l < 0.05 or l > 0.92:
            continue
        chroma += count
        bucket = buckets.setdefault((int(h * 360) // 30) % 12, {"wsat": 0.0, "best": None})
        bucket["wsat"] += count * s
        score = count * s * (1 if 0.12 < l < 0.55 else 0.4)
        if not bucket["best"] or score > bucket["best"][0]:
            bucket["best"] = (score, h, s)
    mean_l = lum / total if total else 0.0
    if not buckets or chroma < 0.08 * total:
        return None, 0.0, mean_l
    win = max(buckets.values(), key=lambda v: v["wsat"])
    return win["best"][1], win["best"][2], mean_l


def tint(hue, sat, light):
    r, g, b = colorsys.hls_to_rgb(hue % 1.0, max(0.0, min(1.0, light)), max(0.0, min(1.0, sat)))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def main():
    if len(sys.argv) < 2:
        return 1
    if sys.argv[1] == "--hue":
        hue = (float(sys.argv[2]) % 360) / 360.0
        mode = sys.argv[3] if len(sys.argv) > 3 else "dark"
        sat = float(sys.argv[4]) if len(sys.argv) > 4 else 0.5
        sat = max(0.0, min(1.0, sat))
        mean_l = 0.85 if mode == "light" else 0.12
        chromatic = sat > 0.02
    else:
        wallpaper = sys.argv[1]
        if not Path(wallpaper).is_file():
            return 0
        hue, sat, mean_l = analyze(wallpaper)
        chromatic = hue is not None
        if not chromatic:
            hue, sat = 0.09, 0.0
    CACHE.mkdir(parents=True, exist_ok=True)

    light = mean_l >= 0.40
    acc_sat = (min(sat + 0.18, 0.85) if light else min(max(sat, 0.30) + 0.12, 0.82)) if chromatic else 0.05
    acc_l, deep_l, glow_l = (0.42, 0.30, 0.55) if light else (0.70, 0.34, 0.86)

    accent = {
        "primary": tint(hue, acc_sat, acc_l),
        "primary_container": tint(hue, min(acc_sat + 0.08, 0.9), deep_l),
        "on_primary_container": tint(hue, min(acc_sat, 0.45), glow_l),
    }
    (CACHE / "colors.json").write_text(json.dumps(accent, indent=2) + "\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
