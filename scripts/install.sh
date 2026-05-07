#!/usr/bin/env bash

set -e

DOTFILES="$HOME/dotfiles"

mkdir -p "$HOME/.config"

backup_and_link() {
  source_path="$1"
  target_path="$2"

  if [ ! -e "$source_path" ]; then
    echo "Skip: source does not exist: $source_path"
    return
  fi

  if [ -L "$target_path" ]; then
    echo "Remove old symlink: $target_path"
    rm "$target_path"
  elif [ -e "$target_path" ]; then
    echo "Backup existing: $target_path -> $target_path.bak"
    mv "$target_path" "$target_path.bak"
  fi

  echo "Link: $target_path -> $source_path"
  ln -s "$source_path" "$target_path"
}

backup_and_link "$DOTFILES/config/nvim" "$HOME/.config/nvim"
backup_and_link "$DOTFILES/config/ghostty" "$HOME/.config/ghostty"
backup_and_link "$DOTFILES/config/lazygit" "$HOME/.config/lazygit"
backup_and_link "$DOTFILES/config/yazi" "$HOME/.config/yazi"
backup_and_link "$DOTFILES/config/ranger" "$HOME/.config/ranger"
backup_and_link "$DOTFILES/config/btop" "$HOME/.config/btop"
backup_and_link "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"

backup_and_link "$DOTFILES/home/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES/home/.gitconfig" "$HOME/.gitconfig"

echo "Done."
