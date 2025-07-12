# instarice

**Auto Developer Environment Setup**

*This tool should have been named `newHire` or `pcRefresh`.*

The idea:  
You get a new PC (Linux or Mac) with nothing installed — possibly even Arch Linux with no programming languages or package managers installed.

---

## Features

- Backup existing dotfiles before setup
- Detect and install missing package managers and Ruby
- Setup a fully-configured development environment
- Install programming languages and tools based on configuration

---

## Backup

Before running the setup, `instarice` will back up the following files/directories:

- `~/.zshrc`
- `~/.vimrc`
- `~/.vim`
- `~/.config/nvim`
- `~/.config/ghostty/config`
- `~/.config/starship.toml`

---

## Requirements

- Network connection (internet configured)
- Package manager (will install if missing)
- Ruby (will install if missing)

---

## Setup Instructions

1. Clone this repository:

    ```bash
    git clone <repo-url>
    cd instarice
    ```

2. Configure programming languages and tools before running:  
   Define desired programs or languages in the following YAML files:
   - `lang_tools/apps.yml`  
   - `lang_tools/lang.yml`  
   - Language-specific tool configs: `lang_tools/ruby.yml`, `python.yml`, etc.

3. Run the setup script:

    ```bash
    ./setup.sh
    ```

---

## How `instarice` Works

- Detects your system’s package manager  
  - If none is found, it will install one

- Removes existing dotfiles to avoid conflicts

- Starts the development environment setup for macOS or Linux:  
  - Copies over configuration files  
  - Prompts to install all apps listed in `apps.yml`  
    - If declined, prompts for installation one-by-one

- Asks to install programming languages defined in `lang.yml`:  
  - Default languages: Ruby, Python, Node, Rust, Go  
  - If declined, asks about languages one-by-one

- Installs related language tools for debugging, linting, etc., tailored for my neovim setup

- Logs errors and instructions during setup

- After completion, prompts for cleanup options:  
  - Remove this repo  
  - Optionally uninstall Homebrew and Ruby (on Mac)

---
