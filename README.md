# Smajo dotfiles

My personal Linux/macOS development environment.

## Includes

- Neovim
- Ghostty
- Starship
- Lazygit
- Yazi
- Ranger
- Btop

## macOS setup

### 1. Install Command Line Tools

```bash
xcode-select --install
```

If that does not work, download the correct Command Line Tools version manually from Apple Developer Downloads.

### 2. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installing Homebrew, make sure it is available in the shell:

```bash
brew --version
```

### 3. Clone this repository

```bash
git clone https://github.com/USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Replace `USERNAME` with your GitHub username.

### 4. Install packages

```bash
brew bundle
```

### 5. Link configuration files

```bash
./scripts/install.sh
```

### 6. Restart shell

```bash
exec zsh
```

## Useful commands

Update dotfiles after changing configs:

```bash
cd ~/dotfiles
git add .
git commit -m "Update dotfiles"
git push
```

Check symlinks:

```bash
ls -la ~/.config
ls -la ~ | grep zshrc
```
