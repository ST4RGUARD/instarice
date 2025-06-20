#!/usr/bin/env ruby
require "fileutils"
require "open3"
require "yaml"

def log(msg)
  puts("[\e[32mINFO\e[0m] #{msg}")
end

def error(msg)
  puts("[\e[31mERROR\e[0m] #{msg}")
end

def header(title)
  puts("\n\e[35m#{"=" * 50}\n#{title}\n#{"=" * 50}\e[0m")
end

def ask_yes_no(question)
  print("\n#{question} (y/n): ")
  response = STDIN.gets.strip.downcase
  response.start_with?("y")
end

def execute(cmd)
  log("Executing: #{cmd}")
  system(cmd)
end

# ---------- Initialization ----------
os = ARGV[0]
unless %w[mac linux].include?(os)
  error("Please run: ruby instarice.rb <mac|linux>")
  exit(1)
end

header("Cleaning up old config files")
HOME = Dir.home

paths_to_remove = [
  "#{HOME}/.zshrc",
  "#{HOME}/.irbrc",
  "#{HOME}/.vimrc",
  "#{HOME}/.vim",
  "#{HOME}/.config/nvim",
  "#{HOME}/.config/ghostty/config"
]

paths_to_remove.each do |path|
  FileUtils.rm_rf(path) if File.exist?(path)
  log("Removed: #{path}")
end

header("Copying config files")

current_user = `whoami`.strip

# Shell config: mac gets special files, linux uses regular .zshrc
if os == "mac"
  log("Detected macOS. Using mac-specific zsh config files.")

  if File.exist?("zshrc_mac")
    FileUtils.cp("zshrc_mac", "#{HOME}/.zshrc", verbose: true)
    log("Copied zshrc_mac → ~/.zshrc")
  else
    error("Missing zshrc_mac file!")
  end

  if File.exist?("zprofile_mac")
    content = File.read("zprofile_mac").gsub("\#{user}", current_user)
    File.write("#{HOME}/.zprofile", content)
    log("Copied zprofile_mac → ~/.zprofile with user substitution")
  else
    error("Missing zprofile_mac file!")
  end

  # linux
else
  log("Detected Linux. Copying standard .zshrc")
  if File.exist?(".zshrc")
    FileUtils.cp(".zshrc", "#{HOME}/.zshrc", verbose: true)
    log("Copied .zshrc → ~/.zshrc")
  else
    error("Missing .zshrc file!")
  end
end

# Copy to ~/
%w[.irbrc .vimrc .vim].each do |item|
  FileUtils.cp_r(item, "#{HOME}/", verbose: true) if File.exist?(item)
end

# Ensure ~/.config & ~/.config/ghostty exist
FileUtils.mkdir_p("#{HOME}/.config")
FileUtils.mkdir_p("#{HOME}/.config/ghostty")
FileUtils.mkdir_p("#{HOME}/.config/ghostty/themes")

# Go setup
FileUtils.mkdir_p("~/go")
system("chmod -R u+rwX \"$GOPATH\"")

# Copy to ~/.config
FileUtils.cp_r("nvim", "#{HOME}/.config/", verbose: true) if Dir.exist?("nvim")
FileUtils.cp_r("config/starship.toml", "#{HOME}/.config/", verbose: true) if File.exist?("config/starship.toml")
if File.exist?("config/ghostty_config")
  FileUtils.cp("config/ghostty_config", "#{HOME}/.config/ghostty/config", verbose: true)
end

FileUtils.cp_r("themes", "#{HOME}/.config/ghostty", verbose: true) if Dir.exist?("themes")

# ---------- Ascii Image Converter ----------
header("Installing ascii-image-converter and copying image")

