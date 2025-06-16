# instarice

auto dev env setup

1. backup ~/.zshrc
2. backup ~/.config/nvim
3. backup ~/.vimrc
4. backup ~/.vim
5. backup ~/.config/ghostty/config

---

CLONE REPO

RUN setup.sh

---

instarice will check mac or linux

instarice will determine package manager

- if none existing will install

instarice will first remove existing ~/.zshrc, ~/.vimrc, ~/.vim/, ~/.config/nvim/, and ~/.config/ghostty/config

instarice will begin setup of devenv for mac or linux systemm
  - it will copy over config files
  - it will ask to install all apps in apps.yml currently [neovim,vim,ghostty,starship]
  - if no it will ask to install 1 by 1

instarice will ask to install all languages - all supported lang in lang.yml in this repo
  - if yes it will begin installing all languages
  - if no instarice will begin asking 1 by 1 which language to install
  - it will then instll gems/modules/packages each languages needs for debugging linting etc (neovim)

instarice will log any errors or instructions and prompt to cleanup which will remove this repo, and give the option to uninstall the used homebrew ruby on mac
