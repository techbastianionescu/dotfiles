# dotfiles

Personal config files for my dev environment. Synced across machines so I don't have to set everything up from scratch every time.

## Layout

```
claude/
  CLAUDE.md             user-level Claude Code memory (persona + working style)
  statusline-command.sh status line script for Claude Code (Git Bash)
  bin/
    jq.exe              required by statusline-command.sh
```

## Setup on a new machine

```bash
git clone git@github.com:techbastianionescu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

The bootstrap script copies (or symlinks) files from this repo into the right system locations.
