#!/usr/bin/env bash
# Claude Code status line, styled after ~/.config/zsh/starship.toml (mono, color only for warnings).
# One line: directory, git branch + status, python venv, model + effort,
# session (5h) and weekly usage bars.
#
# Greys come from the fixed 256-color ramp (232-255), so the kitty theme's
# color8 (#333333 in black.ini) can't make labels unreadable.
# Nerd Font glyphs are byte escapes so editors/tools can't strip them.

input=$(cat)

B=$'\e[1;38;5;255m'   # directory
V=$'\e[38;5;252m'     # values
L=$'\e[38;5;245m'     # labels, secondary info
K=$'\e[38;5;238m'     # empty bar track
Y=$'\e[38;5;179m'     # >= 70%
R=$'\e[38;5;167m'     # >= 90%
N=$'\e[0m'
SEP='   '

ICON_BRANCH=$'\xee\x82\xa0'   # U+E0A0

# One jq call; \x1f (non-whitespace) keeps empty fields from collapsing in read.
IFS=$'\x1f' read -r dir model effort fast rl5_pct rl5_reset rl7_pct < <(
  jq -r '[
    .workspace.current_dir // .cwd // "",
    .model.display_name // "",
    .effort.level // "",
    .fast_mode // false,
    .rate_limits.five_hour.used_percentage // "",
    .rate_limits.five_hour.resets_at // "",
    .rate_limits.seven_day.used_percentage // ""
  ] | map(tostring) | join("")' <<<"$input"
)

# seconds -> 42s, 3m05s, 2h10m, 3d04h
dur() {
  local s=$(( $1 > 0 ? $1 : 0 ))
  if (( s >= 86400 )); then printf '%dd%02dh' $((s / 86400)) $((s % 86400 / 3600))
  elif (( s >= 3600 )); then printf '%dh%02dm' $((s / 3600)) $((s % 3600 / 60))
  elif (( s >= 60 )); then printf '%dm%02ds' $((s / 60)) $((s % 60))
  else printf '%ds' "$s"
  fi
}

# meter LABEL PERCENT [NOTE] -> "session ━━━━━━━━ 43% resets in 3h34m"
meter() {
  local p c=$V w=8 f on off out
  printf -v p '%.0f' "$2"
  if (( p >= 90 )); then c=$R; elif (( p >= 70 )); then c=$Y; fi
  f=$(( (p * w + 50) / 100 ))
  (( p > 0 && f == 0 )) && f=1
  (( f > w )) && f=$w
  printf -v on '%*s' "$f" '';           on=${on// /━}
  printf -v off '%*s' $(( w - f )) '';  off=${off// /━}
  out="${L}$1${N} ${c}${on}${K}${off}${N} ${c}${p}%${N}"
  [[ -n $3 ]] && out+=" ${L}$3${N}"
  printf '%s' "$out"
}

printf -v now '%(%s)T' -1

path=${dir/#$HOME/\~}
IFS=/ read -ra parts <<<"$path"
if (( ${#parts[@]} > 4 )); then
  tail=("${parts[@]: -4}")
  path="…/$(IFS=/; printf '%s' "${tail[*]}")"
fi
line="${B}${path}${N}"

if [[ -n $dir ]] && gs=$(git -C "$dir" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null); then
  branch='' oid='' ahead=0 behind=0 staged=0 modified=0 deleted=0 untracked=0 conflicted=0
  while IFS= read -r l; do
    case $l in
      '# branch.oid '*)  oid=${l#'# branch.oid '} ;;
      '# branch.head '*) branch=${l#'# branch.head '} ;;
      '# branch.ab '*)   read -r _ _ a b <<<"$l"; ahead=${a#+}; behind=${b#-} ;;
      [12]' '*)
        [[ ${l:2:1} != . ]] && ((staged++))
        case ${l:3:1} in D) ((deleted++)) ;; .) ;; *) ((modified++)) ;; esac ;;
      'u '*) ((conflicted++)) ;;
      '? '*) ((untracked++)) ;;
    esac
  done <<<"$gs"
  [[ $branch == '(detached)' ]] && branch=${oid:0:7}

  st=''
  (( conflicted )) && st+=" =$conflicted"
  (( staged ))     && st+=" +$staged"
  (( modified ))   && st+=" ~$modified"
  (( deleted ))    && st+=" ×$deleted"
  (( untracked ))  && st+=" ?$untracked"
  (( ahead ))      && st+=" ↑$ahead"
  (( behind ))     && st+=" ↓$behind"
  line+="${SEP}${L}${ICON_BRANCH}${N} ${V}${branch}${N}${L}${st}${N}"
fi

[[ -n $VIRTUAL_ENV ]] && line+="${SEP}${L}λ ${V}${VIRTUAL_ENV##*/}${N}"

if [[ -n $model ]]; then
  line+="${SEP}${V}${model}${N}"
  [[ -n $effort ]] && line+="${SEP}${L}effort ${V}${effort}${N}"
  [[ $fast == true ]] && line+=" ${Y}fast${N}"
fi

[[ -n $rl5_pct ]] && line+="${SEP}$(meter session "$rl5_pct" "${rl5_reset:+resets in $(dur $((rl5_reset - now)))}")"
[[ -n $rl7_pct ]] && line+="${SEP}$(meter week "$rl7_pct")"

printf '%s' "$line"
