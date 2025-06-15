##!/usr/bin/env ruby
require 'fileutils'
require 'open3'
require 'yaml'

def log(msg)
  puts "[\e[32mINFO\e[0m] #{msg}"
end

def error(msg)
  puts "[\e[31mERROR\e[0m] #{msg}"
end

def header(title)
  puts "\n\e[35m#{"=" * 50}\n#{title}\n#{"=" * 50}\e[0m"
end

def ask_yes_no(question)
  print "\n#{question} (y/n): "
  gets.strip.downcase.start_with?('y')
end

def execute(cmd)
  log("Executing: #{cmd}")
  system(cmd)
end

# ---------- Initialization ----------
os = ARGV[0]
unless %w[mac linux].include?(os)
  error("Please run: ruby instarice.rb <mac|linux>")
  exit 1
end

header("🧼 Cleaning up old config files")
HOME = Dir.home

paths_to_remove = [
  "#{HOME}/.zshrc",
  "#{HOME}/.vimrc",
  "#{HOME}/.vim",
  "#{HOME}/.config/nvim",
  "#{HOME}/.config/ghostty/config"
]

paths_to_remove.each do |path|
  FileUtils.rm_rf(path) if File.exist?(path)
  log("Removed: #{path}")
end

header("📁 Copying config files")

# Copying to ~/
%w[.zshrc .vimrc .vim].each do |item|
  FileUtils.cp_r(item, "#{HOME}/", verbose: true) if File.exist?(item)
end

# Ensure ~/.config & ~/.config/ghostty exist
FileUtils.mkdir_p("#{HOME}/.config")
FileUtils.mkdir_p("#{HOME}/.config/ghostty")

# Copy to ~/.config
FileUtils.cp_r('nvim', "#{HOME}/.config/", verbose: true) if Dir.exist?('nvim')
FileUtils.cp_r('config/starship.toml', "#{HOME}/.config/", verbose: true) if File.exist?('config/starship.toml')
FileUtils.cp('ghostty_config', "#{HOME}/.config/ghostty/config", verbose: true) if File.exist?('ghostty_config')

header("📦 App Installation")

# ---------- Package Manager Detection ----------
def find_package_manager
  return 'brew' if `which brew` != ''
  return 'apt' if `which apt` != ''
  return 'pacman' if `which pacman` != ''
  nil
end

pkg_manager = find_package_manager
unless pkg_manager
  error("No supported package manager found!")
  exit 1
end
log("Package manager detected: #{pkg_manager}")

# ---------- App Installation ----------
def install_apps(file, os, pkg_manager)
  apps = YAML.load_file(file)

  Ractor.new(apps) do |app_list|
    app_list.each do |app|
      Ractor.new(app) do |pkg|
        cmd =
          case os
          when 'mac'
            "brew install #{pkg}"
          when 'linux'
            if pkg_manager == 'apt'
              "sudo apt install -y #{pkg}"
            else
              "sudo pacman -S --noconfirm #{pkg}"
            end
          end
        system(cmd)
      end
    end
  end
end

if ask_yes_no("Do you want to install all apps from apps.yml?")
  install_apps("apps.yml", os, pkg_manager)
end

# ---------- Language Installation ----------
header("💻 Language Setup")

LANG_TOOL = {
  ruby: "frum",
  python: "rye",
  rust: "rustup",
  go: "go"
}

def install_lang_tool(name, os, pkg_manager)
  case name
  when :ruby
    os == 'mac' ? system("brew install frum") : system("#{pkg_manager} install -y curl && curl https://frum.sh/install | bash")
  when :python
    os == 'mac' ? system("brew install rye") : system("curl -sSf https://rye-up.com/get | bash")
  when :rust
    system("curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y")
  when :go
    os == 'mac' ? system("brew install go") : system("#{pkg_manager} install -y golang")
  end
end

if ask_yes_no("Do you want to install all languages from lang.yml?")
  YAML.load_file("lang.yml").each do |lang|
    lang_sym = lang.strip.downcase.to_sym
    Ractor.new(lang_sym) do |l|
      install_lang_tool(l, os, pkg_manager)
    end
  end
else
  YAML.load_file("lang.yml").each do |lang|
    lang_sym = lang.strip.downcase.to_sym
    install_lang_tool(lang_sym, os, pkg_manager) if ask_yes_no("Install #{lang_sym}?")
  end
end

# ---------- Source ZSH ----------
header("💡 Sourcing .zshrc")
execute("source #{HOME}/.zshrc")

# ---------- Cleanup ----------
header("🧹 Final Check and Cleanup Option")

files_to_check = [
  "#{HOME}/.zshrc",
  "#{HOME}/.vimrc",
  "#{HOME}/.vim",
  "#{HOME}/.config/nvim",
  "#{HOME}/.config/ghostty/config",
  "#{HOME}/.config/starship.toml"
]

missing = files_to_check.reject { |f| File.exist?(f) }
if missing.empty?
  log("✅ All config files found!")
  if ask_yes_no("Do you want to clean up and uninstall temporary Ruby?")
    case os
    when 'mac'
      execute("brew uninstall ruby")
    when 'linux'
      execute("#{pkg_manager} remove -y ruby")
    end
    FileUtils.rm_rf(Dir.pwd)
    log("Cleanup complete! ✨")
  else
    log("Skipping cleanup.")
  end
else
  error("Some config files are missing:")
  missing.each { |f| error(f) }
end

# ---------- Final Message ----------
puts <<~EOF

  🎉 Setup is complete!

  🚀 Run the following inside Neovim:
    :Lazy sync
    :Lazy update
    :Lazy install
    :Mason install

  Happy hacking! 💻⚡

EOF
!/usr/bin/env ruby
