#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GGAPP_ROOT="$DIR"

echo ""
echo "GGAPP_ROOT = \"$GGAPP_ROOT\""
echo ""


# set .bash_profile or .profile
ENVSTR="export GGAPP_ROOT=$GGAPP_ROOT"
if [ "$SHELL" == "/bin/bash" ]; then
	PROFILE_NAME=~/.bash_profile
elif [ "$SHELL" == "/bin/sh" ]; then
	PROFILE_NAME=~/.profile
elif [ "$SHELL" == "/bin/zsh" ]; then
	PROFILE_NAME=~/.zshrc
elif [ "$SHELL" == "/bin/csh" ]; then
	PROFILE_NAME=~/.cshrc
	ENVSTR="set GGAPP_ROOT=$GGAPP_ROOT"
else
	echo "Error, unknow shell!"
	exit -1
fi

sed -i '/export GGAPP_ROOT=/d' $PROFILE_NAME
echo $ENVSTR >> $PROFILE_NAME
source $PROFILE_NAME
echo "Setup evn in $PROFILE_NAME"
