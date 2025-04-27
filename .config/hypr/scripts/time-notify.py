import subprocess
from datetime import datetime

# Get local time
local_time = datetime.now().strftime("%a %b %e %I:%M %p")

# Create the notification message
message = f"{local_time}"

# Send notification
subprocess.run(["notify-send", "-t", "4500", message])
