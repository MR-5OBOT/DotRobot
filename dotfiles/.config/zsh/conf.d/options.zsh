# History and shell options.

# ---------- History ----------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# ---------- Navigation & globbing ----------
setopt AUTO_CD
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt COMPLETE_ALIASES
setopt EXTENDED_GLOB
setopt NUMERIC_GLOB_SORT   # sort file10 after file9, not after file1
setopt NOBEEP
