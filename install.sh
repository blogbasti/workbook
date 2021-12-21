#!/usr/bin/env bash
#
# vim: syntax=bash ts=4 sw=4 sts=4 sr noet
#
# setup MacOS workbook
#

set -o errexit
set -o pipefail

function msg () {
  local level="$1"; shift
  local msg="$@"

  echo "[$(date)][$level][${method:-main}] $msg"
}

function error () {
  local msg="$@"

  msg "ERROR" "$msg" >&2
}

function fatal_error () {
  local msg="$@"

  msg "FATAL" "$msg" >&2

  exit 1
}

function info () {
  local msg="$@"

  msg INFO "$msg"
}

function title () {
  # local method='title'

  info "$@"
}

function install_zsh_ext () {
  local method='install_zfs_ext'
  local extension="$1"; shift

  # install zsh extensions
  if [ ! -f /opt/homebrew/share/$extension/$extension.zsh ]; then
    title "installing zsh extension $extension"
    brew install "$extension"
  fi

}

function prepare_env () {
  local method='prepare_env'
  # enable xcode
  title "looking for xcode"
  xcode-select -p >/dev/null || (
    title "enable xcode"
    xcode-select --install
  )
  # install homebrew
  title "looking homebrew"
  if [ ! -x /opt/homebrew/bin/brew ] ; then
    title "install homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # activate homebrew
  if [ -x /opt/homebrew/bin/brew ] ; then
    if ! grep "/opt/homebrew/bin/brew shellenv" $HOME/.zprofile >/dev/null ; then
      title "adding Homebrew to PATH"
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
    fi
    eval "$(/opt/homebrew/bin/brew shellenv)" >/dev/null
  fi
  # install rbenv
  title "looking for rbenv"
  which rbenv >/dev/null || (
    title "install rbenv via brew"
    brew install rbenv
  )
  # install oh-my-zsh
  title "looking for oh-my-zsh"
  if [ ! -d $HOME/.oh-my-zsh ]; then
    title "install oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  install_zsh_ext "zsh-syntax-highlighting"
  install_zsh_ext "zsh-autosuggestions"

  # install rbenv
  title "looking for iterm2"
  brew list --cask iterm2 >/dev/null || (
    title "install iterm2 via brew"
    brew install --cask iterm2
  )
}

function install_file_if_needed () {
  local method='install_file_if_needed'
  local src="$1"; shift
  local dst="$1"; shift

  if [ -e "$dst" ]; then
    if ! cmp -s "$src" "$dst" ; then
      backup="$dst.backup-$(date +%s)"
      title "installing new version of $dst (backup: $backup)"
      cp "$dst" "$backup"
      cp "$src" "$dst"
    fi
  else
    title "installing first version of $dst"
    cp "$src" "$dst"
  fi
}

function install_configs () {
  local method='install_configs'

  install_file_if_needed files/default/.vimrc $HOME/.vimrc
  install_file_if_needed files/default/.zshrc $HOME/.zshrc
}

function install_spaceship () {
  local method='install_spaceship'

  if [ -z "$ZSH_CUSTOM" ]; then
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    info "ZFS_CUSTOM: $ZSH_CUSTOM"
  fi

  title 'looking for zsh theme spaceship'
  if [ -z "$ZSH_CUSTOM" ]; then
    fatal_error "You are not running install.sh from zsh."
  fi
  if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
    title "installing spaceship zsh theme"
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
  fi
  if [ ! -L "$ZSH_CUSTOM/themes/spaceship.zsh-theme" -a ! -e "$ZSH_CUSTOM/themes/spaceship.zsh-theme" ]; then
    ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
  fi

  # brew list svn || (
  #   title "install svn client"
  #   brew install svn
  # )
  #
  # title 'install font fira mono for powerline'
  # brew install --cask homebrew/cask-fonts/font-fira-mono-for-powerline
}

prepare_env
install_spaceship
install_configs


exit 0
