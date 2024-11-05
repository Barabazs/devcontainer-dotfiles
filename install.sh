#!/bin/sh

# Copy the dotfiles
cp gitignore ~/.gitignore

# Copy the bash_aliases
cp bash_aliases ~/.bash_aliases

# Copy the scripts
mkdir ~/.local
cp -r scripts ~/.local/scripts

# Append to .profile
cat <<'EOF' >>~/.profile
if [ -d "${HOME}/.local/scripts" ] ; then
    PATH="${HOME}/.local/scripts:$PATH"
fi
EOF

# chmod the scripts
chmod +x ~/.local/scripts/*
