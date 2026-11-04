#!/usr/bin/env python3
"""tmux-resurrect post-save-layout hook: strip the float.sh scratchpad from a save file.

While the float is open a save holds three pieces of it:
  - the hidden "floating" session itself
  - the floating view pane inside the current window ("z" key in the JSON layout)
  - the backing window, linked into the parent session (shares pane ids with "floating")
Restoring those gives a fake float, a stray [tmux] window and a client stuck in "floating".
"""
import json, os, re, sys

FLOAT = re.compile(r'^floating(-\d+)?$')  # floating-N: older float.sh session names


def pane_ids(node):
    ids = {node['I']} if 'I' in node else set()
    for k in node.get('c', []):
        ids |= pane_ids(k)
    return ids


def drop_floats(node, gone):
    """Remove floating panes from a layout node; collect their pane indexes in gone."""
    if 'c' not in node:
        return node
    kept = []
    for k in node['c']:
        if 'z' in k:
            gone.add(str(k['i']))
        else:
            kept.append(drop_floats(k, gone))
    if len(kept) == 1:  # container left with one child: that child fills it
        kept[0].update({key: node[key] for key in ('w', 'h', 'x', 'y')})
        return kept[0]
    node['c'] = kept
    return node


def clean(text):
    rows = [line.split('\t') for line in text.splitlines()]
    is_win = lambda r: r[0] == 'window' and len(r) > 6 and r[6].startswith('{')

    float_ids = set()
    for r in rows:
        if is_win(r) and FLOAT.match(r[1]):
            float_ids |= pane_ids(json.loads(r[6])['L'])

    dead = set()  # (session, window) or (session, window, pane_index)
    for r in rows:
        if not is_win(r) or FLOAT.match(r[1]):
            continue
        lay = json.loads(r[6])
        if pane_ids(lay['L']) & float_ids:
            dead.add((r[1], r[2]))
            continue
        gone = set()
        lay['L'] = drop_floats(lay['L'], gone)
        dead |= {(r[1], r[2], i) for i in gone}
        r[6] = json.dumps(lay, separators=(',', ':'), ensure_ascii=False)

    out = []
    for r in rows:
        if r[0] == 'state':
            out.append([x if not FLOAT.match(x) else '' for x in r])
        elif len(r) > 1 and FLOAT.match(r[1]):
            continue
        elif r[0] in ('pane', 'window') and (r[1], r[2]) in dead:
            continue
        elif r[0] == 'pane' and (r[1], r[2], r[5]) in dead:
            continue
        else:
            out.append(r)
    return ''.join('\t'.join(r) + '\n' for r in out)


def test():
    sample = '\n'.join([
        'pane\t0\t1\t1\t:*\t1\tt\t:/h\t0\tcodex\t:codex',
        'pane\t0\t1\t1\t:*\t2\tt\t:/h\t0\tclaude\t:claude',
        'pane\t0\t1\t1\t:*\t3\tt\t:/h\t1\tsh\t:tmux attach-session -t =floating',
        'pane\t0\t2\t0\t:\t1\tt\t:/h\t1\tzsh\t:',
        'pane\tfloating\t1\t1\t:*\t1\tt\t:/h\t1\tzsh\t:',
        'window\t0\t1\t:sh\t1\t:*\t{"V":2,"L":{"t":"h","w":237,"h":51,"x":0,"y":0,"c":['
        '{"t":"p","w":118,"h":51,"x":0,"y":0,"i":1,"I":"%1"},'
        '{"t":"p","w":118,"h":51,"x":119,"y":0,"i":2,"I":"%2"},'
        '{"t":"p","w":159,"h":38,"x":38,"y":6,"a":true,"i":3,"z":0,"I":"%12"}]}}\t:',
        'window\t0\t2\t:[tmux]\t0\t:\t{"V":2,"L":{"t":"p","w":159,"h":38,"x":0,"y":0,"i":1,"I":"%13"}}\t:',
        'window\tfloating\t1\t:[tmux]\t1\t:*\t{"V":2,"L":{"t":"p","w":159,"h":38,"x":0,"y":0,"i":1,"I":"%13"}}\t:',
        'state\tfloating\t0',
    ])
    got = clean(sample).splitlines()
    assert [l.split('\t')[:3] for l in got] == [
        ['pane', '0', '1'], ['pane', '0', '1'], ['window', '0', '1'], ['state', '', '0']], got
    assert '"z"' not in got[2] and '%12' not in got[2], got[2]
    # one tiled pane + float collapses to the bare pane
    one = 'window\t0\t1\t:a\t1\t:*\t{"V":2,"L":{"t":"h","w":9,"h":9,"x":0,"y":0,"c":[' \
          '{"t":"p","w":9,"h":9,"x":0,"y":0,"i":1,"I":"%1"},{"t":"p","w":5,"h":5,"x":2,"y":2,"i":2,"z":0,"I":"%2"}]}}\t:'
    assert json.loads(clean(one).split('\t')[6])['L'] == {"t": "p", "w": 9, "h": 9, "x": 0, "y": 0, "i": 1, "I": "%1"}
    print('ok')


if __name__ == '__main__':
    if sys.argv[1:] == ['--test']:
        test()
        sys.exit()
    path = sys.argv[1]
    with open(path, encoding='utf-8', errors='surrogateescape') as f:
        new = clean(f.read())
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8', errors='surrogateescape') as f:
        f.write(new)
    os.replace(tmp, path)  # atomic: a crash above leaves the original save intact
