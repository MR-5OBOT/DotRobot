# Alt+Ctrl+H/J/K/L (workflow.conf): move the pane border the way the key points, like tmux
# resize-pane. Kitty's resize_window only grows/shrinks the active pane, so pick grow or
# shrink from whether a pane sits to its right (H/L) or below it (J/K).
from kittens.tui.handler import result_handler

STEP = {'left': 5, 'right': 5, 'up': 2, 'down': 2}  # cells, same as tmux.conf


def main(args: list[str]) -> None:
    pass


def grows(key: str, has_far_neighbor: bool) -> bool:
    # The border that moves is the far one (right/bottom) if it exists, else the near one.
    return (key in ('right', 'down')) == has_far_neighbor


assert grows('left', True) is False and grows('left', False) is True
assert grows('down', True) is True and grows('down', False) is False


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: str, target_window_id: int, boss) -> None:
    tab = boss.active_tab
    key = args[1]
    if tab is None or key not in STEP:
        return
    horizontal = key in ('left', 'right')
    far = tab.neighboring_group_id('right' if horizontal else 'bottom') is not None
    grow = grows(key, far)
    quality = ('wider' if grow else 'narrower') if horizontal else ('taller' if grow else 'shorter')
    tab.resize_window(quality, STEP[key])
