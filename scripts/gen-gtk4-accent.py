#!/usr/bin/env python3
"""Recolor GTK4's built-in Default-dark blues to the theme purple.

The GTK4 theme imports GTK's Default-dark, which hardcodes ~30 shades of its
#15539e blue (no named colors to override). This pulls every declaration that
uses one of them out of libgtk and maps it onto the GTK3 purples: GTK's
selected-bg #15539e lands exactly on ACCENT and its light accent #3584e4 (links,
focus text) on ACCENT_LIGHT; the shades between/around keep their relative
place. The result goes between the markers in gtk-4.0/gtk.css. Rerun after a
GTK4 update.
"""
import colorsys, re, subprocess, sys
from pathlib import Path

# (GTK blue, theme purple) pairs, darkest first
ANCHORS = [("#15539e", "#521C60"), ("#3584e4", "#a66bb3")]
CSS = Path(__file__).resolve().parent.parent / "dotfiles/.local/share/themes/mr5obot-scheme/gtk-4.0/gtk.css"
BEGIN, END = "/* BEGIN gen-gtk4-accent.py */", "/* END gen-gtk4-accent.py */"
COLOR = re.compile(r"#[0-9a-fA-F]{6}\b|rgba?\(\s*\d+,\s*\d+,\s*\d+(?:,\s*[\d.]+)?\)")


def hls(rgb):
    return colorsys.rgb_to_hls(*(c / 255 for c in rgb))


def parse(s):
    if s.startswith("#"):
        return [int(s[i:i + 2], 16) for i in (1, 3, 5)], None
    nums = re.findall(r"[\d.]+", s)
    return [int(n) for n in nums[:3]], (nums[3] if len(nums) > 3 else None)


def is_blue(s):
    h, _, sat = hls(parse(s)[0])
    return sat > 0.1 and 200 < h * 360 < 225


PTS = [(hls(parse(b)[0]), hls(parse(p)[0])) for b, p in ANCHORS]
HS = [(b[1], p[0]) for b, p in PTS]  # source L -> target hue
LS = [(0, 0)] + [(b[1], p[1]) for b, p in PTS] + [(1, 1)]  # source L -> target L
SS = [(b[1], p[2] / b[2]) for b, p in PTS]  # source L -> saturation ratio


def interp(x, pts):
    if x <= pts[0][0]:
        return pts[0][1]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x <= x1:
            return y0 + (x - x0) * (y1 - y0) / (x1 - x0)
    return pts[-1][1]


def recolor(m):
    s = m.group(0)
    if not is_blue(s):
        return s
    rgb, alpha = parse(s)
    _, l, sat = hls(rgb)
    r, g, b = (round(c * 255) for c in colorsys.hls_to_rgb(interp(l, HS), interp(l, LS), min(1, sat * interp(l, SS))))
    return f"rgba({r}, {g}, {b}, {alpha})" if alpha else f"#{r:02x}{g:02x}{b:02x}"


def blue_rules(css):
    out = []
    for line in css.splitlines():
        if not any(is_blue(c) for c in COLOR.findall(line)):
            continue
        # indented lines continue a multi-line @keyframes: keep them verbatim
        m = re.fullmatch(r"([^@\s{][^{]*)\{(.*)\}\s*", line)
        if m and "url(" not in line:  # plain rule: keep only the blue declarations
            decls = [d.strip() for d in m.group(2).split(";")
                     if any(is_blue(c) for c in COLOR.findall(d))]
            line = f"{m.group(1).strip()} {{ {'; '.join(decls)}; }}"
        out.append(COLOR.sub(recolor, line))
    return out


for blue, purple in ANCHORS:
    assert COLOR.sub(recolor, blue).lower() == purple.lower(), (blue, COLOR.sub(recolor, blue))
assert COLOR.sub(recolor, "#26a269") == "#26a269"  # success green untouched

if __name__ == "__main__":
    lib = next(Path("/usr/lib").glob("libgtk-4.so.1"))
    src = subprocess.run(["gresource", "extract", str(lib), "/org/gtk/libgtk/theme/Default/Default-dark.css"],
                         check=True, capture_output=True, text=True).stdout
    rules = blue_rules(src)
    text = CSS.read_text()
    head, rest = text.split(BEGIN, 1)
    tail = rest.split(END, 1)[1]
    tmp = CSS.with_suffix(".tmp")
    tmp.write_text(f"{head}{BEGIN}\n" + "\n".join(rules) + f"\n{END}{tail}")
    tmp.replace(CSS)
    print(f"{len(rules)} rules recolored into {CSS}", file=sys.stderr)
