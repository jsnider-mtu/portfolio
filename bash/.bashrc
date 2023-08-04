# Appended to the file
clean() {
    unset HISTFILE
    exit
}

function settitle() {
    if [[ -z $AT_PROMPT ]]; then
        return
    fi
    unset AT_PROMPT

    echo -ne "\033]2;$(history 1 | sed 's/^[ ]*[0-9]*[ ]*//g')\007"
}
trap settitle DEBUG

FIRST_PROMPT=1
function blastoff() {
    AT_PROMPT=1

    if [[ -n $FIRST_PROMPT ]]; then
        unset FIRST_PROMPT
        return
    fi

    INCOGNITO=''
    echo -ne "\033]2;Terminal\007"
    if [[ -z $HISTFILE ]]; then
        INCOGNITO='[incognito]'
    fi
    if [[ $STATUS -ne 0 ]]; then
        echo -en "\n\033[01;31m$STATUS\033[01;32m $INCOGNITO\033[00m"
    else
        if [[ ! -z $INCOGNITO ]]; then
            echo -ne "\033]2;Terminal $INCOGNITO\007"
            echo -ne "\n\033[01;32m$INCOGNITO\033[00m"
        fi
    fi
}
starship_precmd_user_func="blastoff"
set -o functrace
eval "$(starship init bash)"
set +o functrace

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# restart pulseaudio
pulseaudio -k
