import os
import sys
import json
import time
import hashlib
import fcntl
import subprocess
import urllib.parse
from concurrent.futures import ThreadPoolExecutor

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

def get_dir_hash(path):
    return hashlib.sha256(os.path.abspath(path).encode("utf-8")).hexdigest()[:16]

def get_color_bucket(hex_str):
    if not hex_str:
        return "Monochrome"
    hex_str = str(hex_str).strip().replace("#", "")
    if len(hex_str) > 6:
        hex_str = hex_str[:6]
    if len(hex_str) != 6:
        return "Monochrome"
    try:
        r = int(hex_str[0:2], 16) / 255.0
        g = int(hex_str[2:4], 16) / 255.0
        b = int(hex_str[4:6], 16) / 255.0
    except ValueError:
        return "Monochrome"

    mx = max(r, g, b)
    mn = min(r, g, b)
    d = mx - mn
    h = 0.0
    s = 0.0 if mx == 0 else d / mx
    v = mx

    if mx != mn:
        if mx == r:
            h = (g - b) / d + (6.0 if g < b else 0.0)
        elif mx == g:
            h = (b - r) / d + 2.0
        else:
            h = (r - g) / d + 4.0
        h /= 6.0
    h *= 360.0

    if s < 0.05 or v < 0.08:
        return "Monochrome"
    if h >= 345 or h < 15:
        return "Red"
    if 15 <= h < 45:
        return "Orange"
    if 45 <= h < 75:
        return "Yellow"
    if 75 <= h < 165:
        return "Green"
    if 165 <= h < 260:
        return "Blue"
    if 260 <= h < 315:
        return "Purple"
    if 315 <= h < 345:
        return "Pink"
    return "Monochrome"

def extract_color(filepath):
    if HAS_PIL:
        try:
            with Image.open(filepath) as im:
                im = im.convert("RGB").resize((1, 1), Image.Resampling.BOX)
                r, g, b = im.getpixel((0, 0))
                return f"#{r:02x}{g:02x}{b:02x}"
        except Exception:
            pass
    for cmd in ["magick", "convert"]:
        try:
            out = subprocess.check_output(
                [cmd, f"{filepath}[0]", "-resize", "1x1!", "-format", "%[hex:p{0,0}]", "info:-"],
                stderr=subprocess.DEVNULL,
                timeout=5
            ).decode("utf-8").strip()
            if len(out) >= 6:
                return f"#{out[:6]}"
        except Exception:
            continue
    return "#808080"

def process_entry(entry_tuple, cached_items):
    fname, fpath, mtime, size = entry_tuple
    existing = cached_items.get(fname)
    if existing and existing.get("mtime") == mtime and existing.get("size") == size:
        return existing
    hex_color = extract_color(fpath)
    return {
        "fileName": fname,
        "filePath": fpath,
        "fileUrl": f"file://{fpath}",
        "hex": hex_color,
        "bucket": get_color_bucket(hex_color),
        "mtime": mtime,
        "size": size
    }

def run_indexing(src_dir, per_dir_cache, index_file):
    os.makedirs(per_dir_cache, exist_ok=True)

    cached_items = {}
    if os.path.exists(index_file):
        try:
            with open(index_file, "r") as f:
                old_data = json.load(f)
                for item in old_data.get("items", []):
                    if item.get("fileName"):
                        cached_items[item.get("fileName")] = item
        except Exception:
            cached_items = {}

    img_exts = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp"}

    entries_to_process = []
    seen_entry_names = set()
    seen_entry_paths = set()
    try:
        dir_entries = list(os.scandir(src_dir))
    except Exception:
        dir_entries = []

    for entry in dir_entries:
        try:
            if not entry.is_file():
                continue
        except OSError:
            continue

        fname = entry.name
        if fname in seen_entry_names:
            continue

        ext = os.path.splitext(fname)[1].lower()
        if ext not in img_exts:
            continue

        try:
            real_path = os.path.realpath(entry.path)
            if real_path in seen_entry_paths:
                continue
            st = entry.stat()
            mtime = int(st.st_mtime)
            size = int(st.st_size)
        except Exception:
            continue

        seen_entry_names.add(fname)
        seen_entry_paths.add(real_path)
        fpath = os.path.abspath(entry.path)
        entries_to_process.append((fname, fpath, mtime, size))

    workers = min(12, max(4, os.cpu_count() or 4))
    items_map = {}
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [executor.submit(process_entry, item, cached_items) for item in entries_to_process]
        for f in futures:
            try:
                res = f.result()
                if res and res.get("fileName") and res.get("filePath"):
                    fn = res["fileName"]
                    if fn not in items_map:
                        items_map[fn] = res
            except Exception:
                pass

    items = [items_map[k] for k in sorted(items_map.keys())]

    output_data = {
        "srcDir": os.path.abspath(src_dir),
        "dirHash": get_dir_hash(src_dir),
        "updatedAt": int(time.time()),
        "items": items
    }

    tmp_index = f"{index_file}.tmp"
    with open(tmp_index, "w") as f:
        json.dump(output_data, f, indent=2)
    os.replace(tmp_index, index_file)

    current_symlink = os.path.join(os.path.dirname(os.path.dirname(per_dir_cache)), "current_index.json")
    tmp_symlink = f"{current_symlink}.tmp"
    with open(tmp_symlink, "w") as f:
        json.dump(output_data, f)
    os.replace(tmp_symlink, current_symlink)

    return output_data

def main():
    if len(sys.argv) < 2:
        return
    src_dir = sys.argv[1]
    if src_dir.startswith("file://"):
        src_dir = urllib.parse.unquote(src_dir[7:])
    cache_dir = sys.argv[2] if len(sys.argv) > 2 else "/tmp"
    run_dir = sys.argv[3] if len(sys.argv) > 3 else cache_dir

    os.makedirs(cache_dir, exist_ok=True)
    os.makedirs(run_dir, exist_ok=True)

    dir_hash = get_dir_hash(src_dir)
    per_dir_cache = os.path.join(cache_dir, "dirs", dir_hash)
    index_file = os.path.join(per_dir_cache, "index.json")

    dirty_file = os.path.join(run_dir, f"indexer_{dir_hash}.dirty")
    lock_file = os.path.join(run_dir, f"indexer_{dir_hash}.lock")

    with open(lock_file, "w") as lock_fd:
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except (BlockingIOError, OSError):
            with open(dirty_file, "w") as df:
                df.write("1")
            if os.path.exists(index_file):
                try:
                    with open(index_file, "r") as f:
                        sys.stdout.write(f.read())
                        sys.stdout.flush()
                except Exception:
                    pass
            sys.exit(0)

        result_data = None
        while True:
            if os.path.exists(dirty_file):
                try:
                    os.remove(dirty_file)
                except OSError:
                    pass
            result_data = run_indexing(src_dir, per_dir_cache, index_file)
            if not os.path.exists(dirty_file):
                break

        if result_data:
            sys.stdout.write(json.dumps(result_data))
            sys.stdout.flush()

if __name__ == "__main__":
    main()
