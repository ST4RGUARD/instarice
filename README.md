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

instarice will next download these from this repo

instarice will ask to install all languages - all supported lang in lang.yml in this repo

if yes - instarice will begin setup of devenv for mac or linux system installing ghostty terminal, language envs and neovim

- this will include neceassary gems, modules, etc

if no - instarice will begin asking 1 by 1 which language to install
