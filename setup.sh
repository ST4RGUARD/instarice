#!/bin/bash

set -e

# Function to print headers
print_header() {
  echo
  echo "==== $1 ===="
}

# Detect OS
print_header "Detecting OS"
OS_TYPE=$(uname)
PACKAGE_MANAGER=""

if [[ "$OS_TYPE" == "Darwin" ]]; then
  echo "System is macOS"
  OS="mac"
elif [[ "$OS_TYPE" == "Linux" ]]; then
  echo "System is Linux"
  OS="linux"
else
  echo "Unsupported OS: $OS_TYPE"
  exit 1
fi

# Detect Package Manager
print_header "Checking for package manager"

if command -v brew &>/dev/null; then
  PACKAGE_MANAGER="brew"
elif command -v apt &>/dev/null; then
  PACKAGE_MANAGER="apt"
elif command -v pacman &>/dev/null; then
  PACKAGE_MANAGER="pacman"
else
  if [[ "$OS" == "mac" ]]; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    PACKAGE_MANAGER="brew"
  else
    echo "No package manager found (brew, apt, pacman). Please install one manually."
    exit 1
  fi
fi

echo "Using package manager: $PACKAGE_MANAGER"

# Check for Ruby
print_header "Checking for Ruby"

if command -v ruby &>/dev/null; then
  echo "Ruby is already installed."
else
  echo "Ruby not found. Installing Ruby..."

  case "$PACKAGE_MANAGER" in
    brew)
      brew install ruby
      ;;
    apt)
      sudo apt update && sudo apt install -y ruby-full
      ;;
    pacman)
      sudo pacman -Sy --noconfirm ruby
      ;;
    *)
      echo "Unsupported package manager: $PACKAGE_MANAGER"
      exit 1
      ;;
  esac
fi

# Fix permissions 
sudo chown -R "$USER":staff "$HOME/.zshrc" "$HOME/.vimrc" "$HOME/.vim" "$HOME/.config" 2>/dev/null

# Add ruby to PATH for Homebrew (macOS specific fix)
if [[ "$OS" == "mac" && "$PACKAGE_MANAGER" == "brew" ]]; then
  RUBY_PATH="$(brew --prefix ruby)/bin"

  if ! command -v ruby &> /dev/null || [[ "$(command -v ruby)" != "$RUBY_PATH/"* ]]; then
    echo "Adding Ruby to PATH: $RUBY_PATH"
    export PATH="$RUBY_PATH:$PATH"

    SHELL_PROFILE="$HOME/.zshrc"
    if ! grep -q "$RUBY_PATH" "$SHELL_PROFILE"; then
      echo 'export PATH="'"$RUBY_PATH"':$PATH"' >> "$SHELL_PROFILE"
      echo "Ruby path added to $SHELL_PROFILE"
    else
      echo "Ruby path already in $SHELL_PROFILE"
    fi

    echo 'here'
  else
    echo "Ruby is already in the correct PATH location: $(command -v ruby)"

  source "$SHELL_PROFILE"
	fi
fi

if [[ "$OS" == "mac" ]]; then
  ruby instarice.rb mac
else
  ruby instarice.rb linux
fi

