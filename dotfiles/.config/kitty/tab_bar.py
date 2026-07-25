# Custom kitty tab bar: flat separator tabs plus a right-aligned clock.
#
# NOTE: kitty imports this module once at startup. Editing it needs a full
# kitty restart -- `load_config_file` only re-reads kitty.conf.
#
# kitty has no built-in right-hand status (tab_title_template only renders
# inside a tab), so the clock tmux used to show has to be drawn here. Loaded
# because kitty.conf sets `tab_bar_style custom`.

from datetime import datetime

from kitty.boss import get_boss
from kitty.fast_data_types import Screen, add_timer
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_tab_with_separator
from kitty.utils import color_as_int

CLOCK_FG = 0x505050
BG = 0x000000

_timer_started = False


def _redraw(_timer_id: int | None = None) -> None:
    # The tab bar only repaints on tab events, so the clock needs its own tick.
    boss = get_boss()
    for tm in getattr(boss, "os_window_map", {}).values():
        tm.mark_tab_bar_dirty()


def _start_timer() -> None:
    global _timer_started
    if not _timer_started:
        _timer_started = True
        add_timer(_redraw, 30.0, True)


def _draw_clock(screen: Screen) -> None:
    text = datetime.now().strftime(" %H:%M ")
    free = screen.columns - screen.cursor.x
    if free < len(text):
        return
    screen.cursor.x = screen.columns - len(text)
    screen.cursor.fg = as_rgb(CLOCK_FG)
    screen.cursor.bg = as_rgb(BG)
    screen.cursor.bold = False
    screen.draw(text)


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    _start_timer()
    end = draw_tab_with_separator(
        draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data
    )
    if is_last:
        _draw_clock(screen)
    return end
