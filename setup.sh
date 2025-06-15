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

# Add ruby to PATH for Homebrew (macOS specific fix)
if [[ "$OS" == "mac" && "$PACKAGE_MANAGER" == "brew" ]]; then
  RUBY_PATH="$(brew --prefix ruby)/bin"
  echo "Adding Ruby to PATH: $RUBY_PATH"
  export PATH="$RUBY_PATH:$PATH"
  echo 'export PATH="'"$RUBY_PATH"':$PATH"' >> ~/.zshrc
  source ~/.zshrc
fi

# Download main Ruby script
print_header "downloading instarice ruby"

REPO_URL="https://github.com/ST4RGUARD/instarice.git"
TARGET_DIR="instarice-setup"

if [ -d "$TARGET_DIR" ]; then
  echo "Directory $TARGET_DIR already exists. Pulling latest changes..."
  cd "$TARGET_DIR"
  git pull
else
  git clone "$REPO_URL" "$TARGET_DIR"
  cd "$TARGET_DIR"
fi
