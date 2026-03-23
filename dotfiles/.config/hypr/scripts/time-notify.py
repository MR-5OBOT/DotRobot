import subprocess
from datetime import datetime

# Get local time
local_time = datetime.now().strftime("%a %b %e %I:%M %p")

# Create the notification message
message = f"{local_time}"

# Send notification with title and body
subprocess.run(["notify-send", "-t", "4500", "🕐 Current Time", message])
