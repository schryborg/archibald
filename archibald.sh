#!/bin/bash

# Print the logo
print_logo() {
  cat << "EOF"
    _    ____   ____ _   _ _ _           _     _ 
   / \  |  _ \ / ___| | | (_) |__   __ _| | __| |
  / _ \ | |_) | |   | |_| | | '_ \ / _` | |/ _` |
 / ___ \|  _ <| |___|  _  | | |_) | (_| | | (_| |
/_/   \_\_| \_\\____|_| |_|_|_.__/ \__,_|_|\__,_|
Arch Linux install helper
by: schryborg
 
EOF
}

clear
print_logo

# exit on error
set -e

# do not run as root
[[ $EUID -eq 0 ]] && { echo "run as normal user"; exit 1; }


SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# source packages
if [ ! -f "$SCRIPT_DIR/packages.conf" ]; then
    echo "Error: packages.conf missing!"
    exit 1
fi

# source utils
if [ ! -f "$SCRIPT_DIR/utils.sh" ]; then
    echo "Error: utils.sh missing!"
    exit 1
fi

source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/packages.conf"

# parse arguments (system type and window manager, any order)
SYSTEM_TYPE=""
WM=""
while [ $# -gt 0 ]; do
  case "$1" in
    --laptop)   SYSTEM_TYPE="laptop" ;;
    --desktop)  SYSTEM_TYPE="desktop" ;;
    --mango)    WM="mango" ;;
    --niri)     WM="niri" ;;
    --hyprland) WM="hyprland" ;;
    --nowm)     WM="no" ;;
    *) echo "Usage: $0 [--laptop|--desktop] [--mango|--niri|--hyprland|--nowm]"; exit 1 ;;
  esac
  shift
done

# determine system type (laptop or desktop)
if [ -z "$SYSTEM_TYPE" ]; then
  while true; do
    read -rp "Is this a Laptop or Desktop? [l/d]: " answer
    case "$answer" in
      l|L|laptop)  SYSTEM_TYPE="laptop"; break ;;
      d|D|desktop) SYSTEM_TYPE="desktop"; break ;;
      *) echo "Please enter 'l' or 'd'." ;;
    esac
  done
fi

# window manager
if [ -z "$WM" ]; then
  while true; do
    read -rp "Which window manager? [(m)ango|(n)ri|(h)yprland|(no)wm]: " answer
    case "$answer" in
      m|M|mango)   WM="mango"; break ;;
      n|N|niri)   WM="niri"; break ;;
      h|H|hyprland) WM="hyprland"; break ;;
      no|NO|nowm)       WM="no"; break ;;
      *) echo "Please enter 'm', n', 'h' or 'no'." ;;
    esac
  done
fi

sudo pacman -Syu --noconfirm

# install paru if not already installed
REPO_DIR="$HOME/repos"
mkdir -p "$REPO_DIR"
if ! command -v paru &> /dev/null; then
    echo "paru not found. Installing now..."
    sudo pacman -S --needed --noconfirm base-devel git
    cd "$REPO_DIR"
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd "$REPO_DIR"
    rm -rf paru
fi

cd "$REPO_DIR"
if [ -d "$REPO_DIR/dotfiles" ]; then
  cd "$REPO_DIR/dotfiles"
  git pull
else
  git clone https://gitea.schryborg.de/luke/dotfiles.git
fi

sudo pacman -S --needed --noconfirm stow
cd "$REPO_DIR/dotfiles"
stow -t "$HOME" ghostty 
stow -t "$HOME" wireplumber
stow -t "$HOME" pipewire
stow -t "$HOME" nvim
stow -t "$HOME" starship 
stow -t "$HOME" yazi
stow -t "$HOME" zsh
stow -t "$HOME" fuzzel

case "$WM" in
  mango)
    install_packages "${MANGO[@]}"
    install_packages "${WM_COMMON[@]}"
    stow -t "$HOME" mango
    stow -t "$HOME" mako
    stow -t "$HOME" waybar 
    ;;
  niri)
    install_packages "${NIRI[@]}"
    install_packages "${WM_COMMON[@]}"
    stow -t "$HOME" niri
    stow -t "$HOME" mako
    stow -t "$HOME" waybar 
    ;;
  hyprland)
    install_packages "${HYPRLAND[@]}"
    install_packages "${WM_COMMON[@]}"
    stow -t "$HOME" hyprland
    stow -t "$HOME" mako
    stow -t "$HOME" waybar 
    ;;
esac

install_packages "${SYSTEM_UTILS[@]}"
install_packages "${FONTS[@]}"
install_packages "${MUSIC[@]}"
install_packages "${DEV_TOOLS[@]}"
if contains "neovim" "${DEV_TOOLS[@]}"; then
  echo "Neovim found in packages, installing tree-sitter-cli"
  wget https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-cli-linux-x64.zip
  unzip tree-sitter-cli-linux-x64.zip
  chmod +x tree-sitter
  sudo rm -f /usr/local/bin/tree-sitter
  sudo mv tree-sitter /usr/local/bin/tree-sitter
  rm tree-sitter-cli-linux-x64.zip 
fi
install_packages "${MAKER[@]}"

case "SYSTEM_TYPE" in
  hyprland)
    systemctl --user enable --now waybar.service
    systemctl --user enable --now mako.service
    systemctl --user enable --now hyprpolkitagent.service
    ;;
  niri)
    ;;
esac

zsh_path="/usr/bin/zsh"
if [ "$SHELL" != "$zsh_path" ]; then
  chsh -s "$zsh_path"
fi

case "$SYSTEM_TYPE" in
  desktop)
    install_packages "${VIRTUALIZATION[@]}"
    install_packages "${GAMING[@]}"
    ;;
  laptop)
    install_packages "${WIRELESS[@]}"
    install_packages "${NOTEBOOK[@]}"
    echo "uhid" | sudo tee /etc/modules-load.d/uhid.conf
    ;;
esac

git config --global user.email "luke@schryborg.de"
git config --global user.name "luke"

echo "Installation done! Remember to create ssh keys: \n ssh-keygen -t ed25519 \n ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_gitea -C \"luke@schryborg.de\""
