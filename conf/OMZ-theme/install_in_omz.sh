#!/bin/sh

echo "Creating symlink from here to your oh-my-zsh themes path..."

mkdir -p ~/.oh-my-zsh/custom/themes/
ln -f panda.zsh-theme ~/.oh-my-zsh/custom/themes/panda.zsh-theme

echo "
Done ! (the symlink is ~/.oh-my-zsh/custom/themes/panda.zsh-theme)
----------------------------------------------------------------------------------
Options:
All options must be overridden in your .zshrc file.
See README.md for more info.
----------------------------------------------------------------------------------
Requirements:
Z shell (zsh): See oh-my-zsh for more info.
Make sure terminal is using 256-colors mode with export TERM=\"xterm-256color\"".
