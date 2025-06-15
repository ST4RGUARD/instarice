# instarice
auto dev env setup 

1. backup ~/.zshrc
2. backup ~/.config/nvim
3. backup ~/.vimrc
4. backup ~/.vim
5. backup ~/.config/ghostty/config

instarice will check mac or linux

instarice will first remove existing .zshrc, nvim, and ghostty configs

instarice will next download these from this repo

instarice will ask to install all languages - all supported lang in lang.yml in this repo

if yes - instarice will begin setup of devenv for mac or linux system installing ghostty terminal, language envs and neovim

if no - instarice will begin asking 1 by 1 which language to install
