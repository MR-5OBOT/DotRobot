import subprocess


def download_clip(video_url, start_time, end_time, output_filename):
    try:
        # Get the direct video URL using yt-dlp
        result = subprocess.run(["yt-dlp", "-f", "best", "-g", video_url], capture_output=True, text=True, check=True)
        video_direct_url = result.stdout.strip()

        if not video_direct_url:
            print("Failed to retrieve video URL.")
            return

        # Run ffmpeg to download and trim the video
        subprocess.run(
            ["ffmpeg", "-ss", start_time, "-to", end_time, "-i", video_direct_url, "-c", "copy", output_filename], check=True
        )

        print(f"Clip saved as {output_filename}")
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    print("\nYouTube Clip Downloader\n----------------------")
    video_url = input("Enter YouTube video URL: ")
    start_time = input("Enter start time (hh:mm:ss): ")
    end_time = input("Enter end time (hh:mm:ss): ")
    output_filename = input("Enter output file name (e.g., clip.mp4): ")

    download_clip(video_url, start_time, end_time, output_filename)
