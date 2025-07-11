# instarice

auto dev env setup - should have been named newHire or pcRefresh
the idea is you get a new pc with linux or mac and nothing else,
maybe even arch with no programming languages installed or package manager

1. backup
   - ~/.zshrc
   - ~/.vimrc
   - ~/.vim
   - ~/.config/nvim
   - ~/.config/ghostty/config
   - ~/.config/starship.toml
---

2. Requirements
   - network (internet configured)
   - package manager (which it will install if missing)
   - ruby (will install if missing)

---

CLONE REPO

Before running define any programs or programming languages in lang_tools/apps.yml and lang_tools/lang.yml
  - programming language tools or gems etc can be defined in lang_tools/ruby.yml python.yml etc

./setup.sh

---

instarice will determine package manager

- if none existing will install

instarice will first remove existing dotfiles

instarice will begin setup of devenv for mac or linux system
  - it will copy over config files
  - it will ask to install all apps in apps.yml
  - if no it will ask to install 1 by 1

instarice will ask to install all languages - declared in lang.yml
  - if yes it will begin installing all languages
    - default - [ruby,python,node,rust,go]  
  - if no instarice will begin asking 1 by 1 which language to install
  - it will then install relevant language tools i use for debugging linting etc with my setup (neovim)

instarice will log any errors or instructions and prompt to cleanup which will remove this repo, and give the option to uninstall the used homebrew ruby on mac