def install_ascii_image_converter(os)
  if os == "mac"
    log("Installing ascii-image-converter via Homebrew...")
    system("brew install TheZoraiz/ascii-image-converter/ascii-image-converter")
  elsif os == "linux"
    log("Downloading ascii-image-converter for Linux...")
    require "open-uri"
    require "json"

    api_url = "https://api.github.com/repos/TheZoraiz/ascii-image-converter/releases/latest"
    latest_release = JSON.parse(URI.open(api_url).read)
    asset = latest_release["assets"].find { |a|
      a["name"].include?("ascii-image-converter") && a["name"].end_with?(".tar.gz")
    }

    unless asset
      error("Could not find suitable binary in latest release.")
      return
    end

    download_url = asset["browser_download_url"]
    temp_dir = Dir.mktmpdir
    tar_file = File.join(temp_dir, "ascii-image-converter.tar.gz")

    log("Downloading from: #{download_url}")
    URI.open(download_url) do |download|
      File.open(tar_file, "wb") { |f| f.write(download.read) }
    end

    Dir.chdir(temp_dir) do
      system("tar -xzf #{tar_file}")
      binary_path = Dir["ascii-image-converter*"].find { |f| File.executable?(f) && !File.directory?(f) }
      if binary_path
        log("Copying #{binary_path} to /usr/local/bin (requires sudo)")
        system("sudo cp #{binary_path} /usr/local/bin/")
      else
        error("Could not find extracted binary to install.")
      end
    end
  end
end

def copy_image
  source_image = File.join(Dir.pwd, "beyonder.jpg")
  target_dir = File.join(Dir.home, "Pictures")
  target_path = File.join(target_dir, "beyonder.jpg")

  unless File.exist?(source_image)
    error("Image file 'beyonder.jpg' not found in current directory.")
    return
  end

  FileUtils.mkdir_p(target_dir)
  FileUtils.cp(source_image, target_path)
  log("Copied image to: #{target_path}")
end

install_ascii_image_converter(os)
copy_image

header("App Installation")

# ---------- Package Manager Detection ----------
def find_package_manager
  return "brew" if `which brew` != ""
  return "apt" if `which apt` != ""
  return "pacman" if `which pacman` != ""
  nil
end

pkg_manager = find_package_manager
unless pkg_manager
  error("No supported package manager found!")
  exit(1)
end

log("Package manager detected: #{pkg_manager}")

# ---------- App Installation ----------
def install_apps(file, os, pkg_manager)
  apps = YAML.load_file(file)
  apps.each do |pkg|
    cmd = case os
    when "mac"
      "brew install #{pkg}"
    when "linux"
      if pkg_manager == "apt"
        "sudo apt install -y #{pkg}"
      else
        "sudo pacman -S --noconfirm #{pkg}"
      end
    end

    log("Installing #{pkg}...")
    system(cmd)
  end
end

if ask_yes_no("Do you want to install all apps from apps.yml?")
  install_apps("apps.yml", os, pkg_manager)
end

# ---------- Language Installation ----------
header("Language Setup")

LANG_TOOL = {
  ruby: "frum",
  python: "rye",
  rust: "rustup",
  go: "go",
  node: "node"
}

def install_openssl_for_ruby(os, pkg_manager)
  log("Checking for OpenSSL...")

  if os == "mac"
    unless system("brew list openssl@3 > /dev/null 2>&1")
      log("Installing OpenSSL via Homebrew...")
      system("brew install openssl@3")
    end

    `brew --prefix openssl@3`.strip
  elsif os == "linux"
    if pkg_manager == "apt"
      unless system("dpkg -s libssl-dev > /dev/null 2>&1")
        log("Installing OpenSSL via APT...")
        system("sudo apt update && sudo apt install -y libssl-dev")
      end
    elsif pkg_manager == "pacman"
      unless system("pacman -Qi openssl > /dev/null 2>&1")
        log("Installing OpenSSL via Pacman...")
        system("sudo pacman -Syu --noconfirm openssl")
      end
    else
      error("Unsupported Linux package manager for OpenSSL install.")
      return nil
    end

    "/usr"
  else
    error("Unsupported OS for OpenSSL setup.")
    nil
  end
