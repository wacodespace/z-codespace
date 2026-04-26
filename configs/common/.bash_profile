# ~/.bash_profile - Login shell entrypoint
# ============================================================

# Alacritty on macOS starts bash as a login shell, which reads this file.
# Silence macOS's default-shell migration notice for bash sessions.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Keep interactive shell behavior centralized in ~/.bashrc.
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
