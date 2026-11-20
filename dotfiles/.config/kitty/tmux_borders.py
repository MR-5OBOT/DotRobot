# Watcher kitty runs inside its own process (workflow.conf: watcher): with exactly two panes,
# colour only half the divider like tmux does, top/left half = first pane focused,
# bottom/right half = second. Three or more panes keep kitty's per-pane edge colouring.
# shortcut: patches kitty's internal Splits.minimal_borders; if a kitty update breaks the
# imports or the checks below, kitty logs it and keeps its stock full-length border.
from kitty.borders import BorderColor
from kitty.layout.base import BorderLine
from kitty.layout.splits import Splits
from kitty.types import Edges

_stock = Splits.minimal_borders


def halve(lines: list[BorderLine]) -> list[BorderLine]:
    active = [b for b in lines if b.color == BorderColor.active]
    if not active:
        return lines
    # Edges is (left, top, right, bottom); a divider between side-by-side panes runs along y.
    a, z, side = (0, 2, 1) if lines[0].horizontal else (1, 3, 0)
    mid = (min(b.edges[a] for b in lines) + max(b.edges[z] for b in lines)) // 2
    # The divider is 1px from each pane; the left/top pane's is the one nearer the origin.
    first = active[0].edges[side] == min(b.edges[side] for b in lines)
    out = []
    for b in lines:
        off = BorderColor.inactive if b.color == BorderColor.active else b.color  # keeps bell
        for s, t, on in ((b.edges[a], min(b.edges[z], mid), first), (max(b.edges[a], mid), b.edges[z], not first)):
            if s < t:
                e = list(b.edges)
                e[a], e[z] = s, t
                out.append(b._replace(edges=Edges(*e), color=BorderColor.active if on else off))
    return out


def _minimal_borders(self, windows):  # type: ignore[no-untyped-def]
    lines = list(_stock(self, windows))
    return halve(lines) if sum(1 for _ in windows.iter_all_layoutable_groups()) == 2 else lines


# Side by side, left focused: both 1px columns purple on the top half only.
_l = BorderLine(Edges(100, 0, 101, 50), BorderColor.active, 1, False)
_r = BorderLine(Edges(101, 0, 102, 50), BorderColor.inactive, -2, False)
assert [(b.edges, b.color) for b in halve([_l, _r])] == [
    (Edges(100, 0, 101, 25), BorderColor.active), (Edges(100, 25, 101, 50), BorderColor.inactive),
    (Edges(101, 0, 102, 25), BorderColor.active), (Edges(101, 25, 102, 50), BorderColor.inactive)]
# Stacked, bottom focused: right half purple.
_t = BorderLine(Edges(0, 40, 80, 41), BorderColor.inactive, 1, True)
_b = BorderLine(Edges(0, 41, 80, 42), BorderColor.active, -2, True)
assert [b.color for b in halve([_t, _b])] == [BorderColor.inactive, BorderColor.active] * 2
assert halve([_t]) == [_t]  # nothing focused: untouched

# Patch only once the checks above pass, so a kitty update that breaks them leaves stock borders.
Splits.minimal_borders = _minimal_borders
