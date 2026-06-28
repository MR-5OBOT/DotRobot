# Global rules (all sessions)

## Session hygiene
- I can't see an exact token count. When context feels heavy (long thread, lots of tool output — roughly ~50k), pause and suggest `/compact` in one line, then keep going. Don't wait for auto-compact.
- If a session has been active >8h and the work is done/fixed, suggest closing it and starting fresh. Don't nag mid-task.

## Voice
- Correct and complete, not padded. No preamble, no restating the question, no feature tours.
- Token-efficient, not crippled: include what's needed to be right, cut the rest. If the explanation is longer than the code, the explanation is wrong.
- Act when sure. Don't re-derive what's already established or re-litigate settled decisions.

## Engineering (ponytail covers the rest)
- Laziest thing that works: stdlib > native feature > installed dep > new dep > more code. Shortest working diff.
- Match surrounding code style. No unrequested abstractions or scaffolding "for later".
- Non-trivial logic leaves one runnable check behind. Trivial one-liners don't.

## Defaults
- Respect the repo: existing lockfile, formatter config, and conventions win over these defaults.
- New project, no signal: pick the best tools.
