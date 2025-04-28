# simple easy converting for jpg images to png

import os


def format_converter(input: str, output: str) -> None:
    """simle func to convert jpg format to png
    - take absolute path if function runs outside the files dir"""
    os.system(f"ffmpeg {input} {output}")


jpg = input("jpg path: ")
png = input("png path: ")

format_converter(jpg, png)
print(f"Done: {jpg}, is now converted to {png}")
