#!/usr/bin/env python3
"""Save a dropped image file or HTTP(S) image URL into the wallpaper folder."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import unquote, urlsplit


IMAGE_TYPES = {
    ".png": {"image/png"},
    ".jpg": {"image/jpeg"},
    ".jpeg": {"image/jpeg"},
    ".webp": {"image/webp"},
    ".gif": {"image/gif"},
    ".bmp": {"image/bmp", "image/x-ms-bmp"},
}


def save_wallpaper(source, folder):
    url = urlsplit(source)
    if url.scheme not in ("", "file", "http", "https"):
        raise ValueError("Drop an image file or an HTTP(S) image link")
    if url.scheme == "file" and url.netloc not in ("", "localhost"):
        raise ValueError("Only local file links are supported")
    remote = url.scheme in ("http", "https")
    path = Path(unquote(url.path) if url.scheme else source)
    if path.suffix.lower() not in IMAGE_TYPES:
        raise ValueError("Only PNG, JPEG, WebP, GIF and BMP wallpapers are accepted")
    if not remote and not path.is_file():
        raise ValueError("The dropped image file does not exist")

    folder = Path(folder).expanduser()
    folder.mkdir(parents=True, exist_ok=True)
    destination = folder / path.name
    # Stage first; failed downloads and name collisions must not damage a wallpaper.
    with tempfile.NamedTemporaryFile(dir=folder, prefix=".wallpaper-drop-") as staged:
        if remote:
            subprocess.run([
                "curl", "--fail", "--location", "--silent", "--show-error",
                "--proto", "=http,https", "--proto-redir", "=http,https",
                "--max-time", "60", "--output", staged.name, "--", source,
            ], check=True, capture_output=True)
        else:
            with path.open("rb") as image:
                shutil.copyfileobj(image, staged)
            staged.flush()
        mime = subprocess.check_output(
            ["file", "--brief", "--mime-type", "--", staged.name], text=True
        ).strip()
        if mime not in IMAGE_TYPES[path.suffix.lower()]:
            raise ValueError("The dropped file is not a supported image")
        if not remote and destination.exists() and path.samefile(destination):
            return destination
        number = 1
        while True:
            try:
                os.link(staged.name, destination)
                return destination
            except FileExistsError:
                number += 1
                destination = folder / f"{path.stem}-{number}{path.suffix}"


if __name__ == "__main__":
    try:
        if len(sys.argv) != 3:
            raise ValueError("usage: wallpaper-drop.py <image-path-or-url> <wallpaper-folder>")
        print(save_wallpaper(sys.argv[1], sys.argv[2]))
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        message = (error.stderr.decode(errors="replace").strip()
                   if isinstance(error, subprocess.CalledProcessError) and error.stderr
                   else str(error))
        print(message, file=sys.stderr)
        sys.exit(1)
