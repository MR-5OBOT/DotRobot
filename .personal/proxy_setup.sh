#!/bin/bash

# Function to display usage
usage() {
	echo "Usage: $0 {set|reset}"
	echo "  set   - Set up proxy using network gateway"
	echo "  reset - Remove proxy settings"
	exit 1
}

# Check if an argument is provided
if [ $# -ne 1 ]; then
	usage
fi

# Proxy setup function
setup_proxy() {
	# Get the gateway IP
	PROXY_IP=$(ip route | grep default | awk '{print $3}')
	PROXY_PORT="8080" # Adjust if your proxy uses a different port

	# Set temporary environment variables
	export http_proxy="http://$PROXY_IP:$PROXY_PORT"
	export https_proxy="http://$PROXY_IP:$PROXY_PORT"
	export HTTP_PROXY="http://$PROXY_IP:$PROXY_PORT"
	export HTTPS_PROXY="http://$PROXY_IP:$PROXY_PORT"

	# Add to /etc/environment if not already present
	if ! grep -q "http_proxy" /etc/environment; then
		echo "Adding proxy settings to /etc/environment"
		sudo bash -c "echo 'http_proxy=\"http://$PROXY_IP:$PROXY_PORT\"' >> /etc/environment"
		sudo bash -c "echo 'https_proxy=\"http://$PROXY_IP:$PROXY_PORT\"' >> /etc/environment"
		sudo bash -c "echo 'HTTP_PROXY=\"http://$PROXY_IP:$PROXY_PORT\"' >> /etc/environment"
		sudo bash -c "echo 'HTTPS_PROXY=\"http://$PROXY_IP:$PROXY_PORT\"' >> /etc/environment"
	fi

	# Add to .zshrc if not already present
	if [ -f ~/.zshrc ] && ! grep -q "http_proxy" ~/.zshrc; then
		echo "Adding proxy settings to ~/.zshrc"
		echo "export http_proxy=\"http://$PROXY_IP:$PROXY_PORT\"" >>~/.zshrc
		echo "export https_proxy=\"http://$PROXY_IP:$PROXY_PORT\"" >>~/.zshrc
		echo "export HTTP_PROXY=\"http://$PROXY_IP:$PROXY_PORT\"" >>~/.zshrc
		echo "export HTTPS_PROXY=\"http://$PROXY_IP:$PROXY_PORT\"" >>~/.zshrc
	fi

	echo "Proxy set to: http://$PROXY_IP:$PROXY_PORT"
	echo "Settings applied to current session, /etc/environment, and ~/.zshrc"
}

# Proxy reset function
reset_proxy() {
	# Unset environment variables from current session
	unset http_proxy
	unset https_proxy
	unset HTTP_PROXY
	unset HTTPS_PROXY

	# Remove proxy settings from /etc/environment
	if grep -q "http_proxy" /etc/environment; then
		echo "Removing proxy settings from /etc/environment"
		sudo sed -i '/http_proxy/d' /etc/environment
		sudo sed -i '/https_proxy/d' /etc/environment
		sudo sed -i '/HTTP_PROXY/d' /etc/environment
		sudo sed -i '/HTTPS_PROXY/d' /etc/environment
	fi

	# Remove proxy settings from .zshrc
	if [ -f ~/.zshrc ] && grep -q "http_proxy" ~/.zshrc; then
		echo "Removing proxy settings from ~/.zshrc"
		sed -i '/http_proxy/d' ~/.zshrc
		sed -i '/https_proxy/d' ~/.zshrc
		sed -i '/HTTP_PROXY/d' ~/.zshrc
		sed -i '/HTTPS_PROXY/d' ~/.zshrc
	fi

	echo "Proxy settings have been removed from current session, /etc/environment, and ~/.zshrc"
}

# Main logic based on argument
case "$1" in
"set")
	setup_proxy
	;;
"reset")
	reset_proxy
	;;
*)
	usage
	;;
esac
