import os

import yt_dlp


def download_yt_trimmed(video_url, start_time, end_time):
    # Convert times to seconds if they're in "MM:SS" format
    if ":" in start_time:
        start_min, start_sec = map(int, start_time.split(":"))
        start_seconds = start_min * 60 + start_sec
    else:
        start_seconds = int(start_time)

    if ":" in end_time:
        end_min, end_sec = map(int, end_time.split(":"))
        end_seconds = end_min * 60 + end_sec
    else:
        end_seconds = int(end_time)

    # Calculate duration
    duration = end_seconds - start_seconds

    # yt-dlp options
    ydl_opts = {
        "format": "bestvideo+bestaudio/best",  # Download best quality
        "outtmpl": "%(title)s_trimmed.%(ext)s",  # Output filename
        "postprocessors": [
            {
                "key": "FFmpegExtractAudio",  # Use FFmpeg to trim
                "preferredcodec": "mp4",
            }
        ],
        "postprocessor_args": ["-ss", str(start_seconds), "-t", str(duration)],  # Start time  # Duration
        "merge_output_format": "mp4",  # Ensure output is in mp4 format
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            print(f"Downloading trimmed video from {start_time} to {end_time}...")
            ydl.download([video_url])
            print("Download completed!")
    except Exception as e:
        print(f"An error occurred: {str(e)}")


# Example usage
video_url = input("Enter YouTube video URL: ")
start = input("Enter start time (in seconds or MM:SS format): ")
end = input("Enter end time (in seconds or MM:SS format): ")

download_yt_trimmed(video_url, start, end)
