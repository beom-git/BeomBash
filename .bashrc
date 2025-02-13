#!/bin/bash -f

#
#
# Step #0 : Set Umask
#
# Description : Set umask to 022 (755 for directories, 644 for files)
#
    umask 022

#
# Step #1 : Set prompt
#
# Description : (%h:%m) username@hostname: current path
# Reference   : http://www.understudy.net/custom.html
#
    if [ -f ~/.bash/.bash_profile ]; then 
        source ~/.bash/.bash_profile
    fi 

    #PS1="(\A) \[\033[01;32m\]\u@\h⛄:\[\033[01;34m\]\W\[\033[00m\]\$ "
    export PS1="(\A) \[${C_Bold_GREEN}\]\u@\h⛄:\[${C_Bold_BLUE}\]\W\[${C_End}\]\$ "

	# enable color support of ls and also add handy aliases
	if [ -x /usr/bin/dircolors ]; then
	    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	    alias ls='ls --color=auto'
	    #alias dir='dir --color=auto'
	    #alias vdir='vdir --color=auto'
	
	    alias grep='grep --color=auto'
	    alias fgrep='fgrep --color=auto'
	    alias egrep='egrep --color=auto'
	fi

#
# Step #2 : Set Welcome Banner
#
# Description : show motd(message of the day)
#
    if [ -f ~/.bash/.bash_motd ]; then 
        source ~/.bash/.bash_motd
    fi 

#
# Step #3 : Set Shell Options 
#
# shopt [-pqsu] [-o] [optname …]
#   -s : Enable (set) each optname.
#   -u : Disable (unset) each optname.
#   -q : Suppresses normal output (quiet mode); the return status indicates whether the optname is set or unset.
#   -p : Display a list of all settable options, instead of performing the specified action.
#   -o : Restricts the values of optname to be those defined for the -o option to the set builtin.
#
# Reference : https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
#             https://mug896.github.io/bash-shell/shell_options.html
#

    # Don't put duplicate lines or lines starting with space in the history.
    # See bash(1) for more options.
    HISTCONTROL=ignoreboth

    # Set history length and format.
    export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S '
    HISTSIZE=10
    HISTFILESIZE=100

    if [ command shopt &> /dev/null ]; then
        
        # Set change directory without cd command
        # shopt -s autocd

        # Append to the history file, don't overwrite it
        # shopt -s histappend

        # Check the window size after each command and, if necessary,
        # update the values of LINES and COLUMNS.
        # shopt -s checkwinsize

        # If set, the pattern "**" used in a pathname expansion context will
        # match all files and zero or more directories and subdirectories.
        #
        # Example: `ls **/bin` will show all files in all the subdirectories of bin.
        shopt -s globstar
    else
        printf "[INFO] 'shopt' command not found, skipping shell options\n"
    fi

#
# Step #4 : Set Alias
#
# Description : Set alias for frequently used commands
if [ -f ~/.bash/.bash_alias ]; then 
    source ~/.bash/.bash_alias
fi

#
# Step #5 : Set User Defined Functions
#
# Description : Set user defined functions
#
if [ -f ~/.bash/.bash_function ]; then 
    source ~/.bash/.bash_function
fi

#
# Step #6 : Set User Defined Completion
#
# Description : Set user defined completion
#

if [ -f ~/.bash/.bash_completion ]; then 
    source ~/.bash/.bash_completion
fi
