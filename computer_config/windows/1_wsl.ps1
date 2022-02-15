


wsl --set-default-version 2

# Configures mem limit on WSL Config
"[wsl2]" >> "$HOME/.wslconfig"
"memory=2GB" >> "$HOME/.wslconfig"
"swap=512MB" >> "$HOME/.wslconfig"