end

def install_lang_pkg(name, os, pkg_manager)
  case name
  when :ruby
    log("Installing Ruby with frum...")
    openssl_dir = install_openssl_for_ruby(os, pkg_manager)

    if openssl_dir
      cmd = "RUBY_CONFIGURE_OPTS=\"--with-openssl-dir=#{openssl_dir}\" frum install 3.4.4"
      log("Running: #{cmd}")
      system(cmd)
      system("frum global 3.4.4")
    else
      error("Could not determine OpenSSL location. Skipping Ruby install.")
    end

  when :python
    os == "mac" ? system("brew install rye") : system("curl -sSf https://rye-up.com/get | bash")
  when :rust
    system("curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y")
  when :go
    os == "mac" ? system("brew install go") : system("#{pkg_manager} install -y golang")
  when :node
    os == "mac" ? system("brew install node") : system("#{pkg_manager} install -y nodejs npm")
  end
end

lang_tools = []

if ask_yes_no("Do you want to install all languages from lang.yml?")
  YAML.load_file("lang.yml").each do |lang|
    lang_sym = lang.strip.downcase.to_sym
    install_lang_pkg(lang_sym, os, pkg_manager)
    lang_tools << lang.downcase
  end
else
  YAML.load_file("lang.yml").each do |lang|
    lang_sym = lang.strip.downcase.to_sym
    install_lang_pkg(lang_sym, os, pkg_manager) if ask_yes_no("Install #{lang_sym}?")
    lang_tools << lang.downcase
  end
end

# ---------- Source ZSH ----------
header("If you installed rye - please run rye in your terminal to install")
zshrc = "#{HOME}/.zshrc"
line = "source \"$HOME/.rye/env\""
unless File.readlines(zshrc).any? { |l| l.strip == line }
  File.open(zshrc, "a") { |f| f.puts(line) }
end

header("Please restart your terminal or run: source ~/.zshrc")

# ---------- Language Tools ------
# -- python
if lang_tools.include?("python")
  system("rye install debugpy")
  system("rye install black")
end
# -- ruby
if lang_tools.include?("ruby")
  sib_dir = "#{HOME}/.config/seeing_is_believing"
  FileUtils.mkdir_p(sib_dir)
  system("git clone https://github.com/JoshCheek/seeing_is_believing.git '#{sib_dir}'")
  frum_ruby_bin = File.expand_path("~/.frum/versions/3.4.4/bin/")
  ENV["PATH"] = "#{frum_ruby_bin}:#{ENV["PATH"]}"

  # Install gems
  gems = ["interactive_editor"]
  gems.each do |gem|
    log("Installing Ruby gem: #{gem}")
    system("gem install #{gem}")
  end

  Dir.chdir(sib_dir) do
    system("gem build seeing_is_believing.gemspec")
    system("gem install seeing_is_believing-*.gem")
  end
end
# -- golang
if lang_tools.include?("go")
  system("go install github.com/incu6us/goimports-reviser/v3@latest")
  system("go install mvdan.cc/gofumpt@latest")
  system("go install github.com/segmentio/golines@latest")
  system("go install github.com/go-delve/delve/cmd/dlv@latest")
end

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
  log("All config files found!")
  if ask_yes_no("Do you want to clean up and uninstall temporary Ruby?")
    case os
    when "mac"
      execute("brew uninstall ruby")
    when "linux"
      execute("#{pkg_manager} remove -y ruby")
    end

    FileUtils.rm_rf(Dir.pwd)
    log("Cleanup complete!")
  else
    log("Skipping cleanup.")
  end
else
  error("Some config files are missing:")
  missing.each { |f| error(f) }
end

# ---------- Final Message ----------
puts(
  <<~EOF

    Setup is complete!

    Run the following inside Neovim:
      :Lazy sync
      :Lazy update
      :Lazy install
      :Mason update
      :Mason install

    Happy hacking! ⚡

  EOF
)
