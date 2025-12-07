if [ -e '/usr/share/bash-completion/completions/git' ]; then
    . /usr/share/bash-completion/completions/git
fi

# Explain (v) what was done when moving a file
alias mv='mv -v'
# Create any non-existent (p)arent directories and explain (v) what was done
alias mkdir='mkdir -pv'

# Current directory’s listing, in long format, including hidden directories
alias ll="ls -lhAF"

# Easier navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

alias ll="ls -lhAF"

alias diff='diff --color=auto --side-by-side --left-column --ignore-blank-lines --ignore-space-change --suppress-common-lines'

# Some Git Shortcuts & Autocompletion
alias g="git"
__git_complete g __git_main

alias gst="git status"
__git_complete gst _git_status

alias gp="git push"
__git_complete gp _git_push

alias gpf="git push --force-with-lease --force-if-includes"
__git_complete gpf _git_push

alias gpl="git pull"
__git_complete gpl _git_pull

alias gb="git branch"
__git_complete gb _git_branch

alias ga="git add . -v"
__git_complete ga _git_add

alias gap="git add -p"
__git_complete gap _git_add

alias gc="git commit"
__git_complete gc _git_commit

alias gca="git commit --amend --no-edit"
__git_complete gcm _git_commit

alias gcm="git commit -m $1"
__git_complete gcm _git_commit

alias gl="git log --oneline"
__git_complete gl _git_log

alias glg="git log --graph --date-order --oneline --all"
__git_complete glg _git_log

alias grbc="git rebase --continue"
__git_complete grbc _git_rebase

alias undo-commit="git reset --soft HEAD~1"
alias gundo=undo-commit
__git_complete gundo _git_reset
__git_complete undo-commit _git_reset
 
alias yolo-claude="\claude --dangerously-skip-permissions"
alias claude="claude-launcher"

alias list-screenshots="find  ~/claude-screenshots -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.jpeg" \) -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2"
alias last-screenshot="list-screenshots | head -n 1"

