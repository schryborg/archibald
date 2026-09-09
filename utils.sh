#sourced by archibald.sh

install_packages() {
  local packages=("$@")

  if [ ${#packages[@]} -ne 0 ]; then
    echo "Installing: ${packages[*]}"
    paru -S --needed --noconfirm "${packages[@]}"
  fi
} 

contains() {
  local value="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$value" ]]; then
      return 0  # found
    fi
  done
  return 1  # not found
}

