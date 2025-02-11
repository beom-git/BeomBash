#!/bin/bash -f

#
# Step #1 : Define colors
#

# default
C_Nomal_DEFAULT=$(tput sgr0)
C_End=$(tput sgr0)

# Normal
C_Normal_BLACK=$(tput setaf 0)
C_Normal_RED=$(tput setaf 1)
C_Normal_GREEN=$(tput setaf 2)
C_Normal_YELLOW=$(tput setaf 3)
C_Normal_BLUE=$(tput setaf 4)
C_Normal_MAGENTA=$(tput setaf 5)
C_Normal_CYAN=$(tput setaf 6)
C_Normal_WHITE=$(tput setaf 7)

# Bold
C_Bold_BLACK=$(tput setaf 0)$(tput bold)
C_Bold_RED=$(tput setaf 1)$(tput bold)
C_Bold_GREEN=$(tput setaf 2)$(tput bold)
C_Bold_YELLOW=$(tput setaf 3)$(tput bold)
C_Bold_BLUE=$(tput setaf 4)$(tput bold)
C_Bold_MAGENTA=$(tput setaf 5)$(tput bold)
C_Bold_CYAN=$(tput setaf 6)$(tput bold)
C_Bold_WHITE=$(tput setaf 7)$(tput bold)

# Background
C_Back_BLACK=$(tput setab 0)
C_Back_RED=$(tput setab 1)
C_Back_GREEN=$(tput setab 2)
C_Back_YELLOW=$(tput setab 3)
C_Back_BLUE=$(tput setab 4)
C_Back_MAGENTA=$(tput setab 5)
C_Back_CYAN=$(tput setab 6)
C_Back_WHITE=$(tput setab 7)
