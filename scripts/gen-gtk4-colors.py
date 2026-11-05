#!/usr/bin/env python3
"""Map GTK4's built-in Default-dark colors onto the paradise palette.

The GTK4 theme imports GTK's Default-dark, which hardcodes its colors (no named
colors to override). This pulls every declaration that uses one of them out of
libgtk, remaps it, and writes the result between the markers in
gtk-4.0/gtk.css. Rerun after a GTK4 update.

- Blues -> GTK3 purples: selected-bg #15539e lands exactly on #521C60 and the
  light accent #3584e4 (links) on #a66bb3. Focus rings take #a66bb3.
- Greys -> paradise darks: window #353535 lands on #101010 and buttons #3a3a3a
  on #1d1d1d (GTK3's button fill); lighter greys (dim text) and white stay.
Shades between/around the anchors keep their relative place.
"""
import colorsys, re, subprocess, sys
from pathlib import Path

# (GTK blue, theme purple) pairs, darkest first
BLUE_ANCHORS = [("#15539e", "#521C60"), ("#3584e4", "#a66bb3")]
# (GTK grey, paradise grey) channel values: borders, views, window, buttons, dim text
GREY_ANCHORS = [(0, 0), (0x1b, 0x08), (0x2d, 0x0e), (0x35, 0x10), (0x3a, 0x1d), (0x91, 0x91), (255, 255)]
CSS = Path(__file__).resolve().parent.parent / "dotfiles/.local/share/themes/mr5obot-scheme/gtk-4.0/gtk.css"
BEGIN, END = "/* BEGIN gen-gtk4-colors.py */", "/* END gen-gtk4-colors.py */"
COLOR = re.compile(r"#[0-9a-fA-F]{6}\b|rgba?\(\s*\d+,\s*\d+,\s*\d+(?:,\s*[\d.]+)?\)")


def hls(rgb):
    return colorsys.rgb_to_hls(*(c / 255 for c in rgb))


def parse(s):
    if s.startswith("#"):
        return [int(s[i:i + 2], 16) for i in (1, 3, 5)], None
    nums = re.findall(r"[\d.]+", s)
    return [int(n) for n in nums[:3]], (nums[3] if len(nums) > 3 else None)


def interp(x, pts):
    if x <= pts[0][0]:
        return pts[0][1]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x <= x1:
            return y0 + (x - x0) * (y1 - y0) / (x1 - x0)
    return pts[-1][1]


PTS = [(hls(parse(b)[0]), hls(parse(p)[0])) for b, p in BLUE_ANCHORS]
HS = [(b[1], p[0]) for b, p in PTS]  # source L -> target hue
LS = [(0, 0)] + [(b[1], p[1]) for b, p in PTS] + [(1, 1)]  # source L -> target L
SS = [(b[1], p[2] / b[2]) for b, p in PTS]  # source L -> saturation ratio
GS = [(a / 255, b / 255) for a, b in GREY_ANCHORS]


def remap(s):
    rgb, alpha = parse(s)
    h, l, sat = hls(rgb)
    if sat > 0.1 and 200 < h * 360 < 225:  # blue
        h, l, sat = interp(l, HS), interp(l, LS), min(1, sat * interp(l, SS))
    elif sat <= 0.1:  # grey: lightness only, any faint tint kept
        l = interp(l, GS)
    else:
        return s
    r, g, b = (round(c * 255) for c in colorsys.hls_to_rgb(h, l, sat))
    out = f"rgba({r}, {g}, {b}, {alpha})" if alpha else f"#{r:02x}{g:02x}{b:02x}"
    return s if parse(out) == (rgb, alpha) else out


def changes(text):
    return any(remap(c) != c for c in COLOR.findall(text))


def remapped_rules(css):
    out = []
    for line in css.splitlines():
        if not changes(line):
            continue
        # indented lines continue a multi-line @keyframes: keep them verbatim
        m = re.fullmatch(r"([^@\s{][^{]*)\{(.*)\}\s*", line)
        if m and "url(" not in line:  # plain rule: keep only the remapped declarations
            decls = [d.strip() for d in m.group(2).split(";") if changes(d)]
            line = f"{m.group(1).strip()} {{ {'; '.join(decls)}; }}"
        # Focus rings are the selected colour at 70%; dark purple vanishes on
        # dark grey, so they take the light purple GTK3 also uses for focus.
        out.append(COLOR.sub(lambda m: remap(m.group(0)), line)
                   .replace("outline-color: rgba(82, 28, 96,", "outline-color: rgba(166, 107, 179,"))
    return out


for src, dst in BLUE_ANCHORS + [("#353535", "#101010"), ("#3a3a3a", "#1d1d1d")]:
    assert remap(src).lower() == dst.lower(), (src, remap(src))
for same in ("#26a269", "#000000", "#ffffff", "#919190", "rgba(0, 0, 0, 0.5)"):
    assert remap(same) == same, (same, remap(same))

if __name__ == "__main__":
    lib = next(Path("/usr/lib").glob("libgtk-4.so.1"))
    src = subprocess.run(["gresource", "extract", str(lib), "/org/gtk/libgtk/theme/Default/Default-dark.css"],
                         check=True, capture_output=True, text=True).stdout
    rules = remapped_rules(src)
    text = CSS.read_text()
    head, rest = text.split(BEGIN, 1)
    tail = rest.split(END, 1)[1]
    tmp = CSS.with_suffix(".tmp")
    tmp.write_text(f"{head}{BEGIN}\n" + "\n".join(rules) + f"\n{END}{tail}")
    tmp.replace(CSS)
    print(f"{len(rules)} rules remapped into {CSS}", file=sys.stderr)
